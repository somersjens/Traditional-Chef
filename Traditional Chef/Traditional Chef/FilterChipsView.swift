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
        GeometryReader { proxy in
            HStack(spacing: 7) {
                Button {
                    onCountryTap()
                } label: {
                    chipLabel(text: countryLabel, isSelected: isCountrySelected, availableWidth: proxy.size.width)
                }
                .buttonStyle(.plain)

                ForEach(RecipeCategory.filterCategories) { cat in
                    let isOn = selected.contains(cat)
                    Button {
                        onToggle(cat)
                    } label: {
                        chipLabel(text: cat.localizedName, isSelected: isOn, availableWidth: proxy.size.width)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
        .frame(height: 40)
    }

    private func chipLabel(text: String, isSelected: Bool, availableWidth: CGFloat) -> some View {
        Text(text)
            .font(chipFont(for: availableWidth))
            .foregroundStyle(isSelected ? AppTheme.pageBackground : AppTheme.primaryBlue)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(isSelected ? AppTheme.primaryBlue : AppTheme.secondaryOffWhite)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(AppTheme.primaryBlue.opacity(isSelected ? 0.6 : 0.18), lineWidth: isSelected ? 2 : 1)
            )
    }

    private func chipFont(for availableWidth: CGFloat) -> Font {
        let compactThreshold: CGFloat = 350
        return availableWidth < compactThreshold
            ? .footnote.weight(.semibold)
            : .subheadline.weight(.semibold)
    }
}
