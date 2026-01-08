import Foundation
import CoreDomain
import SharedPresentation

public struct ChartReviewEntry: Identifiable, Hashable, Codable {
    public enum Category: String, Codable, Hashable { case evolution, prescription, exam, note }

    public let id: UUID
    public let category: Category
    public let title: String
    public let detail: String
    public let date: Date
    public let patientID: PatientID?

    public init(
        id: UUID = UUID(),
        category: Category,
        title: String,
        detail: String,
        date: Date,
        patientID: PatientID? = nil
    ) {
        self.id = id
        self.category = category
        self.title = title
        self.detail = detail
        self.date = date
        self.patientID = patientID
    }
}

@MainActor
public protocol AgendaService: ObservableObject {
    var items: [AgendaItem] { get }
    func refresh() async
    func advanceStatuses()
}

@MainActor
public protocol PrescriptionService: ObservableObject {
    var store: DemoPrescriptionStore { get }
    func load() async
}

@MainActor
public protocol EvolutionService: ObservableObject {
    var store: DemoEvolutionStore { get }
    func load() async
}

@MainActor
public protocol ChartReviewService: ObservableObject {
    var items: [ChartReviewEntry] { get }
    func refresh() async
}
