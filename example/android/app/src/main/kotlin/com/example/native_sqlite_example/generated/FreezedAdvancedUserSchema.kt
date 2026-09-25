package com.example.native_sqlite_example.generated

/**
 * Schema constants for FreezedAdvancedUser table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/freezed_advanced.dart
 */
object FreezedAdvancedUserSchema {
    const val TABLE_NAME = "freezed_advanced_users"

    // Column names
    const val ID = "id"
    const val NAME = "name"
    const val LOGIN_DURATION = "login_duration"
    const val PROFILE_URL = "profile_url"
    const val STATUS = "status"
    const val PRIORITY = "priority"
    const val CREATED_AT = "created_at"
    const val IS_VERIFIED = "is_verified"

    // Same statements as the Dart FreezedAdvancedUserSchema
    const val CREATE_TABLE_SQL = "CREATE TABLE \"freezed_advanced_users\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"name\" TEXT NOT NULL, \"login_duration\" INTEGER, \"profile_url\" TEXT, \"status\" INTEGER NOT NULL, \"priority\" INTEGER, \"created_at\" INTEGER NOT NULL, \"is_verified\" INTEGER NOT NULL)"

    val INDEX_SQL: List<String> = listOf(
    )
}
