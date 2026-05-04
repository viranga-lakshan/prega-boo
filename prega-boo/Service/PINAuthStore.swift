import CryptoKit
import Foundation

/// Stores a salted SHA-256 hash of the app PIN in the Keychain (PIN itself is never stored).
final class PINAuthStore {
    static let shared = PINAuthStore()

    private let service = "cw.prega-boo.app-pin"
    private let account = "pinHash"

    private init() {}

    var hasPIN: Bool {
        KeychainHelper.loadString(service: service, account: account) != nil
    }

    private static func hash(pin: String) -> String {
        let salt = "prega-boo.app-lock.v1"
        let payload = "\(salt)|\(pin)"
        let digest = SHA256.hash(data: Data(payload.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    func setPIN(_ pin: String) throws {
        guard pin.count == 4, pin.allSatisfy(\.isNumber) else {
            throw PINError.invalidFormat
        }
        let hashed = Self.hash(pin: pin)
        try KeychainHelper.save(service: service, account: account, value: hashed)
    }

    func verifyPIN(_ pin: String) -> Bool {
        guard let stored = KeychainHelper.loadString(service: service, account: account) else { return false }
        return stored == Self.hash(pin: pin)
    }

    func clearPIN() {
        KeychainHelper.delete(service: service, account: account)
    }

    enum PINError: Error {
        case invalidFormat
    }
}
