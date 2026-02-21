//
//  RecipeRowView.swift
//  FamousChef
//

import SwiftUI

struct RecipeRowView: View {
    private let metricsToFavoriteSpacing: CGFloat = 6.6
    let recipe: Recipe
    let listViewValue: RecipeListValue
    let primaryMetricColumnWidth: CGFloat
    let secondaryMetricColumnWidth: CGFloat?
    let metricColumnSpacing: CGFloat
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let searchText: String
    let showDifficultyColumn: Bool
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()
    private var locale: Locale { Locale(identifier: appLanguage) }

    var body: some View {
        HStack(spacing: 6) {
            Text(FlagEmoji.from(countryCode: recipe.countryCode))
                .font(.title3)
                .frame(width: 34, alignment: .center)

            if showDifficultyColumn {
                difficultyDot
                    .frame(width: 28, alignment: .center)
            }

            Text(highlightedName)
                .lineLimit(2)
                .truncationMode(.tail)

            Spacer()

            HStack(spacing: metricsToFavoriteSpacing) {
                metrics

                Button(action: onToggleFavorite) {
                    Image(systemName: isFavorite ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(isFavorite ? .red : AppTheme.primaryBlue.opacity(0.85))
                        .frame(width: 18, alignment: .center)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .task {
            RecipeImagePrefetcher.prefetch(urlString: recipe.imageURL)
        }
    }

    private func meta(_ text: String, width: CGFloat) -> some View {
        Text(text)
            .font(.headline.weight(.semibold))
            .foregroundStyle(AppTheme.primaryBlue)
            .lineLimit(1)
            .frame(width: width, alignment: .trailing)
    }

    @ViewBuilder
    private var metrics: some View {
        switch listViewValue {
        case .prepAndWaitingTime:
            let passiveMinutes = max(0, recipe.totalMinutes - recipe.totalActiveMinutes)
            HStack(spacing: metricColumnSpacing) {
                meta("\(recipe.totalActiveMinutes)", width: primaryMetricColumnWidth)
                meta("\(passiveMinutes)", width: secondaryMetricColumnWidth ?? primaryMetricColumnWidth)
            }
        default:
            meta(listValueText, width: primaryMetricColumnWidth)
        }
    }

    @ViewBuilder
    private var difficultyDot: some View {
        if let difficulty = recipe.difficulty {
            Circle()
                .fill(DifficultyColor.color(for: difficulty))
                .frame(width: 12, height: 12)
        } else {
            Circle()
                .fill(AppTheme.primaryBlue.opacity(0.15))
                .frame(width: 12, height: 12)
        }
    }

    private var listValueText: String {
        switch listViewValue {
        case .totalTime:
            return "\(recipe.totalMinutes)"
        case .prepTime:
            return "\(recipe.totalActiveMinutes)"
        case .prepAndWaitingTime:
            return "\(recipe.totalActiveMinutes)"
        case .ingredients:
            return "\(recipe.ingredientsCountForList)"
        case .calories:
            return "\(recipe.calories)"
        }
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
