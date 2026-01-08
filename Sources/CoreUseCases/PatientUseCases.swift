import Foundation
import CoreDomain

public struct LoadPatientListUseCase: Sendable {
    private let patientRepo: PatientRepository
    private let pageSize: Int

    public init(patientRepo: PatientRepository, pageSize: Int = 50) {
        self.patientRepo = patientRepo
        self.pageSize = pageSize
    }

    public func execute(query: String?, page: Int) async throws -> [Patient] {
        try await patientRepo.searchPatients(query: query, page: page, pageSize: pageSize)
    }
}

public struct LoadPatientSummaryUseCase: Sendable {
    private let patientRepo: PatientRepository
    private let encounterRepo: EncounterRepository
    private let observationRepo: ObservationRepository

    public init(
        patientRepo: PatientRepository,
        encounterRepo: EncounterRepository,
        observationRepo: ObservationRepository
    ) {
        self.patientRepo = patientRepo
        self.encounterRepo = encounterRepo
        self.observationRepo = observationRepo
    }

    public func execute(patientID: PatientID) async throws -> PatientSummary {
        async let patient = patientRepo.patient(by: patientID)
        async let encounters = encounterRepo.encounters(for: patientID)
        async let vitals = observationRepo.recentVitals(for: patientID, limit: 10)

        guard let resolvedPatient = try await patient else {
            throw DomainError.patientNotFound
        }

        return PatientSummary(
            patient: resolvedPatient,
            recentEncounters: try await encounters,
            recentVitals: try await vitals
        )
    }
}
