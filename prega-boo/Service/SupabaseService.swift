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

        // Only set a default anon Authorization token if the caller did not supply one.
        // (Most authenticated requests pass a user access token.)
        let hasAuthorizationHeader = headers.keys.contains { $0.lowercased() == "authorization" }
        if !hasAuthorizationHeader {
            request.setValue("Bearer \(sanitizedAnonKey)", forHTTPHeaderField: "Authorization")
        }

        // Sanitize headers (especially Authorization) to avoid 401 due to accidental whitespace/newlines.
        headers.forEach { key, value in
            if key.lowercased() == "authorization" {
                request.setValue(value.trimmingCharacters(in: .whitespacesAndNewlines), forHTTPHeaderField: key)
            } else {
                request.setValue(value, forHTTPHeaderField: key)
            }
        }

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
        // Encode each path segment so Storage object names are URL-safe while preserving `/`.
        let encodedPath = path
            .split(separator: "/", omittingEmptySubsequences: false)
            .map { segment -> String in
                String(segment).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String(segment)
            }
            .joined(separator: "/")

        guard let url = URL(string: "/storage/v1/object/\(bucket)/\(encodedPath)", relativeTo: baseURL) else {
            throw SupabaseServiceError.invalidResponse
        }

        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.httpBody = data
        req.setValue(sanitizedAnonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(accessToken.trimmingCharacters(in: .whitespacesAndNewlines))", forHTTPHeaderField: "Authorization")
        req.setValue(contentType, forHTTPHeaderField: "Content-Type")
        req.setValue("true", forHTTPHeaderField: "x-upsert")

        let (respData, resp) = try await URLSession.shared.data(for: req)
        guard let http = resp as? HTTPURLResponse else {
            throw SupabaseServiceError.invalidResponse
        }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: respData, encoding: .utf8) ?? ""
            throw SupabaseServiceError.httpError(status: http.statusCode, body: body)
        }
    }
}
