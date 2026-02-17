//
//  GroceryListCard.swift
//  FamousChef
//

import SwiftUI

struct GroceryListCard: View {
    let recipe: Recipe
    @Binding var servings: Int
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()
    @AppStorage("measurementUnit") private var measurementUnitRaw: String = ""
    @AppStorage("groceryAllMeasurements") private var showAllMeasurements: Bool = true
    private let ingredientRowSpacing: CGFloat = 9
    private var locale: Locale { Locale(identifier: appLanguage) }
    private var measurementUnit: MeasurementUnit {
        MeasurementUnit.resolved(from: measurementUnitRaw, languageCode: appLanguage)
    }

    enum SortMode: String, CaseIterable {
        case useOrder
        case gramsDesc
        case supermarket
    }

    @State private var sortMode: SortMode = .gramsDesc
    @State private var checked: Set<String> = []
    @State private var isResettingChecks: Bool = false
    @State private var resetDisplayIngredients: [Ingredient] = []
    @State private var isExpanded: Bool = false
    @State private var groupByDishPart: Bool = false
    @StateObject private var cardSpeaker = CardReadAloudSpeaker()
    private let minServings = 1
    private let maxServings = 99
    // Grocery amounts in the imported CSV are stored per person.
    // Keep scaling relative to a single serving so the selected
    // number of people multiplies the ingredient amounts directly.
    private let baseServings = 1
    private let headerRowHeight: CGFloat = 28
    private let optionRowHeight: CGFloat = 22.4
    private let optionRowVerticalPadding: CGFloat = 4.8
    private let optionButtonFont: Font = .subheadline.weight(.semibold)

    var body: some View {
        let headerIconWidth: CGFloat = 24
        return VStack(alignment: .leading, spacing: 10) {
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
                    Image(systemName: "cart")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryBlue)
                        .frame(width: headerIconWidth, alignment: .center)

                    Text(AppLanguage.string("recipe.groceryTitle", locale: locale))
                        .font(.headline)
                        .foregroundStyle(AppTheme.textPrimary)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(
                    Text(isExpanded ? AppLanguage.string("recipe.card.readAloud", locale: locale) : "Expand grocery list")
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
                    Text(grocerySummary)
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
                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundStyle(AppTheme.primaryBlue)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
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
            .accessibilityLabel(Text(isExpanded ? "Collapse grocery list" : "Expand grocery list"))

            if isExpanded {
                Divider()
                    .overlay(AppTheme.hairline)

                HStack(alignment: .center, spacing: 12) {
                    Text(AppLanguage.string("grocery.servings", locale: locale))
                        .font(.headline)
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
                            .font(.headline)
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

                if isResettingChecks {
                    VStack(alignment: .leading, spacing: ingredientRowSpacing) {
                        ingredientList(resetDisplayIngredients, checkedState: checked, isCheckedSection: false, dimChecked: true)
                    }
                } else {
                    VStack(alignment: .leading, spacing: ingredientRowSpacing) {
                        ingredientList(uncheckedIngredients, checkedState: [], isCheckedSection: false, dimChecked: false)
                    }

                    if !checkedIngredients.isEmpty {
                        if !uncheckedIngredients.isEmpty {
                            Divider().overlay(AppTheme.hairline)
                        }

                        VStack(alignment: .leading, spacing: ingredientRowSpacing) {
                            ingredientList(checkedIngredients, checkedState: checked, isCheckedSection: true, dimChecked: true)
                        }
                    }
                }

                Divider()
                    .overlay(AppTheme.hairline)

                GeometryReader { geometry in
                    let availableWidth = geometry.size.width - 16
                    let smallButtonWidth = availableWidth * 0.3
                    let largeButtonWidth = availableWidth * 0.4

                    HStack(alignment: .center, spacing: 8) {
                        measurementToggle
                            .frame(width: smallButtonWidth)

                        optionToggle(
                            titleKey: "grocery.option.partOfDish",
                            isOn: groupByDishPart,
                            action: { withAnimation(nil) { groupByDishPart.toggle() } }
                        )
                        .frame(width: smallButtonWidth)

                        sortButton
                            .frame(width: largeButtonWidth)
                    }
                }
                .frame(minHeight: headerRowHeight)
            }
        }
        .padding(12)
        .background(AppTheme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16).stroke(AppTheme.primaryBlue.opacity(0.08), lineWidth: 1)
        )
        .animation(nil, value: checked)
        .animation(nil, value: groupByDishPart)
        .allowsHitTesting(!isResettingChecks)
        .onChange(of: checked) { newValue in
            saveChecked(newValue)
            let checkedVisibleCount = newValue.intersection(visibleIngredientIds).count
            if checkedVisibleCount == visibleIngredientIds.count && !isResettingChecks {
                Haptics.success()
                startSequentialUncheck()
            }
        }
        .onAppear {
            checked = loadChecked()
        }
        .onDisappear {
            cardSpeaker.stop()
        }
        .onChange(of: isExpanded) { expanded in
            if !expanded {
                cardSpeaker.stop()
            }
        }
    }

    private var sortButton: some View {
        Button(action: advanceSortMode) {
            HStack(spacing: 6) {
                Text(sortModeLabel)
                    .font(optionButtonFont)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
                Image(systemName: sortModeArrowSystemName)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(AppTheme.primaryBlue)
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

    private var measurementToggle: some View {
        Button(action: { showAllMeasurements.toggle() }) {
            HStack(spacing: 6) {
                Text(AppLanguage.string(String.LocalizationValue(measurementUnit.groceryOptionKey), locale: locale))
                    .font(optionButtonFont)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
            .foregroundStyle(showAllMeasurements ? Color.white : AppTheme.primaryBlue)
            .frame(maxWidth: .infinity, minHeight: optionRowHeight)
            .padding(.horizontal, 10)
            .padding(.vertical, optionRowVerticalPadding)
            .background(
                Capsule().fill(showAllMeasurements ? AppTheme.primaryBlue : Color.clear)
            )
            .overlay(
                Capsule().stroke(AppTheme.primaryBlue, lineWidth: showAllMeasurements ? 0 : 1)
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

    private var sortModeArrowSystemName: String {
        switch sortMode {
        case .useOrder: return "arrow.down"
        case .gramsDesc: return "arrow.up"
        case .supermarket: return "arrow.down"
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
        let visibleIngredients = recipe.ingredients.filter { !($0.isInvisible ?? false) }
        let sourceIngredients = groupByDishPart ? visibleIngredients : mergedIngredients(visibleIngredients)
        switch sortMode {
        case .useOrder:
            return sourceIngredients.sorted { lhs, rhs in
                if lhs.useOrder != rhs.useOrder { return lhs.useOrder < rhs.useOrder }
                if lhs.nameKey != rhs.nameKey { return lhs.nameKey < rhs.nameKey }
                return lhs.id < rhs.id
            }
        case .gramsDesc:
            return sourceIngredients.sorted { lhs, rhs in
                let leftAmount = sortableAmount(for: lhs)
                let rightAmount = sortableAmount(for: rhs)
                if leftAmount != rightAmount { return leftAmount > rightAmount }
                if lhs.nameKey != rhs.nameKey { return lhs.nameKey < rhs.nameKey }
                return lhs.id < rhs.id
            }
        case .supermarket:
            return sourceIngredients.sorted { lhs, rhs in
                if lhs.aisle.rawValue != rhs.aisle.rawValue { return lhs.aisle.rawValue < rhs.aisle.rawValue }
                let leftGrams = scaledGrams(lhs.grams)
                let rightGrams = scaledGrams(rhs.grams)
                if leftGrams != rightGrams { return leftGrams > rightGrams }
                if lhs.nameKey != rhs.nameKey { return lhs.nameKey < rhs.nameKey }
                return lhs.id < rhs.id
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
        let groups = Array(Set(ingredients.map { $0.group })).sorted { lhs, rhs in
            let leftOrder = ingredients.first { $0.group == lhs }?.groupSortOrder ?? 0
            let rightOrder = ingredients.first { $0.group == rhs }?.groupSortOrder ?? 0
            if leftOrder != rightOrder {
                return leftOrder < rightOrder
            }
            return lhs.id < rhs.id
        }
        return groups.map { group in
            (group: group, items: ingredients.filter { $0.group == group })
        }
    }

    private func mergedIngredients(_ ingredients: [Ingredient]) -> [Ingredient] {
        var byId: [String: Ingredient] = [:]
        for ingredient in ingredients {
            if var existing = byId[ingredient.id] {
                existing = Ingredient(
                    id: existing.id,
                    nameKey: existing.nameKey,
                    grams: existing.grams + ingredient.grams,
                    ounces: existing.ounces + ingredient.ounces,
                    isOptional: false,
                    group: existing.group,
                    groupId: existing.groupId,
                    groupSortOrder: existing.groupSortOrder,
                    aisle: existing.aisle,
                    useOrder: min(existing.useOrder, ingredient.useOrder),
                    customAmountValue: nil,
                    customAmountLabelKey: nil,
                    displayMode: existing.displayMode ?? ingredient.displayMode,
                    gramsPerMl: existing.gramsPerMl ?? ingredient.gramsPerMl,
                    gramsPerTsp: existing.gramsPerTsp ?? ingredient.gramsPerTsp,
                    gramsPerCount: existing.gramsPerCount ?? ingredient.gramsPerCount,
                    allowCup: existing.allowCup,
                    isInvisible: existing.isInvisible ?? ingredient.isInvisible
                )
                byId[ingredient.id] = existing
            } else {
                byId[ingredient.id] = Ingredient(
                    id: ingredient.id,
                    nameKey: ingredient.nameKey,
                    grams: ingredient.grams,
                    ounces: ingredient.ounces,
                    isOptional: false,
                    group: ingredient.group,
                    groupId: ingredient.groupId,
                    groupSortOrder: ingredient.groupSortOrder,
                    aisle: ingredient.aisle,
                    useOrder: ingredient.useOrder,
                    customAmountValue: ingredient.customAmountValue,
                    customAmountLabelKey: ingredient.customAmountLabelKey,
                    displayMode: ingredient.displayMode,
                    gramsPerMl: ingredient.gramsPerMl,
                    gramsPerTsp: ingredient.gramsPerTsp,
                    gramsPerCount: ingredient.gramsPerCount,
                    allowCup: ingredient.allowCup,
                    isInvisible: ingredient.isInvisible
                )
            }
        }
        return Array(byId.values)
    }

    private func ingredientRow(_ ing: Ingredient, isChecked: Bool) -> some View {
        let columnWidths = amountColumnWidths
        return HStack(spacing: 8) {
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

            let amount = formattedAmount(for: ing)
            Text(amount.value)
                .font(.body)
                .foregroundStyle(AppTheme.textPrimary)
                .frame(width: columnWidths.value, alignment: .trailing)

            Text(amount.unit)
                .font(.body)
                .foregroundStyle(AppTheme.textPrimary)
                .lineLimit(1)
                .frame(width: columnWidths.unit, alignment: .leading)

            Image(systemName: isChecked ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isChecked ? AppTheme.primaryBlue : AppTheme.primaryBlue.opacity(0.8))
                .frame(width: 24, alignment: .trailing)
                .offset(y: 1.5)
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

    private var amountColumnWidths: (value: CGFloat, unit: CGFloat) {
        let amounts = sortedAll.map(formattedAmount(for:))
        let maxValueLength = amounts.map { $0.value.count }.max() ?? 1
        let maxUnitLength = amounts.map { $0.unit.count }.max() ?? 1

        let valueWidth = max(30, CGFloat(maxValueLength) * 11)
        let unitWidth = max(12, CGFloat(maxUnitLength) * 9)
        return (value: valueWidth, unit: unitWidth)
    }

    private func formattedAmount(for ingredient: Ingredient) -> GroceryMeasurementFormatter.DisplayAmount {
        GroceryMeasurementFormatter.formattedAmount(
            for: ingredient,
            servings: servings,
            baseServings: baseServings,
            measurementUnit: measurementUnit,
            showAllMeasurements: showAllMeasurements,
            locale: locale,
            localizedCustomLabel: { key in
                AppLanguage.string(String.LocalizationValue(key), locale: locale)
            }
        )
    }

    private func scaledGrams(_ grams: Double) -> Double {
        grams * Double(servings) / Double(baseServings)
    }

    private func sortableAmount(for ingredient: Ingredient) -> Double {
        scaledGrams(ingredient.grams)
    }

    private var grocerySummary: String {
        let format = AppLanguage.string("recipe.grocery.summary", locale: locale)
        return String(format: format, locale: locale, uniqueVisibleIngredientCount)
    }

    private var uniqueVisibleIngredientCount: Int {
        let visibleIngredients = recipe.ingredients.filter { !($0.isInvisible ?? false) }
        return Set(visibleIngredients.map(\.id)).count
    }

    private var checkedStorageKey: String {
        "grocery.checked.\(recipe.id)"
    }

    private var visibleIngredientIds: Set<String> {
        Set(orderedIngredientIds)
    }

    private func loadChecked() -> Set<String> {
        guard let data = UserDefaults.standard.data(forKey: checkedStorageKey),
              let decoded = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(decoded).intersection(visibleIngredientIds)
    }

    private func saveChecked(_ values: Set<String>) {
        let encoded = try? JSONEncoder().encode(Array(values.intersection(visibleIngredientIds)))
        UserDefaults.standard.set(encoded, forKey: checkedStorageKey)
    }

    private func startSequentialUncheck() {
        isResettingChecks = true
        resetDisplayIngredients = sortedAll
        let idsToClear = orderedIngredientIds.filter { checked.contains($0) }
        let stepDelay = 0.08
        for (index, id) in idsToClear.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + (stepDelay * Double(index))) {
                _ = checked.remove(id)
            }
        }
        let totalDelay = (stepDelay * Double(idsToClear.count)) + 0.13
        DispatchQueue.main.asyncAfter(deadline: .now() + totalDelay) {
            isResettingChecks = false
            resetDisplayIngredients = []
        }
    }

    private var orderedIngredientIds: [String] {
        var seen: Set<String> = []
        if groupByDishPart {
            return groupedIngredients(sortedAll).flatMap { group in
                group.items.compactMap { ingredient in
                    guard !seen.contains(ingredient.id) else { return nil }
                    seen.insert(ingredient.id)
                    return ingredient.id
                }
            }
        }
        return sortedAll.compactMap { ingredient in
            guard !seen.contains(ingredient.id) else { return nil }
            seen.insert(ingredient.id)
            return ingredient.id
        }
    }

    private var readAloudText: String {
        let introKey = locale.identifier.lowercased().hasPrefix("nl")
            ? "recipe.grocery.readAloud.intro.nl"
            : "recipe.grocery.readAloud.intro.en"
        let intro = String(
            format: AppLanguage.string(introKey, locale: locale),
            locale: locale,
            servings
        )

        let ingredientSentences: [String]
        if groupByDishPart {
            ingredientSentences = groupedIngredients(uncheckedIngredients).flatMap { group in
                let groupPrefixKey = locale.identifier.lowercased().hasPrefix("nl")
                    ? "recipe.grocery.readAloud.group.nl"
                    : "recipe.grocery.readAloud.group.en"
                let groupPrefix = String(
                    format: AppLanguage.string(groupPrefixKey, locale: locale),
                    locale: locale,
                    group.group.localizedName(in: locale)
                )
                let ingredients = group.items.map(spokenIngredientLine)
                return [groupPrefix] + ingredients
            }
        } else {
            ingredientSentences = uncheckedIngredients.map(spokenIngredientLine)
        }

        if ingredientSentences.isEmpty {
            let emptyKey = locale.identifier.lowercased().hasPrefix("nl")
                ? "recipe.grocery.readAloud.none.nl"
                : "recipe.grocery.readAloud.none.en"
            return "\(intro) \(AppLanguage.string(emptyKey, locale: locale))"
        }
        return "\(intro) \(ingredientSentences.joined(separator: ", "))"
    }

    private func spokenIngredientLine(_ ingredient: Ingredient) -> String {
        let amount = formattedAmount(for: ingredient)
        let name = AppLanguage.string(String.LocalizationValue(ingredient.nameKey), locale: locale)
        let unit = readAloudUnit(amount.unit)
        if unit.isEmpty {
            return "\(name) \(amount.value)"
        }
        return "\(name) \(amount.value) \(unit)"
    }

    private func readAloudUnit(_ unit: String) -> String {
        let languageIsDutch = locale.identifier.lowercased().hasPrefix("nl")
        switch unit.lowercased() {
        case "g": return "gram"
        case "mg": return languageIsDutch ? "milligram" : "milligram"
        case "kg": return languageIsDutch ? "kilogram" : "kilogram"
        case "ml": return "milliliter"
        case "l": return "liter"
        case "oz": return "ounce"
        case "lb": return languageIsDutch ? "pond" : "pound"
        case "cup": return languageIsDutch ? "kop" : "cup"
        case "tbsp": return languageIsDutch ? "eetlepel" : "tablespoon"
        case "tsp": return languageIsDutch ? "theelepel" : "teaspoon"
        case "pcs": return languageIsDutch ? "stuks" : "pieces"
        default: return unit
        }
    }
}
