//
//  Continent.swift
//  Traditional Chef
//

import Foundation

enum Continent: String, CaseIterable, Identifiable {
    case africa
    case asia
    case europe
    case northAmerica
    case southAmerica
    case oceania

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .africa:
            return "🌍"
        case .asia:
            return "🌏"
        case .europe:
            return "🌍"
        case .northAmerica:
            return "🌎"
        case .southAmerica:
            return "🌎"
        case .oceania:
            return "🌊"
        }
    }

    var nameKey: String {
        switch self {
        case .africa:
            return "continent.africa"
        case .asia:
            return "continent.asia"
        case .europe:
            return "continent.europe"
        case .northAmerica:
            return "continent.northAmerica"
        case .southAmerica:
            return "continent.southAmerica"
        case .oceania:
            return "continent.oceania"
        }
    }

    func contains(countryCode: String) -> Bool {
        Continent.countryCodes[self]?.contains(countryCode.uppercased()) ?? false
    }

    static func continent(for countryCode: String) -> Continent? {
        let normalized = countryCode.uppercased()
        return countryCodes.first { $0.value.contains(normalized) }?.key
    }

    private static let countryCodes: [Continent: Set<String>] = [
        .africa: [
            "DZ", "AO", "BJ", "BW", "BF", "BI", "CV", "CM", "CF", "TD", "KM", "CD",
            "DJ", "EG", "GQ", "ER", "ET", "GA", "GM", "GH", "GN", "GW", "CI", "KE",
            "LS", "LR", "LY", "MG", "MW", "ML", "MR", "MU", "MA", "MZ", "NA", "NE",
            "NG", "RW", "ST", "SN", "SC", "SL", "SO", "ZA", "SS", "SD", "SZ", "TZ",
            "TG", "TN", "UG", "EH", "ZM", "ZW"
        ],
        .asia: [
            "AF", "AM", "AZ", "BH", "BD", "BT", "BN", "KH", "CN", "GE", "IN", "ID",
            "IR", "IQ", "IL", "JP", "JO", "KZ", "KW", "KG", "LA", "LB", "MY", "MV",
            "MN", "MM", "NP", "KP", "KR", "OM", "PK", "PH", "QA", "SA", "SG", "LK",
            "SY", "TW", "TJ", "TH", "TL", "TM", "AE", "UZ", "VN", "YE", "HK", "MO", "PS"
        ],
        .europe: [
            "AL", "AD", "AT", "BY", "BE", "BA", "BG", "HR", "CY", "CZ", "DK", "EE",
            "FI", "FR", "DE", "GR", "HU", "IS", "IE", "IT", "LV", "LI", "LT", "LU",
            "MT", "MD", "MC", "ME", "NL", "MK", "NO", "PL", "PT", "RO", "RU", "SM",
            "RS", "SK", "SI", "ES", "SE", "CH", "TR", "UA", "GB", "VA", "XK"
        ],
        .northAmerica: [
            "AG", "BS", "BB", "BZ", "CA", "CR", "CU", "DM", "DO", "SV", "GD", "GT",
            "HT", "HN", "JM", "MX", "NI", "PA", "KN", "LC", "VC", "TT", "US"
        ],
        .southAmerica: [
            "AR", "BO", "BR", "CL", "CO", "EC", "GY", "PY", "PE", "SR", "UY", "VE",
            "GF", "FK"
        ],
        .oceania: [
            "AU", "NZ", "FJ", "PG", "SB", "VU", "NC", "PF", "WS", "TO", "KI", "FM",
            "MH", "NR", "PW", "TV"
        ]
    ]
}
