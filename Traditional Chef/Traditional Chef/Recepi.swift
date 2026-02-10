//
//  Recipe.swift
//  FamousChef
//

import Foundation

enum RecipeCategory: String, CaseIterable, Identifiable, Codable {
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

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawValue = (try? container.decode(String.self)) ?? ""
        self = RecipeCategory(rawValue: rawValue) ?? .main
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

struct Recipe: Identifiable, Hashable, Codable {
    let id: String

    /// ISO 3166-1 alpha-2 (e.g. "IT")
    let countryCode: String

    /// Localized name keys (so you can add more languages easily)
    let nameKey: String

    /// Category used in filters
    let category: RecipeCategory

    /// Localized recipe information key.
    let infoKey: String
    let infoSummaryKey: String
    /// Optional hero image URL.
    let imageURL: String?

    /// List view metadata
    let approximateMinutes: Int
    let totalMinutes: Int
    let totalActiveMinutes: Int
    let calories: Int
    let ingredientsCountForList: Int

    /// Ingredients (localized per ingredient)
    let ingredients: [Ingredient]

    /// Required and optional kitchen tools.
    let tools: [RecipeTool]

    /// Steps (localized per step)
    let steps: [RecipeStep]

    /// Optional drink pairing description key.
    let drinkPairingKey: String?
    let drinkPairingSummaryKey: String?

    /// Optional localized phrase keys to render in bold within the drink pairing text.
    let drinkPairingBoldPhraseKeys: [String]

    /// Optional nutrition facts (per serving).
    let nutrition: RecipeNutrition?
}

struct RecipeTool: Identifiable, Hashable, Codable {
    let id: String
    let nameKey: String
    let isOptional: Bool
    let optionalLabelKey: String?
}

struct Ingredient: Identifiable, Hashable, Codable {
    let id: String
    let nameKey: String
    let grams: Double
    let ounces: Double
    let isOptional: Bool
    let group: IngredientGroup
    let groupId: Int?

    /// Used for “supermarket logic”
    let aisle: GroceryAisle

    /// Used for “use order” sorting
    let useOrder: Int

    /// Optional custom amount display
    let customAmountValue: String?
    let customAmountLabelKey: String?

    /// Conversion metadata loaded from groceries.csv (per one base serving)
    let displayMode: IngredientDisplayMode?
    let gramsPerMl: Double?
    let gramsPerTsp: Double?
    let gramsPerCount: Double?
    let allowCup: Bool?
}

enum IngredientDisplayMode: String, Codable {
    case weight
    case liquid
    case spoon
    case pcs
}

struct IngredientGroup: Hashable, Identifiable, Codable {
    let id: String

    func localizedName(in locale: Locale) -> String {
        let key = "grocery.group.\(id)"
        let localized = AppLanguage.string(key, locale: locale)
        return localized == key ? id.capitalized : localized
    }

    init(id: String) {
        self.id = id
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            id = value
            return
        }
        let decoded = try container.decode([String: String].self)
        id = decoded["id"] ?? "other"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(id)
    }
}

enum GroceryAisle: Int, CaseIterable, Codable {
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

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            self = GroceryAisle.from(stringValue)
            return
        }
        let rawValue = try container.decode(Int.self)
        self = GroceryAisle(rawValue: rawValue) ?? .other
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    private static func from(_ value: String) -> GroceryAisle {
        switch value {
        case "vegetables": return .vegetables
        case "aromatics": return .aromatics
        case "meat": return .meat
        case "canned": return .canned
        case "dairy": return .dairy
        case "pantry": return .pantry
        case "spices": return .spices
        default: return .other
        }
    }
}

struct RecipeStep: Identifiable, Hashable, Codable {
    let id: String
    let stepNumber: Int
    let titleKey: String
    let bodyKey: String
    let isPassive: Bool

    /// Optional single timer per step (seconds)
    let timerSeconds: Int?
}

struct RecipeNutrition: Hashable, Codable {
    let energyKcal: Int?
    let proteinGrams: Double?
    let carbohydratesGrams: Double?
    let sugarsGrams: Double?
    let fatGrams: Double?
    let saturatedFatGrams: Double?
    let sodiumMilligrams: Double?
    let fiberGrams: Double?
}
