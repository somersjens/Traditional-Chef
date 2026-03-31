import Foundation

enum TimeDisplayFormatter {
    private enum Unit {
        case minute
        case hour
        case day
    }

    static func columnText(minutes: Int, locale: Locale) -> String {
        let normalizedMinutes = max(0, minutes)
        let converted = convert(minutes: normalizedMinutes)
        return "\(formattedNumber(converted.value, locale: locale))\(columnUnit(for: converted.unit, locale: locale))"
    }

    static func summaryComponent(minutes: Int, locale: Locale) -> String {
        let normalizedMinutes = max(0, minutes)
        let converted = convert(minutes: normalizedMinutes)
        return "\(formattedNumber(converted.value, locale: locale)) \(summaryUnit(for: converted.unit, value: converted.value, locale: locale))"
    }

    static func summaryEquation(activeMinutes: Int, passiveMinutes: Int, totalMinutes: Int, locale: Locale) -> String {
        let active = summaryEquationComponent(minutes: activeMinutes, locale: locale)
        let passive = summaryEquationComponent(minutes: passiveMinutes, locale: locale)

        let total = max(0, totalMinutes)
        let convertedTotal = convert(minutes: total)
        let totalText = "\(formattedNumber(convertedTotal.value, locale: locale)) \(summaryUnit(for: convertedTotal.unit, value: convertedTotal.value, locale: locale))"
        let relation = (active.isApproximate || passive.isApproximate || isNonExactLargeAmount(minutes: total, unit: convertedTotal.unit)) ? "≈" : "="

        return "\(active.text) + \(passive.text) \(relation) \(totalText)"
    }

    static func countdownText(seconds: Int, locale: Locale) -> String {
        let minuteSecondCutoff = 99 * 60 + 59
        if abs(seconds) <= minuteSecondCutoff {
            if seconds >= 0 {
                let m = seconds / 60
                let s = seconds % 60
                return String(format: "%d:%02d", m, s)
            } else {
                let over = abs(seconds)
                let m = over / 60
                let s = over % 60
                return String(format: "-%d:%02d", m, s)
            }
        }

        let roundedMinutes = Int((Double(abs(seconds)) / 60).rounded())
        let converted = convert(minutes: roundedMinutes)
        let sign = seconds < 0 ? "-" : ""
        return "\(sign)\(formattedNumber(converted.value, locale: locale)) \(summaryUnit(for: converted.unit, value: converted.value, locale: locale))"
    }

    private static func convert(minutes: Int) -> (value: Double, unit: Unit) {
        if minutes <= 90 {
            return (Double(minutes), .minute)
        }

        if minutes < 24 * 60 {
            let roundedHalfHours = (Double(minutes) / 60 * 2).rounded() / 2
            return (roundedHalfHours, .hour)
        }

        let halfDaySteps = max(2, minutes / (12 * 60))
        return (Double(halfDaySteps) / 2, .day)
    }

    private static func formattedNumber(_ value: Double, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    private static func summaryEquationComponent(minutes: Int, locale: Locale) -> (text: String, isApproximate: Bool) {
        let normalizedMinutes = max(0, minutes)
        let converted = convert(minutes: normalizedMinutes)
        let isApproximate = converted.unit != .minute
        let prefix = isApproximate ? "~" : ""
        let componentText = "\(prefix)\(formattedNumber(converted.value, locale: locale)) \(summaryUnit(for: converted.unit, value: converted.value, locale: locale))"
        return (componentText, isApproximate)
    }

    private static func isNonExactLargeAmount(minutes: Int, unit: Unit) -> Bool {
        switch unit {
        case .minute:
            return false
        case .hour:
            return minutes % 30 != 0
        case .day:
            return minutes % (12 * 60) != 0
        }
    }

    private static func languageCode(for locale: Locale) -> String {
        if #available(iOS 16, *) {
            return locale.language.languageCode?.identifier ?? "en"
        }
        return locale.identifier
            .split(whereSeparator: { $0 == "_" || $0 == "-" })
            .first
            .map(String.init) ?? "en"
    }

    private static func columnUnit(for unit: Unit, locale: Locale) -> String {
        let languageCode = languageCode(for: locale)
        switch unit {
        case .minute:
            return "m"
        case .hour:
            return languageCode == "nl" ? "u" : "h"
        case .day:
            return "d"
        }
    }

    private static func summaryUnit(for unit: Unit, value: Double, locale: Locale) -> String {
        let languageCode = languageCode(for: locale)
        switch unit {
        case .minute:
            return languageCode == "de" ? "Min." : "min"
        case .hour:
            if languageCode == "nl" { return "uur" }
            if languageCode == "de" { return "Std." }
            if languageCode == "fr" { return "h" }
            return value == 1 ? "hr" : "hrs"
        case .day:
            if languageCode == "nl" { return value == 1 ? "dag" : "dagen" }
            if languageCode == "de" { return value == 1 ? "Tag" : "Tage" }
            if languageCode == "fr" { return value == 1 ? "jour" : "jours" }
            return value == 1 ? "day" : "days"
        }
    }
}
