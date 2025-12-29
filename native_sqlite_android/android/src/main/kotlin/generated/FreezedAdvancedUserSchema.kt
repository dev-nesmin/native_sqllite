package dev.nesmin.native_sqlite.generated

/**
 * Schema constants for FreezedAdvancedUser table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/freezed_advanced_user.dart
 */
object FreezedAdvancedUserSchema {
    const val TABLE_NAME = "advanced_users"

    // Column names
    const val ID = "id"
    const val NAME = "name"
    const val LOGIN_DURATION = "loginDuration"
    const val PROFILE_URL = "profileUrl"
    const val STATUS = "status"
    const val PRIORITY = "priority"
    const val CREATED_AT = "createdAt"
    const val IS_VERIFIED = "isVerified"

    // CREATE TABLE SQL
    const val CREATE_TABLE_SQL = """
        CREATE TABLE advanced_users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            loginDuration INTEGER,
            profileUrl TEXT,
            status INTEGER NOT NULL,
            priority INTEGER,
            createdAt INTEGER NOT NULL,
            isVerified INTEGER NOT NULL
        )
    """.trimIndent()
}
