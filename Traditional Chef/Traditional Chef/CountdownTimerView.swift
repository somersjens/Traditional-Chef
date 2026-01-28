//
//  CountdownTimerView.swift
//  FamousChef
//

import Combine
import SwiftUI

struct CountdownTimerView: View {
    let initialSeconds: Int

    @Environment(\.dismiss) private var dismiss

    @State private var isRunning: Bool = false
    @State private var secondsLeft: Int
    @State private var startDate: Date? = nil

    @State private var beepTaskRunning: Bool = false

    private let tick = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    init(initialSeconds: Int) {
        self.initialSeconds = initialSeconds
        _secondsLeft = State(initialValue: initialSeconds)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Spacer()

                ZStack {
                    Circle()
                        .stroke(AppTheme.primaryBlue.opacity(0.12), lineWidth: 18)

                    Circle()
                        .trim(from: 0, to: progress)
                        .stroke(AppTheme.primaryBlue, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 6) {
                        Text(timeText)
                            .font(.system(size: 44, weight: .bold))
                            .monospacedDigit()
                            .foregroundStyle(AppTheme.primaryBlue)

                        Text(isFinished ? "timer.finished" : "timer.remaining")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(AppTheme.primaryBlue.opacity(0.75))
                    }
                }
                .frame(width: 260, height: 260)
                .padding(.horizontal, 20)

                HStack(spacing: 12) {
                    Button {
                        reset()
                    } label: {
                        Text("timer.reset")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.primaryBlue.opacity(0.10))
                            .foregroundStyle(AppTheme.primaryBlue)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }

                    Button {
                        toggleRun()
                    } label: {
                        Text(isRunning ? "timer.pause" : "timer.start")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(AppTheme.primaryBlue)
                            .foregroundStyle(AppTheme.secondaryOffWhite)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .background(AppTheme.pageBackground.ignoresSafeArea())
            .navigationTitle(Text("timer.title"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("done") { dismiss() }
                }
            }
            .onReceive(tick) { _ in
                guard isRunning else { return }

                secondsLeft -= 1

                if secondsLeft == 0 {
                    // finished at exact zero: ring 3 seconds, then stop
                    isRunning = false
                    ringForThreeSeconds()
                }
            }
        }
    }

    private var isFinished: Bool {
        secondsLeft <= 0
    }

    private var progress: CGFloat {
        if initialSeconds <= 0 { return 0 }
        let elapsed = initialSeconds - max(secondsLeft, 0)
        return CGFloat(elapsed) / CGFloat(initialSeconds)
    }

    private var timeText: String {
        if secondsLeft >= 0 {
            let m = secondsLeft / 60
            let s = secondsLeft % 60
            return String(format: "%d:%02d", m, s)
        } else {
            // show negative overtime
            let over = abs(secondsLeft)
            let m = over / 60
            let s = over % 60
            return String(format: "-%d:%02d", m, s)
        }
    }

    private func toggleRun() {
        isRunning.toggle()
        if isRunning {
            Haptics.light()
        }
    }

    private func reset() {
        isRunning = false
        secondsLeft = initialSeconds
        Haptics.light()
    }

    private func ringForThreeSeconds() {
        guard !beepTaskRunning else { return }
        beepTaskRunning = true
        Haptics.success()

        SoundPlayer.playBeepBurst(durationSeconds: 3.0) {
            beepTaskRunning = false
        }
    }
}
