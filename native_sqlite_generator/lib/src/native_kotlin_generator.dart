import 'native_generator.dart';

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

  String generateSchema(TableModel model) {
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
    buffer.writeln('    const val TABLE_NAME = "${model.tableName}"');
    buffer.writeln();
    buffer.writeln('    // Column names');

    for (final field in model.fields) {
      final constantName = _toScreamingSnakeCase(field.fieldName);
      buffer.writeln('    const val $constantName = "${field.columnName}"');
    }

    buffer.writeln();
    buffer.writeln('    // CREATE TABLE SQL');
    buffer.writeln('    const val CREATE_TABLE_SQL = """');
    buffer.write('        CREATE TABLE ${model.tableName} (');

    final columnDefs = <String>[];
    for (final field in model.fields) {
      final parts = <String>[field.columnName, field.sqlType];

      if (field.isPrimaryKey) {
        parts.add('PRIMARY KEY');
        if (field.autoIncrement) {
          parts.add('AUTOINCREMENT');
        }
      }

      if (!field.isNullable && !field.isPrimaryKey) {
        parts.add('NOT NULL');
      }

      if (field.isUnique && !field.isPrimaryKey) {
        parts.add('UNIQUE');
      }

      columnDefs.add(parts.join(' '));
    }

    buffer.write('\n');
    buffer.write(columnDefs.map((def) => '            $def').join(',\n'));
    buffer.writeln('\n        )');
    buffer.writeln('    """.trimIndent()');
    buffer.writeln('}');

    return buffer.toString();
  }

  String generateHelper(TableModel model) {
    final buffer = StringBuffer();
    final primaryKey = model.fields.firstWhere(
      (f) => f.isPrimaryKey,
      orElse: () => model.fields.first,
    );

    buffer.writeln('package $packageName');
    buffer.writeln();
    buffer.writeln('import android.content.ContentValues');
    buffer.writeln('import dev.nesmin.native_sqlite.NativeSqliteManager');
    buffer.writeln('import java.util.concurrent.ConcurrentHashMap');
    buffer.writeln();
    buffer.writeln('/**');
    buffer.writeln(' * Data class for ${model.className}.');
    buffer.writeln(' * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY');
    buffer.writeln(' */');
    buffer.writeln('data class ${model.className}(');

    final params = <String>[];
    for (final field in model.fields) {
      final kotlinType = _getKotlinType(field);
      final defaultValue = field.isPrimaryKey && field.autoIncrement
          ? ' = null'
          : '';
      params.add('    val ${field.fieldName}: $kotlinType$defaultValue');
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
    buffer.writeln('        val values = ContentValues().apply {');
    for (final field in model.fields) {
      if (field.isPrimaryKey && field.autoIncrement) continue;

      final value = _serializeKotlin(field, 'entity.${field.fieldName}');
      buffer.writeln(
        '            put(${model.className}Schema.${_toScreamingSnakeCase(field.fieldName)}, $value)',
      );
    }
    buffer.writeln('        }');
    buffer.writeln(
      '        return NativeSqliteManager.insert(databaseName, ${model.className}Schema.TABLE_NAME, values)',
    );
    buffer.writeln('    }');
    buffer.writeln();

    // FindById method
    buffer.writeln('    fun findById(id: Long): ${model.className}? {');
    buffer.writeln('        val result = NativeSqliteManager.query(');
    buffer.writeln('            databaseName,');
    buffer.writeln(
      '            "SELECT * FROM \${${model.className}Schema.TABLE_NAME} WHERE \${${model.className}Schema.${_toScreamingSnakeCase(primaryKey.fieldName)}} = ? LIMIT 1",',
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
      '        val result = NativeSqliteManager.query(databaseName, "SELECT * FROM \${${model.className}Schema.TABLE_NAME}")',
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
    buffer.writeln('        val values = ContentValues().apply {');
    for (final field in model.fields) {
      if (field.isPrimaryKey) continue; // Skip PK in updates
      final value = _serializeKotlin(field, 'entity.${field.fieldName}');
      buffer.writeln(
        '            put(${model.className}Schema.${_toScreamingSnakeCase(field.fieldName)}, $value)',
      );
    }
    buffer.writeln('        }');
    buffer.writeln('        return NativeSqliteManager.update(');
    buffer.writeln('            databaseName,');
    buffer.writeln('            ${model.className}Schema.TABLE_NAME,');
    buffer.writeln('            values,');
    buffer.writeln(
      '            "\${${model.className}Schema.${_toScreamingSnakeCase(primaryKey.fieldName)}} = ?",',
    );
    buffer.writeln('            listOf(entity.${primaryKey.fieldName})');
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
      '    fun updatePartial(id: Long, updates: Map<String, Any?>): Int {',
    );
    buffer.writeln('        return NativeSqliteManager.update(');
    buffer.writeln('            databaseName,');
    buffer.writeln('            ${model.className}Schema.TABLE_NAME,');
    buffer.writeln('            updates,');
    buffer.writeln(
      '            "\${${model.className}Schema.${_toScreamingSnakeCase(primaryKey.fieldName)}} = ?",',
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
    buffer.writeln('    fun delete(id: Long): Int {');
    buffer.writeln('        return NativeSqliteManager.delete(');
    buffer.writeln('            databaseName,');
    buffer.writeln('            ${model.className}Schema.TABLE_NAME,');
    buffer.writeln(
      '            "\${${model.className}Schema.${_toScreamingSnakeCase(primaryKey.fieldName)}} = ?",',
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
    buffer.writeln('        return NativeSqliteManager.delete(');
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
      '        val db = NativeSqliteManager.getDatabase(databaseName)',
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
      '        val db = NativeSqliteManager.getDatabase(databaseName)',
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
    buffer.writeln('    fun deleteBatch(ids: List<Long>): Int {');
    buffer.writeln(
      '        val db = NativeSqliteManager.getDatabase(databaseName)',
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
      '        val result = NativeSqliteManager.query(databaseName, sql, whereArgs)',
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
      '        val result = NativeSqliteManager.query(databaseName, sql, whereArgs)',
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
      '        val result = NativeSqliteManager.query(databaseName, sql, whereArgs)',
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
      '        val result = NativeSqliteManager.query(databaseName, sql, whereArgs)',
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
      '        val result = NativeSqliteManager.query(databaseName, sql, whereArgs)',
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
      '        val result = NativeSqliteManager.query(databaseName, sql, whereArgs)',
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
    for (final field in model.fields) {
      final value = _deserializeKotlin(
        field,
        'row[columnMap[${model.className}Schema.${_toScreamingSnakeCase(field.fieldName)}]!!]',
      );
      fieldInits.add('            ${field.fieldName} = $value');
    }
    buffer.writeln(fieldInits.join(',\n'));
    buffer.writeln('        )');
    buffer.writeln('    }');
    buffer.writeln('}');

    return buffer.toString();
  }

  String _getKotlinType(FieldModel field) {
    final baseType = field.dartType.replaceAll('?', '');
    String kotlinType;

    // Handle basic types
    if (baseType == 'int' || baseType == 'Int') {
      kotlinType = 'Long';
    } else if (baseType == 'DateTime') {
      kotlinType = 'Long'; // Stored as epoch milliseconds
    } else if (baseType == 'double' || baseType == 'Double') {
      kotlinType = 'Double';
    } else if (baseType == 'String') {
      kotlinType = 'String';
    } else if (baseType == 'bool' || baseType == 'Boolean') {
      kotlinType = 'Boolean';
    }
    // Handle binary data
    else if (baseType == 'Uint8List') {
      kotlinType = 'ByteArray';
    }
    // Handle collections (stored as JSON)
    else if (baseType.startsWith('List<')) {
      kotlinType = 'String'; // Serialized as JSON string
    } else if (baseType.startsWith('Map<')) {
      kotlinType = 'String'; // Serialized as JSON string
    }
    // Handle enums (assume integer storage by default)
    else if (baseType.contains('Enum')) {
      kotlinType = 'Int';
    } else {
      // Default to Any for unknown types
      kotlinType = 'Any';
    }

    return field.isNullable ? '$kotlinType?' : kotlinType;
  }

  String _serializeKotlin(FieldModel field, String accessor) {
    final baseType = field.dartType.replaceAll('?', '');

    // Handle boolean conversion to integer
    if (baseType == 'bool' || baseType == 'Boolean') {
      return field.isNullable
          ? '$accessor?.let { if (it) 1 else 0 }'
          : 'if ($accessor) 1 else 0';
    }

    // Handle DateTime conversion to epoch milliseconds
    if (baseType == 'DateTime') {
      return field.isNullable
          ? '$accessor?.toEpochMilliseconds()'
          : '$accessor.toEpochMilliseconds()';
    }

    // Handle binary data (Uint8List -> ByteArray)
    if (baseType == 'Uint8List') {
      return accessor; // ByteArray is stored directly
    }

    // Handle List serialization to JSON
    if (baseType.startsWith('List<')) {
      if (field.isNullable) {
        return '$accessor?.let { Json.encodeToString(it) }';
      } else {
        return 'Json.encodeToString($accessor)';
      }
    }

    // Handle Map serialization to JSON
    if (baseType.startsWith('Map<')) {
      if (field.isNullable) {
        return '$accessor?.let { Json.encodeToString(it) }';
      } else {
        return 'Json.encodeToString($accessor)';
      }
    }

    // Default: return as-is
    return accessor;
  }

  String _deserializeKotlin(FieldModel field, String accessor) {
    final baseType = field.dartType.replaceAll('?', '');

    // Handle integer types
    if (baseType == 'int' || baseType == 'Int') {
      return '$accessor as Long${field.isNullable ? "?" : ""}';
    }
    // Handle DateTime (stored as epoch milliseconds)
    else if (baseType == 'DateTime') {
      if (field.isNullable) {
        return '($accessor as? Long)?.let { DateTime.fromEpochMilliseconds(it) }';
      } else {
        return 'DateTime.fromEpochMilliseconds($accessor as Long)';
      }
    }
    // Handle double types
    else if (baseType == 'double' || baseType == 'Double') {
      return '$accessor as Double${field.isNullable ? "?" : ""}';
    }
    // Handle String types
    else if (baseType == 'String') {
      return '$accessor as String${field.isNullable ? "?" : ""}';
    }
    // Handle boolean (stored as integer)
    else if (baseType == 'bool' || baseType == 'Boolean') {
      return field.isNullable
          ? '($accessor as? Long)?.let { it == 1L }'
          : '($accessor as Long) == 1L';
    }
    // Handle binary data
    else if (baseType == 'Uint8List') {
      return '$accessor as ByteArray${field.isNullable ? "?" : ""}';
    }
    // Handle List deserialization from JSON
    else if (baseType.startsWith('List<')) {
      if (field.isNullable) {
        return '($accessor as? String)?.let { Json.decodeFromString(it) }';
      } else {
        return 'Json.decodeFromString($accessor as String)';
      }
    }
    // Handle Map deserialization from JSON
    else if (baseType.startsWith('Map<')) {
      if (field.isNullable) {
        return '($accessor as? String)?.let { Json.decodeFromString(it) }';
      } else {
        return 'Json.decodeFromString($accessor as String)';
      }
    }

    return accessor;
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
