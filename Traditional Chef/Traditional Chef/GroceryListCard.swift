//
//  GroceryListCard.swift
//  FamousChef
//

import SwiftUI

struct GroceryListCard: View {
    let recipe: Recipe
    @Binding var servings: Int
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
    @State private var isExpanded: Bool = true
    @State private var showAllGrams: Bool = true
    @State private var groupByDishPart: Bool = false
    private let minServings = 1
    private let maxServings = 99
    private let baseServings = 4
    private let headerRowHeight: CGFloat = 28
    private let optionRowHeight: CGFloat = 22.4
    private let optionRowVerticalPadding: CGFloat = 4.8
    private let optionButtonFont: Font = .subheadline.weight(.semibold)

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Image(systemName: "checkmark")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryBlue)

                    Text(AppLanguage.string("recipe.groceryTitle", locale: locale))
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    Text(grocerySummary)
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
            .accessibilityLabel(Text(isExpanded ? "Collapse grocery list" : "Expand grocery list"))

            if isExpanded {
                Divider()
                    .overlay(AppTheme.hairline)

                HStack(alignment: .center, spacing: 12) {
                    Text(AppLanguage.string("grocery.servings", locale: locale))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Spacer()

                    HStack(spacing: 10) {
                        Button(action: decrementServings) {
                            Image(systemName: "minus")
                                .font(.subheadline.weight(.semibold))
                                .frame(width: 26, height: 26)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(AppTheme.primaryBlue.opacity(servings <= minServings ? 0.3 : 1))
                        .disabled(servings <= minServings)

                        Text("\(servings)")
                            .font(.subheadline.weight(.semibold))
                            .frame(width: 32)

                        Button(action: incrementServings) {
                            Image(systemName: "plus")
                                .font(.subheadline.weight(.semibold))
                                .frame(width: 26, height: 26)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(AppTheme.primaryBlue.opacity(servings >= maxServings ? 0.3 : 1))
                        .disabled(servings >= maxServings)
                    }
                    .foregroundStyle(AppTheme.primaryBlue)
                }
                .frame(minHeight: headerRowHeight)

                Divider()
                    .overlay(AppTheme.hairline)

                GeometryReader { geometry in
                    let availableWidth = geometry.size.width - 16
                    let smallButtonWidth = availableWidth * 0.3
                    let largeButtonWidth = availableWidth * 0.4

                    HStack(alignment: .center, spacing: 8) {
                        optionToggle(
                            titleKey: "grocery.option.allGrams",
                            isOn: showAllGrams,
                            action: { showAllGrams.toggle() }
                        )
                        .frame(width: smallButtonWidth)

                        optionToggle(
                            titleKey: "grocery.option.partOfDish",
                            isOn: groupByDishPart,
                            action: { groupByDishPart.toggle() }
                        )
                        .frame(width: smallButtonWidth)

                        sortButton
                            .frame(width: largeButtonWidth)
                    }
                }
                .frame(minHeight: headerRowHeight)

                Divider()
                    .overlay(AppTheme.hairline)

                if isResettingChecks {
                    VStack(alignment: .leading, spacing: ingredientRowSpacing) {
                        ingredientList(resetDisplayIngredients, checkedState: checked, isCheckedSection: false, dimChecked: true)
                    }
                } else {
                    VStack(alignment: .leading, spacing: ingredientRowSpacing) {
                        ingredientList(uncheckedIngredients, checkedState: [], isCheckedSection: false, dimChecked: false)
                    }

                    if !checkedIngredients.isEmpty && checkedIngredients.count != recipe.ingredients.count {
                        Divider().overlay(AppTheme.hairline)

                        VStack(alignment: .leading, spacing: ingredientRowSpacing) {
                            ingredientList(checkedIngredients, checkedState: checked, isCheckedSection: true, dimChecked: true)
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

    private var sortButton: some View {
        Button(action: advanceSortMode) {
            HStack(spacing: 6) {
                Text(sortModeLabel)
                    .font(optionButtonFont)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Text("\(sortModeIndex)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.primaryBlue)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        Capsule().fill(AppTheme.primaryBlue.opacity(0.12))
                    )
            }
            .foregroundStyle(AppTheme.primaryBlue)
            .frame(maxWidth: .infinity, minHeight: optionRowHeight)
            .padding(.horizontal, 10)
            .padding(.vertical, optionRowVerticalPadding)
            .background(
                Capsule().stroke(AppTheme.primaryBlue, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func optionToggle(titleKey: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(AppLanguage.string(String.LocalizationValue(titleKey), locale: locale))
                    .font(optionButtonFont)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(isOn ? Color.white : AppTheme.primaryBlue)
            .frame(maxWidth: .infinity, minHeight: optionRowHeight)
            .padding(.horizontal, 10)
            .padding(.vertical, optionRowVerticalPadding)
            .background(
                Capsule().fill(isOn ? AppTheme.primaryBlue : Color.clear)
            )
            .overlay(
                Capsule().stroke(AppTheme.primaryBlue, lineWidth: isOn ? 0 : 1)
            )
        }
        .buttonStyle(.plain)
    }

    private func incrementServings() {
        updateServings(to: servings + 1)
    }

    private func decrementServings() {
        updateServings(to: servings - 1)
    }

    private func updateServings(to newValue: Int) {
        let clamped = min(max(newValue, minServings), maxServings)
        servings = clamped
    }

    private func advanceSortMode() {
        switch sortMode {
        case .useOrder:
            sortMode = .gramsDesc
        case .gramsDesc:
            sortMode = .supermarket
        case .supermarket:
            sortMode = .useOrder
        }
    }

    private var sortModeIndex: Int {
        switch sortMode {
        case .useOrder: return 1
        case .gramsDesc: return 2
        case .supermarket: return 3
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

    private func ingredientList(
        _ ingredients: [Ingredient],
        checkedState: Set<String>,
        isCheckedSection: Bool,
        dimChecked: Bool
    ) -> some View {
        Group {
            if groupByDishPart {
                ForEach(groupedIngredients(ingredients), id: \.group) { group in
                    if !group.items.isEmpty {
                        Text(group.group.localizedName(in: locale))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(AppTheme.textPrimary)
                            .padding(.top, 6)

                        ForEach(group.items) { ing in
                            ingredientRow(ing, isChecked: checkedState.contains(ing.id) || isCheckedSection)
                                .opacity(dimChecked && checkedState.contains(ing.id) ? 0.65 : 1)
                        }
                    }
                }
            } else {
                ForEach(ingredients) { ing in
                    ingredientRow(ing, isChecked: checkedState.contains(ing.id) || isCheckedSection)
                        .opacity(dimChecked && checkedState.contains(ing.id) ? 0.65 : 1)
                }
            }
        }
    }

    private func groupedIngredients(_ ingredients: [Ingredient]) -> [(group: IngredientGroup, items: [Ingredient])] {
        IngredientGroup.allCases.map { group in
            (group: group, items: ingredients.filter { $0.group == group })
        }
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

            if showAllGrams {
                Text(gramsValueString(scaledGrams(ing.grams)))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryBlue)
                    .frame(width: 44, alignment: .trailing)

                Text(gramsUnitString(scaledGrams(ing.grams)))
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(AppTheme.primaryBlue)
                    .frame(width: 28, alignment: .leading)
            } else {
                Spacer()
                    .frame(width: 72, alignment: .leading)
            }

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

    private var grocerySummary: String {
        let format = AppLanguage.string("recipe.grocery.summary", locale: locale)
        return String(format: format, locale: locale, recipe.ingredients.count)
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
