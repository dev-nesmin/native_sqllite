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
    val onConfigure: List<String>? = null,
    val enableWAL: Boolean = true,
    val enableForeignKeys: Boolean = true,
    val busyTimeout: Int = 5_000,
    val readOnly: Boolean = false,
    val migrations: Map<Int, List<String>>? = null,
    val directory: String? = null,
    val iosAppGroup: String? = null,
) {
    init {
        require(Regex("^[A-Za-z0-9_-]+$").matches(name)) {
            "Database name must contain only ASCII letters, digits, underscores, and hyphens"
        }
        require(version >= 1) { "Database version must be at least 1" }
        require(busyTimeout >= 0) { "Busy timeout must not be negative" }
        require(directory == null || directory.startsWith("/")) {
            "Database directory must be an absolute path"
        }
        require(iosAppGroup == null) { "iosAppGroup is only supported on iOS" }
    }

    /** Statements upgrading from [oldVersion] to [version], in order. */
    fun upgradeStatements(oldVersion: Int): List<String> =
        (oldVersion + 1..version).flatMap { migrations?.get(it).orEmpty() } +
            onUpgrade.orEmpty()
}
