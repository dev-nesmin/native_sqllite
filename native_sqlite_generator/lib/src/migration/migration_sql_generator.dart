import 'package:native_sqlite_generator/src/models/schema_snapshot.dart';
import 'package:native_sqlite_generator/src/sql/schema_sql.dart';

/// SQL that migrates one table between two schema versions.
class TableMigration {
  const TableMigration({
    required this.sql,
    required this.summary,
    this.warnings = const [],
  });

  final List<String> sql;
  final String summary;

  /// Consequences worth surfacing at build time (e.g. dropped column data).
  final List<String> warnings;

  Map<String, dynamic> toJson() => {
    'sql': sql,
    'summary': summary,
    if (warnings.isNotEmpty) 'warnings': warnings,
  };
}

/// A schema change that cannot be migrated safely on existing databases.
class MigrationException implements Exception {
  MigrationException(this.message);

  final String message;

  @override
  String toString() => 'MigrationException: $message';
}

/// Generates the SQL that brings an existing table to a new schema.
///
/// Statements run inside the platform's migration transaction with foreign
/// keys disabled (see `DatabaseConfig.migrations`), following SQLite's
/// recommended procedure for schema changes ALTER TABLE can't express.
/// Every CREATE statement comes from [SchemaSql], so a migrated table is
/// identical to a freshly created one.
class MigrationSqlGenerator {
  MigrationSqlGenerator._();

  /// A table added in this version.
  static TableMigration createTable(TableSchemaSnapshot table) {
    return TableMigration(
      sql: [SchemaSql.createTable(table), ...SchemaSql.createIndexes(table)],
      summary: 'Created table',
    );
  }

  /// A table whose schema changed from [previous] to [current].
  ///
  /// Throws [MigrationException] when existing rows could not satisfy the
  /// new schema (a new NOT NULL column without a default).
  static TableMigration changeTable(
    TableSchemaSnapshot previous,
    TableSchemaSnapshot current,
  ) {
    final table = current.tableName;
    final oldColumns = {for (final c in previous.columns) c.name: c};
    final newColumns = {for (final c in current.columns) c.name: c};

    final added = [
      for (final c in current.columns)
        if (!oldColumns.containsKey(c.name)) c,
    ];
    final removed = [
      for (final c in previous.columns)
        if (!newColumns.containsKey(c.name)) c.name,
    ];
    final modified = [
      for (final c in current.columns)
        if (oldColumns[c.name] case final old? when _columnChanged(old, c))
          c.name,
    ];

    final summary = <String>[
      if (added.isNotEmpty) 'Added columns: ${added.map((c) => c.name).join(', ')}',
      if (removed.isNotEmpty) 'Removed columns: ${removed.join(', ')}',
      if (modified.isNotEmpty) 'Changed columns: ${modified.join(', ')}',
    ];
    final warnings = <String>[
      if (removed.isNotEmpty)
        '$table: data in removed column(s) ${removed.join(', ')} is deleted. '
            'A renamed column is treated as removed + added.',
      for (final name in modified)
        if (oldColumns[name]!.nullable &&
            !newColumns[name]!.nullable &&
            newColumns[name]!.defaultValue == null)
          '$table.$name became NOT NULL: the migration fails on devices '
              'where it contains NULL values.',
    ];

    final canAlter =
        removed.isEmpty && modified.isEmpty && added.every(_canAddColumn);

    final sql = <String>[];
    if (canAlter) {
      for (final column in added) {
        sql.add(_addColumn(table, column));
      }
      final indexChanges = _indexChanges(previous, current);
      sql.addAll(indexChanges.sql);
      summary.addAll(indexChanges.summary);
    } else {
      for (final column in added) {
        if (!column.nullable &&
            column.defaultValue == null &&
            !(column.primaryKey && column.autoIncrement)) {
          throw MigrationException(
            'Cannot add NOT NULL column "$table.${column.name}" without a '
            'default value: existing rows would have no value for it. Make it '
            'nullable or give it a defaultValue in @DbColumn.',
          );
        }
      }
      sql.addAll(_rebuildTable(current, oldColumns.keys.toSet()));
      summary.add('Rebuilt table');
    }

    return TableMigration(
      sql: sql,
      summary: summary.isEmpty ? 'Schema updated' : summary.join('; '),
      warnings: warnings,
    );
  }

  static bool _columnChanged(ColumnSchemaSnapshot a, ColumnSchemaSnapshot b) {
    return a.type != b.type ||
        a.nullable != b.nullable ||
        a.primaryKey != b.primaryKey ||
        a.autoIncrement != b.autoIncrement ||
        a.unique != b.unique ||
        a.defaultValue != b.defaultValue ||
        a.foreignKey != b.foreignKey ||
        a.foreignKeyOnDelete != b.foreignKeyOnDelete ||
        a.foreignKeyOnUpdate != b.foreignKeyOnUpdate;
  }

  /// SQLite's ALTER TABLE ADD COLUMN can't add PRIMARY KEY, UNIQUE or
  /// REFERENCES columns, nor NOT NULL columns without a default.
  static bool _canAddColumn(ColumnSchemaSnapshot column) {
    return !column.primaryKey &&
        !column.unique &&
        column.foreignKey == null &&
        (column.nullable || column.defaultValue != null);
  }

  static String _addColumn(String table, ColumnSchemaSnapshot column) {
    final parts = ['ALTER TABLE $table ADD COLUMN ${column.name} ${column.type}'];
    if (!column.nullable) parts.add('NOT NULL');
    if (column.defaultValue != null) parts.add('DEFAULT ${column.defaultValue}');
    return parts.join(' ');
  }

  /// SQLite's 12-step table rebuild: create the new shape, copy the columns
  /// both versions share, swap the tables and recreate the indexes (which
  /// are dropped with the old table).
  static List<String> _rebuildTable(
    TableSchemaSnapshot current,
    Set<String> previousColumnNames,
  ) {
    final table = current.tableName;
    final temp = '${table}_new';
    final shared = [
      for (final c in current.columns)
        if (previousColumnNames.contains(c.name)) c.name,
    ].join(', ');
    return [
      SchemaSql.createTable(current, name: temp),
      if (shared.isNotEmpty)
        'INSERT INTO $temp ($shared) SELECT $shared FROM $table',
      'DROP TABLE $table',
      'ALTER TABLE $temp RENAME TO $table',
      ...SchemaSql.createIndexes(current),
    ];
  }

  static ({List<String> sql, List<String> summary}) _indexChanges(
    TableSchemaSnapshot previous,
    TableSchemaSnapshot current,
  ) {
    String signature(IndexSchemaSnapshot i) =>
        '${i.unique}:${i.columns.join(',')}';
    final before = {
      for (final i in previous.indexes)
        SchemaSql.indexName(previous.tableName, i): i,
    };
    final after = {
      for (final i in current.indexes)
        SchemaSql.indexName(current.tableName, i): i,
    };

    final sql = <String>[];
    final summary = <String>[];
    for (final MapEntry(key: name, value: index) in before.entries) {
      final replacement = after[name];
      if (replacement == null || signature(replacement) != signature(index)) {
        sql.add('DROP INDEX IF EXISTS $name');
        summary.add('Dropped index $name');
      }
    }
    for (final MapEntry(key: name, value: index) in after.entries) {
      final existing = before[name];
      if (existing == null || signature(existing) != signature(index)) {
        sql.add(SchemaSql.createIndex(current.tableName, index));
        summary.add('Created index $name');
      }
    }
    return (sql: sql, summary: summary);
  }
}
