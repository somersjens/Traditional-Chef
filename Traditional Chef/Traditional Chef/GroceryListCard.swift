//
//  GroceryListCard.swift
//  FamousChef
//

import SwiftUI

struct GroceryListCard: View {
    let recipe: Recipe
    let servings: Int
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()
    private let ingredientRowSpacing: CGFloat = 9
    private var locale: Locale { Locale(identifier: appLanguage) }

    enum SortMode: String, CaseIterable {
        case useOrder
        case gramsDesc
        case supermarket
    }

    @State private var sortMode: SortMode = .useOrder
    @State private var checked: Set<String> = []
    @State private var isResettingChecks: Bool = false
    @State private var resetDisplayIngredients: [Ingredient] = []
    private let baseServings = 4

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryBlue)

                    Text(AppLanguage.string("recipe.groceryTitle", locale: locale))
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                }

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

            Divider()
                .overlay(AppTheme.hairline)

            if isResettingChecks {
                VStack(alignment: .leading, spacing: ingredientRowSpacing) {
                    ForEach(resetDisplayIngredients) { ing in
                        let isChecked = checked.contains(ing.id)
                        ingredientRow(ing, isChecked: isChecked)
                            .opacity(isChecked ? 0.65 : 1)
                    }
                }
            } else {
                VStack(alignment: .leading, spacing: ingredientRowSpacing) {
                    ForEach(uncheckedIngredients) { ing in
                        ingredientRow(ing, isChecked: false)
                    }
                }

                if !checkedIngredients.isEmpty && checkedIngredients.count != recipe.ingredients.count {
                    Divider().overlay(AppTheme.hairline)

                    VStack(alignment: .leading, spacing: ingredientRowSpacing) {
                        ForEach(checkedIngredients) { ing in
                            ingredientRow(ing, isChecked: true)
                                .opacity(0.65)
                        }
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
        .animation(nil, value: checked)
        .allowsHitTesting(!isResettingChecks)
        .onChange(of: checked) { _, newValue in
            saveChecked(newValue)
            if newValue.count == recipe.ingredients.count && !isResettingChecks {
                Haptics.success()
                startSequentialUncheck()
            }
        }
        .onAppear {
            checked = loadChecked()
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
            return recipe.ingredients.sorted { scaledGrams($0.grams) > scaledGrams($1.grams) }
        case .supermarket:
            return recipe.ingredients.sorted {
                if $0.aisle.rawValue != $1.aisle.rawValue { return $0.aisle.rawValue < $1.aisle.rawValue }
                return scaledGrams($0.grams) > scaledGrams($1.grams)
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
        HStack(spacing: 8) {
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
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(gramsValueString(scaledGrams(ing.grams)))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.primaryBlue)
                .frame(width: 44, alignment: .trailing)

            Text(gramsUnitString(scaledGrams(ing.grams)))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(AppTheme.primaryBlue)
                .frame(width: 28, alignment: .leading)

            Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isChecked ? AppTheme.primaryBlue : AppTheme.primaryBlue.opacity(0.8))
                .frame(width: 24, alignment: .trailing)
                .animation(.easeInOut(duration: 0.2), value: isChecked)
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

    private func scaledGrams(_ grams: Double) -> Double {
        grams * Double(servings) / Double(baseServings)
    }

    private var checkedStorageKey: String {
        "grocery.checked.\(recipe.id)"
    }

    private func loadChecked() -> Set<String> {
        guard let data = UserDefaults.standard.data(forKey: checkedStorageKey),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(decoded)
    }

    private func saveChecked(_ values: Set<String>) {
        let encoded = try? JSONEncoder().encode(Array(values))
        UserDefaults.standard.set(encoded, forKey: checkedStorageKey)
    }

    private func startSequentialUncheck() {
        isResettingChecks = true
        resetDisplayIngredients = sortedAll
        let idsToClear = sortedAll.map(\.id).filter { checked.contains($0) }
        let stepDelay = 0.12
        for (index, id) in idsToClear.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + (stepDelay * Double(index))) {
                _ = checked.remove(id)
            }
        }
        let totalDelay = (stepDelay * Double(idsToClear.count)) + 0.2
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
            isResettingChecks = false
            resetDisplayIngredients = []
        }
    }
}
