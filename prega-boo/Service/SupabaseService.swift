import Foundation

enum SupabaseServiceError: Error {
    case invalidResponse
    case httpError(status: Int, body: String)
}

final class SupabaseService {
    static let shared = SupabaseService(
        baseURL: SupabaseSecrets.url,
        anonKey: SupabaseSecrets.anonKey
    )

    private let baseURL: URL
    private let anonKey: String

    private var sanitizedAnonKey: String {
        anonKey
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\"", with: "")
    }

    init(baseURL: URL, anonKey: String) {
        self.baseURL = baseURL
        self.anonKey = anonKey
    }

    func healthCheck() async throws {
        _ = try await request(path: "/auth/v1/health")
    }

    /// Raw REST request helper. Use for /rest/v1 queries.
    func request(
        path: String,
        method: String = "GET",
        queryItems: [URLQueryItem] = [],
        headers: [String: String] = [:],
        body: Data? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)
        if !queryItems.isEmpty {
            components?.queryItems = queryItems
        }
        guard let url = components?.url else {
            throw SupabaseServiceError.invalidResponse
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(sanitizedAnonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(sanitizedAnonKey)", forHTTPHeaderField: "Authorization")

        headers.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw SupabaseServiceError.invalidResponse
        }

        if (200..<300).contains(http.statusCode) {
            return (data, http)
        }

        let bodyString = String(data: data, encoding: .utf8) ?? ""
        throw SupabaseServiceError.httpError(status: http.statusCode, body: bodyString)
    }

    /// Convenience: `select *` from a table via PostgREST.
    func selectAll(from table: String) async throws -> Data {
        try await request(
            path: "/rest/v1/\(table)",
            queryItems: [URLQueryItem(name: "select", value: "*")]
        ).0
    }

    /// Upload a file to Supabase Storage.
    func upload(
        bucket: String,
        path: String,
        data: Data,
        contentType: String,
        accessToken: String
    ) async throws {
        // path should be e.g. "child-photos/my-image.jpg"
        let fullPath = "/storage/v1/object/\(bucket)/\(path)"
        
        _ = try await request(
            path: fullPath,
            method: "POST",
            headers: [
                "Authorization": "Bearer \(accessToken)",
                "Content-Type": contentType,
                "x-upsert": "true"
            ],
            body: data
        )
    }
}
