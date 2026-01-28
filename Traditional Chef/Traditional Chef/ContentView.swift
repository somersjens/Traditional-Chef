//
//  ContentView.swift
//  Traditional Chef
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false

    var body: some View {
        Group {
            if hasSeenWelcome {
                RecipeListView()
            } else {
                WelcomeView()
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(RecipeStore())
        .environmentObject(TipStore())
}
