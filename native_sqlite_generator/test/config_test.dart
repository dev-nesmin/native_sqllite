import 'package:native_sqlite_generator/src/config.dart';
import 'package:test/test.dart';

void main() {
  group('NativeSqliteConfig', () {
    test('parses and validates a complete configuration', () {
      final config = NativeSqliteConfig.parse('''
native_sqlite:
  generate_native: true
  database_name: app_db
  include_examples: false
  native_type_prefix: App
  android:
    enabled: true
    output_path: android/generated
    package: com.example.generated
    generate_helpers: false
  ios:
    enabled: true
    output_path: ios/Generated
    generate_helpers: false
''')!;

      expect(config.generateNative, isTrue);
      expect(config.databaseName, 'app_db');
      expect(config.includeExamples, isFalse);
      expect(config.nativeTypePrefix, 'App');
      expect(config.android.package, 'com.example.generated');
      expect(config.android.generateHelpers, isFalse);
      expect(config.ios.outputPath, 'ios/Generated');
    });

    test('ignores a dependency named native_sqlite in pubspec content', () {
      expect(
        NativeSqliteConfig.parse('''
name: sample
dependencies:
  native_sqlite: ^1.0.0
'''),
        isNull,
      );
    });

    test('reports empty dedicated configuration', () {
      expect(
        () => NativeSqliteConfig.parse(
          '',
          source: 'native_sqlite_config.yaml',
          requireNativeSqlite: true,
        ),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('is empty'),
          ),
        ),
      );
    });

    test('rejects unused, unknown, and mistyped options', () {
      expect(
        () => NativeSqliteConfig.parse('''
native_sqlite:
  models: [lib/models/*.dart]
'''),
        throwsFormatException,
      );
      expect(
        () => NativeSqliteConfig.parse('''
native_sqlite:
  generate_native: yes
'''),
        throwsFormatException,
      );
      expect(
        () => NativeSqliteConfig.parse('''
native_sqlite:
  native_type_prefix: bad-prefix
'''),
        throwsFormatException,
      );
      expect(
        () => NativeSqliteConfig.parse('''
native_sqlite:
  android:
    package: not-a-package
'''),
        throwsFormatException,
      );
    });
  });
}
