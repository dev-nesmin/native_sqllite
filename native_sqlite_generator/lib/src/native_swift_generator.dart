import 'package:native_sqlite_generator/src/models/schema_snapshot.dart';
import 'package:native_sqlite_generator/src/native/native_column.dart';
import 'package:native_sqlite_generator/src/native/native_database_spec.dart';
import 'package:native_sqlite_generator/src/sql/schema_sql.dart';

/// Generates Swift code for iOS
class NativeSwiftGenerator {
  final String databaseName;
  final bool includeExamples;

  NativeSwiftGenerator({
    required this.databaseName,
    required this.includeExamples,
  });

  String generateSchema(TableSchemaSnapshot model) {
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
    buffer.writeln(
      '    public static let tableName = ${_swiftString(model.tableName)}',
    );
    buffer.writeln();
    buffer.writeln('    // Column names');

    for (final field in model.columns) {
      final constantName = _swiftIdentifier(_toCamelCase(field.dartName));
      buffer.writeln(
        '    public static let $constantName = ${_swiftString(field.name)}',
      );
    }

    buffer.writeln();
    buffer.writeln('    // Same statements as the Dart ${model.className}Schema');
    buffer.writeln(
      '    public static let createTableSql = ${_swiftString(SchemaSql.createTable(model))}',
    );
    buffer.writeln();
    buffer.writeln('    public static let indexSql: [String] = [');
    for (final sql in SchemaSql.createIndexes(model)) {
      buffer.writeln('        ${_swiftString(sql)},');
    }
    buffer.writeln('    ]');
    buffer.writeln('}');

    return buffer.toString();
  }

  /// Generates a Swift enum mirroring a Dart enum. Case names (and so raw
  /// values) match Dart names; declaration order matches Dart indexes.
  String generateEnum(NativeEnum nativeEnum) {
    final buffer = StringBuffer();
    buffer.writeln('import Foundation');
    buffer.writeln();
    buffer.writeln('/**');
    buffer.writeln(' * Mirrors the Dart enum ${nativeEnum.name}.');
    buffer.writeln(' * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY');
    buffer.writeln(' */');
    buffer.writeln(
      'public enum ${nativeEnum.name}: String, CaseIterable {',
    );
    for (final value in nativeEnum.values) {
      buffer.writeln('    case ${_swiftIdentifier(value)}');
    }
    buffer.writeln();
    buffer.writeln('    /// Index of this case, equal to the Dart enum\'s `index`.');
    buffer.writeln('    public var ordinal: Int64 {');
    buffer.writeln('        Int64(Self.allCases.firstIndex(of: self)!)');
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln('    public init?(ordinal: Int64) {');
    buffer.writeln('        let cases = Array(Self.allCases)');
    buffer.writeln(
      '        guard ordinal >= 0, ordinal < Int64(cases.count) else { return nil }',
    );
    buffer.writeln('        self = cases[Int(ordinal)]');
    buffer.writeln('    }');
    buffer.writeln('}');
    return buffer.toString();
  }

  /// Row decoding support shared by all generated helpers.
  String generateSupport() {
    return '''import Foundation

/**
 * Row decoding support for generated helpers.
 * AUTO-GENERATED - DO NOT EDIT MANUALLY
 */
public enum GeneratedRowError: Error, CustomStringConvertible {
    case missingColumn(String)
    case unexpectedValue(column: String, expected: String, value: Any?)

    public var description: String {
        switch self {
        case .missingColumn(let column):
            return "Column '\\(column)' is missing from the query result"
        case .unexpectedValue(let column, let expected, let value):
            return "Column '\\(column)': expected \\(expected), got \\(String(describing: value))"
        }
    }
}

/// A result row addressed by column name.
struct GeneratedRow {
    let columnMap: [String: Int]
    let values: [Any?]

    func optional<T>(_ column: String, _ convert: (Any) -> T?, expected: String) throws -> T? {
        guard let index = columnMap[column] else {
            throw GeneratedRowError.missingColumn(column)
        }
        guard let value = GeneratedRow.unwrap(values[index]) else { return nil }
        guard let converted = convert(value) else {
            throw GeneratedRowError.unexpectedValue(column: column, expected: expected, value: value)
        }
        return converted
    }

    /// Flattens nested optionals and maps NSNull to nil.
    static func unwrap(_ value: Any?) -> Any? {
        guard let value = value, !(value is NSNull) else { return nil }
        let mirror = Mirror(reflecting: value)
        if mirror.displayStyle == .optional {
            return unwrap(mirror.children.first?.value)
        }
        return value
    }

    func required<T>(_ column: String, _ convert: (Any) -> T?, expected: String) throws -> T {
        guard let value = try optional(column, convert, expected: expected) else {
            throw GeneratedRowError.unexpectedValue(column: column, expected: expected, value: nil)
        }
        return value
    }
}

/// Conversions from SQLite values (Int64, Double, String, Data) to Swift
/// types, using the same storage formats as the Dart side.
enum GeneratedValue {
    static func int64(_ value: Any) -> Int64? {
        (value as? Int64) ?? (value as? Int).map(Int64.init)
    }

    static func double(_ value: Any) -> Double? {
        (value as? Double) ?? int64(value).map(Double.init)
    }

    static func string(_ value: Any) -> String? { value as? String }

    static func data(_ value: Any) -> Data? { value as? Data }

    /// Dart decodes booleans with `== 1`.
    static func bool(_ value: Any) -> Bool? { int64(value).map { \$0 == 1 } }

    /// Milliseconds since epoch.
    static func date(_ value: Any) -> Date? {
        int64(value).map { Date(timeIntervalSince1970: Double(\$0) / 1000) }
    }

    /// Milliseconds.
    static func timeInterval(_ value: Any) -> TimeInterval? {
        int64(value).map { Double(\$0) / 1000 }
    }

    static func url(_ value: Any) -> URL? { string(value).flatMap(URL.init(string:)) }

    static func milliseconds(_ date: Date) -> Int64 {
        Int64((date.timeIntervalSince1970 * 1000).rounded())
    }

    static func milliseconds(_ interval: TimeInterval) -> Int64 {
        Int64((interval * 1000).rounded())
    }
}
''';
  }

  String generateHelper(TableSchemaSnapshot model) {
    final buffer = StringBuffer();
    final primaryKey = model.columns.firstWhere(
      (f) => f.primaryKey,
      orElse: () => model.columns.first,
    );

    final columns = model.columns.map(NativeColumn.of).toList();

    buffer.writeln('import Foundation');
    buffer.writeln('import native_sqlite_ios');
    buffer.writeln();
    buffer.writeln('/**');
    buffer.writeln(' * Struct for ${model.className}.');
    buffer.writeln(' * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY');
    buffer.writeln(' */');
    buffer.writeln('public struct ${model.className} {');

    for (final column in columns) {
      final note = column.rawStorageNote;
      if (note != null) buffer.writeln('    /// Raw $note.');
      buffer.writeln(
        '    public let ${_swiftIdentifier(column.column.dartName)}: ${_getSwiftType(column)}',
      );
    }

    buffer.writeln();
    buffer.writeln('    public init(');
    final initParams = <String>[];
    for (final column in columns) {
      final field = column.column;
      final defaultValue = field.nullable ? ' = nil' : '';
      initParams.add(
        '        ${_swiftIdentifier(field.dartName)}: ${_getSwiftType(column)}$defaultValue',
      );
    }
    buffer.writeln(initParams.join(',\n'));
    buffer.writeln('    ) {');

    for (final column in columns) {
      final name = column.column.dartName;
      buffer.writeln('        self.$name = ${_swiftIdentifier(name)}');
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
      '            _ = isolateInstances.removeValue(forKey: isolateId)',
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
    final pkColumn = NativeColumn.of(primaryKey);
    final pkSwiftType = _getSwiftType(pkColumn).replaceAll('?', '');
    buffer.writeln(
      '    public func insert(_ entity: ${model.className}) throws -> Int64 {',
    );
    _writeValues(
      buffer,
      model,
      columns.where((c) => !(c.column.primaryKey && c.column.autoIncrement)),
    );
    buffer.writeln(
      '        return try manager.insert(name: databaseName, table: ${model.className}Schema.tableName, values: values)',
    );
    buffer.writeln('    }');
    buffer.writeln();

    // FindById method
    buffer.writeln(
      '    public func findById(_ id: $pkSwiftType) throws -> ${model.className}? {',
    );
    buffer.writeln('        let result = try manager.query(');
    buffer.writeln('            name: databaseName,');
    buffer.writeln(
      '            sql: "SELECT * FROM \\(${model.className}Schema.tableName) WHERE \\(${model.className}Schema.${_toCamelCase(primaryKey.dartName)}) = ? LIMIT 1",',
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
      '        return try fromRow(columnMap: columnMap, row: rows[0])',
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
      '        return try rows.map { try fromRow(columnMap: columnMap, row: \$0) }',
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
    _writeValues(buffer, model, columns.where((c) => !c.column.primaryKey));
    buffer.writeln('        return try manager.update(');
    buffer.writeln('            name: databaseName,');
    buffer.writeln('            table: ${model.className}Schema.tableName,');
    buffer.writeln('            values: values,');
    buffer.writeln(
      '            whereClause: "\\(${model.className}Schema.${_toCamelCase(primaryKey.dartName)}) = ?",',
    );
    buffer.writeln(
      '            whereArgs: [${_serializeSwift(pkColumn, 'entity.${primaryKey.dartName}')}]',
    );
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
      '    public func updatePartial(id: $pkSwiftType, updates: [String: Any?]) throws -> Int {',
    );
    buffer.writeln('        return try manager.update(');
    buffer.writeln('            name: databaseName,');
    buffer.writeln('            table: ${model.className}Schema.tableName,');
    buffer.writeln('            values: updates,');
    buffer.writeln(
      '            whereClause: "\\(${model.className}Schema.${_toCamelCase(primaryKey.dartName)}) = ?",',
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
    buffer.writeln('    public func delete(id: $pkSwiftType) throws -> Int {');
    buffer.writeln('        return try manager.delete(');
    buffer.writeln('            name: databaseName,');
    buffer.writeln('            table: ${model.className}Schema.tableName,');
    buffer.writeln(
      '            whereClause: "\\(${model.className}Schema.${_toCamelCase(primaryKey.dartName)}) = ?",',
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
    buffer.writeln('        var results: [Int64] = []');
    buffer.writeln('        ');
    buffer.writeln(
      '        _ = try manager.execute(name: databaseName, sql: "BEGIN TRANSACTION")',
    );
    buffer.writeln('        do {');
    buffer.writeln('            for entity in entities {');
    buffer.writeln('                let id = try insert(entity)');
    buffer.writeln('                results.append(id)');
    buffer.writeln('            }');
    buffer.writeln(
      '            _ = try manager.execute(name: databaseName, sql: "COMMIT")',
    );
    buffer.writeln('        } catch {');
    buffer.writeln(
      '            _ = try? manager.execute(name: databaseName, sql: "ROLLBACK")',
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
      '        _ = try manager.execute(name: databaseName, sql: "BEGIN TRANSACTION")',
    );
    buffer.writeln('        do {');
    buffer.writeln('            for entity in entities {');
    buffer.writeln('                totalAffected += try update(entity)');
    buffer.writeln('            }');
    buffer.writeln(
      '            _ = try manager.execute(name: databaseName, sql: "COMMIT")',
    );
    buffer.writeln('        } catch {');
    buffer.writeln(
      '            _ = try? manager.execute(name: databaseName, sql: "ROLLBACK")',
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
    buffer.writeln('    public func deleteBatch(ids: [$pkSwiftType]) throws -> Int {');
    buffer.writeln('        var totalDeleted = 0');
    buffer.writeln('        ');
    buffer.writeln(
      '        _ = try manager.execute(name: databaseName, sql: "BEGIN TRANSACTION")',
    );
    buffer.writeln('        do {');
    buffer.writeln('            for id in ids {');
    buffer.writeln('                totalDeleted += try delete(id: id)');
    buffer.writeln('            }');
    buffer.writeln(
      '            _ = try manager.execute(name: databaseName, sql: "COMMIT")',
    );
    buffer.writeln('        } catch {');
    buffer.writeln(
      '            _ = try? manager.execute(name: databaseName, sql: "ROLLBACK")',
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
      '        return try rows.map { try fromRow(columnMap: columnMap, row: \$0) }',
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
    buffer.writeln('        return rows.first?.first ?? nil');
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
    buffer.writeln('        return rows.first?.first ?? nil');
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
    buffer.writeln();

    // FromRow helper
    buffer.writeln(
      '    private func fromRow(columnMap: [String: Int], row values: [Any?]) throws -> ${model.className} {',
    );
    buffer.writeln(
      '        let row = GeneratedRow(columnMap: columnMap, values: values)',
    );
    buffer.writeln('        return ${model.className}(');

    final fieldInits = <String>[];
    for (final column in columns) {
      final field = column.column;
      final value = _deserializeSwift(
        column,
        '${model.className}Schema.${_swiftIdentifier(_toCamelCase(field.dartName))}',
      );
      fieldInits.add('            ${_swiftIdentifier(field.dartName)}: $value');
    }
    buffer.writeln(fieldInits.join(',\n'));
    buffer.writeln('        )');
    buffer.writeln('    }');
    buffer.writeln('}');

    return buffer.toString();
  }

  String _getSwiftType(NativeColumn column) {
    final swiftType = switch (column.kind) {
      NativeKind.integer => 'Int64',
      NativeKind.real => 'Double',
      NativeKind.text => 'String',
      NativeKind.blob => 'Data',
      NativeKind.boolean => 'Bool',
      NativeKind.dateTime => 'Date',
      NativeKind.duration => 'TimeInterval',
      NativeKind.uri => 'URL',
      NativeKind.enumeration => column.enumName,
    };
    return column.nullable ? '$swiftType?' : swiftType;
  }

  /// Writes `let values: [String: Any?] = [...]` for [columns].
  void _writeValues(
    StringBuffer buffer,
    TableSchemaSnapshot model,
    Iterable<NativeColumn> columns,
  ) {
    if (columns.isEmpty) {
      buffer.writeln('        let values: [String: Any?] = [:]');
      return;
    }
    buffer.writeln('        let values: [String: Any?] = [');
    for (final column in columns) {
      final field = column.column;
      final value = _serializeSwift(
        column,
        'entity.${_swiftIdentifier(field.dartName)}',
      );
      buffer.writeln(
        '            ${model.className}Schema.${_swiftIdentifier(_toCamelCase(field.dartName))}: $value,',
      );
    }
    buffer.writeln('        ]');
  }

  /// Swift expression converting [accessor] to its SQLite storage value.
  String _serializeSwift(NativeColumn column, String accessor) {
    final String Function(String) convert = switch (column.kind) {
      NativeKind.integer ||
      NativeKind.real ||
      NativeKind.text ||
      NativeKind.blob => (v) => v,
      NativeKind.boolean => (v) => '($v ? Int64(1) : Int64(0))',
      NativeKind.dateTime ||
      NativeKind.duration => (v) => 'GeneratedValue.milliseconds($v)',
      NativeKind.uri => (v) => '$v.absoluteString',
      NativeKind.enumeration =>
        column.storesEnumByName ? (v) => '$v.rawValue' : (v) => '$v.ordinal',
    };
    final direct = convert(accessor);
    if (direct == accessor) return accessor;
    return column.nullable ? '$accessor.map { ${convert('\$0')} }' : direct;
  }

  /// Swift expression decoding [column] from `row` (a `GeneratedRow`).
  String _deserializeSwift(NativeColumn column, String columnName) {
    final (converter, expected) = switch (column.kind) {
      NativeKind.integer => ('GeneratedValue.int64', 'Int64'),
      NativeKind.real => ('GeneratedValue.double', 'Double'),
      NativeKind.text => ('GeneratedValue.string', 'String'),
      NativeKind.blob => ('GeneratedValue.data', 'Data'),
      NativeKind.boolean => ('GeneratedValue.bool', 'Bool'),
      NativeKind.dateTime => ('GeneratedValue.date', 'Date'),
      NativeKind.duration => ('GeneratedValue.timeInterval', 'TimeInterval'),
      NativeKind.uri => ('GeneratedValue.url', 'URL'),
      NativeKind.enumeration => (
        column.storesEnumByName
            ? '{ GeneratedValue.string(\$0).flatMap(${column.enumName}.init(rawValue:)) }'
            : '{ GeneratedValue.int64(\$0).flatMap(${column.enumName}.init(ordinal:)) }',
        column.enumName,
      ),
    };
    final method = column.nullable ? 'optional' : 'required';
    return 'try row.$method($columnName, $converter, expected: "$expected")';
  }

  /// Swift string literal for [value].
  String _swiftString(String value) {
    final escaped = value
        .replaceAll(r'\', r'\\')
        .replaceAll('"', r'\"')
        .replaceAll('\n', r'\n');
    return '"$escaped"';
  }

  /// Escapes Swift keywords used as identifiers.
  String _swiftIdentifier(String name) =>
      _swiftKeywords.contains(name) ? '`$name`' : name;

  static const _swiftKeywords = {
    'associatedtype', 'class', 'deinit', 'enum', 'extension', 'fileprivate',
    'func', 'import', 'init', 'inout', 'internal', 'let', 'open', 'operator',
    'private', 'protocol', 'public', 'rethrows', 'static', 'struct',
    'subscript', 'typealias', 'var', 'break', 'case', 'continue', 'default',
    'defer', 'do', 'else', 'fallthrough', 'for', 'guard', 'if', 'in',
    'repeat', 'return', 'switch', 'where', 'while', 'as', 'catch', 'false',
    'is', 'nil', 'self', 'Self', 'super', 'throw', 'throws', 'true', 'try',
  };

  /// Swift counterpart of the generated Dart DatabaseManager: it opens the
  /// database with the same version, statements and migration steps, so it
  /// makes no difference whether Dart or native code opens it first.
  String generateDatabaseManager(NativeDatabaseSpec spec) {
    final buffer = StringBuffer();
    final schemas = spec.tables;

    buffer.writeln('import Foundation');
    buffer.writeln('import native_sqlite_ios');
    buffer.writeln();
    buffer.writeln('/**');
    buffer.writeln(' * Native database manager, mirroring the generated DatabaseManager.dart.');
    buffer.writeln(
      ' * Call DatabaseManager.shared.initialize() from native iOS code',
    );
    buffer.writeln(
      ' * (BGTaskScheduler, App Extensions) before using the generated helpers.',
    );
    buffer.writeln(' * AUTO-GENERATED - DO NOT EDIT MANUALLY');
    buffer.writeln(' */');
    buffer.writeln('public final class DatabaseManager {');
    buffer.writeln('    public static let shared = DatabaseManager()');
    buffer.writeln();
    buffer.writeln('    public static let schemaVersion = ${spec.schemaVersion}');
    buffer.writeln(
      '    public static let defaultDatabaseName = ${_swiftString(spec.databaseName)}',
    );
    buffer.writeln();
    buffer.writeln('    public static let onCreateStatements: [String] = [');
    for (final schema in schemas) {
      buffer.writeln('        ${schema.className}Schema.createTableSql,');
    }
    buffer.writeln('    ] + [');
    for (final schema in schemas) {
      buffer.writeln('        ${schema.className}Schema.indexSql,');
    }
    buffer.writeln(r'    ].flatMap { $0 }');
    buffer.writeln();
    buffer.writeln(
      '    /// Versioned steps: `migrations[v]` upgrades version `v - 1` to `v`.',
    );
    if (spec.migrations.isEmpty) {
      buffer.writeln('    public static let migrations: [Int: [String]] = [:]');
    } else {
      buffer.writeln('    public static let migrations: [Int: [String]] = [');
      for (final MapEntry(key: version, value: sql) in spec.migrations.entries) {
        buffer.writeln('        $version: [');
        for (final statement in sql) {
          buffer.writeln('            ${_swiftString(statement)},');
        }
        buffer.writeln('        ],');
      }
      buffer.writeln('    ]');
    }
    buffer.writeln();
    buffer.writeln(
      '    /// Run after every upgrade: creates any missing table or index.',
    );
    buffer.writeln('    public static let ensureSchemaStatements: [String] = [');
    for (final statement in spec.ensureSchema) {
      buffer.writeln('        ${_swiftString(statement)},');
    }
    buffer.writeln('    ]');
    buffer.writeln();
    buffer.writeln('    public static let tableNames: [String] = [');
    for (final schema in schemas) {
      buffer.writeln('        ${schema.className}Schema.tableName,');
    }
    buffer.writeln('    ]');
    buffer.writeln();
    buffer.writeln('    private let lock = NSLock()');
    buffer.writeln('    private var currentDatabaseName: String?');
    buffer.writeln();
    buffer.writeln('    private init() {}');
    buffer.writeln();
    buffer.writeln('    /**');
    buffer.writeln('     * Opens the database, creating it or applying pending migrations.');
    buffer.writeln('     */');
    buffer.writeln('    public func initialize(');
    buffer.writeln('        name: String = DatabaseManager.defaultDatabaseName,');
    buffer.writeln('        enableWAL: Bool = true,');
    buffer.writeln('        enableForeignKeys: Bool = true');
    buffer.writeln('    ) throws {');
    buffer.writeln('        lock.lock()');
    buffer.writeln('        defer { lock.unlock() }');
    buffer.writeln('        let manager = NativeSqliteManager.shared');
    buffer.writeln(
      '        // Already opened (e.g. by Dart through the plugin, which shares this',
    );
    buffer.writeln(
      '        // manager) with the same generated schema and migrations.',
    );
    buffer.writeln('        if manager.isDatabaseOpen(name: name) {');
    buffer.writeln('            currentDatabaseName = name');
    buffer.writeln('            return');
    buffer.writeln('        }');
    buffer.writeln('        _ = try manager.openDatabase(config: DatabaseConfig(');
    buffer.writeln('            name: name,');
    buffer.writeln('            version: Self.schemaVersion,');
    buffer.writeln('            onCreate: Self.onCreateStatements,');
    buffer.writeln('            onUpgrade: Self.ensureSchemaStatements,');
    buffer.writeln('            enableWAL: enableWAL,');
    buffer.writeln('            enableForeignKeys: enableForeignKeys,');
    buffer.writeln('            migrations: Self.migrations');
    buffer.writeln('        ))');
    buffer.writeln('        currentDatabaseName = name');
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln('    public func close() throws {');
    buffer.writeln('        lock.lock()');
    buffer.writeln('        defer { lock.unlock() }');
    buffer.writeln('        if let name = currentDatabaseName {');
    buffer.writeln('            try NativeSqliteManager.shared.closeDatabase(name: name)');
    buffer.writeln('        }');
    buffer.writeln('        currentDatabaseName = nil');
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln('    public var isInitialized: Bool {');
    buffer.writeln('        lock.lock()');
    buffer.writeln('        defer { lock.unlock() }');
    buffer.writeln('        return currentDatabaseName != nil');
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln('    public var currentDatabase: String {');
    buffer.writeln('        get throws {');
    buffer.writeln('            lock.lock()');
    buffer.writeln('            defer { lock.unlock() }');
    buffer.writeln('            guard let name = currentDatabaseName else {');
    buffer.writeln('                throw NSError(domain: "DatabaseManager", code: -1,');
    buffer.writeln(
      '                    userInfo: [NSLocalizedDescriptionKey: "Call DatabaseManager.shared.initialize() first"])',
    );
    buffer.writeln('            }');
    buffer.writeln('            return name');
    buffer.writeln('        }');
    buffer.writeln('    }');
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

  String _toCamelCase(String input) {
    if (input.isEmpty) return input;
    return input[0].toLowerCase() + input.substring(1);
  }
}
