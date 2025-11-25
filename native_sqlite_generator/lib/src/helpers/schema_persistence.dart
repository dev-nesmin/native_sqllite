import 'dart:convert';
import 'dart:io';

import 'package:native_sqlite_generator/src/models/schema_snapshot.dart';
import 'package:path/path.dart' as path;

/// Helper class for persisting schema snapshots to disk
class SchemaPersistence {
  /// Saves a schema snapshot to a .schema.json file
  static Future<void> saveSnapshot(
    String outputPath,
    TableSchemaSnapshot snapshot,
  ) async {
    // Generate schema file path
    final schemaFilePath = _getSchemaFilePath(outputPath);
    final file = File(schemaFilePath);

    // Create directory if it doesn't exist
    await file.parent.create(recursive: true);

    // Write JSON
    final json = snapshot.toJson();
    final jsonString = const JsonEncoder.withIndent('  ').convert(json);
    await file.writeAsString(jsonString);
  }

  /// Loads a schema snapshot from a .schema.json file
  static Future<TableSchemaSnapshot?> loadSnapshot(String outputPath) async {
    try {
      final schemaFilePath = _getSchemaFilePath(outputPath);
      final file = File(schemaFilePath);

      if (!await file.exists()) {
        return null;
      }

      final jsonString = await file.readAsString();
      final json = jsonDecode(jsonString) as Map<String, dynamic>;
      return TableSchemaSnapshot.fromJson(json);
    } catch (e) {
      // If there's any error reading the schema, return null
      // This will treat it as a new schema
      return null;
    }
  }

  /// Gets the schema file path for a given output file
  static String _getSchemaFilePath(String outputPath) {
    final dir = path.dirname(outputPath);
    final filename = path.basenameWithoutExtension(outputPath);
    return path.join(dir, '$filename.schema.json');
  }

  /// Checks if a schema file exists
  static Future<bool> schemaExists(String outputPath) async {
    final schemaFilePath = _getSchemaFilePath(outputPath);
    return File(schemaFilePath).exists();
  }

  /// Deletes a schema file
  static Future<void> deleteSchema(String outputPath) async {
    final schemaFilePath = _getSchemaFilePath(outputPath);
    final file = File(schemaFilePath);
    if (await file.exists()) {
      await file.delete();
    }
  }
}
