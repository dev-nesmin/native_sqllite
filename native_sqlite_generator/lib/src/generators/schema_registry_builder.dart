import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';

import '../analyzer/table_analyzer.dart';
import '../config/generator_options.dart';
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
      r'$lib$': ['database_manager.dart'],
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

            final pathParts = assetId.path.split('/');
            final fileName = pathParts.last.replaceAll('.dart', '');
            tableFiles[tableInfo.dartName] = fileName;
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

    final sortedTables = _topologicalSort(tables);
    final code = _generateCode(sortedTables, tableFiles, packageName);

    // Write to .dart_tool/native_sqlite_generator/database_manager.dart
    final projectRoot = Directory.current.path;
    final outputDir = Directory(
      '$projectRoot/.dart_tool/native_sqlite_generator',
    );
    if (!outputDir.existsSync()) {
      outputDir.createSync(recursive: true);
    }

    final outputFile = File('${outputDir.path}/database_manager.dart');
    outputFile.writeAsStringSync(code);

    // Add to package_config.json for package:native_sqlite/
    final packageConfigFile = File(
      '$projectRoot/.dart_tool/package_config.json',
    );
    if (packageConfigFile.existsSync()) {
      final configJson =
          jsonDecode(packageConfigFile.readAsStringSync())
              as Map<String, dynamic>;
      final packages = configJson['packages'] as List;

      // Remove existing native_sqlite_generator entries
      packages.removeWhere(
        (p) => (p as Map)['name'] == 'native_sqlite_generator',
      );

      // Add our generated package
      packages.add({
        'name': 'native_sqlite_generator',
        'rootUri': '../.dart_tool/native_sqlite_generator',
        'packageUri': './',
        'languageVersion': '3.0',
      });

      packageConfigFile.writeAsStringSync(jsonEncode(configJson));
    }

    log.info('✅ database_manager.dart');
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
  ) {
    final buffer = StringBuffer();

    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// Generated by native_sqlite_generator');
    buffer.writeln('// coverage:ignore-file');
    buffer.writeln();
    buffer.writeln("import 'package:flutter/foundation.dart';");
    buffer.writeln("import 'package:native_sqlite/native_sqlite.dart';");
    buffer.writeln();

    for (final table in tables) {
      final fileName =
          tableFiles[table.dartName] ?? _toSnakeCase(table.dartName);
      buffer.writeln("import 'package:$packageName/models/$fileName.dart';");
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

    final schemaHash = _calculateSchemaHash(tables);
    buffer.writeln('  static const schemaVersion = $schemaHash;');
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

    _generateInitMethod(buffer);
    _generateCloseMethod(buffer);
    _generateGetters(buffer);

    buffer.writeln('}');

    return buffer.toString();
  }

  void _generateInitMethod(StringBuffer buffer) {
    buffer.writeln('  /// Initialize database with automatic setup.');
    buffer.writeln(
      '  /// Handles table creation, migrations, and schema updates automatically.',
    );
    buffer.writeln('  static Future<void> init({');
    buffer.writeln('    String name = \'app_database\',');
    buffer.writeln('    bool enableWAL = true,');
    buffer.writeln('    bool enableForeignKeys = true,');
    buffer.writeln('    bool dropRemovedTables = false,');
    buffer.writeln(
      '    Future<void> Function(String, int, int)? onCustomMigrate,',
    );
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
    buffer.writeln('          tables: tables,');
    buffer.writeln('          tableNames: tableNames,');
    buffer.writeln('          enableWAL: enableWAL,');
    buffer.writeln('          enableForeignKeys: enableForeignKeys,');
    buffer.writeln('          dropRemovedTables: dropRemovedTables,');
    buffer.writeln('          onCustomMigrate: onCustomMigrate,');
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

  int _calculateSchemaHash(List<TableInfo> tables) {
    final content = tables.map((t) => t.sqlName).join(',');
    return content.hashCode.abs() % 1000000;
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
