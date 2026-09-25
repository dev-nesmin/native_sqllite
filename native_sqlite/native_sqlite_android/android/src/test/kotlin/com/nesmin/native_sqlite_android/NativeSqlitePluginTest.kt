package dev.nesmin.native_sqlite

import android.content.Context
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test
import org.mockito.ArgumentMatchers
import org.mockito.Mock
import org.mockito.Mockito
import org.mockito.Mockito.never
import org.mockito.Mockito.verify
import org.mockito.Mockito.`when`
import org.mockito.MockitoAnnotations

class NativeSqlitePluginTest {
    @Mock
    lateinit var mockManager: NativeSqliteManager

    @Mock
    lateinit var mockResult: MethodChannel.Result

    @Mock
    lateinit var mockFlutterPluginBinding: FlutterPlugin.FlutterPluginBinding

    @Mock
    lateinit var mockContext: Context

    @Mock
    lateinit var mockBinaryMessenger: BinaryMessenger

    private lateinit var plugin: NativeSqlitePlugin

    @Before
    fun setUp() {
        MockitoAnnotations.openMocks(this)

        `when`(mockContext.applicationContext).thenReturn(mockContext)
        `when`(mockFlutterPluginBinding.applicationContext).thenReturn(mockContext)
        `when`(mockFlutterPluginBinding.binaryMessenger).thenReturn(mockBinaryMessenger)

        plugin = createPlugin()
        plugin.onAttachedToEngine(mockFlutterPluginBinding)
    }

    // Safe matchers to avoid NPE with Kotlin non-nullable types
    private fun <T> any(type: Class<T>): T {
        Mockito.any(type)
        return createInstance(type)
    }

    private fun <T> eq(value: T): T {
        Mockito.eq(value)
        return value
    }

    @Suppress("UNCHECKED_CAST")
    private fun <T> createInstance(type: Class<T>): T {
        return when (type) {
            String::class.java -> "" as T
            Integer::class.java, Int::class.java -> 0 as T
            Long::class.java -> 0L as T
            Boolean::class.java -> false as T
            Map::class.java -> mapOf<Any, Any>() as T
            List::class.java -> listOf<Any>() as T
            DatabaseConfig::class.java -> DatabaseConfig(name = "test") as T
            else -> Mockito.any(type) // Fallback, might return null
        }
    }

    @Test
    fun `openDatabase calls manager and returns path`() {
        val dbName = "test_db"
        val dbPath = "/path/to/test_db.db"
        val arguments = mapOf(
            "name" to dbName,
            "version" to 1,
            "enableWAL" to true,
            "enableForeignKeys" to true
        )
        val call = MethodCall("openDatabase", arguments)

        `when`(mockManager.openDatabase(any(DatabaseConfig::class.java))).thenReturn(dbPath)

        plugin.onMethodCall(call, mockResult)

        verify(mockManager).openDatabase(any(DatabaseConfig::class.java))
        verify(mockResult).success(dbPath)
    }

    @Test
    fun `insert calls manager and returns row id`() {
        val dbName = "test_db"
        val table = "users"
        val values = mapOf("name" to "John", "age" to 30)
        val rowId = 123L
        
        val arguments = mapOf(
            "name" to dbName,
            "table" to table,
            "values" to values
        )
        val call = MethodCall("insert", arguments)

        `when`(
            mockManager.insert(
                eq(dbName),
                eq(table),
                any(Map::class.java) as Map<String, Any?>,
                ArgumentMatchers.isNull(),
            )
        ).thenReturn(rowId)

        plugin.onMethodCall(call, mockResult)

        verify(mockManager).insert(eq(dbName), eq(table), eq(values), ArgumentMatchers.isNull())
        verify(mockResult).success(rowId)
    }

    @Test
    fun `query calls manager and returns result`() {
        val dbName = "test_db"
        val sql = "SELECT * FROM users"
        val queryArgs = listOf<Any?>()
        val queryResult = mapOf(
            "columns" to listOf("id", "name"),
            "rows" to listOf(listOf(1, "John"))
        )

        val arguments = mapOf(
            "name" to dbName,
            "sql" to sql,
            "arguments" to queryArgs
        )
        val call = MethodCall("query", arguments)

        `when`(
            mockManager.query(
                eq(dbName),
                eq(sql),
                any(List::class.java),
                ArgumentMatchers.isNull(),
            )
        ).thenReturn(queryResult)

        plugin.onMethodCall(call, mockResult)

        verify(mockManager).query(eq(dbName), eq(sql), eq(queryArgs), ArgumentMatchers.isNull())
        verify(mockResult).success(queryResult)
    }

    @Test
    fun `execute calls manager and returns rows affected`() {
        val dbName = "test_db"
        val sql = "DELETE FROM users WHERE id = ?"
        val execArgs = listOf(1)
        val rowsAffected = 1

        val arguments = mapOf(
            "name" to dbName,
            "sql" to sql,
            "arguments" to execArgs
        )
        val call = MethodCall("execute", arguments)

        `when`(
            mockManager.execute(
                eq(dbName),
                eq(sql),
                any(List::class.java),
                ArgumentMatchers.isNull(),
            )
        ).thenReturn(rowsAffected)

        plugin.onMethodCall(call, mockResult)

        verify(mockManager).execute(eq(dbName), eq(sql), eq(execArgs), ArgumentMatchers.isNull())
        verify(mockResult).success(rowsAffected)
    }

    @Test
    fun `error handling returns error result`() {
        val call = MethodCall("openDatabase", null) // Missing arguments

        plugin.onMethodCall(call, mockResult)

        verify(mockResult).error(
            eq("NATIVE_SQLITE_ERROR"),
            eq("Database name is required"),
            ArgumentMatchers.nullable(Any::class.java)
        )
    }

    @Test
    fun `detaching one engine leaves shared databases available to another engine`() {
        val secondPlugin = createPlugin()
        secondPlugin.onAttachedToEngine(mockFlutterPluginBinding)
        val queryResult = mapOf(
            "columns" to listOf("value"),
            "rows" to listOf(listOf(1))
        )
        `when`(mockManager.query("shared", "SELECT 1", emptyList())).thenReturn(queryResult)

        plugin.onDetachedFromEngine(mockFlutterPluginBinding)
        secondPlugin.onMethodCall(
            MethodCall(
                "query",
                mapOf("name" to "shared", "sql" to "SELECT 1", "arguments" to emptyList<Any?>())
            ),
            mockResult
        )

        verify(mockManager, never()).closeAll()
        verify(mockManager).query("shared", "SELECT 1", emptyList())
        verify(mockResult).success(queryResult)
    }

    @Test
    fun `database work and result delivery use their dispatchers`() {
        val tasks = mutableListOf<() -> Unit>()
        val completions = mutableListOf<() -> Unit>()
        val queuedPlugin = NativeSqlitePlugin(
            mockManager,
            taskDispatcher = { name, action ->
                assertEquals("worker_db", name)
                tasks += action
            },
            resultDispatcher = { action -> completions += action },
        )
        val queryResult = mapOf(
            "columns" to listOf("value"),
            "rows" to listOf(listOf(1))
        )
        `when`(mockManager.query("worker_db", "SELECT 1", emptyList())).thenReturn(queryResult)

        queuedPlugin.onMethodCall(
            MethodCall(
                "query",
                mapOf("name" to "worker_db", "sql" to "SELECT 1", "arguments" to emptyList<Any?>())
            ),
            mockResult
        )

        verify(mockManager, never()).query("worker_db", "SELECT 1", emptyList())
        tasks.single().invoke()
        verify(mockManager).query("worker_db", "SELECT 1", emptyList())
        verify(mockResult, never()).success(queryResult)
        completions.single().invoke()
        verify(mockResult).success(queryResult)
    }

    private fun createPlugin() = NativeSqlitePlugin(
        mockManager,
        taskDispatcher = { _, action -> action() },
        resultDispatcher = { action -> action() },
    )
}
