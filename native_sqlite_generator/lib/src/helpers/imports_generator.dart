import 'package:native_sqlite_generator/src/config/generator_options.dart';
import 'package:native_sqlite_generator/src/models/table_info.dart';

/// Generates import statements for generated files.
class ImportsGenerator {
  /// Generates all necessary imports for a generated table file.
  ///
  /// This includes:
  /// - Part-of directive (required for Dart part files)
  /// - NOTE: Part files CANNOT have import statements!
  ///   The parent file must import 'package:native_sqlite/native_sqlite.dart'
  ///
  /// [options] - Generator configuration options
  /// [libraryName] - The library name for the part-of directive (e.g., 'user.dart')
  /// [tableInfo] - Table information for the generated file
  static String generate(
    GeneratorOptions options,
    String libraryName,
    TableInfo tableInfo,
  ) {
    final buffer = StringBuffer();

    // Add part-of directive (required for all generated .table.dart files)
    // Part files cannot have imports - all imports must be in the parent library
    buffer.writeln("part of '$libraryName';");
    buffer.writeln();

    return buffer.toString();
  }
}
