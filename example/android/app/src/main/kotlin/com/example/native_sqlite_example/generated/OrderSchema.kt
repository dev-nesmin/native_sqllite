package com.example.native_sqlite_example.generated

/**
 * Schema constants for Order table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/order.dart
 */
object OrderSchema {
    const val TABLE_NAME = "orders"

    // Column names
    const val ID = "id"
    const val USER_ID = "user_id"
    const val PRODUCT_ID = "product_id"
    const val QUANTITY = "quantity"
    const val TOTAL_PRICE = "total_price"
    const val STATUS = "status"
    const val NOTES = "notes"
    const val CREATED_AT = "created_at"
    const val UPDATED_AT = "updated_at"
    const val DELIVERED_AT = "delivered_at"

    // Same statements as the Dart OrderSchema
    const val CREATE_TABLE_SQL = "CREATE TABLE \"orders\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"user_id\" INTEGER NOT NULL, \"product_id\" INTEGER NOT NULL, \"quantity\" INTEGER NOT NULL, \"total_price\" REAL NOT NULL, \"status\" TEXT NOT NULL DEFAULT 'pending', \"notes\" TEXT, \"created_at\" INTEGER NOT NULL, \"updated_at\" INTEGER, \"delivered_at\" INTEGER, FOREIGN KEY (\"user_id\") REFERENCES \"users\"(\"id\") ON DELETE CASCADE ON UPDATE CASCADE, FOREIGN KEY (\"product_id\") REFERENCES \"products\"(\"id\") ON DELETE CASCADE ON UPDATE CASCADE)"

    val INDEX_SQL: List<String> = listOf(
        "CREATE INDEX \"idx_orders_user_id_created_at\" ON \"orders\" (\"user_id\", \"created_at\")",
        "CREATE INDEX \"idx_orders_status\" ON \"orders\" (\"status\")",
    )
}
