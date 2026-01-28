//
//  RecipeListViewModel.swift
//  FamousChef
//

import Foundation
import SwiftUI

@MainActor
final class RecipeListViewModel: ObservableObject {
    @Published var searchText: String = ""

    @Published var selectedCategories: Set<RecipeCategory> = Set(RecipeCategory.allCases)
    @Published var selectedCountryCode: String? = nil // nil = all countries
    @Published var favoritesOnly: Bool = false

    enum SortKey: String {
        case country, name, time, calories, ingredients
    }

    @Published var sortKey: SortKey = .country
    @Published var ascending: Bool = true

    func toggleCategory(_ cat: RecipeCategory) {
        if selectedCategories.contains(cat) {
            selectedCategories.remove(cat)
        } else {
            selectedCategories.insert(cat)
        }

        // If last one is deselected -> select all automatically
        if selectedCategories.isEmpty {
            selectedCategories = Set(RecipeCategory.allCases)
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
