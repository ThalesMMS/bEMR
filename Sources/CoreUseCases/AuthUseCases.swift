import Foundation
import CoreDomain

public struct RefreshSessionUseCase: Sendable {
    private let authRepository: AuthRepository

    public init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    public func execute() async throws {
        try await authRepository.refreshTokenIfNeeded()
    }
}

public struct CurrentUserUseCase: Sendable {
    private let authRepository: AuthRepository

    public init(authRepository: AuthRepository) {
        self.authRepository = authRepository
    }

    public func execute() async throws -> Clinician {
        try await authRepository.currentUser()
    }
}
