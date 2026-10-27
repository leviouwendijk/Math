import Foundation

public enum DecimalInterpolation {
    /// Linear interpolation; position is dimensionless. Allows extrapolation (<0 or >1).
    public static func linear(
        from start: Decimal, to end: Decimal, position: Decimal, scale: Int = 12
    ) throws -> Decimal {
        let span = try DecimalArithmetic.unquantized(.subtract, lhs: end, rhs: start)
        let offset = try DecimalArithmetic.unquantized(.multiply, lhs: span, rhs: position)
        let value = try DecimalArithmetic.unquantized(.add, lhs: start, rhs: offset)
        return try DecimalArithmetic.round(value, scale: scale)
    }
}
