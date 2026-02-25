//
//  AppTheme.swift
//  Traditional Chef
//

import SwiftUI
import UIKit

enum AppTheme {
    static let lightPrimaryBlue = Color(hex: "1C263C")
    static let lightOffWhite = Color(hex: "FAF5F0")

    private static let darkPageBackground = Color(hex: "383A3D")
    private static let darkCardBackground = Color(hex: "434548")
    private static let darkForeground = lightOffWhite

    static let primaryBlue = dynamic(light: lightPrimaryBlue, dark: darkForeground)
    static let secondaryOffWhite = dynamic(light: lightOffWhite, dark: darkCardBackground)
    static let pageBackground = dynamic(light: lightOffWhite, dark: darkPageBackground)
    static let cardBackground = dynamic(light: Color(hex: "FEFCFB"), dark: darkCardBackground)
    static let settingsCardBackground = dynamic(light: lightPrimaryBlue, dark: lightOffWhite)
    static let settingsCardHeaderForeground = dynamic(light: lightOffWhite, dark: Color(hex: "383A3D"))
    static let searchBarBackground = dynamic(light: Color(hex: "FEFCFB"), dark: darkCardBackground)
    static let searchPlaceholder = dynamic(light: Color(hex: "5E6678"), dark: darkForeground.opacity(0.78))
    static let textPrimary = dynamic(light: lightPrimaryBlue, dark: darkForeground)
    static let searchHighlight = dynamic(light: lightPrimaryBlue, dark: darkForeground)
    static let hairline = dynamic(light: lightPrimaryBlue, dark: darkForeground.opacity(0.28))
    static let timerOverdue = Color(hex: "C5454F")
    static let timerActiveGreen = Color(hex: "1F7A3A")
    static let timerActiveGreenBackground = Color(hex: "DDF5E4")
}

private extension AppTheme {
    static func dynamic(light: Color, dark: Color) -> Color {
        Color(
            UIColor { traitCollection in
                traitCollection.userInterfaceStyle == .dark
                    ? UIColor(dark)
                    : UIColor(light)
            }
        )
    }
}
