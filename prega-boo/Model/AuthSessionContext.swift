import Foundation

struct AuthSessionContext: Hashable {
    let userId: UUID
    let accessToken: String
}
