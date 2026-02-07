//  python3 recipe_import/csv_to_app_data.py
//  ContentView.swift
//  Traditional Chef
//

import SwiftUI

struct ContentView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()

    var body: some View {
        Group {
            if hasSeenWelcome {
                RecipeListView()
            } else {
                WelcomeView()
            }
        }
        .environment(\.locale, Locale(identifier: appLanguage))
    }
}

#Preview {
    ContentView()
        .environmentObject(RecipeStore())
        .environmentObject(TipStore())
}
