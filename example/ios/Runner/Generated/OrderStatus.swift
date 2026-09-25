import Foundation

/**
 * Mirrors the Dart enum OrderStatus.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 */
public enum OrderStatus: String, CaseIterable {
    case pending
    case processing
    case shipped
    case delivered
    case cancelled

    /// Index of this case, equal to the Dart enum's `index`.
    public var ordinal: Int64 {
        Int64(Self.allCases.firstIndex(of: self)!)
    }

    public init?(ordinal: Int64) {
        let cases = Array(Self.allCases)
        guard ordinal >= 0, ordinal < Int64(cases.count) else { return nil }
        self = cases[Int(ordinal)]
    }
}
