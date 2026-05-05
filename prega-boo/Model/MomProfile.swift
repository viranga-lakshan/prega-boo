import Foundation

struct MomProfile: Codable {
    let id: UUID?
    let userId: UUID

    var fullName: String
    var contactNumber: String
    var district: String
    var lmpDate: String?
    var photoPath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case fullName = "full_name"
        case contactNumber = "contact_number"
        case district
        case lmpDate = "lmp_date"
        case photoPath = "photo_path"
    }
}
