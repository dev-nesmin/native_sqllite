package com.example.native_sqlite_example.generated

/**
 * Schema constants for Tag table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/tag.dart
 */
object TagSchema {
    const val TABLE_NAME = "tags"

    // Column names
    const val ID = "id"
    const val LABEL = "label_text"

    // Same statements as the Dart TagSchema
    const val CREATE_TABLE_SQL = "CREATE TABLE \"tags\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"label_text\" TEXT NOT NULL)"

    val INDEX_SQL: List<String> = listOf(
        "CREATE UNIQUE INDEX \"idx_tags_label_unique\" ON \"tags\" (\"label_text\")",
    )
}
