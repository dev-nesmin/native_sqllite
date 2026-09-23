package dev.nesmin.native_sqlite

/**
 * Configuration for opening a database.
 *
 * @property onUpgrade Statements run on every upgrade, after [migrations].
 * @property migrations Versioned steps: `migrations[v]` upgrades a database
 *   from version `v - 1` to `v`. Same semantics as the Dart and iOS config.
 */
data class DatabaseConfig(
    val name: String,
    val version: Int = 1,
    val onCreate: List<String>? = null,
    val onUpgrade: List<String>? = null,
    val enableWAL: Boolean = true,
    val enableForeignKeys: Boolean = true,
    val migrations: Map<Int, List<String>>? = null,
) {
    /** Statements upgrading from [oldVersion] to [version], in order. */
    fun upgradeStatements(oldVersion: Int): List<String> =
        (oldVersion + 1..version).flatMap { migrations?.get(it).orEmpty() } +
            onUpgrade.orEmpty()
}
