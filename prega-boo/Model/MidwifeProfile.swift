import Foundation

struct MidwifeProfile: Codable {
    let id: UUID?
    let userId: UUID

    var fullName: String
    var district: String
    var nicNumber: String
    var photoPath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case fullName = "full_name"
        case district
        case nicNumber = "nic_number"
        case photoPath = "photo_path"
    }
}
