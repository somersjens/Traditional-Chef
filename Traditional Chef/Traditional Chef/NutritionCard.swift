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
    private let baseServings = 4
    private let valueColumnWidth: CGFloat = 86
    private let columnPadding: CGFloat = 8
    private let headerVerticalPadding: CGFloat = 4
    private let rowVerticalPadding: CGFloat = 4
    private let tableTopPadding: CGFloat = 4
    private let tableFont: Font = .body

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
                VStack(spacing: 0) {
                    Divider()
                        .overlay(AppTheme.hairline)
                        .transition(.opacity)

                    Spacer()
                        .frame(height: rowVerticalPadding * 2)

                    nutritionHeader
                        .padding(.top, tableTopPadding)
                    dividerRow

                    VStack(spacing: 0) {
                        nutritionRow(
                            labelKey: "recipe.nutrition.energy",
                            perServing: kcalText(recipe.nutrition?.energyKcal),
                            per100g: kcalText(recipe.nutrition?.energyKcal, multiplier: per100gMultiplier)
                        )
                        dividerRow
                        nutritionRow(
                            labelKey: "recipe.nutrition.protein",
                            perServing: gramsText(recipe.nutrition?.proteinGrams),
                            per100g: gramsText(recipe.nutrition?.proteinGrams, multiplier: per100gMultiplier)
                        )
                        dividerRow
                        nutritionRow(
                            labelKey: "recipe.nutrition.carbs",
                            perServing: gramsText(recipe.nutrition?.carbohydratesGrams),
                            per100g: gramsText(recipe.nutrition?.carbohydratesGrams, multiplier: per100gMultiplier)
                        )
                        dividerRow
                        nutritionRow(
                            labelKey: "recipe.nutrition.sugars",
                            perServing: gramsText(recipe.nutrition?.sugarsGrams),
                            per100g: gramsText(recipe.nutrition?.sugarsGrams, multiplier: per100gMultiplier)
                        )
                        dividerRow
                        nutritionRow(
                            labelKey: "recipe.nutrition.fat",
                            perServing: gramsText(recipe.nutrition?.fatGrams),
                            per100g: gramsText(recipe.nutrition?.fatGrams, multiplier: per100gMultiplier)
                        )
                        dividerRow
                        nutritionRow(
                            labelKey: "recipe.nutrition.saturated",
                            perServing: gramsText(recipe.nutrition?.saturatedFatGrams),
                            per100g: gramsText(recipe.nutrition?.saturatedFatGrams, multiplier: per100gMultiplier)
                        )
                        dividerRow
                        nutritionRow(
                            labelKey: "recipe.nutrition.sodium",
                            perServing: milligramsText(recipe.nutrition?.sodiumMilligrams),
                            per100g: milligramsText(recipe.nutrition?.sodiumMilligrams, multiplier: per100gMultiplier)
                        )
                        dividerRow
                        nutritionRow(
                            labelKey: "recipe.nutrition.fiber",
                            perServing: gramsText(recipe.nutrition?.fiberGrams),
                            per100g: gramsText(recipe.nutrition?.fiberGrams, multiplier: per100gMultiplier)
                        )
                    }
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

    private var nutritionHeader: some View {
        HStack(spacing: 0) {
            Text(AppLanguage.string("recipe.nutrition.columnType", locale: locale))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, columnPadding)

            verticalDivider

            Text(AppLanguage.string("recipe.nutrition.columnPerServing", locale: locale))
                .frame(width: valueColumnWidth, alignment: .trailing)
                .padding(.horizontal, columnPadding)

            verticalDivider

            Text(AppLanguage.string("recipe.nutrition.columnPer100g", locale: locale))
                .frame(width: valueColumnWidth, alignment: .trailing)
                .padding(.leading, columnPadding)
        }
        .font(tableFont.weight(.semibold))
        .foregroundStyle(AppTheme.textPrimary.opacity(0.8))
        .padding(.vertical, headerVerticalPadding)
    }

    private func nutritionRow(labelKey: String, perServing: String, per100g: String) -> some View {
        HStack(spacing: 0) {
            Text(AppLanguage.string(labelKey, locale: locale))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.trailing, columnPadding)

            verticalDivider

            Text(perServing)
                .frame(width: valueColumnWidth, alignment: .trailing)
                .padding(.horizontal, columnPadding)

            verticalDivider

            Text(per100g)
                .frame(width: valueColumnWidth, alignment: .trailing)
                .padding(.leading, columnPadding)
        }
        .font(tableFont)
        .foregroundStyle(AppTheme.textPrimary)
        .padding(.vertical, rowVerticalPadding)
    }

    private var per100gMultiplier: Double? {
        let totalGrams = recipe.ingredients.reduce(0) { $0 + $1.grams }
        guard totalGrams > 0 else { return nil }
        let servingGrams = totalGrams / Double(baseServings)
        guard servingGrams > 0 else { return nil }
        return 100.0 / servingGrams
    }

    private var verticalDivider: some View {
        Divider()
            .overlay(AppTheme.hairline)
            .frame(width: 1)
            .frame(maxHeight: .infinity)
    }

    private func kcalText(_ value: Int?, multiplier: Double? = nil) -> String {
        guard let value else { return "x" }
        let scaled = multiplier.map { Double(value) * $0 } ?? Double(value)
        return "\(formattedNumber(scaled)) kcal"
    }

    private func gramsText(_ value: Double?, multiplier: Double? = nil) -> String {
        guard let value else { return "x" }
        let scaled = multiplier.map { value * $0 } ?? value
        return "\(formattedNumber(scaled)) g"
    }

    private func milligramsText(_ value: Double?, multiplier: Double? = nil) -> String {
        guard let value else { return "x" }
        let scaled = multiplier.map { value * $0 } ?? value
        return "\(formattedNumber(scaled)) mg"
    }

    private func formattedNumber(_ value: Double) -> String {
        if value.rounded() == value {
            return String(Int(value))
        }
        return String(format: "%.1f", value)
    }
}
