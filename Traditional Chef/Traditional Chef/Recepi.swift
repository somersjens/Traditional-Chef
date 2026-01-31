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

    func localizedName(in locale: Locale) -> String {
        switch self {
        case .breakfast: return AppLanguage.string("category.breakfast", locale: locale)
        case .snack:     return AppLanguage.string("category.snack", locale: locale)
        case .starter:   return AppLanguage.string("category.starter", locale: locale)
        case .main:      return AppLanguage.string("category.main", locale: locale)
        case .dessert:   return AppLanguage.string("category.dessert", locale: locale)
        }
    }

    var localizedName: String {
        localizedName(in: AppLanguage.currentLocale)
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

    /// Localized recipe information key.
    let infoKey: String

    /// List view metadata
    let approximateMinutes: Int
    let calories: Int
    let ingredientsCountForList: Int

    /// Ingredients (localized per ingredient)
    let ingredients: [Ingredient]

    /// Steps (localized per step)
    let steps: [RecipeStep]

    /// Optional drink pairing description key.
    let drinkPairingKey: String?

    /// Optional localized phrase keys to render in bold within the drink pairing text.
    let drinkPairingBoldPhraseKeys: [String]
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

    func localizedName(in locale: Locale) -> String {
        switch self {
        case .vegetables: return AppLanguage.string("aisle.vegetables", locale: locale)
        case .aromatics:  return AppLanguage.string("aisle.aromatics", locale: locale)
        case .meat:       return AppLanguage.string("aisle.meat", locale: locale)
        case .canned:     return AppLanguage.string("aisle.canned", locale: locale)
        case .dairy:      return AppLanguage.string("aisle.dairy", locale: locale)
        case .pantry:     return AppLanguage.string("aisle.pantry", locale: locale)
        case .spices:     return AppLanguage.string("aisle.spices", locale: locale)
        case .other:      return AppLanguage.string("aisle.other", locale: locale)
        }
    }

    var localizedName: String {
        localizedName(in: AppLanguage.currentLocale)
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
