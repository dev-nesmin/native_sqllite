package com.example.native_sqlite_example.generated

/**
 * Schema constants for SyncEvent table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/sync_event.dart
 */
object SyncEventSchema {
    const val TABLE_NAME = "sync_events"

    // Column names
    const val ID = "id"
    const val SOURCE = "source"
    const val MESSAGE = "message"
    const val CREATED_AT = "created_at"

    // Same statements as the Dart SyncEventSchema
    const val CREATE_TABLE_SQL = "CREATE TABLE \"sync_events\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"source\" TEXT NOT NULL, \"message\" TEXT NOT NULL, \"created_at\" INTEGER NOT NULL)"

    val INDEX_SQL: List<String> = listOf(
        "CREATE INDEX \"idx_sync_events_created_at\" ON \"sync_events\" (\"created_at\")",
    )
}
