package dev.nesmin.native_sqlite.generated

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
    const val PHONE_NUMBER = "phoneNumber"
    const val ADDRESS = "address"
    const val AGE = "age"
    const val IS_ACTIVE = "isActive"
    const val CREATED_AT = "createdAt"
    const val UPDATED_AT = "updatedAt"

    // CREATE TABLE SQL
    const val CREATE_TABLE_SQL = """
        CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            phoneNumber TEXT,
            address TEXT,
            age INTEGER NOT NULL,
            isActive INTEGER NOT NULL,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER
        )
    """.trimIndent()
}
