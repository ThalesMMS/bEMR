import Foundation
import CoreDomain

@MainActor
public final class DemoPrescriptionStore: ObservableObject {
    @Published public private(set) var sections: [Section]
    @Published public private(set) var history: [DemoPrescriptionHistory]
    @Published public private(set) var audit: [AuditEntry]

    private let persistenceKey: String

    public struct Section: Identifiable, Hashable, Codable {
        public let id: UUID
        public let title: String
        public var items: [Item]
        public var isExpanded: Bool
    }

    public struct Item: Identifiable, Hashable, Codable {
        public let id: UUID
        public var type: String
        public var description: String
        public var quantity: String
        public var frequency: String
        public var route: String
        public var duration: String
    }

    public struct AuditEntry: Identifiable, Codable, Hashable {
        public let id: UUID
        public let date: Date
        public let action: String
        public let itemDescription: String
    }

    public init(patientID: PatientID, sections: [DemoPrescriptionSectionData], history: [DemoPrescriptionHistory]) {
        self.persistenceKey = "demo-rx-" + patientID.rawValue
        if let saved = Self.load(key: persistenceKey) {
            self.sections = saved.sections
            self.history = saved.history
            self.audit = saved.audit
        } else {
            self.sections = sections.map { section in
                Section(
                    id: section.id,
                    title: section.title,
                    items: section.items.map { item in
                        Item(
                            id: item.id,
                            type: item.type,
                            description: item.description,
                            quantity: item.quantity,
                            frequency: item.frequency,
                            route: item.route,
                            duration: item.duration
                        )
                    },
                    isExpanded: true
                )
            }
            self.history = history
            self.audit = []
            persist()
        }
    }

    public func addMedicationPlaceholder() {
        // Prefer an existing medications section; otherwise append a new one.
        if let idx = sections.firstIndex(where: { $0.title.localizedCaseInsensitiveContains("med") }) {
            var section = sections[idx]
            section.items.append(makePlaceholderItem())
            sections[idx] = section
        } else {
            let new = Section(id: UUID(), title: "Medications", items: [makePlaceholderItem()], isExpanded: true)
            sections.append(new)
        }
        audit.append(AuditEntry(id: UUID(), date: Date(), action: "Add", itemDescription: "Empty item"))
        persist()
    }

    public func toggleSection(_ id: UUID) {
        guard let idx = sections.firstIndex(where: { $0.id == id }) else { return }
        sections[idx].isExpanded.toggle()
    }

    public func remove(itemID: UUID, in sectionID: UUID) {
        guard let sectionIndex = sections.firstIndex(where: { $0.id == sectionID }) else { return }
        var section = sections[sectionIndex]
        section.items.removeAll { $0.id == itemID }
        sections[sectionIndex] = section
        audit.append(AuditEntry(id: UUID(), date: Date(), action: "Remove", itemDescription: "Item removed"))
        persist()
    }

    public func update(
        itemID: UUID,
        in sectionID: UUID,
        description: String,
        quantity: String,
        frequency: String,
        route: String,
        duration: String
    ) {
        guard let sectionIndex = sections.firstIndex(where: { $0.id == sectionID }) else { return }
        var section = sections[sectionIndex]
        guard let itemIndex = section.items.firstIndex(where: { $0.id == itemID }) else { return }
        var item = section.items[itemIndex]
        item.description = description
        item.quantity = quantity
        item.frequency = frequency
        item.route = route
        item.duration = duration
        section.items[itemIndex] = item
        sections[sectionIndex] = section
        audit.append(AuditEntry(id: UUID(), date: Date(), action: "Edit", itemDescription: description))
        persist()
    }

    private func makePlaceholderItem() -> Item {
        Item(
            id: UUID(),
            type: "Medication",
            description: "New item",
            quantity: "1",
            frequency: "q8h",
            route: "PO",
            duration: "3d"
        )
    }

    // Helpers for mock-live loaders
    public func setSections(_ data: [DemoPrescriptionSectionData]) {
        self.sections = data.map { section in
            Section(
                id: section.id,
                title: section.title,
                items: section.items.map { Item(id: $0.id, type: $0.type, description: $0.description, quantity: $0.quantity, frequency: $0.frequency, route: $0.route, duration: $0.duration) },
                isExpanded: true
            )
        }
        persist()
    }

    public func setHistory(_ history: [DemoPrescriptionHistory]) {
        self.history = history
        persist()
    }

    // MARK: - Persistence
    private func persist() {
        let payload = Persisted(sections: sections, history: history, audit: audit)
        if let data = try? JSONEncoder().encode(payload) {
            UserDefaults.standard.set(data, forKey: persistenceKey)
        }
    }

    private static func load(key: String) -> Persisted? {
        guard let data = UserDefaults.standard.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Persisted.self, from: data)
    }

    private struct Persisted: Codable {
        let sections: [Section]
        let history: [DemoPrescriptionHistory]
        let audit: [AuditEntry]
    }
}
