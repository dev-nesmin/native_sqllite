import 'dart:convert' as convert;
import 'dart:typed_data';

/// Runtime codecs used by generated part files.
///
/// Keeping SDK-library references behind this public helper means a model
/// library does not need imports solely for generated code.
abstract final class NativeSqliteCodec {
  /// Encodes [value] as JSON text.
  static String jsonEncode(Object? value) => convert.jsonEncode(value);

  /// Decodes JSON [source].
  static dynamic jsonDecode(String source) => convert.jsonDecode(source);

  /// Checks and exposes a SQLite BLOB without requiring generated part files
  /// to add their own `dart:typed_data` import.
  static Uint8List asBlob(Object? value) => value as Uint8List;
}
