import XCTest
@testable import Traditional_Chef

final class TimeDisplayFormatterTests: XCTestCase {
    func testSummaryEquationUsesApproximateNotationForLargeComponents() {
        let text = TimeDisplayFormatter.summaryEquation(
            activeMinutes: 37,
            passiveMinutes: 120,
            totalMinutes: 180,
            locale: Locale(identifier: "en_US")
        )

        XCTAssertEqual(text, "37 min + ~2 hrs ≈ 3 hrs")
    }

    func testSummaryEquationShowsApproximateRelationForNonExactDayTotals() {
        let text = TimeDisplayFormatter.summaryEquation(
            activeMinutes: 20,
            passiveMinutes: 2880,
            totalMinutes: 2900,
            locale: Locale(identifier: "en_US")
        )

        XCTAssertEqual(text, "20 min + ~2 days ≈ 2 days")
    }

    func testSummaryEquationKeepsExactRelationForMinuteOnlyValues() {
        let text = TimeDisplayFormatter.summaryEquation(
            activeMinutes: 30,
            passiveMinutes: 20,
            totalMinutes: 50,
            locale: Locale(identifier: "en_US")
        )

        XCTAssertEqual(text, "30 min + 20 min = 50 min")
    }
}
