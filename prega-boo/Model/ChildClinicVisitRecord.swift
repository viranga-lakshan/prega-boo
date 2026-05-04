import Foundation

struct ChildClinicVisitRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let childId: UUID
    let createdByUserId: UUID

    let visitDate: String
    let visitTime: String
    let purpose: String

    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case childId = "child_id"
        case createdByUserId = "created_by_user_id"
        case visitDate = "visit_date"
        case visitTime = "visit_time"
        case purpose
        case createdAt = "created_at"
    }
}
