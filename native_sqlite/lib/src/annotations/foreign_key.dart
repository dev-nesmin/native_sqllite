part of native_sqlite;

/// Annotation to define a foreign key relationship.
class ForeignKey {
  /// The table this foreign key references.
  final String table;

  /// The column in the referenced table.
  final String column;

  /// Action to take when the referenced row is deleted.
  /// Examples: 'CASCADE', 'SET NULL', 'RESTRICT', 'NO ACTION'
  final String? onDelete;

  /// Action to take when the referenced row is updated.
  /// Examples: 'CASCADE', 'SET NULL', 'RESTRICT', 'NO ACTION'
  final String? onUpdate;

  const ForeignKey({
    required this.table,
    required this.column,
    this.onDelete,
    this.onUpdate,
  });
}
