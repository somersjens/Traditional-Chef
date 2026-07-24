//
//  WelcomeView.swift
//  FamousChef
//

import SwiftUI

struct WelcomeView: View {
    private let welcomeBackgroundColor = Color(hex: "FAF5F0")
    private let welcomeTextColor = Color(hex: "1C263C")
    private let welcomeButtonTextColor = Color(hex: "FAF5F0")

    @AppStorage("hasSeenWelcome") private var hasSeenWelcome: Bool = false
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @State private var currentFrameName: String = "11"
    private var locale: Locale { Locale(identifier: appLanguage) }
    private var isCompactHeight: Bool { verticalSizeClass == .compact }
    private var welcomeSpacing: CGFloat { AppTheme.scaled(isCompactHeight ? 8 : 18) }
    private var sponsorMessage: AttributedString {
        var message = AttributedString(AppLanguage.string("welcome.sponsorMessage", locale: locale))
        if let range = message.range(of: "Hakketjak") {
            message[range].link = URL(string: "https://www.hakketjak.nl")
            message[range].font = AppTheme.systemFont(size: 17, weight: .bold)
            message[range].underlineStyle = .single
            message[range].foregroundColor = welcomeTextColor
        }
        return message
    }

    var body: some View {
        GeometryReader { proxy in
            ZStack {
                welcomeBackgroundColor.ignoresSafeArea()

                VStack(spacing: welcomeSpacing) {
                    Spacer(minLength: AppTheme.scaled(isCompactHeight ? 8 : 18))

                    animationStage(in: proxy)

                    VStack(spacing: AppTheme.scaled(isCompactHeight ? 8 : 14)) {
                        Text(AppLanguage.string("welcome.greeting", locale: locale))
                            .font(AppTheme.systemFont(size: 33, weight: .semibold))
                            .foregroundStyle(welcomeTextColor)
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)

                        Button {
                            hasSeenWelcome = true
                        } label: {
                            Text(AppLanguage.string("welcome.startButton", locale: locale))
                                .font(AppTheme.systemFont(size: 19, weight: .medium))
                                .padding(.vertical, AppTheme.scaled(14))
                                .padding(.horizontal, AppTheme.scaled(24))
                                .background(Color(hex: "F57921"))
                                .foregroundStyle(welcomeButtonTextColor)
                                .clipShape(RoundedRectangle(cornerRadius: AppTheme.scaled(26)))
                        }
                        .padding(.horizontal, AppTheme.scaled(22))
                        .padding(.top, AppTheme.scaled(isCompactHeight ? 0 : 6))

                        Text(sponsorMessage)
                            .font(AppTheme.systemFont(size: 17, weight: .medium))
                            .foregroundStyle(welcomeTextColor.opacity(0.85))
                            .multilineTextAlignment(.center)
                            .lineSpacing(AppTheme.scaled(1.8))
                            .padding(.horizontal, AppTheme.scaled(22))
                    }
                    .frame(maxWidth: AppTheme.scaled(360))
                    .frame(maxWidth: .infinity, alignment: .center)

                    Spacer(minLength: AppTheme.scaled(isCompactHeight ? 8 : 24))
                }
                .padding(.horizontal, AppTheme.scaled(24) + proxy.safeAreaInsets.leading + proxy.safeAreaInsets.trailing)
                .frame(width: proxy.size.width, height: proxy.size.height, alignment: .center)
            }
        }
        .task {
            await runAnimationLoop()
        }
    }

    private func animationStage(in proxy: GeometryProxy) -> some View {
        let availableWidth = max(proxy.size.width - AppTheme.scaled(48), 1)
        let maxStageWidth = min(availableWidth, AppTheme.scaled(isCompactHeight ? 360 : 390))
        let maxStageHeight = min(proxy.size.height * (isCompactHeight ? 0.48 : 0.56), AppTheme.scaled(isCompactHeight ? 240 : 390))

        return ZStack {
            Image(currentFrameName)
                .resizable()
                .scaledToFit()
                .frame(width: maxStageWidth, height: maxStageHeight)
                .clipped()
                .accessibilityHidden(true)
        }
        .frame(width: maxStageWidth, height: maxStageHeight)
        .clipped()
        .contentShape(Rectangle())
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
