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
            groupId: "g",
            groupSortOrder: 1,
            aisle: .pantry,
            useOrder: 1,
            customAmountValue: customValue,
            customAmountLabelKey: customLabel,
            displayMode: mode,
            gramsPerMl: gramsPerMl,
            gramsPerTsp: gramsPerTsp,
            gramsPerCount: gramsPerCount,
            allowCup: allowCup,
            isInvisible: false
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

    func testAllWeightModeAlwaysUsesGramsEvenInUSUnits() {
        let ing = ingredient(grams: 56.69904625, mode: .weight)
        let amount = GroceryMeasurementFormatter.formattedAmount(
            for: ing,
            servings: 4,
            baseServings: 4,
            measurementUnit: .us,
            showAllMeasurements: true,
            localizedCustomLabel: { _ in "" }
        )

        XCTAssertEqual(amount.value, "57")
        XCTAssertEqual(amount.unit, "g")
    }

    func testAllWeightModeForLiquidStillUsesGrams() {
        let ing = ingredient(grams: 240, mode: .liquid, gramsPerMl: 1, allowCup: true)
        let amount = GroceryMeasurementFormatter.formattedAmount(
            for: ing,
            servings: 4,
            baseServings: 4,
            measurementUnit: .us,
            showAllMeasurements: true,
            localizedCustomLabel: { _ in "" }
        )

        XCTAssertEqual(amount.value, "240")
        XCTAssertEqual(amount.unit, "g")
    }

    func testMetricMeasurementModeForLiquidUsesMilliliters() {
        let ing = ingredient(grams: 240, mode: .liquid, gramsPerMl: 1, allowCup: true)
        let amount = GroceryMeasurementFormatter.formattedAmount(
            for: ing,
            servings: 4,
            baseServings: 4,
            measurementUnit: .metric,
            showAllMeasurements: false,
            localizedCustomLabel: { _ in "" }
        )

        XCTAssertEqual(amount.value, "240")
        XCTAssertEqual(amount.unit, "ml")
    }

    func testMeasurementModeConvertsUSWeightToOunces() {
        let ing = ingredient(grams: 56.69904625, mode: .weight)
        let amount = GroceryMeasurementFormatter.formattedAmount(
            for: ing,
            servings: 4,
            baseServings: 4,
            measurementUnit: .us,
            showAllMeasurements: false,
            localizedCustomLabel: { _ in "" }
        )

        XCTAssertEqual(amount.value, "2")
        XCTAssertEqual(amount.unit, "oz")
    }

    func testMeasurementModeUSLiquidUsesCupWhenAllowed() {
        let ing = ingredient(grams: 240, mode: .liquid, gramsPerMl: 1, allowCup: true)
        let amount = GroceryMeasurementFormatter.formattedAmount(
            for: ing,
            servings: 4,
            baseServings: 4,
            measurementUnit: .us,
            showAllMeasurements: false,
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
            showAllMeasurements: false,
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
            showAllMeasurements: false,
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
            showAllMeasurements: false,
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
            showAllMeasurements: false,
            localizedCustomLabel: { _ in "" }
        )

        XCTAssertEqual(amount.value, "3")
        XCTAssertEqual(amount.unit, "tsp")
    }

    func testMetricSpoonModeUsesSpoonUnits() {
        let ing = ingredient(grams: 30, mode: .spoon, gramsPerTsp: 5, allowCup: false)
        let amount = GroceryMeasurementFormatter.formattedAmount(
            for: ing,
            servings: 4,
            baseServings: 4,
            measurementUnit: .metric,
            showAllMeasurements: false,
            localizedCustomLabel: { _ in "" }
        )

        XCTAssertEqual(amount.value, "2")
        XCTAssertEqual(amount.unit, "tbsp")
    }

    func testSpoonModeIgnoresZeroGramsPerMlAndUsesTeaspoonDensity() {
        let ing = ingredient(grams: 5, mode: .spoon, gramsPerMl: 0, gramsPerTsp: 5, allowCup: false)
        let amount = GroceryMeasurementFormatter.formattedAmount(
            for: ing,
            servings: 4,
            baseServings: 4,
            measurementUnit: .metric,
            showAllMeasurements: false,
            localizedCustomLabel: { _ in "" }
        )

        XCTAssertEqual(amount.value, "1")
        XCTAssertEqual(amount.unit, "tsp")
    }

    func testLiquidModeIgnoresZeroGramsPerMlFallback() {
        let ing = ingredient(grams: 15, mode: .liquid, gramsPerMl: 0, allowCup: false)
        let amount = GroceryMeasurementFormatter.formattedAmount(
            for: ing,
            servings: 4,
            baseServings: 4,
            measurementUnit: .us,
            showAllMeasurements: false,
            localizedCustomLabel: { _ in "" }
        )

        XCTAssertEqual(amount.value, "1")
        XCTAssertEqual(amount.unit, "tbsp")
    }

    func testPcsModeUsesQuarterRounding() {
        let ing = ingredient(grams: 100, mode: .pcs, gramsPerCount: 40)
        let amount = GroceryMeasurementFormatter.formattedAmount(
            for: ing,
            servings: 4,
            baseServings: 4,
            measurementUnit: .metric,
            showAllMeasurements: false,
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

    func testSortableValueParsesUnicodeFractions() {
        let value = GroceryMeasurementFormatter.sortableValue(from: "1 ¼", locale: Locale(identifier: "en_US"))

        XCTAssertEqual(value, 1.25, accuracy: 0.0001)
    }

    func testSortableValueParsesLocalizedCommaDecimals() {
        let value = GroceryMeasurementFormatter.sortableValue(from: "2,5", locale: Locale(identifier: "nl_NL"))

        XCTAssertEqual(value, 2.5, accuracy: 0.0001)
    }

}
