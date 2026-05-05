import Foundation

final class MomRemindersRepository {
    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    /// Scheduled reminders on or after `fromDateISO` (`yyyy-MM-dd`).
    func fetchScheduled(momUserId: UUID, fromDateISO: String, accessToken: String) async throws -> [MomReminderRecord] {
        let (data, _) = try await supabase.request(
            path: "/rest/v1/mom_reminders",
            queryItems: [
                URLQueryItem(name: "select", value: "id,mom_user_id,created_by_user_id,child_id,title,reminder_date,reminder_time,metadata,reminder_tag,icon_name,notification_enabled,status,created_at,updated_at"),
                URLQueryItem(name: "mom_user_id", value: "eq.\(momUserId.uuidString)"),
                URLQueryItem(name: "status", value: "eq.scheduled"),
                URLQueryItem(name: "reminder_date", value: "gte.\(fromDateISO)"),
                URLQueryItem(name: "order", value: "reminder_date.asc,created_at.asc")
            ],
            headers: [
                "Authorization": "Bearer \(accessToken)"
            ]
        )

        return try JSONDecoder().decode([MomReminderRecord].self, from: data)
    }

    func insertReminder(
        momUserId: UUID,
        createdByUserId: UUID,
        childId: UUID?,
        title: String,
        reminderDateISO: String,
        reminderTimeText: String,
        metadata: String?,
        reminderTag: String,
        iconName: String?,
        accessToken: String
    ) async throws {
        var row: [String: Any] = [
            "mom_user_id": momUserId.uuidString,
            "created_by_user_id": createdByUserId.uuidString,
            "title": title,
            "reminder_date": reminderDateISO,
            "reminder_time": reminderTimeText,
            "reminder_tag": reminderTag,
            "notification_enabled": true,
            "status": "scheduled"
        ]
        if let childId {
            row["child_id"] = childId.uuidString
        }
        if let metadata, !metadata.isEmpty {
            row["metadata"] = metadata
        }
        if let iconName, !iconName.isEmpty {
            row["icon_name"] = iconName
        }

        let payload: [[String: Any]] = [row]
        let body = try JSONSerialization.data(withJSONObject: payload)

        do {
            _ = try await supabase.request(
                path: "/rest/v1/mom_reminders",
                method: "POST",
                headers: [
                    "Content-Type": "application/json",
                    "Prefer": "return=minimal",
                    "Authorization": "Bearer \(accessToken)"
                ],
                body: body
            )
        } catch SupabaseServiceError.httpError(let status, let body) {
            throw SupabaseServiceError.httpError(
                status: status,
                body: "[DB insert mom_reminders] \(body)"
            )
        }
    }

    func updateNotificationEnabled(reminderId: UUID, enabled: Bool, accessToken: String) async throws {
        let row: [String: Any] = ["notification_enabled": enabled]
        let body = try JSONSerialization.data(withJSONObject: row)

        do {
            _ = try await supabase.request(
                path: "/rest/v1/mom_reminders",
                method: "PATCH",
                queryItems: [
                    URLQueryItem(name: "id", value: "eq.\(reminderId.uuidString)")
                ],
                headers: [
                    "Content-Type": "application/json",
                    "Prefer": "return=minimal",
                    "Authorization": "Bearer \(accessToken)"
                ],
                body: body
            )
        } catch SupabaseServiceError.httpError(let status, let body) {
            throw SupabaseServiceError.httpError(
                status: status,
                body: "[DB patch mom_reminders] \(body)"
            )
        }
    }
}
