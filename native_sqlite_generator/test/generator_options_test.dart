import 'package:build/build.dart';
import 'package:native_sqlite_generator/src/config/generator_options.dart';
import 'package:test/test.dart';

void main() {
  test('timestamps are disabled by default for deterministic output', () {
    expect(const GeneratorOptions().includeTimestamp, isFalse);
    expect(
      GeneratorOptions.fromOptions(BuilderOptions(const {})).includeTimestamp,
      isFalse,
    );
  });

  test('timestamps remain an explicit opt-in compatibility option', () {
    final options = GeneratorOptions.fromOptions(
      BuilderOptions(const {'include_timestamp': true}),
    );
    expect(options.includeTimestamp, isTrue);
  });

  test('rejects removed and unknown options', () {
    expect(
      () =>
          GeneratorOptions.fromOptions(BuilderOptions(const {'format': false})),
      throwsArgumentError,
    );
    expect(
      () => GeneratorOptions.fromOptions(
        BuilderOptions(const {'generate_as_part_file': true}),
      ),
      throwsArgumentError,
    );
    expect(
      () => GeneratorOptions.fromOptions(
        BuilderOptions(const {'enable_cached_builds': true}),
      ),
      throwsArgumentError,
    );
  });

  test('validates option values', () {
    expect(
      () => GeneratorOptions.fromOptions(
        BuilderOptions(const {'table_name_case': 'kebab'}),
      ),
      throwsArgumentError,
    );
    expect(
      () => GeneratorOptions.fromOptions(
        BuilderOptions(const {'verbose': 'yes'}),
      ),
      throwsArgumentError,
    );
    expect(
      () => GeneratorOptions.fromOptions(
        BuilderOptions(const {
          'ignore_for_file': [1],
        }),
      ),
      throwsArgumentError,
    );
  });
}
