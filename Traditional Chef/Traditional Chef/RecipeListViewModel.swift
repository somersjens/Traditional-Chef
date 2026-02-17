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
        case country, name, totalTime, prepTime, calories, ingredients
    }

    @Published var sortKey: SortKey = .country
    @Published var ascending: Bool = true

    private var cancellables: Set<AnyCancellable> = []

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
}

enum RecipeListValue: String, CaseIterable, Identifiable {
    case totalTime
    case prepTime
    case prepAndWaitingTime
    case ingredients
    case calories

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
