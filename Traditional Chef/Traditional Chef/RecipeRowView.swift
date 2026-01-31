//
//  RecipeRowView.swift
//  FamousChef
//

import SwiftUI

struct RecipeRowView: View {
    let recipe: Recipe
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let searchText: String
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()
    private var locale: Locale { Locale(identifier: appLanguage) }

    var body: some View {
        HStack(spacing: 10) {
            Text(FlagEmoji.from(countryCode: recipe.countryCode))
                .font(.title3)
                .frame(width: 34, alignment: .center)

            Text(highlightedName)
                .lineLimit(2)
                .truncationMode(.tail)

            Spacer()

            meta("\(recipe.approximateMinutes)", width: 44)

            Button(action: onToggleFavorite) {
                Image(systemName: isFavorite ? "heart.fill" : "heart")
                    .foregroundStyle(isFavorite ? .red : AppTheme.primaryBlue.opacity(0.85))
                    .frame(width: 20, alignment: .center)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background(AppTheme.searchBarBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.primaryBlue.opacity(0.08), lineWidth: 1)
        )
    }

    private func meta(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(.headline.weight(.semibold))
            .foregroundStyle(AppTheme.primaryBlue)
            .frame(width: width, alignment: .trailing)
    }

    private var highlightedName: AttributedString {
        let name = AppLanguage.string(String.LocalizationValue(recipe.nameKey), locale: locale)
        var attributedName = AttributedString(name)
        attributedName.font = .headline
        attributedName.foregroundColor = AppTheme.textPrimary

        let trimmedSearch = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSearch.isEmpty else {
            return attributedName
        }

        var tokens = trimmedSearch
            .split(whereSeparator: \.isWhitespace)
            .map { String($0) }
        let normalizedSearch = trimmedSearch.normalizedSearchKey
        if tokens.isEmpty, !normalizedSearch.isEmpty {
            tokens = [normalizedSearch]
        } else if !normalizedSearch.isEmpty, !tokens.contains(normalizedSearch) {
            tokens.append(normalizedSearch)
        }

        for token in tokens {
            var searchRange = attributedName.startIndex..<attributedName.endIndex
            while searchRange.lowerBound < searchRange.upperBound,
                  let range = attributedName[searchRange].range(
                    of: token,
                    options: [.caseInsensitive],
                    locale: nil
                  ) {
                attributedName[range].foregroundColor = AppTheme.searchHighlight
                searchRange = range.upperBound..<attributedName.endIndex
            }
        }

        return attributedName
    }
}
