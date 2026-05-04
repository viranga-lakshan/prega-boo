import SwiftUI
import Foundation

struct ClinicVisitDetailsMomView: View {
    let model: ClinicVisitDetailsMomModel
    let session: AuthSessionContext?
    let momUserId: UUID?
    let childId: UUID?

    init(model: ClinicVisitDetailsMomModel, session: AuthSessionContext? = nil, momUserId: UUID? = nil, childId: UUID? = nil) {
        self.model = model
        self.session = session
        self.momUserId = momUserId
        self.childId = childId
    }

    @Environment(\.dismiss) private var dismiss

    @State private var visitDate = Date()

    @State private var hour: Int = 10
    @State private var minute: Int = 0
    @State private var meridiem: String = "AM"

    @State private var purpose: String = ""

    @State private var isLoading = false
    @State private var errorMessage: String?

    @State private var visits: [ClinicVisitRow] = [
        ClinicVisitRow(dateText: "Today", timeText: "10:00 am", purpose: "visit"),
        ClinicVisitRow(dateText: "01 October", timeText: "MMR.", purpose: "visit")
    ]

    private let meridiems = ["AM", "PM"]
    private let hours = Array(1...12)
    private let minutes = stride(from: 0, through: 55, by: 5).map { $0 }

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

        guard let session else {
            let dateText = "Today"
            visits.insert(
                ClinicVisitRow(dateText: dateText, timeText: timeText, purpose: trimmedPurpose),
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
                        visitDateISO: isoDate(visitDate),
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
                ClinicVisitRow(dateText: dateText, timeText: timeText, purpose: trimmedPurpose),
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
                    visitDateISO: isoDate(visitDate),
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

    private func applyDatabaseRecords(_ records: [ClinicVisitRecord]) {
        visits = records.map { record in
            ClinicVisitRow(
                dateText: displayDate(fromISO: record.visitDate),
                timeText: record.visitTime,
                purpose: record.purpose
            )
        }
    }

    private func applyDatabaseRecords(_ records: [ChildClinicVisitRecord]) {
        visits = records.map { record in
            ClinicVisitRow(
                dateText: displayDate(fromISO: record.visitDate),
                timeText: record.visitTime,
                purpose: record.purpose
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
