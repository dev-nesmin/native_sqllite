# native_sqlite_annotations

Annotation definitions for the `native_sqlite` plugin. Import this package in your model files to access all annotations.

You typically do **not** need to import this package directly — it is re-exported by `package:native_sqlite/native_sqlite.dart`.

---

## All Annotations

| Annotation | Target | Purpose |
|------------|--------|---------|
| [`@DbTable`](#dbtable) | Class | Mark class as a database table |
| [`@PrimaryKey`](#primarykey) | Field | Mark field as primary key |
| [`@DbColumn`](#dbcolumn) | Field | Customise column mapping |
| [`@ForeignKey`](#foreignkey) | Field | Define foreign key relationship |
| [`@Index`](#index) | Field | Create an index on a column |
| [`@EnumField`](#enumfield) | Field | Control enum storage strategy |
| [`@UseConverter`](#useconverter) | Field | Attach a custom type converter |
| [`@JsonField`](#jsonfield) | Field | Store field as JSON text |
| [`@Ignore`](#ignore) | Field | Exclude field from database |

---

## `@DbTable`

Marks a class as a database table. Every class that should be persisted must have this annotation.

```dart
@DbTable(
  name: 'orders',           // optional — defaults to class name in snake_case
  database: 'shop_db',      // optional — defaults to build.yaml default_database
  indexes: [                // optional — each inner list is one index
    ['user_id', 'status'],  // composite index on two columns
    ['created_at'],         // single-column index
  ],
  auto: true,               // optional — include in auto-generated DatabaseManager
)
class Order { ... }
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | `String?` | Class name → snake_case | SQL table name |
| `database` | `String?` | `build.yaml` `default_database` | Database file this table lives in |
| `indexes` | `List<List<String>>?` | `null` | Table-level indexes; each inner list is a column list for one index |
| `auto` | `bool` | `true` | When `true` the generator includes this table in `DatabaseManager` |

> **Note:** Set `auto: false` if you want to manage this table's schema manually (e.g. a system table that is created by native code).

---

## `@PrimaryKey`

Marks a field as the table's primary key. Every `@DbTable` class must have exactly one field annotated with `@PrimaryKey`.

```dart
// Integer auto-increment (most common)
@PrimaryKey(autoIncrement: true)
final int? id;

// UUID string primary key (generated on insert by the repository)
@PrimaryKey(useLocalUuid: true)
final String id;

// Manual integer key (you supply the value on insert)
@PrimaryKey()
final int id;
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `autoIncrement` | `bool` | `false` | Add `AUTOINCREMENT` to the column. Only valid for `int?` fields. |
| `useLocalUuid` | `bool` | `false` | Let the repository generate a UUID string before inserting. Only valid for `String` fields. |

> Do not combine `autoIncrement: true` and `useLocalUuid: true`.

---

## `@DbColumn`

Customises how a field is mapped to a database column. All parameters are optional — an un-annotated field uses sensible defaults inferred from the Dart type.

```dart
@DbColumn(
  name: 'email_addr',          // override column name
  nullable: false,             // override nullability
  unique: true,                // add UNIQUE constraint
  defaultValue: "'unknown'",   // SQL default expression
  type: 'TEXT',                // override SQLite type
)
final String email;
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | `String?` | Field name → snake_case | SQL column name |
| `nullable` | `bool?` | Inferred from `Type?` | `true` → column allows NULL |
| `unique` | `bool` | `false` | Add `UNIQUE` constraint |
| `defaultValue` | `String?` | `null` | SQL default expression. String values need extra quotes: `"'hello'"`. Numeric: `'0'`. |
| `type` | `String?` | Inferred | Override SQLite affinity: `'TEXT'`, `'INTEGER'`, `'REAL'`, `'BLOB'` |
| `ignore` | `bool` | `false` | Equivalent to adding `@Ignore()` |

**Type inference table:**

| Dart type | Default SQLite type |
|-----------|-------------------|
| `int` | `INTEGER` |
| `double`, `num` | `REAL` |
| `String` | `TEXT` |
| `bool` | `INTEGER` (0/1) |
| `DateTime` | `INTEGER` (milliseconds since epoch) |
| `Duration` | `INTEGER` (milliseconds) |
| `Uri` | `TEXT` |
| `Uint8List` | `BLOB` |

---

## `@ForeignKey`

Defines a foreign key relationship. Must be combined with `@DbColumn`.

```dart
@ForeignKey(
  table: 'users',        // referenced table
  column: 'id',          // referenced column
  onDelete: 'CASCADE',   // optional
  onUpdate: 'CASCADE',   // optional
)
@DbColumn(nullable: false)
final int userId;
```

**Parameters:**

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `table` | `String` | Yes | Name of the referenced table |
| `column` | `String` | Yes | Name of the referenced column |
| `onDelete` | `String?` | No | `'CASCADE'`, `'SET NULL'`, `'SET DEFAULT'`, `'RESTRICT'`, `'NO ACTION'` |
| `onUpdate` | `String?` | No | Same options as `onDelete` |

> **Tip:** Foreign keys require `enableForeignKeys: true` in `DatabaseConfig` (the default). Consider adding an `@Index` on the FK field for better query performance — the `analyze` CLI command will warn you if it is missing.

---

## `@Index`

Creates a dedicated index on one or more columns. Useful for columns frequently used in `WHERE` or `ORDER BY` clauses.

```dart
@Index(columns: ['email'], unique: true)
@DbColumn(nullable: false)
final String email;

// Multi-column index on a field
@Index(columns: ['last_name', 'first_name'], name: 'idx_full_name')
@DbColumn()
final String lastName;
```

**Parameters:**

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `columns` | `List<String>` | required | Column names to include in the index |
| `name` | `String?` | Auto-generated: `idx_<table>_<columns>` | Custom index name |
| `unique` | `bool` | `false` | Unique index (enforces uniqueness across the column combination) |

> **Tip:** For simple single-column indexes you can also use the `indexes` parameter on `@DbTable`:
> ```dart
> @DbTable(indexes: [['email'], ['created_at']])
> ```

---

## `@EnumField`

Controls how an enum field is serialised for storage. Must be combined with `@DbColumn`.

```dart
enum UserStatus { active, inactive, suspended }

// Store as integer index (0=active, 1=inactive, 2=suspended) — default
@EnumField(type: EnumType.ordinal)
@DbColumn()
final UserStatus status;

// Store as string name ('active', 'inactive', ...)
@EnumField(type: EnumType.name)
@DbColumn()
final UserStatus status;

// Store as custom value (requires @EnumValue on each enum member)
@EnumField(type: EnumType.value)
@DbColumn()
final UserStatus status;
```

**`EnumType` values:**

| Value | Storage | Example |
|-------|---------|---------|
| `EnumType.ordinal` | `INTEGER` | `UserStatus.inactive` → `1` |
| `EnumType.name` | `TEXT` | `UserStatus.inactive` → `'inactive'` |
| `EnumType.value` | Depends on `@EnumValue` | `UserStatus.inactive` → your custom value |

**`@EnumValue` (for `EnumType.value` only):**

```dart
enum Priority {
  @EnumValue('LOW')    low,
  @EnumValue('MEDIUM') medium,
  @EnumValue('HIGH')   high,
}
```

---

## `@UseConverter`

Attaches a custom `TypeConverter<DartType, SqlType>` to a field for types not natively supported.

```dart
// 1. Define the converter
class ColorConverter extends TypeConverter<Color, int> {
  const ColorConverter();

  @override
  int toSql(Color value) => value.value;

  @override
  Color fromSql(int sqlValue) => Color(sqlValue);
}

// 2. Use it on the field
@UseConverter(ColorConverter())
@DbColumn(type: 'INTEGER')
final Color backgroundColor;
```

**`TypeConverter<DartType, SqlType>` interface:**

| Method | Description |
|--------|-------------|
| `SqlType toSql(DartType value)` | Convert Dart value → SQLite value |
| `DartType fromSql(SqlType sqlValue)` | Convert SQLite value → Dart value |

`SqlType` must be one of: `int`, `double`, `String`, or `Uint8List`.

---

## `@JsonField`

Stores a field as a JSON-encoded `TEXT` column. The generator emits `jsonEncode`/`jsonDecode` calls in the repository's `_fromMap` and `insert`/`update` methods.

```dart
// Map
@JsonField()
@DbColumn(type: 'TEXT')
final Map<String, dynamic> metadata;

// List
@JsonField()
@DbColumn(type: 'TEXT')
final List<String> tags;

// Custom class (must have toJson() and a fromJson() named constructor/factory)
@JsonField()
@DbColumn(type: 'TEXT')
final Address? billingAddress;
```

**Supported Dart types:**
- `Map<String, dynamic>`
- `List<dynamic>` / `List<T>`
- Any class with `toJson()` returning `Map<String, dynamic>` and a `fromJson(Map<String, dynamic>)` constructor

---

## `@Ignore`

Excludes a field from code generation. The field is not mapped to any database column and will not appear in INSERT, UPDATE, or SELECT statements.

```dart
@Ignore()
String? cachedDisplayName;   // computed at runtime, not stored

@Ignore()
final SomeService _service;  // injected dependency
```

> Alternatively, you can use `@DbColumn(ignore: true)` for the same effect.
