import Foundation

struct GroceryMeasurementFormatter {
    struct DisplayAmount {
        let value: String
        let unit: String
    }

    static func formattedAmount(
        for ingredient: Ingredient,
        servings: Int,
        baseServings: Int,
        measurementUnit: MeasurementUnit,
        showAllMeasurements: Bool,
        locale: Locale,
        localizedCustomLabel: (String) -> String
    ) -> DisplayAmount {
        let grams = scaledGrams(ingredient.grams, servings: servings, baseServings: baseServings)

        if showAllMeasurements {
            return metricWeightAmount(grams, locale: locale)
        }

        if let customValue = ingredient.customAmountValue,
           let customLabelKey = ingredient.customAmountLabelKey {
            return DisplayAmount(
                value: customValue,
                unit: localizedCustomLabel(customLabelKey)
            )
        }

        switch measurementUnit {
        case .metric:
            return metricAmount(for: ingredient, grams: grams, locale: locale)
        case .us, .ukImp, .auNz, .jp:
            return nonMetricAmount(for: ingredient, grams: grams, unit: measurementUnit, locale: locale)
        }
    }

    private static func metricAmount(for ingredient: Ingredient, grams: Double, locale: Locale) -> DisplayAmount {
        let mode = ingredient.displayMode ?? .weight
        switch mode {
        case .pcs:
            return pieceAmount(for: ingredient, grams: grams, locale: locale) ?? metricWeightAmount(grams, locale: locale)
        case .liquid:
            if let gramsPerMl = ingredient.gramsPerMl, gramsPerMl > 0 {
                let ml = grams / gramsPerMl
                if ml >= 1000 {
                    return DisplayAmount(value: formatNumber(ml / 1000, locale: locale), unit: "l")
                }
                return DisplayAmount(value: formatNumber(ml, locale: locale), unit: "ml")
            }
            return metricWeightAmount(grams, locale: locale)
        case .spoon:
            return spoonAmount(for: ingredient, grams: grams, unit: .metric, locale: locale)
        case .weight:
            return metricWeightAmount(grams, locale: locale)
        }
    }

    private static func nonMetricAmount(for ingredient: Ingredient, grams: Double, unit: MeasurementUnit, locale: Locale) -> DisplayAmount {
        let mode = ingredient.displayMode ?? .weight
        switch mode {
        case .pcs:
            return pieceAmount(for: ingredient, grams: grams, locale: locale)
                ?? DisplayAmount(value: formatNumber(grams, locale: locale), unit: "g")
        case .liquid:
            let gramsPerMl = positiveValue(ingredient.gramsPerMl) ?? 1
            return volumeAmount(grams: grams, gramsPerMl: gramsPerMl, allowCup: ingredient.allowCup ?? false, unit: unit, locale: locale)
        case .spoon:
            return spoonAmount(for: ingredient, grams: grams, unit: unit, locale: locale)
        case .weight:
            switch unit {
            case .us, .ukImp:
                return imperialWeightAmount(grams, locale: locale)
            case .metric, .auNz, .jp:
                return metricWeightAmount(grams, locale: locale)
            }
        }
    }

    private static func metricWeightAmount(_ grams: Double, locale: Locale) -> DisplayAmount {
        DisplayAmount(value: formatNumber(grams, locale: locale), unit: "g")
    }

    private static func imperialWeightAmount(_ grams: Double, locale: Locale) -> DisplayAmount {
        let ounces = grams / 28.349523125
        if ounces >= 16 {
            return DisplayAmount(value: formatNumber(ounces / 16, locale: locale), unit: "lb")
        }
        return DisplayAmount(value: formatNumber(ounces, locale: locale), unit: "oz")
    }

    private static func pieceAmount(for ingredient: Ingredient, grams: Double, locale: Locale) -> DisplayAmount? {
        if let gramsPerCount = ingredient.gramsPerCount, gramsPerCount > 0 {
            let count = max(0.25, (grams / gramsPerCount).rounded(toNearest: 0.25))
            return DisplayAmount(value: formatNumber(count, locale: locale), unit: "pcs")
        }

        if ingredient.grams > 0 {
            let count = max(0.25, (grams / ingredient.grams).rounded(toNearest: 0.25))
            return DisplayAmount(value: formatNumber(count, locale: locale), unit: "pcs")
        }

        return nil
    }

    private static func spoonAmount(for ingredient: Ingredient, grams: Double, unit: MeasurementUnit, locale: Locale) -> DisplayAmount {
        let spoonTeaspoonMl = unit == .metric ? 5.0 : unit.teaspoonMilliliters
        let spoonMeasurement = spoonTeaspoonMl > 0 ? spoonTeaspoonMl : 5.0
        let gramsPerMl = positiveValue(ingredient.gramsPerTsp).map { $0 / spoonMeasurement }
            ?? positiveValue(ingredient.gramsPerMl)
            ?? 1
        return volumeAmount(grams: grams, gramsPerMl: gramsPerMl, allowCup: ingredient.allowCup ?? false, unit: unit, locale: locale)
    }

    private static func positiveValue(_ value: Double?) -> Double? {
        guard let value, value > 0 else { return nil }
        return value
    }

    private static func volumeAmount(grams: Double, gramsPerMl: Double, allowCup: Bool, unit: MeasurementUnit, locale: Locale) -> DisplayAmount {
        let ml = grams / max(gramsPerMl, 0.001)
        let teaspoonMl = unit == .metric ? 5.0 : unit.teaspoonMilliliters
        let tablespoonMl = unit == .metric ? 15.0 : unit.tablespoonMilliliters
        let tsp = ml / max(teaspoonMl, 0.001)
        let tbsp = ml / max(tablespoonMl, 0.001)

        if allowCup, unit.cupMilliliters > 0 {
            let cups = ml / unit.cupMilliliters
            if cups >= 0.25 {
                let roundedCups = max(0.25, cups.rounded(toNearest: 0.25))
                return DisplayAmount(value: formatQuarterFraction(roundedCups, locale: locale), unit: "cup")
            }
        }

        if tbsp >= 1 {
            let roundedTbsp = max(1, tbsp.rounded(toNearest: 0.25))
            return DisplayAmount(value: formatQuarterFraction(roundedTbsp, locale: locale), unit: "tbsp")
        }

        let roundedTsp = max(0.25, tsp.rounded(toNearest: 0.25))
        return DisplayAmount(value: formatQuarterFraction(roundedTsp, locale: locale), unit: "tsp")
    }

    private static func scaledGrams(_ grams: Double, servings: Int, baseServings: Int) -> Double {
        grams * Double(servings) / Double(baseServings)
    }

    private static func formatNumber(_ value: Double, locale: Locale) -> String {
        if value.rounded(.down) == value {
            return decimalNumberFormatter(locale: locale, fractionDigits: 0).string(from: NSNumber(value: value))
                ?? "\(Int(value))"
        }
        let fractionDigits = value < 10 ? 1 : 0
        return decimalNumberFormatter(locale: locale, fractionDigits: fractionDigits).string(from: NSNumber(value: value))
            ?? String(format: "%.*f", fractionDigits, value)
    }

    private static func decimalNumberFormatter(locale: Locale, fractionDigits: Int) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        formatter.usesGroupingSeparator = true
        return formatter
    }

    private static func formatQuarterFraction(_ value: Double, locale: Locale) -> String {
        let rounded = value.rounded(toNearest: 0.25)
        let whole = Int(rounded)
        let fraction = rounded - Double(whole)

        let fractionText: String
        switch fraction {
        case 0.25: fractionText = "¼"
        case 0.5: fractionText = "½"
        case 0.75: fractionText = "¾"
        default: fractionText = ""
        }

        if whole == 0 {
            return fractionText.isEmpty ? formatNumber(rounded, locale: locale) : fractionText
        }
        return fractionText.isEmpty ? "\(whole)" : "\(whole) \(fractionText)"
    }
}

private extension Double {
    func rounded(toNearest step: Double) -> Double {
        guard step > 0 else { return self }
        return (self / step).rounded() * step
    }
}
