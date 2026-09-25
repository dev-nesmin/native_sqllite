import Flutter
import native_sqlite_ios
import UIKit
import XCTest

class RunnerTests: XCTestCase {
  func testNativeSqliteManagerOpenMigrateBindAndErrors() throws {
    try onBackground {
      let manager = NativeSqliteManager.shared
      let name = "manager_xctest"
      try? manager.deleteDatabase(name: name)
      defer { try? manager.deleteDatabase(name: name) }

      let create = "CREATE TABLE values_test (id INTEGER PRIMARY KEY, text_value TEXT, payload BLOB)"
      let first = DatabaseConfig(
        name: name,
        onCreate: [create],
        enableWAL: false
      )
      let path = try manager.openDatabase(config: first)
      XCTAssertTrue(path.hasSuffix("/\(name).db"))
      XCTAssertEqual(
        try manager.execute(
          name: name,
          sql: "INSERT INTO values_test (id, text_value, payload) VALUES (?, ?, ?)",
          arguments: [1, "before\0after", Data()]
        ),
        1
      )

      let result = try manager.query(
        name: name,
        sql: "SELECT text_value, payload FROM values_test WHERE id = ?",
        arguments: [1]
      )
      let row = (result["rows"] as! [[Any?]]).first!
      XCTAssertEqual(row[0] as? String, "before\0after")
      XCTAssertEqual(row[1] as? Data, Data())

      let busy = try manager.query(name: name, sql: "PRAGMA busy_timeout")
      XCTAssertEqual((busy["rows"] as! [[Any?]])[0][0] as? Int64, 5_000)
      let journal = try manager.query(name: name, sql: "PRAGMA journal_mode")
      XCTAssertEqual((journal["rows"] as! [[Any?]])[0][0] as? String, "delete")
      XCTAssertEqual(try manager.execute(name: name, sql: "SELECT 1"), 0)
      XCTAssertThrowsError(try manager.execute(name: name, sql: "SELEC broken"))
      try manager.closeDatabase(name: name)

      let second = DatabaseConfig(
        name: name,
        version: 2,
        onCreate: [create],
        enableWAL: false,
        migrations: [
          2: ["ALTER TABLE values_test ADD COLUMN added INTEGER"]
        ]
      )
      _ = try manager.openDatabase(config: second)
      let version = try manager.query(name: name, sql: "PRAGMA user_version")
      XCTAssertEqual((version["rows"] as! [[Any?]])[0][0] as? Int64, 2)

      _ = try manager.insert(name: name, table: "values_test", values: ["id": 2])
      XCTAssertEqual(
        try manager.delete(name: name, table: "values_test", whereClause: ""),
        2
      )
      XCTAssertThrowsError(
        try manager.delete(name: name, table: "values_test", whereArgs: [1])
      )
    }
  }

  private func onBackground<T>(_ operation: @escaping () throws -> T) throws -> T {
    var outcome: Result<T, Error>!
    let finished = DispatchSemaphore(value: 0)
    DispatchQueue.global(qos: .userInitiated).async {
      outcome = Result { try operation() }
      finished.signal()
    }
    finished.wait()
    return try outcome.get()
  }
}
