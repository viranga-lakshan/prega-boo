import Foundation

enum SupabaseAuthError: Error {
    case missingSession
    case emailConfirmationRequired
    case invalidInput(String)
}

final class SupabaseAuthService {
    private let supabase: SupabaseService

    init(supabase: SupabaseService = .shared) {
        self.supabase = supabase
    }

    struct AuthUser: Codable {
        let id: UUID
    }

    struct PasswordGrantResponse: Codable {
        let accessToken: String
        let tokenType: String?
        let expiresIn: Int?
        let refreshToken: String?
        let user: AuthUser

        enum CodingKeys: String, CodingKey {
            case accessToken = "access_token"
            case tokenType = "token_type"
            case expiresIn = "expires_in"
            case refreshToken = "refresh_token"
            case user
        }
    }

    struct SignUpResponse: Codable {
        let user: AuthUser?
        let session: PasswordGrantResponse?
    }

    struct SupabaseErrorPayload: Codable {
        let code: String?
        let errorCode: String?
        let msg: String?
        let message: String?
        let error: String?
        let errorDescription: String?

        enum CodingKeys: String, CodingKey {
            case code
            case errorCode = "error_code"
            case msg
            case message
            case error
            case errorDescription = "error_description"
        }

        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)

            if let stringCode = try? container.decodeIfPresent(String.self, forKey: .code) {
                code = stringCode
            } else if let intCode = try? container.decodeIfPresent(Int.self, forKey: .code) {
                code = String(intCode)
            } else {
                code = nil
            }

            errorCode = try? container.decodeIfPresent(String.self, forKey: .errorCode)
            msg = try? container.decodeIfPresent(String.self, forKey: .msg)
            message = try? container.decodeIfPresent(String.self, forKey: .message)
            error = try? container.decodeIfPresent(String.self, forKey: .error)
            errorDescription = try? container.decodeIfPresent(String.self, forKey: .errorDescription)
        }
    }

    static func humanMessage(fromBody body: String) -> String {
        guard let data = body.data(using: .utf8),
              let payload = try? JSONDecoder().decode(SupabaseErrorPayload.self, from: data)
        else {
            return body.isEmpty ? "Unknown error" : body
        }

        return payload.msg
            ?? payload.errorDescription
            ?? payload.message
            ?? payload.error
            ?? (body.isEmpty ? "Unknown error" : body)
    }

    private static func looksLikeAlreadyRegistered(_ body: String) -> Bool {
        let message = humanMessage(fromBody: body).lowercased()
        return message.contains("already")
            || message.contains("registered")
            || message.contains("exists")
            || body.lowercased().contains("user_already_exists")
            || body.lowercased().contains("email_exists")
    }

    /// Creates an auth user if needed, then signs in to obtain an access token.
    /// This works even when email confirmations are enabled (sign-in is the source of truth).
    func signUpThenSignIn(email: String, password: String) async throws -> PasswordGrantResponse {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedEmail.contains("@"), trimmedEmail.contains(".") else {
            throw SupabaseAuthError.invalidInput("Please enter a valid email address.")
        }
        guard password.count >= 6 else {
            throw SupabaseAuthError.invalidInput("Password must be at least 6 characters.")
        }

        do {
            let signUpSession = try await signUp(email: trimmedEmail, password: password)
            return signUpSession
        } catch SupabaseServiceError.httpError(_, let body) {
            // If the user already exists, fall back to sign-in.
            if Self.looksLikeAlreadyRegistered(body) {
                return try await signIn(email: trimmedEmail, password: password)
            }

            let msg = Self.humanMessage(fromBody: body)
            if msg.lowercased().contains("confirm") && msg.lowercased().contains("email") {
                throw SupabaseAuthError.emailConfirmationRequired
            }
            throw SupabaseAuthError.invalidInput(msg)
        }
    }

    /// Returns a usable session if email confirmations are disabled.
    /// If email confirmations are enabled, the response may not include a session.
    func signUp(email: String, password: String) async throws -> PasswordGrantResponse {
        let payload = ["email": email, "password": password]
        let body = try JSONSerialization.data(withJSONObject: payload)

        let (data, _) = try await supabase.request(
            path: "/auth/v1/signup",
            method: "POST",
            headers: ["Content-Type": "application/json"],
            body: body
        )

        // Some Supabase setups return token fields at the top-level (same shape as password grant).
        if let session = try? JSONDecoder().decode(PasswordGrantResponse.self, from: data) {
            return session
        }

        let decoded = try JSONDecoder().decode(SignUpResponse.self, from: data)
        if let session = decoded.session {
            return session
        }

        throw SupabaseAuthError.emailConfirmationRequired
    }

    func signIn(email: String, password: String) async throws -> PasswordGrantResponse {
        let payload = ["email": email, "password": password]
        let body = try JSONSerialization.data(withJSONObject: payload)

        let (data, _) = try await supabase.request(
            path: "/auth/v1/token",
            method: "POST",
            queryItems: [URLQueryItem(name: "grant_type", value: "password")],
            headers: ["Content-Type": "application/json"],
            body: body
        )

        return try JSONDecoder().decode(PasswordGrantResponse.self, from: data)
    }
}
