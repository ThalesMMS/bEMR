import Foundation
import SwiftData

public enum LocalContainerFactory {
    public static func makeInMemory() throws -> ModelContainer {
        try ModelContainer(for: SwiftDataModelSchema.schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
    }

    public static func makePersistent() throws -> ModelContainer {
        try ModelContainer(for: SwiftDataModelSchema.schema)
    }
}
