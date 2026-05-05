import Foundation

/// Per-reminder notification opt-out for **clinic-derived** rows (IDs only). Custom `mom_reminders` use `notification_enabled` on the server.
final class MomRemindersLocalStore {
    static let shared = MomRemindersLocalStore()

    private let disabledKey = "momReminders.disabledReminderIds.v1"
    private let defaults = UserDefaults.standard

    private init() {}

    func loadDisabledReminderIds() -> Set<UUID> {
        guard let data = defaults.data(forKey: disabledKey),
              let strings = try? JSONDecoder().decode([String].self, from: data) else {
            return []
        }
        return Set(strings.compactMap { UUID(uuidString: $0) })
    }

    func saveDisabledReminderIds(_ ids: Set<UUID>) {
        let strings = ids.map(\.uuidString)
        guard let data = try? JSONEncoder().encode(strings) else { return }
        defaults.set(data, forKey: disabledKey)
    }
}
