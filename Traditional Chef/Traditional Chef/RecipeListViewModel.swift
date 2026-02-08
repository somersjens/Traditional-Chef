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

    @Published var selectedCategories: Set<RecipeCategory> = []
    @Published var selectedCountryCode: String? = nil // nil = all countries
    @Published var selectedContinent: Continent? = nil
    @Published var favoritesOnly: Bool = false

    enum SortKey: String {
        case country, name, totalTime, prepTime, calories, ingredients
    }

    @Published var sortKey: SortKey = .country
    @Published var ascending: Bool = true

    func toggleCategory(_ cat: RecipeCategory) {
        if selectedCategories.contains(cat) {
            selectedCategories.remove(cat)
        } else {
            selectedCategories.insert(cat)
        }

        let filterSet = Set(RecipeCategory.filterCategories)
        if selectedCategories == filterSet {
            selectedCategories.removeAll()
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
}

enum RecipeListValue: String, CaseIterable, Identifiable {
    case totalTime
    case prepTime
    case ingredients
    case calories

    var id: String { rawValue }

    var settingsLabelKey: String {
        switch self {
        case .totalTime:
            return "recipes.column.time"
        case .prepTime:
            return "recipes.column.prepTime"
        case .ingredients:
            return "recipes.column.ingredients"
        case .calories:
            return "recipes.column.calories"
        }
    }

    var columnLabelKey: String {
        switch self {
        case .totalTime:
            return "recipes.column.time"
        case .prepTime:
            return "recipes.column.prepTime"
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
        case .ingredients:
            return .ingredients
        case .calories:
            return .calories
        }
    }
}
