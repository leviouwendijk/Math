import Foundation

/// Finite base-10 arithmetic with an explicit fractional scale.
/// This library is independent of Agentic and any model schema.
public enum DecimalArithmetic {
    public enum Operation: String, Sendable, Codable, Hashable, CaseIterable {
        case add
        case subtract
        case multiply
        case divide
    }

    /// Direction and tie-breaking semantics of Foundation decimal rounding.
    /// `down` rounds toward negative infinity; `up` toward positive infinity.
    public enum RoundingMode: String, Sendable, Codable, Hashable, CaseIterable {
        case plain
        case bankers
        case down
        case up

        var foundation: NSDecimalNumber.RoundingMode {
            switch self {
            case .plain: .plain
            case .bankers: .bankers
            case .down: .down
            case .up: .up
            }
        }
    }

    public enum Failure: Error, Sendable {
        case invalidLiteral(String)
        case invalidScale(Int)
        case divisionByZero
        case invalidResult
    }

    public static func parse(_ literal: String) throws -> Decimal {
        let pattern = #"^[+-]?(?:[0-9]+(?:\.[0-9]+)?|\.[0-9]+)$"#
        let digitCount = literal.utf8.filter { (48...57).contains($0) }.count

        guard literal.count <= 128,
            digitCount <= 38,
            literal.range(of: pattern, options: .regularExpression) != nil,
            let value = Decimal(
                string: literal,
                locale: Locale(identifier: "en_US_POSIX")
            )
        else {
            throw Failure.invalidLiteral(literal)
        }

        return value
    }

    public static func calculate(
        _ operation: Operation,
        lhs: Decimal,
        rhs: Decimal,
        scale: Int = 12,
        mode: RoundingMode = .plain
    ) throws -> Decimal {
        guard (0...16).contains(scale) else {
            throw Failure.invalidScale(scale)
        }

        let left = NSDecimalNumber(decimal: lhs)
        let right = NSDecimalNumber(decimal: rhs)

        if operation == .divide, right == .zero {
            throw Failure.divisionByZero
        }

        let behavior = NSDecimalNumberHandler(
            roundingMode: mode.foundation,
            scale: Int16(scale),
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        )

        let value: NSDecimalNumber
        switch operation {
        case .add:
            value = left.adding(right, withBehavior: behavior)
        case .subtract:
            value = left.subtracting(right, withBehavior: behavior)
        case .multiply:
            value = left.multiplying(by: right, withBehavior: behavior)
        case .divide:
            value = left.dividing(by: right, withBehavior: behavior)
        }

        // Enforce the fractional scale explicitly across Foundation implementations.
        let rounded = value.rounding(accordingToBehavior: behavior)
        guard rounded != .notANumber else {
            throw Failure.invalidResult
        }

        return rounded.decimalValue
    }

    /// Explicitly round an existing Decimal without changing its predecessors.
    /// Do not use binary Double conversion for accounting-sensitive values.
    public static func round(
        _ value: Decimal,
        scale: Int,
        mode: RoundingMode = .plain
    ) throws -> Decimal {
        guard (0...16).contains(scale) else {
            throw Failure.invalidScale(scale)
        }
        let behavior = NSDecimalNumberHandler(
            roundingMode: mode.foundation,
            scale: Int16(scale),
            raiseOnExactness: false,
            raiseOnOverflow: false,
            raiseOnUnderflow: false,
            raiseOnDivideByZero: false
        )
        let result = NSDecimalNumber(decimal: value)
            .rounding(accordingToBehavior: behavior)
        guard result != .notANumber else {
            throw Failure.invalidResult
        }
        return result.decimalValue
    }

    public static func string(_ value: Decimal) -> String {
        NSDecimalNumber(decimal: value).stringValue
    }
}
