//
//  RecipeRowView.swift
//  FamousChef
//

import SwiftUI

struct RecipeRowView: View {
    let recipe: Recipe
    let isFavorite: Bool
    let onToggleFavorite: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Text(FlagEmoji.from(countryCode: recipe.countryCode))
                .font(.title3)
                .frame(width: 34, alignment: .leading)

            Text(String(localized: String.LocalizationValue(recipe.nameKey)))
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(2)
                .truncationMode(.tail)

            Spacer()

            HStack(spacing: 12) {
                meta("\(recipe.approximateMinutes)", width: 44)

                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .foregroundStyle(isFavorite ? .red : AppTheme.primaryBlue.opacity(0.85))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.primaryBlue.opacity(0.08), lineWidth: 1)
        )
    }

    private func meta(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppTheme.primaryBlue.opacity(0.9))
            .frame(width: width, alignment: .trailing)
    }
}
