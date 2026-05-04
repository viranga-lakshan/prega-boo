import Foundation

struct ClinicVisitRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let momUserId: UUID
    let createdByUserId: UUID

    let visitDate: String
    let visitTime: String
    let purpose: String

    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case momUserId = "mom_user_id"
        case createdByUserId = "created_by_user_id"
        case visitDate = "visit_date"
        case visitTime = "visit_time"
        case purpose
        case createdAt = "created_at"
    }
}
