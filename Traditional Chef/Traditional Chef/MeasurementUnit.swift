//
//  MeasurementUnit.swift
//  Traditional Chef
//

import Foundation

enum MeasurementUnit: String, CaseIterable, Identifiable {
    case grams
    case ounces

    var id: String { rawValue }

    static func `default`(for languageCode: String) -> MeasurementUnit {
        languageCode == "nl" ? .grams : .ounces
    }

    static func resolved(from storedValue: String, languageCode: String) -> MeasurementUnit {
        MeasurementUnit(rawValue: storedValue) ?? `default`(for: languageCode)
    }

    var settingsLabelKey: String {
        switch self {
        case .grams:
            return "settings.measurement.grams"
        case .ounces:
            return "settings.measurement.ounces"
        }
    }

    var groceryOptionKey: String {
        switch self {
        case .grams:
            return "grocery.option.allGrams"
        case .ounces:
            return "grocery.option.allOunces"
        }
    }

    var unitSymbol: String {
        switch self {
        case .grams:
            return "g"
        case .ounces:
            return "oz"
        }
    }
}
