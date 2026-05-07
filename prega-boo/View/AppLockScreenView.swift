import SwiftUI

struct AppLockScreenView: View {
    let accentColor: Color

    @EnvironmentObject private var appLock: AppLockManager

    @State private var pin = ""
    @State private var errorShake = false
    @State private var isBiometricRunning = false
    @State private var didAttemptAutoBiometric = false

    private var bioTitle: String {
        BiometricAuthService.biometricTypeDescription()
    }

    private var hasPIN: Bool {
        PINAuthStore.shared.hasPIN
    }

    private var lockInstruction: String {
        switch (hasPIN, appLock.preferBiometricUnlock && BiometricAuthService.canUseBiometrics) {
        case (true, true):
            return "Use \(bioTitle.lowercased()) or enter your PIN."
        case (true, false):
            return "Enter your PIN to continue."
        case (false, true):
            return "Use \(bioTitle.lowercased()) to continue."
        case (false, false):
            return "App lock is unavailable right now."
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.18, green: 0.12, blue: 0.16),
                    Color(red: 0.94, green: 0.39, blue: 0.45).opacity(0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Image(systemName: "lock.circle.fill")
                    .font(.system(size: 56, weight: .bold))
                    .foregroundStyle(.white.opacity(0.95))
                    .padding(.top, 40)

                Text("Prega Boo is locked")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text(lockInstruction)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                if appLock.preferBiometricUnlock, BiometricAuthService.canUseBiometrics {
                    Button {
                        Task { await runBiometric() }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: BiometricAuthService.biometricSystemImageName())
                                .font(.system(size: 20, weight: .semibold))
                            Text("Unlock with \(bioTitle)")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 22)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                    .disabled(isBiometricRunning)
                }

                if hasPIN {
                    PINPadView(accentColor: .white, pin: $pin, maxDigits: 4) { entered in
                        if PINAuthStore.shared.verifyPIN(entered) {
                            appLock.unlock()
                            pin = ""
                        } else {
                            pin = ""
                            withAnimation(.default) { errorShake.toggle() }
                        }
                    }
                    .padding(.horizontal, 36)
                    .offset(x: errorShake ? 8 : 0)
                    .animation(.spring(response: 0.12, dampingFraction: 0.4), value: errorShake)
                }

                Spacer()
            }
        }
        .onAppear {
            // Auto-trigger Face ID / Touch ID once when the lock screen appears,
            // matching the iOS-native expectation (Apple Notes, Banking apps, etc.).
            // If the user cancels or fails, they can still use the PIN pad below.
            guard appLock.preferBiometricUnlock,
                  BiometricAuthService.canUseBiometrics,
                  !didAttemptAutoBiometric else { return }
            didAttemptAutoBiometric = true
            Task { await runBiometric() }
        }
    }

    private func runBiometric() async {
        isBiometricRunning = true
        defer { isBiometricRunning = false }
        let ok = await BiometricAuthService.authenticate(reason: "Unlock Prega Boo")
        if ok {
            appLock.unlock()
            pin = ""
        }
    }
}
