import Foundation
import CoreUseCases
import CoreDomain

@MainActor
public final class PatientSummaryViewModel: ObservableObject {
    @Published public private(set) var summary: PatientSummary?
    @Published public private(set) var isLoading = false
    @Published public var errorMessage: String?

    private let useCase: LoadPatientSummaryUseCase

    public init(useCase: LoadPatientSummaryUseCase) {
        self.useCase = useCase
    }

    public func load(patientID: PatientID) {
        Task {
            await execute(patientID: patientID)
        }
    }

    private func execute(patientID: PatientID) async {
        isLoading = true
        defer { isLoading = false }
        do {
            summary = try await useCase.execute(patientID: patientID)
            errorMessage = nil
        } catch {
            errorMessage = "Unable to load patient summary."
        }
    }
}
