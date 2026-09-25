/// Cross-platform SQLite handles, transactions, generated-code annotations,
/// and the debug-only DevTools inspector connection.
library;

export 'package:native_sqlite_annotations/native_sqlite_annotations.dart';
export 'package:native_sqlite_platform_interface/native_sqlite_platform_interface.dart'
    show DatabaseConfig, NativeSqliteException, QueryResult, TypedRow;

export 'src/auto_migration.dart';
export 'src/codec.dart';
export 'src/desktop/native_sqlite_desktop_stub.dart'
    if (dart.library.io) 'src/desktop/native_sqlite_desktop.dart';
export 'inspector_protocol.dart';
export 'src/inspector_connect.dart' show InspectorConnect;
export 'src/native_sqlite.dart';
export 'src/uuid.dart';
