//
//  DrinkPairingCard.swift
//  FamousChef
//

import SwiftUI

struct DrinkPairingCard: View {
    let recipe: Recipe
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()
    private var locale: Locale { Locale(identifier: appLanguage) }
    @State private var isExpanded: Bool = true

    var body: some View {
        if let bodyKey = recipe.drinkPairingKey {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "wineglass")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryBlue)

                    Text(AppLanguage.string("recipe.drinkTitle", locale: locale))
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    if let summaryKey = recipe.drinkPairingSummaryKey {
                        Text(AppLanguage.string(String.LocalizationValue(summaryKey), locale: locale))
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.primaryBlue.opacity(0.75))
                    }

                    Button {
                        withAnimation(.easeInOut) {
                            isExpanded.toggle()
                        }
                    } label: {
                        Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                            .font(.headline)
                            .foregroundStyle(AppTheme.primaryBlue)
                            .accessibilityLabel(Text(isExpanded ? "Collapse drink recommendation" : "Expand drink recommendation"))
                    }
                    .buttonStyle(.plain)
                }

                if isExpanded {
                    Divider()
                        .overlay(AppTheme.hairline)
                        .transition(.opacity)

                    let raw = AppLanguage.string(String.LocalizationValue(bodyKey), locale: locale)
                    let boldPhrases = recipe.drinkPairingBoldPhraseKeys.map {
                        AppLanguage.string(String.LocalizationValue($0), locale: locale)
                    }

                    Text(AttributedString.boldPhrases(in: raw, phrases: boldPhrases))
                        .font(.body)
                        .foregroundStyle(AppTheme.textPrimary.opacity(0.92))
                        .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
                }
            }
            .animation(.easeInOut(duration: 0.25), value: isExpanded)
            .padding(12)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16).stroke(AppTheme.primaryBlue.opacity(0.08), lineWidth: 1)
            )
        }
    }
}
