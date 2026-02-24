import SwiftUI

enum DifficultyColor {
    private static let p: [Color] = [
        .init(red: 244/255, green: 223/255, blue: 220/255), // #F4DFDC (1)
        .init(red: 234/255, green: 191/255, blue: 185/255), // #EABFB9 (2)
        .init(red: 225/255, green: 159/255, blue: 151/255), // #E19F97 (3)
        .init(red: 215/255, green: 128/255, blue: 118/255), // #D78076 (4)
        .init(red: 190/255, green: 96/255,  blue: 87/255)   // #BE6057 (5) darker
    ]

    static func color(for difficulty: Int) -> Color {
        p[min(max(difficulty, 1), 5) - 1]
    }
}
