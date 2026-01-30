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
                    }
                }
            }
            .navigationTitle(Text("recipes.countryFilterTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("done") { dismiss() }
                }
            }
        }
    }

    private func countryName(for code: String) -> String {
        Locale.current.localizedString(forRegionCode: code) ?? code
    }
}
