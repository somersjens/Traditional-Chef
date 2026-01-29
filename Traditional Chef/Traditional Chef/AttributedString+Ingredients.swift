//
//  AttributedString+Ingredients.swift
//  FamousChef
//

import Foundation
import SwiftUI

extension AttributedString {
    /// Bold ingredient mentions inside the step text.
    /// We match by the localized ingredient display names.
    static func boldIngredients(in text: String, ingredientKeys: [String]) -> AttributedString {
        var attr = AttributedString(text)
        let localizedIngredients: [String] = ingredientKeys.map { String(localized: String.LocalizationValue($0)) }
            .sorted { $0.count > $1.count } // longer first to avoid partial overlaps

        for ing in localizedIngredients {
            guard !ing.isEmpty else { continue }
            // naive substring matching (works well for your current content)
            var searchRange = attr.startIndex..<attr.endIndex
            while searchRange.lowerBound < searchRange.upperBound,
                  let range = attr[searchRange].range(of: ing, options: [.caseInsensitive], locale: nil) {
                attr[range].font = .system(.body, design: .default).bold()
                searchRange = range.upperBound..<attr.endIndex
            }
        }

        return attr
    }
}
