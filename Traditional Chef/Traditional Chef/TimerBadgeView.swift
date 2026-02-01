//
//  TimerBadgeView.swift
//  FamousChef
//

import SwiftUI

struct TimerBadgeView: View {
    let displayText: String
    let isRunning: Bool
    let isOverdue: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(displayText)
                    .monospacedDigit()
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(isOverdue ? AppTheme.timerOverdue : AppTheme.primaryBlue)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeBackground)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var badgeBackground: Color {
        let base = isOverdue ? AppTheme.timerOverdue : AppTheme.primaryBlue
        return base.opacity(isRunning ? 0.16 : 0.08)
    }
}
