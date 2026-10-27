import Foundation

public enum DecimalStatistics {
    public enum Failure: Error, Sendable { case insufficientSamples; case invalidPercentile }

    public static func population_variance(_ values: [Decimal], scale: Int = 12) throws -> Decimal {
        guard !values.isEmpty else { throw Failure.insufficientSamples }
        return try variance(values, denominator: values.count, scale: scale)
    }

    public static func sample_variance(_ values: [Decimal], scale: Int = 12) throws -> Decimal {
        guard values.count > 1 else { throw Failure.insufficientSamples }
        return try variance(values, denominator: values.count - 1, scale: scale)
    }

    private static func variance(_ values: [Decimal], denominator: Int, scale: Int) throws -> Decimal {
        let mean = try DecimalAggregation.mean(values, scale: 16)
        var squares = Decimal.zero
        for value in values {
            let delta = try DecimalArithmetic.unquantized(.subtract, lhs: value, rhs: mean)
            let square = try DecimalArithmetic.unquantized(.multiply, lhs: delta, rhs: delta)
            squares = try DecimalArithmetic.unquantized(.add, lhs: squares, rhs: square)
        }
        return try DecimalRatio.divide(squares, by: Decimal(denominator), scale: scale)
    }

    /// Inclusive percentile 0...100 with linear interpolation between ordered observations.
    public static func percentile(_ values: [Decimal], at percent: Decimal, scale: Int = 12) throws -> Decimal {
        guard !values.isEmpty else { throw Failure.insufficientSamples }
        guard percent >= .zero, percent <= 100 else { throw Failure.invalidPercentile }
        let sorted = values.sorted()
        if sorted.count == 1 { return sorted[0] }
        let fraction = try DecimalRatio.divide(percent, by: 100, scale: 16)
        let rank = try DecimalArithmetic.unquantized(.multiply, lhs: fraction, rhs: Decimal(sorted.count - 1))
        let floor = try DecimalArithmetic.round(rank, scale: 0, mode: .down)
        let low = NSDecimalNumber(decimal: floor).intValue
        let high = Swift.min(low + 1, sorted.count - 1)
        let position = try DecimalArithmetic.unquantized(.subtract, lhs: rank, rhs: floor)
        return try DecimalInterpolation.linear(from: sorted[low], to: sorted[high], position: position, scale: scale)
    }
}
