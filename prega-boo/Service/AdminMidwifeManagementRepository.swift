import Foundation

final class AdminMidwifeManagementRepository {
    private let authService: SupabaseAuthService
    private let roleRepository: UserRoleRepository
    private let midwifeRepository: MidwifeProfileRepository
    private let supabase: SupabaseService

    init(
        authService: SupabaseAuthService = SupabaseAuthService(),
        roleRepository: UserRoleRepository = UserRoleRepository(),
        midwifeRepository: MidwifeProfileRepository = MidwifeProfileRepository(),
        supabase: SupabaseService = .shared
    ) {
        self.authService = authService
        self.roleRepository = roleRepository
        self.midwifeRepository = midwifeRepository
        self.supabase = supabase
    }

    func fetchMidwives(accessToken: String) async throws -> [MidwifeProfile] {
        try await midwifeRepository.fetchAll(accessToken: accessToken)
    }

    func registerMidwife(
        fullName: String,
        district: String,
        nicNumber: String,
        email: String,
        password: String,
        photoData: Data?
    ) async throws {
        let session: SupabaseAuthService.PasswordGrantResponse
        do {
            session = try await authService.signUp(email: email, password: password)
        } catch SupabaseServiceError.httpError(let status, let body) {
            throw SupabaseServiceError.httpError(status: status, body: "[AUTH signup] \(body)")
        }
        let newUserId = session.user.id
        // Use the new midwife session token for self-owned writes.
        // This follows existing self RLS policies and avoids admin-policy dependency.
        let newUserAccessToken = session.accessToken

        do {
            try await roleRepository.upsertRole(
                userId: newUserId,
                role: .midwife,
                accessToken: newUserAccessToken
            )
        } catch SupabaseServiceError.httpError(let status, let body) {
            throw SupabaseServiceError.httpError(status: status, body: "[DB user_roles upsert] \(body)")
        }

        var photoPath: String?
        if let photoData {
            let fileName = "\(UUID().uuidString).jpg"
            let path = "\(newUserId.uuidString.lowercased())/\(fileName)"
            do {
                try await supabase.upload(
                    bucket: "midwife-photos",
                    path: path,
                    data: photoData,
                    contentType: "image/jpeg",
                    accessToken: newUserAccessToken
                )
            } catch SupabaseServiceError.httpError(let status, let body) {
                throw SupabaseServiceError.httpError(status: status, body: "[Storage upload midwife-photos] \(body)")
            }
            photoPath = path
        }

        let profile = MidwifeProfile(
            id: nil,
            userId: newUserId,
            fullName: fullName,
            district: district,
            nicNumber: nicNumber,
            photoPath: photoPath
        )
        do {
            try await midwifeRepository.upsert(profile: profile, accessToken: newUserAccessToken)
        } catch SupabaseServiceError.httpError(let status, let body) {
            throw SupabaseServiceError.httpError(status: status, body: "[DB midwife_profiles upsert] \(body)")
        }
    }
}
