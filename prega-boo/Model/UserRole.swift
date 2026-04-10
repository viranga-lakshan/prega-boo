import Foundation

enum AppRole: String, Codable {
    case mom
    case midwife
    case admin
}

struct UserRoleRow: Codable {
    let userId: UUID
    let role: AppRole

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case role
    }
}
