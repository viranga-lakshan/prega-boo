import SwiftUI

struct ExpectingBabyLoginView: View {
    let model: ExpectingBabyLoginModel

    @Environment(\.dismiss) private var dismiss
    @State private var username = ""
    @State private var password = ""

    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var goToDashboard = false

    var body: some View {
        ZStack {
            model.backgroundColor
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                Spacer().frame(height: 10)

                AssetImage(assetName: model.heroAssetName, fallbackSystemName: "heart.fill")
                    .scaledToFit()
                    .frame(width: 260, height: 260)

                Spacer().frame(height: 18)

                loginCard
                    .padding(.horizontal, 24)

                Spacer()
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert(
            "Error",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { newValue in if !newValue { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .background(
            NavigationLink(
                destination: MomDashboardView(model: MomDashboardController().loadModel()),
                isActive: $goToDashboard
            ) {
                EmptyView()
            }
        )
    }

    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(model.accentColor)
                    .frame(width: 44, height: 44)
                    
            }

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
    }

    private var loginCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(model.title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.75))
                .padding(.top, 18)

            Text(model.userLabel)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)

            fieldRow(
                content: TextField(model.userPlaceholder, text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(),
                trailingSystemImage: "person"
            )

            fieldRow(
                content: SecureField(model.passwordPlaceholder, text: $password),
                trailingSystemImage: "eye.slash"
            )

            Button(action: submitLogin) {
                Text(isSubmitting ? "Please wait..." : model.loginButtonTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.55))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .disabled(isSubmitting)
            .padding(.top, 6)

            Spacer().frame(height: 10)

            Text(model.socialPrompt)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: 18) {
                socialCircle(label: "G")
                socialCircle(systemImage: "apple.logo")
                socialCircle(systemImage: "envelope.fill")
            }
            .frame(maxWidth: .infinity, alignment: .center)

            HStack(spacing: 6) {
                Text(model.manualRegistrationPrompt)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))

                NavigationLink {
                    ManualRegistrationView(model: ManualRegistrationController().loadModel())
                } label: {
                    Text(model.manualRegistrationLinkTitle)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .underline()
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 8)
            .padding(.bottom, 18)
        }
        .padding(.horizontal, 18)
        .background(model.cardColor)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
    }

    private func submitLogin() {
        errorMessage = nil

        let configuredKey = SupabaseSecrets.anonKey
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
        if configuredKey.isEmpty || configuredKey == "PASTE_YOUR_ANON_KEY_HERE" {
            errorMessage = "Supabase anon key is not set. Update SupabaseSecrets.swift (Project Settings → API → anon public)."
            return
        }

        let trimmedEmail = username.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password."
            return
        }

        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                let session = try await SupabaseAuthService().signIn(email: trimmedEmail, password: password)
                #if DEBUG
                print("✅ Logged in userId: \(session.user.id)")
                #endif

                let role = try await UserRoleRepository().fetchRole(
                    userId: session.user.id,
                    accessToken: session.accessToken
                )

                guard role == .mom else {
                    errorMessage = "This account is not registered as a mom. Please use the correct login."
                    return
                }

                goToDashboard = true
            } catch let authError as SupabaseAuthError {
                switch authError {
                case .missingSession:
                    errorMessage = "Login succeeded but no session was returned."
                case .emailConfirmationRequired:
                    errorMessage = "Please confirm your email address in your inbox, then log in."
                case .invalidInput(let msg):
                    errorMessage = msg
                }
            } catch SupabaseServiceError.httpError(let status, let body) {
                errorMessage = "Login failed (\(status)): \(SupabaseAuthService.humanMessage(fromBody: body))"
            } catch {
                errorMessage = "Login failed: \(error.localizedDescription)"
            }
        }
    }

    private func fieldRow<Content: View>(content: Content, trailingSystemImage: String) -> some View {
        HStack(spacing: 12) {
            content
                .font(.system(size: 14))
                .foregroundStyle(Color.black.opacity(0.75))

            Spacer()

            Image(systemName: trailingSystemImage)
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.black.opacity(0.35))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func socialCircle(label: String? = nil, systemImage: String? = nil) -> some View {
        ZStack {
            Circle()
                .fill(Color.white)
                .frame(width: 60, height: 60)

            if let systemImage {
                Image(systemName: systemImage)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(.black)
            } else if let label {
                Text(label)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(model.accentColor)
            }
        }
    }
}

#Preview {
    let model = ExpectingBabyLoginController().loadModel()
    NavigationStack {
        ExpectingBabyLoginView(model: model)
    }
}
