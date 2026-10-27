import Foundation

public enum DecimalAggregation {
    public enum Failure: Error, Sendable {
        case emptyValues
        case mismatchedWeights
        case negativeWeight
        case zeroWeightSum
    }

    public static func sum(_ values: [Decimal]) throws -> Decimal {
        var result = Decimal.zero
        for value in values {
            result = try DecimalArithmetic.unquantized(.add, lhs: result, rhs: value)
        }
        return result
    }

    public static func mean(_ values: [Decimal], scale: Int = 12) throws -> Decimal {
        guard !values.isEmpty else { throw Failure.emptyValues }
        return try DecimalRatio.divide(sum(values), by: Decimal(values.count), scale: scale)
    }

    public static func weighted_mean(
        _ values: [Decimal], weights: [Decimal], scale: Int = 12
    ) throws -> Decimal {
        guard !values.isEmpty else { throw Failure.emptyValues }
        guard values.count == weights.count else { throw Failure.mismatchedWeights }
        guard weights.allSatisfy({ $0 >= .zero }) else { throw Failure.negativeWeight }
        let total_weight = try sum(weights)
        guard total_weight != .zero else { throw Failure.zeroWeightSum }
        var weighted_total = Decimal.zero
        for (value, weight) in zip(values, weights) {
            let product = try DecimalArithmetic.unquantized(.multiply, lhs: value, rhs: weight)
            weighted_total = try DecimalArithmetic.unquantized(.add, lhs: weighted_total, rhs: product)
        }
        return try DecimalRatio.divide(weighted_total, by: total_weight, scale: scale)
    }

    public static func minimum(_ values: [Decimal]) throws -> Decimal {
        guard let value = values.min() else { throw Failure.emptyValues }
        return value
    }

    public static func maximum(_ values: [Decimal]) throws -> Decimal {
        guard let value = values.max() else { throw Failure.emptyValues }
        return value
    }

    public static func median(_ values: [Decimal], scale: Int = 12) throws -> Decimal {
        guard !values.isEmpty else { throw Failure.emptyValues }
        let sorted = values.sorted()
        let middle = sorted.count / 2
        if sorted.count % 2 != 0 { return sorted[middle] }
        return try mean([sorted[middle - 1], sorted[middle]], scale: scale)
    }
}
