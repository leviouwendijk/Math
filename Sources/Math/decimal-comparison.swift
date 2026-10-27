import Foundation

/// Exact base-10 comparisons; tolerance is symmetric about zero.
public enum DecimalComparison {
    public enum Relation: String, Sendable, Codable, Hashable, CaseIterable {
        case less
        case equal
        case greater
    }

    public static func compare(_ lhs: Decimal, _ rhs: Decimal) -> Relation {
        if lhs < rhs { return .less }
        if lhs > rhs { return .greater }
        return .equal
    }

    /// True only when abs(difference) is strictly greater than abs(tolerance).
    public static func exceeds(
        _ difference: Decimal,
        tolerance: Decimal
    ) -> Bool {
        let limit = tolerance < .zero ? -tolerance : tolerance
        return difference < -limit || difference > limit
    }

    public static func withinTolerance(
        _ lhs: Decimal,
        _ rhs: Decimal,
        tolerance: Decimal
    ) -> Bool {
        !exceeds(lhs - rhs, tolerance: tolerance)
    }
}
