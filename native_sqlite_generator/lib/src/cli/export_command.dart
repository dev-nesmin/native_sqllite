import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// Exports table schemas to JSON format for documentation and tooling
class ExportCommand {
  final bool verbose;

  ExportCommand(this.verbose);

  Future<void> execute(List<String> args) async {
    print('📤 Exporting schemas to JSON...\n');

    // Parse arguments
    String? outputPath;
    String? format = 'json';

    for (int i = 0; i < args.length; i++) {
      if (args[i] == '--output' && i + 1 < args.length) {
        outputPath = args[i + 1];
      } else if (args[i] == '--format' && i + 1 < args.length) {
        format = args[i + 1];
      }
    }

    if (outputPath == null) {
      print('❌ Error: Missing required --output argument\n');
      print('Usage: dart run native_sqlite_generator export \\');
      print('  --output <output.json> \\');
      print('  --format <json|yaml> (optional, default: json)');
      print('');
      print('Example:');
      print('  dart run native_sqlite_generator export \\');
      print('    --output docs/schema.json');
      exit(1);
    }

    try {
      // Find all table files
      final tables = await _findTables();

      if (tables.isEmpty) {
        print('⚠️  No tables found');
        return;
      }

      if (verbose) {
        print('Found ${tables.length} table(s):');
        for (final table in tables) {
          print('  • ${table.name}');
        }
        print('');
      }

      // Generate schema
      final schema = _generateSchema(tables);

      // Write output
      final output = format == 'yaml' ? _toYaml(schema) : _toJson(schema);

      final outputFile = File(outputPath);
      await outputFile.create(recursive: true);
      await outputFile.writeAsString(output);

      print('✅ Schema exported successfully!');
      print('');
      print('Output: $outputPath');
      print('Tables: ${tables.length}');
      print('Format: $format');
    } catch (e, stackTrace) {
      print('❌ Error exporting schema: $e');
      if (verbose) {
        print('');
        print('Stack trace:');
        print(stackTrace);
      }
      exit(1);
    }
  }

  Future<List<_TableInfo>> _findTables() async {
    final tables = <_TableInfo>[];
    final libDir = Directory('lib');

    if (!await libDir.exists()) {
      return tables;
    }

    await for (final entity in libDir.list(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.endsWith('.dart')) continue;
      if (entity.path.contains('.g.dart')) continue;
      if (entity.path.contains('.table.dart')) continue;

      try {
        final tableInfo = await _parseFile(entity);
        if (tableInfo != null) {
          tables.add(tableInfo);
        }
      } catch (e) {
        if (verbose) {
          print('⚠️  Error parsing ${entity.path}: $e');
        }
      }
    }

    return tables;
  }

  Future<_TableInfo?> _parseFile(File file) async {
    final content = await file.readAsString();
    final parseResult = parseString(content: content);

    for (final declaration in parseResult.unit.declarations) {
      if (declaration is! ClassDeclaration) continue;

      final hasTable = declaration.metadata.any((m) => m.name.name == 'Table');
      if (!hasTable) continue;

      // Extract table info
      final className = declaration.name.lexeme;
      final fields = <_FieldInfo>[];

      // Get table name from annotation
      String? tableName;
      for (final meta in declaration.metadata) {
        if (meta.name.name == 'Table' && meta.arguments != null) {
          for (final arg in meta.arguments!.arguments) {
            if (arg is NamedExpression && arg.name.label.name == 'name') {
              if (arg.expression is SimpleStringLiteral) {
                tableName = (arg.expression as SimpleStringLiteral).value;
              }
            }
          }
        }
      }

      // Extract fields
      for (final member in declaration.members) {
        if (member is! FieldDeclaration) continue;

        for (final variable in member.fields.variables) {
          final fieldName = variable.name.lexeme;
          final fieldType = member.fields.type?.toString() ?? 'dynamic';

          bool isPrimaryKey = false;
          bool isNullable = fieldType.endsWith('?');
          bool isUnique = false;
          bool hasIndex = false;
          String? foreignKey;
          String? columnName;

          // Check annotations
          for (final meta in member.metadata) {
            final name = meta.name.name;
            if (name == 'PrimaryKey') {
              isPrimaryKey = true;
            } else if (name == 'Unique') {
              isUnique = true;
            } else if (name == 'Index') {
              hasIndex = true;
            } else if (name == 'Column') {
              // Extract column name
              if (meta.arguments != null) {
                for (final arg in meta.arguments!.arguments) {
                  if (arg is NamedExpression && arg.name.label.name == 'name') {
                    if (arg.expression is SimpleStringLiteral) {
                      columnName =
                          (arg.expression as SimpleStringLiteral).value;
                    }
                  }
                }
              }
            } else if (name == 'ForeignKey') {
              if (meta.arguments != null &&
                  meta.arguments!.arguments.isNotEmpty) {
                final arg = meta.arguments!.arguments.first;
                if (arg is SimpleStringLiteral) {
                  foreignKey = arg.value;
                }
              }
            }
          }

          fields.add(_FieldInfo(
            name: fieldName,
            type: fieldType,
            columnName: columnName ?? _toSnakeCase(fieldName),
            isPrimaryKey: isPrimaryKey,
            isNullable: isNullable,
            isUnique: isUnique,
            hasIndex: hasIndex,
            foreignKey: foreignKey,
          ));
        }
      }

      return _TableInfo(
        name: className,
        tableName: tableName ?? _toSnakeCase(className),
        filePath: file.path,
        fields: fields,
      );
    }

    return null;
  }

  Map<String, dynamic> _generateSchema(List<_TableInfo> tables) {
    return {
      'version': '1.0.0',
      'generatedAt': DateTime.now().toIso8601String(),
      'generator': 'native_sqlite_generator',
      'tableCount': tables.length,
      'tables': tables
          .map((t) => {
                'name': t.name,
                'tableName': t.tableName,
                'filePath': t.filePath,
                'fieldCount': t.fields.length,
                'fields': t.fields
                    .map((f) => {
                          'name': f.name,
                          'type': f.type,
                          'columnName': f.columnName,
                          'isPrimaryKey': f.isPrimaryKey,
                          'isNullable': f.isNullable,
                          'isUnique': f.isUnique,
                          'hasIndex': f.hasIndex,
                          if (f.foreignKey != null) 'foreignKey': f.foreignKey,
                        })
                    .toList(),
                'primaryKeys': t.fields
                    .where((f) => f.isPrimaryKey)
                    .map((f) => f.name)
                    .toList(),
                'indexes': t.fields
                    .where((f) => f.hasIndex)
                    .map((f) => f.name)
                    .toList(),
                'foreignKeys': t.fields
                    .where((f) => f.foreignKey != null)
                    .map((f) => {
                          'field': f.name,
                          'references': f.foreignKey,
                        })
                    .toList(),
              })
          .toList(),
    };
  }

  String _toJson(Map<String, dynamic> data) {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(data);
  }

  String _toYaml(Map<String, dynamic> data) {
    // Simple YAML conversion (basic support)
    final buffer = StringBuffer();
    _writeYaml(data, buffer, 0);
    return buffer.toString();
  }

  void _writeYaml(dynamic value, StringBuffer buffer, int indent) {
    final indentStr = '  ' * indent;

    if (value is Map) {
      for (final entry in value.entries) {
        buffer.write('$indentStr${entry.key}:');
        if (entry.value is Map || entry.value is List) {
          buffer.writeln();
          _writeYaml(entry.value, buffer, indent + 1);
        } else {
          buffer.writeln(' ${_formatYamlValue(entry.value)}');
        }
      }
    } else if (value is List) {
      for (final item in value) {
        buffer.write('$indentStr-');
        if (item is Map || item is List) {
          buffer.writeln();
          _writeYaml(item, buffer, indent + 1);
        } else {
          buffer.writeln(' ${_formatYamlValue(item)}');
        }
      }
    }
  }

  String _formatYamlValue(dynamic value) {
    if (value is String) {
      return value.contains(' ') || value.contains(':') ? '"$value"' : value;
    }
    return value.toString();
  }

  String _toSnakeCase(String str) {
    return str
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => '_${match.group(1)!.toLowerCase()}',
        )
        .replaceFirst(RegExp(r'^_'), '');
  }
}

class _TableInfo {
  final String name;
  final String tableName;
  final String filePath;
  final List<_FieldInfo> fields;

  _TableInfo({
    required this.name,
    required this.tableName,
    required this.filePath,
    required this.fields,
  });
}

class _FieldInfo {
  final String name;
  final String type;
  final String columnName;
  final bool isPrimaryKey;
  final bool isNullable;
  final bool isUnique;
  final bool hasIndex;
  final String? foreignKey;

  _FieldInfo({
    required this.name,
    required this.type,
    required this.columnName,
    required this.isPrimaryKey,
    required this.isNullable,
    required this.isUnique,
    required this.hasIndex,
    this.foreignKey,
  });
}
