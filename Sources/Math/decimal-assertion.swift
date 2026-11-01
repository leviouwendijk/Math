import Foundation

/// Deterministic comparisons of supplied and calculated decimal values.
/// The caller selects the rounding policy; this type does not define tax rules.
public enum DecimalAssertion {
    public struct Result: Sendable, Hashable {
        public let expected: Decimal
        public let observed: Decimal
        public let difference: Decimal
        public let tolerance: Decimal
        public let matches: Bool

        public init(
            expected: Decimal,
            observed: Decimal,
            difference: Decimal,
            tolerance: Decimal,
            matches: Bool
        ) {
            self.expected = expected
            self.observed = observed
            self.difference = difference
            self.tolerance = tolerance
            self.matches = matches
        }
    }

    public enum Failure: Error, Sendable {
        case negativeTolerance
    }

    public static func verify(
        expected: Decimal,
        observed: Decimal,
        tolerance: Decimal = .zero
    ) throws -> Result {
        guard tolerance >= .zero else {
            throw Failure.negativeTolerance
        }
        let difference = try DecimalArithmetic.unquantized(
            .subtract,
            lhs: observed,
            rhs: expected
        )
        return Result(
            expected: expected,
            observed: observed,
            difference: difference,
            tolerance: tolerance,
            matches: DecimalComparison.withinTolerance(
                observed,
                expected,
                tolerance: tolerance
            )
        )
    }

    /// `rate` is in percentage points (e.g. 21 means 21%).
    /// Quantization occurs once, at the final expected-value boundary.
    public static func percentage(
        of base: Decimal,
        rate: Decimal,
        observed: Decimal,
        scale: Int,
        mode: DecimalArithmetic.RoundingMode = .plain,
        tolerance: Decimal = .zero
    ) throws -> Result {
        let numerator = try DecimalArithmetic.unquantized(
            .multiply,
            lhs: base,
            rhs: rate
        )
        let unrounded = try DecimalArithmetic.unquantized(
            .divide,
            lhs: numerator,
            rhs: 100
        )
        let expected = try DecimalArithmetic.round(
            unrounded,
            scale: scale,
            mode: mode
        )
        return try verify(
            expected: expected,
            observed: observed,
            tolerance: tolerance
        )
    }
}
