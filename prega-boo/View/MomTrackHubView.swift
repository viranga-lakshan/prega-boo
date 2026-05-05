import SwiftUI

struct MomTrackHubView: View {
    let accentColor: Color
    let backgroundColor: Color
    let session: AuthSessionContext?

    @State private var selectedKind: MomTrackerKind?

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("Tracking tools")
                        .font(.system(size: 38, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.8))
                        .padding(.top, 4)

                    ForEach(MomTrackerKind.allCases) { kind in
                        Button {
                            selectedKind = kind
                        } label: {
                            trackerCard(kind)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
            }
        }
        .background(
            NavigationLink(
                destination: Group {
                    if let kind = selectedKind {
                        MomTrackerEntryView(kind: kind, accentColor: accentColor, backgroundColor: backgroundColor, session: session)
                    } else {
                        EmptyView()
                    }
                },
                isActive: Binding(
                    get: { selectedKind != nil },
                    set: { if !$0 { selectedKind = nil } }
                )
            ) { EmptyView() }
        )
    }

    private func trackerCard(_ kind: MomTrackerKind) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 10) {
                Text(kind.title)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.8))
                    .multilineTextAlignment(.leading)
                Text(trackerSubtitle(kind))
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.52))
                    .lineLimit(1)
                Text(kind.cta)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(accentColor)
                    .clipShape(Capsule())
            }
            Spacer()
            ZStack {
                Circle()
                    .fill(accentColor.opacity(0.12))
                    .frame(width: 60, height: 60)
                Image(systemName: trackerIcon(kind))
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(accentColor)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, minHeight: 132)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(Color.white.opacity(0.96))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .stroke(accentColor.opacity(0.16), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
    }

    private func trackerIcon(_ kind: MomTrackerKind) -> String {
        switch kind {
        case .weight: return "scalemass.fill"
        case .kick: return "figure.pregnant"
        case .pregnancy: return "calendar.badge.clock"
        case .mood: return "face.smiling.fill"
        }
    }

    private func trackerSubtitle(_ kind: MomTrackerKind) -> String {
        switch kind {
        case .weight: return "Track healthy weight progress"
        case .kick: return "Monitor baby movement counts"
        case .pregnancy: return "Weekly progress and milestones"
        case .mood: return "Record daily emotional wellbeing"
        }
    }
}

private struct MomTrackerEntryView: View {
    let kind: MomTrackerKind
    let accentColor: Color
    let backgroundColor: Color
    let session: AuthSessionContext?

    @Environment(\.dismiss) private var dismiss

    @State private var entryDate = Date()
    @State private var numberInput = ""
    @State private var textInput = ""
    @State private var note = ""
    @State private var items: [MomTrackEntry] = []
    @State private var isLoading = false
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    topBar
                    formCard
                    historyCard
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 10)
            }
        }
        .navigationBarBackButtonHidden(true)
        .task { await reload() }
        .alert(
            "Tracker",
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

    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(accentColor)
                    .frame(width: 44, height: 44)
            }
            Text(kind.title)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.8))
            Spacer()
        }
    }

    private var formCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            DatePicker("Date", selection: $entryDate, displayedComponents: .date)

            switch kind {
            case .weight:
                TextField("Weight in kg", text: $numberInput)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
            case .kick:
                TextField("Kick count", text: $numberInput)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
            case .pregnancy:
                TextField("Week / progress note", text: $textInput)
                    .textFieldStyle(.roundedBorder)
            case .mood:
                Picker("Mood", selection: $textInput) {
                    Text("Happy").tag("Happy")
                    Text("Calm").tag("Calm")
                    Text("Tired").tag("Tired")
                    Text("Stressed").tag("Stressed")
                    Text("Anxious").tag("Anxious")
                }
                .pickerStyle(.segmented)
            }

            TextField("Notes (optional)", text: $note)
                .textFieldStyle(.roundedBorder)

            Button(action: { Task { await save() } }) {
                Text(isSaving ? "Saving..." : "Save \(kind.title)")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .disabled(isSaving)
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("History")
                .font(.system(size: 18, weight: .bold, design: .rounded))
            if isLoading {
                ProgressView()
            } else if items.isEmpty {
                Text("No entries yet.")
                    .foregroundStyle(Color.black.opacity(0.45))
            } else {
                ForEach(items.prefix(20)) { row in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(historyMainValue(row))
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(Color.black.opacity(0.78))
                            Text(row.entryDate)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.black.opacity(0.45))
                        }
                        Spacer()
                    }
                    .padding(.vertical, 6)
                    Divider()
                }
            }
        }
        .padding(14)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func historyMainValue(_ row: MomTrackEntry) -> String {
        switch kind {
        case .weight:
            if let n = row.valueNumeric { return String(format: "%.1f kg", n) }
            return row.valueText ?? "Weight logged"
        case .kick:
            if let n = row.valueNumeric { return "\(Int(n)) kicks" }
            return row.valueText ?? "Kick count logged"
        case .pregnancy:
            return row.valueText ?? "Pregnancy progress logged"
        case .mood:
            return row.valueText ?? "Mood logged"
        }
    }

    private func reload() async {
        guard let session else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            items = try await MomTrackRepository().fetchEntries(
                momUserId: session.userId,
                kind: kind,
                accessToken: session.accessToken
            )
        } catch {
            errorMessage = "Could not load tracker entries."
            items = []
        }
    }

    private func save() async {
        guard let session else {
            errorMessage = "Sign in required."
            return
        }
        let iso = MomRemindersDataService.localCalendarDayISO(from: entryDate)

        let numericValue: Double?
        let textValue: String?
        switch kind {
        case .weight:
            numericValue = Double(numberInput.trimmingCharacters(in: .whitespacesAndNewlines))
            textValue = nil
            guard numericValue != nil else {
                errorMessage = "Enter valid weight."
                return
            }
        case .kick:
            numericValue = Double(numberInput.trimmingCharacters(in: .whitespacesAndNewlines))
            textValue = nil
            guard numericValue != nil else {
                errorMessage = "Enter valid kick count."
                return
            }
        case .pregnancy:
            numericValue = nil
            textValue = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
            guard let textValue, !textValue.isEmpty else {
                errorMessage = "Enter pregnancy update."
                return
            }
        case .mood:
            numericValue = nil
            let trimmed = textInput.trimmingCharacters(in: .whitespacesAndNewlines)
            textValue = trimmed.isEmpty ? "Happy" : trimmed
        }

        isSaving = true
        defer { isSaving = false }
        do {
            try await MomTrackRepository().insertEntry(
                momUserId: session.userId,
                kind: kind,
                entryDateISO: iso,
                valueNumeric: numericValue,
                valueText: textValue,
                note: note.trimmingCharacters(in: .whitespacesAndNewlines),
                accessToken: session.accessToken
            )
            numberInput = ""
            textInput = ""
            note = ""
            await reload()
        } catch SupabaseServiceError.httpError(let status, let body) {
            errorMessage = "Save failed (\(status)): \(SupabaseAuthService.humanMessage(fromBody: body))"
        } catch {
            errorMessage = "Save failed: \(error.localizedDescription)"
        }
    }
}
