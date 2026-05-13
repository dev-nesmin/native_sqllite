package com.example.native_sqlite_example.generated

/**
 * Schema constants for Profile table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/profile.dart
 */
object ProfileSchema {
    const val TABLE_NAME = "profiles"

    // Column names
    const val ID = "id"
    const val NAME = "name"
    const val EMAIL = "email"
    const val PHONE_NUMBER = "phone_number"
    const val SETTINGS = "settings"
    const val TAGS = "tags"
    const val ADDRESS = "address"
    const val ADDRESSES = "addresses"
    const val METADATA = "metadata"

    // CREATE TABLE SQL
    const val CREATE_TABLE_SQL = """
        CREATE TABLE profiles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL,
            phone_number TEXT,
            settings TEXT,
            tags TEXT,
            address TEXT,
            addresses TEXT,
            metadata TEXT NOT NULL
        )
    """.trimIndent()
}
