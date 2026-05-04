import SwiftUI

struct AppLockScreenView: View {
    let accentColor: Color

    @EnvironmentObject private var appLock: AppLockManager

    @State private var pin = ""
    @State private var errorShake = false
    @State private var isBiometricRunning = false

    private var bioTitle: String {
        BiometricAuthService.biometricTypeDescription()
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

                Text("Enter your PIN or use \(bioTitle.lowercased()) if enabled.")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)

                if appLock.preferBiometricUnlock, BiometricAuthService.canUseBiometrics {
                    Button {
                        Task { await runBiometric() }
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "faceid")
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

                Spacer()
            }
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
