//
//  SoundPlayer.swift
//  FamousChef
//

import Foundation
import AVFoundation

enum SoundPlayer {
    /// Plays the bundled `tring.wav` once.
    static func playBeepBurst(durationSeconds: Double, completion: @escaping () -> Void) {
        _ = durationSeconds // keep signature stable for existing callsites
        guard let player = makeTringPlayer(loop: false) else {
            completion()
            return
        }

        oneShotPlayer = player
        player.play()

        DispatchQueue.main.asyncAfter(deadline: .now() + max(0.01, player.duration)) {
            if oneShotPlayer === player {
                oneShotPlayer = nil
            }
            completion()
        }
    }

    static func startContinuousBeep(interval: TimeInterval = 0.35) -> UUID {
        _ = interval // looping is controlled by AVAudioPlayer
        let id = UUID()
        guard let player = makeTringPlayer(loop: true) else {
            return id
        }
        activePlayers[id] = player
        player.play()
        return id
    }

    static func stopBeep(id: UUID?) {
        guard let id, let player = activePlayers[id] else { return }
        player.stop()
        player.currentTime = 0
        activePlayers[id] = nil
    }

    private static func makeTringPlayer(loop: Bool) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: "tring", withExtension: "wav") else {
            assertionFailure("Missing tring.wav in app bundle")
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.numberOfLoops = loop ? -1 : 0
            player.prepareToPlay()
            return player
        } catch {
            assertionFailure("Failed to load tring.wav: \(error.localizedDescription)")
            return nil
        }
    }

    private static var activePlayers: [UUID: AVAudioPlayer] = [:]
    private static var oneShotPlayer: AVAudioPlayer?
}
