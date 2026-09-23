import 'package:native_sqlite_generator/src/models/schema_snapshot.dart';
import 'package:native_sqlite_generator/src/native/native_column.dart';
import 'package:native_sqlite_generator/src/native/native_database_spec.dart';
import 'package:native_sqlite_generator/src/sql/schema_sql.dart';

/// Generates Kotlin code for Android
class NativeKotlinGenerator {
  final String packageName;
  final String databaseName;
  final bool includeExamples;

  NativeKotlinGenerator({
    required this.packageName,
    required this.databaseName,
    required this.includeExamples,
  });

  String generateSchema(TableSchemaSnapshot model) {
    final buffer = StringBuffer();

    buffer.writeln('package $packageName');
    buffer.writeln();
    buffer.writeln('/**');
    buffer.writeln(' * Schema constants for ${model.className} table.');
    buffer.writeln(' * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY');
    buffer.writeln(
      ' * Generated from: lib/models/${_toSnakeCase(model.className)}.dart',
    );
    buffer.writeln(' */');
    buffer.writeln('object ${model.className}Schema {');
    buffer.writeln('    const val TABLE_NAME = ${_kotlinString(model.tableName)}');
    buffer.writeln();
    buffer.writeln('    // Column names');

    for (final field in model.columns) {
      final constantName = _toScreamingSnakeCase(field.dartName);
      buffer.writeln('    const val $constantName = ${_kotlinString(field.name)}');
    }

    buffer.writeln();
    buffer.writeln('    // Same statements as the Dart ${model.className}Schema');
    buffer.writeln(
      '    const val CREATE_TABLE_SQL = ${_kotlinString(SchemaSql.createTable(model))}',
    );
    final indexSql = SchemaSql.createIndexes(model);
    buffer.writeln();
    buffer.writeln('    val INDEX_SQL: List<String> = listOf(');
    for (final sql in indexSql) {
      buffer.writeln('        ${_kotlinString(sql)},');
    }
    buffer.writeln('    )');
    buffer.writeln('}');

    return buffer.toString();
  }

  /// Generates a Kotlin enum mirroring a Dart enum. Constant names are kept
  /// identical to Dart so `name`-stored values round-trip unchanged.
  String generateEnum(NativeEnum nativeEnum) {
    final buffer = StringBuffer();
    buffer.writeln('package $packageName');
    buffer.writeln();
    buffer.writeln('/**');
    buffer.writeln(' * Mirrors the Dart enum ${nativeEnum.name}.');
    buffer.writeln(' * Declaration order matches Dart, so ordinals are compatible.');
    buffer.writeln(' * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY');
    buffer.writeln(' */');
    buffer.writeln('enum class ${nativeEnum.name} {');
    buffer.writeln(
      nativeEnum.values.map((v) => '    ${_kotlinIdentifier(v)}').join(',\n'),
    );
    buffer.writeln('}');
    return buffer.toString();
  }

  String generateHelper(TableSchemaSnapshot model) {
    final buffer = StringBuffer();
    final primaryKey = model.columns.firstWhere(
      (f) => f.primaryKey,
      orElse: () => model.columns.first,
    );

    final columns = model.columns.map(NativeColumn.of).toList();
    final kinds = columns.map((c) => c.kind).toSet();

    // The query results are untyped maps from the plugin.
    buffer.writeln('@file:Suppress("UNCHECKED_CAST")');
    buffer.writeln();
    buffer.writeln('package $packageName');
    buffer.writeln();
    if (kinds.contains(NativeKind.uri)) buffer.writeln('import android.net.Uri');
    buffer.writeln('import dev.nesmin.native_sqlite.NativeSqliteManager');
    if (kinds.contains(NativeKind.duration)) {
      buffer.writeln('import java.time.Duration');
    }
    if (kinds.contains(NativeKind.dateTime)) {
      buffer.writeln('import java.time.Instant');
    }
    buffer.writeln('import java.util.concurrent.ConcurrentHashMap');
    buffer.writeln();
    buffer.writeln('/**');
    buffer.writeln(' * Data class for ${model.className}.');
    buffer.writeln(' * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY');
    buffer.writeln(' */');
    buffer.writeln('data class ${model.className}(');

    final params = <String>[];
    for (final column in columns) {
      final field = column.column;
      final kotlinType = _getKotlinType(column);
      final defaultValue = field.nullable ? ' = null' : '';
      final note = column.rawStorageNote;
      final doc = note == null ? '' : '    /** Raw $note. */\n';
      params.add(
        '$doc    val ${_kotlinIdentifier(field.dartName)}: $kotlinType$defaultValue',
      );
    }
    buffer.writeln(params.join(',\n'));
    buffer.writeln(')');
    buffer.writeln();

    buffer.writeln('/**');
    buffer.writeln(' * Helper class for ${model.className} CRUD operations.');
    buffer.writeln(' * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY');
    buffer.writeln(' * Thread-safe for multi-isolate access.');
    if (includeExamples) {
      buffer.writeln(' *');
      buffer.writeln(' * Example usage (single isolate):');
      buffer.writeln(' * ```');
      buffer.writeln(
        ' * val helper = ${model.className}Helper("$databaseName")',
      );
      buffer.writeln(' * val id = helper.insert(${model.className}(...))');
      buffer.writeln(' * val item = helper.findById(id)');
      buffer.writeln(' * ```');
      buffer.writeln(' *');
      buffer.writeln(' * Example usage (multi-isolate safe):');
      buffer.writeln(' * ```');
      buffer.writeln(' * // In WorkManager or background task');
      buffer.writeln(' * val isolateId = Thread.currentThread().id');
      buffer.writeln(
        ' * val helper = ${model.className}Helper.getInstance("$databaseName", isolateId)',
      );
      buffer.writeln(' * val users = helper.findAll()');
      buffer.writeln(' * // When done, cleanup:');
      buffer.writeln(' * ${model.className}Helper.cleanupIsolate(isolateId)');
      buffer.writeln(' * ```');
    }
    buffer.writeln(' */');
    buffer.writeln(
      'class ${model.className}Helper(private val databaseName: String) {',
    );
    buffer.writeln();

    // Add companion object for isolate-aware singleton pattern
    buffer.writeln('    companion object {');
    buffer.writeln(
      '        // Track helper instances per isolate for thread safety',
    );
    buffer.writeln(
      '        private val isolateInstances = ConcurrentHashMap<Long, ${model.className}Helper>()',
    );
    buffer.writeln();
    buffer.writeln('        /**');
    buffer.writeln(
      '         * Get or create helper instance for the given isolate.',
    );
    buffer.writeln(
      '         * Safe to call from different Dart isolates or native threads.',
    );
    buffer.writeln('         *');
    buffer.writeln('         * @param databaseName Name of the database');
    buffer.writeln(
      '         * @param isolateId Unique identifier for the isolate/thread',
    );
    buffer.writeln('         * @return Helper instance for this isolate');
    buffer.writeln('         */');
    buffer.writeln('        @JvmStatic');
    buffer.writeln(
      '        fun getInstance(databaseName: String, isolateId: Long): ${model.className}Helper {',
    );
    buffer.writeln('            return isolateInstances.getOrPut(isolateId) {');
    buffer.writeln('                ${model.className}Helper(databaseName)');
    buffer.writeln('            }');
    buffer.writeln('        }');
    buffer.writeln();
    buffer.writeln('        /**');
    buffer.writeln('         * Cleanup resources for a specific isolate.');
    buffer.writeln('         * Call this when an isolate is being destroyed.');
    buffer.writeln('         *');
    buffer.writeln('         * @param isolateId The isolate ID to cleanup');
    buffer.writeln('         */');
    buffer.writeln('        @JvmStatic');
    buffer.writeln('        fun cleanupIsolate(isolateId: Long) {');
    buffer.writeln('            isolateInstances.remove(isolateId)');
    buffer.writeln('        }');
    buffer.writeln();
    buffer.writeln('        /**');
    buffer.writeln(
      '         * Get all active isolate IDs currently using this helper.',
    );
    buffer.writeln('         * Useful for debugging.');
    buffer.writeln('         */');
    buffer.writeln('        @JvmStatic');
    buffer.writeln('        fun getActiveIsolates(): Set<Long> {');
    buffer.writeln('            return isolateInstances.keys.toSet()');
    buffer.writeln('        }');
    buffer.writeln('    }');
    buffer.writeln();

    // Insert method
    buffer.writeln('    fun insert(entity: ${model.className}): Long {');
    buffer.writeln('        val values: Map<String, Any?> = mapOf(');
    final insertFields = model.columns.where((f) => !(f.primaryKey && f.autoIncrement)).toList();
    for (var i = 0; i < insertFields.length; i++) {
      final field = insertFields[i];
      final value = _serializeKotlin(
        NativeColumn.of(field),
        'entity.${_kotlinIdentifier(field.dartName)}',
      );
      final comma = i < insertFields.length - 1 ? ',' : '';
      buffer.writeln(
        '            ${model.className}Schema.${_toScreamingSnakeCase(field.dartName)} to $value$comma',
      );
    }
    buffer.writeln('        )');
    buffer.writeln(
      '        return NativeSqliteManager.Instance.insert(databaseName, ${model.className}Schema.TABLE_NAME, values)',
    );
    buffer.writeln('    }');
    buffer.writeln();

    // FindById method
    final pkKotlinType = _getKotlinType(
      NativeColumn.of(primaryKey),
    ).replaceAll('?', '');
    buffer.writeln('    fun findById(id: $pkKotlinType): ${model.className}? {');
    buffer.writeln('        val result = NativeSqliteManager.Instance.query(');
    buffer.writeln('            databaseName,');
    buffer.writeln(
      '            "SELECT * FROM \${${model.className}Schema.TABLE_NAME} WHERE \${${model.className}Schema.${_toScreamingSnakeCase(primaryKey.dartName)}} = ? LIMIT 1",',
    );
    buffer.writeln('            listOf(id)');
    buffer.writeln('        )');
    buffer.writeln(
      '        val rows = result["rows"] as? List<List<Any?>> ?: return null',
    );
    buffer.writeln('        if (rows.isEmpty()) return null');
    buffer.writeln('        val columns = result["columns"] as List<String>');
    buffer.writeln(
      '        val columnMap = columns.withIndex().associate { it.value to it.index }',
    );
    buffer.writeln('        return fromRow(columnMap, rows[0])');
    buffer.writeln('    }');
    buffer.writeln();

    // FindAll method
    buffer.writeln('    fun findAll(): List<${model.className}> {');
    buffer.writeln(
      '        val result = NativeSqliteManager.Instance.query(databaseName, "SELECT * FROM \${${model.className}Schema.TABLE_NAME}")',
    );
    buffer.writeln(
      '        val rows = result["rows"] as? List<List<Any?>> ?: return emptyList()',
    );
    buffer.writeln('        val columns = result["columns"] as List<String>');
    buffer.writeln(
      '        val columnMap = columns.withIndex().associate { it.value to it.index }',
    );
    buffer.writeln('        return rows.map { fromRow(columnMap, it) }');
    buffer.writeln('    }');
    buffer.writeln();

    // Update method (full entity)
    buffer.writeln('    /**');
    buffer.writeln('     * Update an existing entity.');
    buffer.writeln(
      '     * @param entity The entity to update (must have a valid primary key)',
    );
    buffer.writeln('     * @return Number of rows affected');
    buffer.writeln('     */');
    buffer.writeln('    fun update(entity: ${model.className}): Int {');
    buffer.writeln('        val values: Map<String, Any?> = mapOf(');
    final updateFields = model.columns.where((f) => !f.primaryKey).toList();
    for (var i = 0; i < updateFields.length; i++) {
      final field = updateFields[i];
      final value = _serializeKotlin(
        NativeColumn.of(field),
        'entity.${_kotlinIdentifier(field.dartName)}',
      );
      final comma = i < updateFields.length - 1 ? ',' : '';
      buffer.writeln(
        '            ${model.className}Schema.${_toScreamingSnakeCase(field.dartName)} to $value$comma',
      );
    }
    buffer.writeln('        )');
    buffer.writeln('        return NativeSqliteManager.Instance.update(');
    buffer.writeln('            databaseName,');
    buffer.writeln('            ${model.className}Schema.TABLE_NAME,');
    buffer.writeln('            values,');
    buffer.writeln(
      '            "\${${model.className}Schema.${_toScreamingSnakeCase(primaryKey.dartName)}} = ?",',
    );
    buffer.writeln(
      '            listOf(${_serializeKotlin(NativeColumn.of(primaryKey), 'entity.${_kotlinIdentifier(primaryKey.dartName)}')})',
    );
    buffer.writeln('        )');
    buffer.writeln('    }');
    buffer.writeln();

    // UpdatePartial method
    buffer.writeln('    /**');
    buffer.writeln('     * Update specific fields of an entity.');
    buffer.writeln('     * @param id The primary key value');
    buffer.writeln('     * @param updates Map of column names to new values');
    buffer.writeln('     * @return Number of rows affected');
    buffer.writeln('     */');
    buffer.writeln(
      '    fun updatePartial(id: $pkKotlinType, updates: Map<String, Any?>): Int {',
    );
    buffer.writeln('        return NativeSqliteManager.Instance.update(');
    buffer.writeln('            databaseName,');
    buffer.writeln('            ${model.className}Schema.TABLE_NAME,');
    buffer.writeln('            updates,');
    buffer.writeln(
      '            "\${${model.className}Schema.${_toScreamingSnakeCase(primaryKey.dartName)}} = ?",',
    );
    buffer.writeln('            listOf(id)');
    buffer.writeln('        )');
    buffer.writeln('    }');
    buffer.writeln();

    // Delete by ID method
    buffer.writeln('    /**');
    buffer.writeln('     * Delete an entity by its primary key.');
    buffer.writeln('     * @param id The primary key value');
    buffer.writeln('     * @return Number of rows deleted');
    buffer.writeln('     */');
    buffer.writeln('    fun delete(id: $pkKotlinType): Int {');
    buffer.writeln('        return NativeSqliteManager.Instance.delete(');
    buffer.writeln('            databaseName,');
    buffer.writeln('            ${model.className}Schema.TABLE_NAME,');
    buffer.writeln(
      '            "\${${model.className}Schema.${_toScreamingSnakeCase(primaryKey.dartName)}} = ?",',
    );
    buffer.writeln('            listOf(id)');
    buffer.writeln('        )');
    buffer.writeln('    }');
    buffer.writeln();

    // DeleteWhere method
    buffer.writeln('    /**');
    buffer.writeln('     * Delete entities matching a WHERE clause.');
    buffer.writeln(
      '     * @param whereClause SQL WHERE clause (without "WHERE" keyword)',
    );
    buffer.writeln('     * @param whereArgs Arguments for the WHERE clause');
    buffer.writeln('     * @return Number of rows deleted');
    buffer.writeln('     */');
    buffer.writeln(
      '    fun deleteWhere(whereClause: String, whereArgs: List<Any?>? = null): Int {',
    );
    buffer.writeln('        return NativeSqliteManager.Instance.delete(');
    buffer.writeln('            databaseName,');
    buffer.writeln('            ${model.className}Schema.TABLE_NAME,');
    buffer.writeln('            whereClause,');
    buffer.writeln('            whereArgs');
    buffer.writeln('        )');
    buffer.writeln('    }');
    buffer.writeln();

    // InsertBatch method
    buffer.writeln('    /**');
    buffer.writeln('     * Insert multiple entities in a single transaction.');
    buffer.writeln('     * @param entities List of entities to insert');
    buffer.writeln('     * @return List of inserted row IDs');
    buffer.writeln('     */');
    buffer.writeln(
      '    fun insertBatch(entities: List<${model.className}>): List<Long> {',
    );
    buffer.writeln(
      '        val db = NativeSqliteManager.Instance.getDatabase(databaseName)',
    );
    buffer.writeln('        val results = mutableListOf<Long>()');
    buffer.writeln('        db.beginTransaction()');
    buffer.writeln('        try {');
    buffer.writeln('            entities.forEach { entity ->');
    buffer.writeln('                results.add(insert(entity))');
    buffer.writeln('            }');
    buffer.writeln('            db.setTransactionSuccessful()');
    buffer.writeln('        } finally {');
    buffer.writeln('            db.endTransaction()');
    buffer.writeln('        }');
    buffer.writeln('        return results');
    buffer.writeln('    }');
    buffer.writeln();

    // UpdateBatch method
    buffer.writeln('    /**');
    buffer.writeln('     * Update multiple entities in a single transaction.');
    buffer.writeln('     * @param entities List of entities to update');
    buffer.writeln('     * @return Total number of rows affected');
    buffer.writeln('     */');
    buffer.writeln(
      '    fun updateBatch(entities: List<${model.className}>): Int {',
    );
    buffer.writeln(
      '        val db = NativeSqliteManager.Instance.getDatabase(databaseName)',
    );
    buffer.writeln('        var totalAffected = 0');
    buffer.writeln('        db.beginTransaction()');
    buffer.writeln('        try {');
    buffer.writeln('            entities.forEach { entity ->');
    buffer.writeln('                totalAffected += update(entity)');
    buffer.writeln('            }');
    buffer.writeln('            db.setTransactionSuccessful()');
    buffer.writeln('        } finally {');
    buffer.writeln('            db.endTransaction()');
    buffer.writeln('        }');
    buffer.writeln('        return totalAffected');
    buffer.writeln('    }');
    buffer.writeln();

    // DeleteBatch method
    buffer.writeln('    /**');
    buffer.writeln(
      '     * Delete multiple entities by their IDs in a single transaction.',
    );
    buffer.writeln('     * @param ids List of primary key values');
    buffer.writeln('     * @return Total number of rows deleted');
    buffer.writeln('     */');
    buffer.writeln('    fun deleteBatch(ids: List<$pkKotlinType>): Int {');
    buffer.writeln(
      '        val db = NativeSqliteManager.Instance.getDatabase(databaseName)',
    );
    buffer.writeln('        var totalDeleted = 0');
    buffer.writeln('        db.beginTransaction()');
    buffer.writeln('        try {');
    buffer.writeln('            ids.forEach { id ->');
    buffer.writeln('                totalDeleted += delete(id)');
    buffer.writeln('            }');
    buffer.writeln('            db.setTransactionSuccessful()');
    buffer.writeln('        } finally {');
    buffer.writeln('            db.endTransaction()');
    buffer.writeln('        }');
    buffer.writeln('        return totalDeleted');
    buffer.writeln('    }');
    buffer.writeln();

    // Query Builder Methods
    buffer.writeln('    /**');
    buffer.writeln(
      '     * Find entities matching a WHERE clause with optional ordering and limit.',
    );
    buffer.writeln(
      '     * @param whereClause SQL WHERE clause (without "WHERE" keyword)',
    );
    buffer.writeln('     * @param whereArgs Arguments for the WHERE clause');
    buffer.writeln(
      '     * @param orderBy Column to order by (e.g., "name ASC", "age DESC")',
    );
    buffer.writeln('     * @param limit Maximum number of results');
    buffer.writeln('     * @param offset Number of results to skip');
    buffer.writeln('     * @return List of matching entities');
    buffer.writeln('     */');
    buffer.writeln('    fun findWhere(');
    buffer.writeln('        whereClause: String? = null,');
    buffer.writeln('        whereArgs: List<Any?>? = null,');
    buffer.writeln('        orderBy: String? = null,');
    buffer.writeln('        limit: Int? = null,');
    buffer.writeln('        offset: Int? = null');
    buffer.writeln('    ): List<${model.className}> {');
    buffer.writeln('        val sql = buildString {');
    buffer.writeln(
      '            append("SELECT * FROM \${${model.className}Schema.TABLE_NAME}")',
    );
    buffer.writeln('            whereClause?.let { append(" WHERE \$it") }');
    buffer.writeln('            orderBy?.let { append(" ORDER BY \$it") }');
    buffer.writeln('            limit?.let { append(" LIMIT \$it") }');
    buffer.writeln('            offset?.let { append(" OFFSET \$it") }');
    buffer.writeln('        }');
    buffer.writeln(
      '        val result = NativeSqliteManager.Instance.query(databaseName, sql, whereArgs)',
    );
    buffer.writeln(
      '        val rows = result["rows"] as? List<List<Any?>> ?: return emptyList()',
    );
    buffer.writeln('        val columns = result["columns"] as List<String>');
    buffer.writeln(
      '        val columnMap = columns.withIndex().associate { it.value to it.index }',
    );
    buffer.writeln('        return rows.map { fromRow(columnMap, it) }');
    buffer.writeln('    }');
    buffer.writeln();

    // Count method
    buffer.writeln('    /**');
    buffer.writeln('     * Count entities matching a WHERE clause.');
    buffer.writeln(
      '     * @param whereClause SQL WHERE clause (without "WHERE" keyword)',
    );
    buffer.writeln('     * @param whereArgs Arguments for the WHERE clause');
    buffer.writeln('     * @return Number of matching entities');
    buffer.writeln('     */');
    buffer.writeln(
      '    fun count(whereClause: String? = null, whereArgs: List<Any?>? = null): Long {',
    );
    buffer.writeln('        val sql = if (whereClause != null) {');
    buffer.writeln(
      '            "SELECT COUNT(*) FROM \${${model.className}Schema.TABLE_NAME} WHERE \$whereClause"',
    );
    buffer.writeln('        } else {');
    buffer.writeln(
      '            "SELECT COUNT(*) FROM \${${model.className}Schema.TABLE_NAME}"',
    );
    buffer.writeln('        }');
    buffer.writeln(
      '        val result = NativeSqliteManager.Instance.query(databaseName, sql, whereArgs)',
    );
    buffer.writeln(
      '        val rows = result["rows"] as? List<List<Any?>> ?: return 0',
    );
    buffer.writeln(
      '        return (rows.firstOrNull()?.firstOrNull() as? Long) ?: 0',
    );
    buffer.writeln('    }');
    buffer.writeln();

    // Aggregation methods
    buffer.writeln('    /**');
    buffer.writeln('     * Get the maximum value of a column.');
    buffer.writeln('     * @param column Column name to get max value from');
    buffer.writeln('     * @param whereClause Optional WHERE clause');
    buffer.writeln('     * @param whereArgs Arguments for WHERE clause');
    buffer.writeln('     * @return Maximum value or null');
    buffer.writeln('     */');
    buffer.writeln(
      '    fun max(column: String, whereClause: String? = null, whereArgs: List<Any?>? = null): Any? {',
    );
    buffer.writeln('        val sql = if (whereClause != null) {');
    buffer.writeln(
      '            "SELECT MAX(\$column) FROM \${${model.className}Schema.TABLE_NAME} WHERE \$whereClause"',
    );
    buffer.writeln('        } else {');
    buffer.writeln(
      '            "SELECT MAX(\$column) FROM \${${model.className}Schema.TABLE_NAME}"',
    );
    buffer.writeln('        }');
    buffer.writeln(
      '        val result = NativeSqliteManager.Instance.query(databaseName, sql, whereArgs)',
    );
    buffer.writeln(
      '        val rows = result["rows"] as? List<List<Any?>> ?: return null',
    );
    buffer.writeln('        return rows.firstOrNull()?.firstOrNull()');
    buffer.writeln('    }');
    buffer.writeln();

    buffer.writeln('    /**');
    buffer.writeln('     * Get the minimum value of a column.');
    buffer.writeln('     * @param column Column name to get min value from');
    buffer.writeln('     * @param whereClause Optional WHERE clause');
    buffer.writeln('     * @param whereArgs Arguments for WHERE clause');
    buffer.writeln('     * @return Minimum value or null');
    buffer.writeln('     */');
    buffer.writeln(
      '    fun min(column: String, whereClause: String? = null, whereArgs: List<Any?>? = null): Any? {',
    );
    buffer.writeln('        val sql = if (whereClause != null) {');
    buffer.writeln(
      '            "SELECT MIN(\$column) FROM \${${model.className}Schema.TABLE_NAME} WHERE \$whereClause"',
    );
    buffer.writeln('        } else {');
    buffer.writeln(
      '            "SELECT MIN(\$column) FROM \${${model.className}Schema.TABLE_NAME}"',
    );
    buffer.writeln('        }');
    buffer.writeln(
      '        val result = NativeSqliteManager.Instance.query(databaseName, sql, whereArgs)',
    );
    buffer.writeln(
      '        val rows = result["rows"] as? List<List<Any?>> ?: return null',
    );
    buffer.writeln('        return rows.firstOrNull()?.firstOrNull()');
    buffer.writeln('    }');
    buffer.writeln();

    buffer.writeln('    /**');
    buffer.writeln('     * Get the average value of a column.');
    buffer.writeln('     * @param column Column name to get average from');
    buffer.writeln('     * @param whereClause Optional WHERE clause');
    buffer.writeln('     * @param whereArgs Arguments for WHERE clause');
    buffer.writeln('     * @return Average value or null');
    buffer.writeln('     */');
    buffer.writeln(
      '    fun avg(column: String, whereClause: String? = null, whereArgs: List<Any?>? = null): Double? {',
    );
    buffer.writeln('        val sql = if (whereClause != null) {');
    buffer.writeln(
      '            "SELECT AVG(\$column) FROM \${${model.className}Schema.TABLE_NAME} WHERE \$whereClause"',
    );
    buffer.writeln('        } else {');
    buffer.writeln(
      '            "SELECT AVG(\$column) FROM \${${model.className}Schema.TABLE_NAME}"',
    );
    buffer.writeln('        }');
    buffer.writeln(
      '        val result = NativeSqliteManager.Instance.query(databaseName, sql, whereArgs)',
    );
    buffer.writeln(
      '        val rows = result["rows"] as? List<List<Any?>> ?: return null',
    );
    buffer.writeln(
      '        return rows.firstOrNull()?.firstOrNull() as? Double',
    );
    buffer.writeln('    }');
    buffer.writeln();

    buffer.writeln('    /**');
    buffer.writeln('     * Get the sum of a column.');
    buffer.writeln('     * @param column Column name to sum');
    buffer.writeln('     * @param whereClause Optional WHERE clause');
    buffer.writeln('     * @param whereArgs Arguments for WHERE clause');
    buffer.writeln('     * @return Sum value or null');
    buffer.writeln('     */');
    buffer.writeln(
      '    fun sum(column: String, whereClause: String? = null, whereArgs: List<Any?>? = null): Double? {',
    );
    buffer.writeln('        val sql = if (whereClause != null) {');
    buffer.writeln(
      '            "SELECT SUM(\$column) FROM \${${model.className}Schema.TABLE_NAME} WHERE \$whereClause"',
    );
    buffer.writeln('        } else {');
    buffer.writeln(
      '            "SELECT SUM(\$column) FROM \${${model.className}Schema.TABLE_NAME}"',
    );
    buffer.writeln('        }');
    buffer.writeln(
      '        val result = NativeSqliteManager.Instance.query(databaseName, sql, whereArgs)',
    );
    buffer.writeln(
      '        val rows = result["rows"] as? List<List<Any?>> ?: return null',
    );
    buffer.writeln(
      '        return rows.firstOrNull()?.firstOrNull() as? Double',
    );
    buffer.writeln('    }');
    buffer.writeln();

    // FromRow helper
    buffer.writeln(
      '    private fun fromRow(columnMap: Map<String, Int>, row: List<Any?>): ${model.className} {',
    );
    buffer.writeln('        return ${model.className}(');

    final fieldInits = <String>[];
    for (final column in columns) {
      final field = column.column;
      final value = _deserializeKotlin(
        column,
        'row[columnMap.getValue(${model.className}Schema.${_toScreamingSnakeCase(field.dartName)})]',
      );
      fieldInits.add('            ${_kotlinIdentifier(field.dartName)} = $value');
    }
    buffer.writeln(fieldInits.join(',\n'));
    buffer.writeln('        )');
    buffer.writeln('    }');
    buffer.writeln('}');

    return buffer.toString();
  }

  String _getKotlinType(NativeColumn column) {
    final kotlinType = switch (column.kind) {
      NativeKind.integer => 'Long',
      NativeKind.real => 'Double',
      NativeKind.text => 'String',
      NativeKind.blob => 'ByteArray',
      NativeKind.boolean => 'Boolean',
      NativeKind.dateTime => 'Instant',
      NativeKind.duration => 'Duration',
      NativeKind.uri => 'Uri',
      NativeKind.enumeration => column.enumName,
    };
    return column.nullable ? '$kotlinType?' : kotlinType;
  }

  /// Kotlin expression converting [accessor] to its SQLite storage value.
  String _serializeKotlin(NativeColumn column, String accessor) {
    final String Function(String) convert = switch (column.kind) {
      NativeKind.integer ||
      NativeKind.real ||
      NativeKind.text ||
      NativeKind.blob => (v) => v,
      NativeKind.boolean => (v) => 'if ($v) 1L else 0L',
      NativeKind.dateTime => (v) => '$v.toEpochMilli()',
      NativeKind.duration => (v) => '$v.toMillis()',
      NativeKind.uri => (v) => '$v.toString()',
      NativeKind.enumeration =>
        column.storesEnumByName ? (v) => '$v.name' : (v) => '$v.ordinal.toLong()',
    };
    final direct = convert(accessor);
    if (direct == accessor) return accessor;
    return column.nullable ? '$accessor?.let { ${convert('it')} }' : direct;
  }

  /// Kotlin expression converting the SQLite value [accessor] (as returned
  /// by NativeSqliteManager: Long, Double, String, ByteArray or null).
  String _deserializeKotlin(NativeColumn column, String accessor) {
    final String Function(String) convert = switch (column.kind) {
      NativeKind.integer => (v) => '($v as Number).toLong()',
      NativeKind.real => (v) => '($v as Number).toDouble()',
      NativeKind.text => (v) => '$v as String',
      NativeKind.blob => (v) => '$v as ByteArray',
      // Dart decodes booleans with `== 1`.
      NativeKind.boolean => (v) => '($v as Number).toLong() == 1L',
      NativeKind.dateTime => (v) => 'Instant.ofEpochMilli(($v as Number).toLong())',
      NativeKind.duration => (v) => 'Duration.ofMillis(($v as Number).toLong())',
      NativeKind.uri => (v) => 'Uri.parse($v as String)',
      NativeKind.enumeration =>
        column.storesEnumByName
            ? (v) => '${column.enumName}.valueOf($v as String)'
            : (v) => '${column.enumName}.entries[($v as Number).toInt()]',
    };
    return column.nullable
        ? '$accessor?.let { ${convert('it')} }'
        : convert(accessor);
  }

  /// Kotlin string literal for [value].
  String _kotlinString(String value) {
    final escaped = value
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll(r'$', r'\$')
        .replaceAll('\n', r'\n');
    return '"$escaped"';
  }

  /// Escapes Kotlin hard keywords used as identifiers.
  String _kotlinIdentifier(String name) =>
      _kotlinKeywords.contains(name) ? '`$name`' : name;

  static const _kotlinKeywords = {
    'as', 'break', 'class', 'continue', 'do', 'else', 'false', 'for', 'fun',
    'if', 'in', 'interface', 'is', 'null', 'object', 'package', 'return',
    'super', 'this', 'throw', 'true', 'try', 'typealias', 'typeof', 'val',
    'var', 'when', 'while',
  };

  /// Kotlin counterpart of the generated Dart DatabaseManager: it opens the
  /// database with the same version, statements and migration steps, so it
  /// makes no difference whether Dart or native code opens it first.
  String generateDatabaseManager(NativeDatabaseSpec spec) {
    final buffer = StringBuffer();
    final schemas = spec.tables;

    buffer.writeln('package $packageName');
    buffer.writeln();
    buffer.writeln('import android.content.Context');
    buffer.writeln('import dev.nesmin.native_sqlite.DatabaseConfig');
    buffer.writeln('import dev.nesmin.native_sqlite.NativeSqliteManager');
    buffer.writeln();
    buffer.writeln('/**');
    buffer.writeln(' * Native database manager, mirroring the generated DatabaseManager.dart.');
    buffer.writeln(
      ' * Call DatabaseManager.init() from native Android code (WorkManager,',
    );
    buffer.writeln(' * Services, App Widgets) before using the generated helpers.');
    buffer.writeln(' * AUTO-GENERATED - DO NOT EDIT MANUALLY');
    buffer.writeln(' */');
    buffer.writeln('object DatabaseManager {');
    buffer.writeln('    const val SCHEMA_VERSION = ${spec.schemaVersion}');
    buffer.writeln(
      '    const val DEFAULT_DATABASE_NAME = ${_kotlinString(spec.databaseName)}',
    );
    buffer.writeln();
    buffer.writeln('    val onCreateStatements: List<String> = listOf(');
    for (final schema in schemas) {
      buffer.writeln('        ${schema.className}Schema.CREATE_TABLE_SQL,');
    }
    buffer.writeln('    ) + listOf(');
    for (final schema in schemas) {
      buffer.writeln('        ${schema.className}Schema.INDEX_SQL,');
    }
    buffer.writeln('    ).flatten()');
    buffer.writeln();
    buffer.writeln(
      '    /** Versioned steps: `migrations[v]` upgrades version `v - 1` to `v`. */',
    );
    buffer.writeln('    val migrations: Map<Int, List<String>> = mapOf(');
    for (final MapEntry(key: version, value: sql) in spec.migrations.entries) {
      buffer.writeln('        $version to listOf(');
      for (final statement in sql) {
        buffer.writeln('            ${_kotlinString(statement)},');
      }
      buffer.writeln('        ),');
    }
    buffer.writeln('    )');
    buffer.writeln();
    buffer.writeln(
      '    /** Run after every upgrade: creates any missing table or index. */',
    );
    buffer.writeln('    val ensureSchemaStatements: List<String> = listOf(');
    for (final statement in spec.ensureSchema) {
      buffer.writeln('        ${_kotlinString(statement)},');
    }
    buffer.writeln('    )');
    buffer.writeln();
    buffer.writeln('    val tableNames: List<String> = listOf(');
    for (final schema in schemas) {
      buffer.writeln('        ${schema.className}Schema.TABLE_NAME,');
    }
    buffer.writeln('    )');
    buffer.writeln();
    buffer.writeln('    @Volatile');
    buffer.writeln('    private var currentDatabaseName: String? = null');
    buffer.writeln();
    buffer.writeln('    /**');
    buffer.writeln('     * Opens the database, creating it or applying pending migrations.');
    buffer.writeln('     *');
    buffer.writeln('     * @param context Any context; the application context is kept');
    buffer.writeln('     * @param name Database name (default: ${spec.databaseName})');
    buffer.writeln('     */');
    buffer.writeln('    @Synchronized');
    buffer.writeln('    fun init(');
    buffer.writeln('        context: Context,');
    buffer.writeln('        name: String = DEFAULT_DATABASE_NAME,');
    buffer.writeln('        enableWAL: Boolean = true,');
    buffer.writeln('        enableForeignKeys: Boolean = true,');
    buffer.writeln('    ) {');
    buffer.writeln('        val manager = NativeSqliteManager.Instance');
    buffer.writeln('        manager.initialize(context)');
    buffer.writeln(
      '        // Already opened (e.g. by Dart through the plugin, which shares this',
    );
    buffer.writeln(
      '        // manager) with the same generated schema and migrations.',
    );
    buffer.writeln('        if (manager.isDatabaseOpen(name)) {');
    buffer.writeln('            currentDatabaseName = name');
    buffer.writeln('            return');
    buffer.writeln('        }');
    buffer.writeln('        manager.openDatabase(');
    buffer.writeln('            DatabaseConfig(');
    buffer.writeln('                name = name,');
    buffer.writeln('                version = SCHEMA_VERSION,');
    buffer.writeln('                onCreate = onCreateStatements,');
    buffer.writeln('                onUpgrade = ensureSchemaStatements,');
    buffer.writeln('                enableWAL = enableWAL,');
    buffer.writeln('                enableForeignKeys = enableForeignKeys,');
    buffer.writeln('                migrations = migrations,');
    buffer.writeln('            )');
    buffer.writeln('        )');
    buffer.writeln('        currentDatabaseName = name');
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln('    @Synchronized');
    buffer.writeln('    fun close() {');
    buffer.writeln(
      '        currentDatabaseName?.let { NativeSqliteManager.Instance.closeDatabase(it) }',
    );
    buffer.writeln('        currentDatabaseName = null');
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln('    val isInitialized: Boolean get() = currentDatabaseName != null');
    buffer.writeln();
    buffer.writeln('    val currentDatabase: String');
    buffer.writeln(
      '        get() = checkNotNull(currentDatabaseName) { "Call DatabaseManager.init() first" }',
    );
    buffer.writeln('}');

    return buffer.toString();
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => '_${match.group(1)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '');
  }

  String _toScreamingSnakeCase(String input) {
    return _toSnakeCase(input).toUpperCase();
  }
}
