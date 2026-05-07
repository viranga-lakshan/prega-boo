import AuthenticationServices
import CryptoKit
import Foundation
import Security
import UIKit

/// Google sign-in via Supabase Auth PKCE + `ASWebAuthenticationSession`.
/// Add this exact URL to Supabase → Authentication → URL Configuration → Redirect URLs:
/// `cw.prega-boo://login-callback`
enum SupabaseGoogleOAuthService {
    static let callbackURLScheme = "cw.prega-boo"
    static let redirectURL = "\(callbackURLScheme)://login-callback"

    @MainActor
    static func signInWithGoogle() async throws -> SupabaseAuthService.PasswordGrantResponse {
        try validateSupabaseURLForDeviceOAuth()

        let verifier = makeCodeVerifier()
        let challenge = codeChallenge(from: verifier)

        var components = URLComponents(url: SupabaseSecrets.url, resolvingAgainstBaseURL: false)
        components?.path = "/auth/v1/authorize"
        components?.queryItems = [
            URLQueryItem(name: "provider", value: "google"),
            URLQueryItem(name: "redirect_to", value: redirectURL),
            URLQueryItem(name: "code_challenge", value: challenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]
        guard let authURL = components?.url else {
            throw SupabaseAuthError.invalidInput("Could not build Google sign-in URL.")
        }

        let callbackURL = try await startWebAuthSession(url: authURL)

        guard let items = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?.queryItems else {
            throw SupabaseAuthError.invalidInput("Google sign-in returned an invalid redirect URL.")
        }
        if let err = items.first(where: { $0.name == "error" })?.value, !err.isEmpty {
            let desc = items.first(where: { $0.name == "error_description" })?.value ?? err
            throw SupabaseAuthError.invalidInput(desc.replacingOccurrences(of: "+", with: " "))
        }
        guard
            let code = items.first(where: { $0.name == "code" })?.value,
            !code.isEmpty
        else {
            throw SupabaseAuthError.invalidInput("Google sign-in did not return an authorization code.")
        }

        let payload: [String: String] = [
            "auth_code": code,
            "code_verifier": verifier
        ]
        let body = try JSONSerialization.data(withJSONObject: payload)

        let (data, _) = try await SupabaseService.shared.request(
            path: "/auth/v1/token",
            method: "POST",
            queryItems: [URLQueryItem(name: "grant_type", value: "pkce")],
            headers: ["Content-Type": "application/json"],
            body: body
        )

        return try JSONDecoder().decode(SupabaseAuthService.PasswordGrantResponse.self, from: data)
    }

    /// OAuth must use your hosted project URL. Local URLs (`localhost` / `127.0.0.1`) are unreachable from the device/simulator and Safari shows “couldn’t connect to the server”.
    private static func validateSupabaseURLForDeviceOAuth() throws {
        guard let host = SupabaseSecrets.url.host?.lowercased(), !host.isEmpty else {
            throw SupabaseAuthError.invalidInput(
                "Supabase URL has no host. Set SupabaseSecrets.url to https://<project-ref>.supabase.co (Project Settings → API)."
            )
        }
        if host == "localhost" || host == "127.0.0.1" || host.hasSuffix(".local") {
            throw SupabaseAuthError.invalidInput(
                "Google sign-in cannot use a local Supabase URL on iPhone. In SupabaseSecrets.swift set url to your cloud project: https://<project-ref>.supabase.co"
            )
        }
    }

    private static func makeCodeVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        precondition(status == errSecSuccess)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private static func codeChallenge(from verifier: String) -> String {
        let data = Data(verifier.utf8)
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    @MainActor
    private static func startWebAuthSession(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: callbackURLScheme) { callback, error in
                if let error {
                    let ns = error as NSError
                    if ns.domain == ASWebAuthenticationSessionError.errorDomain,
                       ns.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: SupabaseAuthError.invalidInput("Sign-in was cancelled."))
                    } else {
                        continuation.resume(throwing: error)
                    }
                    return
                }
                guard let callback else {
                    continuation.resume(throwing: SupabaseAuthError.invalidInput("No redirect URL returned."))
                    return
                }
                continuation.resume(returning: callback)
            }
            session.presentationContextProvider = OAuthPresentationAnchor.shared
            session.prefersEphemeralWebBrowserSession = false
            if !session.start() {
                continuation.resume(throwing: SupabaseAuthError.invalidInput("Could not start sign-in browser."))
            }
        }
    }
}

private final class OAuthPresentationAnchor: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = OAuthPresentationAnchor()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard
            let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let window = scene.windows.first(where: \.isKeyWindow) ?? scene.windows.first
        else {
            return ASPresentationAnchor()
        }
        return window
    }
}
