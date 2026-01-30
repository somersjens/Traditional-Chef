//
//  Recipe.swift
//  FamousChef
//

import Foundation

enum RecipeCategory: String, CaseIterable, Identifiable {
    case breakfast, snack, starter, main, dessert

    var id: String { rawValue }

    static var filterCategories: [RecipeCategory] {
        [.starter, .main, .dessert]
    }

    var localizedName: String {
        switch self {
        case .breakfast: return AppLanguage.string("category.breakfast")
        case .snack:     return AppLanguage.string("category.snack")
        case .starter:   return AppLanguage.string("category.starter")
        case .main:      return AppLanguage.string("category.main")
        case .dessert:   return AppLanguage.string("category.dessert")
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
        case .vegetables: return AppLanguage.string("aisle.vegetables")
        case .aromatics:  return AppLanguage.string("aisle.aromatics")
        case .meat:       return AppLanguage.string("aisle.meat")
        case .canned:     return AppLanguage.string("aisle.canned")
        case .dairy:      return AppLanguage.string("aisle.dairy")
        case .pantry:     return AppLanguage.string("aisle.pantry")
        case .spices:     return AppLanguage.string("aisle.spices")
        case .other:      return AppLanguage.string("aisle.other")
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
