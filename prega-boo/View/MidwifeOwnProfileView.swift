import PhotosUI
import SwiftUI

/// Profile screen for the logged-in midwife.
/// Shows her current details (full name, NIC, district, photo) and lets her edit them.
struct MidwifeOwnProfileView: View {
    let session: AuthSessionContext
    var onLogout: (() -> Void)?

    init(session: AuthSessionContext, onLogout: (() -> Void)? = nil) {
        self.session = session
        self.onLogout = onLogout
    }

    @Environment(\.dismiss) private var dismiss

    private let backgroundColor = Color(red: 1.0, green: 0.97, blue: 0.97)
    private let accentColor = Color(red: 0.94, green: 0.39, blue: 0.45)
    private let deepMaroon = Color(red: 0.42, green: 0.11, blue: 0.20)

    @State private var profile: MidwifeProfile?
    @State private var profilePhoto: UIImage?
    @State private var isLoading = false
    @State private var errorMessage: String?

    @State private var showEditor = false
    @State private var showLogoutConfirm = false

    private let districts: [String] = [
        "Ampara", "Anuradhapura", "Badulla", "Batticaloa", "Colombo", "Galle", "Gampaha",
        "Hambantota", "Jaffna", "Kalutara", "Kandy", "Kegalle", "Kilinochchi", "Kurunegala",
        "Mannar", "Matale", "Matara", "Monaragala", "Mullaitivu", "Nuwara Eliya", "Polonnaruwa",
        "Puttalam", "Ratnapura", "Trincomalee", "Vavuniya"
    ]

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                        .padding(.top, 8)

                    headerCard
                        .padding(.top, 6)

                    detailsCard

                    Button {
                        showEditor = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.pencil")
                                .font(.system(size: 16, weight: .bold))
                            Text("Edit details")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(accentColor)
                        .clipShape(Capsule())
                        .shadow(color: accentColor.opacity(0.35), radius: 12, y: 6)
                    }
                    .disabled(profile == nil)
                    .opacity(profile == nil ? 0.5 : 1.0)

                    Button {
                        showLogoutConfirm = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "power")
                                .font(.system(size: 16, weight: .bold))
                            Text("Log out")
                                .font(.system(size: 16, weight: .bold))
                        }
                        .foregroundStyle(Color.red.opacity(0.85))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.white)
                        .overlay(
                            Capsule()
                                .stroke(Color.red.opacity(0.35), lineWidth: 1)
                        )
                        .clipShape(Capsule())
                    }
                    .padding(.top, 4)

                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 18)
            }
            .refreshable { await loadProfile() }

            if isLoading && profile == nil {
                ProgressView()
            }
        }
        .navigationBarBackButtonHidden(true)
        .task { await loadProfile() }
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
        .sheet(isPresented: $showEditor) {
            MidwifeOwnProfileEditSheet(
                session: session,
                profile: profile,
                accentColor: accentColor,
                backgroundColor: backgroundColor,
                districts: districts,
                onSaved: { updated in
                    profile = updated
                    Task { await loadProfilePhoto() }
                }
            )
            .presentationDetents([.large])
        }
        .confirmationDialog(
            "Log out of this account?",
            isPresented: $showLogoutConfirm,
            titleVisibility: .visible
        ) {
            Button("Log out", role: .destructive) { performLogout() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You'll need to sign in again to use the midwife dashboard on this device.")
        }
    }

    private func performLogout() {
        // Dismiss to the parent (Moms List) which will then pop itself via the supplied callback.
        dismiss()
        // Defer the parent's dismiss to the next runloop so the local pop animation completes cleanly.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            onLogout?()
        }
    }

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(deepMaroon)
                    .frame(width: 44, height: 44)
            }

            Spacer()

            Text("My Profile")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(deepMaroon)

            Spacer()

            Color.clear.frame(width: 44, height: 44)
        }
    }

    private var headerCard: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 110, height: 110)
                    .shadow(color: Color.black.opacity(0.10), radius: 16, x: 0, y: 10)

                if let profilePhoto {
                    Image(uiImage: profilePhoto)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 110, height: 110)
                        .clipShape(Circle())
                } else {
                    Image(systemName: "person.crop.circle.fill")
                        .font(.system(size: 110))
                        .foregroundStyle(Color.black.opacity(0.18))
                }

                Button {
                    showEditor = true
                } label: {
                    Circle()
                        .fill(accentColor)
                        .frame(width: 30, height: 30)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(.white)
                        )
                }
                .offset(x: 40, y: 36)
            }

            Text(profile?.fullName ?? "—")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.78))
                .multilineTextAlignment(.center)

            HStack(spacing: 6) {
                Image(systemName: "stethoscope")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(accentColor)

                Text("Certified Midwife")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.55))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 6)
            .background(Color.white.opacity(0.7))
            .clipShape(Capsule())
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var detailsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Account details")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.75))

            row(icon: "person.fill", label: "Full name", value: profile?.fullName)
            divider
            row(icon: "number", label: "NIC number", value: profile?.nicNumber)
            divider
            row(icon: "mappin.and.ellipse", label: "District", value: profile?.district)
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.04), radius: 16, x: 0, y: 8)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.black.opacity(0.06))
            .frame(height: 1)
    }

    private func row(icon: String, label: String, value: String?) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(accentColor.opacity(0.14))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.45))

                Text((value?.isEmpty == false ? value : nil) ?? "—")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.78))
            }

            Spacer()
        }
    }

    @MainActor
    private func loadProfile() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await MidwifeProfileRepository().fetchOwnProfile(
                userId: session.userId,
                accessToken: session.accessToken
            )
            profile = result
            await loadProfilePhoto()
        } catch SupabaseServiceError.httpError(let status, let body) {
            errorMessage = "Could not load profile (\(status)): \(SupabaseAuthService.humanMessage(fromBody: body))"
        } catch {
            errorMessage = "Could not load profile: \(error.localizedDescription)"
        }
    }

    private func loadProfilePhoto() async {
        guard let path = profile?.photoPath, !path.isEmpty else {
            await MainActor.run { profilePhoto = nil }
            return
        }
        do {
            let data = try await MidwifeProfileRepository().fetchProfilePhoto(
                path: path,
                accessToken: session.accessToken
            )
            let image = UIImage(data: data)
            await MainActor.run { profilePhoto = image }
        } catch {
            await MainActor.run { profilePhoto = nil }
        }
    }
}

// MARK: - Edit sheet

private struct MidwifeOwnProfileEditSheet: View {
    let session: AuthSessionContext
    let profile: MidwifeProfile?
    let accentColor: Color
    let backgroundColor: Color
    let districts: [String]
    var onSaved: (MidwifeProfile) -> Void

    @Environment(\.dismiss) private var dismiss

    @State private var fullName = ""
    @State private var nicNumber = ""
    @State private var district = ""

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var selectedPhotoPreview: Image?

    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ZStack {
                backgroundColor.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 14) {
                        field(label: "Full name", text: $fullName, autocap: .words)
                        field(label: "NIC number", text: $nicNumber, autocap: .characters)

                        VStack(alignment: .leading, spacing: 8) {
                            Text("District")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(Color.black.opacity(0.55))

                            Menu {
                                ForEach(districts, id: \.self) { value in
                                    Button(value) { district = value }
                                }
                            } label: {
                                HStack {
                                    Text(district.isEmpty ? "Select district" : district)
                                        .foregroundStyle(district.isEmpty ? Color.black.opacity(0.35) : Color.black.opacity(0.85))
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundStyle(Color.black.opacity(0.4))
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                            }
                        }

                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            HStack(spacing: 12) {
                                if let selectedPhotoPreview {
                                    selectedPhotoPreview
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 48, height: 48)
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                } else {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundStyle(accentColor)
                                        .frame(width: 48, height: 48)
                                        .background(accentColor.opacity(0.14))
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                }

                                Text("Change profile photo (optional)")
                                    .foregroundStyle(Color.black.opacity(0.75))

                                Spacer()
                            }
                            .padding(12)
                            .background(Color.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }

                        if let errorMessage {
                            Text(errorMessage)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.red.opacity(0.85))
                        }
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Edit profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        Task { await save() }
                    }
                    .disabled(isSaving)
                }
            }
            .onAppear {
                fullName = profile?.fullName ?? ""
                nicNumber = profile?.nicNumber ?? ""
                district = profile?.district ?? ""
            }
            .onChange(of: selectedPhotoItem) { _, newValue in
                guard let newValue else { return }
                Task {
                    if let data = try? await newValue.loadTransferable(type: Data.self),
                       let uiImage = UIImage(data: data) {
                        await MainActor.run {
                            selectedPhotoPreview = Image(uiImage: uiImage)
                            selectedPhotoData = uiImage.jpegData(compressionQuality: 0.85) ?? data
                        }
                    }
                }
            }
        }
    }

    private func field(label: String, text: Binding<String>, autocap: TextInputAutocapitalization) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.55))
            TextField("", text: text)
                .textInputAutocapitalization(autocap)
                .autocorrectionDisabled()
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    @MainActor
    private func save() async {
        errorMessage = nil

        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNic = nicNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDistrict = district.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty, !trimmedNic.isEmpty, !trimmedDistrict.isEmpty else {
            errorMessage = "Full name, NIC number and district are required."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            var photoPath = profile?.photoPath
            if let photoData = selectedPhotoData {
                photoPath = try await MidwifeProfileRepository().uploadProfilePhoto(
                    userId: session.userId,
                    photoData: photoData,
                    accessToken: session.accessToken
                )
            }

            let updated = MidwifeProfile(
                id: profile?.id,
                userId: session.userId,
                fullName: trimmedName,
                district: trimmedDistrict,
                nicNumber: trimmedNic,
                photoPath: photoPath
            )

            try await MidwifeProfileRepository().upsert(
                profile: updated,
                accessToken: session.accessToken
            )

            onSaved(updated)
            dismiss()
        } catch SupabaseServiceError.httpError(let status, let body) {
            errorMessage = "Save failed (\(status)): \(SupabaseAuthService.humanMessage(fromBody: body))"
        } catch {
            errorMessage = "Save failed: \(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack {
        MidwifeOwnProfileView(
            session: AuthSessionContext(userId: UUID(), accessToken: "preview")
        )
    }
}
