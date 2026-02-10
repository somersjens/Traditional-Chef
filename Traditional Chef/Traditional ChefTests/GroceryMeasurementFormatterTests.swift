import XCTest
@testable import Traditional_Chef

final class GroceryMeasurementFormatterTests: XCTestCase {
    private func ingredient(
        grams: Double,
        mode: IngredientDisplayMode,
        gramsPerMl: Double? = nil,
        gramsPerTsp: Double? = nil,
        gramsPerCount: Double? = nil,
        allowCup: Bool? = nil,
        customValue: String? = nil,
        customLabel: String? = nil
    ) -> Ingredient {
        Ingredient(
            id: "i",
            nameKey: "ingredient.test",
            grams: grams,
            ounces: grams / 28.349523125,
            isOptional: false,
            group: IngredientGroup(id: "g"),
            groupId: 1,
            aisle: .pantry,
            useOrder: 1,
            customAmountValue: customValue,
            customAmountLabelKey: customLabel,
            displayMode: mode,
            gramsPerMl: gramsPerMl,
            gramsPerTsp: gramsPerTsp,
            gramsPerCount: gramsPerCount,
            allowCup: allowCup
        )
    }

    func testMetricWeightStaysInGrams() {
        let ing = ingredient(grams: 400, mode: .weight)
        let amount = GroceryMeasurementFormatter.formattedAmount(
            for: ing,
            servings: 4,
            baseServings: 4,
            measurementUnit: .metric,
            showAllMeasurements: true,
            localizedCustomLabel: { _ in "" }
        )

        XCTAssertEqual(amount.value, "400")
        XCTAssertEqual(amount.unit, "g")
    }

    func testUSWeightConvertsToOunces() {
        let ing = ingredient(grams: 56.69904625, mode: .weight)
        let amount = GroceryMeasurementFormatter.formattedAmount(
            for: ing,
            servings: 4,
            baseServings: 4,
            measurementUnit: .us,
            showAllMeasurements: true,
            localizedCustomLabel: { _ in "" }
        )

        XCTAssertEqual(amount.value, "2")
        XCTAssertEqual(amount.unit, "oz")
    }

    func testUSWeightConvertsToPoundsAtSixteenOunces() {
        let ing = ingredient(grams: 453.59237, mode: .weight)
        let amount = GroceryMeasurementFormatter.formattedAmount(
            for: ing,
            servings: 4,
            baseServings: 4,
            measurementUnit: .us,
            showAllMeasurements: true,
            localizedCustomLabel: { _ in "" }
        )

        XCTAssertEqual(amount.value, "1")
        XCTAssertEqual(amount.unit, "lb")
    }

    func testUSLiquidUsesCupWhenAllowed() {
        let ing = ingredient(grams: 240, mode: .liquid, gramsPerMl: 1, allowCup: true)
        let amount = GroceryMeasurementFormatter.formattedAmount(
            for: ing,
            servings: 4,
            baseServings: 4,
            measurementUnit: .us,
            showAllMeasurements: true,
            localizedCustomLabel: { _ in "" }
        )

        XCTAssertEqual(amount.value, "1")
        XCTAssertEqual(amount.unit, "cup")
    }

    func testAUNZLiquidUsesTwoHundredFiftyMlCup() {
        let ing = ingredient(grams: 250, mode: .liquid, gramsPerMl: 1, allowCup: true)
        let amount = GroceryMeasurementFormatter.formattedAmount(
            for: ing,
            servings: 4,
            baseServings: 4,
            measurementUnit: .auNz,
            showAllMeasurements: true,
            localizedCustomLabel: { _ in "" }
        )

        XCTAssertEqual(amount.value, "1")
        XCTAssertEqual(amount.unit, "cup")
    }

    func testJapanLiquidUsesTwoHundredMlCup() {
        let ing = ingredient(grams: 200, mode: .liquid, gramsPerMl: 1, allowCup: true)
        let amount = GroceryMeasurementFormatter.formattedAmount(
            for: ing,
            servings: 4,
            baseServings: 4,
            measurementUnit: .jp,
            showAllMeasurements: true,
            localizedCustomLabel: { _ in "" }
        )

        XCTAssertEqual(amount.value, "1")
        XCTAssertEqual(amount.unit, "cup")
    }

    func testUKLiquidFallsBackToSpoonsWhenCupNotAvailable() {
        let ing = ingredient(grams: 120, mode: .liquid, gramsPerMl: 1, allowCup: true)
        let amount = GroceryMeasurementFormatter.formattedAmount(
            for: ing,
            servings: 4,
            baseServings: 4,
            measurementUnit: .ukImp,
            showAllMeasurements: true,
            localizedCustomLabel: { _ in "" }
        )

        XCTAssertEqual(amount.value, "8")
        XCTAssertEqual(amount.unit, "tbsp")
    }

    func testSpoonModeUsesConfiguredTeaspoonDensity() {
        let ing = ingredient(grams: 9, mode: .spoon, gramsPerTsp: 3, allowCup: false)
        let amount = GroceryMeasurementFormatter.formattedAmount(
            for: ing,
            servings: 4,
            baseServings: 4,
            measurementUnit: .us,
            showAllMeasurements: true,
            localizedCustomLabel: { _ in "" }
        )

        XCTAssertEqual(amount.value, "3")
        XCTAssertEqual(amount.unit, "tsp")
    }

    func testPcsModeUsesQuarterRounding() {
        let ing = ingredient(grams: 100, mode: .pcs, gramsPerCount: 40)
        let amount = GroceryMeasurementFormatter.formattedAmount(
            for: ing,
            servings: 4,
            baseServings: 4,
            measurementUnit: .metric,
            showAllMeasurements: true,
            localizedCustomLabel: { _ in "" }
        )

        XCTAssertEqual(amount.value, "2.5")
        XCTAssertEqual(amount.unit, "pcs")
    }

    func testCustomAmountOverridesWhenAllMeasurementsDisabled() {
        let ing = ingredient(
            grams: 100,
            mode: .weight,
            customValue: "2",
            customLabel: "ingredient.unit.pinches"
        )
        let amount = GroceryMeasurementFormatter.formattedAmount(
            for: ing,
            servings: 4,
            baseServings: 4,
            measurementUnit: .metric,
            showAllMeasurements: false,
            localizedCustomLabel: { key in key == "ingredient.unit.pinches" ? "pinches" : key }
        )

        XCTAssertEqual(amount.value, "2")
        XCTAssertEqual(amount.unit, "pinches")
    }

    func testServingScalingAffectsOutput() {
        let ing = ingredient(grams: 200, mode: .weight)
        let amount = GroceryMeasurementFormatter.formattedAmount(
            for: ing,
            servings: 2,
            baseServings: 4,
            measurementUnit: .metric,
            showAllMeasurements: true,
            localizedCustomLabel: { _ in "" }
        )

        XCTAssertEqual(amount.value, "100")
        XCTAssertEqual(amount.unit, "g")
    }
}
