//
//  RecipeStore.swift
//  FamousChef
//

import Combine
import Foundation
import SwiftUI

@MainActor
final class RecipeStore: ObservableObject {
    @Published private(set) var recipes: [Recipe] = SampleRecipes.all {
        didSet {
            rebuildCaches()
        }
    }

    @AppStorage("favoriteRecipeIDs") private var favoriteRecipeIDsData: String = "[]"
    @Published private(set) var favorites: Set<String> = []

    private(set) var countryCodes: [String] = []
    private var localizedNameCache: [String: [String: String]] = [:]
    private var normalizedNameCache: [String: [String: String]] = [:]

    init() {
        loadRecipes()
        rebuildCaches()
        loadFavorites()
    }

    private func loadRecipes() {
        guard let url = Bundle.main.url(forResource: "recipes", withExtension: "json") else {
            return
        }
        do {
            let data = try Data(contentsOf: url)
            recipes = try JSONDecoder().decode([Recipe].self, from: data)
        } catch {
            print("Failed to load recipes.json: \(error)")
        }
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

    func localizedNames(for locale: Locale) -> [String: String] {
        let key = locale.identifier
        if let cached = localizedNameCache[key] {
            return cached
        }
        let names = Dictionary(
            uniqueKeysWithValues: recipes.map {
                ($0.id, AppLanguage.string(String.LocalizationValue($0.nameKey), locale: locale))
            }
        )
        localizedNameCache[key] = names
        return names
    }

    func normalizedNames(for locale: Locale) -> [String: String] {
        let key = locale.identifier
        if let cached = normalizedNameCache[key] {
            return cached
        }
        let normalized = localizedNames(for: locale)
            .mapValues { $0.normalizedSearchKey(locale: locale) }
        normalizedNameCache[key] = normalized
        return normalized
    }

    private func rebuildCaches() {
        countryCodes = Array(Set(recipes.map { $0.countryCode })).sorted()
        localizedNameCache.removeAll()
        normalizedNameCache.removeAll()
    }
}
