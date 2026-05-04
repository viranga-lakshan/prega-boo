import Foundation

final class ChildGrowthRecordsRepository {
    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    func fetchRecords(childId: UUID, accessToken: String) async throws -> [ChildGrowthRecord] {
        let (data, _) = try await supabase.request(
            path: "/rest/v1/child_growth_records",
            queryItems: [
                URLQueryItem(name: "select", value: "id,child_id,created_by_user_id,measured_on,weight_kg,height_cm,milestones,notes,created_at"),
                URLQueryItem(name: "child_id", value: "eq.\(childId.uuidString)"),
                URLQueryItem(name: "order", value: "measured_on.desc,created_at.desc")
            ],
            headers: [
                "Authorization": "Bearer \(accessToken)"
            ]
        )

        return try JSONDecoder().decode([ChildGrowthRecord].self, from: data)
    }

    func insertRecord(
        childId: UUID,
        createdByUserId: UUID,
        measuredOnISO: String,
        weightKg: Double,
        heightCm: Double,
        milestones: String?,
        notes: String?,
        accessToken: String
    ) async throws {
        var row: [String: Any] = [
            "child_id": childId.uuidString,
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
                path: "/rest/v1/child_growth_records",
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
                body: "[DB insert child_growth_records] \(body)"
            )
        }
    }
}
