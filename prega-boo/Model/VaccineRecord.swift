import Foundation

struct VaccineRecord: Codable, Identifiable, Hashable {
    let id: UUID
    let momUserId: UUID
    let createdByUserId: UUID
    let vaccineName: String
    let dosage: String
    let administeredOn: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case momUserId = "mom_user_id"
        case createdByUserId = "created_by_user_id"
        case vaccineName = "vaccine_name"
        case dosage
        case administeredOn = "administered_on"
        case createdAt = "created_at"
    }
}
