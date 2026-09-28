package dev.nesmin.native_sqlite

import android.content.ContentValues
import android.content.Context
import android.database.Cursor
import android.database.CursorWindow
import android.database.DatabaseUtils
import android.database.SQLException
import android.database.sqlite.SQLiteCursor
import android.database.sqlite.SQLiteDatabase
import android.database.sqlite.SQLiteOpenHelper
import android.database.sqlite.SQLiteProgram
import android.os.Build
import android.os.Looper
import java.io.File
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.Executors

/**
 * Singleton manager for SQLite databases.
 *
 * This manager handles multiple databases and ensures thread-safe access.
 * It can be used directly from native Android code (e.g., WorkManager, Services)
 * without going through Flutter method channels.
 *
 * Example usage from native Android code:
 * ```kotlin
 * // In a WorkManager or Service
 * NativeSqliteManager.Instance.initialize(applicationContext)
 * val db = NativeSqliteManager.Instance.getDatabase("location_db")
 * db.insert("locations", null, ContentValues().apply {
 *     put("latitude", 37.7749)
 *     put("longitude", -122.4194)
 *     put("timestamp", System.currentTimeMillis())
 * })
 * ```
 */
open class NativeSqliteManager {
    companion object {
        val Instance = NativeSqliteManager()

        /** Quotes a SQLite identifier and escapes embedded double quotes. */
        @JvmStatic
        fun quoteIdentifier(identifier: String): String =
            "\"${identifier.replace("\"", "\"\"")}\""

        /** Rejects SQL strings containing more than one executable statement. */
        @JvmStatic
        fun requireSingleStatement(sql: String) {
            var statements = 0
            var hasSql = false
            var index = 0

            while (index < sql.length) {
                val char = sql[index]
                when {
                    char.isWhitespace() -> index++
                    char == '-' && index + 1 < sql.length && sql[index + 1] == '-' -> {
                        index += 2
                        while (index < sql.length && sql[index] != '\n' && sql[index] != '\r') {
                            index++
                        }
                    }
                    char == '/' && index + 1 < sql.length && sql[index + 1] == '*' -> {
                        index += 2
                        while (index + 1 < sql.length &&
                            !(sql[index] == '*' && sql[index + 1] == '/')
                        ) {
                            index++
                        }
                        index = minOf(index + 2, sql.length)
                    }
                    char == ';' -> {
                        if (hasSql) {
                            statements++
                            hasSql = false
                        }
                        index++
                    }
                    char == '\'' || char == '"' || char == '`' -> {
                        hasSql = true
                        val quote = char
                        index++
                        while (index < sql.length) {
                            if (sql[index] == quote) {
                                if (index + 1 < sql.length && sql[index + 1] == quote) {
                                    index += 2
                                } else {
                                    index++
                                    break
                                }
                            } else {
                                index++
                            }
                        }
                    }
                    char == '[' -> {
                        hasSql = true
                        index++
                        while (index < sql.length && sql[index] != ']') index++
                        if (index < sql.length) index++
                    }
                    else -> {
                        hasSql = true
                        index++
                    }
                }

                if (statements > 1) {
                    throw IllegalArgumentException(
                        "Exactly one SQL statement is allowed per string"
                    )
                }
            }

            if (hasSql) statements++
            if (statements > 1) {
                throw IllegalArgumentException(
                    "Exactly one SQL statement is allowed per string"
                )
            }
        }

        private fun executeConfigurationSql(db: SQLiteDatabase, sql: String) {
            requireSingleStatement(sql)
            if (sql.trimStart().startsWith("PRAGMA", ignoreCase = true)) {
                db.rawQuery(sql, null).use { cursor ->
                    while (cursor.moveToNext()) {
                        // Some assignment PRAGMAs return their configured value.
                    }
                }
            } else {
                db.execSQL(sql)
            }
        }

        private fun configsMatch(left: DatabaseConfig, right: DatabaseConfig): Boolean =
            left.name == right.name &&
                left.version == right.version &&
                sqlListsMatch(left.onCreate, right.onCreate) &&
                sqlListsMatch(left.onUpgrade, right.onUpgrade) &&
                sqlListsMatch(left.onConfigure, right.onConfigure) &&
                migrationMapsMatch(left.migrations, right.migrations) &&
                left.enableWAL == right.enableWAL &&
                left.enableForeignKeys == right.enableForeignKeys &&
                left.busyTimeout == right.busyTimeout &&
                left.readOnly == right.readOnly &&
                left.directory == right.directory

        private fun sqlListsMatch(left: List<String>?, right: List<String>?): Boolean {
            if (left == null || right == null) return left == right
            return left.size == right.size && left.indices.all { index ->
                sqlTokens(left[index]) == sqlTokens(right[index])
            }
        }

        private fun migrationMapsMatch(
            left: Map<Int, List<String>>?,
            right: Map<Int, List<String>>?
        ): Boolean {
            if (left == null || right == null) return left == right
            return left.keys == right.keys && left.all { (version, statements) ->
                sqlListsMatch(statements, right[version])
            }
        }

        private fun sqlTokens(sql: String): String {
            val result = StringBuilder()
            var index = 0

            fun addToken(token: String) {
                if (result.isNotEmpty()) result.append('\u001f')
                result.append(token)
            }

            while (index < sql.length) {
                val char = sql[index]
                when {
                    char.isWhitespace() -> index++
                    char == '-' && index + 1 < sql.length && sql[index + 1] == '-' -> {
                        index += 2
                        while (index < sql.length && sql[index] != '\n' && sql[index] != '\r') {
                            index++
                        }
                    }
                    char == '/' && index + 1 < sql.length && sql[index + 1] == '*' -> {
                        index += 2
                        while (index + 1 < sql.length &&
                            !(sql[index] == '*' && sql[index + 1] == '/')
                        ) {
                            index++
                        }
                        index = minOf(index + 2, sql.length)
                    }
                    char == '\'' || char == '"' || char == '`' -> {
                        val start = index++
                        while (index < sql.length) {
                            if (sql[index] == char) {
                                if (index + 1 < sql.length && sql[index + 1] == char) {
                                    index += 2
                                } else {
                                    index++
                                    break
                                }
                            } else {
                                index++
                            }
                        }
                        addToken(sql.substring(start, index))
                    }
                    char == '[' -> {
                        val start = index++
                        while (index < sql.length && sql[index] != ']') index++
                        if (index < sql.length) index++
                        addToken(sql.substring(start, index))
                    }
                    char.isLetterOrDigit() || char == '_' || char == '$' -> {
                        val start = index++
                        while (index < sql.length &&
                            (sql[index].isLetterOrDigit() || sql[index] == '_' || sql[index] == '$')
                        ) {
                            index++
                        }
                        addToken(sql.substring(start, index))
                    }
                    else -> {
                        addToken(char.toString())
                        index++
                    }
                }
            }
            return result.toString()
        }
    }

    private lateinit var appContext: Context
    private val databases = ConcurrentHashMap<String, SQLiteDatabase>()
    private val helpers = ConcurrentHashMap<String, DatabaseHelper>()
    private val databaseConfigs = ConcurrentHashMap<String, DatabaseConfig>()
    private val referenceCounts = ConcurrentHashMap<String, Int>()
    private val activeTransactions = ConcurrentHashMap<String, String>()
    private val executors = ConcurrentHashMap<String, java.util.concurrent.ExecutorService>()

    /** Runs Flutter channel work on the database's dedicated worker thread. */
    open fun dispatch(name: String, action: () -> Unit) {
        val executor = executors.computeIfAbsent(name) { databaseName ->
            Executors.newSingleThreadExecutor { runnable ->
                Thread(runnable, "native-sqlite-${databaseName.take(32)}")
            }
        }
        executor.execute(action)
    }

    private fun assertNotMainThread() {
        if (BuildConfig.DEBUG) {
            check(Looper.myLooper() != Looper.getMainLooper()) {
                "NativeSqliteManager performs synchronous SQLite work; call it from a background thread"
            }
        }
    }

    /**
     * Initialize the manager with application context.
     * This should be called once when the plugin is attached.
     */
    fun initialize(context: Context) {
        appContext = context.applicationContext
    }

    private fun requireAppContext(): Context {
        check(::appContext.isInitialized) {
            "NativeSqliteManager is not initialized. Call initialize(applicationContext) before opening, locating, or deleting a database."
        }
        return appContext
    }

    /**
     * Opens a database with the given configuration.
     *
     * @return The absolute path to the database file
     */
    open fun openDatabase(config: DatabaseConfig): String {
        assertNotMainThread()
        synchronized(this) {
            val existing = databases[config.name]
            if (existing != null) {
                val existingConfig = databaseConfigs[config.name]
                require(existingConfig != null && configsMatch(existingConfig, config)) {
                    "Database '${config.name}' is already open with a different configuration"
                }
                referenceCounts[config.name] = referenceCounts.getValue(config.name) + 1
                return existing.path
            }

            val path = getDatabasePath(config.name, config.directory)
            File(path).parentFile?.mkdirs()
            val helper = if (config.readOnly) null else
                DatabaseHelper(requireAppContext(), config, path)
            val db = try {
                if (config.readOnly) {
                    require(File(path).isFile) {
                        "Read-only database '${config.name}' does not exist"
                    }
                    SQLiteDatabase.openDatabase(
                        path,
                        null,
                        SQLiteDatabase.OPEN_READONLY,
                    ).also {
                        require(it.version == config.version) {
                            "Read-only database is at version ${it.version}, expected ${config.version}"
                        }
                        executeConfigurationSql(
                            it,
                            "PRAGMA busy_timeout = ${config.busyTimeout}",
                        )
                        if (config.enableForeignKeys) {
                            it.setForeignKeyConstraintsEnabled(true)
                        }
                        config.onConfigure?.forEach { sql ->
                            executeConfigurationSql(it, sql)
                        }
                    }
                } else {
                    helper!!.writableDatabase
                }
            } catch (error: Throwable) {
                helper?.close()
                throw error
            }

            if (helper != null) helpers[config.name] = helper
            databases[config.name] = db
            databaseConfigs[config.name] = config
            referenceCounts[config.name] = 1
            return db.path
        }
    }

    /**
     * Gets an open database instance.
     * Throws an exception if the database is not open.
     *
     * This is useful for native code that needs direct database access.
     */
    open fun getDatabase(name: String): SQLiteDatabase {
        assertNotMainThread()
        return databases[name] ?: throw IllegalStateException("Database '$name' is not open")
    }

    /**
     * Checks if a database is currently open.
     */
    open fun isDatabaseOpen(name: String): Boolean {
        return databases.containsKey(name)
    }

    /** Returns whether a database file exists at the configured location. */
    open fun databaseExists(name: String, directory: String? = null): Boolean {
        assertNotMainThread()
        return File(getDatabasePath(name, directory)).exists()
    }

    /** Writes a complete database file while no connection is open. */
    open fun importDatabase(
        name: String,
        bytes: ByteArray,
        directory: String? = null,
        overwrite: Boolean = false,
    ) {
        assertNotMainThread()
        synchronized(this) {
            check(!databases.containsKey(name)) { "Database '$name' is open" }
            val path = getDatabasePath(name, directory)
            val file = File(path)
            if (file.exists() && !overwrite) return
            file.parentFile?.mkdirs()
            if (overwrite) {
                listOf("$path-journal", "$path-wal", "$path-shm").forEach { sidecar ->
                    File(sidecar).delete()
                }
            }
            file.writeBytes(bytes)
        }
    }

    /**
     * Closes a database.
     */
    open fun closeDatabase(name: String) {
        assertNotMainThread()
        synchronized(this) {
            closeDatabaseLocked(name, force = false)
        }
    }

    private fun closeDatabaseLocked(name: String, force: Boolean) {
        check(force || !activeTransactions.containsKey(name)) {
            "Cannot close database $name while a transaction is active"
        }
        val references = referenceCounts[name] ?: return
        if (!force && references > 1) {
            referenceCounts[name] = references - 1
            return
        }

        referenceCounts.remove(name)
        activeTransactions.remove(name)
        databaseConfigs.remove(name)
        val database = databases.remove(name)
        val helper = helpers.remove(name)
        if (helper != null) helper.close() else database?.close()
    }

    /**
     * Closes all open databases.
     */
    open fun closeAll() {
        assertNotMainThread()
        synchronized(this) {
            databases.forEach { (name, database) ->
                val helper = helpers[name]
                if (helper != null) helper.close() else database.close()
            }
            databases.clear()
            helpers.clear()
            databaseConfigs.clear()
            referenceCounts.clear()
            activeTransactions.clear()
            executors.values.forEach { it.shutdown() }
            executors.clear()
        }
    }

    /**
     * Executes a raw SQL statement (INSERT, UPDATE, DELETE, etc.)
     *
     * @return Number of rows affected
     */
    open fun execute(
        name: String,
        sql: String,
        arguments: List<Any?>? = null,
        transactionId: String? = null,
    ): Int {
        requireTransactionAccess(name, transactionId)
        requireSingleStatement(sql)
        val db = getDatabase(name)
        val statement = db.compileStatement(sql)
        try {
            bindArguments(statement, arguments.orEmpty())
            val affectedRows = statement.executeUpdateDelete()
            // Android reports one affected row for some PRAGMA assignments,
            // although they modify no table rows (and iOS reports zero).
            return if (sql.trimStart().startsWith("PRAGMA", ignoreCase = true)) 0 else affectedRows
        } catch (error: SQLException) {
            // Android's SQLiteStatement rejects statements that return rows,
            // while SQLite accepts them for execute semantics. Step through
            // and discard those rows to match iOS and web.
            return try {
                val changesBefore = DatabaseUtils.longForQuery(
                    db,
                    "SELECT total_changes()",
                    null,
                )
                discardReturnedRows(db, sql, arguments.orEmpty())
                val changesAfter = DatabaseUtils.longForQuery(
                    db,
                    "SELECT total_changes()",
                    null,
                )
                (changesAfter - changesBefore).toInt()
            } catch (_: SQLException) {
                throw error
            }
        } finally {
            statement.close()
        }
    }

    /** Executes a raw INSERT and returns its SQLite row ID. */
    open fun executeInsert(
        name: String,
        sql: String,
        arguments: List<Any?>? = null,
        transactionId: String? = null,
    ): Long {
        requireTransactionAccess(name, transactionId)
        requireSingleStatement(sql)
        val statement = getDatabase(name).compileStatement(sql)
        return try {
            bindArguments(statement, arguments.orEmpty())
            val rowId = statement.executeInsert()
            check(rowId >= 0) { "INSERT did not return a row ID" }
            rowId
        } finally {
            statement.close()
        }
    }

    /**
     * Executes a SELECT query and returns the results.
     *
     * @return A map with "columns" and "rows" keys
     */
    open fun query(
        name: String,
        sql: String,
        arguments: List<Any?>? = null,
        transactionId: String? = null,
    ): Map<String, Any> {
        requireTransactionAccess(name, transactionId)
        requireSingleStatement(sql)
        val db = getDatabase(name)
        val cursor = db.rawQueryWithFactory(
            { database, masterQuery, editTable, query ->
                bindArguments(query, arguments.orEmpty())
                SQLiteCursor(database, masterQuery, editTable, query).also { cursor ->
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
                        cursor.window = CursorWindow(
                            "native_sqlite",
                            16L * 1024L * 1024L,
                        )
                    }
                }
            },
            sql,
            emptyArray(),
            ""
        )

        return cursor.use { c ->
            val columns = c.columnNames.toList()
            val rows = mutableListOf<List<Any?>>()

            while (c.moveToNext()) {
                val row = mutableListOf<Any?>()
                for (i in 0 until c.columnCount) {
                    row.add(c.getValue(i))
                }
                rows.add(row)
            }

            mapOf(
                "columns" to columns,
                "rows" to rows
            )
        }
    }

    /**
     * Inserts a row into a table.
     *
     * @return The row ID of the newly inserted row
     */
    open fun insert(
        name: String,
        table: String,
        values: Map<String, Any?>,
        transactionId: String? = null,
    ): Long {
        requireTransactionAccess(name, transactionId)
        val db = getDatabase(name)
        val contentValues = ContentValues().apply {
            values.forEach { (key, value) ->
                putValue(quoteIdentifier(key), value)
            }
        }
        return db.insertOrThrow(quoteIdentifier(table), null, contentValues)
    }

    /**
     * Updates rows in a table.
     *
     * @return The number of rows affected
     */
    open fun update(
        name: String,
        table: String,
        values: Map<String, Any?>,
        where: String? = null,
        whereArgs: List<Any?>? = null,
        transactionId: String? = null,
    ): Int {
        requireTransactionAccess(name, transactionId)
        require(whereArgs.isNullOrEmpty() || !where.isNullOrBlank()) {
            "whereArgs requires a non-empty where clause"
        }
        val db = getDatabase(name)
        require(values.isNotEmpty()) { "Values cannot be empty for update" }
        val entries = values.entries.toList()
        val setClause = entries.joinToString(", ") {
            "${quoteIdentifier(it.key)} = ?"
        }
        val sql = buildString {
            append("UPDATE ${quoteIdentifier(table)} SET $setClause")
            if (!where.isNullOrBlank()) append(" WHERE $where")
        }
        val arguments = entries.map { it.value } + whereArgs.orEmpty()
        requireSingleStatement(sql)
        val statement = db.compileStatement(sql)
        return try {
            bindArguments(statement, arguments)
            statement.executeUpdateDelete()
        } finally {
            statement.close()
        }
    }

    /**
     * Deletes rows from a table.
     *
     * @return The number of rows deleted
     */
    open fun delete(
        name: String,
        table: String,
        where: String? = null,
        whereArgs: List<Any?>? = null,
        transactionId: String? = null,
    ): Int {
        requireTransactionAccess(name, transactionId)
        require(whereArgs.isNullOrEmpty() || !where.isNullOrBlank()) {
            "whereArgs requires a non-empty where clause"
        }
        val db = getDatabase(name)
        val sql = buildString {
            append("DELETE FROM ${quoteIdentifier(table)}")
            if (!where.isNullOrBlank()) append(" WHERE $where")
        }
        requireSingleStatement(sql)
        val statement = db.compileStatement(sql)
        return try {
            bindArguments(statement, whereArgs.orEmpty())
            statement.executeUpdateDelete()
        } finally {
            statement.close()
        }
    }

    /**
     * Executes multiple SQL statements in a transaction.
     *
     * Throws and rolls back if any statement fails.
     */
    open fun transaction(name: String, statements: List<String>) {
        requireTransactionAccess(name, null)
        val db = getDatabase(name)
        db.beginTransaction()
        try {
            statements.forEach { sql ->
                requireSingleStatement(sql)
                db.execSQL(sql)
            }
            db.setTransactionSuccessful()
        } finally {
            db.endTransaction()
        }
    }

    /** Runs native database work atomically on the calling background thread. */
    fun <T> transaction(name: String, block: (NativeSqliteTransaction) -> T): T {
        val transactionId = "native-${System.nanoTime()}"
        beginTransaction(name, transactionId)
        val transaction = NativeSqliteTransaction(this, name, transactionId)
        return try {
            val value = block(transaction)
            transaction.finish()
            endTransaction(name, transactionId, commit = true)
            value
        } catch (error: Throwable) {
            transaction.finish()
            if (activeTransactions[name] == transactionId) {
                try {
                    endTransaction(name, transactionId, commit = false)
                } catch (_: Exception) {
                    // Preserve the callback error.
                }
            }
            throw error
        }
    }

    open fun beginTransaction(name: String, transactionId: String) {
        val db = getDatabase(name)
        check(activeTransactions.putIfAbsent(name, transactionId) == null) {
            "Database $name already has an active transaction"
        }
        try {
            db.beginTransaction()
        } catch (error: Exception) {
            activeTransactions.remove(name, transactionId)
            throw error
        }
    }

    open fun endTransaction(name: String, transactionId: String, commit: Boolean) {
        requireTransactionAccess(name, transactionId)
        val db = getDatabase(name)
        try {
            if (commit) db.setTransactionSuccessful()
        } finally {
            try {
                db.endTransaction()
            } finally {
                activeTransactions.remove(name, transactionId)
            }
        }
    }

    open fun batch(name: String, operations: List<Map<String, Any?>>): List<Any?> {
        val transactionId = "batch-${System.nanoTime()}"
        beginTransaction(name, transactionId)
        return try {
            val results = operations.map { operation ->
                when (val type = operation["type"] as? String) {
                    "execute" -> execute(
                        name,
                        operation["sql"] as String,
                        operation["arguments"] as? List<Any?>,
                        transactionId,
                    )
                    "query" -> query(
                        name,
                        operation["sql"] as String,
                        operation["arguments"] as? List<Any?>,
                        transactionId,
                    )
                    "insert" -> insert(
                        name,
                        operation["table"] as String,
                        operation["values"] as Map<String, Any?>,
                        transactionId,
                    )
                    "update" -> update(
                        name,
                        operation["table"] as String,
                        operation["values"] as Map<String, Any?>,
                        operation["where"] as? String,
                        operation["whereArgs"] as? List<Any?>,
                        transactionId,
                    )
                    "delete" -> delete(
                        name,
                        operation["table"] as String,
                        operation["where"] as? String,
                        operation["whereArgs"] as? List<Any?>,
                        transactionId,
                    )
                    else -> throw IllegalArgumentException("Unknown batch operation: $type")
                }
            }
            endTransaction(name, transactionId, commit = true)
            results
        } catch (error: Exception) {
            if (activeTransactions[name] == transactionId) {
                try {
                    endTransaction(name, transactionId, commit = false)
                } catch (_: Exception) {
                    // Preserve the operation that caused the rollback.
                }
            }
            throw error
        }
    }

    private fun requireTransactionAccess(name: String, transactionId: String?) {
        val active = activeTransactions[name]
        check(active == transactionId) {
            if (transactionId == null) {
                "Database $name has an active transaction"
            } else {
                "Transaction $transactionId is not active for database $name"
            }
        }
    }

    /**
     * Gets the absolute path to a database file.
     */
    open fun getDatabasePath(name: String, directory: String? = null): String {
        assertNotMainThread()
        require(Regex("^[A-Za-z0-9_-]+$").matches(name)) {
            "Database name must contain only ASCII letters, digits, underscores, and hyphens"
        }
        return if (directory == null) {
            requireAppContext().getDatabasePath("$name.db").absolutePath
        } else {
            require(File(directory).isAbsolute) { "Database directory must be absolute" }
            File(directory, "$name.db").absolutePath
        }
    }

    /**
     * Deletes a database file.
     */
    open fun deleteDatabase(name: String, directory: String? = null) {
        assertNotMainThread()
        synchronized(this) {
            closeDatabaseLocked(name, force = true)
            if (directory == null) {
                requireAppContext().deleteDatabase("$name.db")
            } else {
                val path = getDatabasePath(name, directory)
                listOf(path, "$path-journal", "$path-wal", "$path-shm").forEach { file ->
                    File(file).delete()
                }
            }
        }
    }

    private fun discardReturnedRows(
        db: SQLiteDatabase,
        sql: String,
        arguments: List<Any?>,
    ) {
        db.rawQueryWithFactory(
            { database, masterQuery, editTable, query ->
                bindArguments(query, arguments)
                SQLiteCursor(database, masterQuery, editTable, query)
            },
            sql,
            emptyArray(),
            "",
        ).use { cursor ->
            while (cursor.moveToNext()) {
                // Intentionally discard rows: this is execute(), not query().
            }
        }
    }

    // Helper extensions
    private fun Cursor.getValue(index: Int): Any? {
        return when (getType(index)) {
            Cursor.FIELD_TYPE_NULL -> null
            Cursor.FIELD_TYPE_INTEGER -> getLong(index)
            Cursor.FIELD_TYPE_FLOAT -> getDouble(index)
            // CursorWindow.getString stops at an embedded NUL on Android.
            // getBlob retains the full UTF-8 text plus its C terminator.
            Cursor.FIELD_TYPE_STRING -> getBlob(index).let { bytes ->
                val length = if (bytes.isNotEmpty() && bytes.last() == 0.toByte()) {
                    bytes.size - 1
                } else {
                    bytes.size
                }
                String(bytes, 0, length, Charsets.UTF_8)
            }
            Cursor.FIELD_TYPE_BLOB -> getBlob(index)
            else -> null
        }
    }

    private fun ContentValues.putValue(key: String, value: Any?) {
        when (value) {
            null -> putNull(key)
            is String -> put(key, value)
            is Int -> put(key, value)
            is Long -> put(key, value)
            is Double -> put(key, value)
            is Float -> put(key, value)
            is Boolean -> put(key, value)
            is ByteArray -> put(key, value)
            else -> throw IllegalArgumentException(
                "Unsupported SQLite value type for '$key': ${value::class.java.name}"
            )
        }
    }

    /** Binds values without converting their SQLite storage classes to text. */
    private fun bindArguments(program: SQLiteProgram, arguments: List<Any?>) {
        arguments.forEachIndexed { index, value ->
            val bindIndex = index + 1
            when (value) {
                null -> program.bindNull(bindIndex)
                is Boolean -> program.bindLong(bindIndex, if (value) 1L else 0L)
                is Byte -> program.bindLong(bindIndex, value.toLong())
                is Short -> program.bindLong(bindIndex, value.toLong())
                is Int -> program.bindLong(bindIndex, value.toLong())
                is Long -> program.bindLong(bindIndex, value)
                is Float -> program.bindDouble(bindIndex, value.toDouble())
                is Double -> program.bindDouble(bindIndex, value)
                is String -> program.bindString(bindIndex, value)
                is ByteArray -> program.bindBlob(bindIndex, value)
                else -> throw IllegalArgumentException(
                    "Unsupported SQLite argument type at index $index: ${value::class.java.name}"
                )
            }
        }
    }

    /**
     * SQLiteOpenHelper implementation
     */
    private class DatabaseHelper(
        context: Context,
        private val config: DatabaseConfig,
        path: String,
    ) : SQLiteOpenHelper(context, path, null, config.version) {

        init {
            setWriteAheadLoggingEnabled(config.enableWAL)
        }

        // onCreate/onUpgrade run inside SQLiteOpenHelper's transaction with
        // foreign keys still disabled, so table rebuilds can't cascade.
        override fun onCreate(db: SQLiteDatabase) {
            config.onCreate?.forEach { sql ->
                requireSingleStatement(sql)
                db.execSQL(sql)
            }
            db.rawQuery("PRAGMA foreign_key_check", null).use { cursor ->
                check(!cursor.moveToFirst()) {
                    "Database creation left ${cursor.count} foreign key violation(s)"
                }
            }
        }

        override fun onUpgrade(db: SQLiteDatabase, oldVersion: Int, newVersion: Int) {
            config.upgradeStatements(oldVersion).forEach { sql ->
                requireSingleStatement(sql)
                db.execSQL(sql)
            }
            db.rawQuery("PRAGMA foreign_key_check", null).use { cursor ->
                check(!cursor.moveToFirst()) {
                    "Migration to version $newVersion left ${cursor.count} foreign key violation(s)"
                }
            }
        }

        override fun onOpen(db: SQLiteDatabase) {
            // After create/upgrade; applies to every pooled connection.
            if (config.enableForeignKeys) db.setForeignKeyConstraintsEnabled(true)
            executeConfigurationSql(db, "PRAGMA busy_timeout = ${config.busyTimeout}")
            config.onConfigure?.forEach { sql ->
                executeConfigurationSql(db, sql)
            }
        }
    }
}

/** Database operations scoped to a native interactive transaction. */
class NativeSqliteTransaction internal constructor(
    private val manager: NativeSqliteManager,
    private val databaseName: String,
    private val transactionId: String,
) {
    private var active = true

    fun execute(sql: String, arguments: List<Any?>? = null): Int {
        checkActive()
        return manager.execute(databaseName, sql, arguments, transactionId)
    }

    fun query(sql: String, arguments: List<Any?>? = null): Map<String, Any> {
        checkActive()
        return manager.query(databaseName, sql, arguments, transactionId)
    }

    fun insert(table: String, values: Map<String, Any?>): Long {
        checkActive()
        return manager.insert(databaseName, table, values, transactionId)
    }

    fun update(
        table: String,
        values: Map<String, Any?>,
        where: String? = null,
        whereArgs: List<Any?>? = null,
    ): Int {
        checkActive()
        return manager.update(
            databaseName, table, values, where, whereArgs, transactionId,
        )
    }

    fun delete(
        table: String,
        where: String? = null,
        whereArgs: List<Any?>? = null,
    ): Int {
        checkActive()
        return manager.delete(databaseName, table, where, whereArgs, transactionId)
    }

    internal fun finish() {
        active = false
    }

    private fun checkActive() {
        check(active) { "This transaction has already completed" }
    }
}
