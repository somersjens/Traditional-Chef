//
//  String+Search.swift
//  FamousChef
//

import Foundation

extension String {
    /// Lowercased, diacritics-insensitive, and removes all spaces so "bolo gnese" matches "bolognese".
    var normalizedSearchKey: String {
        let lowered = self.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
        let noSpaces = lowered.replacingOccurrences(of: " ", with: "")
        return noSpaces.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
