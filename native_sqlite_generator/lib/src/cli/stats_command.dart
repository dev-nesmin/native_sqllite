import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';

/// Generates statistics about table definitions
class StatsCommand {
  final bool verbose;

  StatsCommand(this.verbose);

  Future<void> execute() async {
    print('📊 Gathering table statistics...\n');

    final stats = TableStatistics();
    final files = await _findDartFiles();

    if (verbose) {
      print('Scanning ${files.length} files...\n');
    }

    for (final file in files) {
      await _analyzeFile(file, stats);
    }

    _printStatistics(stats);
  }

  Future<List<File>> _findDartFiles() async {
    final files = <File>[];
    final libDir = Directory('lib');

    if (!await libDir.exists()) {
      return files;
    }

    await for (final entity in libDir.list(
      recursive: true,
      followLinks: false,
    )) {
      if (entity is File && entity.path.endsWith('.dart')) {
        files.add(entity);
      }
    }

    return files;
  }

  Future<void> _analyzeFile(File file, TableStatistics stats) async {
    try {
      final content = await file.readAsString();
      final parseResult = parseString(content: content);

      if (parseResult.errors.isNotEmpty) {
        return;
      }

      for (final declaration in parseResult.unit.declarations) {
        if (declaration is! ClassDeclaration) continue;

        // Check if class has @DbTable annotation
        final hasTable = declaration.metadata.any(
          (m) => m.name.toString() == 'DbTable',
        );

        if (!hasTable) continue;

        stats.tableCount++;

        // Analyze fields
        final fields = declaration.members
            .whereType<FieldDeclaration>()
            .expand((f) => f.fields.variables)
            .toList();

        stats.totalFields += fields.length;

        // Count field types
        for (final field in fields) {
          final fieldDecl = field.parent!.parent as FieldDeclaration;
          final typeName = fieldDecl.fields.type?.toString() ?? 'dynamic';
          final baseType = typeName.replaceAll('?', '').split('<').first.trim();

          stats.typeCount[baseType] = (stats.typeCount[baseType] ?? 0) + 1;

          // Check for annotations
          final hasPrimaryKey = fieldDecl.metadata.any(
            (m) => m.name.toString() == 'PrimaryKey',
          );
          final hasForeignKey = fieldDecl.metadata.any(
            (m) => m.name.toString() == 'ForeignKey',
          );
          final hasIndex = fieldDecl.metadata.any(
            (m) => m.name.toString() == 'Index',
          );
          final hasJsonField = fieldDecl.metadata.any(
            (m) => m.name.toString() == 'JsonField',
          );
          final hasConverter = fieldDecl.metadata.any(
            (m) => m.name.toString() == 'UseConverter',
          );

          if (hasPrimaryKey) stats.primaryKeyCount++;
          if (hasForeignKey) stats.foreignKeyCount++;
          if (hasIndex) stats.indexCount++;
          if (hasJsonField) stats.jsonFieldCount++;
          if (hasConverter) stats.converterCount++;

          // Check nullability
          if (typeName.contains('?')) {
            stats.nullableFields++;
          }
        }
      }
    } catch (e) {
      if (verbose) {
        print('⚠️  Error analyzing ${file.path}: $e');
      }
    }
  }

  void _printStatistics(TableStatistics stats) {
    if (stats.tableCount == 0) {
      print('ℹ️  No tables found in project');
      print('');
      print('Add @DbTable() annotation to your model classes to get started.');
      return;
    }

    print('📈 Project Statistics:');
    print('');

    // Basic counts
    print('Tables & Fields:');
    print('   Total tables: ${stats.tableCount}');
    print('   Total fields: ${stats.totalFields}');
    final avgFields = (stats.totalFields / stats.tableCount).toStringAsFixed(1);
    print('   Average fields per table: $avgFields');
    print('');

    // Constraints
    if (stats.primaryKeyCount > 0 ||
        stats.foreignKeyCount > 0 ||
        stats.indexCount > 0) {
      print('Constraints & Indexes:');
      if (stats.primaryKeyCount > 0) {
        print('   Primary keys: ${stats.primaryKeyCount}');
      }
      if (stats.foreignKeyCount > 0) {
        print('   Foreign keys: ${stats.foreignKeyCount}');
      }
      if (stats.indexCount > 0) {
        print('   Indexes: ${stats.indexCount}');
      }
      print('');
    }

    // Special fields
    if (stats.nullableFields > 0 ||
        stats.jsonFieldCount > 0 ||
        stats.converterCount > 0) {
      print('Special Fields:');
      if (stats.nullableFields > 0) {
        final nullablePercent = (stats.nullableFields / stats.totalFields * 100)
            .toStringAsFixed(1);
        print(
          '   Nullable fields: ${stats.nullableFields} ($nullablePercent%)',
        );
      }
      if (stats.jsonFieldCount > 0) {
        print('   JSON fields: ${stats.jsonFieldCount}');
      }
      if (stats.converterCount > 0) {
        print('   Custom converters: ${stats.converterCount}');
      }
      print('');
    }

    // Type distribution
    if (stats.typeCount.isNotEmpty) {
      print('Type Distribution:');

      final sortedTypes = stats.typeCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      // Show top 10 types
      final topTypes = sortedTypes.take(10);

      for (final entry in topTypes) {
        final percentage = (entry.value / stats.totalFields * 100)
            .toStringAsFixed(1);
        final bar = _createBar(entry.value, stats.totalFields);
        print(
          '   ${entry.key.padRight(15)} ${entry.value.toString().padLeft(4)} ($percentage%)  $bar',
        );
      }

      if (sortedTypes.length > 10) {
        print('   ... and ${sortedTypes.length - 10} more types');
      }
      print('');
    }

    // Health metrics
    print('Health Metrics:');
    final pkRatio = (stats.primaryKeyCount / stats.tableCount * 100).round();
    print('   Primary key coverage: $pkRatio%');

    if (stats.foreignKeyCount > 0) {
      final indexRatio = (stats.indexCount / stats.foreignKeyCount * 100)
          .round();
      print('   Foreign key index coverage: $indexRatio%');
    }

    final avgComplexity = _calculateComplexity(stats);
    print('   Average table complexity: $avgComplexity');
    print('');

    // Recommendations
    _printRecommendations(stats);
  }

  String _createBar(int value, int total, {int maxWidth = 20}) {
    final ratio = value / total;
    final filledWidth = (ratio * maxWidth).round();
    final filled = '█' * filledWidth;
    final empty = '░' * (maxWidth - filledWidth);
    return filled + empty;
  }

  String _calculateComplexity(TableStatistics stats) {
    if (stats.tableCount == 0) return 'N/A';

    final avgFields = stats.totalFields / stats.tableCount;
    final fkRatio = stats.foreignKeyCount / stats.tableCount;
    final indexRatio = stats.indexCount / stats.tableCount;

    // Simple complexity score
    final complexity = avgFields + (fkRatio * 2) + indexRatio;

    if (complexity < 5) return 'Low';
    if (complexity < 10) return 'Medium';
    return 'High';
  }

  void _printRecommendations(TableStatistics stats) {
    final recommendations = <String>[];

    // Check primary key coverage
    if (stats.primaryKeyCount < stats.tableCount) {
      recommendations.add(
        'Some tables are missing primary keys. Every table should have one.',
      );
    }

    // Check foreign key indexing
    if (stats.foreignKeyCount > 0 && stats.indexCount < stats.foreignKeyCount) {
      recommendations.add(
        'Consider adding indexes to foreign key fields for better performance.',
      );
    }

    // Check complexity
    final avgFields = stats.totalFields / stats.tableCount;
    if (avgFields > 15) {
      recommendations.add(
        'Some tables have many fields (avg: ${avgFields.toStringAsFixed(1)}). Consider splitting complex tables.',
      );
    }

    if (recommendations.isNotEmpty) {
      print('💡 Recommendations:');
      for (int i = 0; i < recommendations.length; i++) {
        print('   ${i + 1}. ${recommendations[i]}');
      }
      print('');
    }

    print(
      '✅ Run "dart run native_sqlite_generator analyze" for detailed analysis',
    );
  }
}

class TableStatistics {
  int tableCount = 0;
  int totalFields = 0;
  int primaryKeyCount = 0;
  int foreignKeyCount = 0;
  int indexCount = 0;
  int nullableFields = 0;
  int jsonFieldCount = 0;
  int converterCount = 0;
  final Map<String, int> typeCount = {};
}
