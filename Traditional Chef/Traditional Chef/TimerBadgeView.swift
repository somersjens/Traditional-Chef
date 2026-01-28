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
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppTheme.primaryBlue)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
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
