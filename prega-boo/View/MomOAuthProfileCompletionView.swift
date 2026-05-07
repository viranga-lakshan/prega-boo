import PhotosUI
import SwiftUI

/// After Google sign-in: collect contact + district (and optional photo), then continue to LMP / due date like manual registration.
struct MomOAuthProfileCompletionView: View {
    let session: AuthSessionContext
    var suggestedFullName: String?
    var suggestedEmail: String?

    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var contactNumber = ""
    @State private var selectedDistrict = ""
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhoto: Image?
    @State private var selectedPhotoData: Data?

    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var registrationContext: RegistrationContext?

    private let countryCode = "+94"

    private let districts: [String] = [
        "Ampara", "Anuradhapura", "Badulla", "Batticaloa", "Colombo", "Galle", "Gampaha",
        "Hambantota", "Jaffna", "Kalutara", "Kandy", "Kegalle", "Kilinochchi", "Kurunegala",
        "Mannar", "Matale", "Matara", "Monaragala", "Mullaitivu", "Nuwara Eliya", "Polonnaruwa",
        "Puttalam", "Ratnapura", "Trincomalee", "Vavuniya"
    ]

    private var accent: Color { Color(red: 0.94, green: 0.39, blue: 0.45) }
    private var background: Color { Color(red: 1.0, green: 0.97, blue: 0.97) }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [background, accent.opacity(0.22)],
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
        .onAppear {
            if name.isEmpty, let suggestedFullName, !suggestedFullName.isEmpty {
                name = suggestedFullName
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
        .onChange(of: selectedPhotoItem) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        selectedPhoto = Image(uiImage: uiImage)
                        selectedPhotoData = uiImage.jpegData(compressionQuality: 0.85) ?? data
                    }
                }
            }
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accent)
                    .frame(width: 44, height: 44)
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.top, 12)
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Complete your profile")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.85))
                .padding(.top, 8)

            if let suggestedEmail, !suggestedEmail.isEmpty {
                Text("Signed in as \(suggestedEmail)")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.5))
                    .padding(.top, 8)
            }

            Spacer().frame(height: 22)

            labeledField("Your name") {
                TextField("", text: $name)
                    .textInputAutocapitalization(.words)
            }

            Spacer().frame(height: 18)

            labeledField("Contact Number") {
                HStack(spacing: 10) {
                    Text(countryCode)
                        .font(.system(size: 16, weight: .medium))
                    TextField("", text: $contactNumber)
                        .keyboardType(.numberPad)
                }
            }

            Spacer().frame(height: 18)

            districtMenu

            Spacer().frame(height: 18)

            photoPicker

            Spacer().frame(height: 24)

            Button(action: submit) {
                Text(isSubmitting ? "Please wait..." : "Next")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(accent)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            .disabled(isSubmitting)

            NavigationLink(
                destination: Group {
                    if let ctx = registrationContext {
                        DueDateInputView(
                            model: DueDateInputController().loadModel(),
                            registration: ctx
                        )
                    } else {
                        EmptyView()
                    }
                },
                isActive: Binding(
                    get: { registrationContext != nil },
                    set: { newValue in if !newValue { registrationContext = nil } }
                )
            ) {
                EmptyView()
            }
        }
    }

    private func labeledField<Content: View>(_ label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.75))
            content()
                .font(.system(size: 16))
            Divider().background(Color.black.opacity(0.25))
        }
    }

    private var districtMenu: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Location")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.75))
            Menu {
                ForEach(districts, id: \.self) { d in
                    Button(d) { selectedDistrict = d }
                }
            } label: {
                HStack {
                    Text(selectedDistrict.isEmpty ? "Select district" : selectedDistrict)
                        .foregroundStyle(selectedDistrict.isEmpty ? Color.black.opacity(0.35) : Color.black.opacity(0.85))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(Color.black.opacity(0.35))
                }
            }
            Divider().background(Color.black.opacity(0.25))
        }
    }

    private var photoPicker: some View {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(Color.black.opacity(0.06))
                        .frame(width: 48, height: 48)
                    if let selectedPhoto {
                        selectedPhoto
                            .resizable()
                            .scaledToFill()
                            .frame(width: 48, height: 48)
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    } else {
                        Image(systemName: "camera.fill")
                            .foregroundStyle(Color.black.opacity(0.45))
                    }
                }
                Text("Profile photo (optional)")
                    .font(.system(size: 14, weight: .medium))
                Spacer()
            }
        }
    }

    private func submit() {
        errorMessage = nil
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedContact = contactNumber.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty, !trimmedContact.isEmpty, !selectedDistrict.isEmpty else {
            errorMessage = "Please enter name, contact number, and district."
            return
        }

        isSubmitting = true
        Task {
            defer { isSubmitting = false }
            do {
                var photoPath: String?
                if let selectedPhotoData {
                    photoPath = try await MomProfileRepository().uploadProfilePhoto(
                        userId: session.userId,
                        photoData: selectedPhotoData,
                        accessToken: session.accessToken
                    )
                }

                registrationContext = RegistrationContext(
                    userId: session.userId,
                    accessToken: session.accessToken,
                    fullName: trimmedName,
                    contactNumber: "\(countryCode)\(trimmedContact)",
                    district: selectedDistrict,
                    photoPath: photoPath
                )
            } catch SupabaseServiceError.httpError(let status, let body) {
                errorMessage = "Could not save photo (\(status)): \(SupabaseAuthService.humanMessage(fromBody: body))"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
