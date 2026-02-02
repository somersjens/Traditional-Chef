//
//  NutritionCard.swift
//  Traditional Chef
//

import SwiftUI

struct NutritionCard: View {
    let recipe: Recipe
    @State private var isExpanded: Bool = true
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()
    private var locale: Locale { Locale(identifier: appLanguage) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "leaf")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryBlue)

                    Text(AppLanguage.string("recipe.nutritionTitle", locale: locale))
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    Text("\(recipe.calories) kcal")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.primaryBlue.opacity(0.75))

                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryBlue)
                        .frame(width: 24, height: 24, alignment: .center)
                }
            }
            .buttonStyle(.plain)
            .contentShape(Rectangle())
            .accessibilityLabel(Text(isExpanded ? "Collapse nutrition" : "Expand nutrition"))

            if isExpanded {
                Divider()
                    .overlay(AppTheme.hairline)
                    .transition(.opacity)

                Text(AppLanguage.string("recipe.nutrition.perServing", locale: locale))
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textPrimary.opacity(0.8))

                VStack(spacing: 0) {
                    nutritionRow(labelKey: "recipe.nutrition.energy", value: kcalText(recipe.nutrition?.energyKcal))
                    dividerRow
                    nutritionRow(labelKey: "recipe.nutrition.protein", value: gramsText(recipe.nutrition?.proteinGrams))
                    dividerRow
                    nutritionRow(labelKey: "recipe.nutrition.carbs", value: gramsText(recipe.nutrition?.carbohydratesGrams))
                    dividerRow
                    nutritionRow(labelKey: "recipe.nutrition.sugars", value: gramsText(recipe.nutrition?.sugarsGrams))
                    dividerRow
                    nutritionRow(labelKey: "recipe.nutrition.fat", value: gramsText(recipe.nutrition?.fatGrams))
                    dividerRow
                    nutritionRow(labelKey: "recipe.nutrition.saturated", value: gramsText(recipe.nutrition?.saturatedFatGrams))
                    dividerRow
                    nutritionRow(labelKey: "recipe.nutrition.sodium", value: milligramsText(recipe.nutrition?.sodiumMilligrams))
                    dividerRow
                    nutritionRow(labelKey: "recipe.nutrition.fiber", value: gramsText(recipe.nutrition?.fiberGrams))
                }
                .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isExpanded)
        .padding(12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(AppTheme.primaryBlue.opacity(0.08), lineWidth: 1)
        )
    }

    private var dividerRow: some View {
        Divider()
            .overlay(AppTheme.hairline)
    }

    private func nutritionRow(labelKey: String, value: String) -> some View {
        HStack {
            Text(AppLanguage.string(labelKey, locale: locale))
                .font(.body)
                .foregroundStyle(AppTheme.textPrimary)

            Spacer()

            Text(value)
                .font(.body)
                .foregroundStyle(AppTheme.textPrimary)
        }
        .padding(.vertical, 6)
    }

    private func kcalText(_ value: Int?) -> String {
        guard let value else { return "x" }
        return "\(value) kcal"
    }

    private func gramsText(_ value: Double?) -> String {
        guard let value else { return "x" }
        return "\(formattedNumber(value)) g"
    }

    private func milligramsText(_ value: Double?) -> String {
        guard let value else { return "x" }
        return "\(formattedNumber(value)) mg"
    }

    private func formattedNumber(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}
