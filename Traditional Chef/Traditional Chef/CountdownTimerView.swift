//
//  CountdownTimerView.swift
//  FamousChef
//

import Combine
import SwiftUI

struct CountdownTimerView: View {
    let initialSeconds: Int
    let liveSeconds: Int
    let isRunning: Bool
    let onReset: () -> Void
    let onPauseToggle: () -> Void
    let onOverride: (Int) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @AppStorage("appLanguage") private var appLanguage: String = AppLanguage.defaultCode()
    private var locale: Locale { Locale(identifier: appLanguage) }

    @State private var overrideMinutesText: String = ""
    @State private var overrideSecondsText: String = ""

    private var isCompactHeight: Bool { verticalSizeClass == .compact }
    private var controlWidth: CGFloat { isCompactHeight ? 108 : 120 }
    private var controlsRowSpacing: CGFloat { isCompactHeight ? 12 : 18 }
    private var controlsTopPadding: CGFloat { isCompactHeight ? 12 : 18 }
    private let controlsRowGap: CGFloat = 0 // jens: adjust to taste
    private var checkmarkTrailingInset: CGFloat { isCompactHeight ? 12 : 25 }
    private var timerSize: CGFloat { isCompactHeight ? 210 : 260 }

    init(initialSeconds: Int, liveSeconds: Int, isRunning: Bool, onReset: @escaping () -> Void, onPauseToggle: @escaping () -> Void, onOverride: @escaping (Int) -> Void) {
        self.initialSeconds = initialSeconds
        self.liveSeconds = liveSeconds
        self.isRunning = isRunning
        self.onReset = onReset
        self.onPauseToggle = onPauseToggle
        self.onOverride = onOverride
    }

    var body: some View {
        NavigationStack {
            Group {
                if isCompactHeight {
                    ScrollView(showsIndicators: false) {
                        timerContent
                            .padding(.vertical, 12)
                    }
                } else {
                    VStack(spacing: 18) {
                        Spacer()
                        timerContent
                        Spacer()
                    }
                }
            }
            .background(AppTheme.pageBackground.ignoresSafeArea())
            .navigationTitle(Text(AppLanguage.string("timer.title", locale: locale)))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(AppLanguage.string("done", locale: locale)) {
                        applyOverrideIfNeeded()
                        dismiss()
                    }
                }
            }
        }
        .onDisappear {
            applyOverrideIfNeeded()
        }
    }

    private var timerContent: some View {
        VStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(AppTheme.primaryBlue.opacity(0.12), lineWidth: 18)

                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(timerColor, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 6) {
                    Text(timeText)
                        .font(.system(size: isCompactHeight ? 38 : 44, weight: .bold))
                        .monospacedDigit()
                        .foregroundStyle(timerColor)

                    Text(AppLanguage.string(isFinished ? "timer.finished" : "timer.remaining", locale: locale))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(timerColor.opacity(0.75))
                }
            }
            .frame(width: timerSize, height: timerSize)
            .padding(.horizontal, 20)

            HStack(spacing: controlsRowSpacing) {
                Button {
                    onReset()
                } label: {
                    Text(AppLanguage.string("timer.reset", locale: locale))
                        .frame(width: controlWidth)
                        .padding(.vertical, 14)
                        .background(AppTheme.primaryBlue.opacity(0.10))
                        .foregroundStyle(AppTheme.primaryBlue)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    onPauseToggle()
                } label: {
                    Text(AppLanguage.string(isRunning ? "timer.pause" : "timer.start", locale: locale))
                        .frame(width: controlWidth)
                        .padding(.vertical, 14)
                        .background(AppTheme.primaryBlue)
                        .foregroundStyle(AppTheme.secondaryOffWhite)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, controlsTopPadding)
            .padding(.bottom, controlsRowGap)

            ZStack {
                ZStack {
                    HStack(spacing: controlsRowSpacing) {
                        TextField("Minutes", text: $overrideMinutesText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 10)
                            .frame(width: controlWidth)
                            .background(AppTheme.primaryBlue.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))

                        TextField("Seconds", text: $overrideSecondsText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.center)
                            .padding(.vertical, 10)
                            .frame(width: controlWidth)
                            .background(AppTheme.primaryBlue.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    Text(":")
                        .font(.title3.weight(.semibold))
                        .foregroundStyle(AppTheme.primaryBlue.opacity(0.7))
                }
                .frame(width: (controlWidth * 2) + 10)

                HStack {
                    Spacer()

                    Button {
                        applyOverrideIfNeeded()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(AppTheme.primaryBlue)
                    }
                    .padding(.trailing, checkmarkTrailingInset)
                    .accessibilityLabel(Text("Apply override"))
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var isFinished: Bool {
        liveSeconds <= 0
    }

    private var progress: CGFloat {
        if initialSeconds <= 0 { return 0 }
        let elapsed = initialSeconds - max(liveSeconds, 0)
        return CGFloat(elapsed) / CGFloat(initialSeconds)
    }

    private var timerColor: Color {
        liveSeconds < 0 ? AppTheme.timerOverdue : AppTheme.primaryBlue
    }

    private var timeText: String {
        if liveSeconds >= 0 {
            let m = liveSeconds / 60
            let s = liveSeconds % 60
            return String(format: "%d:%02d", m, s)
        } else {
            // show negative overtime
            let over = abs(liveSeconds)
            let m = over / 60
            let s = over % 60
            return String(format: "-%d:%02d", m, s)
        }
    }

    private func applyOverrideIfNeeded() {
        let minutes = Int(overrideMinutesText) ?? 0
        let seconds = Int(overrideSecondsText) ?? 0
        let totalSeconds = (minutes * 60) + seconds

        if totalSeconds > 0 {
            onOverride(totalSeconds)
            overrideMinutesText = ""
            overrideSecondsText = ""
        }
    }
}
