package dev.nesmin.native_sqlite

import android.content.Context
import android.database.sqlite.SQLiteConstraintException
import android.database.sqlite.SQLiteException
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Native SQLite Plugin for Android
 *
 * This plugin provides SQLite database access from both Flutter and native Android code.
 * Database work runs on per-database worker queues. WAL is configurable.
 */
class NativeSqlitePlugin(
    private var databaseManager: NativeSqliteManager = NativeSqliteManager.Instance,
    private val taskDispatcher: ((String, () -> Unit) -> Unit)? = null,
    private val resultDispatcher: ((() -> Unit) -> Unit)? = null,
) : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "native_sqlite_android")
        channel.setMethodCallHandler(this)

        // Initialize the database manager with the context
        databaseManager.initialize(context)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        if (call.method !in supportedMethods) {
            result.notImplemented()
            return
        }
        val name = (call.arguments as? Map<*, *>)?.get("name") as? String
        if (name == null) {
            result.error("NATIVE_SQLITE_ERROR", "Database name is required", null)
            return
        }

        dispatch(name) {
            try {
            val transactionId = call.argument<String?>("transactionId")
            when (call.method) {
                "openDatabase" -> {
                    val config = parseDatabaseConfig(call.arguments as Map<*, *>)
                    val path = databaseManager.openDatabase(config)
                    complete { result.success(path) }
                }
                "closeDatabase" -> {
                    databaseManager.closeDatabase(name)
                    complete { result.success(null) }
                }
                "execute" -> {
                    val sql = call.argument<String>("sql")
                        ?: throw IllegalArgumentException("SQL is required")
                    val arguments = call.argument<List<Any?>>("arguments")
                    val rowsAffected = databaseManager.execute(name, sql, arguments, transactionId)
                    complete { result.success(rowsAffected) }
                }
                "executeInsert" -> {
                    val sql = call.argument<String>("sql")
                        ?: throw IllegalArgumentException("SQL is required")
                    val arguments = call.argument<List<Any?>>("arguments")
                    val rowId = databaseManager.executeInsert(
                        name, sql, arguments, transactionId,
                    )
                    complete { result.success(rowId) }
                }
                "query" -> {
                    val sql = call.argument<String>("sql")
                        ?: throw IllegalArgumentException("SQL is required")
                    val arguments = call.argument<List<Any?>>("arguments")
                    val queryResult = databaseManager.query(name, sql, arguments, transactionId)
                    complete { result.success(queryResult) }
                }
                "insert" -> {
                    val table = call.argument<String>("table")
                        ?: throw IllegalArgumentException("Table name is required")
                    val values = call.argument<Map<String, Any?>>("values")
                        ?: throw IllegalArgumentException("Values are required")
                    val rowId = databaseManager.insert(name, table, values, transactionId)
                    complete { result.success(rowId) }
                }
                "update" -> {
                    val table = call.argument<String>("table")
                        ?: throw IllegalArgumentException("Table name is required")
                    val values = call.argument<Map<String, Any?>>("values")
                        ?: throw IllegalArgumentException("Values are required")
                    val where = call.argument<String?>("where")
                    val whereArgs = call.argument<List<Any?>?>("whereArgs")
                    val rowsAffected = databaseManager.update(
                        name, table, values, where, whereArgs, transactionId,
                    )
                    complete { result.success(rowsAffected) }
                }
                "delete" -> {
                    val table = call.argument<String>("table")
                        ?: throw IllegalArgumentException("Table name is required")
                    val where = call.argument<String?>("where")
                    val whereArgs = call.argument<List<Any?>?>("whereArgs")
                    val rowsDeleted = databaseManager.delete(
                        name, table, where, whereArgs, transactionId,
                    )
                    complete { result.success(rowsDeleted) }
                }
                "beginTransaction" -> {
                    val id = transactionId
                        ?: throw IllegalArgumentException("Transaction ID is required")
                    databaseManager.beginTransaction(name, id)
                    complete { result.success(null) }
                }
                "endTransaction" -> {
                    val id = transactionId
                        ?: throw IllegalArgumentException("Transaction ID is required")
                    val commit = call.argument<Boolean>("commit")
                        ?: throw IllegalArgumentException("Commit flag is required")
                    databaseManager.endTransaction(name, id, commit)
                    complete { result.success(null) }
                }
                "batch" -> {
                    val operations = call.argument<List<Map<String, Any?>>>("operations")
                        ?: throw IllegalArgumentException("Batch operations are required")
                    val results = databaseManager.batch(name, operations)
                    complete { result.success(results) }
                }
                "getDatabasePath" -> {
                    val path = databaseManager.getDatabasePath(
                        name,
                        call.argument<String?>("directory"),
                    )
                    complete { result.success(path) }
                }
                "databaseExists" -> {
                    val exists = databaseManager.databaseExists(
                        name,
                        call.argument<String?>("directory"),
                    )
                    complete { result.success(exists) }
                }
                "importDatabase" -> {
                    val bytes = call.argument<ByteArray>("bytes")
                        ?: throw IllegalArgumentException("Database bytes are required")
                    databaseManager.importDatabase(
                        name,
                        bytes,
                        call.argument<String?>("directory"),
                        call.argument<Boolean>("overwrite") ?: false,
                    )
                    complete { result.success(null) }
                }
                "deleteDatabase" -> {
                    databaseManager.deleteDatabase(
                        name,
                        call.argument<String?>("directory"),
                    )
                    complete { result.success(null) }
                }
                else -> error("Unreachable method ${call.method}")
            }
            } catch (e: SQLiteException) {
                val details = sqliteErrorDetails(call, e)
                complete { result.error("NATIVE_SQLITE_ERROR", e.message, details) }
            } catch (e: Exception) {
                // Stack traces are included in debug builds to aid development.
                // In release builds they are omitted to avoid leaking internals.
                val details = if (BuildConfig.DEBUG) e.stackTraceToString() else null
                complete { result.error("NATIVE_SQLITE_ERROR", e.message, details) }
            }
        }
    }

    private fun dispatch(name: String, action: () -> Unit) {
        taskDispatcher?.invoke(name, action) ?: databaseManager.dispatch(name, action)
    }

    private fun complete(action: () -> Unit) {
        resultDispatcher?.invoke(action) ?: Handler(Looper.getMainLooper()).post(action)
    }

    private fun sqliteErrorDetails(call: MethodCall, error: SQLiteException): Map<String, Any?> {
        val message = error.message.orEmpty()
        val reportedCode = Regex("(?:code|error code)\\s+(\\d+)")
            .find(message)?.groupValues?.get(1)?.toIntOrNull()
        val extendedCode = when {
            message.contains("UNIQUE constraint failed", ignoreCase = true) -> 2067
            message.contains("NOT NULL constraint failed", ignoreCase = true) -> 1299
            message.contains("FOREIGN KEY constraint failed", ignoreCase = true) -> 787
            reportedCode != null -> reportedCode
            error is SQLiteConstraintException -> 19
            else -> 1
        }
        return mapOf(
            "code" to (extendedCode and 0xff),
            "extendedCode" to extendedCode,
            "sql" to sqlForCall(call),
        )
    }

    /** Reconstructs statement shapes only; values are deliberately excluded. */
    private fun sqlForCall(call: MethodCall): String? {
        call.argument<String>("sql")?.let { return it }
        val table = call.argument<String>("table") ?: return null
        val quotedTable = NativeSqliteManager.quoteIdentifier(table)
        return when (call.method) {
            "insert" -> {
                val values = call.argument<Map<String, Any?>>("values") ?: return null
                val columns = values.keys.joinToString(", ") {
                    NativeSqliteManager.quoteIdentifier(it)
                }
                val placeholders = values.keys.joinToString(", ") { "?" }
                "INSERT INTO $quotedTable ($columns) VALUES ($placeholders)"
            }
            "update" -> {
                val values = call.argument<Map<String, Any?>>("values") ?: return null
                val set = values.keys.joinToString(", ") {
                    "${NativeSqliteManager.quoteIdentifier(it)} = ?"
                }
                val where = call.argument<String?>("where")
                "UPDATE $quotedTable SET $set${if (where.isNullOrBlank()) "" else " WHERE $where"}"
            }
            "delete" -> {
                val where = call.argument<String?>("where")
                "DELETE FROM $quotedTable${if (where.isNullOrBlank()) "" else " WHERE $where"}"
            }
            else -> null
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    private fun parseDatabaseConfig(map: Map<*, *>): DatabaseConfig {
        return DatabaseConfig(
            name = map["name"] as String,
            version = (map["version"] as? Int) ?: 1,
            onCreate = (map["onCreate"] as? List<*>)?.filterIsInstance<String>(),
            onUpgrade = (map["onUpgrade"] as? List<*>)?.filterIsInstance<String>(),
            onConfigure = (map["onConfigure"] as? List<*>)?.filterIsInstance<String>(),
            enableWAL = (map["enableWAL"] as? Boolean) ?: true,
            enableForeignKeys = (map["enableForeignKeys"] as? Boolean) ?: true,
            busyTimeout = (map["busyTimeout"] as? Int) ?: 5_000,
            readOnly = (map["readOnly"] as? Boolean) ?: false,
            migrations = (map["migrations"] as? Map<*, *>)?.entries?.associate { (version, sql) ->
                (version as Number).toInt() to (sql as List<*>).filterIsInstance<String>()
            },
            directory = map["directory"] as? String,
            iosAppGroup = map["iosAppGroup"] as? String,
        )
    }

    private companion object {
        val supportedMethods = setOf(
            "openDatabase",
            "closeDatabase",
            "execute",
            "executeInsert",
            "query",
            "insert",
            "update",
            "delete",
            "beginTransaction",
            "endTransaction",
            "batch",
            "getDatabasePath",
            "databaseExists",
            "importDatabase",
            "deleteDatabase",
        )
    }
}
