import Foundation

/**
 * Schema constants for User table.
 * IMPORTANT: Keep in sync with lib/models/user.dart
 *
 * This file mirrors the generated Dart schema from user.table.g.dart
 * Update this file whenever you change the User model in Dart.
 */
public enum UserSchema {
    // Table name from @Table(name: 'users')
    public static let tableName = "users"

    // Column names from @Column annotations
    public static let id = "id"                    // @PrimaryKey(autoIncrement: true) final int? id
    public static let name = "name"                // @Column() final String name
    public static let email = "email_address"      // @Column(name: 'email_address', unique: true) final String email
    public static let age = "age"                  // @Column(nullable: true) final int? age
    public static let isActive = "is_active"       // @Column() final bool isActive
    public static let createdAt = "created_at"     // @Column() final DateTime createdAt
    public static let lastLogin = "last_login"     // @Column(nullable: true) final DateTime? lastLogin

    // CREATE TABLE SQL - copy from user.table.g.dart after running build_runner
    public static let createTableSql = """
        CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            email_address TEXT NOT NULL UNIQUE,
            age INTEGER,
            is_active INTEGER NOT NULL,
            created_at INTEGER NOT NULL,
            last_login INTEGER
        )
    """
}
