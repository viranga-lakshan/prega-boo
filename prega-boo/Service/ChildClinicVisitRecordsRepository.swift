import Foundation

final class ChildClinicVisitRecordsRepository {
    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    func fetchRecords(childId: UUID, accessToken: String) async throws -> [ChildClinicVisitRecord] {
        let (data, _) = try await supabase.request(
            path: "/rest/v1/child_clinic_visit_records",
            queryItems: [
                URLQueryItem(name: "select", value: "id,child_id,created_by_user_id,visit_date,visit_time,purpose,created_at"),
                URLQueryItem(name: "child_id", value: "eq.\(childId.uuidString)"),
                URLQueryItem(name: "order", value: "visit_date.desc,created_at.desc")
            ],
            headers: [
                "Authorization": "Bearer \(accessToken)"
            ]
        )

        return try JSONDecoder().decode([ChildClinicVisitRecord].self, from: data)
    }

    func insertRecord(
        childId: UUID,
        createdByUserId: UUID,
        visitDateISO: String,
        visitTimeText: String,
        purpose: String,
        accessToken: String
    ) async throws {
        let row: [String: Any] = [
            "child_id": childId.uuidString,
            "created_by_user_id": createdByUserId.uuidString,
            "visit_date": visitDateISO,
            "visit_time": visitTimeText,
            "purpose": purpose
        ]

        let payload: [[String: Any]] = [row]
        let body = try JSONSerialization.data(withJSONObject: payload)

        do {
            _ = try await supabase.request(
                path: "/rest/v1/child_clinic_visit_records",
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
                body: "[DB insert child_clinic_visit_records] \(body)"
            )
        }
    }
}
