import Foundation

final class MidwifeProfileRepository {
    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    func upsert(profile: MidwifeProfile, accessToken: String) async throws {
        let data = try JSONEncoder().encode([profile])
        _ = try await supabase.request(
            path: "/rest/v1/midwife_profiles",
            method: "POST",
            queryItems: [URLQueryItem(name: "on_conflict", value: "user_id")],
            headers: [
                "Content-Type": "application/json",
                "Prefer": "resolution=merge-duplicates,return=minimal",
                "Authorization": "Bearer \(accessToken)"
            ],
            body: data
        )
    }

    func fetchOwnProfile(userId: UUID, accessToken: String) async throws -> MidwifeProfile? {
        let (data, _) = try await supabase.request(
            path: "/rest/v1/midwife_profiles",
            queryItems: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString)")
            ],
            headers: [
                "Authorization": "Bearer \(accessToken)"
            ]
        )

        let decoded = try JSONDecoder().decode([MidwifeProfile].self, from: data)
        return decoded.first
    }
}
