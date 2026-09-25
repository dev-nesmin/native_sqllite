package com.example.native_sqlite_example.generated

/**
 * Schema constants for Comment table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/comment.dart
 */
object CommentSchema {
    const val TABLE_NAME = "comments"

    // Column names
    const val ID = "id"
    const val PARENT_ID = "parent_id"
    const val BODY = "body"

    // Same statements as the Dart CommentSchema
    const val CREATE_TABLE_SQL = "CREATE TABLE \"comments\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"parent_id\" INTEGER, \"body\" TEXT NOT NULL, FOREIGN KEY (\"parent_id\") REFERENCES \"comments\"(\"id\") ON DELETE SET NULL)"

    val INDEX_SQL: List<String> = listOf(
    )
}
