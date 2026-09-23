import Foundation

/**
 * Mirrors the Dart enum UserStatus.
 * AUTO-GENERATED from Dart - DO NOT EDIT MANUALLY
 */
public enum UserStatus: String, CaseIterable {
    case active
    case inactive
    case suspended

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
