import Foundation

public struct PatientID: Hashable, Codable, Sendable {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

public struct Identifier: Codable, Sendable {
    public let system: String?
    public let value: String

    public init(system: String? = nil, value: String) {
        self.system = system
        self.value = value
    }
}

public struct PersonName: Codable, Sendable {
    public var given: String
    public var family: String
    public var prefix: String?
    public var suffix: String?

    public init(given: String, family: String, prefix: String? = nil, suffix: String? = nil) {
        self.given = given
        self.family = family
        self.prefix = prefix
        self.suffix = suffix
    }
}

public enum AdministrativeGender: String, Codable, Sendable {
    case male
    case female
    case other
    case unknown
}

public struct Clinician: Codable, Sendable {
    public let id: String
    public var name: PersonName
    public var role: String?

    public init(id: String, name: PersonName, role: String? = nil) {
        self.id = id
        self.name = name
        self.role = role
    }
}

public struct ClinicianSummary: Codable, Sendable {
    public let id: String
    public let displayName: String
    public let role: String?

    public init(id: String, displayName: String, role: String? = nil) {
        self.id = id
        self.displayName = displayName
        self.role = role
    }
}

public struct Code: Codable, Sendable {
    public let system: String
    public let code: String
    public let display: String?

    public init(system: String, code: String, display: String? = nil) {
        self.system = system
        self.code = code
        self.display = display
    }
}

public struct Patient: Codable, Sendable {
    public let id: PatientID
    public var mrn: String?
    public var name: PersonName
    public var birthDate: Date?
    public var gender: AdministrativeGender
    public var primaryProvider: ClinicianSummary?
    public var identifiers: [Identifier]

    public init(
        id: PatientID,
        mrn: String? = nil,
        name: PersonName,
        birthDate: Date? = nil,
        gender: AdministrativeGender = .unknown,
        primaryProvider: ClinicianSummary? = nil,
        identifiers: [Identifier] = []
    ) {
        self.id = id
        self.mrn = mrn
        self.name = name
        self.birthDate = birthDate
        self.gender = gender
        self.primaryProvider = primaryProvider
        self.identifiers = identifiers
    }
}

public struct Encounter: Codable, Sendable {
    public let id: String
    public let patientID: PatientID
    public let classCode: EncounterClass
    public let start: Date?
    public let end: Date?
    public let locationName: String?

    public init(
        id: String,
        patientID: PatientID,
        classCode: EncounterClass,
        start: Date? = nil,
        end: Date? = nil,
        locationName: String? = nil
    ) {
        self.id = id
        self.patientID = patientID
        self.classCode = classCode
        self.start = start
        self.end = end
        self.locationName = locationName
    }
}

public enum EncounterClass: String, Codable, Sendable {
    case inpatient
    case outpatient
    case emergency
    case homeHealth
    case virtual
    case unknown
}

public struct Observation: Codable, Sendable {
    public let id: String
    public let patientID: PatientID
    public let code: Code
    public let effectiveDate: Date?
    public let value: ObservationValue

    public init(
        id: String,
        patientID: PatientID,
        code: Code,
        effectiveDate: Date? = nil,
        value: ObservationValue
    ) {
        self.id = id
        self.patientID = patientID
        self.code = code
        self.effectiveDate = effectiveDate
        self.value = value
    }
}

public enum ObservationValue: Codable, Sendable {
    case quantity(value: Double, unit: String)
    case code(Code)
    case string(String)
    case boolean(Bool)
}

public struct PatientSummary: Codable, Sendable {
    public let patient: Patient
    public let recentEncounters: [Encounter]
    public let recentVitals: [Observation]

    public init(patient: Patient, recentEncounters: [Encounter], recentVitals: [Observation]) {
        self.patient = patient
        self.recentEncounters = recentEncounters
        self.recentVitals = recentVitals
    }
}

public enum DomainError: Error, Sendable {
    case patientNotFound
    case unauthorized
    case invalidState(String)
}
