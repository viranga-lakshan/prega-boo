import Foundation

final class VaccineRecordsRepository {
    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    func fetchRecords(momUserId: UUID, accessToken: String) async throws -> [VaccineRecord] {
        let (data, _) = try await supabase.request(
            path: "/rest/v1/vaccine_records",
            queryItems: [
                URLQueryItem(name: "select", value: "id,mom_user_id,created_by_user_id,vaccine_name,dosage,administered_on,created_at"),
                URLQueryItem(name: "mom_user_id", value: "eq.\(momUserId.uuidString)"),
                URLQueryItem(name: "order", value: "administered_on.desc,created_at.desc")
            ],
            headers: [
                "Authorization": "Bearer \(accessToken)"
            ]
        )

        return try JSONDecoder().decode([VaccineRecord].self, from: data)
    }

    func insertRecord(
        momUserId: UUID,
        createdByUserId: UUID,
        vaccineName: String,
        dosage: String,
        administeredOnISO: String,
        accessToken: String
    ) async throws {
        let row: [String: Any] = [
            "mom_user_id": momUserId.uuidString,
            "created_by_user_id": createdByUserId.uuidString,
            "vaccine_name": vaccineName,
            "dosage": dosage,
            "administered_on": administeredOnISO
        ]

        let payload: [[String: Any]] = [row]
        let body = try JSONSerialization.data(withJSONObject: payload)

        do {
            _ = try await supabase.request(
                path: "/rest/v1/vaccine_records",
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
                body: "[DB insert vaccine_records] \(body)"
            )
        }
    }
}
