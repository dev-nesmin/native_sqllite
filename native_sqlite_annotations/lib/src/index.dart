import 'package:meta/meta_meta.dart';

/// Annotation to create an index on specific columns.
@Target({TargetKind.classType})
class Index {
  /// The name of the index. If not specified, a name will be generated.
  final String? name;

  /// The columns to include in the index.
  final List<String> columns;

  /// Whether the index should enforce uniqueness.
  final bool unique;

  /// Creates an index over [columns].
  const Index({this.name, required this.columns, this.unique = false});
}
