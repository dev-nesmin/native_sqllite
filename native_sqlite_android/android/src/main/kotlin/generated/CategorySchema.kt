package dev.nesmin.native_sqlite.generated

/**
 * Schema constants for Category table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/category.dart
 */
object CategorySchema {
    const val TABLE_NAME = "categories"

    // Column names
    const val ID = "id"
    const val NAME = "name"
    const val DESCRIPTION = "description"
    const val CREATED_AT = "createdAt"

    // CREATE TABLE SQL
    const val CREATE_TABLE_SQL = """
        CREATE TABLE categories (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE,
            description TEXT,
            createdAt INTEGER NOT NULL
        )
    """.trimIndent()
}
