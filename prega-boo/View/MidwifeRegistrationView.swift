import SwiftUI

struct MidwifeRegistrationView: View {
    let model: MidwifeRegistrationModel

    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var nicNumber = ""
    @State private var selectedDistrict = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""

    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var sessionContext: AuthSessionContext?

    private let districts: [String] = [
        "Ampara",
        "Anuradhapura",
        "Badulla",
        "Batticaloa",
        "Colombo",
        "Galle",
        "Gampaha",
        "Hambantota",
        "Jaffna",
        "Kalutara",
        "Kandy",
        "Kegalle",
        "Kilinochchi",
        "Kurunegala",
        "Mannar",
        "Matale",
        "Matara",
        "Monaragala",
        "Mullaitivu",
        "Nuwara Eliya",
        "Polonnaruwa",
        "Puttalam",
        "Ratnapura",
        "Trincomalee",
        "Vavuniya"
    ]

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [model.backgroundColor, model.accentColor.opacity(0.22)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                content
                    .padding(.horizontal, 28)
                    .padding(.top, 18)

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

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(model.title)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.85))
                .padding(.top, 8)

            Spacer().frame(height: 26)

            labeledUnderlinedField(label: model.nameLabel) {
                TextField("", text: $fullName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(false)
            }

            Spacer().frame(height: 18)

            labeledUnderlinedField(label: model.nicLabel) {
                TextField("", text: $nicNumber)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
            }

            Spacer().frame(height: 18)

            labeledUnderlinedField(label: model.emailLabel) {
                TextField("", text: $email)
                    .textInputAutocapitalization(.never)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
            }

            Spacer().frame(height: 18)

            labeledUnderlinedField(label: model.passwordLabel) {
                SecureField("", text: $password)
            }

            Spacer().frame(height: 18)

            labeledUnderlinedField(label: model.confirmPasswordLabel) {
                SecureField("", text: $confirmPassword)
            }

            Spacer().frame(height: 18)

            locationDropdown

            Spacer().frame(height: 24)

            Button(action: submitRegistration) {
                Text(isSubmitting ? "Please wait..." : model.registerButtonTitle)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(model.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .disabled(isSubmitting)
            .padding(.top, 10)

            NavigationLink(
                destination: Group {
                    if let sessionContext {
                        MidwifeMomsListView(
                            model: MidwifeMomsListController().loadModel(),
                            session: sessionContext
                        )
                    } else {
                        EmptyView()
                    }
                },
                isActive: Binding(
                    get: { sessionContext != nil },
                    set: { newValue in if !newValue { sessionContext = nil } }
                )
            ) {
                EmptyView()
            }
        }
    }

    private func submitRegistration() {
        errorMessage = nil

        let configuredKey = SupabaseSecrets.anonKey
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")

        if configuredKey.isEmpty || configuredKey == "PASTE_YOUR_ANON_KEY_HERE" {
            errorMessage = "Supabase anon key is not set. Update SupabaseSecrets.swift (Project Settings → API → anon public)."
            return
        }

        let nameTrimmed = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let nicTrimmed = nicNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let emailTrimmed = email.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !nameTrimmed.isEmpty,
              !nicTrimmed.isEmpty,
              !selectedDistrict.isEmpty,
              !emailTrimmed.isEmpty,
              !password.isEmpty,
              !confirmPassword.isEmpty
        else {
            errorMessage = "Please fill all fields."
            return
        }

        guard password == confirmPassword else {
            errorMessage = "Passwords do not match."
            return
        }

        isSubmitting = true

        Task {
            defer { isSubmitting = false }
            do {
                let auth = SupabaseAuthService()
                let session = try await auth.signUpThenSignIn(email: emailTrimmed, password: password)

                // Assign MIDWIFE role
                try await UserRoleRepository().insertRole(
                    userId: session.user.id,
                    role: .midwife,
                    accessToken: session.accessToken
                )

                let profile = MidwifeProfile(
                    id: nil,
                    userId: session.user.id,
                    fullName: nameTrimmed,
                    district: selectedDistrict,
                    nicNumber: nicTrimmed,
                    photoPath: nil
                )

                try await MidwifeProfileRepository().upsert(profile: profile, accessToken: session.accessToken)

                sessionContext = AuthSessionContext(userId: session.user.id, accessToken: session.accessToken)
            } catch let authError as SupabaseAuthError {
                switch authError {
                case .missingSession:
                    errorMessage = "Registration succeeded but no session was returned."
                case .emailConfirmationRequired:
                    errorMessage = "Please confirm your email address in your inbox, then log in. (Or disable email confirmations in Supabase during development.)"
                case .invalidInput(let msg):
                    errorMessage = msg
                }
            } catch SupabaseServiceError.httpError(let status, let body) {
                errorMessage = "Registration failed (\(status)): \(SupabaseAuthService.humanMessage(fromBody: body))"
            } catch {
                errorMessage = "Registration failed: \(error.localizedDescription)"
            }
        }
    }

    private func labeledUnderlinedField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.75))

            content()
                .font(.system(size: 16))
                .foregroundStyle(Color.black.opacity(0.85))

            Divider()
                .background(Color.black.opacity(0.25))
        }
    }

    private var locationDropdown: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(model.locationLabel)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.75))

            Menu {
                ForEach(districts, id: \.self) { district in
                    Button(district) {
                        selectedDistrict = district
                    }
                }
            } label: {
                HStack {
                    Text(selectedDistrict.isEmpty ? "Select district" : selectedDistrict)
                        .font(.system(size: 16))
                        .foregroundStyle(selectedDistrict.isEmpty ? Color.black.opacity(0.35) : Color.black.opacity(0.85))

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.35))
                }
            }

            Divider()
                .background(Color.black.opacity(0.25))
        }
    }
}

#Preview {
    NavigationStack {
        MidwifeRegistrationView(model: MidwifeRegistrationController().loadModel())
    }
}
