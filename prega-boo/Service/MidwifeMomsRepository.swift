import Foundation

final class MidwifeMomsRepository {
    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    func fetchMoms(accessToken: String, limit: Int, offset: Int) async throws -> [MomListRow] {
        let queryItems: [URLQueryItem] = [
            URLQueryItem(name: "select", value: "id,user_id,full_name,district"),
            URLQueryItem(name: "order", value: "created_at.desc"),
            URLQueryItem(name: "limit", value: String(limit)),
            URLQueryItem(name: "offset", value: String(offset))
        ]

        let (data, _) = try await supabase.request(
            path: "/rest/v1/mom_profiles",
            queryItems: queryItems,
            headers: [
                "Authorization": "Bearer \(accessToken)"
            ]
        )

        return try JSONDecoder().decode([MomListRow].self, from: data)
    }
}
