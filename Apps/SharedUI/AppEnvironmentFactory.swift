import Foundation
import DataLocal
import SecurityKit
import SwiftData

public enum AppEnvironmentFactory {
    @MainActor
    public static func makeDefault() -> AppEnvironment {
        let env = ProcessInfo.processInfo.environment
        if
            let base = env["FHIR_BASE_URL"],
            let baseURL = URL(string: base),
            let token = env["FHIR_STATIC_TOKEN"]
        {
            let tokenProvider = LiveAuthFactory.makeStaticTokenProvider(token: token)
            let container = try? LocalContainerFactory.makePersistent()
            return LiveComposition.make(baseURL: baseURL, tokenProvider: tokenProvider, container: container)
        }
        return DemoComposition.make()
    }
}
