//
//  NutritionCard.swift
//  Traditional Chef
//

import SwiftUI

struct NutritionCard: View {
    private struct SpokenNutrient {
        let label: String
        let value: Double?
        let unit: String
    }

    let recipe: Recipe
    @State private var isExpanded: Bool = false
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()
    private var locale: Locale { Locale(identifier: appLanguage) }
    private let baseServings = 4
    private let valueColumnWidth: CGFloat = 86
    private let columnPadding: CGFloat = 8
    private let headerVerticalPadding: CGFloat = 4
    private let rowVerticalPadding: CGFloat = 4
    private let tableTopPadding: CGFloat = 4
    private let tableFont: Font = .body
    @StateObject private var cardSpeaker = CardReadAloudSpeaker()

    var body: some View {
        let headerIconWidth: CGFloat = 24
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Button {
                    if isExpanded {
                        cardSpeaker.toggleRead(text: readAloudText, languageCode: locale.identifier)
                    } else {
                        withAnimation(.easeInOut) {
                            isExpanded = true
                        }
                    }
                } label: {
                    Image(systemName: "chart.pie")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryBlue)
                        .frame(width: headerIconWidth, alignment: .center)

                    Text(AppLanguage.string("recipe.nutritionTitle", locale: locale))
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    Text(isExpanded ? AppLanguage.string("recipe.card.readAloud", locale: locale) : "Expand nutrition")
                )

                if isExpanded && cardSpeaker.isSpeaking {
                    Button {
                        cardSpeaker.toggleRead(text: readAloudText, languageCode: locale.identifier)
                    } label: {
                        Image(systemName: "speaker.wave.2.fill")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.primaryBlue)
                            .frame(width: 18, height: 18, alignment: .center)
                    }
                    .buttonStyle(.plain)
                }

                Spacer()

                Button {
                    withAnimation(.easeInOut) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text("\(recipe.calories) kcal")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.primaryBlue.opacity(0.75))
                        .lineLimit(1)
                }
                .buttonStyle(.plain)

                Button {
                    withAnimation(.easeInOut) {
                        isExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isExpanded ? "chevron.down" : "chevron.right")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryBlue)
                        .frame(width: 24, height: 24, alignment: .center)
                }
                .buttonStyle(.plain)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                guard !isExpanded else { return }
                withAnimation(.easeInOut) {
                    isExpanded = true
                }
            }
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
        .onDisappear {
            cardSpeaker.stop()
        }
        .onChange(of: isExpanded) { _, expanded in
            if !expanded {
                cardSpeaker.stop()
            }
        }
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

    private var readAloudText: String {
        let introFormatKey = locale.identifier.lowercased().hasPrefix("nl")
            ? "recipe.nutrition.readAloud.intro.nl"
            : "recipe.nutrition.readAloud.intro.en"
        let intro = String(
            format: AppLanguage.string(introFormatKey, locale: locale),
            locale: locale,
            recipe.calories
        )
        let nutrientLines: [String] = nutritionReadAloudItems.reduce(into: []) { partialResult, item in
            guard let value = item.value else { return }
            partialResult.append("\(item.label) \(formattedNumber(value)) \(item.unit)")
        }
        guard !nutrientLines.isEmpty else { return intro }
        return "\(intro). \(nutrientLines.joined(separator: ", "))"
    }

    private var nutritionReadAloudItems: [SpokenNutrient] {
        return [
            SpokenNutrient(label: AppLanguage.string("recipe.nutrition.protein", locale: locale), value: recipe.nutrition?.proteinGrams, unit: readAloudUnit("g")),
            SpokenNutrient(label: AppLanguage.string("recipe.nutrition.carbs", locale: locale), value: recipe.nutrition?.carbohydratesGrams, unit: readAloudUnit("g")),
            SpokenNutrient(label: AppLanguage.string("recipe.nutrition.sugars", locale: locale), value: recipe.nutrition?.sugarsGrams, unit: readAloudUnit("g")),
            SpokenNutrient(label: AppLanguage.string("recipe.nutrition.fat", locale: locale), value: recipe.nutrition?.fatGrams, unit: readAloudUnit("g")),
            SpokenNutrient(label: AppLanguage.string("recipe.nutrition.saturated", locale: locale), value: recipe.nutrition?.saturatedFatGrams, unit: readAloudUnit("g")),
            SpokenNutrient(label: AppLanguage.string("recipe.nutrition.sodium", locale: locale), value: recipe.nutrition?.sodiumMilligrams, unit: readAloudUnit("mg")),
            SpokenNutrient(label: AppLanguage.string("recipe.nutrition.fiber", locale: locale), value: recipe.nutrition?.fiberGrams, unit: readAloudUnit("g"))
        ]
    }

    private func readAloudUnit(_ unit: String) -> String {
        switch unit {
        case "g": return locale.identifier.lowercased().hasPrefix("nl") ? "gram" : "gram"
        case "mg": return locale.identifier.lowercased().hasPrefix("nl") ? "milligram" : "milligram"
        default: return unit
        }
    }
}
