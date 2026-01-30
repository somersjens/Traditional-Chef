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
            let parts = locale.identifier.split(whereSeparator: { $0 == "_" || $0 == "-" })
            languageCode = parts.first.map(String.init)
            regionCode = parts.count > 1 ? String(parts[1]) : nil
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

    private static func languageCode(from locale: Locale) -> String? {
        if #available(iOS 16, *) {
            return locale.language.languageCode?.identifier
        }
        return locale.identifier
            .split(whereSeparator: { $0 == "_" || $0 == "-" })
            .first
            .map(String.init)
    }

    private static func bundle(for locale: Locale) -> Bundle {
        guard let languageCode = languageCode(from: locale),
              let path = Bundle.main.path(forResource: languageCode, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return .main
        }
        return bundle
    }

    static var currentBundle: Bundle {
        bundle(for: currentLocale)
    }

    static func option(for code: String) -> Option {
        supported.first { $0.code == code } ?? supported[0]
    }

    static func flag(for code: String) -> String {
        FlagEmoji.from(countryCode: option(for: code).regionCode)
    }

    static func string(_ key: String.LocalizationValue) -> String {
        String(localized: key, bundle: currentBundle, locale: currentLocale)
    }

    static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(key), bundle: currentBundle, locale: currentLocale)
    }

    static func string(_ key: String.LocalizationValue, locale: Locale) -> String {
        String(localized: key, bundle: bundle(for: locale), locale: locale)
    }

    static func string(_ key: String, locale: Locale) -> String {
        String(localized: String.LocalizationValue(key), bundle: bundle(for: locale), locale: locale)
    }
}
