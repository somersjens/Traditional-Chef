//
//  SoundPlayer.swift
//  FamousChef
//

import Foundation
import AudioToolbox

enum SoundPlayer {
    /// Plays a system sound repeatedly for a short burst (no custom audio files needed).
    static func playBeepBurst(durationSeconds: Double, completion: @escaping () -> Void) {
        let soundID: SystemSoundID = 1005 // “new-mail” style beep; safe fallback
        let interval: TimeInterval = 0.35
        let repeats = max(1, Int(durationSeconds / interval))

        var count = 0
        Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { timer in
            AudioServicesPlaySystemSound(soundID)
            count += 1
            if count >= repeats {
                timer.invalidate()
                completion()
            }
        }
    }
}
