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

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                header

                GroceryListCard(recipe: recipe)

                stepsCard
            }
            .padding(12)
        }
        .background(AppTheme.pageBackground)
        .navigationTitle(Text(AppLanguage.string(String.LocalizationValue(recipe.nameKey), locale: locale)))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
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
        HStack {
            Text(FlagEmoji.from(countryCode: recipe.countryCode))
                .font(.largeTitle)

            VStack(alignment: .leading, spacing: 4) {
                Text(AppLanguage.string(String.LocalizationValue(recipe.nameKey), locale: locale))
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("\(recipe.approximateMinutes) min • \(recipe.calories) kcal")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.primaryBlue.opacity(0.75))
            }

            Spacer()
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(AppTheme.primaryBlue.opacity(0.08), lineWidth: 1)
        )
    }

    private var stepsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(AppLanguage.string("recipe.stepsTitle", locale: locale))
                .font(.headline)
                .foregroundStyle(AppTheme.textPrimary)

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
        HStack(alignment: .top, spacing: 10) {
                Text("\(step.stepNumber)")
                    .font(.headline.weight(.bold))
                    .foregroundStyle(AppTheme.primaryBlue)
                    .frame(width: 22, alignment: .leading)

            VStack(alignment: .leading, spacing: 6) {
                Text(AppLanguage.string(String.LocalizationValue(step.titleKey), locale: locale))
                    .font(.headline)
                    .foregroundStyle(AppTheme.textPrimary)

                let raw = AppLanguage.string(String.LocalizationValue(step.bodyKey), locale: locale)
                Text(AttributedString.boldIngredients(
                    in: raw,
                    ingredientKeys: ingredients.map { $0.nameKey },
                    locale: locale
                ))
                    .font(.body)
                    .foregroundStyle(AppTheme.textPrimary.opacity(0.92))
            }

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
        .padding(.vertical, 4)
    }
}
