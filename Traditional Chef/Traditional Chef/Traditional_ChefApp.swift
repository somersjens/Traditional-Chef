//
//  Traditional_ChefApp.swift
//  Traditional Chef
//
//  Created by Jens Somers on 28/01/2026.
//

import SwiftUI

@main
struct Traditional_ChefApp: App {
    @StateObject private var recipeStore = RecipeStore()
    @StateObject private var tipStore = TipStore()
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(recipeStore)
                .environmentObject(tipStore)
                .environment(\.locale, Locale(identifier: appLanguage))
        }
    }
}
