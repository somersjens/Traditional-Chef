import SwiftUI

enum DifficultyColor {
    static func color(for difficulty: Int) -> Color {
        switch difficulty {
        case 1:
            return Color(red: 0.20, green: 0.72, blue: 0.36)
        case 2:
            return Color(red: 0.56, green: 0.87, blue: 0.55)
        case 3:
            return Color(red: 0.95, green: 0.77, blue: 0.27)
        case 4:
            return Color(red: 0.94, green: 0.52, blue: 0.50)
        case 5:
            return Color(red: 0.83, green: 0.25, blue: 0.24)
        default:
            return AppTheme.primaryBlue.opacity(0.25)
        }
    }
}
