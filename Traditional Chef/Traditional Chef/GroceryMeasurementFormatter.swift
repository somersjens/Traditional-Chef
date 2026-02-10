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
        localizedCustomLabel: (String) -> String
    ) -> DisplayAmount {
        if !showAllMeasurements,
           let customValue = ingredient.customAmountValue,
           let customLabelKey = ingredient.customAmountLabelKey {
            return DisplayAmount(
                value: customValue,
                unit: localizedCustomLabel(customLabelKey)
            )
        }

        let grams = scaledGrams(ingredient.grams, servings: servings, baseServings: baseServings)
        switch measurementUnit {
        case .metric:
            return metricAmount(for: ingredient, grams: grams)
        case .us, .ukImp, .auNz, .jp:
            return nonMetricAmount(for: ingredient, grams: grams, unit: measurementUnit)
        }
    }

    private static func metricAmount(for ingredient: Ingredient, grams: Double) -> DisplayAmount {
        let mode = ingredient.displayMode ?? .weight
        switch mode {
        case .pcs:
            if let gramsPerCount = ingredient.gramsPerCount, gramsPerCount > 0 {
                let count = max(0.25, (grams / gramsPerCount).rounded(toNearest: 0.25))
                return DisplayAmount(value: formatNumber(count), unit: "pcs")
            }
            return metricWeightAmount(grams)
        case .liquid, .spoon:
            if let gramsPerMl = ingredient.gramsPerMl, gramsPerMl > 0 {
                let ml = grams / gramsPerMl
                if ml >= 1000 {
                    return DisplayAmount(value: formatNumber(ml / 1000), unit: "l")
                }
                return DisplayAmount(value: formatNumber(ml), unit: "ml")
            }
            return metricWeightAmount(grams)
        case .weight:
            return metricWeightAmount(grams)
        }
    }

    private static func nonMetricAmount(for ingredient: Ingredient, grams: Double, unit: MeasurementUnit) -> DisplayAmount {
        let mode = ingredient.displayMode ?? .weight
        switch mode {
        case .pcs:
            if let gramsPerCount = ingredient.gramsPerCount, gramsPerCount > 0 {
                let count = max(0.25, (grams / gramsPerCount).rounded(toNearest: 0.25))
                return DisplayAmount(value: formatNumber(count), unit: "pcs")
            }
            return DisplayAmount(value: formatNumber(grams), unit: "g")
        case .liquid:
            let gramsPerMl = ingredient.gramsPerMl ?? 1
            return volumeAmount(grams: grams, gramsPerMl: gramsPerMl, allowCup: ingredient.allowCup ?? false, unit: unit)
        case .spoon:
            let gramsPerTsp = ingredient.gramsPerTsp
                ?? ((ingredient.gramsPerMl ?? 1) * unit.teaspoonMilliliters)
            let ml = grams / max(gramsPerTsp / unit.teaspoonMilliliters, 0.001)
            return volumeAmount(grams: grams, gramsPerMl: grams / max(ml, 0.001), allowCup: ingredient.allowCup ?? false, unit: unit)
        case .weight:
            switch unit {
            case .us, .ukImp:
                return imperialWeightAmount(grams)
            case .metric, .auNz, .jp:
                return metricWeightAmount(grams)
            }
        }
    }

    private static func metricWeightAmount(_ grams: Double) -> DisplayAmount {
        DisplayAmount(value: formatNumber(grams), unit: "g")
    }

    private static func imperialWeightAmount(_ grams: Double) -> DisplayAmount {
        let ounces = grams / 28.349523125
        if ounces >= 16 {
            return DisplayAmount(value: formatNumber(ounces / 16), unit: "lb")
        }
        return DisplayAmount(value: formatNumber(ounces), unit: "oz")
    }

    private static func volumeAmount(grams: Double, gramsPerMl: Double, allowCup: Bool, unit: MeasurementUnit) -> DisplayAmount {
        let ml = grams / max(gramsPerMl, 0.001)
        let tsp = ml / unit.teaspoonMilliliters
        let tbsp = ml / unit.tablespoonMilliliters

        if allowCup, unit.cupMilliliters > 0 {
            let cups = ml / unit.cupMilliliters
            if cups >= 0.25 {
                let roundedCups = max(0.25, cups.rounded(toNearest: 0.25))
                return DisplayAmount(value: formatQuarterFraction(roundedCups), unit: "cup")
            }
        }

        if tbsp >= 1 {
            let roundedTbsp = max(1, tbsp.rounded(toNearest: 0.25))
            return DisplayAmount(value: formatQuarterFraction(roundedTbsp), unit: "tbsp")
        }

        let roundedTsp = max(0.25, tsp.rounded(toNearest: 0.25))
        return DisplayAmount(value: formatQuarterFraction(roundedTsp), unit: "tsp")
    }

    private static func scaledGrams(_ grams: Double, servings: Int, baseServings: Int) -> Double {
        grams * Double(servings) / Double(baseServings)
    }

    private static func formatNumber(_ value: Double) -> String {
        if value.rounded(.down) == value {
            return "\(Int(value))"
        }
        if value < 10 {
            return String(format: "%.1f", value)
        }
        return String(format: "%.0f", value)
    }

    private static func formatQuarterFraction(_ value: Double) -> String {
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
            return fractionText.isEmpty ? formatNumber(rounded) : fractionText
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
