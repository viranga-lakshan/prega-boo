import Combine
import Foundation

@MainActor
final class AppLockManager: ObservableObject {
    static let shared = AppLockManager()

    @Published var isLocked: Bool = false

    @Published var lockWhenLeavingApp: Bool {
        didSet { UserDefaults.standard.set(lockWhenLeavingApp, forKey: Keys.lockWhenLeaving) }
    }

    @Published var preferBiometricUnlock: Bool {
        didSet { UserDefaults.standard.set(preferBiometricUnlock, forKey: Keys.preferBio) }
    }

    private enum Keys {
        static let lockWhenLeaving = "appLock.lockWhenLeaving"
        static let preferBio = "appLock.preferBiometric"
    }

    private init() {
        lockWhenLeavingApp = UserDefaults.standard.bool(forKey: Keys.lockWhenLeaving)
        preferBiometricUnlock = UserDefaults.standard.bool(forKey: Keys.preferBio)
    }

    var isAppLockActive: Bool {
        PINAuthStore.shared.hasPIN && lockWhenLeavingApp
    }

    func sceneDidEnterBackground() {
        guard isAppLockActive else { return }
        isLocked = true
    }

    func unlock() {
        isLocked = false
    }

    func resetLockPreferences() {
        lockWhenLeavingApp = false
        preferBiometricUnlock = false
        isLocked = false
    }
}
