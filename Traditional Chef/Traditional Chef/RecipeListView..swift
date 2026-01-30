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
                    topBar
                    FilterChipsView(selected: vm.selectedCategories) { cat in
                        vm.toggleCategory(cat)
                    }

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
                                            onToggleFavorite: { recipeStore.toggleFavorite(recipe) }
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
                        Text(appDisplayName)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryBlue)
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

    private var topBar: some View {
        HStack(spacing: 12) {
            Button {
                showCountryPicker = true
            } label: {
                HStack(spacing: 6) {
                    Text(vm.selectedCountryCode == nil ? "recipes.allCountries" : "recipes.countryOnly")
                        .font(.subheadline.weight(.semibold))
                    Text(vm.selectedCountryCode.map { FlagEmoji.from(countryCode: $0) } ?? "🌍")
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(AppTheme.secondaryOffWhite)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(AppTheme.primaryBlue.opacity(0.12), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                // Favorites only: if no favorites exist, keep showing all (rule)
                vm.favoritesOnly.toggle()
            } label: {
                Image(systemName: vm.favoritesOnly ? "heart.fill" : "heart")
                    .foregroundStyle(vm.favoritesOnly ? .red : AppTheme.primaryBlue)
                    .padding(10)
                    .background(AppTheme.secondaryOffWhite)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(AppTheme.primaryBlue.opacity(0.12), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("recipes.favoritesOnly"))
        }
        .padding(.horizontal, 12)
        .padding(.top, 10)
    }

    private var headerRow: some View {
        HStack(spacing: 8) {
            SortHeaderButton(title: "🇺🇳", isActive: vm.sortKey == .country) { vm.setSort(.country) }
                .frame(width: 44, alignment: .leading)

            SortHeaderButton(title: String(localized: "recipes.column.name"), isActive: vm.sortKey == .name) { vm.setSort(.name) }
                .frame(maxWidth: .infinity, alignment: .leading)

            SortHeaderButton(title: String(localized: "recipes.column.time"), isActive: vm.sortKey == .time) { vm.setSort(.time) }
                .frame(width: 44, alignment: .trailing)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(AppTheme.primaryBlue.opacity(0.9))
        .padding(.horizontal, 16)
        .padding(.top, 4)
    }

    private var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 34))
                .foregroundStyle(AppTheme.primaryBlue.opacity(0.7))

            Text("recipes.noResults")
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

            Text("recipes.noResultsHint")
                .font(.subheadline)
                .foregroundStyle(AppTheme.primaryBlue.opacity(0.85))
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
    let title: String
    let isActive: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                if isActive {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.caption2)
                }
            }
            .foregroundStyle(isActive ? AppTheme.primaryBlue : AppTheme.primaryBlue.opacity(0.65))
        }
        .buttonStyle(.plain)
    }
}
