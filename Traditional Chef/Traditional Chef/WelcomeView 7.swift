//
//  WelcomeView.swift
//  FamousChef
//

import SwiftUI

struct WelcomeView: View {
    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var currentFrameName: String = "11"
    private var locale: Locale { Locale(identifier: appLanguage) }
    private var sponsorMessage: AttributedString {
        var message = AttributedString(AppLanguage.string("welcome.sponsorMessage", locale: locale))
        if let range = message.range(of: "Hakketjak") {
            message[range].link = URL(string: "https://www.hakketjak.nl")
            message[range].font = .system(size: 17, weight: .bold)
            message[range].underlineStyle = .single
            message[range].foregroundColor = AppTheme.textPrimary
        }
        return message
    }

    var body: some View {
        ZStack {
            AppTheme.pageBackground.ignoresSafeArea()

            VStack(spacing: verticalSizeClass == .compact ? 4 : 7) {
                Image(currentFrameName)
                    .resizable()
                    .scaledToFit()
                    .frame(
                        maxWidth: 690,
                        maxHeight: verticalSizeClass == .compact ? 360 : 690
                    )
                    .accessibilityHidden(true)
                    .padding(.bottom, verticalSizeClass == .compact ? 0 : 3)

                VStack(spacing: verticalSizeClass == .compact ? 8 : 14) {
                    Text(AppLanguage.string("welcome.greeting", locale: locale))
                        .font(.system(size: 33, weight: .semibold))
                        .foregroundStyle(AppTheme.textPrimary)

                    Button {
                        hasSeenWelcome = true
                    } label: {
                        Text(AppLanguage.string("welcome.startButton", locale: locale))
                            .font(.system(size: 19, weight: .medium))
                            .padding(.vertical, 14)
                            .padding(.horizontal, 24)
                            .background(Color(hex: "F57921"))
                            .foregroundStyle(AppTheme.secondaryOffWhite)
                            .clipShape(RoundedRectangle(cornerRadius: 26))
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, verticalSizeClass == .compact ? 0 : 6)

                    Text(sponsorMessage)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(AppTheme.textPrimary.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .lineSpacing(1.8)
                        .padding(.horizontal, 22)
                }
                .offset(y: verticalSizeClass == .compact ? -40 : -180)

                Spacer(minLength: verticalSizeClass == .compact ? 0 : 12)
            }
            .padding(.top, 8)
        }
        .task {
            await runAnimationLoop()
        }
    }
}

private extension WelcomeView {
    func runAnimationLoop() async {
        let frameDuration = 0.04
        let forwardFrames = (1...9).map { (name: String($0), duration: frameDuration) }
        let reverseFrames = (1...9).reversed().map { (name: String($0), duration: frameDuration) }
        let sequence: [(name: String, duration: Double)] = [
            (name: "11", duration: 1.0)
        ]
        + forwardFrames
        + [(name: "9", duration: 0.5)]
        + [(name: "10", duration: 0.25)]
        + [(name: "9", duration: 0.5)]
        + reverseFrames
        + [(name: "11", duration: 0.5)]

        while !Task.isCancelled {
            for frame in sequence {
                currentFrameName = frame.name
                let nanos = UInt64(frame.duration * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanos)
                if Task.isCancelled { return }
            }
        }
    }
}
