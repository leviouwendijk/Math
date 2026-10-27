import Foundation

/// Pure positional transformations; callers retain or reindex their own X labels.
public enum DecimalSeries {
    public enum Failure: Error, Sendable { case emptyValues; case invalidWindow; case zeroRange }

    public static func difference(_ values: [Decimal]) throws -> [Decimal] {
        guard !values.isEmpty else { throw Failure.emptyValues }
        guard values.count > 1 else { return [] }
        var output: [Decimal] = []
        for i in 1..<values.count {
            output.append(try DecimalArithmetic.unquantized(.subtract, lhs: values[i], rhs: values[i - 1]))
        }
        return output
    }

    public static func relative_change(_ values: [Decimal], scale: Int = 12) throws -> [Decimal] {
        guard !values.isEmpty else { throw Failure.emptyValues }
        guard values.count > 1 else { return [] }
        var output: [Decimal] = []
        for i in 1..<values.count {
            output.append(try DecimalRatio.relative_change(from: values[i - 1], to: values[i], scale: scale))
        }
        return output
    }

    public static func cumulative(_ values: [Decimal]) throws -> [Decimal] {
        var total = Decimal.zero
        var result: [Decimal] = []
        for value in values {
            total = try DecimalArithmetic.unquantized(.add, lhs: total, rhs: value)
            result.append(total)
        }
        return result
    }

    public static func moving_mean(
        _ values: [Decimal], window: Int, scale: Int = 12
    ) throws -> [Decimal] {
        guard window > 0, window <= values.count else { throw Failure.invalidWindow }
        var results: [Decimal] = []
        for end in (window - 1)..<values.count {
            let beginning = end + 1 - window
            results.append(try DecimalAggregation.mean(Array(values[beginning...end]), scale: scale))
        }
        return results
    }

    /// Min-max map to 0...1; constant series are undefined, not silently all zero.
    public static func normalize(_ values: [Decimal], scale: Int = 12) throws -> [Decimal] {
        guard let lower = values.min(), let upper = values.max() else { throw Failure.emptyValues }
        guard upper != lower else { throw Failure.zeroRange }
        return try values.map { value in
            let offset = try DecimalArithmetic.unquantized(.subtract, lhs: value, rhs: lower)
            let range = try DecimalArithmetic.unquantized(.subtract, lhs: upper, rhs: lower)
            return try DecimalRatio.divide(offset, by: range, scale: scale)
        }
    }
}
