//
//  RecipeRowView.swift
//  FamousChef
//

import SwiftUI
import UIKit

struct RecipeRowView: View {
    private let metricsToFavoriteSpacing: CGFloat = 6.6
    private let flagToContentSpacing: CGFloat = 6
    private let difficultyDotSize: CGFloat = 12
    private let difficultyToNameExtraSpacing: CGFloat = 2
    private var difficultyColumnWidth: CGFloat { difficultyDotSize + difficultyToNameExtraSpacing }
    let recipe: Recipe
    let listIndex: Int
    let listViewValue: RecipeListValue
    let primaryMetricColumnWidth: CGFloat
    let secondaryMetricColumnWidth: CGFloat?
    let metricColumnSpacing: CGFloat
    let isFavorite: Bool
    let onToggleFavorite: () -> Void
    let searchText: String
    let showDifficultyColumn: Bool
    let showImagePreview: Bool
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()
    @State private var randomPreviewImage: UIImage?
    @State private var isRandomPreviewLoading: Bool = false
    @State private var isRowVisible: Bool = false
    private var locale: Locale { Locale(identifier: appLanguage) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: flagToContentSpacing) {
                Text(FlagEmoji.from(countryCode: recipe.countryCode))
                    .font(.title3)
                    .frame(width: 34, alignment: .center)

                if showDifficultyColumn {
                    difficultyDot
                        .frame(width: difficultyColumnWidth, alignment: .leading)
                }

                Text(highlightedName)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .layoutPriority(1)

                Spacer(minLength: 0)

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

            if showImagePreview {
                randomImagePreview
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .animation(.easeInOut(duration: 0.22), value: showImagePreview)
        .onAppear {
            isRowVisible = true
        }
        .onDisappear {
            isRowVisible = false
        }
        .task(id: imageLoadingToken) {
            if showImagePreview && isRowVisible {
                await loadRandomPreviewImageIfNeeded()
            } else {
                randomPreviewImage = nil
                isRandomPreviewLoading = false
            }
        }
    }

    private var imageLoadingToken: String {
        "\(showImagePreview)-\(isRowVisible)-\(recipe.id)-\(listIndex)"
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
                .frame(width: difficultyDotSize, height: difficultyDotSize)
        } else {
            Circle()
                .fill(AppTheme.primaryBlue.opacity(0.15))
                .frame(width: difficultyDotSize, height: difficultyDotSize)
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


    @ViewBuilder
    private var randomImagePreview: some View {
        ZStack {
            AppTheme.secondaryOffWhite

            if let randomPreviewImage {
                Image(uiImage: randomPreviewImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if isRandomPreviewLoading {
                ProgressView()
                    .tint(AppTheme.primaryBlue)
                    .controlSize(.large)
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal, 4)
    }

    @MainActor
    private func loadRandomPreviewImageIfNeeded() async {
        guard randomPreviewImage == nil else { return }

        let maxStaggeredRows = 16
        let staggeredIndex = min(max(0, listIndex), maxStaggeredRows)
        let delayNanoseconds = UInt64(staggeredIndex) * 30_000_000
        if delayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
            guard !Task.isCancelled else { return }
        }

        isRandomPreviewLoading = true
        let loadedImage = await RecipeSharedImageLoader.shared.image(for: recipe.imageURL)
        randomPreviewImage = loadedImage
        isRandomPreviewLoading = false
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
