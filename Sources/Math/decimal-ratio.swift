import Foundation

/// General dimensionless ratios. Rates are fractions until explicitly converted to percentages.
public enum DecimalRatio {
    public enum Failure: Error, Sendable { case zeroBaseline }

    public static func divide(
        _ numerator: Decimal, by denominator: Decimal, scale: Int = 12
    ) throws -> Decimal {
        try DecimalArithmetic.calculate(
            .divide, lhs: numerator, rhs: denominator, scale: scale
        )
    }

    public static func proportion(
        _ part: Decimal, of whole: Decimal, scale: Int = 12
    ) throws -> Decimal {
        try divide(part, by: whole, scale: scale)
    }

    /// Fractional signed change; uses absolute previous magnitude so negative baselines do not invert direction.
    public static func relative_change(
        from previous: Decimal, to current: Decimal, scale: Int = 12
    ) throws -> Decimal {
        guard previous != .zero else { throw Failure.zeroBaseline }
        let numerator = try DecimalArithmetic.unquantized(.subtract, lhs: current, rhs: previous)
        let denominator = previous < .zero ? -previous : previous
        return try divide(numerator, by: denominator, scale: scale)
    }

    /// Percentage points (e.g. 0.15 relative change -> 15); never silently returns a fraction.
    public static func percentage_change(
        from previous: Decimal, to current: Decimal, scale: Int = 12
    ) throws -> Decimal {
        let fraction = try relative_change(from: previous, to: current, scale: 16)
        let percent = try DecimalArithmetic.unquantized(.multiply, lhs: fraction, rhs: 100)
        return try DecimalArithmetic.round(percent, scale: scale)
    }
}
