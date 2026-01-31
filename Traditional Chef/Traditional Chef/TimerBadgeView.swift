//
//  TimerBadgeView.swift
//  FamousChef
//

import SwiftUI

struct TimerBadgeView: View {
    let seconds: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 6) {
                Image(systemName: "timer")
                Text(label)
                    .monospacedDigit()
            }
            .font(.caption2.weight(.semibold))
            .foregroundStyle(AppTheme.primaryBlue)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppTheme.primaryBlue.opacity(0.08))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var label: String {
        let m = seconds / 60
        return "\(m)m"
    }
}
