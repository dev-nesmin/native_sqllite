package dev.nesmin.native_sqlite.generated

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
    const val IS_AVAILABLE = "isAvailable"
    const val CATEGORY_ID = "categoryId"
    const val IMAGE_URL = "imageUrl"
    const val CREATED_AT = "createdAt"
    const val UPDATED_AT = "updatedAt"

    // CREATE TABLE SQL
    const val CREATE_TABLE_SQL = """
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
    """.trimIndent()
}
