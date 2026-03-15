import XCTest
@testable import Traditional_Chef

@MainActor
final class RecipeListViewModelTests: XCTestCase {
    private func recipe(id: String, category: RecipeCategory) -> Recipe {
        Recipe(
            id: id,
            countryCode: "IT",
            nameKey: "name.\(id)",
            category: category,
            infoKey: "info.\(id)",
            infoSummaryKey: "info.summary.\(id)",
            imageURL: nil,
            approximateMinutes: 20,
            totalMinutes: 20,
            totalActiveMinutes: 15,
            calories: 200,
            ingredientsCountForList: 4,
            ingredients: [],
            tools: [],
            steps: [],
            drinkPairingKey: nil,
            drinkPairingSummaryKey: nil,
            drinkPairingBoldPhraseKeys: [],
            nutrition: nil
        )
    }

    func testRandomSelectionWithoutCategoryReturnsSingleDish() {
        let vm = RecipeListViewModel()
        let recipes = [
            recipe(id: "s1", category: .starter),
            recipe(id: "m1", category: .main),
            recipe(id: "d1", category: .dessert)
        ]

        vm.applyRandomSelection(from: recipes, selectedCategory: nil)

        XCTAssertTrue(vm.isRandomModeActive)
        XCTAssertEqual(vm.randomSelectionIDs.count, 1)
        XCTAssertTrue(["s1", "m1", "d1"].contains(vm.randomSelectionIDs[0]))
    }

    func testRandomSelectionWithCategoryOnlyReturnsOneDish() {
        let vm = RecipeListViewModel()
        let recipes = [
            recipe(id: "m1", category: .main),
            recipe(id: "m2", category: .main),
            recipe(id: "d1", category: .dessert)
        ]

        vm.applyRandomSelection(from: recipes, selectedCategory: .main)

        XCTAssertEqual(vm.randomSelectionIDs.count, 1)
        XCTAssertTrue(["m1", "m2"].contains(vm.randomSelectionIDs[0]))
    }


    func testSetCountrySelectionClearsCategoryFilters() {
        let vm = RecipeListViewModel()
        vm.selectedCategories = [.starter]

        vm.setCountrySelection(countryCode: "JP", continent: .asia)

        XCTAssertEqual(vm.selectedCountryCode, "JP")
        XCTAssertEqual(vm.selectedContinent, .asia)
        XCTAssertTrue(vm.selectedCategories.isEmpty)
    }
    func testPseudoRandomBouncesThroughSequence() {
        let vm = RecipeListViewModel()
        let recipes = [
            recipe(id: "m1", category: .main),
            recipe(id: "m2", category: .main),
            recipe(id: "m3", category: .main)
        ]

        vm.applyRandomSelection(from: recipes, selectedCategory: .main)
        let first = vm.randomSelectionIDs.first
        vm.applyRandomSelection(from: recipes, selectedCategory: .main)
        let second = vm.randomSelectionIDs.first
        vm.applyRandomSelection(from: recipes, selectedCategory: .main)
        let third = vm.randomSelectionIDs.first
        vm.applyRandomSelection(from: recipes, selectedCategory: .main)
        let fourth = vm.randomSelectionIDs.first

        XCTAssertEqual([first, second, third, fourth], ["m1", "m2", "m3", "m2"])
    }
}
