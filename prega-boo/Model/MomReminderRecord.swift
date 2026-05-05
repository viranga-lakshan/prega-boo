import Foundation

struct MomReminderRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let momUserId: UUID
    let createdByUserId: UUID
    let childId: UUID?

    let title: String
    let reminderDate: String
    let reminderTime: String
    let metadata: String?
    let reminderTag: String
    let iconName: String?

    let notificationEnabled: Bool
    let status: String

    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case momUserId = "mom_user_id"
        case createdByUserId = "created_by_user_id"
        case childId = "child_id"
        case title
        case reminderDate = "reminder_date"
        case reminderTime = "reminder_time"
        case metadata
        case reminderTag = "reminder_tag"
        case iconName = "icon_name"
        case notificationEnabled = "notification_enabled"
        case status
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
