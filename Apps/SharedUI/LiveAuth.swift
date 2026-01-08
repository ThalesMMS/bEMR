import Foundation
import SecurityKit
import CoreDomain

public enum LiveAuthFactory {
    /// Builds an AccessTokenProvider using AuthSessionManager + Keychain store.
    /// The refresh closure can be wired to your SMART on FHIR flow.
    public static func makeTokenProvider(
        refresh: @escaping () async throws -> AuthToken
    ) -> AuthSessionManager {
        let store = KeychainTokenStore()
        return AuthSessionManager(store: store, refreshHandler: refresh)
    }

    /// Convenience helper for development when you have a static bearer token (e.g., SMART sandbox).
    public static func makeStaticTokenProvider(token: String) -> AuthSessionManager {
        AuthSessionManager(store: InMemoryTokenStore(initial: AuthToken(accessToken: token, refreshToken: nil, expiresAt: nil))) {
            AuthToken(accessToken: token, refreshToken: nil, expiresAt: nil)
        }
    }
}
