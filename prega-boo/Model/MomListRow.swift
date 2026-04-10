import Foundation

struct MomListRow: Identifiable, Codable, Hashable {
    let id: UUID
    let userId: UUID

    let fullName: String
    let district: String

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case fullName = "full_name"
        case district
    }

    /// Stable numeric-looking ID for UI display.
    /// Derived from the UUID bytes so it remains consistent.
    var displayId: String {
        var value: UInt64 = 0
        withUnsafeBytes(of: userId.uuid) { raw in
            let bytes = raw.bindMemory(to: UInt8.self)
            for index in 0..<min(8, bytes.count) {
                value = (value << 8) | UInt64(bytes[index])
            }
        }
        return String(value)
    }
}
