//
//  RecipeListView.swift
//  FamousChef
//

import SwiftUI

struct RecipeListView: View {
    @EnvironmentObject private var recipeStore: RecipeStore
    @StateObject private var vm = RecipeListViewModel()
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()

    @State private var showCountryPicker: Bool = false
    @State private var showLanguagePicker: Bool = false
    private var locale: Locale { Locale(identifier: appLanguage) }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.pageBackground.ignoresSafeArea()

                VStack(spacing: 10) {
                    searchBar

                    FilterChipsView(
                        selected: vm.selectedCategories,
                        onToggle: { cat in
                            vm.toggleCategory(cat)
                        },
                        countryLabel: countryChipLabel,
                        isCountrySelected: vm.selectedCountryCode != nil || vm.selectedContinent != nil,
                        onCountryTap: { showCountryPicker = true },
                        locale: locale
                    )
                    .padding(.top, 10)

                    headerRow

                    ScrollView {
                        LazyVStack(spacing: 10) {
                            if filteredAndSortedRecipes.isEmpty {
                                emptyState
                            } else {
                                ForEach(filteredAndSortedRecipes) { recipe in
                                    NavigationLink(value: recipe) {
                                        RecipeRowView(
                                            recipe: recipe,
                                            isFavorite: recipeStore.isFavorite(recipe),
                                            onToggleFavorite: { recipeStore.toggleFavorite(recipe) },
                                            searchText: vm.searchText
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.horizontal, 12)
                                .padding(.bottom, 16)
                            }
                        }
                        .padding(.top, 6)
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: appLanguage)
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Spacer()
                        Button {
                            hasSeenWelcome = false
                        } label: {
                            HStack(spacing: 10) {
                                Text(appDisplayName)
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundStyle(AppTheme.primaryBlue)

                                Image("chef_no_background")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 29, height: 29)
                            }
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text(AppLanguage.string("welcome.title", locale: locale)))
                        Spacer()
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    languageMenu
                }
            }
            .sheet(isPresented: $showCountryPicker) {
                CountryPickerView(
                    allCountryCodes: allCountryCodes,
                    selected: vm.selectedCountryCode,
                    selectedContinent: vm.selectedContinent,
                    onSelect: { countryCode, continent in
                        vm.selectedCountryCode = countryCode
                        vm.selectedContinent = continent
                    }
                )
            }
        }
    }

    private var countryChipLabel: String {
        if let code = vm.selectedCountryCode {
            return FlagEmoji.from(countryCode: code)
        }
        if let continent = vm.selectedContinent {
            return continent.emoji
        }
        return "🌍"
    }

    private var headerRow: some View {
        HStack(spacing: 10) {
            SortHeaderButton(
                isActive: vm.sortKey == .country,
                isAscending: vm.ascending,
                textAlignment: .center,
                arrowPlacement: .trailing,
                arrowSpacing: 6,
                arrowLayout: .overlay,
                arrowOverlayOffset: 5
            ) {
                Image(systemName: "flag.fill")
                    .font(.system(size: 14, weight: .semibold))
            } action: {
                vm.setSort(.country)
            }
            .frame(width: 34, alignment: .center)

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
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            SortHeaderButton(
                isActive: vm.sortKey == .time,
                isAscending: vm.ascending,
                textAlignment: .trailing,
                arrowPlacement: .leading,
                arrowSpacing: 4
            ) {
                Text(AppLanguage.string("recipes.column.time", locale: locale))
            } action: {
                vm.setSort(.time)
            }
            .frame(width: 56, alignment: .trailing)

            Button {
                // Favorites only: if no favorites exist, keep showing all (rule)
                vm.favoritesOnly.toggle()
            } label: {
                Image(systemName: vm.favoritesOnly ? "heart.fill" : "heart")
                    .foregroundStyle(vm.favoritesOnly ? .red : AppTheme.primaryBlue.opacity(0.9))
                    .frame(width: 20, alignment: .center)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 4)
            .accessibilityLabel(Text(AppLanguage.string("recipes.favoritesOnly", locale: locale)))
        }
        .font(.headline.weight(.semibold))
        .foregroundStyle(AppTheme.primaryBlue)
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.primaryBlue.opacity(0.7))

            TextField(AppLanguage.string("recipes.search", locale: locale), text: $vm.searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
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
        .background(AppTheme.searchBarBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(AppTheme.primaryBlue.opacity(0.08), lineWidth: 1)
        )
        .padding(.horizontal, 16)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 34))
                .foregroundStyle(AppTheme.primaryBlue)

            Text(AppLanguage.string("recipes.noResults", locale: locale))
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Text(AppLanguage.string("recipes.noResultsHint", locale: locale))
                .font(.subheadline)
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 26)
        }
        .padding(.top, 40)
    }

    private var allCountryCodes: [String] {
        recipeStore.countryCodes
    }

    private var filteredAndSortedRecipes: [Recipe] {
        var list = recipeStore.recipes
        let localizedNames = recipeStore.localizedNames(for: locale)
        let normalizedNames = recipeStore.normalizedNames(for: locale)

        // Search: wildcard both sides + ignore spaces
        if !vm.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = vm.searchText.normalizedSearchKey(locale: locale)
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

        // Favorites filter (rule: if none yet, keep showing all)
        if vm.favoritesOnly, !recipeStore.favorites.isEmpty {
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
            case .time:
                result = a.approximateMinutes < b.approximateMinutes
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

    private var languageMenu: some View {
        Button {
            showLanguagePicker = true
        } label: {
            Text(AppLanguage.flag(for: appLanguage))
                .font(.title3)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(AppLanguage.string("language.selector", locale: locale)))
        .confirmationDialog(
            AppLanguage.string("language.selector", locale: locale),
            isPresented: $showLanguagePicker,
            titleVisibility: .visible
        ) {
            ForEach(AppLanguage.supported) { option in
                let label = "\(FlagEmoji.from(countryCode: option.regionCode)) \(AppLanguage.string(option.nameKey, locale: locale))"
                let isCurrent = appLanguage == option.code
                Button(isCurrent ? "\(label) ✓" : label) {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        appLanguage = option.code
                    }
                }
            }
        }
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
        self.label = label
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: arrowSpacing) {
                if arrowPlacement == .leading, arrowLayout == .inline {
                    arrowView
                }
                label()
                if arrowPlacement == .trailing, arrowLayout == .inline {
                    arrowView
                }
            }
            .frame(maxWidth: .infinity, alignment: textAlignment)
            .foregroundStyle(AppTheme.primaryBlue)
            .overlay(alignment: arrowAlignment) {
                if arrowLayout == .overlay {
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

    @ViewBuilder
    private var arrowView: some View {
        if isActive {
            Image(systemName: isAscending ? "arrow.up" : "arrow.down")
                .font(.caption2)
        }
    }
}
