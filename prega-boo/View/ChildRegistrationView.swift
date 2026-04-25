import SwiftUI
import PhotosUI

struct ChildRegistrationView: View {
    let model: ChildRegistrationModel
    let session: AuthSessionContext
    let mom: MomListRow

    let onSaved: () -> Void

    @Environment(\.dismiss) private var dismiss

    private enum Gender: String, CaseIterable {
        case male = "Male"
        case female = "Female"
        case other = "Other"
    }

    @State private var fullName = ""
    @State private var selectedGender: Gender = .male
    @State private var dob = Date()
    @State private var deliveryMethod = ""
    @State private var notes = ""

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedPhoto: Image?
    @State private var selectedPhotoData: Data?

    @State private var isSubmitting = false
    @State private var errorMessage: String?

    private let deliveryMethods: [String] = [
        "Spontaneous Vaginal Delivery (SVD)",
        "C-Section",
        "Assisted Vaginal Delivery",
        "Other"
    ]

    var body: some View {
        ZStack {
            model.backgroundColor.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    topBar
                        .padding(.top, 6)

                    Text(model.title)
                        .font(.system(size: 34, weight: .bold))
                        .foregroundStyle(Color.black.opacity(0.8))
                        .padding(.top, 8)

                    Text(model.subtitle)
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color.black.opacity(0.55))
                        .padding(.top, 6)

                    identityCard
                        .padding(.top, 22)

                    birthCard
                        .padding(.top, 18)

                    additionalCard
                        .padding(.top, 18)

                    Spacer().frame(height: 110)
                }
                .padding(.horizontal, 22)
            }
        }
        .navigationBarBackButtonHidden(true)
        .safeAreaInset(edge: .bottom) {
            saveBar
        }
        .onChange(of: selectedPhotoItem) { _, newValue in
            guard let newValue else { return }
            Task {
                if let data = try? await newValue.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    await MainActor.run {
                        selectedPhoto = Image(uiImage: uiImage)
                        // Normalize to JPEG so Content-Type and bytes always match on upload.
                        selectedPhotoData = uiImage.jpegData(compressionQuality: 0.85) ?? data
                    }
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
    }

    private var identityCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardHeader(systemImage: "face.smiling", title: model.childIdentityTitle)

            Text(model.fullNameLabel)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.55))

            TextField(model.fullNamePlaceholder, text: $fullName)
                .textInputAutocapitalization(.words)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.black.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

            Text(model.genderLabel)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.55))
                .padding(.top, 6)

            HStack(spacing: 12) {
                genderPill(.male, icon: "mustache")
                genderPill(.female, icon: "figure.dress.line.vertical.figure")
                genderPill(.other, icon: "ellipsis")
            }
        }
        .padding(18)
        .background(model.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var birthCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardHeader(systemImage: "calendar", title: model.birthDetailsTitle)

            Text(model.dobLabel)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.55))

            DatePicker("", selection: $dob, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(model.accentColor)
                .labelsHidden()
                .padding(10)
                .background(Color.black.opacity(0.04))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text(model.deliveryMethodLabel)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.55))
                .padding(.top, 6)

            Menu {
                ForEach(deliveryMethods, id: \.self) { m in
                    Button(m) { deliveryMethod = m }
                }
            } label: {
                HStack {
                    Text(deliveryMethod.isEmpty ? "Spontaneous Vaginal Delivery (SVD)" : deliveryMethod)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.7))
                        .lineLimit(1)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.black.opacity(0.35))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 14)
                .background(Color.black.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
        }
        .padding(18)
        .background(model.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private var additionalCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            cardHeader(systemImage: "doc.text", title: model.additionalInfoTitle)

            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                VStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                            .foregroundStyle(Color.black.opacity(0.18))
                            .frame(height: 180)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.black.opacity(0.04))
                            )

                        if let selectedPhoto {
                            selectedPhoto
                                .resizable()
                                .scaledToFill()
                                .frame(height: 180)
                                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                        } else {
                            VStack(spacing: 8) {
                                Image(systemName: "camera")
                                    .font(.system(size: 26, weight: .bold))
                                    .foregroundStyle(Color.black.opacity(0.25))

                                Text(model.uploadIdPhotoTitle)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(Color.black.opacity(0.45))
                            }
                        }
                    }
                }
            }

            Text(model.notesLabel)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.55))

            ZStack(alignment: .topLeading) {
                TextEditor(text: $notes)
                    .frame(minHeight: 120)
                    .padding(10)
                    .background(Color.black.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Text(model.notesPlaceholder)
                        .font(.system(size: 16))
                        .foregroundStyle(Color.black.opacity(0.35))
                        .padding(.horizontal, 18)
                        .padding(.vertical, 18)
                }
            }
        }
        .padding(18)
        .background(model.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
    }

    private func cardHeader(systemImage: String, title: String) -> some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(model.accentColor.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(model.accentColor)
            }

            Text(title)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.75))

            Spacer()
        }
    }

    private func genderPill(_ gender: Gender, icon: String) -> some View {
        let isSelected = selectedGender == gender

        return Button {
            selectedGender = gender
        } label: {
            HStack(spacing: 8) {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(isSelected ? .white : Color.black.opacity(0.35))

                Text(gender.rawValue)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(isSelected ? .white : Color.black.opacity(0.65))
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(isSelected ? model.accentColor : Color.black.opacity(0.06))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var saveBar: some View {
        VStack(spacing: 0) {
            Button(action: save) {
                Text(isSubmitting ? "Please wait..." : model.saveTitle)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(model.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
            .disabled(isSubmitting)
            .padding(.horizontal, 22)
            .padding(.bottom, 14)
            .padding(.top, 10)
            .background(model.backgroundColor)
        }
    }

    private func save() {
        errorMessage = nil

        let trimmed = fullName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            errorMessage = "Please enter full name."
            return
        }

        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        let iso = formatter.string(from: dob)

        isSubmitting = true
        Task {
            defer { Task { @MainActor in isSubmitting = false } }
            do {
                try await ChildProfilesRepository().insertChild(
                    momUserId: mom.userId,
                    fullName: trimmed,
                    birthDateISO: iso,
                    gender: selectedGender.rawValue.lowercased(),
                    deliveryMethod: deliveryMethod.isEmpty ? "Spontaneous Vaginal Delivery (SVD)" : deliveryMethod,
                    notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                    idPhotoPath: nil,
                    photoData: selectedPhotoData,
                    accessToken: session.accessToken
                )

                await MainActor.run {
                    onSaved()
                    dismiss()
                }
            } catch SupabaseServiceError.httpError(let status, let body) {
                await MainActor.run {
                    errorMessage = "Save failed (\(status)): \(SupabaseAuthService.humanMessage(fromBody: body))"
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Save failed: \(error.localizedDescription)"
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ChildRegistrationView(
            model: ChildRegistrationController().loadModel(),
            session: AuthSessionContext(userId: UUID(), accessToken: "test"),
            mom: MomListRow(id: UUID(), userId: UUID(), fullName: "Adithya Ekanayaka", district: "Kalutara"),
            onSaved: {}
        )
    }
}
