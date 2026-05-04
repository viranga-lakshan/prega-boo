import Foundation

final class ChildVaccineRecordsRepository {
    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    func fetchRecords(childId: UUID, accessToken: String) async throws -> [ChildVaccineRecord] {
        let (data, _) = try await supabase.request(
            path: "/rest/v1/child_vaccine_records",
            queryItems: [
                URLQueryItem(name: "select", value: "id,child_id,created_by_user_id,administered_on,vaccine_name,dosage,created_at"),
                URLQueryItem(name: "child_id", value: "eq.\(childId.uuidString)"),
                URLQueryItem(name: "order", value: "administered_on.desc,created_at.desc")
            ],
            headers: [
                "Authorization": "Bearer \(accessToken)"
            ]
        )

        return try JSONDecoder().decode([ChildVaccineRecord].self, from: data)
    }

    func insertRecord(
        childId: UUID,
        createdByUserId: UUID,
        administeredOnISO: String,
        vaccineName: String,
        dosage: String,
        accessToken: String
    ) async throws {
        let row: [String: Any] = [
            "child_id": childId.uuidString,
            "created_by_user_id": createdByUserId.uuidString,
            "administered_on": administeredOnISO,
            "vaccine_name": vaccineName,
            "dosage": dosage
        ]

        let payload: [[String: Any]] = [row]
        let body = try JSONSerialization.data(withJSONObject: payload)

        do {
            _ = try await supabase.request(
                path: "/rest/v1/child_vaccine_records",
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
                body: "[DB insert child_vaccine_records] \(body)"
            )
        }
    }
}
