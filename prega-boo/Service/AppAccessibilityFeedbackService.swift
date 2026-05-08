import AudioToolbox
import AVFoundation
import Foundation
import UIKit

@MainActor
final class AppAccessibilityFeedbackService {
    static let shared = AppAccessibilityFeedbackService()

    private let synth = AVSpeechSynthesizer()

    private init() {}

    func speak(_ text: String) {
        guard AppAccessibilitySettingsStore.shared.screenReaderEnabled else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if UIAccessibility.isVoiceOverRunning {
            UIAccessibility.post(notification: .announcement, argument: trimmed)
            return
        }

        if synth.isSpeaking {
            synth.stopSpeaking(at: .immediate)
        }

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 1.0
        synth.speak(utterance)
    }

    func playTap() {
        guard AppAccessibilitySettingsStore.shared.soundEffectsEnabled else { return }
        // iOS built-in keyboard tap sound.
        AudioServicesPlaySystemSound(1104)
    }

    func playSuccess() {
        guard AppAccessibilitySettingsStore.shared.soundEffectsEnabled else { return }
        // iOS built-in short success tone.
        AudioServicesPlaySystemSound(1110)
    }
}
