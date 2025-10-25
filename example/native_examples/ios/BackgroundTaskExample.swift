import Foundation
import BackgroundTasks
import native_sqlite_ios

/**
 * Example Background Task that uses the generated schema.
 *
 * This demonstrates how to access the database from native iOS code
 * (e.g., Background Tasks, App Extensions) using the same schema
 * defined in your Dart models.
 */
@available(iOS 13.0, *)
class BackgroundTaskExample {
    private static let dbName = "app_db"

    /**
     * Registers the background task.
     * Call this from AppDelegate.
     */
    static func registerBackgroundTask() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: "com.example.database.refresh",
            using: nil
        ) { task in
            handleDatabaseRefresh(task: task as! BGAppRefreshTask)
        }
    }

    /**
     * Schedules the background task.
     */
    static func scheduleBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: "com.example.database.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // 15 minutes

        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }

    /**
     * Handles the background task.
     */
    private static func handleDatabaseRefresh(task: BGAppRefreshTask) {
        // Schedule the next refresh
        scheduleBackgroundTask()

        task.expirationHandler = {
            // Clean up any ongoing work
            print("Background task expired")
        }

        // Perform the database operations
        Task {
            do {
                try await performDatabaseOperations()
                task.setTaskCompleted(success: true)
            } catch {
                print("Background task failed: \(error)")
                task.setTaskCompleted(success: false)
            }
        }
    }

    /**
     * Performs database operations in the background.
     */
    private static func performDatabaseOperations() async throws {
        let manager = NativeSqliteManager.shared

        // Open database with generated schema
        if !manager.isDatabaseOpen(name: dbName) {
            try manager.openDatabase(config: DatabaseConfig(
                name: dbName,
                version: 1,
                onCreate: [UserSchema.createTableSql],
                onUpgrade: nil,
                enableWAL: true,
                enableForeignKeys: true
            ))
        }

        // Use the helper for type-safe operations
        let userHelper = UserHelper(databaseName: dbName)

        // Insert a user from background task
        let timestamp = Int(Date().timeIntervalSince1970 * 1000)
        let userId = try userHelper.insert(User(
            name: "Background User",
            email: "bg\(timestamp)@example.com",
            isActive: true,
            createdAt: timestamp,
            lastLogin: timestamp
        ))

        print("Inserted user with ID: \(userId)")

        // Query active users
        let activeUsers = try userHelper.findActiveUsers()
        print("Found \(activeUsers.count) active users")

        // Update user
        if let user = activeUsers.first {
            let updatedTimestamp = Int(Date().timeIntervalSince1970 * 1000)
            try userHelper.update(User(
                id: user.id,
                name: user.name,
                email: user.email,
                age: user.age,
                isActive: user.isActive,
                createdAt: user.createdAt,
                lastLogin: updatedTimestamp
            ))
            print("Updated user \(user.id ?? 0)")
        }

        // Get user count
        let count = try userHelper.count()
        print("Total users: \(count)")
    }

    /**
     * Example of using the database from an App Extension.
     */
    static func handleWidgetUpdate() {
        do {
            let manager = NativeSqliteManager.shared

            // Open database
            if !manager.isDatabaseOpen(name: dbName) {
                try manager.openDatabase(config: DatabaseConfig(
                    name: dbName,
                    version: 1,
                    onCreate: [UserSchema.createTableSql],
                    onUpgrade: nil,
                    enableWAL: true,
                    enableForeignKeys: true
                ))
            }

            // Use helper
            let userHelper = UserHelper(databaseName: dbName)

            // Get data for widget
            let activeUsers = try userHelper.findActiveUsers()
            let count = try userHelper.count()

            print("Widget data: \(activeUsers.count) active out of \(count) total users")

            // Use this data to update your widget timeline
        } catch {
            print("Error in widget update: \(error)")
        }
    }
}
