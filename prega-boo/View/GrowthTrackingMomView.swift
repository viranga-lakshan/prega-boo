import SwiftUI
import Foundation

struct GrowthTrackingMomView: View {
    let model: GrowthTrackingMomModel
    let session: AuthSessionContext?
    let momUserId: UUID?
    let childId: UUID?
    let mode: HealthFeatureViewMode
    let ageHeadline: String?

    init(
        model: GrowthTrackingMomModel,
        session: AuthSessionContext? = nil,
        momUserId: UUID? = nil,
        childId: UUID? = nil,
        mode: HealthFeatureViewMode = .midwifeEntry,
        ageHeadline: String? = nil
    ) {
        self.model = model
        self.session = session
        self.momUserId = momUserId
        self.childId = childId
        self.mode = mode
        self.ageHeadline = ageHeadline
    }

    @Environment(\.dismiss) private var dismiss

    @State private var weightText: String = ""
    @State private var heightText: String = ""

    @State private var selectedMilestones: Set<String> = ["First Smile"]
    @State private var notes: String = ""

    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var recentWeights: [Double] = []

    @State private var rows: [GrowthRow] = [
        GrowthRow(dateText: "Today", weightText: "3.2", heightText: "50", notesPreview: "First Smile"),
        GrowthRow(dateText: "Yesterday", weightText: "3.1", heightText: "50", notesPreview: "")
    ]

    @State private var momGrowthSource: [GrowthRecord] = []
    @State private var childGrowthSource: [ChildGrowthRecord] = []
    @State private var curveShowsWeight = true

    private let milestones: [String] = [
        "First Smile",
        "Rolled Over",
        "Grasping"
    ]

    private var deepAccent: Color { Color(red: 0.35, green: 0.18, blue: 0.42) }

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

    private var midwifeRoot: some View {
        ZStack {
            model.backgroundColor
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar
                        .padding(.top, 10)

                    headerCard

                    chartCard

                    newEntryRow
                        .padding(.top, 2)

                    weightField

                    heightField

                    milestonesSection

                    notesBox

                    saveButton
                        .padding(.top, 8)

                    listSection
                        .padding(.bottom, 28)
                }
                .padding(.horizontal, 18)
            }
        }
    }

    private var momReadOnlyRoot: some View {
        ZStack {
            Color(red: 0.99, green: 0.96, blue: 0.97)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    momReadOnlyTopBar
                        .padding(.top, 8)

                    momReadOnlyTitleBlock

                    momReadOnlyMetricCards

                    momReadOnlyGrowthCurveCard

                    momReadOnlyMilestonesSection
                        .padding(.bottom, 24)
                }
                .padding(.horizontal, 18)
            }
        }
    }

    private var momReadOnlyTopBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(deepAccent)
                    .frame(width: 44, height: 44)
            }
            Spacer()
        }
    }

    private var momReadOnlyTitleBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                Text(childId == nil ? "Growth Tracking Mom" : "Growth Tracking Baby")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(deepAccent)
                Spacer()
                if let ageHeadline, !ageHeadline.isEmpty {
                    Text(ageHeadline)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(model.accentColor)
                }
            }
            Text("Tracking growth and magical milestones since birth.")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.black.opacity(0.45))
        }
    }

    private var momReadOnlyMetricCards: some View {
        HStack(spacing: 12) {
            momMetricCard(
                icon: "scalemass.fill",
                label: "CURRENT WEIGHT",
                value: latestWeightDisplay,
                delta: weightDeltaDisplay
            )
            momMetricCard(
                icon: "ruler.fill",
                label: "CURRENT HEIGHT",
                value: latestHeightDisplay,
                delta: heightDeltaDisplay
            )
        }
    }

    private func momMetricCard(icon: String, label: String, value: String, delta: String?) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(deepAccent)
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.4))
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.78))
            if let delta, !delta.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 11, weight: .bold))
                    Text(delta)
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(model.accentColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(model.accentColor.opacity(0.14))
                .clipShape(Capsule())
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
    }

    private var latestWeightDisplay: String {
        guard let w = latestWeightValue else { return "—" }
        return String(format: "%.1f kg", w)
    }

    private var latestHeightDisplay: String {
        guard let h = latestHeightValue else { return "—" }
        return String(format: "%.1f cm", h)
    }

    private var latestWeightValue: Double? {
        if childId != nil {
            return childGrowthSource.sorted { $0.measuredOn < $1.measuredOn }.last?.weightKg
        }
        return momGrowthSource.sorted { $0.measuredOn < $1.measuredOn }.last?.weightKg
    }

    private var latestHeightValue: Double? {
        if childId != nil {
            return childGrowthSource.sorted { $0.measuredOn < $1.measuredOn }.last?.heightCm
        }
        return momGrowthSource.sorted { $0.measuredOn < $1.measuredOn }.last?.heightCm
    }

    private var weightDeltaDisplay: String? {
        let vals: [Double] = {
            if childId != nil {
                return childGrowthSource.sorted { $0.measuredOn < $1.measuredOn }.map { $0.weightKg }
            }
            return momGrowthSource.sorted { $0.measuredOn < $1.measuredOn }.map { $0.weightKg }
        }()
        guard vals.count >= 2, let a = vals.dropLast().last, let b = vals.last else { return nil }
        let d = b - a
        guard abs(d) > 0.001 else { return nil }
        return String(format: "%+.1f kg", d)
    }

    private var heightDeltaDisplay: String? {
        let vals: [Double] = {
            if childId != nil {
                return childGrowthSource.sorted { $0.measuredOn < $1.measuredOn }.map { $0.heightCm }
            }
            return momGrowthSource.sorted { $0.measuredOn < $1.measuredOn }.map { $0.heightCm }
        }()
        guard vals.count >= 2, let a = vals.dropLast().last, let b = vals.last else { return nil }
        let d = b - a
        guard abs(d) > 0.001 else { return nil }
        return String(format: "%+.1f cm", d)
    }

    private var momReadOnlyGrowthCurveCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Growth Curve")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(deepAccent)
                    Text(curveShowsWeight ? "Weight progression (from your records)" : "Height progression (from your records)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.black.opacity(0.45))
                }
                Spacer()
                HStack(spacing: 0) {
                    curveToggleButton(title: "Weight", isOn: curveShowsWeight) { curveShowsWeight = true }
                    curveToggleButton(title: "Height", isOn: !curveShowsWeight) { curveShowsWeight = false }
                }
                .padding(4)
                .background(Color.white.opacity(0.7))
                .clipShape(Capsule())
            }

            ZStack {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(model.accentColor.opacity(0.12))
                GrowthLineChart(
                    accentColor: deepAccent,
                    weights: curveShowsWeight ? curveWeights : curveHeights
                )
                .frame(height: 200)
                .padding(.horizontal, 12)
                .padding(.vertical, 14)
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    }

    private func curveToggleButton(title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(isOn ? Color.white : Color.black.opacity(0.45))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isOn ? deepAccent : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var curveWeights: [Double] {
        if childId != nil {
            return childGrowthSource.sorted { $0.measuredOn < $1.measuredOn }.map { $0.weightKg }
        }
        return momGrowthSource.sorted { $0.measuredOn < $1.measuredOn }.map { $0.weightKg }
    }

    private var curveHeights: [Double] {
        if childId != nil {
            return childGrowthSource.sorted { $0.measuredOn < $1.measuredOn }.map { $0.heightCm }
        }
        return momGrowthSource.sorted { $0.measuredOn < $1.measuredOn }.map { $0.heightCm }
    }

    private var momReadOnlyMilestonesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(model.accentColor)
                Text("Milestones")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundStyle(deepAccent)
            }

            if milestoneTimelineItems.isEmpty {
                Text("Milestones from visits will appear here when your midwife adds them.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.45))
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(milestoneTimelineItems.enumerated()), id: \.offset) { idx, item in
                        milestoneRow(item: item, isLast: idx == milestoneTimelineItems.count - 1)
                    }
                }
            }
        }
    }

    private var milestoneTimelineItems: [(date: String, title: String, body: String)] {
        var items: [(String, String, String)] = []
        if childId != nil {
            for r in childGrowthSource.sorted(by: { $0.measuredOn < $1.measuredOn }) {
                let date = displayDate(fromISO: r.measuredOn)
                if let m = r.milestones, !m.isEmpty {
                    for part in m.split(separator: ",") {
                        let t = String(part).trimmingCharacters(in: .whitespacesAndNewlines)
                        if !t.isEmpty {
                            items.append((date, t, r.notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""))
                        }
                    }
                } else if let n = r.notes, !n.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    items.append((date, "Growth visit", n))
                }
            }
        } else {
            for r in momGrowthSource.sorted(by: { $0.measuredOn < $1.measuredOn }) {
                let date = displayDate(fromISO: r.measuredOn)
                if let m = r.milestones, !m.isEmpty {
                    for part in m.split(separator: ",") {
                        let t = String(part).trimmingCharacters(in: .whitespacesAndNewlines)
                        if !t.isEmpty {
                            items.append((date, t, r.notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""))
                        }
                    }
                } else if let n = r.notes, !n.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    items.append((date, "Visit note", n))
                }
            }
        }
        return items.reversed()
    }

    private func milestoneRow(item: (date: String, title: String, body: String), isLast: Bool) -> some View {
        HStack(alignment: .top, spacing: 14) {
            VStack(spacing: 0) {
                Circle()
                    .fill(model.accentColor)
                    .frame(width: 12, height: 12)
                if !isLast {
                    Rectangle()
                        .fill(model.accentColor.opacity(0.25))
                        .frame(width: 2)
                        .frame(minHeight: 36)
                }
            }
            .frame(width: 12)

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(deepAccent)
                Text(item.date)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.4))
                if !item.body.isEmpty {
                    Text(item.body)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.black.opacity(0.55))
                }
            }
            .padding(.bottom, isLast ? 0 : 18)
            Spacer(minLength: 0)
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

            ZStack {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.65))
                    .frame(width: 62, height: 62)

                Image(systemName: "figure.pregnant")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(model.accentColor)
            }
        }
    }

    private var headerCard: some View {
        Text(childId == nil ? model.title : "Growth Tracking\nBaby")
            .font(.system(size: 42, weight: .bold, design: .rounded))
            .foregroundStyle(Color.black.opacity(0.78))
            .padding(.horizontal, 6)
            .padding(.top, 4)
            .padding(.bottom, 6)
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(model.cardTitle)
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.75))

                    Text(model.cardSubtitle)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(Color.black.opacity(0.45))
                }

                Spacer(minLength: 0)

                HStack(spacing: 8) {
                    Circle()
                        .fill(model.accentColor)
                        .frame(width: 6, height: 6)

                    Text(model.cardBadgeTitle)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.black.opacity(0.55))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.7))
                .clipShape(Capsule())
            }

            ZStack {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color.white)
                    .frame(height: 220)

                GrowthLineChart(accentColor: model.accentColor, weights: recentWeights)
                    .frame(height: 200)
                    .padding(.horizontal, 12)
            }
        }
        .padding(18)
        .background(Color.white.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var newEntryRow: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(model.accentColor.opacity(0.18))
                    .frame(width: 44, height: 44)

                Image(systemName: "square.and.pencil")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(model.accentColor)
            }

            Text(model.newEntryTitle)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.75))

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Color.black.opacity(0.25))
        }
    }

    private var weightField: some View {
        labeledUnitField(label: model.weightLabel, unit: model.weightUnit, text: $weightText)
    }

    private var heightField: some View {
        labeledUnitField(label: model.heightLabel, unit: model.heightUnit, text: $heightText)
    }

    private func labeledUnitField(label: String, unit: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(label)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.55))

            HStack {
                TextField("0", text: text)
                    .keyboardType(.decimalPad)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 16)

                Text(unit)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.black.opacity(0.45))
                    .padding(.trailing, 16)
            }
            .background(model.accentColor.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(model.milestonesTitle)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.55))

            HStack(spacing: 10) {
                    ForEach(milestones, id: \.self) { m in
                    milestonePill(title: m)
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func milestonePill(title: String) -> some View {
        let isSelected = selectedMilestones.contains(title)

        return Button {
            if isSelected {
                selectedMilestones.remove(title)
            } else {
                selectedMilestones.insert(title)
            }
        } label: {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(isSelected ? Color.black.opacity(0.75) : Color.black.opacity(0.55))
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? model.accentColor.opacity(0.25) : Color.white.opacity(0.75))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var notesBox: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $notes)
                .frame(minHeight: 140)
                .padding(14)
                .background(model.accentColor.opacity(0.10))
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            if notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(model.notesPlaceholder)
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(Color.black.opacity(0.30))
                    .padding(.horizontal, 22)
                    .padding(.vertical, 22)
            }
        }
    }

    private var saveButton: some View {
        Button(action: saveGrowth) {
            Text(model.saveButtonTitle)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background(model.accentColor.opacity(0.85))
                .clipShape(Capsule())
        }
        .disabled(isLoading)
    }

    private var listSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Recent Entries")
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(Color.black.opacity(0.8))

            columnHeaders

            VStack(spacing: 0) {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                }

                if rows.isEmpty, !isLoading {
                    Text("No records yet")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.45))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                } else {
                    ForEach(rows) { row in
                        growthRow(row)
                        Divider().opacity(0.25)
                    }
                }
            }
            .background(Color.white.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
    }

    private var columnHeaders: some View {
        HStack {
            Text("Date")
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Weight")
                .frame(width: 80, alignment: .leading)

            Text("Height")
                .frame(width: 80, alignment: .leading)

            Color.clear
                .frame(width: 22)
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(Color.black.opacity(0.4))
        .padding(.horizontal, 14)
        .padding(.top, 2)
    }

    private func growthRow(_ row: GrowthRow) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(row.dateText)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.black.opacity(0.75))

                if !row.notesPreview.isEmpty {
                    Text(row.notesPreview)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.45))
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(row.weightText)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Color.black.opacity(0.75))
                .frame(width: 80, alignment: .leading)

            Text(row.heightText)
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

    private func loadFromDatabaseIfPossible() {
        guard let session else { return }

        rows = []
        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                if let childId {
                    let records = try await ChildGrowthRecordsRepository().fetchRecords(
                        childId: childId,
                        accessToken: session.accessToken
                    )
                    applyDatabaseRecords(records)
                } else if let momUserId {
                    let records = try await GrowthRecordsRepository().fetchRecords(
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

    private func saveGrowth() {
        errorMessage = nil

        let trimmedWeight = weightText.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedHeight = heightText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let weightKg = Double(trimmedWeight), let heightCm = Double(trimmedHeight) else {
            errorMessage = "Please enter valid weight and height."
            return
        }

        guard let session else {
            let preview = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            let dateText = "Today"

            rows.insert(
                GrowthRow(
                    dateText: dateText,
                    weightText: String(format: "%.1f", weightKg),
                    heightText: String(format: "%.0f", heightCm),
                    notesPreview: preview
                ),
                at: 0
            )

            recentWeights = rows
                .compactMap { Double($0.weightText) }
                .prefix(5)
                .reversed()

            weightText = ""
            heightText = ""
            notes = ""
            return
        }

        if let childId {
            isLoading = true
            Task {
                defer { isLoading = false }
                do {
                    let milestonesText = selectedMilestones.sorted().joined(separator: ", ")

                    try await ChildGrowthRecordsRepository().insertRecord(
                        childId: childId,
                        createdByUserId: session.userId,
                        measuredOnISO: isoDate(Date()),
                        weightKg: weightKg,
                        heightCm: heightCm,
                        milestones: milestonesText,
                        notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                        accessToken: session.accessToken
                    )

                    weightText = ""
                    heightText = ""
                    notes = ""

                    let records = try await ChildGrowthRecordsRepository().fetchRecords(
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
            let preview = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            let dateText = "Today"

            rows.insert(
                GrowthRow(
                    dateText: dateText,
                    weightText: String(format: "%.1f", weightKg),
                    heightText: String(format: "%.0f", heightCm),
                    notesPreview: preview
                ),
                at: 0
            )

            recentWeights = rows
                .compactMap { Double($0.weightText) }
                .prefix(5)
                .reversed()

            weightText = ""
            heightText = ""
            notes = ""
            return
        }

        isLoading = true
        Task {
            defer { isLoading = false }
            do {
                let milestonesText = selectedMilestones.sorted().joined(separator: ", ")

                try await GrowthRecordsRepository().insertRecord(
                    momUserId: momUserId,
                    createdByUserId: session.userId,
                    measuredOnISO: isoDate(Date()),
                    weightKg: weightKg,
                    heightCm: heightCm,
                    milestones: milestonesText,
                    notes: notes.trimmingCharacters(in: .whitespacesAndNewlines),
                    accessToken: session.accessToken
                )

                weightText = ""
                heightText = ""
                notes = ""

                let records = try await GrowthRecordsRepository().fetchRecords(
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

    private func applyDatabaseRecords(_ records: [GrowthRecord]) {
        momGrowthSource = records
        rows = records.map { record in
            GrowthRow(
                dateText: displayDate(fromISO: record.measuredOn),
                weightText: String(format: "%.1f", record.weightKg),
                heightText: String(format: "%.0f", record.heightCm),
                notesPreview: record.notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            )
        }
        recentWeights = records.prefix(5).map { $0.weightKg }.reversed()
    }

    private func applyDatabaseRecords(_ records: [ChildGrowthRecord]) {
        childGrowthSource = records
        rows = records.map { record in
            GrowthRow(
                dateText: displayDate(fromISO: record.measuredOn),
                weightText: String(format: "%.1f", record.weightKg),
                heightText: String(format: "%.0f", record.heightCm),
                notesPreview: record.notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            )
        }
        recentWeights = records.prefix(5).map { $0.weightKg }.reversed()
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

    private func isoDate(_ date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: date)
    }
}

private struct GrowthRow: Identifiable, Hashable {
    let id = UUID()
    let dateText: String
    let weightText: String
    let heightText: String
    let notesPreview: String
}

private struct GrowthLineChart: View {
    let accentColor: Color
    let weights: [Double]

    init(accentColor: Color, weights: [Double] = []) {
        self.accentColor = accentColor
        self.weights = weights
    }

    var body: some View {
        GeometryReader { proxy in
            let w = proxy.size.width
            let h = proxy.size.height

            ZStack {
                VStack(spacing: 0) {
                    Divider().opacity(0.15)
                    Spacer()
                    Divider().opacity(0.15)
                    Spacer()
                    Divider().opacity(0.15)
                }

                let points: [CGPoint] = {
                    // If we have recent weights, plot them; otherwise use a static placeholder.
                    guard weights.count >= 2 else {
                        return [
                            CGPoint(x: 0.0 * w, y: 0.72 * h),
                            CGPoint(x: 0.28 * w, y: 0.54 * h),
                            CGPoint(x: 0.55 * w, y: 0.43 * h),
                            CGPoint(x: 0.78 * w, y: 0.32 * h),
                            CGPoint(x: 1.0 * w, y: 0.28 * h)
                        ]
                    }

                    let minW = weights.min() ?? 0
                    let maxW = weights.max() ?? 1
                    let denom = max(maxW - minW, 0.0001)

                    return weights.enumerated().map { idx, value in
                        let t = CGFloat(idx) / CGFloat(max(weights.count - 1, 1))
                        let normalized = CGFloat((value - minW) / denom)
                        // invert y so larger weight is higher on screen
                        let y = (1.0 - normalized) * (0.70 * h) + (0.10 * h)
                        return CGPoint(x: t * w, y: y)
                    }
                }()

                Path { path in
                    path.move(to: points[0])
                    for p in points.dropFirst() {
                        path.addLine(to: p)
                    }
                }
                .stroke(accentColor, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                ForEach(Array(points.dropFirst().enumerated()), id: \.offset) { _, p in
                    Circle()
                        .fill(accentColor)
                        .frame(width: 10, height: 10)
                        .position(x: p.x, y: p.y)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        GrowthTrackingMomView(model: GrowthTrackingMomController().loadModel())
    }
}
