# Generator example

Add `native_sqlite_generator` and `build_runner` as development dependencies,
then enable the builders with one shared option anchor:

```yaml
targets:
  $default:
    builders:
      native_sqlite_generator:table:
        options: &native_sqlite_options
          table_name_case: snake
          column_name_case: snake
      native_sqlite_generator:migration:
        options: *native_sqlite_options
      native_sqlite_generator:schema_registry:
        options: *native_sqlite_options
```

Run `flutter pub run build_runner build`. Generated `.table.dart` files,
schema history, and configured Kotlin/Swift helpers are replaced on each run.
