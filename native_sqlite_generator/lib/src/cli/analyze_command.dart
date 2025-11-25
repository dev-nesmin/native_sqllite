import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:path/path.dart' as path;

/// Analyzes table definitions for potential issues
class AnalyzeCommand {
  final bool verbose;

  AnalyzeCommand(this.verbose);

  Future<void> execute() async {
    print('🔍 Analyzing table definitions...\n');

    final issues = <AnalysisIssue>[];

    // Find all Dart files in lib/
    final files = await _findDartFiles();

    if (verbose) {
      print('Found ${files.length} Dart files to analyze\n');
    }

    int tablesFound = 0;

    for (final file in files) {
      final fileIssues = await _analyzeFile(file);
      if (fileIssues.isNotEmpty) {
        final tableCount = fileIssues
            .where((i) => i.type == IssueType.tableInfo)
            .length;
        tablesFound += tableCount;
      }
      issues.addAll(fileIssues);
    }

    // Filter out table info issues for reporting
    final reportableIssues = issues
        .where((i) => i.type != IssueType.tableInfo)
        .toList();

    print('📊 Analysis complete:');
    print('   Files analyzed: ${files.length}');
    print('   Tables found: $tablesFound');
    print('');

    _printReport(reportableIssues);
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

  Future<List<AnalysisIssue>> _analyzeFile(File file) async {
    final issues = <AnalysisIssue>[];

    try {
      final content = await file.readAsString();
      final parseResult = parseString(content: content);

      if (parseResult.errors.isNotEmpty) {
        // Skip files with parse errors
        return issues;
      }

      for (final declaration in parseResult.unit.declarations) {
        if (declaration is! ClassDeclaration) continue;

        // Check if class has @DbTable annotation
        final hasTable = declaration.metadata.any(
          (m) => m.name.toString() == 'DbTable',
        );

        if (!hasTable) continue;

        // Mark that we found a table
        issues.add(
          AnalysisIssue(
            severity: IssueSeverity.info,
            type: IssueType.tableInfo,
            message: 'Table found: ${declaration.name.lexeme}',
            file: file.path,
            line: declaration.name.offset,
          ),
        );

        // Run checks
        issues.addAll(_checkPrimaryKey(declaration, file));
        issues.addAll(_checkNaming(declaration, file));
        issues.addAll(_checkForeignKeyIndexes(declaration, file));
        issues.addAll(_checkFieldTypes(declaration, file));
      }
    } catch (e) {
      if (verbose) {
        print('⚠️  Error analyzing ${file.path}: $e');
      }
    }

    return issues;
  }

  List<AnalysisIssue> _checkPrimaryKey(ClassDeclaration cls, File file) {
    final issues = <AnalysisIssue>[];

    final fields = cls.members.whereType<FieldDeclaration>().expand(
      (f) => f.fields.variables,
    );

    final hasPrimaryKey = fields.any((field) {
      final fieldDecl = field.parent!.parent as FieldDeclaration;
      return fieldDecl.metadata.any((m) => m.name.toString() == 'PrimaryKey');
    });

    if (!hasPrimaryKey) {
      issues.add(
        AnalysisIssue(
          severity: IssueSeverity.error,
          type: IssueType.missingPrimaryKey,
          message: 'Table ${cls.name.lexeme} has no primary key',
          file: file.path,
          line: cls.name.offset,
          suggestion: 'Add @PrimaryKey() annotation to an id field',
        ),
      );
    }

    return issues;
  }

  List<AnalysisIssue> _checkNaming(ClassDeclaration cls, File file) {
    final issues = <AnalysisIssue>[];

    // Check if table name follows PascalCase convention
    final className = cls.name.lexeme;
    if (!_isPascalCase(className)) {
      issues.add(
        AnalysisIssue(
          severity: IssueSeverity.warning,
          type: IssueType.namingConvention,
          message: 'Table class "$className" should use PascalCase',
          file: file.path,
          line: cls.name.offset,
          suggestion: 'Rename to ${_toPascalCase(className)}',
        ),
      );
    }

    // Check field naming
    final fields = cls.members.whereType<FieldDeclaration>().expand(
      (f) => f.fields.variables,
    );

    for (final field in fields) {
      final fieldName = field.name.lexeme;
      if (!_isCamelCase(fieldName)) {
        issues.add(
          AnalysisIssue(
            severity: IssueSeverity.warning,
            type: IssueType.namingConvention,
            message: 'Field "$fieldName" should use camelCase',
            file: file.path,
            line: field.name.offset,
            suggestion: 'Rename to ${_toCamelCase(fieldName)}',
          ),
        );
      }
    }

    return issues;
  }

  List<AnalysisIssue> _checkForeignKeyIndexes(ClassDeclaration cls, File file) {
    final issues = <AnalysisIssue>[];

    final fields = cls.members.whereType<FieldDeclaration>().expand(
      (f) => f.fields.variables,
    );

    for (final field in fields) {
      final fieldName = field.name.lexeme;

      // Check if field looks like a foreign key
      if (fieldName.endsWith('Id') || fieldName.endsWith('_id')) {
        final fieldDecl = field.parent!.parent as FieldDeclaration;

        final hasForeignKey = fieldDecl.metadata.any(
          (m) => m.name.toString() == 'ForeignKey',
        );
        final hasIndex = fieldDecl.metadata.any(
          (m) => m.name.toString() == 'Index',
        );

        if (hasForeignKey && !hasIndex) {
          issues.add(
            AnalysisIssue(
              severity: IssueSeverity.info,
              type: IssueType.missingIndex,
              message:
                  'Foreign key field "$fieldName" would benefit from an index',
              file: file.path,
              line: field.name.offset,
              suggestion:
                  'Add @Index() annotation for better query performance',
            ),
          );
        }
      }
    }

    return issues;
  }

  List<AnalysisIssue> _checkFieldTypes(ClassDeclaration cls, File file) {
    final issues = <AnalysisIssue>[];

    final fields = cls.members.whereType<FieldDeclaration>().expand(
      (f) => f.fields.variables,
    );

    for (final field in fields) {
      final fieldDecl = field.parent!.parent as FieldDeclaration;
      final typeName = fieldDecl.fields.type?.toString() ?? 'dynamic';

      // Clean up type name (remove nullability, generics for basic check)
      final baseType = typeName.replaceAll('?', '').split('<').first.trim();

      if (!_isSupportedType(baseType) && !_hasTypeConverter(fieldDecl)) {
        issues.add(
          AnalysisIssue(
            severity: IssueSeverity.warning,
            type: IssueType.unsupportedType,
            message:
                'Field "${field.name.lexeme}" has type "$typeName" which may need a type converter',
            file: file.path,
            line: field.name.offset,
            suggestion:
                'Add @UseConverter() or @JsonField() annotation if this is a custom type',
          ),
        );
      }
    }

    return issues;
  }

  bool _isSupportedType(String type) {
    const supportedTypes = {
      'int',
      'double',
      'String',
      'bool',
      'DateTime',
      'Uint8List',
      'List',
      'Map',
    };

    return supportedTypes.contains(type);
  }

  bool _hasTypeConverter(FieldDeclaration field) {
    return field.metadata.any(
      (m) =>
          m.name.toString() == 'UseConverter' ||
          m.name.toString() == 'JsonField',
    );
  }

  bool _isPascalCase(String name) {
    if (name.isEmpty) return false;
    if (name[0] != name[0].toUpperCase()) return false;
    return !name.contains('_');
  }

  bool _isCamelCase(String name) {
    if (name.isEmpty) return false;
    if (name[0] != name[0].toLowerCase()) return false;
    return !name.contains('_');
  }

  String _toPascalCase(String name) {
    if (name.isEmpty) return name;
    return name[0].toUpperCase() + name.substring(1);
  }

  String _toCamelCase(String name) {
    if (name.isEmpty) return name;
    return name[0].toLowerCase() + name.substring(1);
  }

  void _printReport(List<AnalysisIssue> issues) {
    if (issues.isEmpty) {
      print('✅ No issues found!');
      print('');
      print('Your table definitions look great! 🎉');
      return;
    }

    final errors = issues
        .where((i) => i.severity == IssueSeverity.error)
        .toList();
    final warnings = issues
        .where((i) => i.severity == IssueSeverity.warning)
        .toList();
    final infos = issues
        .where((i) => i.severity == IssueSeverity.info)
        .toList();

    print('📋 Issues found:');
    print('   ${errors.length} error(s)');
    print('   ${warnings.length} warning(s)');
    print('   ${infos.length} suggestion(s)');
    print('');

    // Print errors first
    if (errors.isNotEmpty) {
      print('❌ Errors:');
      for (final issue in errors) {
        _printIssue(issue);
      }
      print('');
    }

    // Then warnings
    if (warnings.isNotEmpty) {
      print('⚠️  Warnings:');
      for (final issue in warnings) {
        _printIssue(issue);
      }
      print('');
    }

    // Then suggestions
    if (infos.isNotEmpty) {
      print('ℹ️  Suggestions:');
      for (final issue in infos) {
        _printIssue(issue);
      }
      print('');
    }

    // Summary
    if (errors.isNotEmpty) {
      print('⚠️  Found ${errors.length} error(s) that should be fixed');
    } else {
      print('✅ No critical errors found');
    }
  }

  void _printIssue(AnalysisIssue issue) {
    final relativePath = path.relative(issue.file);
    print('  ${issue.message}');
    print('    at $relativePath');

    if (issue.suggestion != null) {
      print('    💡 ${issue.suggestion}');
    }
  }
}

class AnalysisIssue {
  final IssueSeverity severity;
  final IssueType type;
  final String message;
  final String file;
  final int line;
  final String? suggestion;

  AnalysisIssue({
    required this.severity,
    required this.type,
    required this.message,
    required this.file,
    required this.line,
    this.suggestion,
  });
}

enum IssueSeverity { error, warning, info }

enum IssueType {
  tableInfo,
  missingPrimaryKey,
  namingConvention,
  missingIndex,
  unsupportedType,
}
