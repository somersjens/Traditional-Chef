//
//  FlagEmoji.swift
//  FamousChef
//

import Foundation

enum FlagEmoji {
    static func from(countryCode: String) -> String {
        let base: UInt32 = 127397
        return countryCode
            .uppercased()
            .unicodeScalars
            .compactMap { UnicodeScalar(base + $0.value) }
            .map { String($0) }
            .joined()
    }
}
