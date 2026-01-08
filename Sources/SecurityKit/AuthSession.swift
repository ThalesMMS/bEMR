import Foundation

public struct AuthToken: Codable, Sendable {
    public let accessToken: String
    public let refreshToken: String?
    public let expiresAt: Date?

    public init(accessToken: String, refreshToken: String?, expiresAt: Date?) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }

    public var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt <= Date()
    }
}

public enum SecurityKitError: Error, Sendable {
    case tokenNotFound
    case keychainFailure(OSStatus)
    case unsupportedPlatform
}

public protocol TokenStore: Sendable {
    func save(token: AuthToken) async throws
    func load() async throws -> AuthToken?
    func clear() async throws
}

public actor InMemoryTokenStore: TokenStore {
    private var token: AuthToken?

    public init(initial: AuthToken? = nil) {
        self.token = initial
    }

    public func save(token: AuthToken) async throws {
        self.token = token
    }

    public func load() async throws -> AuthToken? {
        token
    }

    public func clear() async throws {
        token = nil
    }
}

public protocol AccessTokenProvider: Sendable {
    func validAccessToken() async throws -> String
    func refreshIfNeeded() async throws
}

public actor AuthSessionManager: AccessTokenProvider {
    private let store: TokenStore
    private let refreshHandler: () async throws -> AuthToken

    public init(store: TokenStore, refreshHandler: @escaping () async throws -> AuthToken) {
        self.store = store
        self.refreshHandler = refreshHandler
    }

    public func validAccessToken() async throws -> String {
        if let token = try await store.load(), !token.isExpired {
            return token.accessToken
        }
        let refreshed = try await refreshHandler()
        try await store.save(token: refreshed)
        return refreshed.accessToken
    }

    public func refreshIfNeeded() async throws {
        if let token = try await store.load(), !token.isExpired {
            return
        }
        let refreshed = try await refreshHandler()
        try await store.save(token: refreshed)
    }
}
