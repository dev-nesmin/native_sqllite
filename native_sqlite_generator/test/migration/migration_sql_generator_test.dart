import 'package:native_sqlite_generator/src/migration/migration_sql_generator.dart';
import 'package:native_sqlite_generator/src/models/schema_snapshot.dart';
import 'package:native_sqlite_generator/src/sql/schema_sql.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:test/test.dart';

ColumnSchemaSnapshot col(
  String name,
  String type, {
  bool nullable = false,
  bool primaryKey = false,
  bool unique = false,
  String? defaultValue,
  String? foreignKey,
}) => ColumnSchemaSnapshot(
  dartName: name,
  name: name,
  type: type,
  nullable: nullable,
  primaryKey: primaryKey,
  autoIncrement: primaryKey,
  unique: unique,
  defaultValue: defaultValue,
  foreignKey: foreignKey,
  foreignKeyOnDelete: foreignKey == null ? null : 'CASCADE',
  isJsonField: false,
  hasConverter: false,
  dartType: type == 'INTEGER' ? 'int' : 'String',
);

final id = col('id', 'INTEGER', nullable: true, primaryKey: true);

TableSchemaSnapshot table(
  String name,
  List<ColumnSchemaSnapshot> columns, [
  List<IndexSchemaSnapshot> indexes = const [],
]) => TableSchemaSnapshot.fromTableInfo(name, name, columns, indexes, 1);

Database create(List<TableSchemaSnapshot> tables) {
  final db = sqlite3.openInMemory();
  for (final t in tables) {
    db.execute(SchemaSql.createTable(t));
    SchemaSql.createIndexes(t).forEach(db.execute);
  }
  return db;
}

/// Applies [sql] the way the Android/iOS/web runtimes do.
void migrate(Database db, List<String> sql) {
  db.execute('PRAGMA foreign_keys = OFF');
  db.execute('BEGIN IMMEDIATE');
  sql.forEach(db.execute);
  expect(db.select('PRAGMA foreign_key_check'), isEmpty);
  db.execute('COMMIT');
  db.execute('PRAGMA foreign_keys = ON');
}

/// Structural description of [tableName], independent of the SQL text.
Map<String, Object?> describe(Database db, String tableName) {
  List<Map<String, Object?>> rows(String sql) => [
    for (final row in db.select(sql)) {...row},
  ];
  final indexes = rows("PRAGMA index_list('$tableName')")
      .where((i) => i['origin'] == 'c')
      .map(
        (i) => {
          'name': i['name'],
          'unique': i['unique'],
          'columns': rows(
            "PRAGMA index_info('${i['name']}')",
          ).map((c) => c['name']).toList(),
        },
      )
      .toList()
    ..sort((a, b) => '${a['name']}'.compareTo('${b['name']}'));
  // ALTER TABLE ADD COLUMN appends, so column order may differ from a fresh
  // table; generated code reads columns by name, so compare them unordered.
  final columns = rows("PRAGMA table_info('$tableName')")
      .map((c) => {...c}..remove('cid'))
      .toList()
    ..sort((a, b) => '${a['name']}'.compareTo('${b['name']}'));
  return {
    'columns': columns,
    'indexes': indexes,
    'foreignKeys': rows("PRAGMA foreign_key_list('$tableName')"),
    'uniqueConstraints': rows(
      "PRAGMA index_list('$tableName')",
    ).where((i) => i['origin'] == 'u').length,
  };
}

/// Migrates a database from [before] to [after], checking that the result
/// is identical to a freshly created [after] and returning the database.
Database migrateAndCompare(
  TableSchemaSnapshot before,
  TableSchemaSnapshot after, {
  void Function(Database db)? seed,
  List<TableSchemaSnapshot> others = const [],
}) {
  final db = create([...others, before]);
  seed?.call(db);
  migrate(db, MigrationSqlGenerator.changeTable(before, after).sql);
  final fresh = create([...others, after]);
  expect(describe(db, after.tableName), describe(fresh, after.tableName));
  return db;
}

void main() {
  final users = table('users', [id, col('name', 'TEXT')], const [
    IndexSchemaSnapshot(columns: ['name'], unique: false, name: 'idx_users_name'),
  ]);

  void seedUsers(Database db) {
    db.execute("INSERT INTO users (name) VALUES ('ada'), ('grace')");
  }

  List<String> names(Database db) =>
      db.select('SELECT name FROM users ORDER BY id').map((r) => r['name'] as String).toList();

  test('adds a nullable column with ALTER TABLE, keeping data', () {
    final after = table('users', [...users.columns, col('bio', 'TEXT', nullable: true)], users.indexes);
    final migration = MigrationSqlGenerator.changeTable(users, after);
    expect(migration.sql, ['ALTER TABLE users ADD COLUMN bio TEXT']);

    final db = migrateAndCompare(users, after, seed: seedUsers);
    expect(names(db), ['ada', 'grace']);
  });

  test('adds a NOT NULL column that has a default with ALTER TABLE', () {
    final after = table('users', [
      ...users.columns,
      col('age', 'INTEGER', defaultValue: '0'),
    ], users.indexes);
    final db = migrateAndCompare(users, after, seed: seedUsers);
    expect(db.select('SELECT age FROM users').map((r) => r['age']), [0, 0]);
  });

  test('rebuilds for a UNIQUE column and keeps data and indexes', () {
    final after = table('users', [
      ...users.columns,
      col('email', 'TEXT', nullable: true, unique: true),
    ], users.indexes);
    final migration = MigrationSqlGenerator.changeTable(users, after);
    expect(migration.sql.first, startsWith('CREATE TABLE users_new'));

    final db = migrateAndCompare(users, after, seed: seedUsers);
    expect(names(db), ['ada', 'grace']);
  });

  test('rebuilds when a column is removed and warns about its data', () {
    final before = table('users', [...users.columns, col('legacy', 'TEXT', nullable: true)], users.indexes);
    final migration = MigrationSqlGenerator.changeTable(before, users);
    expect(migration.warnings.single, contains('legacy'));

    final db = migrateAndCompare(before, users, seed: seedUsers);
    expect(names(db), ['ada', 'grace']);
  });

  test('rebuilds when a column type or nullability changes', () {
    final after = table('users', [id, col('name', 'TEXT', nullable: true)], users.indexes);
    migrateAndCompare(users, after, seed: seedUsers);
  });

  test('rejects a NOT NULL column without default at build time', () {
    final after = table('users', [
      id,
      col('name', 'TEXT', unique: true),
      col('country', 'TEXT'),
    ]);
    expect(
      () => MigrationSqlGenerator.changeTable(users, after),
      throwsA(isA<MigrationException>()),
    );
  });

  test('drops, changes and creates indexes without rebuilding', () {
    final after = table('users', users.columns, const [
      IndexSchemaSnapshot(columns: ['name'], unique: true, name: 'idx_users_name'),
      IndexSchemaSnapshot(columns: ['id', 'name'], unique: false, name: 'idx_users_both'),
    ]);
    final migration = MigrationSqlGenerator.changeTable(users, after);
    expect(migration.sql, [
      'DROP INDEX IF EXISTS idx_users_name',
      'CREATE UNIQUE INDEX idx_users_name ON users (name)',
      'CREATE INDEX idx_users_both ON users (id, name)',
    ]);
    migrateAndCompare(users, after, seed: seedUsers);
  });

  test('rebuilding a parent table keeps child rows (no cascade)', () {
    final orders = table('orders', [
      id,
      col('user_id', 'INTEGER', foreignKey: 'users.id'),
    ]);
    final after = table('users', [
      ...users.columns,
      col('email', 'TEXT', nullable: true, unique: true),
    ], users.indexes);

    final db = migrateAndCompare(
      users,
      after,
      others: [orders],
      seed: (db) {
        seedUsers(db);
        db.execute('INSERT INTO orders (user_id) VALUES (1), (2)');
      },
    );
    expect(db.select('SELECT COUNT(*) AS n FROM orders').single['n'], 2);
  });

  test('adds a foreign key by rebuilding the child table', () {
    final before = table('orders', [id, col('user_id', 'INTEGER')]);
    final after = table('orders', [
      id,
      col('user_id', 'INTEGER', foreignKey: 'users.id'),
    ]);
    migrateAndCompare(before, after, others: [users]);
  });

  test('creates new tables with their indexes', () {
    final db = sqlite3.openInMemory();
    migrate(db, MigrationSqlGenerator.createTable(users).sql);
    expect(describe(db, 'users'), describe(create([users]), 'users'));
  });
}
