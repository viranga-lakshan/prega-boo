import SwiftUI

struct MomProfileView: View {
    let dashboardModel: MomDashboardModel
    let profileCopy: MomProfileDisplayModel

    @EnvironmentObject private var momSession: MomSessionStore
    @EnvironmentObject private var appLock: AppLockManager

    @State private var profile: MomProfile?
    @State private var isLoadingProfile = false
    @State private var profileError: String?

    @State private var showPINSetup = false
    @State private var showRemovePINConfirm = false
    @State private var showSignOutConfirm = false
    @State private var localAlert: String?
    @State private var securityUIRevision = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                headerBlock
                    .padding(.horizontal, 18)
                    .padding(.top, 12)

                personalCard
                    .padding(.horizontal, 18)

                securityCard
                    .id(securityUIRevision)
                    .padding(.horizontal, 18)

                signOutButton
                    .padding(.horizontal, 18)
                    .padding(.bottom, 28)
            }
        }
        .background(dashboardModel.backgroundColor)
        .task { await loadProfile() }
        .refreshable { await loadProfile() }
        .sheet(isPresented: $showPINSetup) {
            PINSetupSheetView(accentColor: dashboardModel.accentColor) {
                showPINSetup = false
                securityUIRevision += 1
            }
            .presentationDetents([.large])
        }
        .onChange(of: showPINSetup) { _, presented in
            if !presented { securityUIRevision += 1 }
        }
        .alert("Profile", isPresented: Binding(
            get: { localAlert != nil },
            set: { if !$0 { localAlert = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(localAlert ?? "")
        }
        .confirmationDialog("Remove PIN?", isPresented: $showRemovePINConfirm, titleVisibility: .visible) {
            Button("Remove PIN & turn off lock", role: .destructive) {
                PINAuthStore.shared.clearPIN()
                appLock.resetLockPreferences()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You will need to set a PIN again to use app lock.")
        }
        .confirmationDialog("Sign out?", isPresented: $showSignOutConfirm, titleVisibility: .visible) {
            Button("Sign out", role: .destructive) { signOut() }
            Button("Cancel", role: .cancel) {}
        }
    }

    private var headerBlock: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(dashboardModel.accentColor.opacity(0.2))
                    .frame(width: 88, height: 88)
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 52, weight: .medium))
                    .foregroundStyle(dashboardModel.accentColor)
            }
            Text(profileCopy.title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.78))
            Text(profileCopy.subtitle)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.45))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var personalCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(profileCopy.personalSectionTitle)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(dashboardModel.accentColor)

            if isLoadingProfile {
                HStack {
                    ProgressView()
                    Text("Loading your profile…")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.45))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 8)
            } else if momSession.session == nil {
                Text("Sign in to sync your profile from the clinic app.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.45))
            } else if let p = profile {
                profileField(title: "Full name", value: p.fullName)
                profileField(title: "Contact", value: p.contactNumber)
                profileField(title: "District", value: p.district)
                if let lmp = p.lmpDate, !lmp.isEmpty {
                    profileField(title: "LMP date", value: lmp)
                }
            } else if let profileError {
                Text(profileError)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.red.opacity(0.85))
            } else {
                Text("No profile row found yet. Complete registration or try refresh.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.45))
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
    }

    private func profileField(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.35))
            Text(value)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.78))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var securityCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(profileCopy.securitySectionTitle)
                .font(.system(size: 13, weight: .bold))
                .foregroundStyle(dashboardModel.accentColor)

            Toggle(isOn: lockWhenLeavingBinding) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Lock when leaving app")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.78))
                    Text("Ask for PIN (or Face ID) when you return from another app.")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.4))
                }
            }
            .tint(dashboardModel.accentColor)

            Toggle(isOn: biometricBinding) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Use \(BiometricAuthService.biometricTypeDescription())")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.78))
                    Text(
                        BiometricAuthService.canUseBiometrics
                        ? "Quick unlock when app lock is on. PIN always works as backup."
                        : "Face ID / Touch ID is unavailable on this device right now."
                    )
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.4))
                }
            }
            .tint(dashboardModel.accentColor)
            .disabled(!PINAuthStore.shared.hasPIN || !BiometricAuthService.canUseBiometrics)
            .opacity((PINAuthStore.shared.hasPIN && BiometricAuthService.canUseBiometrics) ? 1 : 0.45)

            VStack(alignment: .leading, spacing: 8) {
                Button {
                    showPINSetup = true
                } label: {
                    HStack {
                        Image(systemName: PINAuthStore.shared.hasPIN ? "ellipsis.rectangle" : "key.fill")
                        Text(PINAuthStore.shared.hasPIN ? "Change PIN" : "Set up 4-digit PIN")
                            .font(.system(size: 15, weight: .bold))
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(Color.black.opacity(0.25))
                    }
                    .foregroundStyle(Color.black.opacity(0.72))
                    .padding(.vertical, 14)
                    .padding(.horizontal, 14)
                    .background(dashboardModel.accentColor.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)

                if PINAuthStore.shared.hasPIN {
                    Button(role: .destructive) {
                        showRemovePINConfirm = true
                    } label: {
                        Text("Remove PIN")
                            .font(.system(size: 14, weight: .semibold))
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 12, y: 4)
    }

    private var lockWhenLeavingBinding: Binding<Bool> {
        Binding(
            get: { appLock.lockWhenLeavingApp },
            set: { newValue in
                if newValue {
                    guard PINAuthStore.shared.hasPIN else {
                        showPINSetup = true
                        return
                    }
                    appLock.lockWhenLeavingApp = true
                } else {
                    appLock.lockWhenLeavingApp = false
                    appLock.isLocked = false
                }
            }
        )
    }

    private var biometricBinding: Binding<Bool> {
        Binding(
            get: { appLock.preferBiometricUnlock },
            set: { newValue in
                guard PINAuthStore.shared.hasPIN else {
                    localAlert = "Set a PIN before using biometrics."
                    return
                }
                guard BiometricAuthService.canUseBiometrics else {
                    localAlert = "Face ID / Touch ID is unavailable on this device."
                    appLock.preferBiometricUnlock = false
                    return
                }
                if newValue {
                    Task {
                        let verified = await BiometricAuthService.authenticate(
                            reason: "Enable \(BiometricAuthService.biometricTypeDescription()) for app unlock"
                        )
                        await MainActor.run {
                            if verified {
                                appLock.preferBiometricUnlock = true
                                if !appLock.lockWhenLeavingApp {
                                    appLock.lockWhenLeavingApp = true
                                }
                            } else {
                                appLock.preferBiometricUnlock = false
                                localAlert = "Biometric verification failed. Face ID / Touch ID was not enabled."
                            }
                        }
                    }
                } else {
                    appLock.preferBiometricUnlock = false
                }
            }
        )
    }

    private var signOutButton: some View {
        Button {
            showSignOutConfirm = true
        } label: {
            Text(profileCopy.signOutTitle)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.red.opacity(0.9))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func loadProfile() async {
        profileError = nil
        guard let session = momSession.session else {
            profile = nil
            return
        }
        isLoadingProfile = true
        defer { isLoadingProfile = false }
        do {
            let p = try await MomProfileRepository().fetchOwnProfile(
                userId: session.userId,
                accessToken: session.accessToken
            )
            profile = p
        } catch {
            profile = nil
            profileError = "Could not load profile. Check network and Supabase."
        }
    }

    private func signOut() {
        momSession.clearSession()
        appLock.resetLockPreferences()
        PINAuthStore.shared.clearPIN()
        profile = nil
        localAlert = "You are signed out on this device. Use the back button to return to sign in, or restart the app."
    }
}

struct PINSetupSheetView: View {
    let accentColor: Color
    var isMandatory: Bool = false
    var onDone: () -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var step = 0
    @State private var pinFirst = ""
    @State private var pinEntry = ""
    @State private var banner: String?

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(step == 0 ? "Create a 4-digit PIN" : "Confirm your PIN")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.78))
                    .padding(.top, 8)

                if let banner {
                    Text(banner)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.red.opacity(0.85))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                PINPadView(
                    accentColor: accentColor,
                    pin: $pinEntry,
                    maxDigits: 4,
                    digitTextColor: Color.black.opacity(0.72),
                    digitBackgroundColor: Color.black.opacity(0.06),
                    emptyDotColor: Color.black.opacity(0.18),
                    deleteIconColor: Color.black.opacity(0.5)
                ) { entered in
                    if step == 0 {
                        pinFirst = entered
                        pinEntry = ""
                        step = 1
                        banner = nil
                    } else {
                        if entered == pinFirst {
                            do {
                                try PINAuthStore.shared.setPIN(entered)
                                pinEntry = ""
                                onDone()
                                dismiss()
                            } catch {
                                banner = "Could not save PIN."
                                pinEntry = ""
                            }
                        } else {
                            banner = "PINs did not match. Try again."
                            pinEntry = ""
                            step = 0
                            pinFirst = ""
                        }
                    }
                }
                .padding(.horizontal, 32)

                Spacer()
            }
            .background(Color(red: 0.98, green: 0.96, blue: 0.97))
            .toolbar {
                if !isMandatory {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    MomProfileView(
        dashboardModel: MomDashboardController().loadModel(),
        profileCopy: MomDashboardController().loadProfileDisplayModel()
    )
    .environmentObject(MomSessionStore.shared)
    .environmentObject(AppLockManager.shared)
}
