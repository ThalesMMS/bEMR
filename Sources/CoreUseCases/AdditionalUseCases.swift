import Foundation
import CoreDomain

public struct SearchPatientsByIdentifierUseCase: Sendable {
    private let patientRepo: PatientRepository

    public init(patientRepo: PatientRepository) {
        self.patientRepo = patientRepo
    }

    public func execute(identifier: String, page: Int = 0, pageSize: Int = 25) async throws -> [Patient] {
        try await patientRepo.searchPatients(query: identifier, page: page, pageSize: pageSize)
    }
}

public struct LoadEncounterTimelineUseCase: Sendable {
    private let encounterRepo: EncounterRepository

    public init(encounterRepo: EncounterRepository) {
        self.encounterRepo = encounterRepo
    }

    public func execute(patientID: PatientID) async throws -> [Encounter] {
        try await encounterRepo.encounters(for: patientID)
    }
}

public struct LoadRecentVitalsUseCase: Sendable {
    private let observationRepo: ObservationRepository

    public init(observationRepo: ObservationRepository) {
        self.observationRepo = observationRepo
    }

    public func execute(patientID: PatientID, limit: Int = 10) async throws -> [Observation] {
        try await observationRepo.recentVitals(for: patientID, limit: limit)
    }
}
