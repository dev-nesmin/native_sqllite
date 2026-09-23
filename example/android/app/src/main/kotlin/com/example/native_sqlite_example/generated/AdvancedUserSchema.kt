package com.example.native_sqlite_example.generated

/**
 * Schema constants for AdvancedUser table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/advanced_user.dart
 */
object AdvancedUserSchema {
    const val TABLE_NAME = "advanced_users"

    // Column names
    const val ID = "id"
    const val NAME = "name"
    const val PHONE_NUMBER = "phone_number"
    const val ADDRESS = "address"
    const val COUNTRY = "country"
    const val ZIP_CODE = "zip_code"
    const val AGE = "age"
    const val CITY = "city"
    const val LOGIN_DURATION = "login_duration"
    const val PROFILE_URL = "profile_url"
    const val SCORE = "score"
    const val STATUS = "status"
    const val PRIORITY = "priority"
    const val CREATED_AT = "created_at"
    const val IS_VERIFIED = "is_verified"

    // Same statements as the Dart AdvancedUserSchema
    const val CREATE_TABLE_SQL = "CREATE TABLE advanced_users (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL, phone_number TEXT, address TEXT, country TEXT, zip_code TEXT, age INTEGER, city TEXT, login_duration INTEGER, profile_url TEXT, score REAL, status INTEGER NOT NULL, priority TEXT, created_at INTEGER NOT NULL, is_verified INTEGER NOT NULL)"

    val INDEX_SQL: List<String> = listOf(
    )
}
