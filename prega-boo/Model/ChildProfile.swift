import Foundation

struct ChildProfile: Identifiable, Codable, Hashable {
    let id: UUID
    let momUserId: UUID

    var fullName: String
    var birthDate: String

    var gender: String?
    var deliveryMethod: String?
    var notes: String?
    var idPhotoPath: String?

    enum CodingKeys: String, CodingKey {
        case id
        case momUserId = "mom_user_id"
        case fullName = "full_name"
        case birthDate = "birth_date"
        case gender
        case deliveryMethod = "delivery_method"
        case notes
        case idPhotoPath = "id_photo_path"
    }
}
