import Foundation

/**
 * Schema constants for Order table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/order.dart
 */
public enum OrderSchema {
    public static let tableName = "orders"

    // Column names
    public static let id = "id"
    public static let userId = "userId"
    public static let productId = "productId"
    public static let quantity = "quantity"
    public static let totalPrice = "totalPrice"
    public static let status = "status"
    public static let notes = "notes"
    public static let createdAt = "createdAt"
    public static let updatedAt = "updatedAt"
    public static let deliveredAt = "deliveredAt"

    // CREATE TABLE SQL
    public static let createTableSql = """
        CREATE TABLE orders (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            userId INTEGER NOT NULL,
            productId INTEGER NOT NULL,
            quantity INTEGER NOT NULL,
            totalPrice REAL NOT NULL,
            status TEXT NOT NULL,
            notes TEXT,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER,
            deliveredAt INTEGER
        )
        """
}
