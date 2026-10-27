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


        Test("ratios-aggregations-and-precision") {
            let one = try DecimalArithmetic.parse("1")
            let three = try DecimalArithmetic.parse("3")
            try Expect.equal(
                DecimalArithmetic.string(try DecimalRatio.divide(one, by: three, scale: 4)),
                "0.3333", "Explicit division precision"
            )
            try Expect.equal(
                DecimalArithmetic.string(try DecimalRatio.percentage_change(from: 100, to: 115)),
                "15", "Percent expressed as points"
            )
            try Expect.equal(
                DecimalArithmetic.string(try DecimalAggregation.sum([0.1, 0.2, 0.3])),
                "0.6", "Decimal accumulation"
            )
            try Expect.equal(
                DecimalArithmetic.string(try DecimalAggregation.weighted_mean([10, 20], weights: [1, 3])),
                "17.5", "Weighted mean"
            )
            try Expect.equal(
                DecimalArithmetic.string(try DecimalAggregation.median([3, 1, 2, 4])),
                "2.5", "Median"
            )
            try Expect.throwsError("Zero baseline is not a zero result") {
                _ = try DecimalRatio.relative_change(from: 0, to: 10)
            }
            try Expect.throwsError("Zero weight mass is invalid") {
                _ = try DecimalAggregation.weighted_mean([1], weights: [0])
            }
        }


        Test("allocation-largest-remainder-reconciliation") {
            let shares = try DecimalAllocation.proportional(total: 100, weights: [1, 1, 1])
            try Expect.equal(
                shares.map(DecimalArithmetic.string),
                ["33.34", "33.33", "33.33"], "Stable tie-breaking"
            )
            try Expect.equal(
                DecimalArithmetic.string(try DecimalAggregation.sum(shares)),
                "100", "Parts reconcile with total"
            )
            let negative = try DecimalAllocation.proportional(total: -0.01, weights: [1, 1])
            try Expect.equal(negative.map(DecimalArithmetic.string), ["-0.01", "0"], "Signed allocation")
            try Expect.throwsError("Negative weight rejected") {
                _ = try DecimalAllocation.proportional(total: 10, weights: [-1, 2])
            }
        }


        Test("series-statistics-interpolation") {
            try Expect.equal(
                try DecimalSeries.difference([10, 15, 12]).map(DecimalArithmetic.string),
                ["5", "-3"], "Differences retain sign"
            )
            try Expect.equal(
                try DecimalSeries.cumulative([1, 2, 3]).map(DecimalArithmetic.string),
                ["1", "3", "6"], "Cumulative sequence"
            )
            try Expect.equal(
                try DecimalSeries.moving_mean([10, 20, 30], window: 2).map(DecimalArithmetic.string),
                ["15", "25"], "Window-aligned means"
            )
            try Expect.equal(
                try DecimalSeries.normalize([2, 4, 6]).map(DecimalArithmetic.string),
                ["0", "0.5", "1"], "Min-max normalization"
            )
            try Expect.equal(
                DecimalArithmetic.string(try DecimalStatistics.population_variance([1, 2, 3])),
                "0.666666666667", "Population variance"
            )
            try Expect.equal(
                DecimalArithmetic.string(try DecimalStatistics.percentile([1, 2, 3, 4], at: 50)),
                "2.5", "Linear percentile"
            )
            try Expect.throwsError("Constant min-max series has no defined scale") {
                _ = try DecimalSeries.normalize([1, 1])
            }
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
