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
    private let flagBaselineAdjustment: CGFloat = -2
    private let difficultyBaselineAdjustment: CGFloat = 5
    private let previewShowDuration: Double = 0.15
    private let previewHideDuration: Double = 0.00
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
    let foregroundOpacity: CGFloat
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()
    @State private var randomPreviewImage: UIImage?
    @State private var isRandomPreviewLoading: Bool = false
    @State private var isRowVisible: Bool = false
    @State private var isPreviewHiding: Bool = false
    @State private var hideLayerResetTask: Task<Void, Never>?
    private var locale: Locale { Locale(identifier: appLanguage) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: flagToContentSpacing) {
                Text(FlagEmoji.from(countryCode: recipe.countryCode))
                    .font(.title3)
                    .frame(width: 34, alignment: .center)
                    .alignmentGuide(.firstTextBaseline) { dimensions in
                        dimensions[.firstTextBaseline] + flagBaselineAdjustment
                    }

                if showDifficultyColumn {
                    difficultyDot
                        .frame(width: difficultyColumnWidth, alignment: .leading)
                        .alignmentGuide(.firstTextBaseline) { dimensions in
                            dimensions[VerticalAlignment.center] + difficultyBaselineAdjustment
                        }
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
            .opacity(foregroundOpacity)

            if showImagePreview {
                randomImagePreview
                    .transition(
                        .asymmetric(
                            insertion: .opacity.animation(.easeInOut(duration: previewShowDuration)),
                            removal: .opacity.animation(.easeOut(duration: previewHideDuration))
                        )
                    )
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 4)
        .contentShape(Rectangle())
        .zIndex((showImagePreview || isPreviewHiding) ? 1 : 0)
        .animation(.easeInOut(duration: 0.14), value: showImagePreview)
        .onAppear {
            isRowVisible = true
            isPreviewHiding = false
        }
        .onChange(of: showImagePreview) { isShowingPreview in
            hideLayerResetTask?.cancel()
            guard !isShowingPreview else {
                isPreviewHiding = false
                return
            }

            isPreviewHiding = true
            let waitNanoseconds = UInt64(previewHideDuration * 1_000_000_000)
            hideLayerResetTask = Task { @MainActor in
                try? await Task.sleep(nanoseconds: waitNanoseconds)
                guard !Task.isCancelled, !showImagePreview else { return }
                isPreviewHiding = false
            }
        }
        .onDisappear {
            isRowVisible = false
            isRandomPreviewLoading = false
            hideLayerResetTask?.cancel()
            isPreviewHiding = false
        }
        .task(id: imageLoadingToken) {
            if showImagePreview && isRowVisible {
                await loadRandomPreviewImageIfNeeded()
            } else {
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
                meta(TimeDisplayFormatter.columnText(minutes: recipe.totalActiveMinutes, locale: locale), width: primaryMetricColumnWidth)
                meta(TimeDisplayFormatter.columnText(minutes: passiveMinutes, locale: locale), width: secondaryMetricColumnWidth ?? primaryMetricColumnWidth)
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
            return TimeDisplayFormatter.columnText(minutes: recipe.totalMinutes, locale: locale)
        case .prepTime:
            return TimeDisplayFormatter.columnText(minutes: recipe.totalActiveMinutes, locale: locale)
        case .prepAndWaitingTime:
            return TimeDisplayFormatter.columnText(minutes: recipe.totalActiveMinutes, locale: locale)
        case .ingredients:
            return "\(recipe.ingredientsCountForList)"
        case .calories:
            return formattedCaloriesPerPortion(recipe.calories)
        }
    }

    private func formattedCaloriesPerPortion(_ calories: Int) -> String {
        let roundedToNearestTen = (Double(calories) / 10).rounded() * 10
        return String(Int(roundedToNearestTen))
    }


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

        isRandomPreviewLoading = true

        let maxStaggeredRows = 16
        let staggeredIndex = min(max(0, listIndex), maxStaggeredRows)
        let delayNanoseconds = UInt64(staggeredIndex) * 30_000_000
        if delayNanoseconds > 0 {
            try? await Task.sleep(nanoseconds: delayNanoseconds)
            guard !Task.isCancelled else {
                isRandomPreviewLoading = false
                return
            }
        }

        let loadedImage = await RecipeSharedImageLoader.shared.image(for: recipe.imageURL)
        guard !Task.isCancelled else {
            isRandomPreviewLoading = false
            return
        }

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
