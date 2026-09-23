import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

import '../analyzer/table_analyzer.dart';
import '../config.dart';
import '../config/generator_options.dart';
import '../migration/migration_steps.dart';
import '../models/table_info.dart';

/// Builder that automatically generates DatabaseManager.
///
/// Works like Flutter's l10n - NO trigger file needed!
/// Just run build_runner and DatabaseManager is ready to use.
class SchemaRegistryBuilder implements Builder {
  final GeneratorOptions options;
  bool _hasRun = false;

  SchemaRegistryBuilder(this.options);

  @override
  Map<String, List<String>> get buildExtensions {
    return const {
      r'$lib$': ['generated/database_manager.dart'],
    };
  }

  @override
  Future<void> build(BuildStep buildStep) async {
    // Only run once per build (like Flutter's l10n)
    if (_hasRun) return;
    _hasRun = true;

    log.info('🔧 Generating DatabaseManager...');

    final packageName = buildStep.inputId.package;
    final resolver = buildStep.resolver;
    final tables = <TableInfo>[];
    final tableFiles = <String, String>{};

    // Read schema via build system to declare dependency on migration builder
    // and avoid dart:io timing issues (file may not be flushed to disk yet).
    final schemaAsset = AssetId(packageName, 'lib/generated/native_sqlite_schema.json');
    String? schemaContent;
    if (await buildStep.canRead(schemaAsset)) {
      schemaContent = await buildStep.readAsString(schemaAsset);
    }

    // Scan all Dart files for @DbTable annotations
    final dartFiles = Glob('lib/**.dart');
    final assets = await buildStep.findAssets(dartFiles).toList();

    for (final assetId in assets) {
      try {
        if (!await resolver.isLibrary(assetId)) continue;

        final lib = await resolver.libraryFor(assetId);
        final reader = LibraryReader(lib);
        final tableChecker = TypeChecker.fromUrl(
          'package:native_sqlite_annotations/src/table.dart#DbTable',
        );

        for (final annotatedElement in reader.annotatedWith(tableChecker)) {
          final element = annotatedElement.element;
          if (element is! ClassElement) continue;

          final annotation = annotatedElement.annotation;
          final autoValue = annotation.read('auto').literalValue as bool?;

          // Skip if auto=false
          if (autoValue == false) continue;

          try {
            final analyzer = TableAnalyzer(options);
            final tableInfo = analyzer.analyze(element, annotation);
            tables.add(tableInfo);

            // Store path relative to lib/ (without extension) so the import
            // is reconstructed as package:<pkg>/<rel_path>.dart
            final relPath = assetId.path
                .replaceFirst('lib/', '')
                .replaceAll('.dart', '');
            tableFiles[tableInfo.dartName] = relPath;
          } catch (e) {
            log.warning('⚠️  Failed to analyze ${element.name}: $e');
          }
        }
      } catch (e) {
        log.fine('Skipping ${assetId.path}: $e');
      }
    }

    if (tables.isEmpty) {
      log.warning(
        '⚠️  No @DbTable models found. DatabaseManager not generated.',
      );
      return;
    }

    log.info('✅ Found ${tables.length} tables');

    _verifySchemaMatchesTables(tables, schemaContent);

    final sortedTables = _topologicalSort(tables);
    final databaseName =
        (await NativeSqliteConfig.load())?.databaseName ??
        NativeSqliteConfig.defaultDatabaseName;
    final code = _generateCode(
      sortedTables,
      tableFiles,
      packageName,
      schemaContent,
      databaseName,
    );

    // Write to fixed location: lib/generated/database_manager.dart
    await buildStep.writeAsString(
      AssetId(packageName, 'lib/generated/database_manager.dart'),
      code,
    );

    log.info('✅ generated/database_manager.dart');
  }

  /// The schema snapshot (written by the `migration` builder) drives runtime
  /// migrations and native code, while the CREATE TABLE statements come from
  /// this builder's analysis. If they disagree — e.g. `column_name_case` was
  /// configured for one builder but not the others — migrations would target
  /// columns that don't exist, so fail the build instead.
  void _verifySchemaMatchesTables(List<TableInfo> tables, String? schemaContent) {
    if (schemaContent == null) return;
    final schemas =
        (jsonDecode(schemaContent) as Map<String, dynamic>)['schemas'] as List?;
    if (schemas == null) return;

    final snapshotColumns = <String, Set<String>>{
      for (final schema in schemas.cast<Map<String, dynamic>>())
        schema['tableName'] as String: {
          for (final c in (schema['columns'] as List).cast<Map<String, dynamic>>())
            c['name'] as String,
        },
    };

    final mismatches = <String>[];
    for (final table in tables) {
      final expected = table.columns.map((c) => c.sqlName).toSet();
      final recorded = snapshotColumns[table.sqlName];
      if (recorded == null) {
        mismatches.add('table "${table.sqlName}" missing from schema snapshot');
      } else if (recorded.length != expected.length ||
          !recorded.containsAll(expected)) {
        mismatches.add(
          '"${table.sqlName}": snapshot has $recorded, tables use $expected',
        );
      }
    }

    if (mismatches.isNotEmpty) {
      throw StateError(
        'native_sqlite_schema.json does not match the generated tables:\n'
        '  ${mismatches.join('\n  ')}\n'
        'Naming options (table_name_case, column_name_case) must be identical '
        'for the native_sqlite_generator:table, :migration and '
        ':schema_registry builders in build.yaml.',
      );
    }
  }

  List<TableInfo> _topologicalSort(List<TableInfo> tables) {
    final sorted = <TableInfo>[];
    final visited = <String>{};
    final visiting = <String>{};

    void visit(TableInfo table) {
      if (visited.contains(table.sqlName)) return;
      if (visiting.contains(table.sqlName)) return; // Circular dependency

      visiting.add(table.sqlName);

      for (final column in table.columns) {
        if (column.foreignKeyTable != null) {
          final refTable = tables.firstWhere(
            (t) => t.sqlName == column.foreignKeyTable,
            orElse: () => table,
          );
          if (refTable != table) visit(refTable);
        }
      }

      visiting.remove(table.sqlName);
      visited.add(table.sqlName);
      sorted.add(table);
    }

    for (final table in tables) {
      visit(table);
    }

    return sorted;
  }

  String _generateCode(
    List<TableInfo> tables,
    Map<String, String> tableFiles,
    String packageName,
    String? schemaContent,
    String databaseName,
  ) {
    final buffer = StringBuffer();

    // Everything the runtime needs is embedded at build time: the schema
    // JSON only exists in the project, not on devices or the web.
    final schemaVersion = schemaContent == null
        ? 1
        : (jsonDecode(schemaContent) as Map<String, dynamic>)['schemaVersion']
                  as int? ??
              1;
    final migrations = MigrationSteps.load(
      currentSchemaJson: schemaContent,
      onSkipped: (file) => log.warning(
        '⚠️  Ignoring migrations in $file: written by an older generator '
        'whose migrations were never applied.',
      ),
    );
    final ensureSchema = schemaContent == null
        ? const <String>[]
        : MigrationSteps.ensureSchema(MigrationSteps.tablesOf(schemaContent));

    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// Generated by native_sqlite_generator');
    buffer.writeln('// coverage:ignore-file');
    buffer.writeln();
    buffer.writeln("import 'package:flutter/foundation.dart';");
    buffer.writeln("import 'package:native_sqlite/native_sqlite.dart';");
    buffer.writeln();

    for (final table in tables) {
      final relPath =
          tableFiles[table.dartName] ?? 'models/${_toSnakeCase(table.dartName)}';
      buffer.writeln("import 'package:$packageName/$relPath.dart';");
    }

    buffer.writeln();
    buffer.writeln('/// Auto-generated database manager.');
    buffer.writeln('/// Call DatabaseManager.init() at app startup.');
    buffer.writeln('class DatabaseManager {');
    buffer.writeln('  DatabaseManager._();');
    buffer.writeln();
    buffer.writeln('  static bool _initialized = false;');
    buffer.writeln('  static String? _currentDatabaseName;');
    buffer.writeln();

    buffer.writeln('  /// Schema version from native_sqlite_schema.json.');
    buffer.writeln('  /// Increments whenever tables are added or changed.');
    buffer.writeln('  static const int schemaVersion = $schemaVersion;');
    buffer.writeln();
    buffer.writeln('  /// Database name from native_sqlite_config.yaml, shared with the');
    buffer.writeln('  /// generated native DatabaseManager.');
    buffer.writeln("  static const String defaultDatabaseName = ${_dartString(databaseName)};");
    buffer.writeln();

    buffer.writeln('  static const tables = <String, String>{');
    for (final table in tables) {
      buffer.writeln(
        "    '${table.sqlName}': ${table.dartName}Schema.createTableSql,",
      );
    }
    buffer.writeln('  };');
    buffer.writeln();

    buffer.writeln('  static List<String> get onCreateStatements => [');
    for (final table in tables) {
      buffer.writeln('    ${table.dartName}Schema.createTableSql,');
    }
    for (final table in tables) {
      if (table.hasIndexes) {
        buffer.writeln('    ...${table.dartName}Schema.indexSql,');
      }
    }
    buffer.writeln('  ];');
    buffer.writeln();

    buffer.writeln('  static List<String> get tableNames => [');
    for (final table in tables) {
      buffer.writeln("    '${table.sqlName}',");
    }
    buffer.writeln('  ];');
    buffer.writeln();

    buffer.writeln(
      '  /// Versioned migration steps: `migrations[v]` upgrades version',
    );
    buffer.writeln('  /// `v - 1` to `v`. Generated from lib/generated/schemas/.');
    buffer.writeln('  static const Map<int, List<String>> migrations = {');
    for (final MapEntry(key: version, value: sql) in migrations.entries) {
      buffer.writeln('    $version: [');
      for (final statement in sql) {
        buffer.writeln('      ${_dartString(statement)},');
      }
      buffer.writeln('    ],');
    }
    buffer.writeln('  };');
    buffer.writeln();

    buffer.writeln(
      '  /// Run after every upgrade: creates any missing table or index.',
    );
    buffer.writeln('  static const List<String> ensureSchemaStatements = [');
    for (final statement in ensureSchema) {
      buffer.writeln('    ${_dartString(statement)},');
    }
    buffer.writeln('  ];');
    buffer.writeln();

    _generateInitMethod(buffer);
    _generateCloseMethod(buffer);
    _generateGetters(buffer);

    buffer.writeln('}');

    return buffer.toString();
  }

  /// Dart single-quoted string literal for [value].
  String _dartString(String value) {
    final escaped = value
        .replaceAll(r'\', r'\\')
        .replaceAll("'", r"\'")
        .replaceAll(r'$', r'\$')
        .replaceAll('\n', r'\n');
    return "'$escaped'";
  }

  void _generateInitMethod(StringBuffer buffer) {
    buffer.writeln('  /// Opens the database, creating it or applying pending migrations.');
    buffer.writeln('  ///');
    buffer.writeln(
      '  /// The platform runs the steps while opening, identically to the',
    );
    buffer.writeln(
      '  /// generated native DatabaseManager, whichever opens the database first.',
    );
    buffer.writeln('  static Future<void> init({');
    buffer.writeln('    String name = defaultDatabaseName,');
    buffer.writeln('    bool enableWAL = true,');
    buffer.writeln('    bool enableForeignKeys = true,');
    buffer.writeln('  }) async {');
    buffer.writeln('    if (_initialized) {');
    buffer.writeln(
      '      debugPrint(\'DatabaseManager already initialized\');',
    );
    buffer.writeln('      return;');
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln('    try {');
    buffer.writeln('      _currentDatabaseName = name;');
    buffer.writeln();
    buffer.writeln('      await NativeSqlite.open(');
    buffer.writeln('        config: AutoMigration.createConfig(');
    buffer.writeln('          name: name,');
    buffer.writeln('          schemaVersion: schemaVersion,');
    buffer.writeln('          onCreateStatements: onCreateStatements,');
    buffer.writeln('          migrations: migrations,');
    buffer.writeln('          ensureSchemaStatements: ensureSchemaStatements,');
    buffer.writeln('          enableWAL: enableWAL,');
    buffer.writeln('          enableForeignKeys: enableForeignKeys,');
    buffer.writeln('        ),');
    buffer.writeln('      );');
    buffer.writeln();
    buffer.writeln('      _initialized = true;');
    buffer.writeln(
      '      debugPrint(\'✅ DatabaseManager initialized (v\$schemaVersion)\');',
    );
    buffer.writeln('    } catch (e, stack) {');
    buffer.writeln('      debugPrint(\'❌ DatabaseManager init failed: \$e\');');
    buffer.writeln('      debugPrint(stack.toString());');
    buffer.writeln('      rethrow;');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _generateCloseMethod(StringBuffer buffer) {
    buffer.writeln('  static Future<void> close() async {');
    buffer.writeln(
      '    if (!_initialized || _currentDatabaseName == null) return;',
    );
    buffer.writeln('    await NativeSqlite.close(_currentDatabaseName!);');
    buffer.writeln('    _initialized = false;');
    buffer.writeln('    _currentDatabaseName = null;');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _generateGetters(StringBuffer buffer) {
    buffer.writeln('  static bool get isInitialized => _initialized;');
    buffer.writeln();
    buffer.writeln('  static String get currentDatabase {');
    buffer.writeln('    if (!_initialized || _currentDatabaseName == null) {');
    buffer.writeln(
      '      throw StateError(\'Call DatabaseManager.init() first\');',
    );
    buffer.writeln('    }');
    buffer.writeln('    return _currentDatabaseName!;');
    buffer.writeln('  }');
    buffer.writeln();
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => '_${match.group(1)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '');
  }
}
