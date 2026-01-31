//
//  DrinkPairingCard.swift
//  FamousChef
//

import SwiftUI

struct DrinkPairingCard: View {
    let recipe: Recipe
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()
    private var locale: Locale { Locale(identifier: appLanguage) }

    var body: some View {
        if let bodyKey = recipe.drinkPairingKey {
            VStack(alignment: .leading, spacing: 10) {
                Text(AppLanguage.string("recipe.drinkTitle", locale: locale))
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                let raw = AppLanguage.string(String.LocalizationValue(bodyKey), locale: locale)
                let boldPhrases = recipe.drinkPairingBoldPhraseKeys.map {
                    AppLanguage.string(String.LocalizationValue($0), locale: locale)
                }

                Text(AttributedString.boldPhrases(in: raw, phrases: boldPhrases))
                    .font(.body)
                    .foregroundStyle(AppTheme.textPrimary.opacity(0.92))
            }
            .padding(12)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16).stroke(AppTheme.primaryBlue.opacity(0.08), lineWidth: 1)
            )
        }
    }
}
