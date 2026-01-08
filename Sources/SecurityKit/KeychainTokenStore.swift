import Foundation
#if canImport(Security)
import Security
#endif

public actor KeychainTokenStore: TokenStore {
    private let service: String
    private let account: String
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    public init(service: String = "bEMR.auth", account: String = "session") {
        self.service = service
        self.account = account
    }

    public func save(token: AuthToken) async throws {
#if canImport(Security)
        let data = try encoder.encode(token)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
        var attributes = query
        attributes[kSecValueData as String] = data

        let status = SecItemAdd(attributes as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw SecurityKitError.keychainFailure(status)
        }
#else
        // Fallback for platforms without Security; use in-memory storage only.
        throw SecurityKitError.unsupportedPlatform
#endif
    }

    public func load() async throws -> AuthToken? {
#if canImport(Security)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)

        if status == errSecItemNotFound {
            return nil
        }

        guard status == errSecSuccess, let data = item as? Data else {
            throw SecurityKitError.keychainFailure(status)
        }
        return try decoder.decode(AuthToken.self, from: data)
#else
        throw SecurityKitError.unsupportedPlatform
#endif
    }

    public func clear() async throws {
#if canImport(Security)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw SecurityKitError.keychainFailure(status)
        }
#else
        throw SecurityKitError.unsupportedPlatform
#endif
    }
}
