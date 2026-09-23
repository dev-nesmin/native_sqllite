import Flutter
import UIKit
import native_sqlite_ios

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NativeIntegration") {
      NativeIntegration.register(messenger: registrar.messenger())
    }
  }
}

/// Handles the example's "Native Integration" screen: the same database the
/// Flutter side uses, accessed from Swift through the generated helpers.
enum NativeIntegration {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "com.example.native_sqlite_example/native",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      do {
        // Reuses the connection Flutter opened, or opens and migrates it.
        try DatabaseManager.shared.initialize()
        let users = UserHelper(databaseName: try DatabaseManager.shared.currentDatabase)

        switch call.method {
        case "testNativeAccess":
          result(try runAccessTests(users))
        case "createUserFromNative":
          guard let args = call.arguments as? [String: Any],
                let name = args["name"] as? String,
                let email = args["email"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "name and email are required", details: nil))
            return
          }
          result(try users.insert(User(name: name, email: email, age: 25, isActive: true, createdAt: Date())))
        case "getUsersFromNative":
          result(try users.findWhere(orderBy: "\(UserSchema.createdAt) DESC", limit: 10).map(toMap))
        default:
          result(FlutterMethodNotImplemented)
        }
      } catch {
        result(FlutterError(code: "NATIVE_SQLITE_ERROR", message: "\(error)", details: nil))
      }
    }
  }

  private static func runAccessTests(_ users: UserHelper) throws -> String {
    var output = "Native SQLite access from Swift\n\n"

    let email = "ios\(Int64(Date().timeIntervalSince1970 * 1000))@native.dev"
    let id = try users.insert(
      User(name: "Native iOS User", email: email, age: 30, isActive: true, createdAt: Date())
    )
    output += "✓ Inserted user #\(id)\n"

    guard let user = try users.findById(id) else {
      throw GeneratedRowError.missingColumn(UserSchema.id)
    }
    output += "✓ Read back: \(user.name) <\(user.email)>, created \(user.createdAt)\n"

    let updated = try users.update(
      User(id: id, name: "Updated Native User", email: user.email, age: user.age,
           isActive: user.isActive, createdAt: user.createdAt, updatedAt: Date())
    )
    output += "✓ Updated \(updated) row(s)\n"

    let active = try users.count(whereClause: "\(UserSchema.isActive) = ?", whereArgs: [1])
    output += "✓ Active users: \(active)\n"

    let joined = try NativeSqliteManager.shared.query(
      name: try DatabaseManager.shared.currentDatabase,
      sql: """
        SELECT u.\(UserSchema.name) AS user_name, COUNT(o.\(OrderSchema.id)) AS order_count
        FROM \(UserSchema.tableName) u
        LEFT JOIN \(OrderSchema.tableName) o ON o.\(OrderSchema.userId) = u.\(UserSchema.id)
        GROUP BY u.\(UserSchema.id) LIMIT 5
        """
    )
    let rows = joined["rows"] as? [[Any?]] ?? []
    output += "✓ JOIN returned \(rows.count) row(s)\n"
    for row in rows {
      output += "  - \(row[0] as? String ?? "?"): \(row[1] as? Int64 ?? 0) orders\n"
    }

    return output + "\n✅ All native access tests passed"
  }

  private static func toMap(_ user: User) -> [String: Any] {
    ["id": user.id ?? 0, "name": user.name, "email": user.email, "age": user.age]
  }
}
