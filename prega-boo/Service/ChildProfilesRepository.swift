import Foundation

final class ChildProfilesRepository {
    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    func fetchChildren(momUserId: UUID, accessToken: String) async throws -> [ChildProfile] {
        let (data, _) = try await supabase.request(
            path: "/rest/v1/child_profiles",
            queryItems: [
                URLQueryItem(name: "select", value: "id,mom_user_id,full_name,birth_date"),
                URLQueryItem(name: "mom_user_id", value: "eq.\(momUserId.uuidString)"),
                URLQueryItem(name: "order", value: "created_at.desc")
            ],
            headers: [
                "Authorization": "Bearer \(accessToken)"
            ]
        )

        return try JSONDecoder().decode([ChildProfile].self, from: data)
    }

    func insertChild(
        momUserId: UUID,
        fullName: String,
        birthDateISO: String,
        gender: String?,
        deliveryMethod: String?,
        notes: String?,
        idPhotoPath: String?,
        accessToken: String
    ) async throws {
        var row: [String: Any] = [
            "mom_user_id": momUserId.uuidString,
            "full_name": fullName,
            "birth_date": birthDateISO
        ]
        if let gender, !gender.isEmpty { row["gender"] = gender }
        if let deliveryMethod, !deliveryMethod.isEmpty { row["delivery_method"] = deliveryMethod }
        if let notes, !notes.isEmpty { row["notes"] = notes }
        if let idPhotoPath, !idPhotoPath.isEmpty { row["id_photo_path"] = idPhotoPath }

        let payload: [[String: Any]] = [row]
        let body = try JSONSerialization.data(withJSONObject: payload)

        _ = try await supabase.request(
            path: "/rest/v1/child_profiles",
            method: "POST",
            headers: [
                "Content-Type": "application/json",
                "Prefer": "return=minimal",
                "Authorization": "Bearer \(accessToken)"
            ],
            body: body
        )
    }
}
