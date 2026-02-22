//
//  RecipeListViewModel.swift
//  FamousChef
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class RecipeListViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published private(set) var debouncedSearchText: String = ""

    @Published var selectedCategories: Set<RecipeCategory> = []
    @Published var selectedCountryCode: String? = nil // nil = all countries
    @Published var selectedContinent: Continent? = nil
    @Published var favoritesOnly: Bool = false

    enum SortKey: String {
        case country, difficulty, name, totalTime, prepTime, waitingTime, calories, ingredients
    }

    @Published var sortKey: SortKey = .country
    @Published var ascending: Bool = true
    @Published var isRandomModeActive: Bool = false
    @Published private(set) var randomSelectionIDs: [String] = []

    private var cancellables: Set<AnyCancellable> = []
    private var randomPointers: [String: RandomPointer] = [:]

    private struct RandomPointer {
        var index: Int = 0
        var direction: Int = 1
    }

    init() {
        $searchText
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .removeDuplicates()
            .debounce(for: .milliseconds(180), scheduler: DispatchQueue.main)
            .assign(to: \.debouncedSearchText, on: self)
            .store(in: &cancellables)
    }

    func toggleCategory(_ cat: RecipeCategory) {
        if selectedCategories.contains(cat) {
            selectedCategories.removeAll()
        } else {
            selectedCategories = [cat]
        }
    }

    func setSort(_ key: SortKey) {
        if sortKey == key {
            ascending.toggle()
        } else {
            sortKey = key
            ascending = true
        }
    }

    func applyRandomSelection(from recipes: [Recipe], selectedCategory: RecipeCategory?) {
        let categories: [RecipeCategory] = {
            if let selectedCategory {
                return [selectedCategory]
            }
            return RecipeCategory.filterCategories
        }()

        var generatedIDs: [String] = []
        for category in categories {
            let pool = recipes
                .filter { $0.category == category }
                .map(\.id)
                .sorted()
            guard let id = nextID(from: pool, key: category.rawValue) else { continue }
            generatedIDs.append(id)
        }

        randomSelectionIDs = generatedIDs
        isRandomModeActive = true
    }

    func rerandomCategory(_ category: RecipeCategory, from recipes: [Recipe], selectedCategory: RecipeCategory?) {
        if selectedCategory != nil, selectedCategory != category {
            return
        }

        let pool = recipes
            .filter { $0.category == category }
            .map(\.id)
            .sorted()
        guard let newID = nextID(from: pool, key: category.rawValue) else {
            randomSelectionIDs.removeAll { recipeID in
                !recipes.contains(where: { $0.id == recipeID && $0.category == category })
            }
            return
        }

        randomSelectionIDs.removeAll { recipeID in
            recipes.first(where: { $0.id == recipeID })?.category == category
        }
        randomSelectionIDs.append(newID)
    }

    func clearRandomSelection() {
        isRandomModeActive = false
        randomSelectionIDs = []
    }

    func refreshRandomSelectionIfNeeded(from recipes: [Recipe], selectedCategory: RecipeCategory?) {
        guard isRandomModeActive else { return }
        applyRandomSelection(from: recipes, selectedCategory: selectedCategory)
    }

    private func nextID(from pool: [String], key: String) -> String? {
        guard !pool.isEmpty else { return nil }
        var pointer = randomPointers[key] ?? RandomPointer()

        if pointer.index >= pool.count {
            pointer.index = pool.count - 1
            pointer.direction = -1
        }

        let selected = pool[pointer.index]

        if pool.count > 1 {
            pointer.index += pointer.direction
            if pointer.index >= pool.count {
                pointer.index = pool.count - 2
                pointer.direction = -1
            } else if pointer.index < 0 {
                pointer.index = 1
                pointer.direction = 1
            }
        }

        randomPointers[key] = pointer
        return selected
    }
}

enum RecipeListValue: String, CaseIterable, Identifiable {
    case totalTime
    case prepTime
    case prepAndWaitingTime
    case ingredients
    case calories

    static var allCases: [RecipeListValue] {
        [.ingredients, .calories, .totalTime, .prepTime, .prepAndWaitingTime]
    }

    var id: String { rawValue }

    var settingsLabelKey: String {
        switch self {
        case .totalTime:
            return "recipes.column.time"
        case .prepTime:
            return "recipes.column.prepTime"
        case .prepAndWaitingTime:
            return "recipes.column.prepAndWaitingTime"
        case .ingredients:
            return "recipes.column.ingredients"
        case .calories:
            return "recipes.column.calories"
        }
    }

    var headerSymbolName: String {
        switch self {
        case .totalTime:
            return "clock"
        case .prepTime:
            return "flame"
        case .prepAndWaitingTime:
            return "flame"
        case .ingredients:
            return "cart"
        case .calories:
            return "chart.pie"
        }
    }

    var settingsSymbolName: String {
        switch self {
        case .prepAndWaitingTime:
            return "person.2"
        default:
            return headerSymbolName
        }
    }

    var columnLabelKey: String {
        switch self {
        case .totalTime:
            return "recipes.column.timeShort"
        case .prepTime:
            return "recipes.column.prepTimeShort"
        case .prepAndWaitingTime:
            return "recipes.column.prepAndWaitingTimeShort"
        case .ingredients:
            return "recipes.column.ingredientsShort"
        case .calories:
            return "recipes.column.caloriesShort"
        }
    }

    var sortKey: RecipeListViewModel.SortKey {
        switch self {
        case .totalTime:
            return .totalTime
        case .prepTime:
            return .prepTime
        case .prepAndWaitingTime:
            return .prepTime
        case .ingredients:
            return .ingredients
        case .calories:
            return .calories
        }
    }
}
