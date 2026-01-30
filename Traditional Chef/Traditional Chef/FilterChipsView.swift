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
                        .foregroundStyle(isCountrySelected ? AppTheme.secondaryOffWhite : AppTheme.primaryBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isCountrySelected ? AppTheme.primaryBlue : AppTheme.secondaryOffWhite)
                        .clipShape(Capsule())
                        .overlay(
                            Capsule().stroke(AppTheme.primaryBlue.opacity(0.18), lineWidth: 1)
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
                            .foregroundStyle(isOn ? AppTheme.secondaryOffWhite : AppTheme.primaryBlue)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(isOn ? AppTheme.primaryBlue : AppTheme.secondaryOffWhite)
                            .clipShape(Capsule())
                            .overlay(
                                Capsule().stroke(AppTheme.primaryBlue.opacity(0.18), lineWidth: 1)
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
