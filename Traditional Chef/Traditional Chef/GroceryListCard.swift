//
//  GroceryListCard.swift
//  FamousChef
//

import SwiftUI

struct GroceryListCard: View {
    let recipe: Recipe
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()
    private var locale: Locale { Locale(identifier: appLanguage) }

    enum SortMode: String, CaseIterable {
        case useOrder
        case gramsDesc
        case supermarket
    }

    @State private var sortMode: SortMode = .useOrder
    @State private var checked: Set<String> = []
    @State private var showCelebration: Bool = false

    var body: some View {
        ZStack {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(AppLanguage.string("recipe.groceryTitle", locale: locale))
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    Menu {
                        Button(AppLanguage.string("grocery.sort.useOrder", locale: locale)) { sortMode = .useOrder }
                        Button(AppLanguage.string("grocery.sort.grams", locale: locale)) { sortMode = .gramsDesc }
                        Button(AppLanguage.string("grocery.sort.supermarket", locale: locale)) { sortMode = .supermarket }
                    } label: {
                        HStack(spacing: 6) {
                            Text(sortModeLabel)
                                .font(.subheadline.weight(.semibold))
                            Image(systemName: "arrow.up.arrow.down")
                        }
                        .foregroundStyle(AppTheme.primaryBlue)
                    }
                }

                Grid(horizontalSpacing: 6, verticalSpacing: 8) {
                    ForEach(uncheckedIngredients) { ing in
                        ingredientRow(ing, isChecked: false)
                    }
                }

                if !checkedIngredients.isEmpty {
                    Divider().overlay(AppTheme.hairline)

                    Grid(horizontalSpacing: 6, verticalSpacing: 8) {
                        ForEach(checkedIngredients) { ing in
                            ingredientRow(ing, isChecked: true)
                                .opacity(0.65)
                        }
                    }
                }
            }
            .padding(12)
            .background(AppTheme.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16).stroke(AppTheme.primaryBlue.opacity(0.08), lineWidth: 1)
            )

            if showCelebration {
                CelebrationOverlay(locale: locale)
                    .transition(.opacity)
            }
        }
        .onChange(of: checked) { _, newValue in
            if newValue.count == recipe.ingredients.count {
                Haptics.success()
                withAnimation(.easeInOut(duration: 0.2)) { showCelebration = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                    withAnimation(.easeInOut(duration: 0.2)) { showCelebration = false }
                    checked.removeAll()
                }
            }
        }
    }

    private var sortModeLabel: String {
        switch sortMode {
        case .useOrder: return AppLanguage.string("grocery.sortLabel.useOrder", locale: locale)
        case .gramsDesc: return AppLanguage.string("grocery.sortLabel.grams", locale: locale)
        case .supermarket: return AppLanguage.string("grocery.sortLabel.supermarket", locale: locale)
        }
    }

    private var sortedAll: [Ingredient] {
        switch sortMode {
        case .useOrder:
            return recipe.ingredients.sorted { $0.useOrder < $1.useOrder }
        case .gramsDesc:
            return recipe.ingredients.sorted { $0.grams > $1.grams }
        case .supermarket:
            return recipe.ingredients.sorted {
                if $0.aisle.rawValue != $1.aisle.rawValue { return $0.aisle.rawValue < $1.aisle.rawValue }
                return $0.grams > $1.grams
            }
        }
    }

    private var uncheckedIngredients: [Ingredient] {
        sortedAll.filter { !checked.contains($0.id) }
    }

    private var checkedIngredients: [Ingredient] {
        sortedAll.filter { checked.contains($0.id) }
    }

    private func ingredientRow(_ ing: Ingredient, isChecked: Bool) -> some View {
        GridRow {
            HStack(spacing: 6) {
                Text(AppLanguage.string(String.LocalizationValue(ing.nameKey), locale: locale))
                    .font(.body)
                    .foregroundStyle(AppTheme.textPrimary)

                if ing.isOptional {
                    Text(AppLanguage.string("grocery.optional", locale: locale))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryBlue.opacity(0.7))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(AppTheme.primaryBlue.opacity(0.08))
                        .clipShape(Capsule())
                }
            }
            .gridColumnAlignment(.leading)

            Text(gramsValueString(ing.grams))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.primaryBlue)
                .frame(width: 44, alignment: .trailing)
                .gridColumnAlignment(.trailing)

            Text(gramsUnitString(ing.grams))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.primaryBlue)
                .frame(width: 28, alignment: .leading)
                .gridColumnAlignment(.leading)

            Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isChecked ? AppTheme.primaryBlue : AppTheme.primaryBlue.opacity(0.8))
                .gridColumnAlignment(.trailing)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if isChecked {
                checked.remove(ing.id)
            } else {
                checked.insert(ing.id)
            }
        }
    }

    private func gramsValueString(_ grams: Double) -> String {
        if grams < 1 {
            return String(format: "%.1f", grams)
        }
        if grams.rounded(.down) == grams {
            return "\(Int(grams))"
        }
        return String(format: "%.0f", grams)
    }

    private func gramsUnitString(_ grams: Double) -> String {
        _ = grams
        return "g"
    }
}

private struct CelebrationOverlay: View {
    let locale: Locale
    @State private var pop: Bool = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.black.opacity(0.08))

            VStack(spacing: 8) {
                Text("🎉")
                    .font(.system(size: 44))
                    .scaleEffect(pop ? 1.15 : 0.8)

                Text(AppLanguage.string("grocery.allCollected", locale: locale))
                    .font(.headline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryBlue)
                    .opacity(pop ? 1 : 0.3)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.35, dampingFraction: 0.55)) {
                pop = true
            }
        }
    }
}
