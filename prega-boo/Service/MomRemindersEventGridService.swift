import Foundation

/// Aggregates every dated health record (mom + children) into a unified event list for the calendar grid.
/// Combines: clinic visits, custom reminders, growth checks, and vaccine entries.
enum MomRemindersEventGridService {

    /// Fetches all calendar events in parallel and returns them sorted ascending by date+title.
    @MainActor
    static func loadEvents(session: AuthSessionContext) async throws -> [MomCalendarEvent] {
        let momId = session.userId
        let token = session.accessToken
        let today = MomRemindersDataService.utcTodayISODay()

        async let momVisitsTask = ClinicVisitRecordsRepository().fetchRecords(momUserId: momId, accessToken: token)
        async let momGrowthTask = GrowthRecordsRepository().fetchRecords(momUserId: momId, accessToken: token)
        async let momVaccinesTask = VaccineRecordsRepository().fetchRecords(momUserId: momId, accessToken: token)
        async let childrenTask = ChildProfilesRepository().fetchChildren(momUserId: momId, accessToken: token)
        // Use 1970 floor so we get past + future custom reminders for the calendar.
        async let customRemindersTask = MomRemindersRepository().fetchScheduled(momUserId: momId, fromDateISO: "1970-01-01", accessToken: token)

        let (momVisits, momGrowth, momVaccines, kids, customReminders) =
            try await (momVisitsTask, momGrowthTask, momVaccinesTask, childrenTask, customRemindersTask)

        var childVisits: [ChildClinicVisitRecord] = []
        var childGrowth: [ChildGrowthRecord] = []
        var childVaccines: [ChildVaccineRecord] = []

        for child in kids {
            async let visitsTask = ChildClinicVisitRecordsRepository().fetchRecords(childId: child.id, accessToken: token)
            async let growthTask = ChildGrowthRecordsRepository().fetchRecords(childId: child.id, accessToken: token)
            async let vaccinesTask = ChildVaccineRecordsRepository().fetchRecords(childId: child.id, accessToken: token)
            let (visits, growth, vax) = try await (visitsTask, growthTask, vaccinesTask)
            childVisits.append(contentsOf: visits)
            childGrowth.append(contentsOf: growth)
            childVaccines.append(contentsOf: vax)
        }

        let childById = Dictionary(uniqueKeysWithValues: kids.map { ($0.id, $0) })

        var events: [MomCalendarEvent] = []

        for v in momVisits {
            events.append(
                MomCalendarEvent(
                    id: v.id,
                    dateISO: v.visitDate,
                    title: v.purpose.isEmpty ? "Clinic visit" : v.purpose,
                    timeText: v.visitTime,
                    metadata: "Your clinic visit",
                    category: .clinicMom,
                    isPast: v.visitDate < today,
                    scheduleAt: MomReminderVisitScheduling.fireDate(visitDateISO: v.visitDate, visitTimeText: v.visitTime)
                )
            )
        }

        for v in childVisits {
            let firstName = childById[v.childId]?.fullName.split(separator: " ").first.map(String.init) ?? "Baby"
            events.append(
                MomCalendarEvent(
                    id: v.id,
                    dateISO: v.visitDate,
                    title: v.purpose.isEmpty ? "\(firstName): clinic visit" : "\(firstName): \(v.purpose)",
                    timeText: v.visitTime,
                    metadata: "Pediatric visit",
                    category: .clinicChild,
                    isPast: v.visitDate < today,
                    scheduleAt: MomReminderVisitScheduling.fireDate(visitDateISO: v.visitDate, visitTimeText: v.visitTime)
                )
            )
        }

        for g in momGrowth {
            events.append(
                MomCalendarEvent(
                    id: g.id,
                    dateISO: g.measuredOn,
                    title: "Your growth check-in",
                    timeText: nil,
                    metadata: String(format: "%.1f kg · %.0f cm", g.weightKg, g.heightCm),
                    category: .growth,
                    isPast: g.measuredOn < today,
                    scheduleAt: nil
                )
            )
        }

        for g in childGrowth {
            let firstName = childById[g.childId]?.fullName.split(separator: " ").first.map(String.init) ?? "Baby"
            events.append(
                MomCalendarEvent(
                    id: g.id,
                    dateISO: g.measuredOn,
                    title: "\(firstName): growth recorded",
                    timeText: nil,
                    metadata: String(format: "%.1f kg · %.0f cm", g.weightKg, g.heightCm),
                    category: .growth,
                    isPast: g.measuredOn < today,
                    scheduleAt: nil
                )
            )
        }

        for r in momVaccines {
            events.append(
                MomCalendarEvent(
                    id: r.id,
                    dateISO: r.administeredOn,
                    title: "Vaccine: \(r.vaccineName)",
                    timeText: nil,
                    metadata: r.dosage.isEmpty ? nil : r.dosage,
                    category: .vaccine,
                    isPast: r.administeredOn < today,
                    scheduleAt: nil
                )
            )
        }

        for r in childVaccines {
            let firstName = childById[r.childId]?.fullName.split(separator: " ").first.map(String.init) ?? "Baby"
            events.append(
                MomCalendarEvent(
                    id: r.id,
                    dateISO: r.administeredOn,
                    title: "\(firstName): \(r.vaccineName)",
                    timeText: nil,
                    metadata: r.dosage.isEmpty ? nil : r.dosage,
                    category: .vaccine,
                    isPast: r.administeredOn < today,
                    scheduleAt: nil
                )
            )
        }

        for r in customReminders {
            // Pediatric tag → child icon/color, otherwise treat as a custom reminder.
            let category: MomEventCategory =
                (r.reminderTag.lowercased() == "pediatric") ? .clinicChild : .customReminder

            let metadata: String?
            if let m = r.metadata, !m.isEmpty {
                metadata = m
            } else if let cid = r.childId, let child = childById[cid] {
                let firstName = child.fullName.split(separator: " ").first.map(String.init) ?? "Baby"
                metadata = firstName
            } else {
                metadata = nil
            }

            events.append(
                MomCalendarEvent(
                    id: r.id,
                    dateISO: r.reminderDate,
                    title: r.title,
                    timeText: r.reminderTime.isEmpty ? nil : r.reminderTime,
                    metadata: metadata,
                    category: category,
                    isPast: r.reminderDate < today,
                    scheduleAt: MomReminderVisitScheduling.fireDate(visitDateISO: r.reminderDate, visitTimeText: r.reminderTime)
                )
            )
        }

        events.sort { lhs, rhs in
            if lhs.dateISO != rhs.dateISO { return lhs.dateISO < rhs.dateISO }
            return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
        }
        return events
    }

    /// Groups events by their `yyyy-MM-dd` `dateISO` for fast day-cell lookup.
    static func groupByDate(_ events: [MomCalendarEvent]) -> [String: [MomCalendarEvent]] {
        Dictionary(grouping: events, by: { $0.dateISO })
    }
}
