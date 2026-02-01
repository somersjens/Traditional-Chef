//
//  TimerBadgeView.swift
//  FamousChef
//

import SwiftUI

struct TimerBadgeView: View {
    let displayText: String
    let isRunning: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Text(displayText)
                    .monospacedDigit()
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(AppTheme.primaryBlue)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppTheme.primaryBlue.opacity(isRunning ? 0.16 : 0.08))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
