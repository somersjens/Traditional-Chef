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
    @AppStorage("measurementUnit") private var measurementUnitRaw: String = ""
    @AppStorage("defaultServings") private var defaultServings: Int = 4
    @AppStorage("timerAutoStop") private var timerAutoStop: Bool = true

    @State private var showCountryPicker: Bool = false
    @State private var showSettings: Bool = false
    private var locale: Locale { Locale(identifier: appLanguage) }

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.pageBackground.ignoresSafeArea()

                VStack(spacing: 10) {
                    topBar

                    if showSettings {
                        settingsCard
                            .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    searchBar

                    FilterChipsView(
                        selected: vm.selectedCategories,
                        onToggle: { cat in
                            vm.toggleCategory(cat)
                        },
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
            .toolbar(.hidden, for: .navigationBar)
            .onAppear {
                ensureMeasurementUnit()
            }
            .onChange(of: appLanguage) { _, _ in
                ensureMeasurementUnit()
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

    private var resolvedMeasurementUnit: MeasurementUnit {
        MeasurementUnit.resolved(from: measurementUnitRaw, languageCode: appLanguage)
    }

    private func ensureMeasurementUnit() {
        if MeasurementUnit(rawValue: measurementUnitRaw) == nil {
            measurementUnitRaw = MeasurementUnit.default(for: appLanguage).rawValue
        }
    }

    private var headerRow: some View {
        HStack(spacing: 10) {
            Button {
                vm.setSort(.country)
                showCountryPicker = true
            } label: {
                Text(countryFilterEmoji)
                    .font(.system(size: 16))
            }
            .buttonStyle(.plain)
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

    private var topBar: some View {
        ZStack {
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

            HStack {
                Spacer()
                settingsButton
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
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

    private var settingsButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                showSettings.toggle()
            }
        } label: {
            Image(systemName: "gearshape.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.primaryBlue)
        }
        .buttonStyle(.plain)
        .background(Color.clear)
        .accessibilityLabel(Text(AppLanguage.string("settings.title", locale: locale)))
    }

    private var settingsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Text(AppLanguage.string("settings.language", locale: locale))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryBlue)
                Spacer()
                Picker("", selection: $appLanguage) {
                    ForEach(AppLanguage.supported) { option in
                        Text("\(AppLanguage.string(option.nameKey, locale: locale)) \(FlagEmoji.from(countryCode: option.regionCode))")
                            .tag(option.code)
                    }
                }
                .pickerStyle(.menu)
                .tint(AppTheme.primaryBlue)
            }

            HStack(spacing: 12) {
                Text(AppLanguage.string("settings.measurement", locale: locale))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryBlue)
                Spacer()
                Picker("", selection: Binding(
                    get: { resolvedMeasurementUnit },
                    set: { measurementUnitRaw = $0.rawValue }
                )) {
                    ForEach(MeasurementUnit.allCases) { unit in
                        Text(AppLanguage.string(unit.settingsLabelKey, locale: locale))
                            .tag(unit)
                    }
                }
                .pickerStyle(.menu)
                .tint(AppTheme.primaryBlue)
            }

            HStack(spacing: 12) {
                Text(AppLanguage.string("settings.servings", locale: locale))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryBlue)
                Spacer()
                Picker("", selection: $defaultServings) {
                    ForEach(1...12, id: \.self) { servings in
                        Text("\(servings)")
                            .tag(servings)
                    }
                }
                .pickerStyle(.menu)
                .tint(AppTheme.primaryBlue)
            }

            Toggle(isOn: $timerAutoStop) {
                Text(AppLanguage.string("settings.timerAutoStop", locale: locale))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryBlue)
            }
            .tint(AppTheme.primaryBlue)
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(AppTheme.primaryBlue.opacity(0.08), lineWidth: 1)
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
