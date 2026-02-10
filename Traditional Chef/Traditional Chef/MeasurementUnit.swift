//
//  MeasurementUnit.swift
//  Traditional Chef
//

import Foundation

enum MeasurementUnit: String, CaseIterable, Identifiable {
    case metric
    case us
    case ukImp
    case auNz
    case jp

    var id: String { rawValue }

    static func `default`(for languageCode: String) -> MeasurementUnit {
        _ = languageCode
        return .metric
    }

    static func resolved(from storedValue: String, languageCode: String) -> MeasurementUnit {
        MeasurementUnit(rawValue: storedValue) ?? `default`(for: languageCode)
    }

    var settingsLabelKey: String {
        switch self {
        case .metric:
            return "settings.measurement.metric.short"
        case .us:
            return "settings.measurement.us.short"
        case .ukImp:
            return "settings.measurement.uk.short"
        case .auNz:
            return "settings.measurement.aunz.short"
        case .jp:
            return "settings.measurement.jp.short"
        }
    }

    var settingsListLabelKey: String {
        switch self {
        case .metric:
            return "settings.measurement.metric.long"
        case .us:
            return "settings.measurement.us.long"
        case .ukImp:
            return "settings.measurement.uk.long"
        case .auNz:
            return "settings.measurement.aunz.long"
        case .jp:
            return "settings.measurement.jp.long"
        }
    }

    var groceryOptionKey: String {
        switch self {
        case .metric:
            return "grocery.option.allWeight"
        case .us, .ukImp, .auNz, .jp:
            return "grocery.option.allWeight"
        }
    }

    var cupMilliliters: Double {
        switch self {
        case .metric:
            return 0
        case .us:
            return 240
        case .ukImp:
            return 0
        case .auNz:
            return 250
        case .jp:
            return 200
        }
    }

    var tablespoonMilliliters: Double {
        switch self {
        case .metric:
            return 0
        case .us, .ukImp, .jp:
            return 15
        case .auNz:
            return 20
        }
    }

    var teaspoonMilliliters: Double {
        switch self {
        case .metric:
            return 0
        case .us, .ukImp, .auNz, .jp:
            return 5
        }
    }
}
