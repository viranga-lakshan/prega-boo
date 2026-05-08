import Foundation

struct AuthSessionContext: Hashable {
    let userId: UUID
    let accessToken: String
    let refreshToken: String?

    init(userId: UUID, accessToken: String, refreshToken: String? = nil) {
        self.userId = userId
        self.accessToken = accessToken
        self.refreshToken = refreshToken
    }
}
