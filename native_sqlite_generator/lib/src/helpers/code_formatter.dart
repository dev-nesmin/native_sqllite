import 'package:dart_style/dart_style.dart';
import 'package:pub_semver/pub_semver.dart';

/// Utility for formatting generated Dart code.
///
/// This wrapper around DartFormatter provides safe formatting
/// with proper error handling.
class CodeFormatter {
  final DartFormatter _formatter;
  final bool enabled;

  /// Creates a new code formatter.
  ///
  /// [enabled] - Whether formatting is enabled (default: true)
  /// [pageWidth] - Maximum line width (default: 80)
  CodeFormatter({
    this.enabled = true,
    int? pageWidth,
  }) : _formatter = DartFormatter(
          pageWidth: pageWidth ?? 80,
          languageVersion: Version(3, 6, 0), // Use current Dart version
        );

  /// Formats the given Dart code.
  ///
  /// If formatting fails, returns the unformatted code and prints a warning.
  /// If [enabled] is false, returns the code as-is.
  String format(String code) {
    if (!enabled) return code;

    try {
      return _formatter.format(code);
    } on FormatterException catch (e) {
      print('⚠️  Format error: ${e.message()}');
      print('   Returning unformatted code');
      return code;
    } catch (e) {
      print('⚠️  Unexpected format error: $e');
      return code;
    }
  }

  /// Formats multiple code strings.
  ///
  /// This is useful when generating multiple files or sections.
  List<String> formatMultiple(List<String> codes) {
    return codes.map(format).toList();
  }
}
