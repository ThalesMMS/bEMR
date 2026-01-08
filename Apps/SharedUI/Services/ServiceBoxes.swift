import Foundation
import Combine
import SharedPresentation

// Thin type-eraser boxes so SwiftUI @StateObject can hold protocol-backed services

@MainActor
public final class AgendaServiceBox: ObservableObject, AgendaService {
    @Published public private(set) var items: [AgendaItem]
    private var base: any AgendaService

    public init(_ base: any AgendaService) {
        self.base = base
        self.items = base.items
    }

    public func refresh() async {
        await base.refresh()
        items = base.items
    }

    public func advanceStatuses() {
        base.advanceStatuses()
        items = base.items
    }

    public func updateBase(_ newBase: any AgendaService) {
        base = newBase
        items = newBase.items
    }
}

@MainActor
public final class PrescriptionServiceBox: ObservableObject, PrescriptionService {
    private var base: any PrescriptionService

    public init(_ base: any PrescriptionService) {
        self.base = base
    }

    public var store: DemoPrescriptionStore { base.store }
    public func load() async { await base.load() }

    public func updateBase(_ newBase: any PrescriptionService) {
        base = newBase
    }
}

@MainActor
public final class EvolutionServiceBox: ObservableObject, EvolutionService {
    private var base: any EvolutionService

    public init(_ base: any EvolutionService) {
        self.base = base
    }

    public var store: DemoEvolutionStore { base.store }
    public func load() async { await base.load() }

    public func updateBase(_ newBase: any EvolutionService) {
        base = newBase
    }
}

@MainActor
public final class ChartReviewServiceBox: ObservableObject, ChartReviewService {
    @Published public private(set) var items: [ChartReviewEntry]
    private var base: any ChartReviewService

    public init(_ base: any ChartReviewService) {
        self.base = base
        self.items = base.items
    }

    public func refresh() async {
        await base.refresh()
        items = base.items
    }

    public func addDemoNote(detail: String) {
        if let demo = base as? DemoChartReviewService {
            demo.addDemoNote(detail: detail)
            items = demo.items
        }
    }

    public func updateBase(_ newBase: any ChartReviewService) {
        base = newBase
        items = newBase.items
    }
}
