//
//  TimerBadgeView.swift
//  FamousChef
//

import SwiftUI

struct TimerBadgeView: View {
    let displayText: String
    let widthReferenceText: String
    let isRunning: Bool
    let isOverdue: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                ZStack {
                    Text(widthReferenceText)
                        .monospacedDigit()
                        .lineLimit(1)
                        .opacity(0)
                        .accessibilityHidden(true)
                    Text(displayText)
                        .monospacedDigit()
                        .lineLimit(1)
                }
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(badgeForeground)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(badgeBackground)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var badgeForeground: Color {
        if isOverdue {
            return AppTheme.timerOverdue
        }

        return isRunning ? AppTheme.timerActiveGreen : AppTheme.primaryBlue
    }

    private var badgeBackground: Color {
        if isOverdue {
            return AppTheme.timerOverdue.opacity(0.12)
        }

        return isRunning ? AppTheme.timerActiveGreenBackground : AppTheme.primaryBlue.opacity(0.08)
    }
}
