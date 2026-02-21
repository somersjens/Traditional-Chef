//
//  CountryPickerView.swift
//  FamousChef
//

import SwiftUI

struct CountryPickerView: View {
    let allCountryCodes: [String]
    let recipes: [Recipe]
    let selected: String?
    let selectedContinent: Continent?
    let onSelect: (String?, Continent?) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()
    private var locale: Locale { Locale(identifier: appLanguage) }

    var body: some View {
        NavigationStack {
            List {
                Button {
                    onSelect(nil, nil)
                    dismiss()
                } label: {
                    HStack {
                        Text(AppLanguage.string("recipes.allCountries", locale: locale))
                        Spacer()
                        selectionStatus(count: recipes.count, isSelected: selected == nil && selectedContinent == nil)
                    }
                }
                .listRowBackground(AppTheme.searchBarBackground)

                if !availableContinents.isEmpty {
                    Section(AppLanguage.string("recipes.pickContinent", locale: locale)) {
                        ForEach(availableContinents) { continent in
                            Button {
                                onSelect(nil, continent)
                                dismiss()
                            } label: {
                                HStack {
                                    Text("\(continent.emoji) \(AppLanguage.string(continent.nameKey, locale: locale))")
                                    Spacer()
                                    selectionStatus(
                                        count: continentRecipeCounts[continent, default: 0],
                                        isSelected: selectedContinent == continent
                                    )
                                }
                            }
                            .listRowBackground(AppTheme.searchBarBackground)
                        }
                    }
                    .listRowBackground(AppTheme.searchBarBackground)
                }

                Section(AppLanguage.string("recipes.pickCountry", locale: locale)) {
                    ForEach(allCountryCodes, id: \.self) { code in
                        Button {
                            onSelect(code, nil)
                            dismiss()
                        } label: {
                            HStack {
                                Text("\(FlagEmoji.from(countryCode: code)) \(countryName(for: code))")
                                Spacer()
                                selectionStatus(
                                    count: countryRecipeCounts[code.uppercased(), default: 0],
                                    isSelected: selected == code
                                )
                            }
                        }
                        .listRowBackground(AppTheme.searchBarBackground)
                    }
                }
                .listRowBackground(AppTheme.searchBarBackground)
            }
            .navigationBarTitleDisplayMode(.inline)
            .scrollContentBackground(.hidden)
            .background(AppTheme.pageBackground)
            .foregroundStyle(AppTheme.primaryBlue)
            .tint(AppTheme.primaryBlue)
            .toolbarBackground(AppTheme.pageBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Text(AppLanguage.string("done", locale: locale))
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                    }
                    .buttonStyle(.plain)
                }
                ToolbarItem(placement: .principal) {
                    Text(AppLanguage.string("recipes.countryFilterTitle", locale: locale))
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryBlue)
                }
            }
        }
    }

    private func countryName(for code: String) -> String {
        locale.localizedString(forRegionCode: code) ?? code
    }

    private var availableContinents: [Continent] {
        Continent.allCases.filter { continent in
            allCountryCodes.contains { continent.contains(countryCode: $0) }
        }
    }

    private var countryRecipeCounts: [String: Int] {
        Dictionary(grouping: recipes, by: { $0.countryCode.uppercased() })
            .mapValues(\.count)
    }

    private var continentRecipeCounts: [Continent: Int] {
        Dictionary(uniqueKeysWithValues: availableContinents.map { continent in
            (continent, recipes.filter { continent.contains(countryCode: $0.countryCode) }.count)
        })
    }

    @ViewBuilder
    private func selectionStatus(count: Int, isSelected: Bool) -> some View {
        HStack(spacing: 8) {
            if isSelected {
                Image(systemName: "checkmark")
            }
            Text("\(count)")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.primaryBlue.opacity(0.8))
                .monospacedDigit()
        }
    }
}
