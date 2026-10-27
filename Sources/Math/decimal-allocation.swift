import Foundation

/// Deterministic largest-remainder distribution of quantized decimal units.
public enum DecimalAllocation {
    public enum Failure: Error, Sendable {
        case emptyWeights
        case tooManyWeights
        case negativeWeight
        case zeroWeightSum
        case invalidRemainder
    }

    /// Quantize total at requested scale; nonnegative weights, signed total supported.
    /// Equal fractional remainders use original index order, making results reproducible.
    public static func proportional(
        total: Decimal, weights: [Decimal], scale: Int = 2
    ) throws -> [Decimal] {
        guard !weights.isEmpty else { throw Failure.emptyWeights }
        guard weights.count <= 256 else { throw Failure.tooManyWeights }
        guard weights.allSatisfy({ $0 >= .zero }) else { throw Failure.negativeWeight }
        let weight_sum = try DecimalAggregation.sum(weights)
        guard weight_sum > .zero else { throw Failure.zeroWeightSum }

        let rounded_total = try DecimalArithmetic.round(total, scale: scale)
        let negative = rounded_total < .zero
        let magnitude = negative ? -rounded_total : rounded_total
        let unit = try DecimalArithmetic.parse(
            scale == 0 ? "1" : "0." + String(repeating: "0", count: scale - 1) + "1"
        )
        var shares: [Decimal] = []
        var fractions: [(index: Int, remainder: Decimal)] = []
        for (index, weight) in weights.enumerated() {
            let weighted = try DecimalArithmetic.unquantized(.multiply, lhs: magnitude, rhs: weight)
            let ideal = try DecimalArithmetic.unquantized(.divide, lhs: weighted, rhs: weight_sum)
            let floor = try DecimalArithmetic.round(ideal, scale: scale, mode: .down)
            shares.append(floor)
            let fractional = try DecimalArithmetic.unquantized(.subtract, lhs: ideal, rhs: floor)
            fractions.append((index, fractional))
        }
        let assigned = try DecimalAggregation.sum(shares)
        var remainder = try DecimalArithmetic.unquantized(.subtract, lhs: magnitude, rhs: assigned)
        fractions.sort {
            if $0.remainder == $1.remainder { return $0.index < $1.index }
            return $0.remainder > $1.remainder
        }
        // Largest-remainder allocation requires at most one additional unit per share.
        for candidate in fractions where remainder >= unit {
            shares[candidate.index] = try DecimalArithmetic.unquantized(
                .add, lhs: shares[candidate.index], rhs: unit
            )
            remainder = try DecimalArithmetic.unquantized(.subtract, lhs: remainder, rhs: unit)
        }
        guard remainder == .zero else { throw Failure.invalidRemainder }
        if negative { shares = shares.map { -$0 } }
        guard try DecimalAggregation.sum(shares) == rounded_total else { throw Failure.invalidRemainder }
        return shares
    }
}
