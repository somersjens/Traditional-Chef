import SwiftUI

enum DifficultyColor {
    private static let p: [Color] = [
        .init(red: 87/255, green: 181/255, blue: 113/255), // green (1)
        .init(red: 163/255, green: 201/255, blue: 88/255), // yellow-green (2)
        .init(red: 242/255, green: 208/255, blue: 102/255), // yellow (3)
        .init(red: 234/255, green: 149/255, blue: 69/255), // orange (4)
        .init(red: 214/255, green: 84/255, blue: 84/255)   // red (5)
    ]

    static func color(for difficulty: Int) -> Color {
        p[min(max(difficulty, 1), 5) - 1]
    }
}
