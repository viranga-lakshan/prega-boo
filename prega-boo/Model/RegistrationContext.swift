import Foundation

struct RegistrationContext: Hashable {
    let userId: UUID
    let accessToken: String

    var fullName: String
    var contactNumber: String
    var district: String
}
