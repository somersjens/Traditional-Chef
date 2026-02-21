import Foundation
import AVFoundation

enum ReadVoicePreference: String, CaseIterable, Identifiable {
    case male
    case female
    case none

    var id: String { rawValue }

    var settingsLabelKey: String {
        switch self {
        case .male:
            return "settings.readVoice.male"
        case .female:
            return "settings.readVoice.female"
        case .none:
            return "settings.readVoice.none"
        }
    }

    static let appStorageKey = "readVoicePreference"

    static var defaultValue: ReadVoicePreference { .male }

    static func resolved(from rawValue: String) -> ReadVoicePreference {
        ReadVoicePreference(rawValue: rawValue) ?? defaultValue
    }
}

struct ReadVoiceResolver {
    private let availableVoices: [AVSpeechSynthesisVoice]

    init(availableVoices: [AVSpeechSynthesisVoice] = AVSpeechSynthesisVoice.speechVoices()) {
        self.availableVoices = availableVoices
    }

    func preferredVoice(for languageCode: String, preference: ReadVoicePreference) -> AVSpeechSynthesisVoice? {
        guard preference != .none else { return nil }
        let baseCode = baseLanguageCode(for: languageCode)
        let candidates = availableVoices.filter { baseLanguageCode(for: $0.language) == baseCode }

        let preferredNameCandidates = preferredNames(for: baseCode, preference: preference)
        if let preferred = bestVoice(from: candidates.filter({ voice in
            preferredNameCandidates.contains(where: { voice.name.localizedCaseInsensitiveContains($0) })
        })) {
            return preferred
        }

        if let fallbackCandidate = bestVoice(from: candidates) {
            return fallbackCandidate
        }

        return AVSpeechSynthesisVoice(language: languageCode) ?? AVSpeechSynthesisVoice(language: baseCode)
    }

    private func preferredNames(for language: String, preference: ReadVoicePreference) -> [String] {
        let maleNames: [String: [String]] = [
            "en": ["Daniel", "Alex", "Arthur", "Aaron", "Nathan", "Tom"],
            "nl": ["Xander", "Daan"],
            "fr": ["Thomas"],
            "de": ["Markus", "Yannick"]
        ]

        let femaleNames: [String: [String]] = [
            "en": ["Samantha", "Ava", "Allison", "Karen", "Moira", "Tessa"],
            "nl": ["Ellen", "Sara", "Claire"],
            "fr": ["Amélie", "Audrey", "Marie"],
            "de": ["Anna", "Petra", "Helena"]
        ]

        switch preference {
        case .male:
            return maleNames[language] ?? []
        case .female:
            return femaleNames[language] ?? []
        case .none:
            return []
        }
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
}
