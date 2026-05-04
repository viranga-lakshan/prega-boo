import Foundation

struct ChildGrowthRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let childId: UUID
    let createdByUserId: UUID

    let measuredOn: String
    let weightKg: Double
    let heightCm: Double
    let milestones: String?
    let notes: String?

    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case childId = "child_id"
        case createdByUserId = "created_by_user_id"
        case measuredOn = "measured_on"
        case weightKg = "weight_kg"
        case heightCm = "height_cm"
        case milestones
        case notes
        case createdAt = "created_at"
    }
}
