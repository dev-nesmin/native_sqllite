package dev.nesmin.native_sqlite.generated

/**
 * Schema constants for Order table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/order.dart
 */
object OrderSchema {
    const val TABLE_NAME = "orders"

    // Column names
    const val ID = "id"
    const val USER_ID = "userId"
    const val PRODUCT_ID = "productId"
    const val QUANTITY = "quantity"
    const val TOTAL_PRICE = "totalPrice"
    const val STATUS = "status"
    const val NOTES = "notes"
    const val CREATED_AT = "createdAt"
    const val UPDATED_AT = "updatedAt"
    const val DELIVERED_AT = "deliveredAt"

    // CREATE TABLE SQL
    const val CREATE_TABLE_SQL = """
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
    """.trimIndent()
}
