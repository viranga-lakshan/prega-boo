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

    func fetchAll(accessToken: String) async throws -> [MidwifeProfile] {
        let (data, _) = try await supabase.request(
            path: "/rest/v1/midwife_profiles",
            queryItems: [
                URLQueryItem(name: "select", value: "*"),
                URLQueryItem(name: "order", value: "created_at.desc")
            ],
            headers: [
                "Authorization": "Bearer \(accessToken)"
            ]
        )
        return try JSONDecoder().decode([MidwifeProfile].self, from: data)
    }

    /// Upload (or replace) the current midwife's profile photo into the `midwife-photos` bucket.
    /// Storage RLS requires the first path segment to be the user's auth uid (lower-cased).
    func uploadProfilePhoto(userId: UUID, photoData: Data, accessToken: String) async throws -> String {
        let fileName = "\(UUID().uuidString).jpg"
        let path = "\(userId.uuidString.lowercased())/\(fileName)"
        do {
            try await supabase.upload(
                bucket: "midwife-photos",
                path: path,
                data: photoData,
                contentType: "image/jpeg",
                accessToken: accessToken
            )
        } catch SupabaseServiceError.httpError(let status, let body) {
            throw SupabaseServiceError.httpError(
                status: status,
                body: "[Storage upload midwife-photos] \(body)"
            )
        }
        return path
    }

    func fetchProfilePhoto(path: String, accessToken: String) async throws -> Data {
        let encodedPath = path
            .split(separator: "/", omittingEmptySubsequences: false)
            .map { part -> String in
                String(part).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String(part)
            }
            .joined(separator: "/")

        let (data, _) = try await supabase.request(
            path: "/storage/v1/object/authenticated/midwife-photos/\(encodedPath)",
            headers: [
                "Authorization": "Bearer \(accessToken)"
            ]
        )
        return data
    }
}
