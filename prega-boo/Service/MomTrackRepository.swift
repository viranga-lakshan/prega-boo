import Foundation

final class MomTrackRepository {
    private let supabase: SupabaseService
    private let offlineStore: CoreDataOfflineStore

    init(supabase: SupabaseService = .shared, offlineStore: CoreDataOfflineStore = .shared) {
        self.supabase = supabase
        self.offlineStore = offlineStore
    }

    func fetchEntries(momUserId: UUID, kind: MomTrackerKind, accessToken: String) async throws -> [MomTrackEntry] {
        do {
            let (data, _) = try await supabase.request(
                path: "/rest/v1/mom_track_entries",
                queryItems: [
                    URLQueryItem(name: "select", value: "id,mom_user_id,tracker_type,entry_date,value_numeric,value_text,note,created_at"),
                    URLQueryItem(name: "mom_user_id", value: "eq.\(momUserId.uuidString)"),
                    URLQueryItem(name: "tracker_type", value: "eq.\(kind.rawValue)"),
                    URLQueryItem(name: "order", value: "entry_date.desc,created_at.desc")
                ],
                headers: [
                    "Authorization": "Bearer \(accessToken)"
                ]
            )
            let entries = try JSONDecoder().decode([MomTrackEntry].self, from: data)
            offlineStore.cacheTrackEntries(entries, momUserId: momUserId, kind: kind)
            return entries
        } catch {
            let cached = offlineStore.loadTrackEntries(momUserId: momUserId, kind: kind)
            if !cached.isEmpty { return cached }
            throw error
        }
    }

    func insertEntry(
        momUserId: UUID,
        kind: MomTrackerKind,
        entryDateISO: String,
        valueNumeric: Double?,
        valueText: String?,
        note: String?,
        accessToken: String
    ) async throws {
        var row: [String: Any] = [
            "mom_user_id": momUserId.uuidString,
            "tracker_type": kind.rawValue,
            "entry_date": entryDateISO
        ]
        if let valueNumeric { row["value_numeric"] = valueNumeric }
        if let valueText, !valueText.isEmpty { row["value_text"] = valueText }
        if let note, !note.isEmpty { row["note"] = note }

        let payload = try JSONSerialization.data(withJSONObject: [row])
        _ = try await supabase.request(
            path: "/rest/v1/mom_track_entries",
            method: "POST",
            headers: [
                "Content-Type": "application/json",
                "Prefer": "return=minimal",
                "Authorization": "Bearer \(accessToken)"
            ],
            body: payload
        )
        let offlineEntry = MomTrackEntry(
            id: UUID(),
            momUserId: momUserId,
            trackerType: kind.rawValue,
            entryDate: entryDateISO,
            valueNumeric: valueNumeric,
            valueText: valueText,
            note: note,
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        let existing = offlineStore.loadTrackEntries(momUserId: momUserId, kind: kind)
        offlineStore.cacheTrackEntries([offlineEntry] + existing, momUserId: momUserId, kind: kind)
    }
}
