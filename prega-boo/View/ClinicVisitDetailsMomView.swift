import SwiftUI
import Foundation

struct ClinicVisitDetailsMomView: View {
    let model: ClinicVisitDetailsMomModel
    let session: AuthSessionContext?
    let momUserId: UUID?
    let childId: UUID?
    let mode: HealthFeatureViewMode

    init(
        model: ClinicVisitDetailsMomModel,
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

    @State private var visitDate = Date()

    @State private var hour: Int = 10
    @State private var minute: Int = 0
    @State private var meridiem: String = "AM"

    @State private var purpose: String = ""

    @State private var isLoading = false
    @State private var errorMessage: String?

    /// Midwife table / local inserts
    @State private var visits: [ClinicVisitRow] = []
    /// Mom read-only: next upcoming (by visit date)
    @State private var nextAppointment: ClinicVisitRow?
    /// Mom read-only: past visits, newest first
    @State private var historyVisits: [ClinicVisitRow] = []

    private let meridiems = ["AM", "PM"]
    private let hours = Array(1...12)
    private let minutes = stride(from: 0, through: 55, by: 5).map { $0 }

    private var deepMaroon: Color { Color(red: 0.42, green: 0.11, blue: 0.20) }

    private var screenTitle: String {
        if childId == nil {
            return "Clinic Visits Mom"
        }
        return "Clinic Visits Baby"
    }

    var body: some View {
        Group {
            if mode == .momReadOnly {
                momReadOnlyRoot
            } else {
                midwifeRoot
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

    // MARK: - Mom read-only (Health Passport style)

    private var momReadOnlyRoot: some View {
        ZStack {
            model.backgroundColor
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    momReadOnlyTopBar
                        .padding(.top, 10)

                    Text("NEXT APPOINTMENT")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(model.accentColor)
                        .tracking(0.8)

                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 24)
                    } else if let next = nextAppointment {
                        nextAppointmentCard(next)
                    } else {
                        noNextAppointmentCard
                    }

                    Text("HISTORY")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.38))
                        .tracking(0.8)
                        .padding(.top, 8)

                    if historyVisits.isEmpty, !isLoading {
                        Text("No past visits on file yet.")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(Color.black.opacity(0.45))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.vertical, 8)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(historyVisits) { row in
                                historyRow(row)
                            }
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 28)
            }
        }
    }

    private var momReadOnlyTopBar: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(deepMaroon)
                }
                Spacer()
            }

            Text(screenTitle)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(deepMaroon)
        }
    }

    private func nextAppointmentCard(_ row: ClinicVisitRow) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Text(visitCategoryTag(row.purpose))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(model.accentColor)
                    .clipShape(Capsule())

                Spacer(minLength: 12)

                VStack(alignment: .trailing, spacing: 4) {
                    Text(row.timeText)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(deepMaroon)
                    if let iso = row.visitDateISO {
                        Text(formatAppointmentHeaderDate(iso: iso))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.black.opacity(0.45))
                    }
                }
            }

            Text(row.purpose)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(deepMaroon)
                .fixedSize(horizontal: false, vertical: true)

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "cross.case.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(deepMaroon)
                    .frame(width: 28, alignment: .leading)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Your care team")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(deepMaroon)
                    Text("Visit details are kept in your Health Passport. Ask your clinic if you need the exact provider or location.")
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color.black.opacity(0.45))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(model.accentColor.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(18)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
    }

    private var noNextAppointmentCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("No upcoming visit")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(deepMaroon)
            Text("There isn’t a future clinic visit on file. Past visits appear below.")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.black.opacity(0.45))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.9))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private func historyRow(_ row: ClinicVisitRow) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(Color.white)
                    .frame(width: 56, height: 56)
                    .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)

                Text(historyDateBadge(iso: row.visitDateISO))
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(deepMaroon)
                    .multilineTextAlignment(.center)
                    .frame(width: 52)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(row.purpose)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(deepMaroon)
                    .fixedSize(horizontal: false, vertical: true)

                Text("\(row.timeText) · Completed visit")
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(Color.black.opacity(0.45))
            }

            Spacer(minLength: 0)

            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundStyle(Color.black.opacity(0.22))
        }
        .padding(14)
        .background(model.accentColor.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private func visitCategoryTag(_ purpose: String) -> String {
        let t = purpose.trimmingCharacters(in: .whitespacesAndNewlines)
        if t.isEmpty { return "VISIT" }
        let line = t.split(separator: "\n").first.map(String.init) ?? t
        let capped = line.count > 28 ? String(line.prefix(28)) + "…" : line
        return capped.uppercased()
    }

    private func formatAppointmentHeaderDate(iso: String) -> String {
        guard let d = MomHealthAgeFormatting.parseVisitDate(iso: iso) else { return "" }
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "EEEE, d MMM"
        return df.string(from: d)
    }

    private func historyDateBadge(iso: String?) -> String {
        guard let iso, let d = MomHealthAgeFormatting.parseVisitDate(iso: iso) else { return "—" }
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "MMM\ndd"
        return df.string(from: d).uppercased()
    }

    // MARK: - Midwife entry (original)

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
                Text(childId == nil ? model.title : "Clinic Visit Details Baby")
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.8))
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 0)

                ZStack {
                    Circle()
                        .fill(model.accentColor.opacity(0.18))
                        .frame(width: 120, height: 120)

                    Circle()
                        .fill(Color.white)
                        .frame(width: 98, height: 98)

                    Image(systemName: "clock")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(model.accentColor)
                }
                .padding(.bottom, 6)
            }
            .padding(18)
        }
        .frame(maxWidth: .infinity)
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(model.visitDateTitle)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.8))

            DatePicker("", selection: $visitDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .tint(model.accentColor)
                .labelsHidden()
                .padding(10)
                .background(Color.black.opacity(0.03))
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            Text(model.visitTimeTitle)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.8))
                .padding(.top, 10)

            timePickers

            Text(model.purposeTitle)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.8))
                .padding(.top, 10)

            TextField(model.purposePlaceholder, text: $purpose)
                .textInputAutocapitalization(.sentences)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white)
                .clipShape(Capsule())

            Button(action: addVisit) {
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

    private var timePickers: some View {
        HStack(spacing: 10) {
            Menu {
                ForEach(hours, id: \.self) { h in
                    Button(String(format: "%02d", h)) { hour = h }
                }
            } label: {
                timePill(text: String(format: "%02d", hour))
            }

            Text(":")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.5))

            Menu {
                ForEach(minutes, id: \.self) { m in
                    Button(String(format: "%02d", m)) { minute = m }
                }
            } label: {
                timePill(text: String(format: "%02d", minute))
            }

            Menu {
                ForEach(meridiems, id: \.self) { v in
                    Button(v) { meridiem = v }
                }
            } label: {
                timePill(text: meridiem)
            }

            Spacer(minLength: 0)
        }
    }

    private func timePill(text: String) -> some View {
        HStack(spacing: 10) {
            Text(text)
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.75))

            Image(systemName: "chevron.down")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.35))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.black.opacity(0.08), lineWidth: 1)
        )
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

                if visits.isEmpty, !isLoading {
                    Text("No visits yet")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.45))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }
                ForEach(visits) { row in
                    visitRow(row)
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

            Text(model.timeColumnTitle)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(model.purposeColumnTitle)
                .frame(maxWidth: .infinity, alignment: .leading)

            Color.clear
                .frame(width: 22)
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(Color.black.opacity(0.4))
        .padding(.horizontal, 14)
        .padding(.top, 2)
    }

    private func visitRow(_ row: ClinicVisitRow) -> some View {
        HStack {
            Text(row.dateText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.75))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(row.timeText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.75))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(row.purpose)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.75))
                .frame(maxWidth: .infinity, alignment: .leading)

            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.25))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .contentShape(Rectangle())
    }

    private func addVisit() {
        errorMessage = nil

        let trimmedPurpose = purpose.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPurpose.isEmpty else { return }

        let timeText = String(format: "%02d:%02d %@", hour, minute, meridiem.lowercased())
        let dateISO = isoDate(visitDate)

        guard let session else {
            let dateText = "Today"
            visits.insert(
                ClinicVisitRow(
                    dateText: dateText,
                    timeText: timeText,
                    purpose: trimmedPurpose,
                    visitDateISO: dateISO
                ),
                at: 0
            )
            purpose = ""
            return
        }

        if let childId {
            isLoading = true
            Task {
                defer { isLoading = false }
                do {
                    try await ChildClinicVisitRecordsRepository().insertRecord(
                        childId: childId,
                        createdByUserId: session.userId,
                        visitDateISO: dateISO,
                        visitTimeText: timeText,
                        purpose: trimmedPurpose,
                        accessToken: session.accessToken
                    )

                    purpose = ""

                    let records = try await ChildClinicVisitRecordsRepository().fetchRecords(
                        childId: childId,
                        accessToken: session.accessToken
                    )
                    applyDatabaseRecords(records)
                } catch SupabaseServiceError.httpError(let status, let body) {
                    errorMessage = "Save failed (\(status)): \(SupabaseAuthService.humanMessage(fromBody: body))"
                } catch {
                    errorMessage = "Save failed: \(error.localizedDescription)"
                }
            }
            return
        }

        guard let momUserId else {
            let dateText = "Today"
            visits.insert(
                ClinicVisitRow(
                    dateText: dateText,
                    timeText: timeText,
                    purpose: trimmedPurpose,
                    visitDateISO: dateISO
                ),
                at: 0
            )
            purpose = ""
            return
        }

        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                try await ClinicVisitRecordsRepository().insertRecord(
                    momUserId: momUserId,
                    createdByUserId: session.userId,
                    visitDateISO: dateISO,
                    visitTimeText: timeText,
                    purpose: trimmedPurpose,
                    accessToken: session.accessToken
                )

                purpose = ""

                let records = try await ClinicVisitRecordsRepository().fetchRecords(
                    momUserId: momUserId,
                    accessToken: session.accessToken
                )
                applyDatabaseRecords(records)
            } catch SupabaseServiceError.httpError(let status, let body) {
                errorMessage = "Save failed (\(status)): \(SupabaseAuthService.humanMessage(fromBody: body))"
            } catch {
                errorMessage = "Save failed: \(error.localizedDescription)"
            }
        }
    }

    private func loadFromDatabaseIfPossible() {
        guard let session else { return }

        visits = []
        nextAppointment = nil
        historyVisits = []
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                if let childId {
                    let records = try await ChildClinicVisitRecordsRepository().fetchRecords(
                        childId: childId,
                        accessToken: session.accessToken
                    )
                    applyDatabaseRecords(records)
                } else if let momUserId {
                    let records = try await ClinicVisitRecordsRepository().fetchRecords(
                        momUserId: momUserId,
                        accessToken: session.accessToken
                    )
                    applyDatabaseRecords(records)
                }
            } catch SupabaseServiceError.httpError(let status, let body) {
                errorMessage = "Load failed (\(status)): \(SupabaseAuthService.humanMessage(fromBody: body))"
            } catch {
                errorMessage = "Load failed: \(error.localizedDescription)"
            }
        }
    }

    private func applyMomReadOnlyRows(_ rows: [ClinicVisitRow]) {
        let cal = Calendar.current
        let today = cal.startOfDay(for: Date())

        let dated: [(ClinicVisitRow, Date)] = rows.compactMap { row in
            guard let iso = row.visitDateISO,
                  let d = MomHealthAgeFormatting.parseVisitDate(iso: iso) else { return nil }
            return (row, cal.startOfDay(for: d))
        }

        let future = dated.filter { $0.1 >= today }.sorted { $0.1 < $1.1 }
        let past = dated.filter { $0.1 < today }.sorted { $0.1 > $1.1 }

        nextAppointment = future.first?.0

        let undated = rows.filter { row in
            guard let iso = row.visitDateISO else { return true }
            return MomHealthAgeFormatting.parseVisitDate(iso: iso) == nil
        }

        historyVisits = past.map(\.0) + undated.reversed()
    }

    private func applyDatabaseRecords(_ records: [ClinicVisitRecord]) {
        let rows = records.map { record in
            ClinicVisitRow(
                id: record.id,
                dateText: displayDate(fromISO: record.visitDate),
                timeText: record.visitTime,
                purpose: record.purpose,
                visitDateISO: record.visitDate
            )
        }
        switch mode {
        case .momReadOnly:
            applyMomReadOnlyRows(rows)
        case .midwifeEntry:
            visits = rows.sorted { a, b in
                guard let ia = a.visitDateISO,
                      let da = MomHealthAgeFormatting.parseVisitDate(iso: ia),
                      let ib = b.visitDateISO,
                      let db = MomHealthAgeFormatting.parseVisitDate(iso: ib) else { return false }
                return da > db
            }
        }
    }

    private func applyDatabaseRecords(_ records: [ChildClinicVisitRecord]) {
        let rows = records.map { record in
            ClinicVisitRow(
                id: record.id,
                dateText: displayDate(fromISO: record.visitDate),
                timeText: record.visitTime,
                purpose: record.purpose,
                visitDateISO: record.visitDate
            )
        }
        switch mode {
        case .momReadOnly:
            applyMomReadOnlyRows(rows)
        case .midwifeEntry:
            visits = rows.sorted { a, b in
                guard let ia = a.visitDateISO,
                      let da = MomHealthAgeFormatting.parseVisitDate(iso: ia),
                      let ib = b.visitDateISO,
                      let db = MomHealthAgeFormatting.parseVisitDate(iso: ib) else { return false }
                return da > db
            }
        }
    }

    private func isoDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: date)
    }

    private func displayDate(fromISO isoDateString: String) -> String {
        let inDf = DateFormatter()
        inDf.locale = Locale(identifier: "en_US_POSIX")
        inDf.timeZone = TimeZone(secondsFromGMT: 0)
        inDf.dateFormat = "yyyy-MM-dd"

        let outDf = DateFormatter()
        outDf.locale = Locale(identifier: "en_US_POSIX")
        outDf.timeZone = TimeZone(secondsFromGMT: 0)
        outDf.dateFormat = "dd MMM"

        if let d = inDf.date(from: isoDateString) {
            return outDf.string(from: d)
        }
        return isoDateString
    }
}

#Preview {
    NavigationStack {
        ClinicVisitDetailsMomView(model: ClinicVisitDetailsMomController().loadModel())
    }
}
