import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'src/table_generator.dart';

/// Creates a builder for generating table schemas and repositories.
Builder tableBuilder(BuilderOptions options) {
  return SharedPartBuilder(
    [TableGenerator()],
    'table',
  );
}
