package com.example.native_sqlite_example.generated

/**
 * Schema constants for User table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/user.dart
 */
object UserSchema {
    const val TABLE_NAME = "users"

    // Column names
    const val ID = "id"
    const val NAME = "name"
    const val EMAIL = "email"
    const val PHONE_NUMBER = "phone_number"
    const val ADDRESS = "address"
    const val AGE = "age"
    const val IS_ACTIVE = "is_active"
    const val CREATED_AT = "created_at"
    const val UPDATED_AT = "updated_at"

    // Same statements as the Dart UserSchema
    const val CREATE_TABLE_SQL = "CREATE TABLE \"users\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"name\" TEXT NOT NULL, \"email\" TEXT NOT NULL UNIQUE, \"phone_number\" TEXT, \"address\" TEXT, \"age\" INTEGER NOT NULL DEFAULT 18, \"is_active\" INTEGER NOT NULL DEFAULT 1, \"created_at\" INTEGER NOT NULL, \"updated_at\" INTEGER)"

    val INDEX_SQL: List<String> = listOf(
        "CREATE INDEX \"idx_users_email\" ON \"users\" (\"email\")",
        "CREATE INDEX \"idx_users_created_at\" ON \"users\" (\"created_at\")",
        "CREATE UNIQUE INDEX \"idx_users_phone\" ON \"users\" (\"phone_number\")",
    )
}
