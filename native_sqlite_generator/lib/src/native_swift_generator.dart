import 'native_generator.dart';

/// Generates Swift code for iOS
class NativeSwiftGenerator {
  final String databaseName;
  final bool includeExamples;

  NativeSwiftGenerator({
    required this.databaseName,
    required this.includeExamples,
  });

  String generateSchema(TableModel model) {
    final buffer = StringBuffer();

    buffer.writeln('import Foundation');
    buffer.writeln();
    buffer.writeln('/**');
    buffer.writeln(' * Schema constants for ${model.className} table.');
    buffer.writeln(' * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY');
    buffer.writeln(
      ' * Generated from: lib/models/${_toSnakeCase(model.className)}.dart',
    );
    buffer.writeln(' */');
    buffer.writeln('public enum ${model.className}Schema {');
    buffer.writeln('    public static let tableName = "${model.tableName}"');
    buffer.writeln();
    buffer.writeln('    // Column names');

    for (final field in model.fields) {
      final constantName = _toCamelCase(field.fieldName);
      buffer.writeln(
        '    public static let $constantName = "${field.columnName}"',
      );
    }

    buffer.writeln();
    buffer.writeln('    // CREATE TABLE SQL');
    buffer.writeln('    public static let createTableSql = """');
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
    buffer.writeln('        """');
    buffer.writeln('}');

    return buffer.toString();
  }

  String generateHelper(TableModel model) {
    final buffer = StringBuffer();
    final primaryKey = model.fields.firstWhere(
      (f) => f.isPrimaryKey,
      orElse: () => model.fields.first,
    );

    buffer.writeln('import Foundation');
    buffer.writeln();
    buffer.writeln('/**');
    buffer.writeln(' * Struct for ${model.className}.');
    buffer.writeln(' * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY');
    buffer.writeln(' */');
    buffer.writeln('public struct ${model.className} {');

    for (final field in model.fields) {
      final swiftType = _getSwiftType(field);
      buffer.writeln('    public let ${field.fieldName}: $swiftType');
    }

    buffer.writeln();
    buffer.writeln('    public init(');
    final initParams = <String>[];
    for (final field in model.fields) {
      final swiftType = _getSwiftType(field);
      final defaultValue = field.isPrimaryKey && field.autoIncrement
          ? ' = nil'
          : '';
      initParams.add('        ${field.fieldName}: $swiftType$defaultValue');
    }
    buffer.writeln(initParams.join(',\n'));
    buffer.writeln('    ) {');

    for (final field in model.fields) {
      buffer.writeln('        self.${field.fieldName} = ${field.fieldName}');
    }

    buffer.writeln('    }');
    buffer.writeln('}');
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
        ' * let helper = ${model.className}Helper(databaseName: \"$databaseName\")',
      );
      buffer.writeln(' * let id = try helper.insert(${model.className}(...))');
      buffer.writeln(' * let item = try helper.findById(id)');
      buffer.writeln(' * ```');
      buffer.writeln(' *');
      buffer.writeln(' * Example usage (multi-isolate safe):');
      buffer.writeln(' * ```');
      buffer.writeln(' * // In BGTaskScheduler or background isolate');
      buffer.writeln(' * let isolateId = Int64(pthread_self())');
      buffer.writeln(
        ' * let helper = ${model.className}Helper.getInstance(databaseName: \"$databaseName\", isolateId: isolateId)',
      );
      buffer.writeln(' * let users = try helper.findAll()');
      buffer.writeln(' * // When done, cleanup:');
      buffer.writeln(
        ' * ${model.className}Helper.cleanupIsolate(isolateId: isolateId)',
      );
      buffer.writeln(' * ```');
    }
    buffer.writeln(' */');
    buffer.writeln('public class ${model.className}Helper {');
    buffer.writeln('    private let databaseName: String');
    buffer.writeln('    private let manager = NativeSqliteManager.shared');
    buffer.writeln();

    // Add static instance management for isolate safety
    buffer.writeln(
      '    // Track helper instances per isolate for thread safety',
    );
    buffer.writeln(
      '    private static var isolateInstances = [Int64: ${model.className}Helper]()',
    );
    buffer.writeln(
      '    private static let isolateQueue = DispatchQueue(label: \"${model.className}Helper.isolate\")',
    );
    buffer.writeln();
    buffer.writeln('    /**');
    buffer.writeln(
      '     * Get or create helper instance for the given isolate.',
    );
    buffer.writeln(
      '     * Safe to call from different Dart isolates or native threads.',
    );
    buffer.writeln('     *');
    buffer.writeln('     * - Parameters:');
    buffer.writeln('     *   - databaseName: Name of the database');
    buffer.writeln(
      '     *   - isolateId: Unique identifier for the isolate/thread',
    );
    buffer.writeln('     * - Returns: Helper instance for this isolate');
    buffer.writeln('     */');
    buffer.writeln(
      '    public static func getInstance(databaseName: String, isolateId: Int64) -> ${model.className}Helper {',
    );
    buffer.writeln('        return isolateQueue.sync {');
    buffer.writeln(
      '            if let existing = isolateInstances[isolateId] {',
    );
    buffer.writeln('                return existing');
    buffer.writeln('            }');
    buffer.writeln(
      '            let helper = ${model.className}Helper(databaseName: databaseName)',
    );
    buffer.writeln('            isolateInstances[isolateId] = helper');
    buffer.writeln('            return helper');
    buffer.writeln('        }');
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln('    /**');
    buffer.writeln('     * Cleanup resources for a specific isolate.');
    buffer.writeln('     * Call this when an isolate is being destroyed.');
    buffer.writeln('     *');
    buffer.writeln('     * - Parameter isolateId: The isolate ID to cleanup');
    buffer.writeln('     */');
    buffer.writeln('    public static func cleanupIsolate(isolateId: Int64) {');
    buffer.writeln('        isolateQueue.sync {');
    buffer.writeln(
      '            isolateInstances.removeValue(forKey: isolateId)',
    );
    buffer.writeln('        }');
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln('    /**');
    buffer.writeln(
      '     * Get all active isolate IDs currently using this helper.',
    );
    buffer.writeln('     * Useful for debugging.');
    buffer.writeln('     *');
    buffer.writeln('     * - Returns: Set of active isolate IDs');
    buffer.writeln('     */');
    buffer.writeln(
      '    public static func getActiveIsolates() -> Set<Int64> {',
    );
    buffer.writeln('        return isolateQueue.sync {');
    buffer.writeln('            return Set(isolateInstances.keys)');
    buffer.writeln('        }');
    buffer.writeln('    }');
    buffer.writeln();

    buffer.writeln('    public init(databaseName: String) {');
    buffer.writeln('        self.databaseName = databaseName');
    buffer.writeln('    }');
    buffer.writeln();

    // Insert method
    buffer.writeln(
      '    public func insert(_ entity: ${model.className}) throws -> Int {',
    );
    buffer.writeln('        var values: [String: Any] = [:]');
    for (final field in model.fields) {
      if (field.isPrimaryKey && field.autoIncrement) continue;

      final value = _serializeSwift(field, 'entity.${field.fieldName}');
      buffer.writeln(
        '        values[${model.className}Schema.${_toCamelCase(field.fieldName)}] = $value',
      );
    }
    buffer.writeln(
      '        return try manager.insert(name: databaseName, table: ${model.className}Schema.tableName, values: values)',
    );
    buffer.writeln('    }');
    buffer.writeln();

    // FindById method
    buffer.writeln(
      '    public func findById(_ id: Int) throws -> ${model.className}? {',
    );
    buffer.writeln('        let result = try manager.query(');
    buffer.writeln('            name: databaseName,');
    buffer.writeln(
      '            sql: "SELECT * FROM \\(${model.className}Schema.tableName) WHERE \\(${model.className}Schema.${_toCamelCase(primaryKey.fieldName)}) = ? LIMIT 1",',
    );
    buffer.writeln('            arguments: [id]');
    buffer.writeln('        )');
    buffer.writeln(
      '        guard let rows = result["rows"] as? [[Any?]], !rows.isEmpty,',
    );
    buffer.writeln(
      '              let columns = result["columns"] as? [String] else {',
    );
    buffer.writeln('            return nil');
    buffer.writeln('        }');
    buffer.writeln('        var columnMap: [String: Int] = [:]');
    buffer.writeln('        for (index, column) in columns.enumerated() {');
    buffer.writeln('            columnMap[column] = index');
    buffer.writeln('        }');
    buffer.writeln(
      '        return fromRow(columnMap: columnMap, row: rows[0])',
    );
    buffer.writeln('    }');
    buffer.writeln();

    // FindAll method
    buffer.writeln(
      '    public func findAll() throws -> [${model.className}] {',
    );
    buffer.writeln(
      '        let result = try manager.query(name: databaseName, sql: "SELECT * FROM \\(${model.className}Schema.tableName)")',
    );
    buffer.writeln('        guard let rows = result["rows"] as? [[Any?]],');
    buffer.writeln(
      '              let columns = result["columns"] as? [String] else {',
    );
    buffer.writeln('            return []');
    buffer.writeln('        }');
    buffer.writeln('        var columnMap: [String: Int] = [:]');
    buffer.writeln('        for (index, column) in columns.enumerated() {');
    buffer.writeln('            columnMap[column] = index');
    buffer.writeln('        }');
    buffer.writeln(
      '        return rows.map { fromRow(columnMap: columnMap, row: \$0) }',
    );
    buffer.writeln('    }');
    buffer.writeln();

    // Update method (full entity)
    buffer.writeln('    /**');
    buffer.writeln('     * Update an existing entity.');
    buffer.writeln(
      '     * - Parameter entity: The entity to update (must have a valid primary key)',
    );
    buffer.writeln('     * - Returns: Number of rows affected');
    buffer.writeln('     * - Throws: Database errors');
    buffer.writeln('     */');
    buffer.writeln(
      '    public func update(_ entity: ${model.className}) throws -> Int {',
    );
    buffer.writeln('        var values: [String: Any] = [:]');
    for (final field in model.fields) {
      if (field.isPrimaryKey) continue; // Skip PK in updates
      final value = _serializeSwift(field, 'entity.${field.fieldName}');
      buffer.writeln(
        '        values[${model.className}Schema.${_toCamelCase(field.fieldName)}] = $value',
      );
    }
    buffer.writeln('        return try manager.update(');
    buffer.writeln('            name: databaseName,');
    buffer.writeln('            table: ${model.className}Schema.tableName,');
    buffer.writeln('            values: values,');
    buffer.writeln(
      '            whereClause: "\\(${model.className}Schema.${_toCamelCase(primaryKey.fieldName)}) = ?",',
    );
    buffer.writeln('            whereArgs: [entity.${primaryKey.fieldName}]');
    buffer.writeln('        )');
    buffer.writeln('    }');
    buffer.writeln();

    // UpdatePartial method
    buffer.writeln('    /**');
    buffer.writeln('     * Update specific fields of an entity.');
    buffer.writeln('     * - Parameters:');
    buffer.writeln('     *   - id: The primary key value');
    buffer.writeln(
      '     *   - updates: Dictionary of column names to new values',
    );
    buffer.writeln('     * - Returns: Number of rows affected');
    buffer.writeln('     * - Throws: Database errors');
    buffer.writeln('     */');
    buffer.writeln(
      '    public func updatePartial(id: Int, updates: [String: Any]) throws -> Int {',
    );
    buffer.writeln('        return try manager.update(');
    buffer.writeln('            name: databaseName,');
    buffer.writeln('            table: ${model.className}Schema.tableName,');
    buffer.writeln('            values: updates,');
    buffer.writeln(
      '            whereClause: "\\(${model.className}Schema.${_toCamelCase(primaryKey.fieldName)}) = ?",',
    );
    buffer.writeln('            whereArgs: [id]');
    buffer.writeln('        )');
    buffer.writeln('    }');
    buffer.writeln();

    // Delete by ID method
    buffer.writeln('    /**');
    buffer.writeln('     * Delete an entity by its primary key.');
    buffer.writeln('     * - Parameter id: The primary key value');
    buffer.writeln('     * - Returns: Number of rows deleted');
    buffer.writeln('     * - Throws: Database errors');
    buffer.writeln('     */');
    buffer.writeln('    public func delete(id: Int) throws -> Int {');
    buffer.writeln('        return try manager.delete(');
    buffer.writeln('            name: databaseName,');
    buffer.writeln('            table: ${model.className}Schema.tableName,');
    buffer.writeln(
      '            whereClause: "\\(${model.className}Schema.${_toCamelCase(primaryKey.fieldName)}) = ?",',
    );
    buffer.writeln('            whereArgs: [id]');
    buffer.writeln('        )');
    buffer.writeln('    }');
    buffer.writeln();

    // DeleteWhere method
    buffer.writeln('    /**');
    buffer.writeln('     * Delete entities matching a WHERE clause.');
    buffer.writeln('     * - Parameters:');
    buffer.writeln(
      '     *   - whereClause: SQL WHERE clause (without "WHERE" keyword)',
    );
    buffer.writeln('     *   - whereArgs: Arguments for the WHERE clause');
    buffer.writeln('     * - Returns: Number of rows deleted');
    buffer.writeln('     * - Throws: Database errors');
    buffer.writeln('     */');
    buffer.writeln(
      '    public func deleteWhere(whereClause: String, whereArgs: [Any?]? = nil) throws -> Int {',
    );
    buffer.writeln('        return try manager.delete(');
    buffer.writeln('            name: databaseName,');
    buffer.writeln('            table: ${model.className}Schema.tableName,');
    buffer.writeln('            whereClause: whereClause,');
    buffer.writeln('            whereArgs: whereArgs');
    buffer.writeln('        )');
    buffer.writeln('    }');
    buffer.writeln();

    // InsertBatch method
    buffer.writeln('    /**');
    buffer.writeln('     * Insert multiple entities in a single transaction.');
    buffer.writeln('     * - Parameter entities: Array of entities to insert');
    buffer.writeln('     * - Returns: Array of inserted row IDs');
    buffer.writeln('     * - Throws: Database errors');
    buffer.writeln('     */');
    buffer.writeln(
      '    public func insertBatch(_ entities: [${model.className}]) throws -> [Int64] {',
    );
    buffer.writeln(
      '        let db = try manager.getDatabase(name: databaseName)',
    );
    buffer.writeln('        var results: [Int64] = []');
    buffer.writeln('        ');
    buffer.writeln(
      '        try manager.execute(name: databaseName, sql: "BEGIN TRANSACTION")',
    );
    buffer.writeln('        do {');
    buffer.writeln('            for entity in entities {');
    buffer.writeln('                let id = try insert(entity)');
    buffer.writeln('                results.append(id)');
    buffer.writeln('            }');
    buffer.writeln(
      '            try manager.execute(name: databaseName, sql: "COMMIT")',
    );
    buffer.writeln('        } catch {');
    buffer.writeln(
      '            try? manager.execute(name: databaseName, sql: "ROLLBACK")',
    );
    buffer.writeln('            throw error');
    buffer.writeln('        }');
    buffer.writeln('        return results');
    buffer.writeln('    }');
    buffer.writeln();

    // UpdateBatch method
    buffer.writeln('    /**');
    buffer.writeln('     * Update multiple entities in a single transaction.');
    buffer.writeln('     * - Parameter entities: Array of entities to update');
    buffer.writeln('     * - Returns: Total number of rows affected');
    buffer.writeln('     * - Throws: Database errors');
    buffer.writeln('     */');
    buffer.writeln(
      '    public func updateBatch(_ entities: [${model.className}]) throws -> Int {',
    );
    buffer.writeln('        var totalAffected = 0');
    buffer.writeln('        ');
    buffer.writeln(
      '        try manager.execute(name: databaseName, sql: "BEGIN TRANSACTION")',
    );
    buffer.writeln('        do {');
    buffer.writeln('            for entity in entities {');
    buffer.writeln('                totalAffected += try update(entity)');
    buffer.writeln('            }');
    buffer.writeln(
      '            try manager.execute(name: databaseName, sql: "COMMIT")',
    );
    buffer.writeln('        } catch {');
    buffer.writeln(
      '            try? manager.execute(name: databaseName, sql: "ROLLBACK")',
    );
    buffer.writeln('            throw error');
    buffer.writeln('        }');
    buffer.writeln('        return totalAffected');
    buffer.writeln('    }');
    buffer.writeln();

    // DeleteBatch method
    buffer.writeln('    /**');
    buffer.writeln(
      '     * Delete multiple entities by their IDs in a single transaction.',
    );
    buffer.writeln('     * - Parameter ids: Array of primary key values');
    buffer.writeln('     * - Returns: Total number of rows deleted');
    buffer.writeln('     * - Throws: Database errors');
    buffer.writeln('     */');
    buffer.writeln('    public func deleteBatch(ids: [Int]) throws -> Int {');
    buffer.writeln('        var totalDeleted = 0');
    buffer.writeln('        ');
    buffer.writeln(
      '        try manager.execute(name: databaseName, sql: "BEGIN TRANSACTION")',
    );
    buffer.writeln('        do {');
    buffer.writeln('            for id in ids {');
    buffer.writeln('                totalDeleted += try delete(id: id)');
    buffer.writeln('            }');
    buffer.writeln(
      '            try manager.execute(name: databaseName, sql: "COMMIT")',
    );
    buffer.writeln('        } catch {');
    buffer.writeln(
      '            try? manager.execute(name: databaseName, sql: "ROLLBACK")',
    );
    buffer.writeln('            throw error');
    buffer.writeln('        }');
    buffer.writeln('        return totalDeleted');
    buffer.writeln('    }');
    buffer.writeln();

    // Query Builder Methods
    buffer.writeln('    /**');
    buffer.writeln(
      '     * Find entities matching a WHERE clause with optional ordering and limit.',
    );
    buffer.writeln('     * - Parameters:');
    buffer.writeln(
      '     *   - whereClause: SQL WHERE clause (without "WHERE" keyword)',
    );
    buffer.writeln('     *   - whereArgs: Arguments for the WHERE clause');
    buffer.writeln(
      '     *   - orderBy: Column to order by (e.g., "name ASC", "age DESC")',
    );
    buffer.writeln('     *   - limit: Maximum number of results');
    buffer.writeln('     *   - offset: Number of results to skip');
    buffer.writeln('     * - Returns: Array of matching entities');
    buffer.writeln('     * - Throws: Database errors');
    buffer.writeln('     */');
    buffer.writeln('    public func findWhere(');
    buffer.writeln('        whereClause: String? = nil,');
    buffer.writeln('        whereArgs: [Any?]? = nil,');
    buffer.writeln('        orderBy: String? = nil,');
    buffer.writeln('        limit: Int? = nil,');
    buffer.writeln('        offset: Int? = nil');
    buffer.writeln('    ) throws -> [${model.className}] {');
    buffer.writeln(
      '        var sql = "SELECT * FROM \\(${model.className}Schema.tableName)"',
    );
    buffer.writeln('        if let whereClause = whereClause {');
    buffer.writeln('            sql += " WHERE \\(whereClause)"');
    buffer.writeln('        }');
    buffer.writeln('        if let orderBy = orderBy {');
    buffer.writeln('            sql += " ORDER BY \\(orderBy)"');
    buffer.writeln('        }');
    buffer.writeln('        if let limit = limit {');
    buffer.writeln('            sql += " LIMIT \\(limit)"');
    buffer.writeln('        }');
    buffer.writeln('        if let offset = offset {');
    buffer.writeln('            sql += " OFFSET \\(offset)"');
    buffer.writeln('        }');
    buffer.writeln(
      '        let result = try manager.query(name: databaseName, sql: sql, arguments: whereArgs)',
    );
    buffer.writeln('        guard let rows = result["rows"] as? [[Any?]],');
    buffer.writeln(
      '              let columns = result["columns"] as? [String] else {',
    );
    buffer.writeln('            return []');
    buffer.writeln('        }');
    buffer.writeln('        var columnMap: [String: Int] = [:]');
    buffer.writeln('        for (index, column) in columns.enumerated() {');
    buffer.writeln('            columnMap[column] = index');
    buffer.writeln('        }');
    buffer.writeln(
      '        return rows.map { fromRow(columnMap: columnMap, row: \$0) }',
    );
    buffer.writeln('    }');
    buffer.writeln();

    // Count method
    buffer.writeln('    /**');
    buffer.writeln('     * Count entities matching a WHERE clause.');
    buffer.writeln('     * - Parameters:');
    buffer.writeln(
      '     *   - whereClause: SQL WHERE clause (without "WHERE" keyword)',
    );
    buffer.writeln('     *   - whereArgs: Arguments for the WHERE clause');
    buffer.writeln('     * - Returns: Number of matching entities');
    buffer.writeln('     * - Throws: Database errors');
    buffer.writeln('     */');
    buffer.writeln(
      '    public func count(whereClause: String? = nil, whereArgs: [Any?]? = nil) throws -> Int64 {',
    );
    buffer.writeln('        let sql: String');
    buffer.writeln('        if let whereClause = whereClause {');
    buffer.writeln(
      '            sql = "SELECT COUNT(*) FROM \\(${model.className}Schema.tableName) WHERE \\(whereClause)"',
    );
    buffer.writeln('        } else {');
    buffer.writeln(
      '            sql = "SELECT COUNT(*) FROM \\(${model.className}Schema.tableName)"',
    );
    buffer.writeln('        }');
    buffer.writeln(
      '        let result = try manager.query(name: databaseName, sql: sql, arguments: whereArgs)',
    );
    buffer.writeln('        guard let rows = result["rows"] as? [[Any?]],');
    buffer.writeln(
      '              let count = rows.first?.first as? Int64 else {',
    );
    buffer.writeln('            return 0');
    buffer.writeln('        }');
    buffer.writeln('        return count');
    buffer.writeln('    }');
    buffer.writeln();

    // Aggregation methods
    buffer.writeln('    /**');
    buffer.writeln('     * Get the maximum value of a column.');
    buffer.writeln('     * - Parameters:');
    buffer.writeln('     *   - column: Column name to get max value from');
    buffer.writeln('     *   - whereClause: Optional WHERE clause');
    buffer.writeln('     *   - whereArgs: Arguments for WHERE clause');
    buffer.writeln('     * - Returns: Maximum value or nil');
    buffer.writeln('     * - Throws: Database errors');
    buffer.writeln('     */');
    buffer.writeln(
      '    public func max(column: String, whereClause: String? = nil, whereArgs: [Any?]? = nil) throws -> Any? {',
    );
    buffer.writeln('        let sql: String');
    buffer.writeln('        if let whereClause = whereClause {');
    buffer.writeln(
      '            sql = "SELECT MAX(\\(column)) FROM \\(${model.className}Schema.tableName) WHERE \\(whereClause)"',
    );
    buffer.writeln('        } else {');
    buffer.writeln(
      '            sql = "SELECT MAX(\\(column)) FROM \\(${model.className}Schema.tableName)"',
    );
    buffer.writeln('        }');
    buffer.writeln(
      '        let result = try manager.query(name: databaseName, sql: sql, arguments: whereArgs)',
    );
    buffer.writeln(
      '        guard let rows = result["rows"] as? [[Any?]] else { return nil }',
    );
    buffer.writeln('        return rows.first?.first');
    buffer.writeln('    }');
    buffer.writeln();

    buffer.writeln('    /**');
    buffer.writeln('     * Get the minimum value of a column.');
    buffer.writeln('     * - Parameters:');
    buffer.writeln('     *   - column: Column name to get min value from');
    buffer.writeln('     *   - whereClause: Optional WHERE clause');
    buffer.writeln('     *   - whereArgs: Arguments for WHERE clause');
    buffer.writeln('     * - Returns: Minimum value or nil');
    buffer.writeln('     * - Throws: Database errors');
    buffer.writeln('     */');
    buffer.writeln(
      '    public func min(column: String, whereClause: String? = nil, whereArgs: [Any?]? = nil) throws -> Any? {',
    );
    buffer.writeln('        let sql: String');
    buffer.writeln('        if let whereClause = whereClause {');
    buffer.writeln(
      '            sql = "SELECT MIN(\\(column)) FROM \\(${model.className}Schema.tableName) WHERE \\(whereClause)"',
    );
    buffer.writeln('        } else {');
    buffer.writeln(
      '            sql = "SELECT MIN(\\(column)) FROM \\(${model.className}Schema.tableName)"',
    );
    buffer.writeln('        }');
    buffer.writeln(
      '        let result = try manager.query(name: databaseName, sql: sql, arguments: whereArgs)',
    );
    buffer.writeln(
      '        guard let rows = result["rows"] as? [[Any?]] else { return nil }',
    );
    buffer.writeln('        return rows.first?.first');
    buffer.writeln('    }');
    buffer.writeln();

    buffer.writeln('    /**');
    buffer.writeln('     * Get the average value of a column.');
    buffer.writeln('     * - Parameters:');
    buffer.writeln('     *   - column: Column name to get average from');
    buffer.writeln('     *   - whereClause: Optional WHERE clause');
    buffer.writeln('     *   - whereArgs: Arguments for WHERE clause');
    buffer.writeln('     * - Returns: Average value or nil');
    buffer.writeln('     * - Throws: Database errors');
    buffer.writeln('     */');
    buffer.writeln(
      '    public func avg(column: String, whereClause: String? = nil, whereArgs: [Any?]? = nil) throws -> Double? {',
    );
    buffer.writeln('        let sql: String');
    buffer.writeln('        if let whereClause = whereClause {');
    buffer.writeln(
      '            sql = "SELECT AVG(\\(column)) FROM \\(${model.className}Schema.tableName) WHERE \\(whereClause)"',
    );
    buffer.writeln('        } else {');
    buffer.writeln(
      '            sql = "SELECT AVG(\\(column)) FROM \\(${model.className}Schema.tableName)"',
    );
    buffer.writeln('        }');
    buffer.writeln(
      '        let result = try manager.query(name: databaseName, sql: sql, arguments: whereArgs)',
    );
    buffer.writeln(
      '        guard let rows = result["rows"] as? [[Any?]] else { return nil }',
    );
    buffer.writeln('        return rows.first?.first as? Double');
    buffer.writeln('    }');
    buffer.writeln();

    buffer.writeln('    /**');
    buffer.writeln('     * Get the sum of a column.');
    buffer.writeln('     * - Parameters:');
    buffer.writeln('     *   - column: Column name to sum');
    buffer.writeln('     *   - whereClause: Optional WHERE clause');
    buffer.writeln('     *   - whereArgs: Arguments for WHERE clause');
    buffer.writeln('     * - Returns: Sum value or nil');
    buffer.writeln('     * - Throws: Database errors');
    buffer.writeln('     */');
    buffer.writeln(
      '    public func sum(column: String, whereClause: String? = nil, whereArgs: [Any?]? = nil) throws -> Double? {',
    );
    buffer.writeln('        let sql: String');
    buffer.writeln('        if let whereClause = whereClause {');
    buffer.writeln(
      '            sql = "SELECT SUM(\\(column)) FROM \\(${model.className}Schema.tableName) WHERE \\(whereClause)"',
    );
    buffer.writeln('        } else {');
    buffer.writeln(
      '            sql = "SELECT SUM(\\(column)) FROM \\(${model.className}Schema.tableName)"',
    );
    buffer.writeln('        }');
    buffer.writeln(
      '        let result = try manager.query(name: databaseName, sql: sql, arguments: whereArgs)',
    );
    buffer.writeln(
      '        guard let rows = result["rows"] as? [[Any?]] else { return nil }',
    );
    buffer.writeln('        return rows.first?.first as? Double');
    buffer.writeln('    }');
    buffer.writeln('    }');
    buffer.writeln();

    // FromRow helper
    buffer.writeln(
      '    private func fromRow(columnMap: [String: Int], row: [Any?]) -> ${model.className} {',
    );
    buffer.writeln('        return ${model.className}(');

    final fieldInits = <String>[];
    for (final field in model.fields) {
      final value = _deserializeSwift(
        field,
        'row[columnMap[${model.className}Schema.${_toCamelCase(field.fieldName)}]!]',
      );
      fieldInits.add('            ${field.fieldName}: $value');
    }
    buffer.writeln(fieldInits.join(',\n'));
    buffer.writeln('        )');
    buffer.writeln('    }');
    buffer.writeln('}');

    return buffer.toString();
  }

  String _getSwiftType(FieldModel field) {
    final baseType = field.dartType.replaceAll('?', '');
    String swiftType;

    // Handle basic types
    if (baseType == 'int' || baseType == 'Int') {
      swiftType = 'Int';
    } else if (baseType == 'DateTime') {
      swiftType = 'Int'; // Stored as epoch milliseconds
    } else if (baseType == 'double' || baseType == 'Double') {
      swiftType = 'Double';
    } else if (baseType == 'String') {
      swiftType = 'String';
    } else if (baseType == 'bool' || baseType == 'Boolean') {
      swiftType = 'Bool';
    }
    // Handle binary data
    else if (baseType == 'Uint8List') {
      swiftType = 'Data';
    }
    // Handle collections (stored as JSON)
    else if (baseType.startsWith('List<')) {
      swiftType = 'String'; // Serialized as JSON string
    } else if (baseType.startsWith('Map<')) {
      swiftType = 'String'; // Serialized as JSON string
    }
    // Handle enums (assume integer storage by default)
    else if (baseType.contains('Enum')) {
      swiftType = 'Int';
    } else {
      // Default to Any for unknown types
      swiftType = 'Any';
    }

    return field.isNullable ? '$swiftType?' : swiftType;
  }

  String _serializeSwift(FieldModel field, String accessor) {
    final baseType = field.dartType.replaceAll('?', '');

    // Handle boolean conversion to integer
    if (baseType == 'bool' || baseType == 'Boolean') {
      return field.isNullable
          ? '$accessor.map { \$0 ? 1 : 0 } ?? NSNull()'
          : '$accessor ? 1 : 0';
    }

    // Handle DateTime conversion to epoch milliseconds
    if (baseType == 'DateTime') {
      return field.isNullable
          ? '$accessor?.timeIntervalSince1970 ?? NSNull()'
          : 'Int($accessor.timeIntervalSince1970 * 1000)';
    }

    // Handle binary data (Uint8List -> Data)
    if (baseType == 'Uint8List') {
      return field.isNullable ? '$accessor ?? NSNull()' : accessor;
    }

    // Handle List serialization to JSON
    if (baseType.startsWith('List<')) {
      if (field.isNullable) {
        return '$accessor.flatMap { try? JSONEncoder().encode(\$0) }.flatMap { String(data: \$0, encoding: .utf8) } ?? NSNull()';
      } else {
        return 'try! String(data: JSONEncoder().encode($accessor), encoding: .utf8)!';
      }
    }

    // Handle Map serialization to JSON
    if (baseType.startsWith('Map<')) {
      if (field.isNullable) {
        return '$accessor.flatMap { try? JSONSerialization.data(withJSONObject: \$0) }.flatMap { String(data: \$0, encoding: .utf8) } ?? NSNull()';
      } else {
        return 'String(data: try! JSONSerialization.data(withJSONObject: $accessor), encoding: .utf8)!';
      }
    }

    return field.isNullable ? '$accessor ?? NSNull()' : accessor;
  }

  String _deserializeSwift(FieldModel field, String accessor) {
    final baseType = field.dartType.replaceAll('?', '');

    // Handle integer types
    if (baseType == 'int' || baseType == 'Int') {
      return field.isNullable ? '$accessor as? Int' : '$accessor as! Int';
    }
    // Handle DateTime (stored as epoch milliseconds)
    else if (baseType == 'DateTime') {
      if (field.isNullable) {
        return '($accessor as? Int).map { Date(timeIntervalSince1970: TimeInterval(\$0) / 1000) }';
      } else {
        return 'Date(timeIntervalSince1970: TimeInterval($accessor as! Int) / 1000)';
      }
    }
    // Handle double types
    else if (baseType == 'double' || baseType == 'Double') {
      return field.isNullable ? '$accessor as? Double' : '$accessor as! Double';
    }
    // Handle String types
    else if (baseType == 'String') {
      return field.isNullable ? '$accessor as? String' : '$accessor as! String';
    }
    // Handle boolean (stored as integer)
    else if (baseType == 'bool' || baseType == 'Boolean') {
      return field.isNullable
          ? '($accessor as? Int).map { \$0 == 1 }'
          : '($accessor as! Int) == 1';
    }
    // Handle binary data
    else if (baseType == 'Uint8List') {
      return field.isNullable ? '$accessor as? Data' : '$accessor as! Data';
    }
    // Handle List deserialization from JSON
    else if (baseType.startsWith('List<')) {
      if (field.isNullable) {
        return '($accessor as? String).flatMap { try? JSONDecoder().decode([Any].self, from: \$0.data(using: .utf8)!) }';
      } else {
        return 'try! JSONDecoder().decode([Any].self, from: ($accessor as! String).data(using: .utf8)!)';
      }
    }
    // Handle Map deserialization from JSON
    else if (baseType.startsWith('Map<')) {
      if (field.isNullable) {
        return '($accessor as? String).flatMap { try? JSONSerialization.jsonObject(with: \$0.data(using: .utf8)!) as? [String: Any] }';
      } else {
        return 'try! JSONSerialization.jsonObject(with: ($accessor as! String).data(using: .utf8)!) as! [String: Any]';
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

  String _toCamelCase(String input) {
    if (input.isEmpty) return input;
    return input[0].toLowerCase() + input.substring(1);
  }
}
