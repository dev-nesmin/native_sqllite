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
    public static let isAvailable = "is_available"
    public static let categoryId = "category_id"
    public static let imageUrl = "image_url"
    public static let createdAt = "created_at"
    public static let updatedAt = "updated_at"

    // Same statements as the Dart ProductSchema
    public static let createTableSql = "CREATE TABLE \"products\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"name\" TEXT NOT NULL, \"description\" TEXT, \"price\" REAL NOT NULL, \"stock\" INTEGER NOT NULL DEFAULT 0, \"is_available\" INTEGER NOT NULL DEFAULT 1, \"category_id\" INTEGER NOT NULL, \"image_url\" TEXT, \"created_at\" INTEGER NOT NULL, \"updated_at\" INTEGER, FOREIGN KEY (\"category_id\") REFERENCES \"categories\"(\"id\") ON DELETE CASCADE ON UPDATE CASCADE)"

    public static let indexSql: [String] = [
        "CREATE INDEX \"idx_products_category_id_price\" ON \"products\" (\"category_id\", \"price\")",
        "CREATE INDEX \"idx_products_name\" ON \"products\" (\"name\")",
    ]
}
