import SwiftUI

struct MidwifeMomDetailsView: View {
    let model: MidwifeMomDetailsModel
    let session: AuthSessionContext
    let mom: MomListRow

    @Environment(\.dismiss) private var dismiss

    @State private var children: [ChildProfile] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    @State private var isNavigatingToChildRegistration = false

    var body: some View {
        ZStack {
            model.backgroundColor.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    topBar
                        .padding(.top, 10)

                    header
                        .padding(.top, 10)

                    description
                        .padding(.top, 12)

                    actionButtons
                        .padding(.top, 18)

                    childrenSection
                        .padding(.top, 26)

                    memberSinceCard
                        .padding(.top, 26)
                        .padding(.bottom, 18)
                }
                .padding(.horizontal, 22)
            }

            NavigationLink(
                destination: ChildRegistrationView(
                    model: ChildRegistrationController().loadModel(),
                    session: session,
                    mom: mom,
                    onSaved: { loadChildren() }
                ),
                isActive: $isNavigatingToChildRegistration
            ) {
                EmptyView()
            }
            .hidden()
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            loadChildren()
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

    private var topBar: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(model.accentColor)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Circle()
                .fill(Color.black.opacity(0.06))
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: "person.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(Color.black.opacity(0.25))
                )

            Color.clear.frame(width: 44, height: 44)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(model.sectionLabel)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(model.accentColor)

            Text(mom.fullName)
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.8))

            Text(mom.district)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.5))
        }
    }

    private var description: some View {
        Text("Managing healthcare journeys for the \(mom.fullName) family since 2021.")
            .font(.system(size: 18, weight: .regular))
            .foregroundStyle(Color.black.opacity(0.55))
            .fixedSize(horizontal: false, vertical: true)
    }

    private var actionButtons: some View {
        VStack(spacing: 14) {
            Button {
                isNavigatingToChildRegistration = true
            } label: {
                HStack(spacing: 10) {
                    Text(model.addChildTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)

                    Image(systemName: "plus.circle")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(model.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }

            Button {
                errorMessage = "Update Mom Details is not implemented yet."
            } label: {
                HStack(spacing: 10) {
                    Text(model.updateMomTitle)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(model.accentColor)

                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(model.accentColor)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.white.opacity(0.35))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(Color.black.opacity(0.12), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            }
        }
    }

    private var childrenSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(model.childrenSectionTitle)
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.8))

                Spacer()

                Text("\(children.count) Total")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.55))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.white.opacity(0.55))
                    .clipShape(Capsule())
            }

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 10)
            } else if children.isEmpty {
                Text("No children added yet.")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.45))
                    .padding(.vertical, 12)
            } else {
                VStack(spacing: 16) {
                    ForEach(children) { child in
                        childRow(child)
                    }
                }
            }
        }
    }

    private func childRow(_ child: ChildProfile) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 70, height: 70)

                Image(systemName: "face.smiling")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.25))
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(child.fullName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.75))

                HStack(spacing: 8) {
                    Image(systemName: "calendar")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.35))

                    Text("Born \(formattedDOB(child.birthDate))")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.55))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.25))
                .padding(.trailing, 8)
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 10)
    }

    private var memberSinceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(model.memberSinceTitle)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(model.accentColor)

            Text("2021")
                .font(.system(size: 44, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.75))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.65), model.accentColor.opacity(0.08)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func loadChildren() {
        isLoading = true
        Task {
            defer { Task { @MainActor in isLoading = false } }
            do {
                let rows = try await ChildProfilesRepository().fetchChildren(
                    momUserId: mom.userId,
                    accessToken: session.accessToken
                )
                await MainActor.run {
                    children = rows
                }
            } catch SupabaseServiceError.httpError(let status, let body) {
                await MainActor.run {
                    errorMessage = "Failed to load children (\(status)): \(SupabaseAuthService.humanMessage(fromBody: body))"
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to load children: \(error.localizedDescription)"
                }
            }
        }
    }

    private func formattedDOB(_ iso: String) -> String {
        let input = DateFormatter()
        input.locale = Locale(identifier: "en_US_POSIX")
        input.timeZone = TimeZone(secondsFromGMT: 0)
        input.dateFormat = "yyyy-MM-dd"

        let output = DateFormatter()
        output.locale = Locale(identifier: "en_US_POSIX")
        output.dateFormat = "MMM d, yyyy"

        guard let date = input.date(from: iso) else { return iso }
        return output.string(from: date)
    }
}

#Preview {
    NavigationStack {
        MidwifeMomDetailsView(
            model: MidwifeMomDetailsController().loadModel(),
            session: AuthSessionContext(userId: UUID(), accessToken: "test"),
            mom: MomListRow(id: UUID(), userId: UUID(), fullName: "Adithya Ekanayaka", district: "Kalutara")
        )
    }
}
