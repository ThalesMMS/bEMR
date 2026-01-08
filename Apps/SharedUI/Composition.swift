import Foundation
import CoreDomain
import CoreUseCases
import DataLocal
import SharedPresentation
import DataFHIR
import SecurityKit
import SwiftData

public struct AppEnvironment {
    public let patientListViewModel: PatientListViewModel
    public let summaryViewModelFactory: () -> PatientSummaryViewModel
}

public enum DemoComposition {
    @MainActor
    public static func make() -> AppEnvironment {
        let demoPatients = DemoData.patients
        let patientRepo = DemoPatientRepository(patients: demoPatients)
        let encounterRepo = DemoEncounterRepository(encounters: DemoData.encounters)
        let observationRepo = DemoObservationRepository(observations: DemoData.observations)

        return buildEnvironment(
            patientRepo: patientRepo,
            encounterRepo: encounterRepo,
            observationRepo: observationRepo
        )
    }
}

public enum LiveComposition {
    @MainActor
    public static func make(
        baseURL: URL,
        tokenProvider: AccessTokenProvider,
        container: ModelContainer?
    ) -> AppEnvironment {
        let client = FHIRClient(baseURL: baseURL, tokenProvider: tokenProvider)
        let remotePatient = FHIRPatientRepository(client: client)
        let remoteEncounter = FHIREncounterRepository(client: client)
        let remoteObservation = FHIRObservationRepository(client: client)

        let patientRepo: PatientRepository
        let encounterRepo: EncounterRepository
        let observationRepo: ObservationRepository

        if let container {
            let patientLocal = SwiftDataPatientLocalStore(container: container)
            let encounterLocal = SwiftDataEncounterLocalStore(container: container)
            let observationLocal = SwiftDataObservationLocalStore(container: container)
            patientRepo = CachingPatientRepository(remote: remotePatient, local: patientLocal)
            encounterRepo = CachingEncounterRepository(remote: remoteEncounter, local: encounterLocal)
            observationRepo = CachingObservationRepository(remote: remoteObservation, local: observationLocal)
        } else {
            patientRepo = remotePatient
            encounterRepo = remoteEncounter
            observationRepo = remoteObservation
        }

        return buildEnvironment(
            patientRepo: patientRepo,
            encounterRepo: encounterRepo,
            observationRepo: observationRepo
        )
    }
}

@MainActor
private func buildEnvironment(
    patientRepo: PatientRepository,
    encounterRepo: EncounterRepository,
    observationRepo: ObservationRepository
) -> AppEnvironment {
    let loadPatientList = LoadPatientListUseCase(patientRepo: patientRepo, pageSize: 20)
    let loadSummary = LoadPatientSummaryUseCase(
        patientRepo: patientRepo,
        encounterRepo: encounterRepo,
        observationRepo: observationRepo
    )

    return AppEnvironment(
        patientListViewModel: PatientListViewModel(loadPatientList: loadPatientList),
        summaryViewModelFactory: { PatientSummaryViewModel(useCase: loadSummary) }
    )
}

enum DemoData {
    static let patients: [Patient] = [
        Patient(
            id: PatientID("demo-001"),
            mrn: "MRN-001",
            name: PersonName(given: "Amelia", family: "Rogers"),
            birthDate: Date(timeIntervalSince1970: 0),
            gender: .female,
            primaryProvider: ClinicianSummary(id: "clinician-1", displayName: "Dr. Smith"),
            identifiers: []
        ),
        Patient(
            id: PatientID("demo-002"),
            mrn: "MRN-002",
            name: PersonName(given: "Brian", family: "Sanders"),
            birthDate: Date(timeIntervalSince1970: 100_000),
            gender: .male,
            primaryProvider: ClinicianSummary(id: "clinician-2", displayName: "Dr. Carter"),
            identifiers: []
        ),
        Patient(
            id: PatientID("demo-003"),
            mrn: "MRN-003",
            name: PersonName(given: "Charles", family: "Lane"),
            birthDate: Date(timeIntervalSince1970: 200_000),
            gender: .male,
            primaryProvider: ClinicianSummary(id: "clinician-3", displayName: "Dr. Brooks"),
            identifiers: []
        ),
        Patient(
            id: PatientID("demo-004"),
            mrn: "MRN-004",
            name: PersonName(given: "Danielle", family: "Parker"),
            birthDate: Date(timeIntervalSince1970: 300_000),
            gender: .female,
            primaryProvider: ClinicianSummary(id: "clinician-4", displayName: "Dr. Nelson"),
            identifiers: []
        ),
        Patient(
            id: PatientID("demo-005"),
            mrn: "MRN-005",
            name: PersonName(given: "Edward", family: "Coleman"),
            birthDate: Date(timeIntervalSince1970: 400_000),
            gender: .male,
            primaryProvider: ClinicianSummary(id: "clinician-5", displayName: "Dr. Collins"),
            identifiers: []
        ),
        Patient(
            id: PatientID("demo-006"),
            mrn: "MRN-006",
            name: PersonName(given: "Fiona", family: "Allen"),
            birthDate: Date(timeIntervalSince1970: 500_000),
            gender: .female,
            primaryProvider: ClinicianSummary(id: "clinician-6", displayName: "Dr. Moore"),
            identifiers: []
        ),
        Patient(
            id: PatientID("demo-007"),
            mrn: "MRN-007",
            name: PersonName(given: "Gabriel", family: "Scott"),
            birthDate: Date(timeIntervalSince1970: 600_000),
            gender: .male,
            primaryProvider: ClinicianSummary(id: "clinician-7", displayName: "Dr. Barnes"),
            identifiers: []
        ),
        Patient(
            id: PatientID("demo-008"),
            mrn: "MRN-008",
            name: PersonName(given: "Helen", family: "Martin"),
            birthDate: Date(timeIntervalSince1970: 700_000),
            gender: .female,
            primaryProvider: ClinicianSummary(id: "clinician-8", displayName: "Dr. Fields"),
            identifiers: []
        ),
        Patient(
            id: PatientID("demo-009"),
            mrn: "MRN-009",
            name: PersonName(given: "Isabella", family: "Cooper"),
            birthDate: Date(timeIntervalSince1970: 800_000),
            gender: .female,
            primaryProvider: ClinicianSummary(id: "clinician-9", displayName: "Dr. Taylor"),
            identifiers: []
        ),
        Patient(
            id: PatientID("demo-010"),
            mrn: "MRN-010",
            name: PersonName(given: "John", family: "Greene"),
            birthDate: Date(timeIntervalSince1970: 900_000),
            gender: .male,
            primaryProvider: ClinicianSummary(id: "clinician-10", displayName: "Dr. Pratt"),
            identifiers: []
        ),
        Patient(
            id: PatientID("demo-011"),
            mrn: "MRN-011",
            name: PersonName(given: "Kara", family: "Miller"),
            birthDate: Date(timeIntervalSince1970: 1_000_000),
            gender: .female,
            primaryProvider: ClinicianSummary(id: "clinician-11", displayName: "Dr. Adams"),
            identifiers: []
        ),
        Patient(
            id: PatientID("demo-012"),
            mrn: "MRN-012",
            name: PersonName(given: "Leo", family: "Preston"),
            birthDate: Date(timeIntervalSince1970: 1_100_000),
            gender: .male,
            primaryProvider: ClinicianSummary(id: "clinician-12", displayName: "Dr. Rivers"),
            identifiers: []
        ),
        Patient(
            id: PatientID("demo-013"),
            mrn: "MRN-013",
            name: PersonName(given: "Mary", family: "Fisher"),
            birthDate: Date(timeIntervalSince1970: 1_200_000),
            gender: .female,
            primaryProvider: ClinicianSummary(id: "clinician-13", displayName: "Dr. Lewis"),
            identifiers: []
        ),
        Patient(
            id: PatientID("demo-014"),
            mrn: "MRN-014",
            name: PersonName(given: "Nicholas", family: "Foster"),
            birthDate: Date(timeIntervalSince1970: 1_300_000),
            gender: .male,
            primaryProvider: ClinicianSummary(id: "clinician-14", displayName: "Dr. Ashton"),
            identifiers: []
        ),
        Patient(
            id: PatientID("demo-015"),
            mrn: "MRN-015",
            name: PersonName(given: "Olivia", family: "Carter"),
            birthDate: Date(timeIntervalSince1970: 1_400_000),
            gender: .female,
            primaryProvider: ClinicianSummary(id: "clinician-15", displayName: "Dr. Maddox"),
            identifiers: []
        ),
        Patient(
            id: PatientID("demo-016"),
            mrn: "MRN-016",
            name: PersonName(given: "Paul", family: "Moore"),
            birthDate: Date(timeIntervalSince1970: 1_500_000),
            gender: .male,
            primaryProvider: ClinicianSummary(id: "clinician-16", displayName: "Dr. Barrett"),
            identifiers: []
        ),
        Patient(
            id: PatientID("demo-017"),
            mrn: "MRN-017",
            name: PersonName(given: "Quinn", family: "Abbott"),
            birthDate: Date(timeIntervalSince1970: 1_600_000),
            gender: .female,
            primaryProvider: ClinicianSummary(id: "clinician-17", displayName: "Dr. Page"),
            identifiers: []
        ),
        Patient(
            id: PatientID("demo-018"),
            mrn: "MRN-018",
            name: PersonName(given: "Ryan", family: "Davis"),
            birthDate: Date(timeIntervalSince1970: 1_700_000),
            gender: .male,
            primaryProvider: ClinicianSummary(id: "clinician-18", displayName: "Dr. Sawyer"),
            identifiers: []
        ),
        Patient(
            id: PatientID("demo-019"),
            mrn: "MRN-019",
            name: PersonName(given: "Sarah", family: "Myers"),
            birthDate: Date(timeIntervalSince1970: 1_800_000),
            gender: .female,
            primaryProvider: ClinicianSummary(id: "clinician-19", displayName: "Dr. Blake"),
            identifiers: []
        ),
        Patient(
            id: PatientID("demo-020"),
            mrn: "MRN-020",
            name: PersonName(given: "Trevor", family: "Randall"),
            birthDate: Date(timeIntervalSince1970: 1_900_000),
            gender: .male,
            primaryProvider: ClinicianSummary(id: "clinician-20", displayName: "Dr. Peterson"),
            identifiers: []
        )
    ]

    static let encounters: [Encounter] = [
        Encounter(
            id: "enc-1",
            patientID: PatientID("demo-001"),
            classCode: .outpatient,
            start: Date(),
            end: Date(),
            locationName: "Clinic A"
        ),
        Encounter(
            id: "enc-2",
            patientID: PatientID("demo-002"),
            classCode: .outpatient,
            start: Date(),
            end: Date(),
            locationName: "Clinic B"
        ),
        Encounter(
            id: "enc-3",
            patientID: PatientID("demo-003"),
            classCode: .outpatient,
            start: Date(),
            end: Date(),
            locationName: "Clinic C"
        ),
        Encounter(
            id: "enc-4",
            patientID: PatientID("demo-004"),
            classCode: .virtual,
            start: Date(),
            end: Date(),
            locationName: "Telehealth"
        ),
        Encounter(
            id: "enc-5",
            patientID: PatientID("demo-005"),
            classCode: .outpatient,
            start: Date(),
            end: Date(),
            locationName: "Clinic D"
        ),
        Encounter(
            id: "enc-6",
            patientID: PatientID("demo-006"),
            classCode: .emergency,
            start: Date(),
            end: Date(),
            locationName: "ER"
        ),
        Encounter(
            id: "enc-7",
            patientID: PatientID("demo-007"),
            classCode: .homeHealth,
            start: Date(),
            end: Date(),
            locationName: "Home Visit"
        ),
        Encounter(
            id: "enc-8",
            patientID: PatientID("demo-008"),
            classCode: .outpatient,
            start: Date(),
            end: Date(),
            locationName: "Clinic E"
        ),
        Encounter(
            id: "enc-9",
            patientID: PatientID("demo-009"),
            classCode: .inpatient,
            start: Date(),
            end: nil,
            locationName: "Pediatrics"
        ),
        Encounter(
            id: "enc-10",
            patientID: PatientID("demo-010"),
            classCode: .inpatient,
            start: Date(),
            end: nil,
            locationName: "Neuro ICU"
        ),
        Encounter(
            id: "enc-11",
            patientID: PatientID("demo-011"),
            classCode: .inpatient,
            start: Date(),
            end: nil,
            locationName: "8th Floor"
        ),
        Encounter(
            id: "enc-12",
            patientID: PatientID("demo-012"),
            classCode: .emergency,
            start: Date(),
            end: nil,
            locationName: "Red Zone"
        ),
        Encounter(
            id: "enc-13",
            patientID: PatientID("demo-013"),
            classCode: .inpatient,
            start: Date(),
            end: nil,
            locationName: "5th Floor"
        ),
        Encounter(
            id: "enc-14",
            patientID: PatientID("demo-014"),
            classCode: .inpatient,
            start: Date(),
            end: nil,
            locationName: "Isolation"
        ),
        Encounter(
            id: "enc-15",
            patientID: PatientID("demo-015"),
            classCode: .inpatient,
            start: Date(),
            end: nil,
            locationName: "4th Floor"
        ),
        Encounter(
            id: "enc-16",
            patientID: PatientID("demo-016"),
            classCode: .inpatient,
            start: Date(),
            end: nil,
            locationName: "Maternity"
        ),
        Encounter(
            id: "enc-17",
            patientID: PatientID("demo-017"),
            classCode: .inpatient,
            start: Date(),
            end: nil,
            locationName: "Hemodialysis"
        ),
        Encounter(
            id: "enc-18",
            patientID: PatientID("demo-018"),
            classCode: .outpatient,
            start: Date(),
            end: Date(),
            locationName: "Day Clinic"
        ),
        Encounter(
            id: "enc-19",
            patientID: PatientID("demo-019"),
            classCode: .outpatient,
            start: Date(),
            end: Date(),
            locationName: "ENT Clinic"
        ),
        Encounter(
            id: "enc-20",
            patientID: PatientID("demo-020"),
            classCode: .emergency,
            start: Date(),
            end: nil,
            locationName: "Yellow Zone"
        )
    ]

    static let observations: [Observation] = [
        Observation(
            id: "obs-1",
            patientID: PatientID("demo-001"),
            code: Code(system: "loinc", code: "85354-9", display: "Blood pressure panel"),
            effectiveDate: Date(),
            value: .quantity(value: 120, unit: "mmHg")
        ),
        Observation(
            id: "obs-2",
            patientID: PatientID("demo-001"),
            code: Code(system: "loinc", code: "8462-4", display: "Diastolic"),
            effectiveDate: Date(),
            value: .quantity(value: 80, unit: "mmHg")
        ),
        Observation(
            id: "obs-3",
            patientID: PatientID("demo-002"),
            code: Code(system: "loinc", code: "8867-4", display: "Heart rate"),
            effectiveDate: Date(),
            value: .quantity(value: 72, unit: "bpm")
        ),
        Observation(
            id: "obs-4",
            patientID: PatientID("demo-002"),
            code: Code(system: "loinc", code: "8480-6", display: "Systolic"),
            effectiveDate: Date(),
            value: .quantity(value: 118, unit: "mmHg")
        ),
        Observation(
            id: "obs-5",
            patientID: PatientID("demo-003"),
            code: Code(system: "loinc", code: "8310-5", display: "Body temperature"),
            effectiveDate: Date(),
            value: .quantity(value: 36.7, unit: "C")
        ),
        Observation(
            id: "obs-6",
            patientID: PatientID("demo-003"),
            code: Code(system: "loinc", code: "8287-5", display: "Oxygen saturation"),
            effectiveDate: Date(),
            value: .quantity(value: 98, unit: "%")
        ),
        Observation(
            id: "obs-7",
            patientID: PatientID("demo-004"),
            code: Code(system: "loinc", code: "29463-7", display: "Body weight"),
            effectiveDate: Date(),
            value: .quantity(value: 68, unit: "kg")
        ),
        Observation(
            id: "obs-8",
            patientID: PatientID("demo-004"),
            code: Code(system: "loinc", code: "8302-2", display: "Body height"),
            effectiveDate: Date(),
            value: .quantity(value: 170, unit: "cm")
        ),
        Observation(
            id: "obs-9",
            patientID: PatientID("demo-005"),
            code: Code(system: "loinc", code: "2339-0", display: "Glucose"),
            effectiveDate: Date(),
            value: .quantity(value: 92, unit: "mg/dL")
        ),
        Observation(
            id: "obs-10",
            patientID: PatientID("demo-005"),
            code: Code(system: "loinc", code: "718-7", display: "Hemoglobin"),
            effectiveDate: Date(),
            value: .quantity(value: 13.8, unit: "g/dL")
        ),
        Observation(
            id: "obs-11",
            patientID: PatientID("demo-006"),
            code: Code(system: "loinc", code: "14749-6", display: "Respiratory rate"),
            effectiveDate: Date(),
            value: .quantity(value: 18, unit: "breaths/min")
        ),
        Observation(
            id: "obs-12",
            patientID: PatientID("demo-006"),
            code: Code(system: "loinc", code: "8480-6", display: "Systolic"),
            effectiveDate: Date(),
            value: .quantity(value: 126, unit: "mmHg")
        ),
        Observation(
            id: "obs-13",
            patientID: PatientID("demo-007"),
            code: Code(system: "loinc", code: "59576-9", display: "BMI"),
            effectiveDate: Date(),
            value: .quantity(value: 24.5, unit: "kg/m2")
        ),
        Observation(
            id: "obs-14",
            patientID: PatientID("demo-007"),
            code: Code(system: "loinc", code: "8302-2", display: "Body height"),
            effectiveDate: Date(),
            value: .quantity(value: 182, unit: "cm")
        ),
        Observation(
            id: "obs-15",
            patientID: PatientID("demo-008"),
            code: Code(system: "loinc", code: "55284-4", display: "Blood pressure systolic & diastolic"),
            effectiveDate: Date(),
            value: .quantity(value: 115, unit: "mmHg")
        ),
        Observation(
            id: "obs-16",
            patientID: PatientID("demo-008"),
            code: Code(system: "loinc", code: "8867-4", display: "Heart rate"),
            effectiveDate: Date(),
            value: .quantity(value: 75, unit: "bpm")
        )
    ]
}

struct DemoPatientRepository: PatientRepository {
    private let patients: [Patient]

    init(patients: [Patient]) {
        self.patients = patients
    }

    func searchPatients(query: String?, page: Int, pageSize: Int) async throws -> [Patient] {
        guard let term = query?.lowercased(), !term.isEmpty else {
            return patients
        }
        return patients.filter { p in
            p.name.given.lowercased().contains(term) || p.name.family.lowercased().contains(term)
        }
    }

    func patient(by id: PatientID) async throws -> Patient? {
        patients.first { $0.id == id }
    }
}

struct DemoEncounterRepository: EncounterRepository {
    private let encounters: [Encounter]

    init(encounters: [Encounter]) {
        self.encounters = encounters
    }

    func encounters(for patientID: PatientID) async throws -> [Encounter] {
        encounters.filter { $0.patientID == patientID }
    }
}

struct DemoObservationRepository: ObservationRepository {
    private let observations: [Observation]

    init(observations: [Observation]) {
        self.observations = observations
    }

    func recentVitals(for patientID: PatientID, limit: Int) async throws -> [Observation] {
        let filtered = observations.filter { $0.patientID == patientID }
        return Array(filtered.prefix(limit))
    }
}
