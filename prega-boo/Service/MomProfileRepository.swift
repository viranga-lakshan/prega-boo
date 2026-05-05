import Foundation

final class MomProfileRepository {
    private let supabase: SupabaseService
    private let offlineStore: CoreDataOfflineStore

    init(supabase: SupabaseService = .shared, offlineStore: CoreDataOfflineStore = .shared) {
        self.supabase = supabase
        self.offlineStore = offlineStore
    }

    /// Insert or update the current user's mom profile.
    /// Requires the user to be authenticated and `userId` to match auth.uid() due to RLS.
    func upsert(profile: MomProfile, accessToken: String) async throws {
        let data = try JSONEncoder().encode([profile])
        _ = try await supabase.request(
            path: "/rest/v1/mom_profiles",
            method: "POST",
            queryItems: [URLQueryItem(name: "on_conflict", value: "user_id")],
            headers: [
                "Content-Type": "application/json",
                "Prefer": "resolution=merge-duplicates,return=minimal",
                "Authorization": "Bearer \(accessToken)"
            ],
            body: data
        )
        offlineStore.cacheMomProfile(profile)
    }

    func fetchOwnProfile(userId: UUID, accessToken: String) async throws -> MomProfile? {
        do {
            let (data, _) = try await supabase.request(
                path: "/rest/v1/mom_profiles",
                queryItems: [
                    URLQueryItem(name: "select", value: "*"),
                    URLQueryItem(name: "user_id", value: "eq.\(userId.uuidString)")
                ],
                headers: [
                    "Authorization": "Bearer \(accessToken)"
                ]
            )

            let decoded = try JSONDecoder().decode([MomProfile].self, from: data)
            if let profile = decoded.first {
                offlineStore.cacheMomProfile(profile)
                return profile
            }
            return nil
        } catch {
            if let cached = offlineStore.loadMomProfile(userId: userId) {
                return cached
            }
            throw error
        }
    }

    func uploadProfilePhoto(userId: UUID, photoData: Data, accessToken: String) async throws -> String {
        let fileName = "\(UUID().uuidString).jpg"
        let path = "\(userId.uuidString)/\(fileName)"
        try await supabase.upload(
            bucket: "mom-photos",
            path: path,
            data: photoData,
            contentType: "image/jpeg",
            accessToken: accessToken
        )
        return path
    }
}
