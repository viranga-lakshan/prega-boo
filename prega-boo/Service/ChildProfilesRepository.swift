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
        photoData: Data?,
        accessToken: String
    ) async throws {
        var finalPhotoPath = idPhotoPath

        // If we have photo data, upload it first
        if let photoData = photoData {
            let fileName = "\(UUID().uuidString).jpg"
            let storagePath = "\(momUserId.uuidString)/\(fileName)"
            
            try await supabase.upload(
                bucket: "child-photos",
                path: storagePath,
                data: photoData,
                contentType: "image/jpeg",
                accessToken: accessToken
            )
            
            finalPhotoPath = storagePath
        }

        var row: [String: Any] = [
            "mom_user_id": momUserId.uuidString,
            "full_name": fullName,
            "birth_date": birthDateISO
        ]
        if let gender, !gender.isEmpty { row["gender"] = gender }
        if let deliveryMethod, !deliveryMethod.isEmpty { row["delivery_method"] = deliveryMethod }
        if let notes, !notes.isEmpty { row["notes"] = notes }
        if let finalPhotoPath, !finalPhotoPath.isEmpty { row["id_photo_path"] = finalPhotoPath }

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
