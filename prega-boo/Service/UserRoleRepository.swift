import Foundation

final class UserRoleRepository {
    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    /// Inserts a role row for the authenticated user.
    /// Designed for the "mom self-register" case (INSERT only).
    func insertRole(userId: UUID, role: AppRole, accessToken: String) async throws {
        let payload: [[String: String]] = [[
            "user_id": userId.uuidString,
            "role": role.rawValue
        ]]
        let body = try JSONSerialization.data(withJSONObject: payload)

        do {
            _ = try await supabase.request(
                path: "/rest/v1/user_roles",
                method: "POST",
                headers: [
                    "Content-Type": "application/json",
                    "Prefer": "return=minimal",
                    "Authorization": "Bearer \(accessToken)"
                ],
                body: body
            )
        } catch SupabaseServiceError.httpError(let status, let bodyString) {
            // If the row already exists, ignore.
            if status == 409 { return }
            throw SupabaseServiceError.httpError(status: status, body: bodyString)
        }
    }

    func fetchRole(userId: UUID, accessToken: String) async throws -> AppRole? {
        let (data, _) = try await supabase.request(
            path: "/rest/v1/user_roles",
            queryItems: [
                URLQueryItem(name: "select", value: "role"),
                URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString)")
            ],
            headers: [
                "Authorization": "Bearer \(accessToken)"
            ]
        )

        struct RoleOnly: Codable { let role: AppRole }
        let decoded = try JSONDecoder().decode([RoleOnly].self, from: data)
        return decoded.first?.role
    }
}
