import Foundation
import UserNotifications

/// Schedules **local** notifications for upcoming clinic reminders. Respects Push Alerts / Mute All / per-reminder toggles.
/// (Remote APNs pushes would need a server + Push capability — this is on-device scheduling only.)
final class MomRemindersNotificationService: NSObject, UNUserNotificationCenterDelegate {
    static let shared = MomRemindersNotificationService()

    private let idPrefix = "pregaboo.reminder."

    private override init() {
        super.init()
    }

    func configure() {
        UNUserNotificationCenter.current().delegate = self
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completion: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completion([.banner, .sound, .list])
    }

    // MARK: - Scheduling

    /// Removes all pending Prega Boo reminder notifications, then re-adds from `upcoming` when allowed.
    @MainActor
    func reschedule(
        upcoming: [MomUpcomingReminderItem],
        disabledReminderIds: Set<UUID>,
        pushAlertsEnabled: Bool,
        muteAll: Bool
    ) async {
        let center = UNUserNotificationCenter.current()

        let pending = await center.pendingNotificationRequests()
        let ourIds = pending.map(\.identifier).filter { $0.hasPrefix(idPrefix) }
        center.removePendingNotificationRequests(withIdentifiers: ourIds)

        guard pushAlertsEnabled, !muteAll else { return }

        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            _ = try? await center.requestAuthorization(options: [.alert, .sound, .badge])
        }

        let auth = await center.notificationSettings()
        switch auth.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            break
        default:
            return
        }

        let now = Date()
        for item in upcoming {
            let notificationsOn: Bool
            switch item.source {
            case .clinicMom, .clinicChild:
                notificationsOn = !disabledReminderIds.contains(item.id)
            case .customDatabase:
                notificationsOn = item.dbNotificationEnabled
            }
            guard notificationsOn,
                  let fire = item.scheduleAt,
                  fire > now else { continue }

            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = "\(item.scheduleText) — \(item.metadata)"
            content.sound = .default

            let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fire)
            let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
            let identifier = "\(idPrefix)\(item.id.uuidString)"
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

            do {
                try await center.add(request)
            } catch {
                // Best-effort; avoid breaking UI
            }
        }
    }
}
