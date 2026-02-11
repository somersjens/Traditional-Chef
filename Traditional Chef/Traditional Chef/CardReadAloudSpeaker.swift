import Foundation
import AVFoundation
import Combine

extension Notification.Name {
    static let readAloudDidStart = Notification.Name("readAloudDidStart")
}

final class CardReadAloudSpeaker: NSObject, ObservableObject, AVSpeechSynthesizerDelegate {
    @Published private(set) var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()
    private let audioSession = AVAudioSession.sharedInstance()
    private let speakerID = UUID().uuidString
    private lazy var availableVoices: [AVSpeechSynthesisVoice] = AVSpeechSynthesisVoice.speechVoices()
    private lazy var preferredVoicesByLanguage: [String: AVSpeechSynthesisVoice] = buildPreferredVoices()

    override init() {
        super.init()
        synthesizer.delegate = self
        configureAudioSession()
        warmUpVoiceSelection()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleExternalReadAloudStart(_:)),
            name: .readAloudDidStart,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func toggleRead(text: String, languageCode: String) {
        if isSpeaking {
            stop()
            return
        }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        activateAudioSession()
        notifyReadAloudStart()
        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = preferredVoice(for: languageCode)
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
            try audioSession.setCategory(.playback, mode: .spokenAudio, options: [.mixWithOthers])
        } catch {
            assertionFailure("Failed to configure card read-aloud audio session: \(error.localizedDescription)")
        }
    }

    private func activateAudioSession() {
        do {
            try audioSession.setActive(true, options: [])
        } catch {
            assertionFailure("Failed to activate card read-aloud audio session: \(error.localizedDescription)")
        }
    }

    private func warmUpVoiceSelection() {
        _ = preferredVoicesByLanguage
    }

    private func preferredVoice(for languageCode: String) -> AVSpeechSynthesisVoice? {
        let baseCode = baseLanguageCode(for: languageCode)
        if let cached = preferredVoicesByLanguage[baseCode] {
            return cached
        }
        if let fallback = AVSpeechSynthesisVoice(language: languageCode) {
            return fallback
        }
        return AVSpeechSynthesisVoice(language: baseCode)
    }

    private func buildPreferredVoices() -> [String: AVSpeechSynthesisVoice] {
        let preferredMaleNamesByLanguage: [String: [String]] = [
            "en": ["Daniel", "Alex", "Arthur", "Aaron", "Nathan", "Tom"],
            "nl": ["Xander", "Daan"]
        ]

        var selected: [String: AVSpeechSynthesisVoice] = [:]

        for (language, names) in preferredMaleNamesByLanguage {
            let candidates = availableVoices.filter { baseLanguageCode(for: $0.language) == language }
            let maleCandidates = candidates.filter { voice in
                names.contains(where: { maleName in
                    voice.name.localizedCaseInsensitiveContains(maleName)
                })
            }

            if let voice = bestVoice(from: maleCandidates) ?? bestVoice(from: candidates) {
                selected[language] = voice
            }
        }

        return selected
    }

    private func bestVoice(from voices: [AVSpeechSynthesisVoice]) -> AVSpeechSynthesisVoice? {
        voices.max(by: { voiceRank($0.quality) < voiceRank($1.quality) })
    }

    private func voiceRank(_ quality: AVSpeechSynthesisVoiceQuality) -> Int {
        switch quality {
        case .premium:
            return 3
        case .enhanced:
            return 2
        default:
            return 1
        }
    }

    private func baseLanguageCode(for languageCode: String) -> String {
        languageCode
            .split(whereSeparator: { $0 == "_" || $0 == "-" })
            .first
            .map(String.init) ?? languageCode
    }

    private func notifyReadAloudStart() {
        NotificationCenter.default.post(name: .readAloudDidStart, object: speakerID)
    }

    @objc
    private func handleExternalReadAloudStart(_ notification: Notification) {
        guard let sourceSpeakerID = notification.object as? String, sourceSpeakerID != speakerID else { return }
        stop()
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
