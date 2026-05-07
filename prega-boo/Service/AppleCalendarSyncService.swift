import EventKit
import Foundation

enum AppleCalendarSyncError: LocalizedError {
    case accessDenied
    case eventStoreError(String)
    case noDate

    var errorDescription: String? {
        switch self {
        case .accessDenied:
            return "Calendar access was denied. Enable it in Settings → Privacy & Security → Calendars → Prega Boo."
        case .eventStoreError(let message):
            return "Could not update Apple Calendar: \(message)"
        case .noDate:
            return "This event does not have a usable date."
        }
    }
}

/// Saves Prega Boo events into the user's default Apple Calendar via EventKit.
/// Keeps a local map of `MomCalendarEvent.id` ↔ EKEvent identifier in `UserDefaults` so the UI can show a “Saved” state.
@MainActor
final class AppleCalendarSyncService {
    static let shared = AppleCalendarSyncService()

    private let store = EKEventStore()
    private let mapKey = "pregaboo.appleCalendar.eventMap"

    /// Requests calendar permission. iOS 17+ uses `requestFullAccessToEvents`; older iOS uses the legacy callback API.
    func requestAccess() async throws -> Bool {
        if #available(iOS 17.0, *) {
            do {
                return try await store.requestFullAccessToEvents()
            } catch {
                throw AppleCalendarSyncError.eventStoreError(error.localizedDescription)
            }
        } else {
            return try await withCheckedThrowingContinuation { continuation in
                store.requestAccess(to: .event) { granted, error in
                    if let error {
                        continuation.resume(throwing: AppleCalendarSyncError.eventStoreError(error.localizedDescription))
                    } else {
                        continuation.resume(returning: granted)
                    }
                }
            }
        }
    }

    /// Saves the event to the user's default calendar and returns the new EKEvent identifier.
    @discardableResult
    func add(event: MomCalendarEvent) async throws -> String {
        let granted = try await requestAccess()
        guard granted else { throw AppleCalendarSyncError.accessDenied }

        guard let calendar = store.defaultCalendarForNewEvents else {
            throw AppleCalendarSyncError.eventStoreError("No default calendar is available on this device.")
        }

        let startDate: Date
        let isAllDay: Bool
        if let scheduled = event.scheduleAt, hasParsedTime(event.timeText) {
            startDate = scheduled
            isAllDay = false
        } else if let day = parseISODay(event.dateISO) {
            startDate = day
            isAllDay = true
        } else {
            throw AppleCalendarSyncError.noDate
        }

        let endDate = Calendar.current.date(byAdding: .hour, value: 1, to: startDate)
            ?? startDate.addingTimeInterval(3600)

        let ek = EKEvent(eventStore: store)
        ek.title = event.title
        ek.startDate = startDate
        ek.endDate = endDate
        ek.isAllDay = isAllDay
        ek.calendar = calendar

        var noteParts: [String] = []
        if let metadata = event.metadata, !metadata.isEmpty { noteParts.append(metadata) }
        noteParts.append("Category: \(event.category.label)")
        noteParts.append("Added from Prega Boo")
        ek.notes = noteParts.joined(separator: "\n")

        if !event.isPast {
            ek.alarms = [EKAlarm(relativeOffset: -3600)]
        }

        do {
            try store.save(ek, span: .thisEvent, commit: true)
        } catch {
            throw AppleCalendarSyncError.eventStoreError(error.localizedDescription)
        }

        let identifier = ek.eventIdentifier ?? ""
        var map = loadMap()
        map[event.id.uuidString] = identifier
        saveMap(map)
        return identifier
    }

    /// Removes a previously-synced event from the user's calendar (and the local map).
    func remove(eventId: UUID) async throws {
        var map = loadMap()
        guard let ekId = map[eventId.uuidString] else { return }

        if let ek = store.event(withIdentifier: ekId) {
            do {
                try store.remove(ek, span: .thisEvent, commit: true)
            } catch {
                throw AppleCalendarSyncError.eventStoreError(error.localizedDescription)
            }
        }
        map.removeValue(forKey: eventId.uuidString)
        saveMap(map)
    }

    /// Bulk-syncs every upcoming event in the supplied list. Skips events that are already synced or in the past.
    /// Returns the count actually added.
    @discardableResult
    func syncUpcoming(_ events: [MomCalendarEvent]) async throws -> Int {
        let granted = try await requestAccess()
        guard granted else { throw AppleCalendarSyncError.accessDenied }

        var added = 0
        let alreadySynced = syncedIdentifiers()
        for event in events where !event.isPast && !alreadySynced.contains(event.id) {
            do {
                _ = try await add(event: event)
                added += 1
            } catch AppleCalendarSyncError.noDate {
                continue
            }
        }
        return added
    }

    /// Returns the set of `MomCalendarEvent.id`s that currently have a corresponding EKEvent on disk.
    func syncedIdentifiers() -> Set<UUID> {
        let map = loadMap()
        var result = Set<UUID>()
        for (key, ekId) in map {
            guard let uuid = UUID(uuidString: key) else { continue }
            if store.event(withIdentifier: ekId) != nil {
                result.insert(uuid)
            }
        }
        return result
    }

    func isSynced(eventId: UUID) -> Bool {
        guard let ekId = loadMap()[eventId.uuidString] else { return false }
        return store.event(withIdentifier: ekId) != nil
    }

    // MARK: - Helpers

    private func loadMap() -> [String: String] {
        UserDefaults.standard.dictionary(forKey: mapKey) as? [String: String] ?? [:]
    }

    private func saveMap(_ map: [String: String]) {
        UserDefaults.standard.set(map, forKey: mapKey)
    }

    private func parseISODay(_ iso: String) -> Date? {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.timeZone = TimeZone.current
        df.dateFormat = "yyyy-MM-dd"
        guard let day = df.date(from: iso) else { return nil }
        // Anchor to 9:00 local for all-day fallbacks; isAllDay flag controls the actual presentation.
        return Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: day) ?? day
    }

    private func hasParsedTime(_ text: String?) -> Bool {
        guard let text, !text.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        return true
    }
}
