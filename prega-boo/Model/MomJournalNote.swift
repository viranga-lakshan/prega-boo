import Foundation

/// A care/journal note attached to a mom (and optionally a specific child).
/// Authored by a midwife, mom or admin; visible to the mom, midwives in her district and admins.
struct MomJournalNote: Codable, Identifiable, Hashable {
    let id: UUID
    let momUserId: UUID
    let createdByUserId: UUID
    let authorRole: String
    let childId: UUID?
    let title: String
    let body: String
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case momUserId = "mom_user_id"
        case createdByUserId = "created_by_user_id"
        case authorRole = "author_role"
        case childId = "child_id"
        case title
        case body
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}
