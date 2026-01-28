//
//  Recipe.swift
//  FamousChef
//

import Foundation

enum RecipeCategory: String, CaseIterable, Identifiable {
    case breakfast, snack, starter, main, dessert

    var id: String { rawValue }

    var localizedName: String {
        switch self {
        case .breakfast: return String(localized: "category.breakfast")
        case .snack:     return String(localized: "category.snack")
        case .starter:   return String(localized: "category.starter")
        case .main:      return String(localized: "category.main")
        case .dessert:   return String(localized: "category.dessert")
        }
    }
}

struct Recipe: Identifiable, Hashable {
    let id: String

    /// ISO 3166-1 alpha-2 (e.g. "IT")
    let countryCode: String

    /// Localized name keys (so you can add more languages easily)
    let nameKey: String

    /// Category used in filters
    let category: RecipeCategory

    /// List view metadata
    let approximateMinutes: Int
    let calories: Int
    let ingredientsCountForList: Int

    /// Ingredients (localized per ingredient)
    let ingredients: [Ingredient]

    /// Steps (localized per step)
    let steps: [RecipeStep]
}

struct Ingredient: Identifiable, Hashable {
    let id: String
    let nameKey: String
    let grams: Double
    let isOptional: Bool

    /// Used for “supermarket logic”
    let aisle: GroceryAisle

    /// Used for “use order” sorting
    let useOrder: Int
}

enum GroceryAisle: Int, CaseIterable {
    case vegetables = 0
    case aromatics
    case meat
    case canned
    case dairy
    case pantry
    case spices
    case other

    var localizedName: String {
        switch self {
        case .vegetables: return String(localized: "aisle.vegetables")
        case .aromatics:  return String(localized: "aisle.aromatics")
        case .meat:       return String(localized: "aisle.meat")
        case .canned:     return String(localized: "aisle.canned")
        case .dairy:      return String(localized: "aisle.dairy")
        case .pantry:     return String(localized: "aisle.pantry")
        case .spices:     return String(localized: "aisle.spices")
        case .other:      return String(localized: "aisle.other")
        }
    }
}

struct RecipeStep: Identifiable, Hashable {
    let id: String
    let stepNumber: Int
    let titleKey: String
    let bodyKey: String

    /// Optional single timer per step (seconds)
    let timerSeconds: Int?
}
