package dev.nesmin.native_sqlite

import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test

class NativeSqliteManagerTest {
    @Test
    fun quoteIdentifierEscapesEmbeddedQuotes() {
        assertEquals("\"order\"", NativeSqliteManager.quoteIdentifier("order"))
        assertEquals("\"odd\"\"name\"", NativeSqliteManager.quoteIdentifier("odd\"name"))
    }

    @Test
    fun requireSingleStatementRejectsOnlyExecutableTails() {
        NativeSqliteManager.requireSingleStatement(
            "SELECT ';' AS value; -- a trailing comment\n"
        )
        NativeSqliteManager.requireSingleStatement(
            "/* leading ; */ SELECT \"semi;colon\" FROM [table;name];"
        )

        assertThrows(IllegalArgumentException::class.java) {
            NativeSqliteManager.requireSingleStatement("SELECT 1; SELECT 2")
        }
    }
}
