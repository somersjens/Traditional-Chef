import SwiftUI

enum DifficultyColor {
    private static let p: [Color] = [
        .init(red: 68/255,  green: 206/255, blue: 27/255),  // #44ce1b
        .init(red: 187/255, green: 219/255, blue: 68/255),  // #bbdb44
        .init(red: 247/255, green: 227/255, blue: 121/255), // #f7e379
        .init(red: 242/255, green: 161/255, blue: 52/255),  // #f2a134
        .init(red: 229/255, green: 31/255,  blue: 31/255)   // #e51f1f
    ]

    static func color(for difficulty: Int) -> Color {
        p[min(max(difficulty, 1), 5) - 1]
    }
}
