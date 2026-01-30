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
        let languageCode: String?
        let regionCode: String?

        if #available(iOS 16, *) {
            languageCode = locale.language.languageCode?.identifier
            regionCode = locale.region?.identifier
        } else {
            languageCode = locale.languageCode
            regionCode = locale.regionCode
        }

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

    static func string(_ key: String.LocalizationValue, locale: Locale) -> String {
        String(localized: key, locale: locale)
    }

    static func string(_ key: String, locale: Locale) -> String {
        String(localized: String.LocalizationValue(key), locale: locale)
    }
}
