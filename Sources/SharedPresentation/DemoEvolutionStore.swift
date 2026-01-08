import Foundation
import CoreDomain

@MainActor
public final class DemoEvolutionStore: ObservableObject {
    @Published public private(set) var notes: [DemoEvolutionNote]
    private let author: String
    private let role: String
    private let persistenceKey: String
    @Published public private(set) var audit: [AuditEntry]

    public struct AuditEntry: Identifiable, Codable, Hashable {
        public let id: UUID
        public let date: Date
        public let action: String
        public let text: String
    }

    public init(patientID: PatientID, notes: [DemoEvolutionNote], author: String = "Dr. Demo", role: String = "Internal Medicine") {
        self.persistenceKey = "demo-evo-" + patientID.rawValue
        self.author = author
        self.role = role
        if let saved = Self.load(key: persistenceKey) {
            self.notes = saved.notes
            self.audit = saved.audit
        } else {
            self.notes = notes
            self.audit = []
            persist()
        }
    }

    public func sign(text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        let note = DemoEvolutionNote(author: author, role: role, text: text, details: nil, date: Date())
        notes.insert(note, at: 0)
        audit.append(AuditEntry(id: UUID(), date: Date(), action: "Sign", text: text))
        persist()
    }

    public func replace(notes newNotes: [DemoEvolutionNote]) {
        notes = newNotes
        persist()
    }

    // MARK: - Persistence
    private func persist() {
        let payload = Persisted(notes: notes, audit: audit)
        if let data = try? JSONEncoder().encode(payload) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }

    private static func load(key: String) -> Persisted? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Persisted.self, from: data)
    }

    private struct Persisted: Codable {
        let notes: [DemoEvolutionNote]
        let audit: [AuditEntry]
    }
}
