# native_sqlite walkthrough

Add `native_sqlite` to dependencies and `native_sqlite_generator` plus
`build_runner` to dev dependencies. Define a model in `lib/task.dart`:

```dart
import 'package:native_sqlite/native_sqlite.dart';

part 'task.table.dart';

@DbTable(name: 'tasks', indexes: [['done']])
class Task {
  const Task({this.id, required this.title, this.done = false});

  @PrimaryKey(autoIncrement: true)
  final int? id;

  @DbColumn(nullable: false)
  final String title;

  @DbColumn(nullable: false, defaultValue: '0')
  final bool done;
}
```

Generate the table schema, repository, query builder, database manager, and
optional native helpers:

```sh
flutter pub run build_runner build
```

Open the generated database manager once during application startup:

```dart
await DatabaseManager.init();
final database = DatabaseManager.currentDatabase;
final tasks = TaskRepository(database);
```

Generated repositories provide typed CRUD methods:

```dart
final id = await tasks.insert(const Task(title: 'Ship native_sqlite'));
final task = await tasks.findById(id);
await tasks.update(Task(id: id, title: task!.title, done: true));
```

Generated query builders bind values and expose the generated SQL for
debugging:

```dart
final query = TaskQueryBuilder(database)
  ..doneEqualTo(false)
  ..sortByTitleAsc()
  ..limit(20);

final pending = await query.findAll();
print(query.toSql());
```

Set `generate_native: true` and the Android/iOS output paths in
`native_sqlite_config.yaml` to generate helpers for the same database. Kotlin
code can then write while Flutter is not running:

```kotlin
DatabaseManager.init(context)
val tasks = TaskHelper(DatabaseManager.currentDatabase)
tasks.insert(Task(title = "Created by Kotlin", done = false))
```

Swift uses the same generated schema and migration version:

```swift
try DatabaseManager.shared.initialize()
let tasks = TaskHelper(
  databaseName: try DatabaseManager.shared.currentDatabase
)
_ = try tasks.insert(Task(title: "Created by Swift", done: false))
```

Schema history is versioned and the generated Dart, Kotlin, and Swift managers
apply identical ordered migration steps. Keep committed schema snapshots;
never edit or delete old versions by hand. The explicit migration-creation
workflow is being finalized before 0.1.0, so follow the migration guide shipped
with the release rather than relying on intermediate watch-mode builds.

The full Android, iOS, and web application is maintained in the repository's
top-level `example/` directory until the final published location is approved.
