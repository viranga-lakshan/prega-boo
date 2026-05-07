import Foundation

/// PostgREST repository for `public.mom_journal_notes`.
final class MomJournalNotesRepository {
    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    /// Notes for a mom, newest first.
    /// - Parameters:
    ///   - momUserId: the mom whose notes we want.
    ///   - childId: when `nil`, returns only mom-level notes (rows where `child_id IS NULL`).
    ///              when set, returns only baby-specific notes (rows where `child_id = childId`).
    func fetchNotes(momUserId: UUID, childId: UUID? = nil, accessToken: String) async throws -> [MomJournalNote] {
        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "select", value: "id,mom_user_id,created_by_user_id,author_role,child_id,title,body,created_at,updated_at"),
            URLQueryItem(name: "mom_user_id", value: "eq.\(momUserId.uuidString)"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ]
        if let childId {
            queryItems.append(URLQueryItem(name: "child_id", value: "eq.\(childId.uuidString)"))
        } else {
            queryItems.append(URLQueryItem(name: "child_id", value: "is.null"))
        }

        let (data, _) = try await supabase.request(
            path: "/rest/v1/mom_journal_notes",
            queryItems: queryItems,
            headers: [
                "Authorization": "Bearer \(accessToken)"
            ]
        )

        return try JSONDecoder().decode([MomJournalNote].self, from: data)
    }

    func insertNote(
        momUserId: UUID,
        createdByUserId: UUID,
        authorRole: String,
        childId: UUID?,
        title: String,
        body: String,
        accessToken: String
    ) async throws {
        var row: [String: Any] = [
            "mom_user_id": momUserId.uuidString,
            "created_by_user_id": createdByUserId.uuidString,
            "author_role": authorRole,
            "title": title,
            "body": body
        ]
        if let childId {
            row["child_id"] = childId.uuidString
        }

        let payload: [[String: Any]] = [row]
        let bodyData = try JSONSerialization.data(withJSONObject: payload)

        do {
            _ = try await supabase.request(
                path: "/rest/v1/mom_journal_notes",
                method: "POST",
                headers: [
                    "Content-Type": "application/json",
                    "Prefer": "return=minimal",
                    "Authorization": "Bearer \(accessToken)"
                ],
                body: bodyData
            )
        } catch SupabaseServiceError.httpError(let status, let respBody) {
            throw SupabaseServiceError.httpError(
                status: status,
                body: "[DB insert mom_journal_notes] \(respBody)"
            )
        }
    }

    func updateNote(noteId: UUID, title: String, body: String, accessToken: String) async throws {
        let row: [String: Any] = [
            "title": title,
            "body": body
        ]
        let bodyData = try JSONSerialization.data(withJSONObject: row)

        do {
            _ = try await supabase.request(
                path: "/rest/v1/mom_journal_notes",
                method: "PATCH",
                queryItems: [
                    URLQueryItem(name: "id", value: "eq.\(noteId.uuidString)")
                ],
                headers: [
                    "Content-Type": "application/json",
                    "Prefer": "return=minimal",
                    "Authorization": "Bearer \(accessToken)"
                ],
                body: bodyData
            )
        } catch SupabaseServiceError.httpError(let status, let respBody) {
            throw SupabaseServiceError.httpError(
                status: status,
                body: "[DB patch mom_journal_notes] \(respBody)"
            )
        }
    }

    func deleteNote(noteId: UUID, accessToken: String) async throws {
        do {
            _ = try await supabase.request(
                path: "/rest/v1/mom_journal_notes",
                method: "DELETE",
                queryItems: [
                    URLQueryItem(name: "id", value: "eq.\(noteId.uuidString)")
                ],
                headers: [
                    "Authorization": "Bearer \(accessToken)"
                ]
            )
        } catch SupabaseServiceError.httpError(let status, let respBody) {
            throw SupabaseServiceError.httpError(
                status: status,
                body: "[DB delete mom_journal_notes] \(respBody)"
            )
        }
    }
}
