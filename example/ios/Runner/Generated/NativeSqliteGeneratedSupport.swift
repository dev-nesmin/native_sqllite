import Foundation

/**
 * Row decoding support for generated helpers.
 * AUTO-GENERATED - DO NOT EDIT MANUALLY
 */
public enum GeneratedRowError: Error, CustomStringConvertible {
    case missingColumn(String)
    case unexpectedValue(column: String, expected: String, value: Any?)

    public var description: String {
        switch self {
        case .missingColumn(let column):
            return "Column '\(column)' is missing from the query result"
        case .unexpectedValue(let column, let expected, let value):
            return "Column '\(column)': expected \(expected), got \(String(describing: value))"
        }
    }
}

/// A result row addressed by column name.
struct GeneratedRow {
    let columnMap: [String: Int]
    let values: [Any?]

    func optional<T>(_ column: String, _ convert: (Any) -> T?, expected: String) throws -> T? {
        guard let index = columnMap[column] else {
            throw GeneratedRowError.missingColumn(column)
        }
        guard let value = GeneratedRow.unwrap(values[index]) else { return nil }
        guard let converted = convert(value) else {
            throw GeneratedRowError.unexpectedValue(column: column, expected: expected, value: value)
        }
        return converted
    }

    /// Flattens nested optionals and maps NSNull to nil.
    static func unwrap(_ value: Any?) -> Any? {
        guard let value = value, !(value is NSNull) else { return nil }
        let mirror = Mirror(reflecting: value)
        if mirror.displayStyle == .optional {
            return unwrap(mirror.children.first?.value)
        }
        return value
    }

    func required<T>(_ column: String, _ convert: (Any) -> T?, expected: String) throws -> T {
        guard let value = try optional(column, convert, expected: expected) else {
            throw GeneratedRowError.unexpectedValue(column: column, expected: expected, value: nil)
        }
        return value
    }
}

/// Conversions from SQLite values (Int64, Double, String, Data) to Swift
/// types, using the same storage formats as the Dart side.
enum GeneratedValue {
    static func int64(_ value: Any) -> Int64? {
        (value as? Int64) ?? (value as? Int).map(Int64.init)
    }

    static func double(_ value: Any) -> Double? {
        (value as? Double) ?? int64(value).map(Double.init)
    }

    static func string(_ value: Any) -> String? { value as? String }

    static func data(_ value: Any) -> Data? { value as? Data }

    /// Dart decodes booleans with `== 1`.
    static func bool(_ value: Any) -> Bool? { int64(value).map { $0 == 1 } }

    /// Milliseconds since epoch.
    static func date(_ value: Any) -> Date? {
        int64(value).map { Date(timeIntervalSince1970: Double($0) / 1000) }
    }

    /// Milliseconds.
    static func timeInterval(_ value: Any) -> TimeInterval? {
        int64(value).map { Double($0) / 1000 }
    }

    static func url(_ value: Any) -> URL? { string(value).flatMap(URL.init(string:)) }

    static func milliseconds(_ date: Date) -> Int64 {
        Int64((date.timeIntervalSince1970 * 1000).rounded())
    }

    static func milliseconds(_ interval: TimeInterval) -> Int64 {
        Int64((interval * 1000).rounded())
    }
}
