import SwiftUI
import UIKit

/// SwiftUI bridge for `UIActivityViewController` so we can present a share sheet for a generated `.ics` file.
private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}

/// Professional event grid for the mom: month calendar with multi-color event dots, category filters, and a day events list.
/// Reuses `MomRemindersEventGridService` so it shows the same data backing the Reminders screen plus past records.
struct MomEventGridView: View {
    let backgroundColor: Color
    let accentColor: Color
    let session: AuthSessionContext?

    @Environment(\.dismiss) private var dismiss

    @State private var anchorMonth: Date = Date()
    @State private var selectedDateISO: String?
    @State private var allEvents: [MomCalendarEvent] = []
    @State private var grouped: [String: [MomCalendarEvent]] = [:]
    @State private var activeCategories: Set<MomEventCategory> = Set(MomEventCategory.allCases)
    @State private var isLoading = false
    @State private var loadError: String?

    @State private var syncedEventIds: Set<UUID> = []
    @State private var syncingEventIds: Set<UUID> = []
    @State private var isBulkSyncing = false
    @State private var calendarMessage: String?

    @State private var shareItems: [Any] = []
    @State private var isSharePresented = false

    private var deepMaroon: Color { Color(red: 0.42, green: 0.11, blue: 0.20) }

    private static let isoDayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.current
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    var body: some View {
        ZStack {
            backgroundColor.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    topBar
                    monthHeader
                    weekdayHeaderRow
                    monthGrid
                    filtersBar
                    eventsForSelectedDay

                    if let loadError {
                        Text(loadError)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.red.opacity(0.85))
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }

                    Spacer(minLength: 18)
                }
                .padding(.horizontal, 18)
                .padding(.top, 6)
                .padding(.bottom, 24)
            }
            .refreshable { await reload() }
        }
        .navigationBarBackButtonHidden(true)
        .task {
            if selectedDateISO == nil {
                selectedDateISO = Self.isoDayFormatter.string(from: Date())
            }
            syncedEventIds = AppleCalendarSyncService.shared.syncedIdentifiers()
            await reload()
        }
        .alert(
            "Apple Calendar",
            isPresented: Binding(
                get: { calendarMessage != nil },
                set: { if !$0 { calendarMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(calendarMessage ?? "")
        }
        .sheet(isPresented: $isSharePresented) {
            ShareSheet(items: shareItems)
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button { dismiss() } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(deepMaroon)
                    .frame(width: 44, height: 44)
            }
            Text("Event Calendar")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(deepMaroon)
                .frame(maxWidth: .infinity)
            Button {
                anchorMonth = Date()
                selectedDateISO = Self.isoDayFormatter.string(from: Date())
            } label: {
                Text("Today")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(accentColor)
                    .frame(width: 60, height: 44, alignment: .trailing)
            }
        }
    }

    // MARK: - Month Header

    private var monthHeader: some View {
        HStack {
            Button { stepMonth(-1) } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(deepMaroon)
                    .frame(width: 44, height: 44)
            }
            Spacer()
            Text(monthTitle())
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(deepMaroon)
            Spacer()
            Button { stepMonth(1) } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(deepMaroon)
                    .frame(width: 44, height: 44)
            }
        }
        .padding(.horizontal, 4)
    }

    private var weekdayHeaderRow: some View {
        HStack(spacing: 0) {
            ForEach(weekdaySymbols(), id: \.self) { sym in
                Text(sym)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Color.black.opacity(0.45))
                    .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Month Grid

    private var monthGrid: some View {
        VStack(spacing: 8) {
            let cells = monthCells()
            let rows = cells.count / 7
            ForEach(0..<rows, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { col in
                        dayCell(cells[row * 7 + col])
                    }
                }
            }
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .shadow(color: Color.black.opacity(0.06), radius: 10, y: 4)
    }

    private struct DayCell: Identifiable, Hashable {
        let id: String
        let date: Date?
        let dateISO: String?
        let isCurrentMonth: Bool
        let isToday: Bool
    }

    private func dayCell(_ cell: DayCell) -> some View {
        let dayEvents = (cell.dateISO.flatMap { grouped[$0] } ?? [])
            .filter { activeCategories.contains($0.category) }
        let dotCategoriesAll = Array(Set(dayEvents.map(\.category)))
            .sorted(by: { $0.rawValue < $1.rawValue })
        let dotCategories = Array(dotCategoriesAll.prefix(3))
        let isSelected = cell.dateISO != nil && cell.dateISO == selectedDateISO

        return Button {
            if let iso = cell.dateISO { selectedDateISO = iso }
        } label: {
            VStack(spacing: 4) {
                Text(cell.date.map { String(Calendar.current.component(.day, from: $0)) } ?? "")
                    .font(.system(size: 14, weight: cell.isToday ? .bold : .semibold, design: .rounded))
                    .foregroundStyle(
                        cell.isCurrentMonth
                            ? (cell.isToday ? Color.white : Color.black.opacity(0.78))
                            : Color.black.opacity(0.22)
                    )
                    .frame(width: 30, height: 30)
                    .background(
                        Circle().fill(cell.isToday ? accentColor : Color.clear)
                    )
                    .overlay(
                        Circle()
                            .stroke(isSelected && !cell.isToday ? accentColor : Color.clear, lineWidth: 2)
                    )

                HStack(spacing: 3) {
                    if !dayEvents.isEmpty {
                        ForEach(dotCategories, id: \.self) { cat in
                            Circle()
                                .fill(cat.color)
                                .frame(width: 5, height: 5)
                        }
                        if dotCategoriesAll.count > 3 {
                            Text("+")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundStyle(Color.black.opacity(0.45))
                        }
                    } else {
                        Circle().fill(Color.clear).frame(width: 5, height: 5)
                    }
                }
                .frame(height: 8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
        }
        .buttonStyle(.plain)
        .disabled(cell.dateISO == nil)
    }

    // MARK: - Filters

    private var filtersBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                allFilterChip
                ForEach(MomEventCategory.allCases) { cat in
                    filterChip(cat)
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var allFilterChip: some View {
        let allOn = activeCategories.count == MomEventCategory.allCases.count
        return Button {
            if allOn { activeCategories = [] }
            else { activeCategories = Set(MomEventCategory.allCases) }
        } label: {
            Text("All")
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(allOn ? .white : deepMaroon)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(allOn ? deepMaroon : Color.white)
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(deepMaroon.opacity(0.18), lineWidth: 1)
                )
        }
    }

    private func filterChip(_ cat: MomEventCategory) -> some View {
        let on = activeCategories.contains(cat)
        return Button {
            if on { activeCategories.remove(cat) }
            else { activeCategories.insert(cat) }
        } label: {
            HStack(spacing: 6) {
                Circle().fill(cat.color).frame(width: 8, height: 8)
                Text(cat.label)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(on ? .white : Color.black.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(on ? cat.color : Color.white)
            .clipShape(Capsule())
            .overlay(
                Capsule().stroke(cat.color.opacity(0.25), lineWidth: 1)
            )
        }
    }

    // MARK: - Events for selected day

    private var eventsForSelectedDay: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(selectedDayHeader())
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(deepMaroon)
                Spacer()
                if let count = filteredEventsForSelectedDay()?.count, count > 0 {
                    Text("\(count) event\(count == 1 ? "" : "s")")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.black.opacity(0.5))
                }
            }

            bulkSyncButton

            if isLoading {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else if let events = filteredEventsForSelectedDay(), !events.isEmpty {
                VStack(spacing: 10) {
                    ForEach(events) { event in
                        eventRow(event)
                    }
                }
            } else {
                Text(session == nil
                     ? "Sign in to view scheduled events."
                     : "No events on this day.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.black.opacity(0.45))
                    .padding(.vertical, 8)
            }
        }
    }

    private func eventRow(_ event: MomCalendarEvent) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(event.category.color.opacity(0.16))
                        .frame(width: 42, height: 42)
                    Image(systemName: event.category.systemImage)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(event.category.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(event.title)
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundStyle(deepMaroon)
                        .lineLimit(2)
                    HStack(spacing: 6) {
                        if let t = event.timeText, !t.isEmpty {
                            Text(t)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(Color.black.opacity(0.55))
                        }
                        if let m = event.metadata, !m.isEmpty {
                            if event.timeText?.isEmpty == false {
                                Text("·")
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.black.opacity(0.3))
                            }
                            Text(m)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundStyle(Color.black.opacity(0.45))
                                .lineLimit(1)
                        }
                    }
                }

                Spacer()

                Text(event.isPast ? "Done" : "Upcoming")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(event.isPast ? Color.black.opacity(0.4) : event.category.color)
                    .clipShape(Capsule())
            }

            calendarSyncButton(for: event)
        }
        .padding(12)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 8, y: 3)
    }

    // MARK: - Apple Calendar sync UI

    private var bulkSyncButton: some View {
        let dayEvents = filteredEventsForSelectedDay() ?? []
        let upcoming = dayEvents.filter { !$0.isPast }
        let pending = upcoming.filter { !syncedEventIds.contains($0.id) }
        let canSync = !pending.isEmpty && !isBulkSyncing
        let canEmail = !dayEvents.isEmpty

        return HStack(spacing: 8) {
            Spacer()

            Button {
                emailEvents(dayEvents, filenameStem: "pregaboo-\(selectedDateISO ?? "events")")
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "envelope.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Email day's events")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(canEmail ? deepMaroon : Color.black.opacity(0.4))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(canEmail ? Color.white : Color.black.opacity(0.05))
                .clipShape(Capsule())
                .overlay(
                    Capsule().stroke(deepMaroon.opacity(0.25), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(!canEmail)

            Button {
                Task { await bulkSyncSelectedDay() }
            } label: {
                HStack(spacing: 6) {
                    if isBulkSyncing {
                        ProgressView().scaleEffect(0.8)
                    } else {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    Text(pending.isEmpty
                         ? (upcoming.isEmpty ? "All synced for past days" : "All synced for this day")
                         : "Sync \(pending.count) to Apple Calendar")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundStyle(canSync ? .white : Color.black.opacity(0.45))
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .background(canSync ? accentColor : Color.black.opacity(0.06))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
            .disabled(!canSync)
        }
    }

    private func calendarSyncButton(for event: MomCalendarEvent) -> some View {
        let isSynced = syncedEventIds.contains(event.id)
        let isBusy = syncingEventIds.contains(event.id)
        return HStack(spacing: 8) {
            Spacer()

            Button {
                emailEvents([event], filenameStem: "pregaboo-event-\(event.id.uuidString.prefix(8))")
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "envelope")
                        .font(.system(size: 12, weight: .semibold))
                    Text("Email")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(deepMaroon)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().stroke(deepMaroon.opacity(0.25), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            Button {
                Task { await toggleCalendarSync(for: event) }
            } label: {
                HStack(spacing: 6) {
                    if isBusy {
                        ProgressView().scaleEffect(0.7)
                    } else {
                        Image(systemName: isSynced ? "checkmark.circle.fill" : "calendar.badge.plus")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    Text(isSynced ? "In Apple Calendar" : "Add to Apple Calendar")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundStyle(isSynced ? Color.green : event.category.color)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule().stroke((isSynced ? Color.green : event.category.color).opacity(0.45), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .disabled(isBusy)
        }
    }

    private func emailEvents(_ events: [MomCalendarEvent], filenameStem: String) {
        guard !events.isEmpty else { return }
        do {
            let url = try EventCalendarICSExportService.writeTemporaryFile(events: events, filenameStem: filenameStem)
            shareItems = [url]
            isSharePresented = true
        } catch {
            calendarMessage = error.localizedDescription
        }
    }

    @MainActor
    private func toggleCalendarSync(for event: MomCalendarEvent) async {
        syncingEventIds.insert(event.id)
        defer { syncingEventIds.remove(event.id) }
        do {
            if syncedEventIds.contains(event.id) {
                try await AppleCalendarSyncService.shared.remove(eventId: event.id)
                syncedEventIds.remove(event.id)
            } else {
                _ = try await AppleCalendarSyncService.shared.add(event: event)
                syncedEventIds.insert(event.id)
            }
        } catch {
            calendarMessage = error.localizedDescription
        }
    }

    @MainActor
    private func bulkSyncSelectedDay() async {
        let upcoming = (filteredEventsForSelectedDay() ?? []).filter { !$0.isPast && !syncedEventIds.contains($0.id) }
        guard !upcoming.isEmpty else { return }
        isBulkSyncing = true
        defer { isBulkSyncing = false }
        do {
            let added = try await AppleCalendarSyncService.shared.syncUpcoming(upcoming)
            syncedEventIds = AppleCalendarSyncService.shared.syncedIdentifiers()
            calendarMessage = added > 0
                ? "Added \(added) event\(added == 1 ? "" : "s") to Apple Calendar."
                : "No new events were added."
        } catch {
            calendarMessage = error.localizedDescription
        }
    }

    // MARK: - Helpers

    private func stepMonth(_ delta: Int) {
        if let next = Calendar.current.date(byAdding: .month, value: delta, to: anchorMonth) {
            anchorMonth = next
        }
    }

    private func monthTitle() -> String {
        let df = DateFormatter()
        df.locale = Locale.current
        df.dateFormat = "MMMM yyyy"
        return df.string(from: anchorMonth)
    }

    private func weekdaySymbols() -> [String] {
        let cal = Calendar.current
        let symbols = cal.shortWeekdaySymbols
        let shift = cal.firstWeekday - 1
        return Array(symbols[shift...] + symbols[..<shift])
    }

    private func monthCells() -> [DayCell] {
        let cal = Calendar.current
        guard let monthInterval = cal.dateInterval(of: .month, for: anchorMonth) else { return [] }
        let firstOfMonth = monthInterval.start

        let firstWeekday = cal.firstWeekday
        let weekdayOfFirst = cal.component(.weekday, from: firstOfMonth)
        let leading = (weekdayOfFirst - firstWeekday + 7) % 7

        guard let range = cal.range(of: .day, in: .month, for: firstOfMonth) else { return [] }
        let daysInMonth = range.count

        let occupied = leading + daysInMonth
        let totalCells = (occupied % 7 == 0) ? occupied : occupied + (7 - occupied % 7)

        let todayISO = Self.isoDayFormatter.string(from: Date())

        var cells: [DayCell] = []
        for i in 0..<leading {
            cells.append(DayCell(id: "lead-\(i)", date: nil, dateISO: nil, isCurrentMonth: false, isToday: false))
        }
        for day in 1...daysInMonth {
            var comps = cal.dateComponents([.year, .month], from: firstOfMonth)
            comps.day = day
            let date = cal.date(from: comps) ?? firstOfMonth
            let iso = Self.isoDayFormatter.string(from: date)
            cells.append(
                DayCell(id: iso, date: date, dateISO: iso, isCurrentMonth: true, isToday: iso == todayISO)
            )
        }
        let trailing = totalCells - cells.count
        for i in 0..<trailing {
            cells.append(DayCell(id: "trail-\(i)", date: nil, dateISO: nil, isCurrentMonth: false, isToday: false))
        }
        return cells
    }

    private func selectedDayHeader() -> String {
        guard
            let iso = selectedDateISO,
            let date = Self.isoDayFormatter.date(from: iso)
        else { return "Events" }
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today's events" }
        if cal.isDateInTomorrow(date) { return "Tomorrow's events" }
        if cal.isDateInYesterday(date) { return "Yesterday's events" }
        let df = DateFormatter()
        df.dateFormat = "EEEE, MMM d"
        return "Events on \(df.string(from: date))"
    }

    private func filteredEventsForSelectedDay() -> [MomCalendarEvent]? {
        guard let iso = selectedDateISO else { return nil }
        return (grouped[iso] ?? []).filter { activeCategories.contains($0.category) }
    }

    @MainActor
    private func reload() async {
        guard let session else {
            allEvents = []
            grouped = [:]
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            let events = try await MomRemindersEventGridService.loadEvents(session: session)
            allEvents = events
            grouped = MomRemindersEventGridService.groupByDate(events)
            loadError = nil
        } catch SupabaseServiceError.httpError(let status, let body) {
            loadError = "Could not load (\(status)): \(SupabaseAuthService.humanMessage(fromBody: body))"
            allEvents = []
            grouped = [:]
        } catch {
            loadError = "Could not load: \(error.localizedDescription)"
            allEvents = []
            grouped = [:]
        }
    }
}

#Preview {
    NavigationStack {
        MomEventGridView(
            backgroundColor: Color(red: 1.0, green: 0.97, blue: 0.97),
            accentColor: Color(red: 0.94, green: 0.39, blue: 0.45),
            session: nil
        )
    }
}
