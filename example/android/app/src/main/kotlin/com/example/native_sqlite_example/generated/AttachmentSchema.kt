package com.example.native_sqlite_example.generated

/**
 * Schema constants for Attachment table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/attachment.dart
 */
object AttachmentSchema {
    const val TABLE_NAME = "attachments"

    // Column names
    const val ID = "id"
    const val FILENAME = "filename"
    const val BYTES = "bytes"

    // Same statements as the Dart AttachmentSchema
    const val CREATE_TABLE_SQL = "CREATE TABLE \"attachments\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"filename\" TEXT NOT NULL, \"bytes\" BLOB NOT NULL)"

    val INDEX_SQL: List<String> = listOf(
    )
}
