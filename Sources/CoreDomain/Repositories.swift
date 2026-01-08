import Foundation

public protocol PatientRepository: Sendable {
    func searchPatients(query: String?, page: Int, pageSize: Int) async throws -> [Patient]
    func patient(by id: PatientID) async throws -> Patient?
}

public protocol EncounterRepository: Sendable {
    func encounters(for patientID: PatientID) async throws -> [Encounter]
}

public protocol ObservationRepository: Sendable {
    func recentVitals(for patientID: PatientID, limit: Int) async throws -> [Observation]
}

public protocol AuthRepository: Sendable {
    func currentUser() async throws -> Clinician
    func refreshTokenIfNeeded() async throws
    func accessToken() async throws -> String
}
