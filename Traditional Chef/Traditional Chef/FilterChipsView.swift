//
//  FilterChipsView.swift
//  FamousChef
//

import SwiftUI

struct FilterChipsView: View {
    let selected: Set<RecipeCategory>
    let onToggle: (RecipeCategory) -> Void
    let countryLabel: String
    let isCountrySelected: Bool
    let onCountryTap: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                Button {
                    onCountryTap()
                } label: {
                    Text(countryLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppTheme.secondaryOffWhite)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(AppTheme.primaryBlue.opacity(isCountrySelected ? 0.6 : 0.18), lineWidth: isCountrySelected ? 2 : 1)
                        )
                }
                .buttonStyle(.plain)

                ForEach(RecipeCategory.filterCategories) { cat in
                    let isOn = selected.contains(cat)
                    Button {
                        onToggle(cat)
                    } label: {
                        Text(cat.localizedName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryBlue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppTheme.secondaryOffWhite)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(AppTheme.primaryBlue.opacity(isOn ? 0.6 : 0.18), lineWidth: isOn ? 2 : 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
        }
    }
}
