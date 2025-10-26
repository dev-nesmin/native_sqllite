import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as path;

import 'config.dart';
import 'native_kotlin_generator.dart';
import 'native_swift_generator.dart';

/// Generates native code files for Android and iOS
class NativeCodeGenerator {
  Future<void> generate({bool runBuildRunner = true}) async {
    // Check if build_runner needs to run first
    if (runBuildRunner) {
      final needsBuildRunner = await _checkBuildRunner();
      if (needsBuildRunner) {
        print('📦 Running build_runner first...');
        print('');
        final result = await Process.run(
          'dart',
          ['run', 'build_runner', 'build', '--delete-conflicting-outputs'],
        );

        if (result.exitCode != 0) {
          throw Exception('build_runner failed:\n${result.stderr}');
        }

        print('✓ build_runner completed');
        print('');
      }
    }

    // Load configuration
    print('📋 Loading configuration...');
    final config = await NativeSqliteConfig.load();

    if (config == null) {
      print('⚠️  No native_sqlite configuration found.');
      print(
          '   Add configuration to pubspec.yaml or create native_sqlite_config.yaml');
      print('   See native_sqlite_config.example.yaml for reference.');
      return;
    }

    if (!config.generateNative) {
      print('ℹ️  Native code generation is disabled (generate_native: false)');
      return;
    }

    print('✓ Configuration loaded\n');

    // Find Dart model files
    print('🔍 Finding model files...');
    final modelFiles = await _findModelFiles(config.models);

    if (modelFiles.isEmpty) {
      print('⚠️  No model files found.');
      print('   Check the "models" configuration in your config file.');
      return;
    }

    print('✓ Found ${modelFiles.length} model file(s)\n');

    // Parse each file and generate native code
    final generatedFiles = <String>[];

    for (final file in modelFiles) {
      print('📄 Processing ${path.basename(file)}...');

      try {
        final models = await _parseModels(file);

        if (models.isEmpty) {
          print('   ⊘ No @Table annotated classes found');
          continue;
        }

        print(
            '   Found ${models.length} table(s): ${models.map((m) => m.className).join(", ")}');

        // Generate Android code
        if (config.android.enabled) {
          final androidFiles = await _generateAndroid(
            models,
            config.android,
            config.databaseName,
            config.includeExamples,
          );
          generatedFiles.addAll(androidFiles);
        }

        // Generate iOS code
        if (config.ios.enabled) {
          final iosFiles = await _generateIos(
            models,
            config.ios,
            config.databaseName,
            config.includeExamples,
          );
          generatedFiles.addAll(iosFiles);
        }
      } catch (e) {
        print('   ❌ Error: $e');
      }
    }

    // Summary
    print('\n📊 Generation Summary');
    print('   Files generated: ${generatedFiles.length}');

    if (config.android.enabled) {
      final androidFiles =
          generatedFiles.where((f) => f.endsWith('.kt')).length;
      print('   - Android (Kotlin): $androidFiles file(s)');
    }

    if (config.ios.enabled) {
      final iosFiles = generatedFiles.where((f) => f.endsWith('.swift')).length;
      print('   - iOS (Swift): $iosFiles file(s)');
    }

    print('\n💡 Next steps:');
    if (config.android.enabled) {
      print('   • Rebuild your Android app to include the generated files');
    }
    if (config.ios.enabled) {
      print('   • Add generated Swift files to your Xcode project');
      print('   • Right-click on Runner folder → Add Files to "Runner"');
    }
  }

  Future<List<String>> _findModelFiles(List<String> patterns) async {
    final files = <String>[];

    // Load config to get patterns if not provided
    if (patterns.isEmpty) {
      final config = await NativeSqliteConfig.load();
      if (config != null && config.models.isNotEmpty) {
        patterns = config.models;
      } else {
        // Default: search in lib/models/
        patterns = ['lib/models/**/*.dart'];
      }
    }

    for (final pattern in patterns) {
      if (pattern.contains('*')) {
        // Glob pattern
        final glob = Glob(pattern);
        await for (final entity in glob.list()) {
          if (entity is File && entity.path.endsWith('.dart')) {
            files.add(entity.path);
          }
        }
      } else {
        // Direct file path
        if (await File(pattern).exists()) {
          files.add(pattern);
        }
      }
    }

    return files.toSet().toList();
  }

  Future<List<TableModel>> _parseModels(String filePath) async {
    final models = <TableModel>[];
    final file = File(filePath);
    final content = await file.readAsString();

    // Parse the Dart file
    final parseResult = parseString(content: content);
    final unit = parseResult.unit;

    // Find classes with @Table annotation
    for (final declaration in unit.declarations) {
      if (declaration is ClassDeclaration) {
        final tableAnnotation = _findTableAnnotation(declaration);
        if (tableAnnotation != null) {
          models.add(await _parseTableModel(declaration, tableAnnotation));
        }
      }
    }

    return models;
  }

  Annotation? _findTableAnnotation(ClassDeclaration classDecl) {
    for (final metadata in classDecl.metadata) {
      final name = metadata.name.name;
      if (name == 'Table') {
        return metadata;
      }
    }
    return null;
  }

  Future<TableModel> _parseTableModel(
    ClassDeclaration classDecl,
    Annotation tableAnnotation,
  ) async {
    final className = classDecl.name.lexeme;

    // Parse table name from annotation
    String tableName = _toSnakeCase(className);
    final arguments = tableAnnotation.arguments?.arguments;
    if (arguments != null) {
      for (final arg in arguments) {
        if (arg is NamedExpression && arg.name.label.name == 'name') {
          if (arg.expression is StringLiteral) {
            tableName =
                (arg.expression as StringLiteral).stringValue ?? tableName;
          }
        }
      }
    }

    // Parse fields
    final fields = <FieldModel>[];
    for (final member in classDecl.members) {
      if (member is FieldDeclaration) {
        for (final variable in member.fields.variables) {
          final fieldModel = _parseField(variable, member);
          if (fieldModel != null) {
            fields.add(fieldModel);
          }
        }
      }
    }

    return TableModel(
      className: className,
      tableName: tableName,
      fields: fields,
    );
  }

  FieldModel? _parseField(
      VariableDeclaration variable, FieldDeclaration fieldDecl) {
    // Check for @Ignore
    for (final metadata in fieldDecl.metadata) {
      if (metadata.name.name == 'Ignore') {
        return null;
      }
    }

    final fieldName = variable.name.lexeme;
    String columnName = fieldName;
    bool isPrimaryKey = false;
    bool autoIncrement = false;
    bool isUnique = false;
    bool isNullable = fieldDecl.fields.type?.question != null;
    String? dartType = fieldDecl.fields.type.toString().replaceAll('?', '');

    // Parse annotations
    for (final metadata in fieldDecl.metadata) {
      final name = metadata.name.name;

      if (name == 'PrimaryKey') {
        isPrimaryKey = true;
        final arguments = metadata.arguments?.arguments;
        if (arguments != null) {
          for (final arg in arguments) {
            if (arg is NamedExpression &&
                arg.name.label.name == 'autoIncrement') {
              if (arg.expression is BooleanLiteral) {
                autoIncrement = (arg.expression as BooleanLiteral).value;
              }
            }
          }
        }
      } else if (name == 'Column') {
        final arguments = metadata.arguments?.arguments;
        if (arguments != null) {
          for (final arg in arguments) {
            if (arg is NamedExpression) {
              final argName = arg.name.label.name;
              if (argName == 'name' && arg.expression is StringLiteral) {
                columnName =
                    (arg.expression as StringLiteral).stringValue ?? columnName;
              } else if (argName == 'unique' &&
                  arg.expression is BooleanLiteral) {
                isUnique = (arg.expression as BooleanLiteral).value;
              }
            }
          }
        }
      }
    }

    return FieldModel(
      fieldName: fieldName,
      columnName: columnName,
      dartType: dartType,
      isNullable: isNullable,
      isPrimaryKey: isPrimaryKey,
      autoIncrement: autoIncrement,
      isUnique: isUnique,
    );
  }

  Future<List<String>> _generateAndroid(
    List<TableModel> models,
    AndroidConfig config,
    String databaseName,
    bool includeExamples,
  ) async {
    final generator = NativeKotlinGenerator(
      packageName: config.package,
      databaseName: databaseName,
      includeExamples: includeExamples,
    );

    final generatedFiles = <String>[];
    final outputDir = Directory(config.outputPath);

    // Create output directory
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
      print('   📁 Created directory: ${config.outputPath}');
    }

    for (final model in models) {
      // Generate schema file
      final schemaCode = generator.generateSchema(model);
      final schemaFile =
          File(path.join(config.outputPath, '${model.className}Schema.kt'));
      await schemaFile.writeAsString(schemaCode);
      generatedFiles.add(schemaFile.path);
      print('   ✓ Generated ${path.basename(schemaFile.path)}');

      // Generate helper file if enabled
      if (config.generateHelpers) {
        final helperCode = generator.generateHelper(model);
        final helperFile =
            File(path.join(config.outputPath, '${model.className}Helper.kt'));
        await helperFile.writeAsString(helperCode);
        generatedFiles.add(helperFile.path);
        print('   ✓ Generated ${path.basename(helperFile.path)}');
      }
    }

    return generatedFiles;
  }

  Future<List<String>> _generateIos(
    List<TableModel> models,
    IosConfig config,
    String databaseName,
    bool includeExamples,
  ) async {
    final generator = NativeSwiftGenerator(
      databaseName: databaseName,
      includeExamples: includeExamples,
    );

    final generatedFiles = <String>[];
    final outputDir = Directory(config.outputPath);

    // Create output directory
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
      print('   📁 Created directory: ${config.outputPath}');
    }

    for (final model in models) {
      // Generate schema file
      final schemaCode = generator.generateSchema(model);
      final schemaFile =
          File(path.join(config.outputPath, '${model.className}Schema.swift'));
      await schemaFile.writeAsString(schemaCode);
      generatedFiles.add(schemaFile.path);
      print('   ✓ Generated ${path.basename(schemaFile.path)}');

      // Generate helper file if enabled
      if (config.generateHelpers) {
        final helperCode = generator.generateHelper(model);
        final helperFile = File(
            path.join(config.outputPath, '${model.className}Helper.swift'));
        await helperFile.writeAsString(helperCode);
        generatedFiles.add(helperFile.path);
        print('   ✓ Generated ${path.basename(helperFile.path)}');
      }
    }

    return generatedFiles;
  }

  String _toSnakeCase(String input) {
    return input
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => '_${match.group(1)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '');
  }

  /// Check if build_runner needs to run
  Future<bool> _checkBuildRunner() async {
    final modelFiles = await _findModelFiles([]);

    for (final modelFile in modelFiles) {
      // Check if .table.g.dart exists and is newer than source
      final generatedFile = modelFile.replaceAll('.dart', '.table.g.dart');
      final generated = File(generatedFile);
      final source = File(modelFile);

      if (!await generated.exists()) {
        print('ℹ️  Generated file missing: ${path.basename(generatedFile)}');
        return true;
      }

      final generatedTime = await generated.lastModified();
      final sourceTime = await source.lastModified();

      if (sourceTime.isAfter(generatedTime)) {
        print(
            'ℹ️  Source file newer than generated: ${path.basename(modelFile)}');
        return true;
      }
    }

    return false;
  }
}

/// Model representing a table
class TableModel {
  final String className;
  final String tableName;
  final List<FieldModel> fields;

  TableModel({
    required this.className,
    required this.tableName,
    required this.fields,
  });
}

/// Model representing a field/column
class FieldModel {
  final String fieldName;
  final String columnName;
  final String dartType;
  final bool isNullable;
  final bool isPrimaryKey;
  final bool autoIncrement;
  final bool isUnique;

  FieldModel({
    required this.fieldName,
    required this.columnName,
    required this.dartType,
    required this.isNullable,
    required this.isPrimaryKey,
    required this.autoIncrement,
    required this.isUnique,
  });

  String get sqlType {
    final baseType = dartType.replaceAll('?', '');
    if (baseType == 'int' ||
        baseType == 'Int' ||
        baseType == 'bool' ||
        baseType == 'DateTime') {
      return 'INTEGER';
    } else if (baseType == 'double' || baseType == 'Double') {
      return 'REAL';
    } else if (baseType == 'String') {
      return 'TEXT';
    }
    return 'TEXT';
  }
}
