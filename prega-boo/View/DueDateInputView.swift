import SwiftUI

struct DueDateInputView: View {
    let model: DueDateInputModel
    let registration: RegistrationContext?

    @State private var selectedDate = Date()
    @State private var typedDate = ""

    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var goToDashboard = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [model.backgroundColor, model.accentColor.opacity(0.22)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                headerCard
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                Spacer().frame(height: 22)

                dateField
                    .padding(.horizontal, 20)

                Spacer().frame(height: 18)

                calendarCard
                    .padding(.horizontal, 20)

                Spacer()

                Button(action: submitDueDate) {
                    Text(isSubmitting ? "Please wait..." : model.continueButtonTitle)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(model.accentColor)
                        .clipShape(Capsule())
                }
                .disabled(isSubmitting)
                .padding(.horizontal, 36)
                .padding(.bottom, 28)

                NavigationLink(
                    destination: MomDashboardView(model: MomDashboardController().loadModel()),
                    isActive: $goToDashboard
                ) {
                    EmptyView()
                }
            }
        }
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

    private func submitDueDate() {
        errorMessage = nil
        isSubmitting = true

        Task {
            defer { isSubmitting = false }

            do {
                if let registration {
                    let formatter = DateFormatter()
                    formatter.locale = Locale(identifier: "en_US_POSIX")
                    formatter.timeZone = TimeZone(secondsFromGMT: 0)
                    formatter.dateFormat = "yyyy-MM-dd"
                    let lmpString = formatter.string(from: selectedDate)

                    let profile = MomProfile(
                        id: nil,
                        userId: registration.userId,
                        fullName: registration.fullName,
                        contactNumber: registration.contactNumber,
                        district: registration.district,
                        lmpDate: lmpString,
                        photoPath: registration.photoPath
                    )

                    try await MomProfileRepository().upsert(profile: profile, accessToken: registration.accessToken)
                }

                if let registration {
                    await MainActor.run {
                        MomSessionStore.shared.setSession(
                            AuthSessionContext(userId: registration.userId, accessToken: registration.accessToken)
                        )
                    }
                }

                goToDashboard = true
            } catch SupabaseServiceError.httpError(let status, let body) {
                errorMessage = "Failed to save due date (\(status)): \(SupabaseAuthService.humanMessage(fromBody: body))"
            } catch {
                errorMessage = "Failed to save due date: \(error.localizedDescription)"
            }
        }
    }

    private var headerCard: some View {
        VStack(spacing: 10) {
            Text(model.title)
                .font(.system(size: 18, weight: .bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(Color.black.opacity(0.8))

            Button(action: {}) {
                Text(model.helpLinkTitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.7))
                    .underline()
            }
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 14)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var dateField: some View {
        TextField(model.datePlaceholder, text: $typedDate)
            .font(.system(size: 14))
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
            )
    }

    private var calendarCard: some View {
        DatePicker(
            "",
            selection: $selectedDate,
            displayedComponents: [.date]
        )
        .datePickerStyle(.graphical)
        .labelsHidden()
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .shadow(color: Color.black.opacity(0.08), radius: 18, x: 0, y: 10)
    }
}

#Preview {
    DueDateInputView(model: DueDateInputController().loadModel(), registration: nil)
}
