import Foundation

/// Builds Reminders “Upcoming” and “Past history” from Supabase health tables for the logged-in mom.
enum MomRemindersDataService {

    private static let isoDayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone(secondsFromGMT: 0)
        df.dateFormat = "yyyy-MM-dd"
        return df
    }()

    static func utcTodayISODay() -> String {
        isoDayFormatter.string(from: Date())
    }

    /// Local calendar day as `yyyy-MM-dd` (for `mom_reminders.reminder_date`, consistent with how visit days are chosen in the device time zone).
    static func localCalendarDayISO(from date: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.current
        df.dateFormat = "yyyy-MM-dd"
        return df.string(from: date)
    }

    static func load(session: AuthSessionContext) async throws -> (upcoming: [MomUpcomingReminderItem], history: [MomReminderHistoryItem]) {
        let momId = session.userId
        let token = session.accessToken
        let today = utcTodayISODay()

        async let momVisits = ClinicVisitRecordsRepository().fetchRecords(momUserId: momId, accessToken: token)
        async let momGrowth = GrowthRecordsRepository().fetchRecords(momUserId: momId, accessToken: token)
        async let momVaccines = VaccineRecordsRepository().fetchRecords(momUserId: momId, accessToken: token)
        async let children = ChildProfilesRepository().fetchChildren(momUserId: momId, accessToken: token)
        async let customReminders = MomRemindersRepository().fetchScheduled(momUserId: momId, fromDateISO: today, accessToken: token)

        let (mv, mg, mvc, kids, dbReminders) = try await (momVisits, momGrowth, momVaccines, children, customReminders)

        var childVisits: [ChildClinicVisitRecord] = []
        var childGrowth: [ChildGrowthRecord] = []
        var childVaccines: [ChildVaccineRecord] = []

        for child in kids {
            async let visits = ChildClinicVisitRecordsRepository().fetchRecords(childId: child.id, accessToken: token)
            async let growth = ChildGrowthRecordsRepository().fetchRecords(childId: child.id, accessToken: token)
            async let vaccines = ChildVaccineRecordsRepository().fetchRecords(childId: child.id, accessToken: token)
            let (v, g, vx) = try await (visits, growth, vaccines)
            childVisits.append(contentsOf: v)
            childGrowth.append(contentsOf: g)
            childVaccines.append(contentsOf: vx)
        }

        var upcoming: [MomUpcomingReminderItem] = []

        for v in mv where v.visitDate >= today {
            upcoming.append(
                MomUpcomingReminderItem(
                    id: v.id,
                    sortKey: v.visitDate,
                    scheduleAt: MomReminderVisitScheduling.fireDate(visitDateISO: v.visitDate, visitTimeText: v.visitTime),
                    title: v.purpose.isEmpty ? "Clinic visit" : v.purpose,
                    scheduleText: scheduleSubtitle(visitDate: v.visitDate, visitTime: v.visitTime),
                    tag: .health,
                    metadata: "Your visit · \(v.visitTime)",
                    iconSystemName: "calendar",
                    source: .clinicMom,
                    dbNotificationEnabled: true
                )
            )
        }

        let childById = Dictionary(uniqueKeysWithValues: kids.map { ($0.id, $0) })
        for v in childVisits where v.visitDate >= today {
            let name = childById[v.childId]?.fullName.split(separator: " ").first.map(String.init) ?? "Baby"
            upcoming.append(
                MomUpcomingReminderItem(
                    id: v.id,
                    sortKey: v.visitDate,
                    scheduleAt: MomReminderVisitScheduling.fireDate(visitDateISO: v.visitDate, visitTimeText: v.visitTime),
                    title: v.purpose.isEmpty ? "Clinic visit" : v.purpose,
                    scheduleText: scheduleSubtitle(visitDate: v.visitDate, visitTime: v.visitTime),
                    tag: .pediatric,
                    metadata: "\(name) · \(v.visitTime)",
                    iconSystemName: "cross.case.fill",
                    source: .clinicChild,
                    dbNotificationEnabled: true
                )
            )
        }

        for r in dbReminders {
            upcoming.append(upcomingItem(from: r, childById: childById))
        }

        upcoming.sort {
            if $0.sortKey != $1.sortKey { return $0.sortKey < $1.sortKey }
            return $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending
        }

        var historyCandidates: [(sort: String, item: MomReminderHistoryItem)] = []

        for v in mv where v.visitDate < today {
            historyCandidates.append((
                v.visitDate + " " + v.visitTime,
                MomReminderHistoryItem(
                    id: v.id,
                    title: v.purpose.isEmpty ? "Clinic visit" : v.purpose,
                    completedText: completedClinicText(visitDate: v.visitDate, visitTime: v.visitTime)
                )
            ))
        }

        for v in childVisits where v.visitDate < today {
            let name = childById[v.childId]?.fullName.split(separator: " ").first.map(String.init) ?? "Baby"
            historyCandidates.append((
                v.visitDate + " " + v.visitTime,
                MomReminderHistoryItem(
                    id: v.id,
                    title: "\(name): \(v.purpose.isEmpty ? "Clinic visit" : v.purpose)",
                    completedText: completedClinicText(visitDate: v.visitDate, visitTime: v.visitTime)
                )
            ))
        }

        for g in mg.prefix(12) {
            historyCandidates.append((
                g.measuredOn,
                MomReminderHistoryItem(
                    id: g.id,
                    title: "Your growth check-in",
                    completedText: completedRecordText(isoDate: g.measuredOn, detail: String(format: "%.1f kg · %.0f cm", g.weightKg, g.heightCm))
                )
            ))
        }

        for g in childGrowth.prefix(12) {
            let name = childById[g.childId]?.fullName.split(separator: " ").first.map(String.init) ?? "Baby"
            historyCandidates.append((
                g.measuredOn,
                MomReminderHistoryItem(
                    id: g.id,
                    title: "\(name): growth recorded",
                    completedText: completedRecordText(isoDate: g.measuredOn, detail: String(format: "%.1f kg · %.0f cm", g.weightKg, g.heightCm))
                )
            ))
        }

        for r in mvc.prefix(12) {
            historyCandidates.append((
                r.administeredOn,
                MomReminderHistoryItem(
                    id: r.id,
                    title: "Vaccine: \(r.vaccineName)",
                    completedText: completedRecordText(isoDate: r.administeredOn, detail: r.dosage)
                )
            ))
        }

        for r in childVaccines.prefix(12) {
            let name = childById[r.childId]?.fullName.split(separator: " ").first.map(String.init) ?? "Baby"
            historyCandidates.append((
                r.administeredOn,
                MomReminderHistoryItem(
                    id: r.id,
                    title: "\(name): \(r.vaccineName)",
                    completedText: completedRecordText(isoDate: r.administeredOn, detail: r.dosage)
                )
            ))
        }

        let sorted = historyCandidates.sorted { $0.sort > $1.sort }.map(\.item)
        var seen = Set<UUID>()
        let history: [MomReminderHistoryItem] = sorted.compactMap { item in
            guard seen.insert(item.id).inserted else { return nil }
            return item
        }.prefix(25).map { $0 }

        return (upcoming, history)
    }

    private static func scheduleSubtitle(visitDate: String, visitTime: String) -> String {
        let prettyDay = prettyDayLabel(isoDay: visitDate)
        return "\(prettyDay) · \(visitTime)"
    }

    private static func prettyDayLabel(isoDay: String) -> String {
        guard let d = MomHealthAgeFormatting.parseVisitDate(iso: isoDay) else { return isoDay }
        let cal = Calendar.current
        if cal.isDateInToday(d) { return "Today" }
        if cal.isDateInTomorrow(d) { return "Tomorrow" }
        let df = DateFormatter()
        df.dateFormat = "EEE, MMM d"
        return df.string(from: d)
    }

    private static func completedClinicText(visitDate: String, visitTime: String) -> String {
        let day = prettyDayLabel(isoDay: visitDate)
        return "Completed \(day) · \(visitTime)"
    }

    private static func completedRecordText(isoDate: String, detail: String) -> String {
        guard let d = MomHealthAgeFormatting.parseVisitDate(iso: isoDate) else {
            return "Completed · \(detail)"
        }
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .none
        return "Completed on \(df.string(from: d)) · \(detail)"
    }

    private static func upcomingItem(from r: MomReminderRecord, childById: [UUID: ChildProfile]) -> MomUpcomingReminderItem {
        let tag = MomReminderTagStyle(rawValue: r.reminderTag) ?? .health
        let icon: String
        if let n = r.iconName, !n.isEmpty {
            icon = n
        } else {
            icon = tag == .pediatric ? "cross.case.fill" : "calendar"
        }
        let meta: String
        if let m = r.metadata, !m.isEmpty {
            meta = m
        } else if let cid = r.childId, let child = childById[cid] {
            let name = child.fullName.split(separator: " ").first.map(String.init) ?? "Baby"
            meta = "\(name) · \(r.reminderTime)"
        } else {
            meta = "—"
        }
        return MomUpcomingReminderItem(
            id: r.id,
            sortKey: r.reminderDate,
            scheduleAt: MomReminderVisitScheduling.fireDate(visitDateISO: r.reminderDate, visitTimeText: r.reminderTime),
            title: r.title,
            scheduleText: scheduleSubtitle(visitDate: r.reminderDate, visitTime: r.reminderTime),
            tag: tag,
            metadata: meta,
            iconSystemName: icon,
            source: .customDatabase,
            dbNotificationEnabled: r.notificationEnabled
        )
    }
}
