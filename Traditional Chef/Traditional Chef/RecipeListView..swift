//
//  RecipeListView.swift
//  FamousChef
//

import SwiftUI
import UIKit

struct RecipeListView: View {
    private let metricsColumnSpacingMultiplier: CGFloat = 1.1
    private let metricsToFavoriteSpacingBase: CGFloat = 6
    private let flagToContentSpacing: CGFloat = 6
    private let difficultyDotSize: CGFloat = 12
    private let difficultyToNameExtraSpacing: CGFloat = 2
    private let minDefaultServings: Int = 1
    private let maxDefaultServings: Int = 12
    private var difficultyColumnWidth: CGFloat { difficultyDotSize + difficultyToNameExtraSpacing }
    private enum ScrollAnchor {
        static let top = "recipe-list-top"
    }

    @EnvironmentObject private var recipeStore: RecipeStore
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @StateObject private var vm = RecipeListViewModel()
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()
    @AppStorage("measurementUnit") private var measurementUnitRaw: String = ""
    @AppStorage(ReadVoicePreference.appStorageKey) private var readVoicePreferenceRaw: String = ReadVoicePreference.defaultValue.rawValue
    @AppStorage("defaultServings") private var defaultServings: Int = 4
    @AppStorage("listViewValue") private var listViewValueRaw: String = RecipeListValue.totalTime.rawValue
    @AppStorage("timerAutoStop") private var timerAutoStop: Bool = true
    @AppStorage("showDifficultyColumn") private var showDifficultyColumn: Bool = false

    @State private var showCountryPicker: Bool = false
    @State private var showSettings: Bool = false
    @State private var navigationPath: [Recipe] = []
    @State private var settingsCardMeasuredHeight: CGFloat = 0
    @State private var showMeasurementOptions: Bool = false
    @State private var scrollToTopRequest: Int = 0
    @State private var pendingNavigationTask: Task<Void, Never>?
    @State private var isOpeningRecipeDetail: Bool = false
    @State private var randomControlMaxButtonWidth: CGFloat = 0
    @FocusState private var isSearchFocused: Bool
    private var locale: Locale { Locale(identifier: appLanguage) }
    private var selectedCategoryFilter: RecipeCategory? { vm.selectedCategories.first }

    var body: some View {
        let visibleRecipes = filteredAndSortedRecipes
        let metricColumnWidths = metricColumnWidths(for: visibleRecipes)

        NavigationStack(path: $navigationPath) {
            ZStack {
                AppTheme.pageBackground.ignoresSafeArea()

                VStack(spacing: 10) {
                    topBar

                    settingsCardContainer

                    searchBar

                    ScrollViewReader { proxy in
                        FilterChipsView(
                            selected: vm.selectedCategories,
                            onToggle: { cat in
                                vm.toggleCategory(cat)
                                if vm.isRandomModeActive {
                                    vm.applyRandomSelection(from: filteredRecipesBeforeRandom, selectedCategory: selectedCategoryFilter)
                                }
                                requestScrollToTop()
                            },
                            locale: locale
                        )
                        .frame(maxWidth: contentMaxWidth, alignment: .leading)
                        .frame(maxWidth: .infinity, alignment: .center)

                        headerRow(metricColumnWidths: metricColumnWidths, onFilterOrSortChange: {
                            requestScrollToTop()
                        })

                        ScrollView {
                            VStack(spacing: 0) {
                                Color.clear
                                    .frame(height: 1)
                                    .id(ScrollAnchor.top)

                                LazyVStack(spacing: 10) {
                                    if visibleRecipes.isEmpty {
                                        emptyState
                                            .frame(maxWidth: contentMaxWidth, alignment: .center)
                                            .frame(maxWidth: .infinity, alignment: .center)
                                    } else {
                                        LazyVStack(spacing: 0) {
                                            ForEach(visibleRecipes) { recipe in
                                                Button {
                                                    openRecipeDetail(recipe)
                                                } label: {
                                                    RecipeRowView(
                                                        recipe: recipe,
                                                        listViewValue: listViewValue,
                                                        primaryMetricColumnWidth: metricColumnWidths.primary,
                                                        secondaryMetricColumnWidth: metricColumnWidths.secondary,
                                                        metricColumnSpacing: metricColumnWidths.columnSpacing,
                                                        isFavorite: recipeStore.isFavorite(recipe),
                                                        onToggleFavorite: { recipeStore.toggleFavorite(recipe) },
                                                        searchText: vm.debouncedSearchText,
                                                        showDifficultyColumn: showDifficultyColumn
                                                    )
                                                }
                                                .buttonStyle(RecipeSelectionButtonStyle())
                                                .disabled(isOpeningRecipeDetail)

                                                if recipe.id != visibleRecipes.last?.id {
                                                    Rectangle()
                                                        .fill(AppTheme.primaryBlue.opacity(0.14))
                                                        .frame(height: 0.5)
                                                        .padding(.leading, 21)
                                                        .padding(.trailing, 21)
                                                }
                                            }
                                        }
                                        .background(AppTheme.searchBarBackground)
                                        .clipShape(RoundedRectangle(cornerRadius: 16))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(AppTheme.primaryBlue.opacity(0.08), lineWidth: 1)
                                        )
                                        .padding(.horizontal, listSideInset)
                                        .frame(maxWidth: contentMaxWidth, alignment: .leading)
                                        .frame(maxWidth: .infinity, alignment: .center)

                                        if vm.isRandomModeActive {
                                            randomControls
                                                .padding(.top, 10)
                                                .padding(.bottom, 16)
                                                .frame(maxWidth: contentMaxWidth, alignment: .leading)
                                                .frame(maxWidth: .infinity, alignment: .center)
                                        } else {
                                            Color.clear.frame(height: 16)
                                        }
                                    }
                                }
                                .padding(.top, 6)
                            }
                        }
                        .onChange(of: scrollToTopRequest) { _ in
                            scrollToTop(using: proxy)
                        }
                    }
                }
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
                    .transaction { transaction in
                        transaction.disablesAnimations = true
                    }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                ensureMeasurementUnit()
                _ = RecipeDetailView.preparedKnifeImage
                isOpeningRecipeDetail = false
            }
            .onChange(of: vm.debouncedSearchText) { _ in
                vm.refreshRandomSelectionIfNeeded(from: filteredRecipesBeforeRandom, selectedCategory: selectedCategoryFilter)
            }
            .onChange(of: vm.selectedCountryCode) { _ in
                vm.refreshRandomSelectionIfNeeded(from: filteredRecipesBeforeRandom, selectedCategory: selectedCategoryFilter)
            }
            .onChange(of: vm.selectedContinent) { _ in
                vm.refreshRandomSelectionIfNeeded(from: filteredRecipesBeforeRandom, selectedCategory: selectedCategoryFilter)
            }
            .onChange(of: vm.favoritesOnly) { _ in
                vm.refreshRandomSelectionIfNeeded(from: filteredRecipesBeforeRandom, selectedCategory: selectedCategoryFilter)
            }
            .onChange(of: recipeStore.recipes) { _ in
                vm.refreshRandomSelectionIfNeeded(from: filteredRecipesBeforeRandom, selectedCategory: selectedCategoryFilter)
            }
            .onChange(of: appLanguage) { _ in
                ensureMeasurementUnit()
                randomControlMaxButtonWidth = 0
            }
            .onChange(of: vm.selectedCategories) { _ in
                randomControlMaxButtonWidth = 0
            }
            .onChange(of: vm.isRandomModeActive) { _ in
                randomControlMaxButtonWidth = 0
            }
            .sheet(isPresented: $showCountryPicker) {
                CountryPickerView(
                    allCountryCodes: allCountryCodes,
                    recipes: recipeStore.recipes,
                    selected: vm.selectedCountryCode,
                    selectedContinent: vm.selectedContinent,
                    onSelect: { countryCode, continent in
                        vm.selectedCountryCode = countryCode
                        vm.selectedContinent = continent
                        requestScrollToTop()
                    }
                )
            }
        }
    }

    private func requestScrollToTop() {
        scrollToTopRequest += 1
    }

    private func scrollToTop(using proxy: ScrollViewProxy) {
        withAnimation(.snappy(duration: 0.24, extraBounce: 0.03)) {
            proxy.scrollTo(ScrollAnchor.top, anchor: .top)
        }
    }

    private var resolvedMeasurementUnit: MeasurementUnit {
        MeasurementUnit.resolved(from: measurementUnitRaw, languageCode: appLanguage)
    }

    private var listViewValue: RecipeListValue {
        RecipeListValue(rawValue: listViewValueRaw) ?? .totalTime
    }

    private var readVoicePreference: ReadVoicePreference {
        ReadVoicePreference.resolved(from: readVoicePreferenceRaw)
    }

    private func ensureMeasurementUnit() {
        if MeasurementUnit(rawValue: measurementUnitRaw) == nil {
            measurementUnitRaw = MeasurementUnit.default(for: appLanguage).rawValue
        }
    }

    @MainActor
    private func openRecipeDetail(_ recipe: Recipe) {
        guard pendingNavigationTask == nil, !isOpeningRecipeDetail else { return }
        isOpeningRecipeDetail = true

        RecipeImagePrefetcher.prefetch(
            urlString: recipe.imageURL,
            priority: URLSessionTask.highPriority
        )

        OpeningTransitionSnapshotStore.listSnapshot = UIApplication.shared.firstKeyWindow?.snapshotImage()

        pendingNavigationTask = Task { @MainActor in
            defer {
                pendingNavigationTask = nil
            }

            try? await Task.sleep(nanoseconds: 120_000_000)
            guard !Task.isCancelled else { return }

            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                navigationPath.append(recipe)
            }
        }
    }

    private var contentMaxWidth: CGFloat {
        horizontalSizeClass == .regular ? 760 : .infinity
    }

    private struct MetricColumnWidths {
        let primary: CGFloat
        let secondary: CGFloat?
        let columnSpacing: CGFloat
    }

    private func metricColumnWidths(for recipes: [Recipe]) -> MetricColumnWidths {
        let headlineFont = UIFont.preferredFont(forTextStyle: .headline)
        let standardMinWidth: CGFloat = dynamicTypeSize.isAccessibilitySize ? 56 : 48
        let splitMetricMinDigits = dynamicTypeSize.isAccessibilitySize ? "888" : "88"
        let splitMetricMinWidth = ceil((splitMetricMinDigits as NSString)
            .size(withAttributes: [.font: headlineFont]).width) + 2
        let splitSecondaryLeadingRoom: CGFloat = dynamicTypeSize.isAccessibilitySize ? 12 : 8

        func width(for values: [String], minWidth: CGFloat) -> CGFloat {
            let measuredWidth = values
                .map { ($0 as NSString).size(withAttributes: [.font: headlineFont]).width }
                .max() ?? headlineFont.pointSize
            let computedWidth = ceil(measuredWidth) + 2
            return max(minWidth, computedWidth)
        }

        if listViewValue == .prepAndWaitingTime {
            let primaryValues = recipes.map { "\($0.totalActiveMinutes)" }
            let secondaryValues = recipes.map { "\(max(0, $0.totalMinutes - $0.totalActiveMinutes))" }
            return MetricColumnWidths(
                primary: width(
                    for: primaryValues + [AppLanguage.string("recipes.column.prepShort", locale: locale)],
                    minWidth: splitMetricMinWidth
                ),
                secondary: width(
                    for: secondaryValues + [AppLanguage.string("recipes.column.waitingShort", locale: locale)],
                    minWidth: splitMetricMinWidth + splitSecondaryLeadingRoom
                ),
                columnSpacing: 6 * metricsColumnSpacingMultiplier
            )
        }

        return MetricColumnWidths(
            primary: width(for: recipes.map(listValueText(for:)), minWidth: standardMinWidth),
            secondary: nil,
            columnSpacing: 4
        )
    }

    private func listValueText(for recipe: Recipe) -> String {
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

    private func decrementDefaultServings() {
        guard defaultServings > minDefaultServings else { return }
        defaultServings -= 1
    }

    private func incrementDefaultServings() {
        guard defaultServings < maxDefaultServings else { return }
        defaultServings += 1
    }

    private var listSideInset: CGFloat {
        16
    }
    private func headerRow(metricColumnWidths: MetricColumnWidths, onFilterOrSortChange: @escaping () -> Void) -> some View {
        HStack(spacing: flagToContentSpacing) {
            Button {
                vm.setSort(.country)
                onFilterOrSortChange()
                showCountryPicker = true
            } label: {
                Text(countryFilterEmoji)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
            .frame(width: 34, alignment: .center)

            if showDifficultyColumn {
                SortHeaderButton(
                    isActive: vm.sortKey == .difficulty,
                    isAscending: vm.ascending,
                    textAlignment: .center,
                    arrowPlacement: .trailing,
                    arrowSpacing: 4,
                    showArrow: false
                ) {
                    Circle()
                        .fill(difficultyHeaderColor)
                        .frame(width: difficultyDotSize, height: difficultyDotSize)
                        .offset(x: -1)
                } action: {
                    vm.setSort(.difficulty)
                    onFilterOrSortChange()
                }
                .frame(width: difficultyColumnWidth, alignment: .leading)
            }

            SortHeaderButton(
                isActive: vm.sortKey == .name,
                isAscending: vm.ascending,
                textAlignment: .leading,
                arrowPlacement: .trailing,
                arrowSpacing: 4
            ) {
                Text(AppLanguage.string("recipes.column.name", locale: locale))
            } action: {
                vm.setSort(.name)
                onFilterOrSortChange()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: metricsToFavoriteSpacingBase * metricsColumnSpacingMultiplier) {
                if listViewValue == .prepAndWaitingTime {
                    HStack(spacing: metricColumnWidths.columnSpacing) {
                        SortHeaderButton(
                            isActive: vm.sortKey == .prepTime,
                            isAscending: vm.ascending,
                            textAlignment: .trailing,
                            arrowPlacement: .leading,
                            arrowSpacing: 3
                        ) {
                            Image(systemName: "flame")
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)
                        } action: {
                            vm.setSort(.prepTime)
                            onFilterOrSortChange()
                        }
                        .frame(width: metricColumnWidths.primary, alignment: .trailing)

                        SortHeaderButton(
                            isActive: vm.sortKey == .waitingTime,
                            isAscending: vm.ascending,
                            textAlignment: .trailing,
                            arrowPlacement: .leading,
                            arrowSpacing: 3
                        ) {
                            Image(systemName: "hourglass")
                                .font(.system(size: 13, weight: .semibold))
                                .lineLimit(1)
                        } action: {
                            vm.setSort(.waitingTime)
                            onFilterOrSortChange()
                        }
                        .frame(width: metricColumnWidths.secondary ?? metricColumnWidths.primary, alignment: .trailing)
                    }
                } else {
                    SortHeaderButton(
                        isActive: vm.sortKey == listViewValue.sortKey,
                        isAscending: vm.ascending,
                        textAlignment: .trailing,
                        arrowPlacement: .leading,
                        arrowSpacing: 4
                    ) {
                        Image(systemName: listViewValue.headerSymbolName)
                            .font(.system(size: 13, weight: .semibold))
                            .lineLimit(1)
                    } action: {
                        vm.setSort(listViewValue.sortKey)
                        onFilterOrSortChange()
                    }
                    .frame(minWidth: metricColumnWidths.primary, alignment: .trailing)
                }

                Button {
                    vm.favoritesOnly.toggle()
                    onFilterOrSortChange()
                } label: {
                    Image(systemName: vm.favoritesOnly ? "heart.fill" : "heart")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(vm.favoritesOnly ? .red : AppTheme.primaryBlue.opacity(0.9))
                        .frame(width: 18, alignment: .center)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
                .accessibilityLabel(Text(AppLanguage.string("recipes.favoritesOnly", locale: locale)))
            }
        }
        .font(.headline.weight(.semibold))
        .foregroundStyle(AppTheme.primaryBlue)
        .padding(.horizontal, 4)
        .padding(.horizontal, listSideInset)
        .padding(.top, 4)
        .frame(maxWidth: contentMaxWidth, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var topBar: some View {
        ZStack {
            Button {
                hasSeenWelcome = false
            } label: {
                HStack(spacing: 10) {
                    Text(appDisplayName)
                        .font(.system(size: 26.4, weight: .semibold))
                        .foregroundStyle(AppTheme.primaryBlue)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)

                    Image("chef_no_background")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 32, height: 32)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text(AppLanguage.string("welcome.title", locale: locale)))

            HStack {
                randomizeButton
                Spacer()
                settingsButton
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .frame(maxWidth: contentMaxWidth, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var randomizeButton: some View {
        Button {
            isSearchFocused = false
            if vm.isRandomModeActive {
                vm.clearRandomSelection()
            } else {
                vm.applyRandomSelection(from: filteredRecipesBeforeRandom, selectedCategory: selectedCategoryFilter)
            }
            requestScrollToTop()
        } label: {
            Image(systemName: vm.isRandomModeActive ? "shuffle.circle.fill" : "shuffle")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.primaryBlue)
                .frame(width: 20, alignment: .center)
        }
        .buttonStyle(.plain)
        .padding(.leading, 8)
        .accessibilityLabel(Text(AppLanguage.string("recipes.randomize", locale: locale)))
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.primaryBlue.opacity(0.7))

            TextField(
                AppLanguage.string("recipes.search", locale: locale),
                text: $vm.searchText,
                prompt: Text(AppLanguage.string("recipes.search", locale: locale))
                    .foregroundColor(AppTheme.searchPlaceholder)
            )
                .textFieldStyle(.plain)
                .focused($isSearchFocused)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .font(.body)
                .foregroundStyle(AppTheme.textPrimary)

            if !vm.searchText.isEmpty {
                Button {
                    vm.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(AppTheme.primaryBlue.opacity(0.6))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(Text(AppLanguage.string("recipes.search.clear", locale: locale)))
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .frame(minHeight: 44)
        .background(AppTheme.searchBarBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.primaryBlue.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .frame(maxWidth: contentMaxWidth, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var settingsCardContainer: some View {
        ZStack(alignment: .top) {
            settingsCard
                .background(
                    GeometryReader { proxy in
                        Color.clear
                            .preference(key: SettingsCardHeightPreferenceKey.self, value: proxy.size.height)
                    }
                )
        }
        .frame(height: showSettings ? settingsCardMeasuredHeight : 0, alignment: .top)
        .clipped()
        .opacity(showSettings ? 1 : 0)
        .padding(.top, showSettings ? 6 : 0)
        .onPreferenceChange(SettingsCardHeightPreferenceKey.self) { height in
            if height > 0 {
                settingsCardMeasuredHeight = height
            }
        }
    }

    private var settingsButton: some View {
        Button {
            isSearchFocused = false
            withAnimation(.easeInOut(duration: 0.2)) {
                showSettings.toggle()
                if !showSettings {
                    showMeasurementOptions = false
                }
            }
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.primaryBlue)
                .frame(width: 20, alignment: .center)
        }
        .buttonStyle(.plain)
        .background(Color.clear)
        .padding(.trailing, 8)
        .accessibilityLabel(Text(AppLanguage.string("settings.title", locale: locale)))
    }

    private var settingsCard: some View {
        let selectedLanguage = AppLanguage.supported.first(where: { $0.code == appLanguage })
        let controlFont = Font.headline.weight(.regular)
        let rowMinHeight: CGFloat = 44
        let rowVerticalPadding: CGFloat = 4
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(AppLanguage.string("settings.title", locale: locale))
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(AppTheme.pageBackground)
                Spacer()
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showSettings = false
                        showMeasurementOptions = false
                    }
                } label: {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(AppTheme.pageBackground)
                }
                .buttonStyle(.plain)
            }
            .padding(.vertical, 2)
            .padding(.horizontal, 14)

            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 12) {
                    Text(AppLanguage.string("settings.language", locale: locale))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryBlue)
                        .multilineTextAlignment(.leading)
                        .layoutPriority(1)
                    Spacer()
                    Menu {
                        ForEach(AppLanguage.supported) { option in
                            Button {
                                appLanguage = option.code
                            } label: {
                                Text("\(AppLanguage.string(option.nameKey, locale: locale)) \(FlagEmoji.from(countryCode: option.regionCode))")
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text("\(AppLanguage.string(selectedLanguage?.nameKey ?? "settings.language", locale: locale)) \(FlagEmoji.from(countryCode: selectedLanguage?.regionCode ?? ""))")
                            Image(systemName: "chevron.down")
                        }
                        .font(controlFont)
                        .foregroundStyle(AppTheme.primaryBlue)
                        .fixedSize(horizontal: true, vertical: false)
                    }
                    .menuIndicator(.hidden)
                }
                .padding(.vertical, rowVerticalPadding)
                .frame(minHeight: rowMinHeight)

                Divider()
                    .overlay(AppTheme.primaryBlue.opacity(0.12))

                HStack(spacing: 12) {
                    Text(AppLanguage.string("settings.readVoice", locale: locale))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryBlue)
                        .multilineTextAlignment(.leading)
                        .layoutPriority(1)
                    Spacer()
                    Menu {
                        ForEach(ReadVoicePreference.allCases) { option in
                            Button {
                                readVoicePreferenceRaw = option.rawValue
                            } label: {
                                Text(AppLanguage.string(option.settingsLabelKey, locale: locale))
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(AppLanguage.string(readVoicePreference.settingsLabelKey, locale: locale))
                            Image(systemName: "chevron.down")
                        }
                        .font(controlFont)
                        .foregroundStyle(AppTheme.primaryBlue)
                        .fixedSize(horizontal: true, vertical: false)
                    }
                    .menuIndicator(.hidden)
                }
                .padding(.vertical, rowVerticalPadding)
                .frame(minHeight: rowMinHeight)

                Divider()
                    .overlay(AppTheme.primaryBlue.opacity(0.12))

                HStack(spacing: 12) {
                    Text(AppLanguage.string("settings.measurement", locale: locale))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryBlue)
                        .multilineTextAlignment(.leading)
                        .layoutPriority(1)
                    Spacer()
                    Button {
                        showMeasurementOptions = true
                    } label: {
                        HStack(spacing: 6) {
                            Text(AppLanguage.string(resolvedMeasurementUnit.settingsLabelKey, locale: locale))
                            Image(systemName: "chevron.down")
                        }
                        .font(controlFont)
                        .foregroundStyle(AppTheme.primaryBlue)
                        .fixedSize(horizontal: true, vertical: false)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showMeasurementOptions, arrowEdge: .top) {
                        VStack(alignment: .leading, spacing: 0) {
                            ForEach(MeasurementUnit.allCases) { unit in
                                Button {
                                    measurementUnitRaw = unit.rawValue
                                    showMeasurementOptions = false
                                } label: {
                                    HStack(spacing: 0) {
                                        Text(AppLanguage.string(unit.settingsListLabelKey, locale: locale))
                                            .foregroundStyle(AppTheme.primaryBlue)
                                            .multilineTextAlignment(.leading)
                                        Spacer(minLength: 0)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 10)
                                    .padding(.horizontal, 14)
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)

                                if unit != MeasurementUnit.allCases.last {
                                    Divider()
                                        .overlay(AppTheme.primaryBlue.opacity(0.12))
                                }
                            }
                        }
                        .frame(width: 330)
                        .padding(.vertical, 4)
                        .modifier(PopoverCompactAdaptationModifier())
                    }
                }
                .padding(.vertical, rowVerticalPadding)
                .frame(minHeight: rowMinHeight)

                Divider()
                    .overlay(AppTheme.primaryBlue.opacity(0.12))

                HStack(spacing: 12) {
                    Text(AppLanguage.string("settings.servings", locale: locale))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryBlue)
                        .multilineTextAlignment(.leading)
                        .layoutPriority(1)
                    Spacer()
                    HStack(spacing: 10) {
                        Button(action: decrementDefaultServings) {
                            Image(systemName: "minus")
                                .font(.subheadline.weight(.semibold))
                                .frame(width: 26, height: 26)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(AppTheme.primaryBlue.opacity(defaultServings <= minDefaultServings ? 0.3 : 1))
                        .disabled(defaultServings <= minDefaultServings)

                        Text("\(defaultServings)")
                            .font(.headline)
                            .foregroundStyle(AppTheme.primaryBlue)
                            .frame(width: 32)

                        Button(action: incrementDefaultServings) {
                            Image(systemName: "plus")
                                .font(.subheadline.weight(.semibold))
                                .frame(width: 26, height: 26)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(AppTheme.primaryBlue.opacity(defaultServings >= maxDefaultServings ? 0.3 : 1))
                        .disabled(defaultServings >= maxDefaultServings)
                    }
                }
                .padding(.vertical, rowVerticalPadding)
                .frame(minHeight: rowMinHeight)

                Divider()
                    .overlay(AppTheme.primaryBlue.opacity(0.12))

                HStack(spacing: 12) {
                    Text(AppLanguage.string("settings.listViewValue", locale: locale))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryBlue)
                        .multilineTextAlignment(.leading)
                        .layoutPriority(1)
                    Spacer()
                    Menu {
                        ForEach(RecipeListValue.allCases) { option in
                            Button {
                                listViewValueRaw = option.rawValue
                                vm.setSort(option.sortKey)
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: option.settingsSymbolName)
                                    Text(AppLanguage.string(option.settingsLabelKey, locale: locale))
                                }
                            }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: listViewValue.settingsSymbolName)
                            Image(systemName: "chevron.down")
                        }
                        .font(controlFont)
                        .foregroundStyle(AppTheme.primaryBlue)
                        .fixedSize(horizontal: true, vertical: false)
                    }
                    .menuIndicator(.hidden)
                }
                .padding(.vertical, rowVerticalPadding)
                .frame(minHeight: rowMinHeight)

                Divider()
                    .overlay(AppTheme.primaryBlue.opacity(0.12))

                HStack(spacing: 12) {
                    Text(AppLanguage.string("settings.difficultyColumn", locale: locale))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryBlue)
                        .multilineTextAlignment(.leading)
                        .layoutPriority(1)
                    Spacer()
                    Toggle("", isOn: $showDifficultyColumn)
                        .labelsHidden()
                        .tint(AppTheme.primaryBlue)
                        .scaleEffect(0.8, anchor: .trailing)
                }
                .padding(.vertical, rowVerticalPadding)
                .frame(minHeight: rowMinHeight)

                Divider()
                    .overlay(AppTheme.primaryBlue.opacity(0.12))

                HStack(spacing: 12) {
                    Text(AppLanguage.string("settings.timerAutoStop", locale: locale))
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryBlue)
                        .multilineTextAlignment(.leading)
                        .layoutPriority(1)
                    Spacer()
                    Toggle("", isOn: $timerAutoStop)
                        .labelsHidden()
                        .tint(AppTheme.primaryBlue)
                        .scaleEffect(0.8, anchor: .trailing)
                }
                .padding(.vertical, rowVerticalPadding)
                .frame(minHeight: rowMinHeight)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 14)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12).stroke(AppTheme.primaryBlue.opacity(0.12), lineWidth: 1)
            )
        }
        .padding(12)
        .background(AppTheme.settingsCardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(AppTheme.primaryBlue.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .frame(maxWidth: contentMaxWidth, alignment: .leading)
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 34))
                .foregroundStyle(AppTheme.primaryBlue)

            Text(AppLanguage.string("recipes.noResults", locale: locale))
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Button {
                clearAllFilters()
            } label: {
                Text(AppLanguage.string("recipes.clearAllFilters", locale: locale))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.pageBackground)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 9)
                    .background(AppTheme.primaryBlue)
                    .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
        }
        .padding(.top, 40)
    }

    private var randomControls: some View {
        VStack(spacing: 8) {
            actionButton(
                title: AppLanguage.string("recipes.random.new", locale: locale),
                isPrimary: false
            ) {
                vm.applyRandomSelection(from: filteredRecipesBeforeRandom, selectedCategory: selectedCategoryFilter)
                requestScrollToTop()
            }

            actionButton(
                title: AppLanguage.string("recipes.random.undo", locale: locale),
                isPrimary: true
            ) {
                vm.clearRandomSelection()
                requestScrollToTop()
            }
        }
        .frame(maxWidth: 320)
        .frame(maxWidth: .infinity, alignment: .center)
        .onPreferenceChange(RandomControlButtonWidthPreferenceKey.self) { width in
            randomControlMaxButtonWidth = width
        }
    }

    private func actionButton(title: String, isPrimary: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isPrimary ? AppTheme.pageBackground : AppTheme.primaryBlue)
                .lineLimit(1)
                .padding(.horizontal, 16)
                .padding(.vertical, 9)
                .background(
                    GeometryReader { proxy in
                        Color.clear.preference(key: RandomControlButtonWidthPreferenceKey.self, value: proxy.size.width)
                    }
                )
                .frame(width: randomControlMaxButtonWidth > 0 ? randomControlMaxButtonWidth : nil)
                .frame(maxWidth: .infinity)
                .background(isPrimary ? AppTheme.primaryBlue : AppTheme.secondaryOffWhite)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(AppTheme.primaryBlue.opacity(isPrimary ? 0.65 : 0.2), lineWidth: isPrimary ? 1 : 1.4)
                )
        }
        .buttonStyle(.plain)
    }


    private func clearAllFilters() {
        vm.selectedCountryCode = nil
        vm.selectedContinent = nil
        vm.selectedCategories.removeAll()
        vm.favoritesOnly = false
        vm.searchText = ""
        isSearchFocused = false
    }

    private var filteredAndSortedRecipes: [Recipe] {
        let sorted = filteredRecipesBeforeRandom
        guard vm.isRandomModeActive else { return sorted }

        let selectedIDs = Set(vm.randomSelectionIDs)
        var randomList = sorted.filter { selectedIDs.contains($0.id) }
        if selectedCategoryFilter == nil {
            randomList.sort { lhs, rhs in
                RecipeCategory.filterCategories.firstIndex(of: lhs.category) ?? 0
                < RecipeCategory.filterCategories.firstIndex(of: rhs.category) ?? 0
            }
        }
        return randomList
    }

    private var filteredRecipesBeforeRandom: [Recipe] {
        var list = recipeStore.recipes
        let localizedNames = recipeStore.localizedNames(for: locale)
        let normalizedNames = recipeStore.normalizedNames(for: locale)
        let query = vm.debouncedSearchText.normalizedSearchKey(locale: locale)

        // Search: wildcard both sides + ignore spaces
        if !query.isEmpty {
            list = list.filter { recipe in
                let name = normalizedNames[recipe.id]
                    ?? AppLanguage.string(String.LocalizationValue(recipe.nameKey), locale: locale)
                        .normalizedSearchKey(locale: locale)
                let country = recipe.countryCode.normalizedSearchKey(locale: locale)
                return name.contains(query) || country.contains(query)
            }
        }

        // Category filter
        if !vm.selectedCategories.isEmpty {
            list = list.filter { vm.selectedCategories.contains($0.category) }
        }

        // Continent filter
        if let continent = vm.selectedContinent {
            list = list.filter { continent.contains(countryCode: $0.countryCode) }
        }

        // Country filter
        if let cc = vm.selectedCountryCode {
            list = list.filter { $0.countryCode == cc }
        }

        // Favorites filter
        if vm.favoritesOnly {
            list = list.filter { recipeStore.isFavorite($0) }
        }

        // Sorting (one active at a time)
        list.sort { a, b in
            let result: Bool
            switch vm.sortKey {
            case .country:
                result = a.countryCode < b.countryCode
            case .name:
                let an = localizedNames[a.id]
                    ?? AppLanguage.string(String.LocalizationValue(a.nameKey), locale: locale)
                let bn = localizedNames[b.id]
                    ?? AppLanguage.string(String.LocalizationValue(b.nameKey), locale: locale)
                result = an.localizedCaseInsensitiveCompare(bn) == .orderedAscending
            case .difficulty:
                result = (a.difficulty ?? 0) < (b.difficulty ?? 0)
            case .totalTime:
                result = a.totalMinutes < b.totalMinutes
            case .prepTime:
                result = a.totalActiveMinutes < b.totalActiveMinutes
            case .waitingTime:
                result = max(0, a.totalMinutes - a.totalActiveMinutes) < max(0, b.totalMinutes - b.totalActiveMinutes)
            case .calories:
                result = a.calories < b.calories
            case .ingredients:
                result = a.ingredientsCountForList < b.ingredientsCountForList
            }
            return vm.ascending ? result : !result
        }
        return list
    }

    private var appDisplayName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "App"
    }

    private var allCountryCodes: [String] {
        recipeStore.countryCodes
    }

    private var countryFilterEmoji: String {
        if let countryCode = vm.selectedCountryCode {
            return FlagEmoji.from(countryCode: countryCode)
        }
        if let continent = vm.selectedContinent {
            return continent.emoji
        }
        return "🌍"
    }

    private var difficultyHeaderColor: Color {
        guard vm.sortKey == .difficulty else {
            return DifficultyColor.color(for: 3)
        }
        return vm.ascending ? DifficultyColor.color(for: 1) : DifficultyColor.color(for: 5)
    }
}

private struct RecipeSelectionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

private struct SortHeaderButton<Label: View>: View {
    enum ArrowPlacement {
        case leading
        case trailing
    }

    enum ArrowLayout {
        case inline
        case overlay
    }

    let isActive: Bool
    let isAscending: Bool
    let textAlignment: Alignment
    let arrowPlacement: ArrowPlacement
    let arrowSpacing: CGFloat
    let arrowLayout: ArrowLayout
    let arrowOverlayOffset: CGFloat
    let showArrow: Bool
    let label: () -> Label
    let action: () -> Void

    init(
        isActive: Bool,
        isAscending: Bool,
        textAlignment: Alignment,
        arrowPlacement: ArrowPlacement,
        arrowSpacing: CGFloat,
        arrowLayout: ArrowLayout = .inline,
        arrowOverlayOffset: CGFloat = 0,
        showArrow: Bool = true,
        @ViewBuilder label: @escaping () -> Label,
        action: @escaping () -> Void
    ) {
        self.isActive = isActive
        self.isAscending = isAscending
        self.textAlignment = textAlignment
        self.arrowPlacement = arrowPlacement
        self.arrowSpacing = arrowSpacing
        self.arrowLayout = arrowLayout
        self.arrowOverlayOffset = arrowOverlayOffset
        self.showArrow = showArrow
        self.label = label
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: arrowSpacing) {
                if showArrow, arrowPlacement == .leading, arrowLayout == .inline {
                    inlineArrowSlot
                }
                label()
                if showArrow, arrowPlacement == .trailing, arrowLayout == .inline {
                    inlineArrowSlot
                }
            }
            .frame(maxWidth: .infinity, alignment: textAlignment)
            .foregroundStyle(AppTheme.primaryBlue)
            .overlay(alignment: arrowAlignment) {
                if showArrow, arrowLayout == .overlay {
                    arrowView
                        .offset(x: arrowPlacement == .leading ? -arrowOverlayOffset : arrowOverlayOffset)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var arrowAlignment: Alignment {
        arrowPlacement == .leading ? .leading : .trailing
    }

    private var inlineArrowSlot: some View {
        Image(systemName: isAscending ? "arrow.up" : "arrow.down")
            .font(.caption2)
            .opacity(isActive ? 1 : 0)
            .frame(width: 10)
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var arrowView: some View {
        if showArrow, isActive {
            Image(systemName: isAscending ? "arrow.up" : "arrow.down")
                .font(.caption2)
        }
    }
}

private struct SettingsCardHeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct RandomControlButtonWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}


private struct PopoverCompactAdaptationModifier: ViewModifier {
    @ViewBuilder
    func body(content: Content) -> some View {
        if #available(iOS 16.4, *) {
            content.presentationCompactAdaptation(.popover)
        } else {
            content
        }
    }
}
