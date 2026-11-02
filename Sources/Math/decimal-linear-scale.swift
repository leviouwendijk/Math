import Foundation

/// A dimensionless affine mapping over an explicit, nondegenerate decimal domain.
/// A position can be outside 0...1; clipping is a responsibility of its consumer.
public struct DecimalLinearScale: Sendable, Hashable {
    public enum Failure: Error, Sendable, Equatable {
        case invalidDomain
    }

    public let lower: Decimal
    public let upper: Decimal

    public init(lower: Decimal, upper: Decimal) throws {
        guard lower < upper else { throw Failure.invalidDomain }
        self.lower = lower
        self.upper = upper
    }

    public func position(of value: Decimal, scale: Int = 12) throws -> Decimal {
        let offset = try DecimalArithmetic.unquantized(.subtract, lhs: value, rhs: lower)
        let span = try DecimalArithmetic.unquantized(.subtract, lhs: upper, rhs: lower)
        return try DecimalRatio.divide(offset, by: span, scale: scale)
    }
}