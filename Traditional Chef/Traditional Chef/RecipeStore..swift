//
//  RecipeStore.swift
//  FamousChef
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class RecipeStore: ObservableObject {
    @Published private(set) var recipes: [Recipe] = SampleRecipes.all

    @AppStorage("favoriteRecipeIDs") private var favoriteRecipeIDsData: String = "[]"
    @Published private(set) var favorites: Set<String> = []

    init() {
        loadFavorites()
    }

    func isFavorite(_ recipe: Recipe) -> Bool {
        favorites.contains(recipe.id)
    }

    func toggleFavorite(_ recipe: Recipe) {
        if favorites.contains(recipe.id) {
            favorites.remove(recipe.id)
        } else {
            favorites.insert(recipe.id)
        }
        saveFavorites()
    }

    private func loadFavorites() {
        guard let data = favoriteRecipeIDsData.data(using: .utf8),
              let decoded = try? JSONDecoder().decode([String].self, from: data)
        else {
            favorites = []
            return
        }
        favorites = Set(decoded)
    }

    private func saveFavorites() {
        let array = Array(favorites).sorted()
        if let data = try? JSONEncoder().encode(array),
           let string = String(data: data, encoding: .utf8) {
            favoriteRecipeIDsData = string
        }
    }
}
