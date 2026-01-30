//
//  RecipeListView.swift
//  FamousChef
//

import SwiftUI

struct RecipeListView: View {
    @EnvironmentObject private var recipeStore: RecipeStore
    @StateObject private var vm = RecipeListViewModel()
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false

    @State private var showCountryPicker: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.pageBackground.ignoresSafeArea()

                VStack(spacing: 10) {
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
            .searchable(text: $vm.searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: Text("recipes.search"))
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button {
                        hasSeenWelcome = false
                    } label: {
                        HStack(spacing: 8) {
                            Image("chef_no_background")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 24, height: 24)

                            Text(appDisplayName)
                                .font(.title3.weight(.semibold))
                                .foregroundStyle(AppTheme.primaryBlue)
                        }
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("welcome.title"))
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
        return String(localized: "recipes.allCountriesShort")
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
                title: "🇺🇳",
                isActive: vm.sortKey == .country,
                isAscending: vm.ascending,
                textAlignment: .center,
                arrowPlacement: .trailing
            ) { vm.setSort(.country) }
                .frame(width: 34, alignment: .center)

            SortHeaderButton(
                title: String(localized: "recipes.column.name"),
                isActive: vm.sortKey == .name,
                isAscending: vm.ascending,
                textAlignment: .leading,
                arrowPlacement: .leadingGap(offset: -12)
            ) { vm.setSort(.name) }
                .frame(maxWidth: .infinity, alignment: .leading)

            SortHeaderButton(
                title: String(localized: "recipes.column.time"),
                isActive: vm.sortKey == .time,
                isAscending: vm.ascending,
                textAlignment: .trailing,
                arrowPlacement: .trailing
            ) { vm.setSort(.time) }
                .frame(width: 44, alignment: .trailing)
        }
        .font(.headline.weight(.semibold))
        .foregroundStyle(AppTheme.primaryBlue)
        .padding(.horizontal, 12)
        .padding(.top, 4)
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
                let name = String(localized: String.LocalizationValue(recipe.nameKey)).normalizedSearchKey
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
                let an = String(localized: String.LocalizationValue(a.nameKey))
                let bn = String(localized: String.LocalizationValue(b.nameKey))
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
}

private struct SortHeaderButton: View {
    enum ArrowPlacement {
        case trailing
        case leadingGap(offset: CGFloat)
    }

    let title: String
    let isActive: Bool
    let isAscending: Bool
    let textAlignment: Alignment
    let arrowPlacement: ArrowPlacement
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .frame(maxWidth: .infinity, alignment: textAlignment)
                .overlay(alignment: overlayAlignment) {
                    if isActive {
                        Image(systemName: isAscending ? "arrow.up" : "arrow.down")
                            .font(.caption2)
                            .offset(x: arrowOffset)
                    }
                }
                .foregroundStyle(AppTheme.primaryBlue)
        }
        .buttonStyle(.plain)
    }

    private var overlayAlignment: Alignment {
        switch arrowPlacement {
        case .trailing:
            return .trailing
        case .leadingGap:
            return .leading
        }
    }

    private var arrowOffset: CGFloat {
        switch arrowPlacement {
        case .trailing:
            return 0
        case .leadingGap(let offset):
            return offset
        }
    }
}
