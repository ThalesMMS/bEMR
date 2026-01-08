import Foundation
import SharedPresentation
import CoreDomain

@MainActor
public final class DemoAgendaService: ObservableObject, AgendaService {
    @Published public private(set) var items: [AgendaItem] = DemoAgendaService.makeAgendaItems()

    public init() {}

    public func refresh() async {
        items = Self.makeAgendaItems()
    }

    public func advanceStatuses() {
        items = items.map { item in
            AgendaItem(
                time: item.time,
                patientName: item.patientName,
                reason: item.reason,
                location: item.location,
                patientID: item.patientID,
                status: Self.nextStatus(from: item.status)
            )
        }
    }

    public static func nextStatus(from status: AgendaItem.Status) -> AgendaItem.Status {
        switch status {
        case .scheduled: return .inProgress
        case .inProgress: return .completed
        case .completed, .missed: return status
        }
    }

    public static func makeAgendaItems() -> [AgendaItem] {
        [
            AgendaItem(time: "08:00", patientName: "Brian Sanders", reason: "Chest pain", location: "Room 1", patientID: PatientID("demo-002"), status: .scheduled),
            AgendaItem(time: "08:30", patientName: "Leo Preston", reason: "Post-op reevaluation", location: "ICU 2", patientID: PatientID("demo-012"), status: .inProgress),
            AgendaItem(time: "09:10", patientName: "Amelia Rogers", reason: "Hypertension", location: "7th Floor", patientID: PatientID("demo-001"), status: .completed),
            AgendaItem(time: "09:40", patientName: "Charles Lane", reason: "Review labs", location: "ED", patientID: PatientID("demo-003"), status: .scheduled)
        ]
    }
}

@MainActor
public final class MockLiveAgendaService: ObservableObject, AgendaService {
    @Published public private(set) var items: [AgendaItem] = []

    public init() { Task { await load() } }

    public func refresh() async { await load() }

    public func advanceStatuses() {
        items = items.map { item in
            AgendaItem(
                time: item.time,
                patientName: item.patientName,
                reason: item.reason,
                location: item.location,
                patientID: item.patientID,
                status: DemoAgendaService.nextStatus(from: item.status)
            )
        }
    }

    private func load() async {
        try? await Task.sleep(nanoseconds: 250_000_000)
        items = DemoAgendaService.makeAgendaItems()
        try? await Task.sleep(nanoseconds: 250_000_000)
        advanceStatuses()
    }
}

@MainActor
public final class DemoPrescriptionService: ObservableObject, PrescriptionService {
    @Published public private(set) var store: DemoPrescriptionStore
    private let patientID: PatientID

    public init(patientID: PatientID = PatientID("demo-001")) {
        self.patientID = patientID
        self.store = DemoPrescriptionStore(
            patientID: patientID,
            sections: DemoSummaryRegistry.prescriptions(for: patientID),
            history: DemoSummaryRegistry.prescriptionHistory(for: patientID)
        )
    }

    public func load() async {
        store.setSections(DemoSummaryRegistry.prescriptions(for: patientID))
        store.setHistory(DemoSummaryRegistry.prescriptionHistory(for: patientID))
    }
}

@MainActor
public final class MockLivePrescriptionService: ObservableObject, PrescriptionService {
    @Published public private(set) var store: DemoPrescriptionStore
    private let patientID: PatientID

    public init(patientID: PatientID = PatientID("demo-002")) {
        self.patientID = patientID
        self.store = DemoPrescriptionStore(
            patientID: patientID,
            sections: DemoSummaryRegistry.prescriptions(for: patientID),
            history: DemoSummaryRegistry.prescriptionHistory(for: patientID)
        )
        Task { await load() }
    }

    public func load() async {
        try? await Task.sleep(nanoseconds: 200_000_000)
        store.setSections(DemoSummaryRegistry.prescriptions(for: patientID))
        store.setHistory(DemoSummaryRegistry.prescriptionHistory(for: patientID))
    }
}

@MainActor
public final class DemoEvolutionService: ObservableObject, EvolutionService {
    @Published public private(set) var store: DemoEvolutionStore
    private let patientID: PatientID

    public init(patientID: PatientID = PatientID("demo-001")) {
        self.patientID = patientID
        self.store = DemoEvolutionStore(patientID: patientID, notes: DemoSummaryRegistry.evolutions(for: patientID))
    }

    public func load() async {
        store.replace(notes: DemoSummaryRegistry.evolutions(for: patientID))
    }
}

@MainActor
public final class MockLiveEvolutionService: ObservableObject, EvolutionService {
    @Published public private(set) var store: DemoEvolutionStore
    private let patientID: PatientID

    public init(patientID: PatientID = PatientID("demo-012")) {
        self.patientID = patientID
        self.store = DemoEvolutionStore(patientID: patientID, notes: DemoSummaryRegistry.evolutions(for: patientID))
        Task { await load() }
    }

    public func load() async {
        try? await Task.sleep(nanoseconds: 200_000_000)
        store.replace(notes: DemoSummaryRegistry.evolutions(for: patientID))
    }
}

@MainActor
public final class DemoChartReviewService: ObservableObject, ChartReviewService {
    @Published public private(set) var items: [ChartReviewEntry] = DemoChartReviewService.makeEntries()

    public init() {}

    public func refresh() async {
        items = Self.makeEntries()
    }

    func addDemoNote(detail: String) {
        let entry = ChartReviewEntry(category: .note, title: "Note", detail: detail, date: Date())
        items.insert(entry, at: 0)
    }

    public static func makeEntries() -> [ChartReviewEntry] {
        let now = Date()
        return [
            ChartReviewEntry(category: .evolution, title: "Medical progress", detail: "Pain improved; continue aspirin", date: now - 3_600, patientID: PatientID("demo-002")),
            ChartReviewEntry(category: .prescription, title: "Prescription adjustment", detail: "Stop opioid, continue PPI", date: now - 7_200, patientID: PatientID("demo-002")),
            ChartReviewEntry(category: .exam, title: "Exam", detail: "ECG and troponin reviewed", date: now - 10_800, patientID: PatientID("demo-001")),
            ChartReviewEntry(category: .note, title: "Nursing note", detail: "Dressing clean, no pain", date: now - 12_000, patientID: PatientID("demo-003"))
        ]
    }
}

@MainActor
public final class MockLiveChartReviewService: ObservableObject, ChartReviewService {
    @Published public private(set) var items: [ChartReviewEntry] = []

    public init() { Task { await refresh() } }

    public func refresh() async {
        try? await Task.sleep(nanoseconds: 200_000_000)
        items = DemoChartReviewService.makeEntries()
    }
}
