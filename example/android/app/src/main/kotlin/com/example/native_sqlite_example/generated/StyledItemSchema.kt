package com.example.native_sqlite_example.generated

/**
 * Schema constants for StyledItem table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/styled_item.dart
 */
object StyledItemSchema {
    const val TABLE_NAME = "styled_items"

    // Column names
    const val ID = "id"
    const val NAME = "name"
    const val BACKGROUND_COLOR = "backgroundColor"
    const val TEXT_COLOR = "textColor"
    const val TAGS = "tags"
    const val CREATED_AT = "createdAt"

    // CREATE TABLE SQL
    const val CREATE_TABLE_SQL = """
        CREATE TABLE styled_items (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            backgroundColor INTEGER NOT NULL,
            textColor INTEGER,
            tags TEXT NOT NULL,
            createdAt INTEGER NOT NULL
        )
    """.trimIndent()
}
