package com.example.native_sqlite_example.generated

/**
 * Schema constants for Note table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/note.dart
 */
object NoteSchema {
    const val TABLE_NAME = "notes"

    // Column names
    const val ID = "id"
    const val BODY = "body"

    // Same statements as the Dart NoteSchema
    const val CREATE_TABLE_SQL = "CREATE TABLE \"notes\" (\"id\" TEXT PRIMARY KEY NOT NULL, \"body\" TEXT NOT NULL)"

    val INDEX_SQL: List<String> = listOf(
    )
}
