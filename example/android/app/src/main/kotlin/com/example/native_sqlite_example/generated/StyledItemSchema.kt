package com.example.native_sqlite_example.generated

/**
 * Schema constants for StyledItem table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/custom_converter.dart
 */
object StyledItemSchema {
    const val TABLE_NAME = "styled_items"

    // Column names
    const val ID = "id"
    const val NAME = "name"
    const val BACKGROUND_COLOR = "background_color"
    const val TEXT_COLOR = "text_color"
    const val TAGS = "tags"
    const val CREATED_AT = "created_at"

    // Same statements as the Dart StyledItemSchema
    const val CREATE_TABLE_SQL = "CREATE TABLE \"styled_items\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"name\" TEXT NOT NULL, \"background_color\" INTEGER NOT NULL, \"text_color\" INTEGER, \"tags\" TEXT NOT NULL, \"created_at\" INTEGER NOT NULL)"

    val INDEX_SQL: List<String> = listOf(
    )
}
