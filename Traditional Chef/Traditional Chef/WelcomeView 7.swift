//
//  WelcomeView.swift
//  FamousChef
//

import SwiftUI
import StoreKit

struct WelcomeView: View {
    @EnvironmentObject private var tipStore: TipStore
    @Environment(\.locale) private var locale
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false

    @State private var showAlert: Bool = false
    @State private var alertMessage: String = ""

    var body: some View {
        ZStack {
            AppTheme.pageBackground.ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer()

                // App icon placeholder (use your Assets AppIcon)
                Image(systemName: "fork.knife.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 120, height: 120)
                    .foregroundStyle(AppTheme.primaryBlue)

                Text("welcome.title")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(AppTheme.textPrimary)

                Text("welcome.body")
                    .font(.body)
                    .foregroundStyle(AppTheme.textPrimary.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 26)

                VStack(spacing: 12) {
                    TipButtonsRow(
                        onTip: { productID in
                            Task { await buyTip(productID: productID) }
                        }
                    )

                    Button {
                        hasSeenWelcome = true
                    } label: {
                        Text("welcome.startButton")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.primaryBlue)
                            .foregroundStyle(AppTheme.secondaryOffWhite)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 6)
                }

                Spacer()
                Spacer()
            }
        }
        .task { await tipStore.loadProducts() }
        .alert("welcome.alertTitle", isPresented: $showAlert) {
            Button("ok", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func buyTip(productID: String) async {
        guard let product = tipStore.product(for: productID) else {
            alertMessage = AppLanguage.string("tip.notConfigured", locale: locale)
            showAlert = true
            return
        }
        let success = await tipStore.buy(product)
        if success {
            alertMessage = AppLanguage.string("tip.thanks", locale: locale)
        } else if let msg = tipStore.lastErrorMessage {
            alertMessage = msg
        } else {
            alertMessage = AppLanguage.string("tip.cancelled", locale: locale)
        }
        showAlert = true
    }
}

private struct TipButtonsRow: View {
    let onTip: (String) -> Void

    var body: some View {
        HStack(spacing: 16) {
            TipCircleButton(title: "€1") { onTip("tip_1") }
            TipCircleButton(title: "€2") { onTip("tip_2") }
            TipCircleButton(title: "€5") { onTip("tip_5") }
        }
        .padding(.top, 6)
    }
}

private struct TipCircleButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(AppTheme.primaryBlue)
                .frame(width: 64, height: 64)
                .background(AppTheme.secondaryOffWhite)
                .overlay(
                    Circle().stroke(AppTheme.primaryBlue.opacity(0.35), lineWidth: 2)
                )
                .clipShape(Circle())
                .shadow(radius: 2, y: 1)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("Tip \(title)"))
    }
}
