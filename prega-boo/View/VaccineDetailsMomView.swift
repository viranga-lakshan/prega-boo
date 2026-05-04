import SwiftUI

struct VaccineDetailsMomView: View {
    let model: VaccineDetailsMomModel
    let session: AuthSessionContext?
    let momUserId: UUID?
    let childId: UUID?

    init(model: VaccineDetailsMomModel, session: AuthSessionContext? = nil, momUserId: UUID? = nil, childId: UUID? = nil) {
        self.model = model
        self.session = session
        self.momUserId = momUserId
        self.childId = childId
    }

    @Environment(\.dismiss) private var dismiss

    @State private var vaccineName = ""
    @State private var dosage = ""

    @State private var isLoading = false
    @State private var errorMessage: String?

    @State private var vaccines: [VaccineRow] = [
        VaccineRow(dateText: "Today", name: "Rotavirus", dosage: "30mm"),
        VaccineRow(dateText: "01 October", name: "MMR.", dosage: "20mm")
    ]

    var body: some View {
        ZStack {
            model.backgroundColor
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                        .padding(.top, 10)

                    headerCard

                    formCard

                    listSection
                        .padding(.bottom, 28)
                }
                .padding(.horizontal, 18)
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear { loadFromDatabaseIfPossible() }
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
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.85))
                        .frame(width: 46, height: 46)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.45))
                }
            }

            Spacer()
        }
    }

    private var headerCard: some View {
        ZStack(alignment: .bottomLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color.white.opacity(0.55))

            HStack(alignment: .bottom, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(childId == nil ? model.title : "Vaccine Details Baby")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.8))
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 0)

                ZStack {
                    Circle()
                        .fill(model.accentColor.opacity(0.18))
                        .frame(width: 110, height: 110)

                    Circle()
                        .fill(model.accentColor)
                        .frame(width: 92, height: 92)

                    Image(systemName: "syringe")
                        .font(.system(size: 40, weight: .bold))
                        .foregroundStyle(.white)
                        .offset(x: -4, y: -2)

                    Image(systemName: "cross.vial")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(.white.opacity(0.95))
                        .offset(x: 24, y: 20)
                }
                .padding(.bottom, 6)
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity)
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            labeledField(label: model.vaccineNameLabel) {
                TextField(model.vaccineNamePlaceholder, text: $vaccineName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled(true)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .clipShape(Capsule())
            }

            Divider().opacity(0.25)

            labeledField(label: model.dosageLabel) {
                TextField(model.dosagePlaceholder, text: $dosage)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(true)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white)
                    .clipShape(Capsule())
            }

            Button(action: addVaccine) {
                Text(model.addButtonTitle)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 190)
                    .padding(.vertical, 16)
                    .background(model.accentColor.opacity(0.85))
                    .clipShape(Capsule())
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 6)
        }
        .padding(18)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func labeledField<Content: View>(label: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.75))

            content()
        }
    }

    private var listSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(model.listTitle)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.8))

            columnHeaders

            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
                ForEach(vaccines) { row in
                    vaccineRow(row)
                    Divider().opacity(0.25)
                }
            }
            .background(Color.white.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var columnHeaders: some View {
        HStack {
            Text(model.dateColumnTitle)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(model.nameColumnTitle)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(model.dosageColumnTitle)
                .frame(width: 80, alignment: .leading)

            Color.clear
                .frame(width: 22)
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(Color.black.opacity(0.4))
        .padding(.horizontal, 14)
        .padding(.top, 2)
    }

    private func vaccineRow(_ row: VaccineRow) -> some View {
        HStack {
            Text(row.dateText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.75))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(row.name)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.75))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(row.dosage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.75))
                .frame(width: 80, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.25))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }

    private func addVaccine() {
        let trimmedName = vaccineName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedDosage = dosage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty, !trimmedDosage.isEmpty else { return }

        guard let session else {
            vaccines.insert(
                VaccineRow(dateText: "Today", name: trimmedName, dosage: trimmedDosage),
                at: 0
            )
            vaccineName = ""
            dosage = ""
            return
        }

        if let childId {
            isLoading = true
            Task {
                defer { isLoading = false }
                do {
                    let todayISO = isoDate(Date())
                    try await ChildVaccineRecordsRepository().insertRecord(
                        childId: childId,
                        createdByUserId: session.userId,
                        administeredOnISO: todayISO,
                        vaccineName: trimmedName,
                        dosage: trimmedDosage,
                        accessToken: session.accessToken
                    )

                    vaccineName = ""
                    dosage = ""

                    try await reloadChildRecords(childId: childId, accessToken: session.accessToken)
                } catch SupabaseServiceError.httpError(let status, let body) {
                    errorMessage = "Save failed (\(status)): \(SupabaseAuthService.humanMessage(fromBody: body))"
                } catch {
                    errorMessage = "Save failed: \(error.localizedDescription)"
                }
            }
            return
        }

        guard let momUserId else {
            vaccines.insert(
                VaccineRow(dateText: "Today", name: trimmedName, dosage: trimmedDosage),
                at: 0
            )
            vaccineName = ""
            dosage = ""
            return
        }

        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let todayISO = isoDate(Date())
                try await VaccineRecordsRepository().insertRecord(
                    momUserId: momUserId,
                    createdByUserId: session.userId,
                    vaccineName: trimmedName,
                    dosage: trimmedDosage,
                    administeredOnISO: todayISO,
                    accessToken: session.accessToken
                )

                vaccineName = ""
                dosage = ""

                try await reloadMomRecords(momUserId: momUserId, accessToken: session.accessToken)
            } catch SupabaseServiceError.httpError(let status, let body) {
                errorMessage = "Save failed (\(status)): \(SupabaseAuthService.humanMessage(fromBody: body))"
            } catch {
                errorMessage = "Save failed: \(error.localizedDescription)"
            }
        }
    }

    private func loadFromDatabaseIfPossible() {
        guard let session else { return }
        vaccines = []
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                if let childId {
                    try await reloadChildRecords(childId: childId, accessToken: session.accessToken)
                } else if let momUserId {
                    try await reloadMomRecords(momUserId: momUserId, accessToken: session.accessToken)
                }
            } catch SupabaseServiceError.httpError(let status, let body) {
                errorMessage = "Load failed (\(status)): \(SupabaseAuthService.humanMessage(fromBody: body))"
            } catch {
                errorMessage = "Load failed: \(error.localizedDescription)"
            }
        }
    }

    private func reloadMomRecords(momUserId: UUID, accessToken: String) async throws {
        let records = try await VaccineRecordsRepository().fetchRecords(momUserId: momUserId, accessToken: accessToken)
        vaccines = records.map {
            VaccineRow(
                id: $0.id,
                dateText: displayDate(iso: $0.administeredOn),
                name: $0.vaccineName,
                dosage: $0.dosage
            )
        }
    }

    private func reloadChildRecords(childId: UUID, accessToken: String) async throws {
        let records = try await ChildVaccineRecordsRepository().fetchRecords(childId: childId, accessToken: accessToken)
        vaccines = records.map {
            VaccineRow(
                id: $0.id,
                dateText: displayDate(iso: $0.administeredOn),
                name: $0.vaccineName,
                dosage: $0.dosage
            )
        }
    }

    private func isoDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: date)
    }

    private func displayDate(iso: String) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd"

        let out = DateFormatter()
        out.locale = Locale(identifier: "en_US_POSIX")
        out.dateFormat = "dd MMMM"

        guard let date = df.date(from: iso) else { return iso }
        if Calendar.current.isDateInToday(date) { return "Today" }
        return out.string(from: date)
    }
}

#Preview {
    NavigationStack {
        VaccineDetailsMomView(model: VaccineDetailsMomController().loadModel())
    }
}
