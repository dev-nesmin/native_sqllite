package com.example.native_sqlite_example.generated

/**
 * Schema constants for User table.
 * IMPORTANT: Keep in sync with lib/models/user.dart
 *
 * This file mirrors the generated Dart schema from user.table.g.dart
 * Update this file whenever you change the User model in Dart.
 */
object UserSchema {
    // Table name from @Table(name: 'users')
    const val TABLE_NAME = "users"

    // Column names from @Column annotations
    const val ID = "id"                    // @PrimaryKey(autoIncrement: true) final int? id
    const val NAME = "name"                // @Column() final String name
    const val EMAIL = "email_address"      // @Column(name: 'email_address', unique: true) final String email
    const val AGE = "age"                  // @Column(nullable: true) final int? age
    const val IS_ACTIVE = "is_active"      // @Column() final bool isActive
    const val CREATED_AT = "created_at"    // @Column() final DateTime createdAt
    const val LAST_LOGIN = "last_login"    // @Column(nullable: true) final DateTime? lastLogin

    // CREATE TABLE SQL - copy from user.table.g.dart after running build_runner
    const val CREATE_TABLE_SQL = """
        CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email_address TEXT NOT NULL UNIQUE,
            age INTEGER,
            is_active INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            last_login INTEGER
        )
    """.trimIndent()
}
