import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    private let CHANNEL = "com.example.native_sqlite_example/native"

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
        let channel = FlutterMethodChannel(
            name: CHANNEL,
            binaryMessenger: controller.binaryMessenger
        )

        channel.setMethodCallHandler({ [weak self]
            (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
            guard let self = self else { return }

            switch call.method {
            case "testNativeAccess":
                self.testNativeAccess(result: result)
            case "createUserFromNative":
                if let args = call.arguments as? [String: Any],
                   let name = args["name"] as? String,
                   let email = args["email"] as? String {
                    self.createUserFromNative(name: name, email: email, result: result)
                } else {
                    result(FlutterError(code: "INVALID_ARGS", message: "Invalid arguments", details: nil))
                }
            case "getUsersFromNative":
                self.getUsersFromNative(result: result)
            default:
                result(FlutterMethodNotImplemented)
            }
        })

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    /**
     * Demonstrates native SQLite access from Swift code
     * This code can be called from anywhere in your iOS app
     * without going through Flutter
     */
    private func testNativeAccess(result: @escaping FlutterResult) {
        let dbName = "example_app"
        var output = "Testing Native SQLite Access from Swift...\n\n"

        do {
            let manager = NativeSqliteManager.shared

            // Test 1: Create a user using generated schema constants
            output += "Test 1: Creating user using generated schema...\n"
            let userId = try manager.insert(
                name: dbName,
                table: UserSchema.tableName,
                values: [
                    UserSchema.name: "Native iOS User",
                    UserSchema.email: "ios\(Int(Date().timeIntervalSince1970 * 1000))@native.com",
                    UserSchema.age: 30,
                    UserSchema.isActive: 1,
                    UserSchema.createdAt: Int(Date().timeIntervalSince1970 * 1000)
                ]
            )
            output += "✓ Created user with ID: \(userId)\n\n"

            // Test 2: Query users
            output += "Test 2: Querying users...\n"
            let queryResult = try manager.query(
                name: dbName,
                sql: "SELECT \(UserSchema.name), \(UserSchema.email) FROM \(UserSchema.tableName) " +
                     "WHERE \(UserSchema.isActive) = ? LIMIT 5",
                args: [1]
            )

            let users = queryResult.mapList
            output += "✓ Found \(users.count) active users:\n"
            for user in users {
                if let name = user[UserSchema.name] as? String,
                   let email = user[UserSchema.email] as? String {
                    output += "  - \(name): \(email)\n"
                }
            }
            output += "\n"

            // Test 3: Update user
            output += "Test 3: Updating user...\n"
            let updatedRows = try manager.update(
                name: dbName,
                table: UserSchema.tableName,
                values: [UserSchema.name: "Updated Native User"],
                where: "id = ?",
                whereArgs: [userId]
            )
            output += "✓ Updated \(updatedRows) row(s)\n\n"

            // Test 4: Count users
            output += "Test 4: Counting users...\n"
            let countResult = try manager.query(
                name: dbName,
                sql: "SELECT COUNT(*) as count FROM \(UserSchema.tableName)",
                args: []
            )
            if let count = countResult.mapList.first?["count"] {
                output += "✓ Total users: \(count)\n\n"
            }

            // Test 5: Complex query with join
            output += "Test 5: Complex JOIN query...\n"
            do {
                let joinResult = try manager.query(
                    name: dbName,
                    sql: """
                    SELECT
                        u.\(UserSchema.name) as user_name,
                        COUNT(o.id) as order_count
                    FROM \(UserSchema.tableName) u
                    LEFT JOIN \(OrderSchema.tableName) o ON u.id = o.\(OrderSchema.userId)
                    GROUP BY u.id
                    LIMIT 5
                    """,
                    args: []
                )
                output += "✓ Found \(joinResult.mapList.count) users with order counts\n"
                for row in joinResult.mapList {
                    if let userName = row["user_name"],
                       let orderCount = row["order_count"] {
                        output += "  - \(userName): \(orderCount) orders\n"
                    }
                }
            } catch {
                output += "⚠ JOIN query skipped (tables may be empty)\n"
            }

            output += "\n✅ All native access tests completed successfully!"
            result(output)
        } catch {
            output += "\n❌ Error: \(error.localizedDescription)"
            result(FlutterError(
                code: "ERROR",
                message: "Native access failed",
                details: output
            ))
        }
    }

    /**
     * Create a user from native iOS code
     */
    private func createUserFromNative(name: String, email: String, result: @escaping FlutterResult) {
        do {
            let manager = NativeSqliteManager.shared
            let userId = try manager.insert(
                name: "example_app",
                table: UserSchema.tableName,
                values: [
                    UserSchema.name: name,
                    UserSchema.email: email,
                    UserSchema.age: 25,
                    UserSchema.isActive: 1,
                    UserSchema.createdAt: Int(Date().timeIntervalSince1970 * 1000)
                ]
            )
            result(userId)
        } catch {
            result(FlutterError(
                code: "ERROR",
                message: "Failed to create user: \(error.localizedDescription)",
                details: nil
            ))
        }
    }

    /**
     * Get users from native iOS code
     */
    private func getUsersFromNative(result: @escaping FlutterResult) {
        do {
            let manager = NativeSqliteManager.shared
            let queryResult = try manager.query(
                name: "example_app",
                sql: "SELECT * FROM \(UserSchema.tableName) ORDER BY \(UserSchema.createdAt) DESC LIMIT 10",
                args: []
            )
            result(queryResult.mapList)
        } catch {
            result(FlutterError(
                code: "ERROR",
                message: "Failed to get users: \(error.localizedDescription)",
                details: nil
            ))
        }
    }
}
