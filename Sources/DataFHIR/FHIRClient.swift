import Foundation
import CoreDomain
import SecurityKit
import ModelsR4

public enum FHIRClientError: Error, Sendable {
    case invalidURL
    case httpError(Int)
    case decodingError
}

/// Minimal SMART on FHIR client that injects OAuth token from SecurityKit.
public final class FHIRClient: @unchecked Sendable {
    private let baseURL: URL
    private let tokenProvider: AccessTokenProvider
    private let session: URLSession

    public init(baseURL: URL, tokenProvider: AccessTokenProvider, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.tokenProvider = tokenProvider
        self.session = session
    }

    public func get<Resource: Decodable>(
        _ path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> Resource {
        let token = try await tokenProvider.validAccessToken()
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else {
            throw FHIRClientError.invalidURL
        }
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        guard let url = components.url else { throw FHIRClientError.invalidURL }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue("application/fhir+json", forHTTPHeaderField: "Accept")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw FHIRClientError.httpError(-1)
        }
        guard (200..<300).contains(http.statusCode) else {
            throw FHIRClientError.httpError(http.statusCode)
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        decoder.keyDecodingStrategy = .useDefaultKeys

        do {
            return try decoder.decode(Resource.self, from: data)
        } catch {
            throw FHIRClientError.decodingError
        }
    }
}
