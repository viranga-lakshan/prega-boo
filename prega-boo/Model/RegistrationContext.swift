import Foundation

struct RegistrationContext: Hashable {
    let userId: UUID
    let accessToken: String
    let refreshToken: String?

    var fullName: String
    var contactNumber: String
    var district: String
    var photoPath: String?
}
