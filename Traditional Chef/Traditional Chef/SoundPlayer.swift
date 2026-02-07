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

    static func startContinuousBeep(interval: TimeInterval = 0.35) -> UUID {
        let soundID: SystemSoundID = 1005
        let id = UUID()
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            AudioServicesPlaySystemSound(soundID)
        }
        activeTimers[id] = timer
        return id
    }

    static func stopBeep(id: UUID?) {
        guard let id, let timer = activeTimers[id] else { return }
        timer.invalidate()
        activeTimers[id] = nil
    }

    private static var activeTimers: [UUID: Timer] = [:]
}
