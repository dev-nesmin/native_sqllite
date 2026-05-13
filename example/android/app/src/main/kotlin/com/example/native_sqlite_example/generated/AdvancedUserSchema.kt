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
    const val PHONE_NUMBER = "phoneNumber"
    const val ADDRESS = "address"
    const val COUNTRY = "country"
    const val ZIP_CODE = "zipCode"
    const val AGE = "age"
    const val CITY = "city"
    const val LOGIN_DURATION = "loginDuration"
    const val PROFILE_URL = "profileUrl"
    const val SCORE = "score"
    const val STATUS = "status"
    const val PRIORITY = "priority"
    const val CREATED_AT = "createdAt"
    const val IS_VERIFIED = "isVerified"

    // CREATE TABLE SQL
    const val CREATE_TABLE_SQL = """
        CREATE TABLE advanced_users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            phoneNumber TEXT,
            address TEXT,
            country TEXT,
            zipCode TEXT,
            age INTEGER,
            city TEXT,
            loginDuration INTEGER,
            profileUrl TEXT,
            score REAL,
            status INTEGER NOT NULL,
            priority TEXT,
            createdAt INTEGER NOT NULL,
            isVerified INTEGER NOT NULL
        )
    """.trimIndent()
}
