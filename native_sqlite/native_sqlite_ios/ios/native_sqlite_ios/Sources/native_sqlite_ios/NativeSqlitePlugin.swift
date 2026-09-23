import Flutter
import UIKit

/**
 * Native SQLite Plugin for iOS
 *
 * This plugin provides SQLite database access from both Flutter and native iOS code.
 * It uses WAL (Write-Ahead Logging) mode for concurrent access support.
 */
public class NativeSqlitePlugin: NSObject, FlutterPlugin {
    private let databaseManager = NativeSqliteManager.shared

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "native_sqlite_ios", binaryMessenger: registrar.messenger())
        let instance = NativeSqlitePlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        do {
            switch call.method {
            case "openDatabase":
                guard let args = call.arguments as? [String: Any] else {
                    throw NSError(domain: "NativeSqlite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid arguments"])
                }
                let config = try parseDatabaseConfig(args)
                let path = try databaseManager.openDatabase(config: config)
                result(path)

            case "closeDatabase":
                guard let args = call.arguments as? [String: Any],
                      let name = args["name"] as? String else {
                    throw NSError(domain: "NativeSqlite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database name is required"])
                }
                try databaseManager.closeDatabase(name: name)
                result(nil)

            case "execute":
                guard let args = call.arguments as? [String: Any],
                      let name = args["name"] as? String,
                      let sql = args["sql"] as? String else {
                    throw NSError(domain: "NativeSqlite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database name and SQL are required"])
                }
                let arguments = sqlValues(args["arguments"])
                let rowsAffected = try databaseManager.execute(name: name, sql: sql, arguments: arguments)
                result(rowsAffected)

            case "query":
                guard let args = call.arguments as? [String: Any],
                      let name = args["name"] as? String,
                      let sql = args["sql"] as? String else {
                    throw NSError(domain: "NativeSqlite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database name and SQL are required"])
                }
                let arguments = sqlValues(args["arguments"])
                let queryResult = try databaseManager.query(name: name, sql: sql, arguments: arguments)
                result(channelResult(queryResult))

            case "insert":
                guard let args = call.arguments as? [String: Any],
                      let name = args["name"] as? String,
                      let table = args["table"] as? String,
                      let values = sqlValues(map: args["values"]) else {
                    throw NSError(domain: "NativeSqlite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database name, table, and values are required"])
                }
                let rowId = try databaseManager.insert(name: name, table: table, values: values)
                result(rowId)

            case "update":
                guard let args = call.arguments as? [String: Any],
                      let name = args["name"] as? String,
                      let table = args["table"] as? String,
                      let values = sqlValues(map: args["values"]) else {
                    throw NSError(domain: "NativeSqlite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database name, table, and values are required"])
                }
                let whereClause = args["where"] as? String
                let whereArgs = sqlValues(args["whereArgs"])
                let rowsAffected = try databaseManager.update(name: name, table: table, values: values, whereClause: whereClause, whereArgs: whereArgs)
                result(rowsAffected)

            case "delete":
                guard let args = call.arguments as? [String: Any],
                      let name = args["name"] as? String,
                      let table = args["table"] as? String else {
                    throw NSError(domain: "NativeSqlite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database name and table are required"])
                }
                let whereClause = args["where"] as? String
                let whereArgs = sqlValues(args["whereArgs"])
                let rowsDeleted = try databaseManager.delete(name: name, table: table, whereClause: whereClause, whereArgs: whereArgs)
                result(rowsDeleted)

            case "transaction":
                guard let args = call.arguments as? [String: Any],
                      let name = args["name"] as? String,
                      let statements = args["statements"] as? [String] else {
                    throw NSError(domain: "NativeSqlite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database name and SQL statements are required"])
                }
                let success = try databaseManager.transaction(name: name, statements: statements)
                result(success)

            case "getDatabasePath":
                guard let args = call.arguments as? [String: Any],
                      let name = args["name"] as? String else {
                    throw NSError(domain: "NativeSqlite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database name is required"])
                }
                let path = databaseManager.getDatabasePath(name: name)
                result(path)

            case "deleteDatabase":
                guard let args = call.arguments as? [String: Any],
                      let name = args["name"] as? String else {
                    throw NSError(domain: "NativeSqlite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database name is required"])
                }
                try databaseManager.deleteDatabase(name: name)
                result(nil)

            default:
                result(FlutterMethodNotImplemented)
            }
        } catch {
            result(FlutterError(code: "NATIVE_SQLITE_ERROR",
                              message: error.localizedDescription,
                              details: nil))
        }
    }

    // MARK: - Channel value conversion
    //
    // The standard codec delivers Dart null as NSNull and Uint8List as
    // FlutterStandardTypedData; NativeSqliteManager works with plain Swift
    // values (nil, Data), shared with native callers.

    private func sqlValue(_ value: Any?) -> Any? {
        switch value {
        case nil, is NSNull:
            return nil
        case let typed as FlutterStandardTypedData:
            return typed.data
        default:
            return value
        }
    }

    private func sqlValues(_ value: Any?) -> [Any?]? {
        (value as? [Any])?.map(sqlValue)
    }

    private func sqlValues(map value: Any?) -> [String: Any?]? {
        (value as? [String: Any])?.mapValues(sqlValue)
    }

    private func channelResult(_ result: [String: Any]) -> [String: Any] {
        guard let rows = result["rows"] as? [[Any?]] else { return result }
        var converted = result
        converted["rows"] = rows.map { row in
            row.map { value -> Any in
                switch value {
                case nil:
                    return NSNull()
                case let data as Data:
                    return FlutterStandardTypedData(bytes: data)
                case let value?:
                    return value
                }
            }
        }
        return converted
    }

    private func parseDatabaseConfig(_ map: [String: Any]) throws -> DatabaseConfig {
        guard let name = map["name"] as? String else {
            throw NSError(domain: "NativeSqlite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database name is required"])
        }

        return DatabaseConfig(
            name: name,
            version: map["version"] as? Int ?? 1,
            onCreate: map["onCreate"] as? [String],
            onUpgrade: map["onUpgrade"] as? [String],
            enableWAL: map["enableWAL"] as? Bool ?? true,
            enableForeignKeys: map["enableForeignKeys"] as? Bool ?? true,
            migrations: parseMigrations(map["migrations"])
        )
    }

    /// The standard codec delivers Dart `Map<int, List<String>>` keys as NSNumber.
    private func parseMigrations(_ value: Any?) -> [Int: [String]]? {
        guard let map = value as? [AnyHashable: Any] else { return nil }
        var migrations: [Int: [String]] = [:]
        for (key, sql) in map {
            guard let version = (key as? NSNumber)?.intValue ?? (key as? Int),
                  let statements = sql as? [String] else { continue }
            migrations[version] = statements
        }
        return migrations
    }
}
