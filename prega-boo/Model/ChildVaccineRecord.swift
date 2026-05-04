import Foundation

struct ChildVaccineRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let childId: UUID
    let createdByUserId: UUID

    let administeredOn: String
    let vaccineName: String
    let dosage: String

    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case childId = "child_id"
        case createdByUserId = "created_by_user_id"
        case administeredOn = "administered_on"
        case vaccineName = "vaccine_name"
        case dosage
        case createdAt = "created_at"
    }
}
