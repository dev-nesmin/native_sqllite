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
        let messenger = registrar.messenger()
        let channel = FlutterMethodChannel(
            name: "native_sqlite_ios",
            binaryMessenger: messenger,
            codec: FlutterStandardMethodCodec.sharedInstance(),
            taskQueue: messenger.makeBackgroundTaskQueue?()
        )
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
                let transactionId = args["transactionId"] as? String
                let rowsAffected = try databaseManager.execute(
                    name: name, sql: sql, arguments: arguments,
                    transactionId: transactionId
                )
                result(rowsAffected)

            case "query":
                guard let args = call.arguments as? [String: Any],
                      let name = args["name"] as? String,
                      let sql = args["sql"] as? String else {
                    throw NSError(domain: "NativeSqlite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database name and SQL are required"])
                }
                let arguments = sqlValues(args["arguments"])
                let transactionId = args["transactionId"] as? String
                let queryResult = try databaseManager.query(
                    name: name, sql: sql, arguments: arguments,
                    transactionId: transactionId
                )
                result(channelResult(queryResult))

            case "executeInsert":
                guard let args = call.arguments as? [String: Any],
                      let name = args["name"] as? String,
                      let sql = args["sql"] as? String else {
                    throw NSError(domain: "NativeSqlite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database name and SQL are required"])
                }
                let rowId = try databaseManager.executeInsert(
                    name: name,
                    sql: sql,
                    arguments: sqlValues(args["arguments"]),
                    transactionId: args["transactionId"] as? String
                )
                result(rowId)

            case "insert":
                guard let args = call.arguments as? [String: Any],
                      let name = args["name"] as? String,
                      let table = args["table"] as? String,
                      let values = sqlValues(map: args["values"]) else {
                    throw NSError(domain: "NativeSqlite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database name, table, and values are required"])
                }
                let rowId = try databaseManager.insert(
                    name: name, table: table, values: values,
                    transactionId: args["transactionId"] as? String
                )
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
                let rowsAffected = try databaseManager.update(
                    name: name, table: table, values: values,
                    whereClause: whereClause, whereArgs: whereArgs,
                    transactionId: args["transactionId"] as? String
                )
                result(rowsAffected)

            case "delete":
                guard let args = call.arguments as? [String: Any],
                      let name = args["name"] as? String,
                      let table = args["table"] as? String else {
                    throw NSError(domain: "NativeSqlite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database name and table are required"])
                }
                let whereClause = args["where"] as? String
                let whereArgs = sqlValues(args["whereArgs"])
                let rowsDeleted = try databaseManager.delete(
                    name: name, table: table, whereClause: whereClause,
                    whereArgs: whereArgs,
                    transactionId: args["transactionId"] as? String
                )
                result(rowsDeleted)

            case "beginTransaction":
                guard let args = call.arguments as? [String: Any],
                      let name = args["name"] as? String,
                      let transactionId = args["transactionId"] as? String else {
                    throw NSError(domain: "NativeSqlite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database name and transaction ID are required"])
                }
                try databaseManager.beginTransaction(name: name, transactionId: transactionId)
                result(nil)

            case "endTransaction":
                guard let args = call.arguments as? [String: Any],
                      let name = args["name"] as? String,
                      let transactionId = args["transactionId"] as? String,
                      let commit = args["commit"] as? Bool else {
                    throw NSError(domain: "NativeSqlite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database name, transaction ID, and commit flag are required"])
                }
                try databaseManager.endTransaction(
                    name: name, transactionId: transactionId, commit: commit
                )
                result(nil)

            case "batch":
                guard let args = call.arguments as? [String: Any],
                      let name = args["name"] as? String,
                      let operations = batchOperations(args["operations"]) else {
                    throw NSError(domain: "NativeSqlite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database name and batch operations are required"])
                }
                let values = try databaseManager.batch(name: name, operations: operations)
                result(values.map { value -> Any in
                    if let query = value as? [String: Any] {
                        return channelResult(query)
                    }
                    return value
                })

            case "getDatabasePath":
                guard let args = call.arguments as? [String: Any],
                      let name = args["name"] as? String else {
                    throw NSError(domain: "NativeSqlite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database name is required"])
                }
                let path = try databaseManager.getDatabasePath(
                    name: name,
                    directory: args["directory"] as? String,
                    iosAppGroup: args["iosAppGroup"] as? String
                )
                result(path)

            case "databaseExists":
                guard let args = call.arguments as? [String: Any],
                      let name = args["name"] as? String else {
                    throw NSError(domain: "NativeSqlite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database name is required"])
                }
                result(try databaseManager.databaseExists(
                    name: name,
                    directory: args["directory"] as? String,
                    iosAppGroup: args["iosAppGroup"] as? String
                ))

            case "importDatabase":
                guard let args = call.arguments as? [String: Any],
                      let name = args["name"] as? String,
                      let typedData = args["bytes"] as? FlutterStandardTypedData else {
                    throw NSError(domain: "NativeSqlite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database name and bytes are required"])
                }
                try databaseManager.importDatabase(
                    name: name,
                    data: typedData.data,
                    directory: args["directory"] as? String,
                    iosAppGroup: args["iosAppGroup"] as? String,
                    overwrite: args["overwrite"] as? Bool ?? false
                )
                result(nil)

            case "deleteDatabase":
                guard let args = call.arguments as? [String: Any],
                      let name = args["name"] as? String else {
                    throw NSError(domain: "NativeSqlite", code: -1, userInfo: [NSLocalizedDescriptionKey: "Database name is required"])
                }
                try databaseManager.deleteDatabase(
                    name: name,
                    directory: args["directory"] as? String,
                    iosAppGroup: args["iosAppGroup"] as? String
                )
                result(nil)

            default:
                result(FlutterMethodNotImplemented)
            }
        } catch {
            let nativeError = error as NSError
            var details: [String: Any]? = nil
            if nativeError.domain == "NativeSqlite", nativeError.code > 0 {
                let extendedCode = nativeError.userInfo["extendedCode"] as? Int
                    ?? nativeError.code
                var sql = nativeError.userInfo["sql"] as? String
                if sql == nil,
                   let arguments = call.arguments as? [String: Any] {
                    sql = arguments["sql"] as? String
                }
                details = [
                    "code": nativeError.code,
                    "extendedCode": extendedCode,
                ]
                if let sql = sql { details?["sql"] = sql }
            }
            result(FlutterError(code: "NATIVE_SQLITE_ERROR",
                              message: error.localizedDescription,
                              details: details))
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

    private func batchOperations(_ value: Any?) -> [[String: Any]]? {
        guard let operations = value as? [[String: Any]] else { return nil }
        return operations.map { operation in
            var converted = operation
            if operation.keys.contains("arguments") {
                converted["arguments"] = sqlValues(operation["arguments"]) ?? []
            }
            if operation.keys.contains("whereArgs") {
                converted["whereArgs"] = sqlValues(operation["whereArgs"]) ?? []
            }
            if operation.keys.contains("values"),
               let values = sqlValues(map: operation["values"]) {
                converted["values"] = values
            }
            return converted
        }
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
            onConfigure: map["onConfigure"] as? [String],
            enableWAL: map["enableWAL"] as? Bool ?? true,
            enableForeignKeys: map["enableForeignKeys"] as? Bool ?? true,
            busyTimeout: map["busyTimeout"] as? Int ?? 5_000,
            readOnly: map["readOnly"] as? Bool ?? false,
            migrations: parseMigrations(map["migrations"]),
            directory: map["directory"] as? String,
            iosAppGroup: map["iosAppGroup"] as? String
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
