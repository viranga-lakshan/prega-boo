import PhotosUI
import SwiftUI

struct AdminLoginView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var adminSession: AuthSessionContext?

    var body: some View {
        ZStack {
            Color(red: 1.0, green: 0.97, blue: 0.97).ignoresSafeArea()

            VStack(spacing: 16) {
                HStack {
                    Button(action: { dismiss() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color(red: 0.82, green: 0.2, blue: 0.45))
                            .frame(width: 44, height: 44)
                    }
                    Spacer()
                }

                VStack(alignment: .leading, spacing: 14) {
                    Text("Admin Login")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    Text("Sign in with an admin account to manage midwives.")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.5))

                    field(label: "Email Address", text: $email, secure: false)
                    field(label: "Password", text: $password, secure: true)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.red.opacity(0.9))
                    }

                    Button(action: submit) {
                        Text(isSubmitting ? "Please wait..." : "Admin Login")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(Color(red: 0.82, green: 0.2, blue: 0.45))
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .disabled(isSubmitting)
                }
                .padding(20)
                .background(Color.white.opacity(0.75))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

                NavigationLink(
                    destination: Group {
                        if let adminSession {
                            AdminPortalView(session: adminSession)
                        } else {
                            EmptyView()
                        }
                    },
                    isActive: Binding(
                        get: { adminSession != nil },
                        set: { newValue in if !newValue { adminSession = nil } }
                    )
                ) {
                    EmptyView()
                }

                Spacer()
            }
            .padding(.horizontal, 20)
        }
        .navigationBarBackButtonHidden(true)
    }

    private func field(label: String, text: Binding<String>, secure: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.55))
            Group {
                if secure {
                    SecureField("", text: text)
                } else {
                    TextField("", text: text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color(red: 0.98, green: 0.92, blue: 0.94))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private func submit() {
        errorMessage = nil
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password."
            return
        }

        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                let auth = SupabaseAuthService()
                let session = try await auth.signIn(email: trimmedEmail, password: password)
                let context = AuthSessionContext(userId: session.user.id, accessToken: session.accessToken)
                let role = try await UserRoleRepository().fetchRole(userId: context.userId, accessToken: context.accessToken)
                guard role == .admin else {
                    errorMessage = "This account is not an admin."
                    return
                }
                adminSession = context
            } catch SupabaseServiceError.httpError(let status, let body) {
                errorMessage = "Login failed (\(status)): \(SupabaseAuthService.humanMessage(fromBody: body))"
            } catch {
                errorMessage = "Login failed: \(error.localizedDescription)"
            }
        }
    }
}

private struct AdminPortalView: View {
    let session: AuthSessionContext

    @Environment(\.dismiss) private var dismiss
    @State private var midwives: [MidwifeProfile] = []
    @State private var midwifePhotoByUserId: [UUID: UIImage] = [:]
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showAddMidwife = false
    @State private var showUpdateMidwife = false
    @State private var selectedMidwife: MidwifeProfile?

    var body: some View {
        ZStack {
            Color(red: 1.0, green: 0.97, blue: 0.97).ignoresSafeArea()
            VStack(spacing: 12) {
                HStack {
                    Text("Admin Portal")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                    Spacer()
                    Button("Logout") { dismiss() }
                        .foregroundStyle(Color(red: 0.82, green: 0.2, blue: 0.45))
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)

                HStack {
                    Text("Midwife Directory")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    Spacer()
                }
                .padding(.horizontal, 18)

                if isLoading {
                    ProgressView().padding(.top, 24)
                    Spacer()
                } else {
                    ScrollView {
                        VStack(spacing: 12) {
                            ForEach(midwives, id: \.userId) { midwife in
                                HStack(alignment: .center, spacing: 12) {
                                    ZStack {
                                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                                            .fill(Color.black.opacity(0.06))
                                            .frame(width: 56, height: 56)
                                        if let image = midwifePhotoByUserId[midwife.userId] {
                                            Image(uiImage: image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 56, height: 56)
                                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                                        } else {
                                            Image(systemName: "person.fill")
                                                .font(.system(size: 24, weight: .semibold))
                                                .foregroundStyle(Color.black.opacity(0.25))
                                        }
                                    }

                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(midwife.fullName)
                                            .font(.system(size: 18, weight: .bold))
                                        Text(midwife.district)
                                            .foregroundStyle(Color.black.opacity(0.55))
                                        Text("NIC: \(midwife.nicNumber)")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(Color.black.opacity(0.4))
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)

                                    Button("Update") {
                                        selectedMidwife = midwife
                                        showUpdateMidwife = true
                                    }
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(Color(red: 0.82, green: 0.2, blue: 0.45))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color(red: 0.82, green: 0.2, blue: 0.45).opacity(0.1))
                                    .clipShape(Capsule())
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(14)
                                .background(Color.white)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                        }
                        .padding(.horizontal, 18)
                        .padding(.vertical, 8)
                    }
                }

                Button(action: { showAddMidwife = true }) {
                    Text("+ Add New Midwife")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.78, green: 0.2, blue: 0.55), Color(red: 0.94, green: 0.39, blue: 0.45)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 18)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task { await loadMidwives() }
        .sheet(isPresented: $showAddMidwife) {
            AdminRegisterMidwifeSheet(session: session) {
                Task { await loadMidwives() }
            }
            .presentationDetents([.large])
        }
        .sheet(isPresented: $showUpdateMidwife) {
            if let selectedMidwife {
                AdminUpdateMidwifeSheet(session: session, midwife: selectedMidwife) {
                    Task { await loadMidwives() }
                }
                .presentationDetents([.large])
            }
        }
        .alert(
            "Error",
            isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
    }

    private func loadMidwives() async {
        isLoading = true
        defer { isLoading = false }
        do {
            let list = try await AdminMidwifeManagementRepository().fetchMidwives(accessToken: session.accessToken)
            await MainActor.run {
                midwives = list
            }
            await loadMidwifePhotos(rows: list)
        } catch SupabaseServiceError.httpError(let status, let body) {
            await MainActor.run {
                errorMessage = "Failed to load midwives (\(status)): \(SupabaseAuthService.humanMessage(fromBody: body))"
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to load midwives: \(error.localizedDescription)"
            }
        }
    }

    private func loadMidwifePhotos(rows: [MidwifeProfile]) async {
        var fetched: [UUID: UIImage] = [:]
        await withTaskGroup(of: (UUID, UIImage?).self) { group in
            for row in rows {
                guard let path = row.photoPath, !path.isEmpty else { continue }
                group.addTask {
                    do {
                        let data = try await MidwifeProfileRepository().fetchProfilePhoto(
                            path: path,
                            accessToken: session.accessToken
                        )
                        return (row.userId, UIImage(data: data))
                    } catch {
                        return (row.userId, nil)
                    }
                }
            }
            for await (userId, image) in group {
                if let image {
                    fetched[userId] = image
                }
            }
        }
        await MainActor.run {
            for (userId, image) in fetched {
                midwifePhotoByUserId[userId] = image
            }
        }
    }
}

private struct AdminUpdateMidwifeSheet: View {
    let session: AuthSessionContext
    let midwife: MidwifeProfile
    var onSuccess: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var fullName = ""
    @State private var district = ""
    @State private var nicNumber = ""
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private let districts = [
        "Ampara", "Anuradhapura", "Badulla", "Batticaloa", "Colombo", "Galle", "Gampaha",
        "Hambantota", "Jaffna", "Kalutara", "Kandy", "Kegalle", "Kilinochchi", "Kurunegala",
        "Mannar", "Matale", "Matara", "Monaragala", "Mullaitivu", "Nuwara Eliya", "Polonnaruwa",
        "Puttalam", "Ratnapura", "Trincomalee", "Vavuniya"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    textField("Full Name", text: $fullName)
                    districtField
                    textField("NIC Number", text: $nicNumber)

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.red.opacity(0.9))
                    }
                }
                .padding(18)
            }
            .navigationTitle("Update Midwife")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSubmitting ? "Saving..." : "Save") {
                        Task { await saveChanges() }
                    }
                    .disabled(isSubmitting)
                }
            }
            .onAppear {
                fullName = midwife.fullName
                district = midwife.district
                nicNumber = midwife.nicNumber
            }
        }
    }

    private func textField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.55))
            TextField("", text: text)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var districtField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("District")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.55))
            Menu {
                ForEach(districts, id: \.self) { value in
                    Button(value) { district = value }
                }
            } label: {
                HStack {
                    Text(district.isEmpty ? "Select District" : district)
                        .foregroundStyle(district.isEmpty ? Color.black.opacity(0.35) : Color.black.opacity(0.8))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(Color.black.opacity(0.35))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private func saveChanges() async {
        errorMessage = nil
        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDistrict = district.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNIC = nicNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty, !trimmedDistrict.isEmpty, !trimmedNIC.isEmpty else {
            errorMessage = "Please fill all fields."
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            let updated = MidwifeProfile(
                id: midwife.id,
                userId: midwife.userId,
                fullName: trimmedName,
                district: trimmedDistrict,
                nicNumber: trimmedNIC,
                photoPath: midwife.photoPath
            )
            try await MidwifeProfileRepository().upsert(profile: updated, accessToken: session.accessToken)
            onSuccess()
            dismiss()
        } catch SupabaseServiceError.httpError(let status, let body) {
            errorMessage = "Update failed (\(status)): \(SupabaseAuthService.humanMessage(fromBody: body))"
        } catch {
            errorMessage = "Update failed: \(error.localizedDescription)"
        }
    }
}

private struct AdminRegisterMidwifeSheet: View {
    let session: AuthSessionContext
    var onSuccess: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var fullName = ""
    @State private var district = ""
    @State private var nicNumber = ""
    @State private var email = ""
    @State private var password = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhotoData: Data?
    @State private var selectedPhotoPreview: Image?
    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private let districts = [
        "Ampara", "Anuradhapura", "Badulla", "Batticaloa", "Colombo", "Galle", "Gampaha",
        "Hambantota", "Jaffna", "Kalutara", "Kandy", "Kegalle", "Kilinochchi", "Kurunegala",
        "Mannar", "Matale", "Matara", "Monaragala", "Mullaitivu", "Nuwara Eliya", "Polonnaruwa",
        "Puttalam", "Ratnapura", "Trincomalee", "Vavuniya"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    textField("Full Name", text: $fullName, secure: false)
                    districtField
                    textField("NIC Number", text: $nicNumber, secure: false)
                    textField("Email Address", text: $email, secure: false)
                    textField("Password", text: $password, secure: true)
                    photoPickerRow

                    if let errorMessage {
                        Text(errorMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.red.opacity(0.9))
                    }
                }
                .padding(18)
            }
            .navigationTitle("Register New Midwife")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSubmitting ? "Saving..." : "Register") {
                        Task { await registerMidwife() }
                    }
                    .disabled(isSubmitting)
                }
            }
            .onChange(of: selectedPhotoItem) { newValue in
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

    private func textField(_ title: String, text: Binding<String>, secure: Bool) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.55))
            Group {
                if secure {
                    SecureField("", text: text)
                } else {
                    TextField("", text: text)
                        .textInputAutocapitalization(title.contains("Email") ? .never : .words)
                        .autocorrectionDisabled(title.contains("Email"))
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color.black.opacity(0.05))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var districtField: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("District")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.55))
            Menu {
                ForEach(districts, id: \.self) { value in
                    Button(value) { district = value }
                }
            } label: {
                HStack {
                    Text(district.isEmpty ? "Select District" : district)
                        .foregroundStyle(district.isEmpty ? Color.black.opacity(0.35) : Color.black.opacity(0.8))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(Color.black.opacity(0.35))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private var photoPickerRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Profile Photo (optional)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.55))

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color.black.opacity(0.05))
                            .frame(width: 46, height: 46)
                        if let selectedPhotoPreview {
                            selectedPhotoPreview
                                .resizable()
                                .scaledToFill()
                                .frame(width: 46, height: 46)
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        } else {
                            Image(systemName: "camera.fill")
                                .foregroundStyle(Color.black.opacity(0.35))
                        }
                    }
                    Text(selectedPhotoPreview == nil ? "Tap to select image" : "Image selected")
                        .foregroundStyle(Color.black.opacity(0.7))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundStyle(Color.black.opacity(0.35))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
        }
    }

    private func registerMidwife() async {
        errorMessage = nil

        let trimmedName = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedNIC = nicNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedNIC.isEmpty, !district.isEmpty, !trimmedEmail.isEmpty, !password.isEmpty else {
            errorMessage = "Please fill all fields."
            return
        }

        isSubmitting = true
        defer { isSubmitting = false }

        do {
            try await AdminMidwifeManagementRepository().registerMidwife(
                fullName: trimmedName,
                district: district,
                nicNumber: trimmedNIC,
                email: trimmedEmail,
                password: password,
                photoData: selectedPhotoData
            )
            onSuccess()
            dismiss()
        } catch let authError as SupabaseAuthError {
            switch authError {
            case .emailConfirmationRequired:
                errorMessage = "Email confirmation is enabled. Disable confirm-email for admin-created accounts or use a temporary password flow."
            case .invalidInput(let msg):
                errorMessage = msg
            case .missingSession:
                errorMessage = "Could not create auth user session."
            }
        } catch SupabaseServiceError.httpError(let status, let body) {
            let human = SupabaseAuthService.humanMessage(fromBody: body)
            let lowerBody = body.lowercased()
            if lowerBody.contains("[storage upload midwife-photos]") && lowerBody.contains("row-level security") {
                errorMessage = "Register failed: midwife photo upload blocked by storage RLS. Run migration 20260506213000_add_midwife_photos_storage_admin_support.sql."
            } else if (status == 403 || status == 400) && (lowerBody.contains("user_roles") || lowerBody.contains("row-level security")) {
                errorMessage = "Register failed: admin DB RLS policy is missing. Run migrations 20260506194000 and 20260506201000, and make sure this login account has role=admin in public.user_roles."
            } else {
                errorMessage = "Register failed (\(status)): \(human)"
            }
        } catch {
            errorMessage = "Register failed: \(error.localizedDescription)"
        }
    }
}

#Preview {
    NavigationStack {
        AdminLoginView()
    }
}
