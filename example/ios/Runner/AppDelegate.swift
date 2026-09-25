import Flutter
import BackgroundTasks
import UIKit
import native_sqlite_ios

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    NativeBackgroundSync.register()
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
      binaryMessenger: messenger,
      codec: FlutterStandardMethodCodec.sharedInstance(),
      taskQueue: messenger.makeBackgroundTaskQueue?()
    )
    channel.setMethodCallHandler { call, result in
      do {
        if call.method == "openDatabaseFromNative" {
          try DatabaseManager.shared.initialize()
          result(try DatabaseManager.shared.currentDatabase)
          return
        }
        if call.method == "closeDatabaseFromNative" {
          try DatabaseManager.shared.close()
          result(nil)
          return
        }
        if call.method == "stressNativeWrites" {
          try DatabaseManager.shared.initialize()
          let databaseName = try DatabaseManager.shared.currentDatabase
          DispatchQueue.global(qos: .userInitiated).async {
            do {
              let users = UserHelper(databaseName: databaseName)
              for index in 0..<200 {
                _ = try users.insert(User(
                  name: "Native stress \(index)",
                  email: "ios-stress-\(index)-\(UUID().uuidString)@native.dev",
                  age: 25,
                  isActive: true,
                  createdAt: Date()
                ))
              }
              DispatchQueue.main.async { result(200) }
            } catch {
              DispatchQueue.main.async {
                result(FlutterError(
                  code: "NATIVE_SQLITE_STRESS_ERROR",
                  message: "\(error)",
                  details: nil
                ))
              }
            }
          }
          return
        }

        // Reuses the connection Flutter opened, or opens and migrates it.
        try DatabaseManager.shared.initialize()
        let users = UserHelper(databaseName: try DatabaseManager.shared.currentDatabase)

        switch call.method {
        case "testNativeAccess":
          result(try runAccessTests(users))
        case "roundTripModelGallery":
          result(try roundTripModelGallery())
        case "scheduleBackgroundSync":
          try NativeBackgroundSync.schedule()
          result(NativeBackgroundSync.refreshIdentifier)
        case "enqueueBackgroundSyncNow":
          try NativeBackgroundSync.scheduleRefresh(earliestBeginDate: Date())
          result(nil)
        case "runBackgroundSyncNow":
          result(try NativeBackgroundSync.runTaskBody())
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
        case "createNoteFromNative":
          guard let args = call.arguments as? [String: Any],
                let body = args["body"] as? String else {
            result(FlutterError(code: "INVALID_ARGS", message: "body is required", details: nil))
            return
          }
          let notes = NoteHelper(databaseName: try DatabaseManager.shared.currentDatabase)
          result(try notes.insert(Note(body: body)))
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

  /// Exercises every generated native model/helper against the shared DB.
  private static func roundTripModelGallery() throws -> [String] {
    let database = try DatabaseManager.shared.currentDatabase
    let suffix = UUID().uuidString
    let now = Date()
    var passed: [String] = []

    let users = UserHelper(databaseName: database)
    let userID = try users.insert(User(
      name: "Gallery User",
      email: "ios-gallery-\(suffix)@example.com",
      age: 29,
      isActive: true,
      createdAt: now
    ))
    try require(try users.findById(userID)?.name == "Gallery User", "User")
    passed.append("User")

    let categories = CategoryHelper(databaseName: database)
    let categoryID = try categories.insert(Category(
      name: "iOS Gallery \(suffix)",
      createdAt: now
    ))
    try require(
      try categories.findById(categoryID)?.name == "iOS Gallery \(suffix)",
      "Category"
    )
    passed.append("Category")

    let products = ProductHelper(databaseName: database)
    let productID = try products.insert(Product(
      name: "Native Product \(suffix)",
      price: 19.95,
      stock: 7,
      isAvailable: true,
      categoryId: categoryID,
      createdAt: now
    ))
    try require(try products.findById(productID)?.categoryId == categoryID, "Product")
    passed.append("Product")

    let orders = OrderHelper(databaseName: database)
    let orderID = try orders.insert(Order(
      userId: userID,
      productId: productID,
      quantity: 2,
      totalPrice: 39.90,
      status: .processing,
      createdAt: now
    ))
    try require(try orders.findById(orderID)?.status == .processing, "Order")
    passed.append("Order")

    let profiles = ProfileHelper(databaseName: database)
    let profileID = try profiles.insert(Profile(
      name: "Native Profile",
      email: "ios-profile-\(suffix)@example.com",
      settings: "{\"dark\":true}",
      tags: "[\"native\"]",
      metadata: "{\"source\":\"ios\"}"
    ))
    try require(
      try profiles.findById(profileID)?.settings == "{\"dark\":true}",
      "Profile"
    )
    passed.append("Profile")

    let advanced = AdvancedUserHelper(databaseName: database)
    let advancedID = try advanced.insert(AdvancedUser(
      name: "Native Advanced \(suffix)",
      loginDuration: 720,
      profileUrl: URL(string: "https://example.com/\(suffix)"),
      score: 98.5,
      status: .suspended,
      priority: .urgent,
      createdAt: now,
      isVerified: true
    ))
    try require(try advanced.findById(advancedID)?.priority == .urgent, "AdvancedUser")
    passed.append("AdvancedUser")

    let freezed = FreezedAdvancedUserHelper(databaseName: database)
    let freezedID = try freezed.insert(FreezedAdvancedUser(
      name: "Native Freezed \(suffix)",
      loginDuration: 45,
      profileUrl: URL(string: "https://example.com/freezed/\(suffix)"),
      status: .active,
      priority: .high,
      createdAt: now,
      isVerified: false
    ))
    try require(
      try freezed.findById(freezedID)?.loginDuration == 45,
      "FreezedAdvancedUser"
    )
    passed.append("FreezedAdvancedUser")

    let styled = StyledItemHelper(databaseName: database)
    let styledID = try styled.insert(StyledItem(
      name: "Native Styled \(suffix)",
      backgroundColor: 0xff123456,
      textColor: 0xffabcdef,
      tags: "[\"comma,value\",\"native\"]",
      createdAt: now
    ))
    try require(
      try styled.findById(styledID)?.tags == "[\"comma,value\",\"native\"]",
      "StyledItem"
    )
    passed.append("StyledItem")

    let notes = NoteHelper(databaseName: database)
    let noteID = try notes.insert(Note(body: "Native Note \(suffix)"))
    try require(try notes.findById(noteID)?.body == "Native Note \(suffix)", "Note")
    passed.append("Note")

    let attachments = AttachmentHelper(databaseName: database)
    let bytes = Data([0, 1, 2, 127, 128, 255])
    let attachmentID = try attachments.insert(Attachment(
      filename: "native-\(suffix).bin",
      bytes: bytes
    ))
    try require(try attachments.findById(attachmentID)?.bytes == bytes, "Attachment")
    passed.append("Attachment")

    let tags = TagHelper(databaseName: database)
    let tagID = try tags.insert(Tag(label: "ios-gallery-\(suffix)"))
    try require(try tags.findById(tagID)?.label == "ios-gallery-\(suffix)", "Tag")
    passed.append("Tag")

    let comments = CommentHelper(databaseName: database)
    let parentID = try comments.insert(Comment(body: "Native parent \(suffix)"))
    let childID = try comments.insert(Comment(
      parentId: parentID,
      body: "Native child \(suffix)"
    ))
    try require(try comments.findById(childID)?.parentId == parentID, "Comment parent")
    _ = try comments.delete(id: parentID)
    try require(try comments.findById(childID)?.parentId == nil, "Comment SET NULL")
    passed.append("Comment")

    let syncEvents = SyncEventHelper(databaseName: database)
    let syncEventID = try syncEvents.insert(SyncEvent(
      source: "native-gallery",
      message: "Native helper round-trip",
      createdAt: now
    ))
    try require(
      try syncEvents.findById(syncEventID)?.source == "native-gallery",
      "SyncEvent"
    )
    passed.append("SyncEvent")

    return passed
  }

  private static func require(_ condition: @autoclosure () throws -> Bool, _ model: String) throws {
    guard try condition() else {
      throw NSError(
        domain: "ModelGallery",
        code: 1,
        userInfo: [NSLocalizedDescriptionKey: "\(model) did not round-trip"]
      )
    }
  }

  private static func toMap(_ user: User) -> [String: Any] {
    ["id": user.id ?? 0, "name": user.name, "email": user.email, "age": user.age]
  }
}

enum NativeBackgroundSync {
  static let refreshIdentifier = "dev.nesmin.native-sqlite-example.refresh"
  static let processingIdentifier = "dev.nesmin.native-sqlite-example.processing"

  static func register() {
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: refreshIdentifier,
      using: nil
    ) { task in
      guard let refreshTask = task as? BGAppRefreshTask else {
        task.setTaskCompleted(success: false)
        return
      }
      handle(refreshTask)
    }
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: processingIdentifier,
      using: nil
    ) { task in
      guard let processingTask = task as? BGProcessingTask else {
        task.setTaskCompleted(success: false)
        return
      }
      handle(processingTask)
    }
  }

  static func schedule() throws {
    try scheduleRefresh()
    let request = BGProcessingTaskRequest(identifier: processingIdentifier)
    request.earliestBeginDate = Date(timeIntervalSinceNow: 60 * 60)
    request.requiresNetworkConnectivity = false
    request.requiresExternalPower = false
    try BGTaskScheduler.shared.submit(request)
  }

  static func scheduleRefresh(earliestBeginDate: Date? = nil) throws {
    let request = BGAppRefreshTaskRequest(identifier: refreshIdentifier)
    request.earliestBeginDate = earliestBeginDate ?? Date(timeIntervalSinceNow: 15 * 60)
    try BGTaskScheduler.shared.submit(request)
  }

  static func runTaskBody() throws -> Int64 {
    try DatabaseManager.shared.initialize()
    let events = SyncEventHelper(databaseName: try DatabaseManager.shared.currentDatabase)
    return try events.insert(SyncEvent(
      source: "native-worker",
      message: "iOS BackgroundTasks sync",
      createdAt: Date()
    ))
  }

  private static func handle(_ task: BGAppRefreshTask) {
    try? scheduleRefresh()
    execute(task)
  }

  private static func handle(_ task: BGProcessingTask) {
    try? schedule()
    execute(task)
  }

  private static func execute(_ task: BGTask) {
    task.expirationHandler = {
      task.setTaskCompleted(success: false)
    }
    DispatchQueue.global(qos: .utility).async {
      do {
        _ = try runTaskBody()
        task.setTaskCompleted(success: true)
      } catch {
        task.setTaskCompleted(success: false)
      }
    }
  }
}
