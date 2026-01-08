import Foundation
import CoreDomain

public protocol PatientLocalStore: Sendable {
    func save(patients: [Patient]) async throws
    func patient(by id: PatientID) async throws -> Patient?
    func search(query: String?) async throws -> [Patient]
}

public protocol EncounterLocalStore: Sendable {
    func save(encounters: [Encounter]) async throws
    func encounters(for patientID: PatientID) async throws -> [Encounter]
}

public protocol ObservationLocalStore: Sendable {
    func save(observations: [Observation]) async throws
    func recent(for patientID: PatientID, limit: Int) async throws -> [Observation]
}

public actor InMemoryPatientLocalStore: PatientLocalStore {
    private var storage: [PatientID: Patient] = [:]

    public init() {}

    public func save(patients: [Patient]) async throws {
        patients.forEach { storage[$0.id] = $0 }
    }

    public func patient(by id: PatientID) async throws -> Patient? {
        storage[id]
    }

    public func search(query: String?) async throws -> [Patient] {
        guard let term = query?.lowercased(), !term.isEmpty else {
            return Array(storage.values)
        }
        return storage.values.filter { patient in
            patient.name.family.lowercased().contains(term) || patient.name.given.lowercased().contains(term)
        }
    }
}

public actor InMemoryEncounterLocalStore: EncounterLocalStore {
    private var storage: [PatientID: [Encounter]] = [:]

    public init() {}

    public func save(encounters: [Encounter]) async throws {
        encounters.forEach { encounter in
            storage[encounter.patientID, default: []].append(encounter)
        }
    }

    public func encounters(for patientID: PatientID) async throws -> [Encounter] {
        storage[patientID, default: []]
    }
}

public actor InMemoryObservationLocalStore: ObservationLocalStore {
    private var storage: [PatientID: [Observation]] = [:]

    public init() {}

    public func save(observations: [Observation]) async throws {
        observations.forEach { observation in
            storage[observation.patientID, default: []].append(observation)
        }
    }

    public func recent(for patientID: PatientID, limit: Int) async throws -> [Observation] {
        let items = storage[patientID, default: []].sorted { lhs, rhs in
            (lhs.effectiveDate ?? .distantPast) > (rhs.effectiveDate ?? .distantPast)
        }
        return Array(items.prefix(limit))
    }
}

public struct CachingPatientRepository: PatientRepository {
    private let remote: PatientRepository
    private let local: PatientLocalStore

    public init(remote: PatientRepository, local: PatientLocalStore) {
        self.remote = remote
        self.local = local
    }

    public func searchPatients(query: String?, page: Int, pageSize: Int) async throws -> [Patient] {
        let remotePatients = try await remote.searchPatients(query: query, page: page, pageSize: pageSize)
        try await local.save(patients: remotePatients)
        return remotePatients
    }

    public func patient(by id: PatientID) async throws -> Patient? {
        if let cached = try await local.patient(by: id) {
            return cached
        }
        let remotePatient = try await remote.patient(by: id)
        if let patient = remotePatient {
            try await local.save(patients: [patient])
        }
        return remotePatient
    }
}

public struct CachingEncounterRepository: EncounterRepository {
    private let remote: EncounterRepository
    private let local: EncounterLocalStore

    public init(remote: EncounterRepository, local: EncounterLocalStore) {
        self.remote = remote
        self.local = local
    }

    public func encounters(for patientID: PatientID) async throws -> [Encounter] {
        let remoteEncounters = try await remote.encounters(for: patientID)
        try await local.save(encounters: remoteEncounters)
        return remoteEncounters
    }
}

public struct CachingObservationRepository: ObservationRepository {
    private let remote: ObservationRepository
    private let local: ObservationLocalStore

    public init(remote: ObservationRepository, local: ObservationLocalStore) {
        self.remote = remote
        self.local = local
    }

    public func recentVitals(for patientID: PatientID, limit: Int) async throws -> [Observation] {
        let remoteObservations = try await remote.recentVitals(for: patientID, limit: limit)
        try await local.save(observations: remoteObservations)
        return try await local.recent(for: patientID, limit: limit)
    }
}
