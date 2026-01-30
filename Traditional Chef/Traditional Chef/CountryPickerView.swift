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
    @Environment(\.locale) private var locale

    var body: some View {
        NavigationStack {
            List {
                Button {
                    onSelect(nil)
                    dismiss()
                } label: {
                    HStack {
                        Text("recipes.allCountries")
                        Spacer()
                        if selected == nil { Image(systemName: "checkmark") }
                    }
                }
                .listRowBackground(AppTheme.searchBarBackground)

                Section("recipes.pickCountry") {
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
                        Text("done")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(AppTheme.searchBarBackground)
                            .clipShape(Capsule())
                    }
                }
                ToolbarItem(placement: .principal) {
                    Text("recipes.countryFilterTitle")
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
