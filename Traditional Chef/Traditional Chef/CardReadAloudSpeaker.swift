import Foundation
import AVFoundation
import Combine

final class CardReadAloudSpeaker: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published private(set) var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()
    private let audioSession = AVAudioSession.sharedInstance()

    override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
    }

    func toggleRead(text: String, languageCode: String) {
        if isSpeaking {
            stop()
            return
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        activateAudioSession()
        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = AVSpeechSynthesisVoice(language: languageCode) ?? AVSpeechSynthesisVoice(language: String(languageCode.prefix(2)))
        utterance.rate = 0.46
        utterance.pitchMultiplier = 0.95
        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        guard synthesizer.isSpeaking || synthesizer.isPaused else { return }
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        isSpeaking = false
    }

    func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        isSpeaking = false
    }

    private func configureAudioSession() {
        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.duckOthers])
        } catch {
            assertionFailure("Failed to configure card read-aloud audio session: \(error.localizedDescription)")
        }
    }

    private func activateAudioSession() {
        do {
            try audioSession.setActive(true, options: [.notifyOthersOnDeactivation])
        } catch {
            assertionFailure("Failed to activate card read-aloud audio session: \(error.localizedDescription)")
        }
    }
}

func localizedAndWord(for locale: Locale) -> String {
    locale.identifier.lowercased().hasPrefix("nl") ? "en" : "and"
}

func joinedForSpeech(_ items: [String], locale: Locale) -> String {
    let cleaned = items.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
    guard !cleaned.isEmpty else { return "" }
    if cleaned.count == 1 { return cleaned[0] }
    if cleaned.count == 2 {
        return "\(cleaned[0]) \(localizedAndWord(for: locale)) \(cleaned[1])"
    }
    let head = cleaned.dropLast().joined(separator: ", ")
    return "\(head), \(localizedAndWord(for: locale)) \(cleaned.last!)"
}
