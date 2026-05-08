import Combine
import Foundation

@MainActor
final class MomSessionStore: ObservableObject {
    static let shared = MomSessionStore()

    private static let service = "cw.prega-boo.mom-session"
    private static let userIdAccount = "userId"
    private static let tokenAccount = "accessToken"
    private static let refreshTokenAccount = "refreshToken"

    @Published private(set) var session: AuthSessionContext?

    private init() {
        restore()
    }

    func restore() {
        guard let idString = KeychainHelper.loadString(service: Self.service, account: Self.userIdAccount),
              let userId = UUID(uuidString: idString),
              let token = KeychainHelper.loadString(service: Self.service, account: Self.tokenAccount)
        else {
            session = nil
            return
        }
        let refreshToken = KeychainHelper.loadString(service: Self.service, account: Self.refreshTokenAccount)
        session = AuthSessionContext(userId: userId, accessToken: token, refreshToken: refreshToken)
    }

    func setSession(_ context: AuthSessionContext) {
        session = context
        do {
            try KeychainHelper.save(service: Self.service, account: Self.userIdAccount, value: context.userId.uuidString)
            try KeychainHelper.save(service: Self.service, account: Self.tokenAccount, value: context.accessToken)
            if let refreshToken = context.refreshToken, !refreshToken.isEmpty {
                try KeychainHelper.save(service: Self.service, account: Self.refreshTokenAccount, value: refreshToken)
            } else {
                KeychainHelper.delete(service: Self.service, account: Self.refreshTokenAccount)
            }
        } catch {
            #if DEBUG
            print("MomSessionStore keychain save failed: \(error)")
            #endif
        }
    }

    func clearSession() {
        session = nil
        KeychainHelper.delete(service: Self.service, account: Self.userIdAccount)
        KeychainHelper.delete(service: Self.service, account: Self.tokenAccount)
        KeychainHelper.delete(service: Self.service, account: Self.refreshTokenAccount)
    }

    /// Refreshes the access token using the stored refresh token.
    /// Returns true if the session was refreshed and persisted.
    func refreshSessionIfPossible() async -> Bool {
        guard let current = session,
              let refreshToken = current.refreshToken,
              !refreshToken.isEmpty
        else {
            return false
        }
        do {
            let refreshed = try await SupabaseAuthService().refreshSession(refreshToken: refreshToken)
            setSession(
                AuthSessionContext(
                    userId: refreshed.user.id,
                    accessToken: refreshed.accessToken,
                    refreshToken: refreshed.refreshToken ?? refreshToken
                )
            )
            return true
        } catch {
            return false
        }
    }
}
