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
    public static let userId = "user_id"
    public static let productId = "product_id"
    public static let quantity = "quantity"
    public static let totalPrice = "total_price"
    public static let status = "status"
    public static let notes = "notes"
    public static let createdAt = "created_at"
    public static let updatedAt = "updated_at"
    public static let deliveredAt = "delivered_at"

    // Same statements as the Dart OrderSchema
    public static let createTableSql = "CREATE TABLE orders (id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER NOT NULL, product_id INTEGER NOT NULL, quantity INTEGER NOT NULL, total_price REAL NOT NULL, status TEXT NOT NULL DEFAULT 'pending', notes TEXT, created_at INTEGER NOT NULL, updated_at INTEGER, delivered_at INTEGER, FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE ON UPDATE CASCADE, FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE ON UPDATE CASCADE)"

    public static let indexSql: [String] = [
        "CREATE INDEX idx_orders_user_id_created_at ON orders (user_id, created_at)",
        "CREATE INDEX idx_orders_status ON orders (status)",
    ]
}
