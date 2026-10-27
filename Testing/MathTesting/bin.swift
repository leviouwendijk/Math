import Math
import Testing

private enum MathTestingFailure: Error {
    case failed
}

@main
struct MathTestingMain {
    static func main() async throws {
        let reporter = PlainTextTestReporter()
        let result = await TestRunner.run(
            MathTestSuite.testSuite,
            sink: reporter
        )
        let rendered = await reporter.rendered()
        if !rendered.isEmpty {
            print(rendered)
        }
        if result.isFailure {
            throw MathTestingFailure.failed
        }
    }
}

enum MathTestSuite {
    static let testSuite = TestSuite(
        "math",
        title: "Math deterministic decimal arithmetic"
    ) {
        Test("chained-decimal-arithmetic") {
            let discounted = try DecimalArithmetic.calculate(
                .multiply,
                lhs: DecimalArithmetic.parse("1270"),
                rhs: DecimalArithmetic.parse("0.85")
            )
            let taxed = try DecimalArithmetic.calculate(
                .multiply,
                lhs: discounted,
                rhs: DecimalArithmetic.parse("1.21")
            )
            let installment = try DecimalArithmetic.calculate(
                .divide,
                lhs: taxed,
                rhs: DecimalArithmetic.parse("3")
            )

            try Expect.equal(
                DecimalArithmetic.string(discounted),
                "1079.5",
                "Discounted value"
            )
            try Expect.equal(
                DecimalArithmetic.string(taxed),
                "1306.195",
                "Taxed value"
            )
            try Expect.equal(
                DecimalArithmetic.string(installment),
                "435.398333333333",
                "Rounded installment"
            )
        }

        Test("explicit-decimal-rounding-modes") {
            let positive = try DecimalArithmetic.parse("1.005")
            let negative = try DecimalArithmetic.parse("-1.005")
            try Expect.equal(
                DecimalArithmetic.string(try DecimalArithmetic.round(positive, scale: 2)),
                "1.01", "Plain positive tie"
            )
            try Expect.equal(
                DecimalArithmetic.string(try DecimalArithmetic.round(negative, scale: 2)),
                "-1.01", "Plain negative tie"
            )
            try Expect.equal(
                DecimalArithmetic.string(try DecimalArithmetic.round(positive, scale: 2, mode: .bankers)),
                "1", "Bankers positive tie"
            )
            try Expect.equal(
                DecimalArithmetic.string(try DecimalArithmetic.round(negative, scale: 2, mode: .bankers)),
                "-1", "Bankers negative tie"
            )
        }

        Test("decimal-comparison-tolerance") {
            let a = try DecimalArithmetic.parse("0.300")
            let b = try DecimalArithmetic.parse("0.3")
            let tolerance = try DecimalArithmetic.parse("0.01")
            let difference = try DecimalArithmetic.parse("-0.02")
            try Expect.equal(DecimalComparison.compare(a, b), .equal, "Decimal equality")
            try Expect.equal(
                DecimalComparison.withinTolerance(a, b, tolerance: tolerance),
                true, "Within tolerance"
            )
            try Expect.equal(
                DecimalComparison.exceeds(difference, tolerance: tolerance),
                true, "Symmetric tolerance"
            )
            try Expect.equal(
                DecimalComparison.exceeds(tolerance, tolerance: tolerance),
                false, "Inclusive boundary"
            )
        }

        Test("reject-invalid-decimal-inputs") {
            try Expect.throwsError("Reject malformed decimal literal") {
                _ = try DecimalArithmetic.parse("42garbage")
            }
            try Expect.throwsError("Reject division by zero") {
                _ = try DecimalArithmetic.calculate(
                    .divide,
                    lhs: DecimalArithmetic.parse("1"),
                    rhs: DecimalArithmetic.parse("0")
                )
            }
            try Expect.throwsError("Reject unsupported scale") {
                _ = try DecimalArithmetic.calculate(
                    .add,
                    lhs: DecimalArithmetic.parse("1"),
                    rhs: DecimalArithmetic.parse("2"),
                    scale: 100
                )
            }
        }
    }
}
