import Foundation
import CoreDomain
import SecurityKit

public final class AuthRepositoryAdapter: AuthRepository {
    private let sessionManager: AuthSessionManager
    private let userProvider: @Sendable () async throws -> Clinician

    public init(sessionManager: AuthSessionManager, userProvider: @escaping @Sendable () async throws -> Clinician) {
        self.sessionManager = sessionManager
        self.userProvider = userProvider
    }

    public func currentUser() async throws -> Clinician {
        try await userProvider()
    }

    public func refreshTokenIfNeeded() async throws {
        try await sessionManager.refreshIfNeeded()
    }

    public func accessToken() async throws -> String {
        try await sessionManager.validAccessToken()
    }
}
