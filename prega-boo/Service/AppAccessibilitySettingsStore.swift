import Combine
import Foundation
import UIKit

@MainActor
final class AppAccessibilitySettingsStore: ObservableObject {
    static let shared = AppAccessibilitySettingsStore()

    @Published var screenReaderEnabled: Bool {
        didSet { UserDefaults.standard.set(screenReaderEnabled, forKey: Keys.screenReaderEnabled) }
    }

    @Published var soundEffectsEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEffectsEnabled, forKey: Keys.soundEffectsEnabled) }
    }

    @Published var dynamicTextEnabled: Bool {
        didSet { UserDefaults.standard.set(dynamicTextEnabled, forKey: Keys.dynamicTextEnabled) }
    }

    private enum Keys {
        static let screenReaderEnabled = "accessibility.screenReaderEnabled"
        static let soundEffectsEnabled = "accessibility.soundEffectsEnabled"
        static let dynamicTextEnabled = "accessibility.dynamicTextEnabled"
    }

    private init() {
        let defaults = UserDefaults.standard
        screenReaderEnabled = defaults.object(forKey: Keys.screenReaderEnabled) as? Bool ?? false
        soundEffectsEnabled = defaults.object(forKey: Keys.soundEffectsEnabled) as? Bool ?? true
        dynamicTextEnabled = defaults.object(forKey: Keys.dynamicTextEnabled) as? Bool ?? true
    }

    /// Optional helper for future use (announces only when both VoiceOver and
    /// in-app screen-reader support are enabled).
    func announce(_ message: String) {
        guard screenReaderEnabled, UIAccessibility.isVoiceOverRunning else { return }
        UIAccessibility.post(notification: .announcement, argument: message)
    }
}
