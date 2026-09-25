package dev.nesmin.native_sqlite

import org.junit.After
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.RuntimeEnvironment
import org.robolectric.annotation.Config
import java.util.concurrent.Callable
import java.util.concurrent.Executors

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class NativeSqliteManagerDatabaseTest {
    private val manager = NativeSqliteManager.Instance
    private val executor = Executors.newSingleThreadExecutor()
    private val name = "manager_robolectric_test"

    @Before
    fun setUp() {
        manager.initialize(RuntimeEnvironment.getApplication())
        background { manager.deleteDatabase(name) }
    }

    @After
    fun tearDown() {
        background { manager.deleteDatabase(name) }
        executor.shutdownNow()
    }

    @Test
    fun realDatabaseCoversOpenMigrateBindQueryAndErrors() {
        background {
            manager.openDatabase(
                DatabaseConfig(
                    name = name,
                    onCreate = listOf(
                        "CREATE TABLE values_test (" +
                            "id INTEGER PRIMARY KEY, text_value TEXT, payload BLOB)"
                    ),
                )
            )

            assertEquals(
                1,
                manager.execute(
                    name,
                    "INSERT INTO values_test (id, text_value, payload) VALUES (?, ?, ?)",
                    listOf(1, "before\u0000after", byteArrayOf()),
                )
            )
            val row = manager.query(
                name,
                "SELECT text_value, payload FROM values_test WHERE id = ?",
                listOf(1),
            )["rows"] as List<*>
            val values = row.single() as List<*>
            assertEquals("before\u0000after", values[0])
            assertArrayEquals(byteArrayOf(), values[1] as ByteArray)

            assertEquals(0, manager.execute(name, "SELECT 1"))
            assertEquals(0, manager.execute(name, "PRAGMA cache_size = -1000"))
            assertThrows(android.database.sqlite.SQLiteException::class.java) {
                manager.execute(name, "SELEC broken")
            }
            manager.closeDatabase(name)

            manager.openDatabase(
                DatabaseConfig(
                    name = name,
                    version = 2,
                    onCreate = listOf(
                        "CREATE TABLE values_test (" +
                            "id INTEGER PRIMARY KEY, text_value TEXT, payload BLOB)"
                    ),
                    migrations = mapOf(
                        2 to listOf("ALTER TABLE values_test ADD COLUMN added INTEGER")
                    ),
                )
            )
            assertEquals(
                2L,
                (manager.query(name, "PRAGMA user_version")["rows"] as List<*>)
                    .let { (it.single() as List<*>).single() },
            )
        }
    }

    @Test
    fun readsRowsLargerThanTheDefaultCursorWindowAndNormalizesEmptyWhere() {
        background {
            manager.openDatabase(
                DatabaseConfig(
                    name = name,
                    onCreate = listOf(
                        "CREATE TABLE values_test (id INTEGER PRIMARY KEY, payload BLOB)"
                    ),
                )
            )
            val payload = ByteArray(3 * 1024 * 1024) { index -> (index % 251).toByte() }
            manager.insert(name, "values_test", mapOf("id" to 1, "payload" to payload))
            val rows = manager.query(
                name,
                "SELECT payload FROM values_test WHERE id = 1",
            )["rows"] as List<*>
            assertArrayEquals(payload, (rows.single() as List<*>).single() as ByteArray)

            manager.insert(name, "values_test", mapOf("id" to 2))
            assertEquals(2, manager.delete(name, "values_test", where = ""))
            assertThrows(IllegalArgumentException::class.java) {
                manager.delete(name, "values_test", whereArgs = listOf(1))
            }
        }
    }

    private fun <T> background(action: () -> T): T =
        executor.submit(Callable { action() }).get()
}
