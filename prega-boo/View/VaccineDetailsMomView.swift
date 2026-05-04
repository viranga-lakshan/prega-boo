import SwiftUI

struct VaccineDetailsMomView: View {
    let model: VaccineDetailsMomModel
    let session: AuthSessionContext?
    let momUserId: UUID?
    let childId: UUID?
    let mode: HealthFeatureViewMode

    init(
        model: VaccineDetailsMomModel,
        session: AuthSessionContext? = nil,
        momUserId: UUID? = nil,
        childId: UUID? = nil,
        mode: HealthFeatureViewMode = .midwifeEntry
    ) {
        self.model = model
        self.session = session
        self.momUserId = momUserId
        self.childId = childId
        self.mode = mode
    }

    @Environment(\.dismiss) private var dismiss

    @State private var vaccineName = ""
    @State private var dosage = ""

    @State private var isLoading = false
    @State private var errorMessage: String?

    @State private var vaccines: [VaccineRow] = []

    private var deepMaroon: Color { Color(red: 0.45, green: 0.12, blue: 0.24) }

    var body: some View {
        Group {
            if mode == .momReadOnly {
                momReadOnlyRoot
            } else {
                midwifeRoot
            }
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            if mode == .midwifeEntry, vaccines.isEmpty, session == nil {
                vaccines = [
                    VaccineRow(dateText: "Today", name: "Rotavirus", dosage: "Dose 1 • Oral"),
                    VaccineRow(dateText: "01 October", name: "MMR", dosage: "Booster")
                ]
            }
            loadFromDatabaseIfPossible()
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

    private var midwifeRoot: some View {
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
    }

    private var momReadOnlyRoot: some View {
        ZStack {
            Color(red: 0.99, green: 0.97, blue: 0.98)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(deepMaroon)
                                .frame(width: 44, height: 44)
                        }
                        Spacer()
                    }
                    .padding(.top, 8)

                    Text("HEALTH PASSPORT")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(model.accentColor)

                    Text(childId == nil ? "Vaccination History Mom" : "Vaccination History Baby")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.82))

                    Text("A verified record of immunizations entered by your care team in Prega Boo.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.45))

                    statusSummaryCard

                    totalDosesCard

                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding()
                    }

                    ForEach(vaccines) { v in
                        momVaccineCard(v)
                    }

                    Spacer().frame(height: 24)
                }
                .padding(.horizontal, 18)
            }
        }
    }

    private var statusSummaryCard: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: "checkmark.shield.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(deepMaroon)
            VStack(alignment: .leading, spacing: 6) {
                Text(vaccines.isEmpty ? "No doses on file yet" : "Protection record")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(deepMaroon)
                Text(
                    vaccines.isEmpty
                        ? "When your midwife adds vaccines, they will appear here."
                        : "You have \(vaccines.count) dose(s) recorded. Keep following your clinic schedule."
                )
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.45))
            }
            Spacer(minLength: 0)
        }
        .padding(18)
        .background(model.accentColor.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var totalDosesCard: some View {
        VStack(spacing: 8) {
            Text(String(format: "%02d", vaccines.count))
                .font(.system(size: 42, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("TOTAL DOSES")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(.white.opacity(0.9))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(deepMaroon)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private func momVaccineCard(_ row: VaccineRow) -> some View {
        let parts = doseAndRoute(from: row.dosage)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(model.accentColor.opacity(0.15))
                    .frame(width: 48, height: 48)
                    .overlay(
                        Image(systemName: "syringe.fill")
                            .foregroundStyle(deepMaroon)
                    )

                VStack(alignment: .leading, spacing: 8) {
                    Text(row.name)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.82))

                    HStack(spacing: 8) {
                        Text(parts.doseTag)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(model.accentColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(model.accentColor.opacity(0.12))
                            .clipShape(Capsule())

                        Text("•")
                            .foregroundStyle(Color.black.opacity(0.25))

                        Text(parts.route)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.black.opacity(0.4))
                    }

                    Text(displayDateLongFromRow(row.dateText))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.black.opacity(0.78))

                    Text("Recorded in Prega Boo by your care provider.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.4))
                }
                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
    }

    private func doseAndRoute(from dosage: String) -> (doseTag: String, route: String) {
        let lower = dosage.lowercased()
        let route: String
        if lower.contains("oral") { route = "Oral" }
        else if lower.contains("im") || lower.contains("intramuscular") { route = "Intramuscular" }
        else if lower.contains("injection") { route = "Injection" }
        else { route = "As recorded" }

        if dosage.localizedCaseInsensitiveContains("dose") || dosage.localizedCaseInsensitiveContains("booster") {
            return (dosage, route)
        }
        return ("Dose recorded", route)
    }

    /// Row date is already formatted; keep readable.
    private func displayDateLongFromRow(_ dateText: String) -> String {
        dateText
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
                dateText: displayDateMedium(iso: $0.administeredOn),
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
                dateText: displayDateMedium(iso: $0.administeredOn),
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

    private func displayDateMedium(iso: String) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd"
        let out = DateFormatter()
        out.locale = Locale(identifier: "en_US_POSIX")
        out.dateFormat = "MMM d, yyyy"
        guard let date = df.date(from: iso) else { return iso }
        return out.string(from: date)
    }
}

#Preview {
    NavigationStack {
        VaccineDetailsMomView(model: VaccineDetailsMomController().loadModel())
    }
}
