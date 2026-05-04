import Foundation

final class GrowthRecordsRepository {
    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    func fetchRecords(momUserId: UUID, accessToken: String) async throws -> [GrowthRecord] {
        let (data, _) = try await supabase.request(
            path: "/rest/v1/growth_records",
            queryItems: [
                URLQueryItem(name: "select", value: "id,mom_user_id,created_by_user_id,measured_on,weight_kg,height_cm,milestones,notes,created_at"),
                URLQueryItem(name: "mom_user_id", value: "eq.\(momUserId.uuidString)"),
                URLQueryItem(name: "order", value: "measured_on.desc,created_at.desc")
            ],
            headers: [
                "Authorization": "Bearer \(accessToken)"
            ]
        )

        return try JSONDecoder().decode([GrowthRecord].self, from: data)
    }

    func insertRecord(
        momUserId: UUID,
        createdByUserId: UUID,
        measuredOnISO: String,
        weightKg: Double,
        heightCm: Double,
        milestones: String?,
        notes: String?,
        accessToken: String
    ) async throws {
        var row: [String: Any] = [
            "mom_user_id": momUserId.uuidString,
            "created_by_user_id": createdByUserId.uuidString,
            "measured_on": measuredOnISO,
            "weight_kg": weightKg,
            "height_cm": heightCm
        ]
        if let milestones, !milestones.isEmpty { row["milestones"] = milestones }
        if let notes, !notes.isEmpty { row["notes"] = notes }

        let payload: [[String: Any]] = [row]
        let body = try JSONSerialization.data(withJSONObject: payload)

        do {
            _ = try await supabase.request(
                path: "/rest/v1/growth_records",
                method: "POST",
                headers: [
                    "Content-Type": "application/json",
                    "Prefer": "return=minimal",
                    "Authorization": "Bearer \(accessToken)"
                ],
                body: body
            )
        } catch SupabaseServiceError.httpError(let status, let body) {
            throw SupabaseServiceError.httpError(
                status: status,
                body: "[DB insert growth_records] \(body)"
            )
        }
    }
}
