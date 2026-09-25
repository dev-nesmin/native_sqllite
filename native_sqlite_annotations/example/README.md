# Annotation example

```dart
@DbTable(name: 'notes', indexes: [['created_at']])
class Note {
  const Note({this.id, required this.body, required this.createdAt});

  @PrimaryKey(autoIncrement: true)
  final int? id;
  final String body;
  final DateTime createdAt;
}
```

Use these annotations through `package:native_sqlite/native_sqlite.dart` in a
Flutter app and run `flutter pub run build_runner build`.
