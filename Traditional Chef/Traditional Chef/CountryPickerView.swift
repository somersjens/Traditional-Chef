//
//  CountryPickerView.swift
//  FamousChef
//

import SwiftUI

struct CountryPickerView: View {
    let allCountryCodes: [String]
    let selected: String?
    let onSelect: (String?) -> Void

    @Environment(\.dismiss) private var dismiss
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()
    private var locale: Locale { Locale(identifier: appLanguage) }

    var body: some View {
        NavigationStack {
            List {
                Button {
                    onSelect(nil)
                    dismiss()
                } label: {
                    HStack {
                        Text(AppLanguage.string("recipes.allCountries", locale: locale))
                        Spacer()
                        if selected == nil { Image(systemName: "checkmark") }
                    }
                }
                .listRowBackground(AppTheme.searchBarBackground)

                Section(AppLanguage.string("recipes.pickCountry", locale: locale)) {
                    ForEach(allCountryCodes, id: \.self) { code in
                        Button {
                            onSelect(code)
                            dismiss()
                        } label: {
                            HStack {
                                Text("\(FlagEmoji.from(countryCode: code)) \(countryName(for: code))")
                                Spacer()
                                if selected == code { Image(systemName: "checkmark") }
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
}
