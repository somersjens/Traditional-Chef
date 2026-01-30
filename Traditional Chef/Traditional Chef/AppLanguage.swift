//
//  AppLanguage.swift
//  Traditional Chef
//

import Foundation

enum AppLanguage {
    struct Option: Identifiable {
        let code: String
        let regionCode: String
        let nameKey: String

        var id: String { code }
    }

    static let supported: [Option] = [
        Option(code: "nl", regionCode: "NL", nameKey: "language.dutch"),
        Option(code: "en", regionCode: "GB", nameKey: "language.english")
    ]

    static func defaultCode() -> String {
        let locale = Locale.current
        let languageCode = locale.language.languageCode?.identifier ?? locale.languageCode
        let regionCode = locale.region?.identifier ?? locale.regionCode

        if languageCode == "nl" || regionCode == "NL" {
            return "nl"
        }
        return "en"
    }

    static var currentCode: String {
        UserDefaults.standard.string(forKey: "appLanguage") ?? defaultCode()
    }

    static var currentLocale: Locale {
        Locale(identifier: currentCode)
    }

    static func option(for code: String) -> Option {
        supported.first { $0.code == code } ?? supported[0]
    }

    static func flag(for code: String) -> String {
        FlagEmoji.from(countryCode: option(for: code).regionCode)
    }

    static func string(_ key: String.LocalizationValue) -> String {
        String(localized: key, locale: currentLocale)
    }

    static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), locale: currentLocale)
    }
}
