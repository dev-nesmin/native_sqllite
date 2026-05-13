import Foundation

/**
 * Schema constants for Product table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/product.dart
 */
public enum ProductSchema {
    public static let tableName = "products"

    // Column names
    public static let id = "id"
    public static let name = "name"
    public static let description = "description"
    public static let price = "price"
    public static let stock = "stock"
    public static let isAvailable = "isAvailable"
    public static let categoryId = "categoryId"
    public static let imageUrl = "imageUrl"
    public static let createdAt = "createdAt"
    public static let updatedAt = "updatedAt"

    // CREATE TABLE SQL
    public static let createTableSql = """
        CREATE TABLE products (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            description TEXT,
            price REAL NOT NULL,
            stock INTEGER NOT NULL,
            isAvailable INTEGER NOT NULL,
            categoryId INTEGER NOT NULL,
            imageUrl TEXT,
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER
        )
        """
}
