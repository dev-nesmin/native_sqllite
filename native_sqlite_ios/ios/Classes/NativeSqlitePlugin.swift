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
                let arguments = args["arguments"] as? [Any?]
                let rowsAffected = try databaseManager.execute(name: name, sql: sql, arguments: arguments)
                result(rowsAffected)

            case "query":
                guard let args = call.arguments as? [String: Any],
                      let name = args["name"] as? String,
                      let sql = args["sql"] as? String else {
                    throw NSError(domain: "NativeSqlite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database name and SQL are required"])
                }
                let arguments = args["arguments"] as? [Any?]
                let queryResult = try databaseManager.query(name: name, sql: sql, arguments: arguments)
                result(queryResult)

            case "insert":
                guard let args = call.arguments as? [String: Any],
                      let name = args["name"] as? String,
                      let table = args["table"] as? String,
                      let values = args["values"] as? [String: Any?] else {
                    throw NSError(domain: "NativeSqlite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database name, table, and values are required"])
                }
                let rowId = try databaseManager.insert(name: name, table: table, values: values)
                result(rowId)

            case "update":
                guard let args = call.arguments as? [String: Any],
                      let name = args["name"] as? String,
                      let table = args["table"] as? String,
                      let values = args["values"] as? [String: Any?] else {
                    throw NSError(domain: "NativeSqlite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database name, table, and values are required"])
                }
                let whereClause = args["where"] as? String
                let whereArgs = args["whereArgs"] as? [Any?]
                let rowsAffected = try databaseManager.update(name: name, table: table, values: values, whereClause: whereClause, whereArgs: whereArgs)
                result(rowsAffected)

            case "delete":
                guard let args = call.arguments as? [String: Any],
                      let name = args["name"] as? String,
                      let table = args["table"] as? String else {
                    throw NSError(domain: "NativeSqlite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database name and table are required"])
                }
                let whereClause = args["where"] as? String
                let whereArgs = args["whereArgs"] as? [Any?]
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
            enableForeignKeys: map["enableForeignKeys"] as? Bool ?? true
        )
    }
}

struct DatabaseConfig {
    let name: String
    let version: Int
    let onCreate: [String]?
    let onUpgrade: [String]?
    let enableWAL: Bool
    let enableForeignKeys: Bool
}
