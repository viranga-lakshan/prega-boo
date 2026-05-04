import Combine
import Foundation

@MainActor
final class MomSessionStore: ObservableObject {
    static let shared = MomSessionStore()

    private static let service = "cw.prega-boo.mom-session"
    private static let userIdAccount = "userId"
    private static let tokenAccount = "accessToken"

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
        session = AuthSessionContext(userId: userId, accessToken: token)
    }

    func setSession(_ context: AuthSessionContext) {
        session = context
        do {
            try KeychainHelper.save(service: Self.service, account: Self.userIdAccount, value: context.userId.uuidString)
            try KeychainHelper.save(service: Self.service, account: Self.tokenAccount, value: context.accessToken)
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
    }
}
