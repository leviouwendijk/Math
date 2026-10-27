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
