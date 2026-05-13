import Foundation

/**
 * Database migration from version 2 to 3
 * AUTO-GENERATED - Customize as needed
 */
public class Migration_2_3 {

    public static func migrate(databaseName: String) throws {
        let manager = NativeSqliteManager.shared
        
        try manager.execute(name: databaseName, sql: "BEGIN TRANSACTION")
        do {
            // Add your migration logic here
            // Example: Add new column
            // try manager.execute(name: databaseName, sql: "ALTER TABLE users ADD COLUMN phone TEXT")

            // Example: Create new table
            // try manager.execute(name: databaseName, sql: "CREATE TABLE IF NOT EXISTS ...")

            try manager.execute(name: databaseName, sql: "COMMIT")
        } catch {
            try? manager.execute(name: databaseName, sql: "ROLLBACK")
            throw error
        }
    }

    /**
     * Add a new column to a table
     */
    public static func addColumn(
        databaseName: String,
        tableName: String,
        columnName: String,
        columnType: String,
        defaultValue: String? = nil
    ) throws {
        var sql = "ALTER TABLE \(tableName) ADD COLUMN \(columnName) \(columnType)"
        if let defaultValue = defaultValue {
            sql += " DEFAULT \(defaultValue)"
        }
        try NativeSqliteManager.shared.execute(name: databaseName, sql: sql)
    }

    /**
     * Rename a table
     */
    public static func renameTable(
        databaseName: String,
        oldName: String,
        newName: String
    ) throws {
        try NativeSqliteManager.shared.execute(
            name: databaseName,
            sql: "ALTER TABLE \(oldName) RENAME TO \(newName)"
        )
    }

    /**
     * Copy data from old table to new table with schema changes
     */
    public static func migrateTableData(
        databaseName: String,
        oldTable: String,
        newTable: String,
        columnMapping: [String: String]
    ) throws {
        let columns = columnMapping.map { "\($0.key) AS \($0.value)" }.joined(separator: ", ")
        let sql = "INSERT INTO \(newTable) SELECT \(columns) FROM \(oldTable)"
        try NativeSqliteManager.shared.execute(name: databaseName, sql: sql)
    }
}
