package com.example.native_sqlite_example

import android.net.Uri
import com.example.native_sqlite_example.generated.*
import dev.nesmin.native_sqlite.NativeSqliteManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import java.time.Duration
import java.time.Instant

/**
 * Handles the example's "Native Integration" screen: the same database the
 * Flutter side uses, accessed from Kotlin through the generated helpers.
 */
class MainActivity : FlutterActivity() {

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(
            messenger,
            "com.example.native_sqlite_example/native",
            StandardMethodCodec.INSTANCE,
            messenger.makeBackgroundTaskQueue(),
        ).setMethodCallHandler { call, result ->
            try {
                if (call.method == "openDatabaseFromNative") {
                    DatabaseManager.init(applicationContext)
                    result.success(DatabaseManager.currentDatabase)
                    return@setMethodCallHandler
                }
                if (call.method == "closeDatabaseFromNative") {
                    DatabaseManager.close()
                    result.success(null)
                    return@setMethodCallHandler
                }

                // Reuses the connection Flutter opened, or opens and migrates it.
                DatabaseManager.init(applicationContext)
                val users = UserHelper(DatabaseManager.currentDatabase)

                when (call.method) {
                    "testNativeAccess" -> result.success(runAccessTests(users))
                    "roundTripModelGallery" -> result.success(roundTripModelGallery())
                    "scheduleBackgroundSync" -> {
                        NativeSyncTask.schedulePeriodic(applicationContext)
                        result.success(NativeSyncTask.periodicWorkName)
                    }
                    "enqueueBackgroundSyncNow" -> {
                        NativeSyncTask.enqueueNow(applicationContext)
                        result.success(null)
                    }
                    "runBackgroundSyncNow" -> result.success(
                        NativeSyncTask.run(applicationContext)
                    )
                    "createUserFromNative" -> {
                        val name = call.argument<String>("name")
                        val email = call.argument<String>("email")
                        if (name == null || email == null) {
                            result.error("INVALID_ARGS", "name and email are required", null)
                        } else {
                            result.success(
                                users.insert(
                                    User(name = name, email = email, age = 25, isActive = true, createdAt = Instant.now())
                                )
                            )
                        }
                    }
                    "getUsersFromNative" -> result.success(
                        users.findWhere(orderBy = "${UserSchema.CREATED_AT} DESC", limit = 10).map(::toMap)
                    )
                    "createNoteFromNative" -> {
                        val body = call.argument<String>("body")
                        if (body == null) {
                            result.error("INVALID_ARGS", "body is required", null)
                        } else {
                            val notes = NoteHelper(DatabaseManager.currentDatabase)
                            result.success(notes.insert(Note(body = body)))
                        }
                    }
                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                result.error("NATIVE_SQLITE_ERROR", e.message, null)
            }
        }
    }

    private fun runAccessTests(users: UserHelper): String = buildString {
        appendLine("Native SQLite access from Kotlin\n")

        val id = users.insert(
            User(
                name = "Native Android User",
                email = "android${System.currentTimeMillis()}@native.dev",
                age = 30,
                isActive = true,
                createdAt = Instant.now(),
            )
        )
        appendLine("✓ Inserted user #$id")

        val user = checkNotNull(users.findById(id)) { "User #$id not found" }
        appendLine("✓ Read back: ${user.name} <${user.email}>, created ${user.createdAt}")

        val updated = users.update(user.copy(name = "Updated Native User", updatedAt = Instant.now()))
        appendLine("✓ Updated $updated row(s)")

        val active = users.count("${UserSchema.IS_ACTIVE} = ?", listOf(1))
        appendLine("✓ Active users: $active")

        val joined = NativeSqliteManager.Instance.query(
            DatabaseManager.currentDatabase,
            """
            SELECT u.${UserSchema.NAME} AS user_name, COUNT(o.${OrderSchema.ID}) AS order_count
            FROM ${UserSchema.TABLE_NAME} u
            LEFT JOIN ${OrderSchema.TABLE_NAME} o ON o.${OrderSchema.USER_ID} = u.${UserSchema.ID}
            GROUP BY u.${UserSchema.ID} LIMIT 5
            """.trimIndent(),
        )
        @Suppress("UNCHECKED_CAST")
        val rows = joined["rows"] as? List<List<Any?>> ?: emptyList()
        appendLine("✓ JOIN returned ${rows.size} row(s)")
        rows.forEach { appendLine("  - ${it[0]}: ${it[1]} orders") }

        append("\n✅ All native access tests passed")
    }

    /** Exercises every generated native model/helper against the shared DB. */
    private fun roundTripModelGallery(): List<String> {
        val database = DatabaseManager.currentDatabase
        val suffix = System.nanoTime().toString()
        val now = Instant.now()
        val passed = mutableListOf<String>()

        val users = UserHelper(database)
        val userId = users.insert(
            User(name = "Gallery User", email = "android-gallery-$suffix@example.com", age = 29, isActive = true, createdAt = now)
        )
        check(users.findById(userId)?.name == "Gallery User")
        passed += "User"

        val categories = CategoryHelper(database)
        val categoryId = categories.insert(Category(name = "Android Gallery $suffix", createdAt = now))
        check(categories.findById(categoryId)?.name == "Android Gallery $suffix")
        passed += "Category"

        val products = ProductHelper(database)
        val productId = products.insert(
            Product(name = "Native Product $suffix", price = 19.95, stock = 7, isAvailable = true, categoryId = categoryId, createdAt = now)
        )
        check(products.findById(productId)?.categoryId == categoryId)
        passed += "Product"

        val orders = OrderHelper(database)
        val orderId = orders.insert(
            Order(userId = userId, productId = productId, quantity = 2, totalPrice = 39.90, status = OrderStatus.processing, createdAt = now)
        )
        check(orders.findById(orderId)?.status == OrderStatus.processing)
        passed += "Order"

        val profiles = ProfileHelper(database)
        val profileId = profiles.insert(
            Profile(name = "Native Profile", email = "android-profile-$suffix@example.com", settings = "{\"dark\":true}", tags = "[\"native\"]", metadata = "{\"source\":\"android\"}")
        )
        check(profiles.findById(profileId)?.settings == "{\"dark\":true}")
        passed += "Profile"

        val advanced = AdvancedUserHelper(database)
        val advancedId = advanced.insert(
            AdvancedUser(
                name = "Native Advanced $suffix",
                loginDuration = Duration.ofMinutes(12),
                profileUrl = Uri.parse("https://example.com/$suffix"),
                score = 98.5,
                status = UserStatus.suspended,
                priority = Priority.urgent,
                createdAt = now,
                isVerified = true,
            )
        )
        check(advanced.findById(advancedId)?.priority == Priority.urgent)
        passed += "AdvancedUser"

        val freezed = FreezedAdvancedUserHelper(database)
        val freezedId = freezed.insert(
            FreezedAdvancedUser(
                name = "Native Freezed $suffix",
                loginDuration = Duration.ofSeconds(45),
                profileUrl = Uri.parse("https://example.com/freezed/$suffix"),
                status = UserStatus.active,
                priority = Priority.high,
                createdAt = now,
                isVerified = false,
            )
        )
        check(freezed.findById(freezedId)?.loginDuration == Duration.ofSeconds(45))
        passed += "FreezedAdvancedUser"

        val styled = StyledItemHelper(database)
        val styledId = styled.insert(
            StyledItem(
                name = "Native Styled $suffix",
                backgroundColor = 0xff123456,
                textColor = 0xffabcdef,
                tags = "[\"comma,value\",\"native\"]",
                createdAt = now,
            )
        )
        check(styled.findById(styledId)?.tags == "[\"comma,value\",\"native\"]")
        passed += "StyledItem"

        val notes = NoteHelper(database)
        val noteId = notes.insert(Note(body = "Native Note $suffix"))
        check(notes.findById(noteId)?.body == "Native Note $suffix")
        passed += "Note"

        val attachments = AttachmentHelper(database)
        val bytes = byteArrayOf(0, 1, 2, 127, -128, -1)
        val attachmentId = attachments.insert(Attachment(filename = "native-$suffix.bin", bytes = bytes))
        check(attachments.findById(attachmentId)?.bytes?.contentEquals(bytes) == true)
        passed += "Attachment"

        val tags = TagHelper(database)
        val tagId = tags.insert(Tag(label = "android-gallery-$suffix"))
        check(tags.findById(tagId)?.label == "android-gallery-$suffix")
        passed += "Tag"

        val comments = CommentHelper(database)
        val parentId = comments.insert(Comment(body = "Native parent $suffix"))
        val childId = comments.insert(Comment(parentId = parentId, body = "Native child $suffix"))
        check(comments.findById(childId)?.parentId == parentId)
        comments.delete(parentId)
        check(comments.findById(childId)?.parentId == null)
        passed += "Comment"

        val syncEvents = SyncEventHelper(database)
        val syncEventId = syncEvents.insert(
            SyncEvent(source = "native-gallery", message = "Native helper round-trip", createdAt = now)
        )
        check(syncEvents.findById(syncEventId)?.source == "native-gallery")
        passed += "SyncEvent"

        return passed
    }

    private fun toMap(user: User): Map<String, Any?> = mapOf(
        "id" to user.id,
        "name" to user.name,
        "email" to user.email,
        "age" to user.age,
    )
}
