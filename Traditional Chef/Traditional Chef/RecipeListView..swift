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
                        isCountrySelected: vm.selectedCountryCode != nil,
                        onCountryTap: { showCountryPicker = true }
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
            }
            .navigationDestination(for: Recipe.self) { recipe in
                RecipeDetailView(recipe: recipe)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
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
                    .accessibilityLabel(Text("welcome.title"))
                }
                ToolbarItem(placement: .topBarTrailing) {
                    languageMenu
                }
            }
            .sheet(isPresented: $showCountryPicker) {
                CountryPickerView(
                    allCountryCodes: allCountryCodes,
                    selected: vm.selectedCountryCode,
                    onSelect: { vm.selectedCountryCode = $0 }
                )
            }
        }
    }

    private var countryChipLabel: String {
        if let code = vm.selectedCountryCode {
            return FlagEmoji.from(countryCode: code)
        }
        return AppLanguage.string("recipes.allCountriesShort")
    }

    private var headerRow: some View {
        HStack(spacing: 10) {
            Button {
                // Favorites only: if no favorites exist, keep showing all (rule)
                vm.favoritesOnly.toggle()
            } label: {
                Image(systemName: vm.favoritesOnly ? "heart.fill" : "heart")
                    .foregroundStyle(vm.favoritesOnly ? .red : AppTheme.primaryBlue.opacity(0.9))
                    .frame(width: 26, alignment: .center)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("recipes.favoritesOnly"))

            SortHeaderButton(
                isActive: vm.sortKey == .country,
                isAscending: vm.ascending,
                textAlignment: .center,
                arrowPlacement: .trailing,
                arrowSpacing: 6
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
                Text(AppLanguage.string("recipes.column.name"))
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
                Text(AppLanguage.string("recipes.column.time"))
            } action: {
                vm.setSort(.time)
            }
            .frame(width: 44, alignment: .trailing)
        }
        .font(.headline.weight(.semibold))
        .foregroundStyle(AppTheme.primaryBlue)
        .padding(.horizontal, 24)
        .padding(.top, 4)
    }

    private var searchBar: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(AppTheme.primaryBlue.opacity(0.7))

            TextField(AppLanguage.string("recipes.search"), text: $vm.searchText)
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
                .accessibilityLabel(Text("Clear search"))
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

            Text("recipes.noResults")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Text("recipes.noResultsHint")
                .font(.subheadline)
                .foregroundStyle(AppTheme.textPrimary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 26)
        }
        .padding(.top, 40)
    }

    private var allCountryCodes: [String] {
        Array(Set(recipeStore.recipes.map { $0.countryCode }))
            .sorted()
    }

    private var filteredAndSortedRecipes: [Recipe] {
        var list = recipeStore.recipes

        // Search: wildcard both sides + ignore spaces
        if !vm.searchText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let query = vm.searchText.normalizedSearchKey
            list = list.filter { recipe in
                let name = AppLanguage.string(String.LocalizationValue(recipe.nameKey)).normalizedSearchKey
                let country = recipe.countryCode.normalizedSearchKey
                return name.contains(query) || country.contains(query)
            }
        }

        // Category filter
        if !vm.selectedCategories.isEmpty {
            list = list.filter { vm.selectedCategories.contains($0.category) }
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
                let an = AppLanguage.string(String.LocalizationValue(a.nameKey))
                let bn = AppLanguage.string(String.LocalizationValue(b.nameKey))
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
        Menu {
            ForEach(AppLanguage.supported) { option in
                Button {
                    appLanguage = option.code
                } label: {
                    HStack {
                        Text("\(FlagEmoji.from(countryCode: option.regionCode)) \(AppLanguage.string(option.nameKey))")
                        if appLanguage == option.code {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 6) {
                Text(AppLanguage.flag(for: appLanguage))
                    .font(.title3)
                Image(systemName: "chevron.down")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryBlue.opacity(0.8))
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppTheme.searchBarBackground)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(AppTheme.primaryBlue.opacity(0.15), lineWidth: 1)
            )
        }
        .accessibilityLabel(Text(AppLanguage.string("language.selector")))
    }
}

private struct SortHeaderButton<Label: View>: View {
    enum ArrowPlacement {
        case leading
        case trailing
    }

    let isActive: Bool
    let isAscending: Bool
    let textAlignment: Alignment
    let arrowPlacement: ArrowPlacement
    let arrowSpacing: CGFloat
    let label: () -> Label
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: arrowSpacing) {
                if arrowPlacement == .leading {
                    arrowView
                }
                label()
                if arrowPlacement == .trailing {
                    arrowView
                }
            }
            .frame(maxWidth: .infinity, alignment: textAlignment)
            .foregroundStyle(AppTheme.primaryBlue)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var arrowView: some View {
        if isActive {
            Image(systemName: isAscending ? "arrow.up" : "arrow.down")
                .font(.caption2)
        }
    }
}
