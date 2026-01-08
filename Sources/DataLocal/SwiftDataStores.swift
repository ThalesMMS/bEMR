import Foundation
import SwiftData
import CoreDomain

public final actor SwiftDataPatientLocalStore: PatientLocalStore {
    private let context: ModelContext

    public init(container: ModelContainer) {
        self.context = ModelContext(container)
    }

    public func save(patients: [Patient]) async throws {
        for patient in patients {
            let record = PatientRecord(
                id: patient.id.rawValue,
                given: patient.name.given,
                family: patient.name.family,
                mrn: patient.mrn,
                gender: patient.gender.rawValue,
                birthDate: patient.birthDate,
                providerName: patient.primaryProvider?.displayName
            )
            context.insert(record)
        }
        try context.save()
    }

    public func patient(by id: PatientID) async throws -> Patient? {
        let descriptor = FetchDescriptor<PatientRecord>(
            predicate: #Predicate { $0.id == id.rawValue },
            sortBy: []
        )
        if let record = try context.fetch(descriptor).first {
            return record.toDomain()
        }
        return nil
    }

    public func search(query: String?) async throws -> [Patient] {
        let descriptor: FetchDescriptor<PatientRecord>
        if let term = query, !term.isEmpty {
            descriptor = FetchDescriptor(
                predicate: #Predicate {
                    $0.given.localizedStandardContains(term) || $0.family.localizedStandardContains(term)
                }
            )
        } else {
            descriptor = FetchDescriptor()
        }
        let records = try context.fetch(descriptor)
        return records.map { $0.toDomain() }
    }
}

public final actor SwiftDataEncounterLocalStore: EncounterLocalStore {
    private let context: ModelContext

    public init(container: ModelContainer) {
        self.context = ModelContext(container)
    }

    public func save(encounters: [Encounter]) async throws {
        for encounter in encounters {
            let record = EncounterRecord(
                id: encounter.id,
                patientID: encounter.patientID.rawValue,
                classCode: encounter.classCode.rawValue,
                start: encounter.start,
                end: encounter.end,
                locationName: encounter.locationName
            )
            context.insert(record)
        }
        try context.save()
    }

    public func encounters(for patientID: PatientID) async throws -> [Encounter] {
        let descriptor = FetchDescriptor<EncounterRecord>(
            predicate: #Predicate { $0.patientID == patientID.rawValue },
            sortBy: [SortDescriptor(\.start, order: .reverse)]
        )
        let records = try context.fetch(descriptor)
        return records.map { $0.toDomain() }
    }
}

public final actor SwiftDataObservationLocalStore: ObservationLocalStore {
    private let context: ModelContext

    public init(container: ModelContainer) {
        self.context = ModelContext(container)
    }

    public func save(observations: [Observation]) async throws {
        for observation in observations {
            let record = ObservationRecord(
                id: observation.id,
                patientID: observation.patientID.rawValue,
                codeSystem: observation.code.system,
                code: observation.code.code,
                display: observation.code.display,
                effectiveDate: observation.effectiveDate,
                valueDescription: observation.value.displayText
            )
            context.insert(record)
        }
        try context.save()
    }

    public func recent(for patientID: PatientID, limit: Int) async throws -> [Observation] {
        var descriptor = FetchDescriptor<ObservationRecord>(
            predicate: #Predicate { $0.patientID == patientID.rawValue },
            sortBy: [SortDescriptor(\.effectiveDate, order: .reverse)]
        )
        descriptor.fetchLimit = limit
        let records = try context.fetch(descriptor)
        return records.map { $0.toDomain() }
    }
}

// MARK: - Helpers

private extension PatientRecord {
    func toDomain() -> Patient {
        Patient(
            id: PatientID(id),
            mrn: mrn,
            name: PersonName(given: given, family: family),
            birthDate: birthDate,
            gender: AdministrativeGender(rawValue: gender) ?? .unknown,
            primaryProvider: providerName.map { ClinicianSummary(id: "provider", displayName: $0) },
            identifiers: []
        )
    }
}

private extension EncounterRecord {
    func toDomain() -> Encounter {
        Encounter(
            id: id,
            patientID: PatientID(patientID),
            classCode: EncounterClass(rawValue: classCode) ?? .unknown,
            start: start,
            end: end,
            locationName: locationName
        )
    }
}

private extension ObservationRecord {
    func toDomain() -> Observation {
        Observation(
            id: id,
            patientID: PatientID(patientID),
            code: Code(system: codeSystem, code: code, display: display),
            effectiveDate: effectiveDate,
            value: .string(valueDescription)
        )
    }
}

private extension ObservationValue {
    var displayText: String {
        switch self {
        case .quantity(let value, let unit):
            return "\(value) \(unit)".trimmingCharacters(in: .whitespaces)
        case .code(let code):
            return code.display ?? code.code
        case .string(let string):
            return string
        case .boolean(let bool):
            return bool ? "Yes" : "No"
        }
    }
}
