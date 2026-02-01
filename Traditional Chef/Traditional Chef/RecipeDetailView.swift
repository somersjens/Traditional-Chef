//
//  RecipeDetailView.swift
//  FamousChef
//

import SwiftUI

struct RecipeDetailView: View {
    @EnvironmentObject private var recipeStore: RecipeStore
    let recipe: Recipe
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()
    private var locale: Locale { Locale(identifier: appLanguage) }
    @State private var isInfoExpanded: Bool = true

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header

                DrinkPairingCard(recipe: recipe)

                GroceryListCard(recipe: recipe)

                stepsCard
            }
            .padding(12)
        }
        .background(AppTheme.pageBackground)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                let title = AppLanguage.string(String.LocalizationValue(recipe.nameKey), locale: locale)
                Text("\(FlagEmoji.from(countryCode: recipe.countryCode)) \(title)")
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .truncationMode(.tail)
                    .accessibilityLabel(Text("\(FlagEmoji.from(countryCode: recipe.countryCode)) \(title)"))
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    recipeStore.toggleFavorite(recipe)
                } label: {
                    Image(systemName: recipeStore.isFavorite(recipe) ? "heart.fill" : "heart")
                        .foregroundStyle(recipeStore.isFavorite(recipe) ? .red : AppTheme.primaryBlue)
                }
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "mappin")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryBlue)

                Text(AppLanguage.string("recipe.infoTitle", locale: locale))
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                Text("\(recipe.approximateMinutes) min • \(recipe.calories) kcal")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.primaryBlue.opacity(0.75))

                Button {
                    withAnimation(.easeInOut) {
                        isInfoExpanded.toggle()
                    }
                } label: {
                    Image(systemName: isInfoExpanded ? "chevron.down" : "chevron.right")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryBlue)
                        .accessibilityLabel(Text(isInfoExpanded ? "Collapse info" : "Expand info"))
                }
                .buttonStyle(.plain)
            }

            if isInfoExpanded {
                Divider()
                    .overlay(AppTheme.hairline)
                    .transition(.opacity)

                Text(AppLanguage.string(String.LocalizationValue(recipe.infoKey), locale: locale))
                    .font(.body)
                    .foregroundStyle(AppTheme.textPrimary)
                    .transition(.opacity.combined(with: .scale(scale: 0.98, anchor: .top)))
            }
        }
        .animation(.easeInOut(duration: 0.25), value: isInfoExpanded)
        .padding(12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(AppTheme.primaryBlue.opacity(0.08), lineWidth: 1)
        )
    }

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Image(systemName: "figure.walk")
                    .font(.headline)
                    .foregroundStyle(AppTheme.primaryBlue)

                Text(AppLanguage.string("recipe.stepsTitle", locale: locale))
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)
            }

            Divider()
                .overlay(AppTheme.hairline)

            ForEach(recipe.steps) { step in
                StepRowView(step: step, ingredients: recipe.ingredients)
                if step.id != recipe.steps.last?.id {
                    Divider().overlay(AppTheme.hairline)
                }
            }
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(AppTheme.primaryBlue.opacity(0.08), lineWidth: 1)
        )
    }
}

private struct StepRowView: View {
    let step: RecipeStep
    let ingredients: [Ingredient]

    @State private var showTimer: Bool = false
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()
    private var locale: Locale { Locale(identifier: appLanguage) }

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(alignment: .firstTextBaseline, spacing: 0) {
                Text("\(step.stepNumber). ")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(AppTheme.primaryBlue)
                Text(AppLanguage.string(String.LocalizationValue(step.titleKey), locale: locale))
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Spacer()

                if let seconds = step.timerSeconds {
                    TimerBadgeView(seconds: seconds) {
                        showTimer = true
                    }
                    .sheet(isPresented: $showTimer) {
                        CountdownTimerView(initialSeconds: seconds)
                    }
                }
            }

            let raw = AppLanguage.string(String.LocalizationValue(step.bodyKey), locale: locale)
            Text(AttributedString.boldIngredients(
                in: raw,
                ingredientKeys: ingredients.map { $0.nameKey },
                locale: locale
            ))
                .font(.system(size: 14))
                .foregroundStyle(AppTheme.textPrimary.opacity(0.92))
        }
        .padding(.vertical, 1.5)
    }
}
