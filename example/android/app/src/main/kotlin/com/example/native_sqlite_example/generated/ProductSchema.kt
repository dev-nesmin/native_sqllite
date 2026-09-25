package com.example.native_sqlite_example.generated

/**
 * Schema constants for Product table.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 * Generated from: lib/models/product.dart
 */
object ProductSchema {
    const val TABLE_NAME = "products"

    // Column names
    const val ID = "id"
    const val NAME = "name"
    const val DESCRIPTION = "description"
    const val PRICE = "price"
    const val STOCK = "stock"
    const val IS_AVAILABLE = "is_available"
    const val CATEGORY_ID = "category_id"
    const val IMAGE_URL = "image_url"
    const val CREATED_AT = "created_at"
    const val UPDATED_AT = "updated_at"

    // Same statements as the Dart ProductSchema
    const val CREATE_TABLE_SQL = "CREATE TABLE \"products\" (\"id\" INTEGER PRIMARY KEY AUTOINCREMENT, \"name\" TEXT NOT NULL, \"description\" TEXT, \"price\" REAL NOT NULL, \"stock\" INTEGER NOT NULL DEFAULT 0, \"is_available\" INTEGER NOT NULL DEFAULT 1, \"category_id\" INTEGER NOT NULL, \"image_url\" TEXT, \"created_at\" INTEGER NOT NULL, \"updated_at\" INTEGER, FOREIGN KEY (\"category_id\") REFERENCES \"categories\"(\"id\") ON DELETE CASCADE ON UPDATE CASCADE)"

    val INDEX_SQL: List<String> = listOf(
        "CREATE INDEX \"idx_products_category_id_price\" ON \"products\" (\"category_id\", \"price\")",
        "CREATE INDEX \"idx_products_name\" ON \"products\" (\"name\")",
    )
}
