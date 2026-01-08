import Foundation
import CoreDomain
import ModelsR4

public final class FHIRPatientRepository: PatientRepository {
    private let client: FHIRClient

    public init(client: FHIRClient) {
        self.client = client
    }

    public func searchPatients(query: String?, page: Int, pageSize: Int) async throws -> [CoreDomain.Patient] {
        var items: [URLQueryItem] = [
            .init(name: "_count", value: "\(pageSize)"),
            .init(name: "_offset", value: "\(page * pageSize)")
        ]
        if let query, !query.isEmpty {
            items.append(.init(name: "name", value: query))
        }
        let bundle: ModelsR4.Bundle = try await client.get("Patient", queryItems: items)
        let entries = bundle.entry ?? []
        return entries.compactMap { entry in
            guard let fhirPatient = entry.resource?.get(if: ModelsR4.Patient.self) else { return nil }
            return PatientMapper.fromFHIR(fhirPatient)
        }
    }

    public func patient(by id: PatientID) async throws -> CoreDomain.Patient? {
        let fhirPatient: ModelsR4.Patient = try await client.get("Patient/\(id.rawValue)")
        return PatientMapper.fromFHIR(fhirPatient)
    }
}

public final class FHIREncounterRepository: EncounterRepository {
    private let client: FHIRClient

    public init(client: FHIRClient) {
        self.client = client
    }

    public func encounters(for patientID: PatientID) async throws -> [CoreDomain.Encounter] {
        let query: [URLQueryItem] = [
            .init(name: "patient", value: patientID.rawValue),
            .init(name: "_sort", value: "-date")
        ]
        let bundle: ModelsR4.Bundle = try await client.get("Encounter", queryItems: query)
        let entries = bundle.entry ?? []
        return entries.compactMap { entry in
            guard let fhirEncounter = entry.resource?.get(if: ModelsR4.Encounter.self) else { return nil }
            return EncounterMapper.fromFHIR(fhirEncounter, patientID: patientID)
        }
    }
}

public final class FHIRObservationRepository: ObservationRepository {
    private let client: FHIRClient

    public init(client: FHIRClient) {
        self.client = client
    }

    public func recentVitals(for patientID: PatientID, limit: Int) async throws -> [CoreDomain.Observation] {
        let query: [URLQueryItem] = [
            .init(name: "patient", value: patientID.rawValue),
            .init(name: "_count", value: "\(limit)"),
            .init(name: "_sort", value: "-date")
        ]
        let bundle: ModelsR4.Bundle = try await client.get("Observation", queryItems: query)
        let entries = bundle.entry ?? []
        return entries.compactMap { entry in
            guard let fhirObservation = entry.resource?.get(if: ModelsR4.Observation.self) else { return nil }
            return ObservationMapper.fromFHIR(fhirObservation, patientID: patientID)
        }
    }
}

enum PatientMapper {
    static func fromFHIR(_ patient: ModelsR4.Patient) -> CoreDomain.Patient {
        let id = PatientID(patient.id?.value?.string ?? UUID().uuidString)
        let name = buildName(from: patient.name?.first)
        let mrn = patient.identifier?.first?.value?.value?.string
        let identifiers: [CoreDomain.Identifier] = (patient.identifier ?? []).compactMap { identifier in
            guard let value = identifier.value?.value?.string else { return nil }
            let system = identifier.system?.value?.url.absoluteString
            return CoreDomain.Identifier(system: system, value: value)
        }
        let gender = mapGender(patient.gender?.value)
        let providerReference = patient.generalPractitioner?.first
        let providerDisplay = providerReference?.display?.value?.string
        let clinician = providerReference.flatMap { ref -> ClinicianSummary? in
            guard let display = providerDisplay else { return nil }
            let clinicianID = ref.reference?.value?.string ?? ""
            return ClinicianSummary(id: clinicianID, displayName: display, role: nil)
        }

        return CoreDomain.Patient(
            id: id,
            mrn: mrn,
            name: name,
            birthDate: FHIRDateConverter.date(from: patient.birthDate),
            gender: gender,
            primaryProvider: clinician,
            identifiers: identifiers
        )
    }

    private static func buildName(from humanName: HumanName?) -> PersonName {
        let given = humanName?.given?.first?.value?.string ?? ""
        let family = humanName?.family?.value?.string ?? ""
        let prefix = humanName?.prefix?.first?.value?.string
        let suffix = humanName?.suffix?.first?.value?.string
        return PersonName(given: given, family: family, prefix: prefix, suffix: suffix)
    }

    private static func mapGender(_ gender: ModelsR4.AdministrativeGender?) -> CoreDomain.AdministrativeGender {
        switch gender {
        case .male: return .male
        case .female: return .female
        case .other: return .other
        case .unknown: return .unknown
        case .none: return .unknown
        }
    }
}

enum EncounterMapper {
    static func fromFHIR(_ encounter: ModelsR4.Encounter, patientID: PatientID) -> CoreDomain.Encounter {
        let mappedClass = mapClass(encounter.class.code?.value?.string)
        let start = FHIRDateConverter.date(from: encounter.period?.start)
        let end = FHIRDateConverter.date(from: encounter.period?.end)
        let locationName = encounter.location?.first?.location.display?.value?.string

        return CoreDomain.Encounter(
            id: encounter.id?.value?.string ?? UUID().uuidString,
            patientID: patientID,
            classCode: mappedClass,
            start: start,
            end: end,
            locationName: locationName
        )
    }

    private static func mapClass(_ code: String?) -> EncounterClass {
        switch code?.lowercased() {
        case "imp", "inpatient": return .inpatient
        case "out", "outpatient": return .outpatient
        case "emergency", "emerg": return .emergency
        case "hh": return .homeHealth
        case "vr": return .virtual
        default: return .unknown
        }
    }
}

enum ObservationMapper {
    static func fromFHIR(_ observation: ModelsR4.Observation, patientID: PatientID) -> CoreDomain.Observation {
        let codeable = observation.code
        let code = Code(
            system: codeable.coding?.first?.system?.value?.url.absoluteString ?? "unknown",
            code: codeable.coding?.first?.code?.value?.string ?? "unknown",
            display: codeable.coding?.first?.display?.value?.string ?? codeable.text?.value?.string
        )
        let value = mapValue(observation.value)

        return CoreDomain.Observation(
            id: observation.id?.value?.string ?? UUID().uuidString,
            patientID: patientID,
            code: code,
            effectiveDate: FHIRDateConverter.date(from: observation.effective),
            value: value
        )
    }

    private static func mapValue(_ value: ModelsR4.Observation.ValueX?) -> ObservationValue {
        switch value {
        case .quantity(let quantity):
            let unit = quantity.unit?.value?.string ?? quantity.code?.value?.string ?? ""
            let decimal = quantity.value?.value?.decimal ?? 0
            let doubleValue = NSDecimalNumber(decimal: decimal).doubleValue
            return .quantity(value: doubleValue, unit: unit)
        case .codeableConcept(let concept):
            let coding = concept.coding?.first
            let code = Code(
                system: coding?.system?.value?.url.absoluteString ?? "unknown",
                code: coding?.code?.value?.string ?? "unknown",
                display: coding?.display?.value?.string ?? concept.text?.value?.string
            )
            return .code(code)
        case .string(let string):
            return .string(string.value?.string ?? "")
        case .boolean(let bool):
            return .boolean(bool.value?.bool ?? false)
        default:
            return .string("Unsupported")
        }
    }
}

enum FHIRDateConverter {
    private static let calendar = Calendar(identifier: .gregorian)

    static func date(from fhirDate: FHIRPrimitive<FHIRDate>?) -> Date? {
        guard let fhirDate else { return nil }
        var components = DateComponents()
        components.year = fhirDate.value?.year
        if let month = fhirDate.value?.month {
            components.month = Int(month)
        }
        if let day = fhirDate.value?.day {
            components.day = Int(day)
        }
        components.timeZone = TimeZone(secondsFromGMT: 0)
        return calendar.date(from: components)
    }

    static func date(from dateTime: FHIRPrimitive<DateTime>?) -> Date? {
        guard let value = dateTime?.value else { return nil }
        var components = DateComponents()
        components.year = value.date.year
        if let month = value.date.month {
            components.month = Int(month)
        }
        if let day = value.date.day {
            components.day = Int(day)
        }
        if let time = value.time {
            components.hour = Int(time.hour)
            components.minute = Int(time.minute)
            components.second = Int(NSDecimalNumber(decimal: time.second).intValue)
        }
        components.timeZone = value.timeZone ?? TimeZone(secondsFromGMT: 0)
        return calendar.date(from: components)
    }

    static func date(from instant: FHIRPrimitive<Instant>?) -> Date? {
        guard let instant = instant?.value else { return nil }
        var components = DateComponents()
        components.year = instant.date.year
        components.month = Int(instant.date.month)
        components.day = Int(instant.date.day)
        components.hour = Int(instant.time.hour)
        components.minute = Int(instant.time.minute)
        components.second = Int(NSDecimalNumber(decimal: instant.time.second).intValue)
        components.timeZone = instant.timeZone
        return calendar.date(from: components)
    }

    static func date(from effective: ModelsR4.Observation.EffectiveX?) -> Date? {
        switch effective {
        case .dateTime(let dateTime):
            return date(from: dateTime)
        case .instant(let instant):
            return date(from: instant)
        case .period(let period):
            return date(from: period.start)
        case .timing:
            return nil
        case .none:
            return nil
        }
    }
}
