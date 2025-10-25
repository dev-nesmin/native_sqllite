package dev.nesmin.native_sqlite

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

/**
 * Native SQLite Plugin for Android
 *
 * This plugin provides SQLite database access from both Flutter and native Android code.
 * It uses WAL (Write-Ahead Logging) mode for concurrent access support.
 */
class NativeSqlitePlugin : FlutterPlugin, MethodCallHandler {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private val databaseManager = NativeSqliteManager

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "native_sqlite_android")
        channel.setMethodCallHandler(this)

        // Initialize the database manager with the context
        databaseManager.initialize(context)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        try {
            when (call.method) {
                "openDatabase" -> {
                    val config = parseDatabaseConfig(call.arguments as Map<*, *>)
                    val path = databaseManager.openDatabase(config)
                    result.success(path)
                }
                "closeDatabase" -> {
                    val name = call.argument<String>("name")
                        ?: throw IllegalArgumentException("Database name is required")
                    databaseManager.closeDatabase(name)
                    result.success(null)
                }
                "execute" -> {
                    val name = call.argument<String>("name")
                        ?: throw IllegalArgumentException("Database name is required")
                    val sql = call.argument<String>("sql")
                        ?: throw IllegalArgumentException("SQL is required")
                    val arguments = call.argument<List<Any?>>("arguments")
                    val rowsAffected = databaseManager.execute(name, sql, arguments)
                    result.success(rowsAffected)
                }
                "query" -> {
                    val name = call.argument<String>("name")
                        ?: throw IllegalArgumentException("Database name is required")
                    val sql = call.argument<String>("sql")
                        ?: throw IllegalArgumentException("SQL is required")
                    val arguments = call.argument<List<Any?>>("arguments")
                    val queryResult = databaseManager.query(name, sql, arguments)
                    result.success(queryResult)
                }
                "insert" -> {
                    val name = call.argument<String>("name")
                        ?: throw IllegalArgumentException("Database name is required")
                    val table = call.argument<String>("table")
                        ?: throw IllegalArgumentException("Table name is required")
                    val values = call.argument<Map<String, Any?>>("values")
                        ?: throw IllegalArgumentException("Values are required")
                    val rowId = databaseManager.insert(name, table, values)
                    result.success(rowId)
                }
                "update" -> {
                    val name = call.argument<String>("name")
                        ?: throw IllegalArgumentException("Database name is required")
                    val table = call.argument<String>("table")
                        ?: throw IllegalArgumentException("Table name is required")
                    val values = call.argument<Map<String, Any?>>("values")
                        ?: throw IllegalArgumentException("Values are required")
                    val where = call.argument<String?>("where")
                    val whereArgs = call.argument<List<Any?>?>("whereArgs")
                    val rowsAffected = databaseManager.update(name, table, values, where, whereArgs)
                    result.success(rowsAffected)
                }
                "delete" -> {
                    val name = call.argument<String>("name")
                        ?: throw IllegalArgumentException("Database name is required")
                    val table = call.argument<String>("table")
                        ?: throw IllegalArgumentException("Table name is required")
                    val where = call.argument<String?>("where")
                    val whereArgs = call.argument<List<Any?>?>("whereArgs")
                    val rowsDeleted = databaseManager.delete(name, table, where, whereArgs)
                    result.success(rowsDeleted)
                }
                "transaction" -> {
                    val name = call.argument<String>("name")
                        ?: throw IllegalArgumentException("Database name is required")
                    val statements = call.argument<List<String>>("statements")
                        ?: throw IllegalArgumentException("SQL statements are required")
                    val success = databaseManager.transaction(name, statements)
                    result.success(success)
                }
                "getDatabasePath" -> {
                    val name = call.argument<String>("name")
                        ?: throw IllegalArgumentException("Database name is required")
                    val path = databaseManager.getDatabasePath(name)
                    result.success(path)
                }
                "deleteDatabase" -> {
                    val name = call.argument<String>("name")
                        ?: throw IllegalArgumentException("Database name is required")
                    databaseManager.deleteDatabase(name)
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        } catch (e: Exception) {
            result.error("NATIVE_SQLITE_ERROR", e.message, e.stackTraceToString())
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        databaseManager.closeAll()
    }

    private fun parseDatabaseConfig(map: Map<*, *>): DatabaseConfig {
        return DatabaseConfig(
            name = map["name"] as String,
            version = (map["version"] as? Int) ?: 1,
            onCreate = (map["onCreate"] as? List<*>)?.filterIsInstance<String>(),
            onUpgrade = (map["onUpgrade"] as? List<*>)?.filterIsInstance<String>(),
            enableWAL = (map["enableWAL"] as? Boolean) ?: true,
            enableForeignKeys = (map["enableForeignKeys"] as? Boolean) ?: true
        )
    }
}

data class DatabaseConfig(
    val name: String,
    val version: Int,
    val onCreate: List<String>?,
    val onUpgrade: List<String>?,
    val enableWAL: Boolean,
    val enableForeignKeys: Boolean
)
