import 'package:flutter/services.dart';

/// A SQLite engine error reported consistently by every native_sqlite backend.
///
/// [sql] contains the statement shape only. Bound parameter values are never
/// included, so this exception can be logged without disclosing user data.
final class NativeSqliteException implements Exception {
  /// Creates a structured SQLite exception.
  const NativeSqliteException({
    required this.resultCode,
    required this.extendedResultCode,
    required this.message,
    this.sql,
  });

  /// The primary SQLite result code (the low byte of [extendedResultCode]).
  final int resultCode;

  /// The extended SQLite result code.
  final int extendedResultCode;

  /// SQLite's diagnostic message, without bound parameter values.
  final String message;

  /// The SQL statement that failed, when known.
  final String? sql;

  /// Whether this is any `SQLITE_CONSTRAINT` error.
  bool get isConstraintViolation => resultCode == 19;

  /// Whether a UNIQUE constraint rejected the operation.
  bool get isUniqueViolation => extendedResultCode == 2067;

  /// Whether a NOT NULL constraint rejected the operation.
  bool get isNotNullViolation => extendedResultCode == 1299;

  /// Whether a FOREIGN KEY constraint rejected the operation.
  bool get isForeignKeyViolation => extendedResultCode == 787;

  /// Whether SQLite rejected invalid SQL syntax.
  bool get isSyntaxError => resultCode == 1;

  /// Converts the structured error details sent over a Flutter method channel.
  factory NativeSqliteException.fromPlatformException(
    PlatformException error, {
    String? sql,
  }) {
    final details = error.details;
    final map = details is Map ? details : const <Object?, Object?>{};
    final extended = map['extendedCode'];
    final primary = map['code'];
    final extendedCode = extended is int
        ? extended
        : primary is int
        ? primary
        : 1;
    return NativeSqliteException(
      resultCode: primary is int ? primary : extendedCode & 0xff,
      extendedResultCode: extendedCode,
      message: error.message ?? 'SQLite operation failed',
      sql: map['sql'] is String ? map['sql'] as String : sql,
    );
  }

  @override
  String toString() {
    final statement = sql == null ? '' : '\n  SQL: $sql';
    return 'NativeSqliteException($extendedResultCode): $message$statement';
  }
}
