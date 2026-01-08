import Foundation
import CoreDomain

public struct DemoPrescriptionLine: Identifiable, Sendable, Codable {
    public let id: UUID
    public let type: String
    public let description: String
    public let quantity: String
    public let frequency: String
    public let route: String
    public let duration: String

    public init(id: UUID = UUID(), type: String, description: String, quantity: String, frequency: String, route: String, duration: String) {
        self.id = id
        self.type = type
        self.description = description
        self.quantity = quantity
        self.frequency = frequency
        self.route = route
        self.duration = duration
    }
}

public struct DemoPrescriptionSectionData: Identifiable, Sendable {
    public let id = UUID()
    public let title: String
    public let items: [DemoPrescriptionLine]
}

public struct DemoEvolutionNote: Identifiable, Sendable, Codable {
    public let id: UUID
    public let author: String
    public let role: String
    public let text: String
    public let details: [String]?
    public let date: Date

    public init(id: UUID = UUID(), author: String, role: String, text: String, details: [String]?, date: Date) {
        self.id = id
        self.author = author
        self.role = role
        self.text = text
        self.details = details
        self.date = date
    }
}

public struct DemoPrescriptionHistory: Identifiable, Sendable, Codable {
    public let id: UUID
    public let date: Date
    public let summary: String
    public let medicationCount: Int
    public let solutionCount: Int
    public let items: [DemoPrescriptionLine]

    public init(id: UUID = UUID(), date: Date, summary: String, medicationCount: Int, solutionCount: Int, items: [DemoPrescriptionLine]) {
        self.id = id
        self.date = date
        self.summary = summary
        self.medicationCount = medicationCount
        self.solutionCount = solutionCount
        self.items = items
    }
}

public struct DemoAnamnesisEntry: Identifiable, Sendable {
    public let id = UUID()
    public let patientID: PatientID
    public let chiefComplaint: String
    public let presentIllness: String
    public let pastHistory: [String]
    public let recordedDate: Date
}

public struct DemoDiagnosisEntry: Identifiable, Sendable {
    public enum Status: String, Sendable { case active, resolved, provisional }
    public let id = UUID()
    public let patientID: PatientID
    public let code: String
    public let description: String
    public let status: Status
    public let recordedDate: Date
}

public struct DemoAllergyEntry: Identifiable, Sendable {
    public enum Severity: String, Sendable { case mild, moderate, severe }
    public let id = UUID()
    public let patientID: PatientID
    public let allergen: String
    public let reaction: String
    public let severity: Severity
    public let recordedDate: Date
}

public struct DemoExamEntry: Identifiable, Sendable {
    public enum Status: String, Sendable { case pending, completed, reviewed }
    public let id = UUID()
    public let patientID: PatientID
    public let name: String
    public let details: String
    public let status: Status
    public let requestedDate: Date
}

public enum DemoSummaryRegistry {
    public static func prescriptions(for patientID: PatientID) -> [DemoPrescriptionSectionData] {
        switch patientID.rawValue {
        case "demo-002":
            return cardio()
        case "demo-012":
            return sepsis()
        case "demo-010":
            return neuro()
        default:
            return baseline()
        }
    }

    public static func prescriptionHistory(for patientID: PatientID) -> [DemoPrescriptionHistory] {
        switch patientID.rawValue {
        case "demo-002":
            return demoPrescriptionHistoryCardio
        case "demo-012":
            return demoPrescriptionHistorySepsis
        default:
            return demoPrescriptionHistoryDefault
        }
    }

    public static func evolutions(for patientID: PatientID) -> [DemoEvolutionNote] {
        let now = Date()
        switch patientID.rawValue {
        case "demo-002":
            return [
                DemoEvolutionNote(author: "Dr. Carter", role: "Cardiology", text: "Patient reports chest pain improving after nitrate. Continue continuous monitoring.", details: ["BP 120x80", "SpO2 97%", "Pain 2/10"], date: now - 3_600),
                DemoEvolutionNote(author: "Dr. Carter", role: "Cardiology", text: "Troponin trending down; plan transfer to step-down unit.", details: ["Troponin 0.12", "ECG stable"], date: now - 27_000)
            ]
        case "demo-012":
            return [
                DemoEvolutionNote(author: "Dr. Taylor", role: "Emergency", text: "Sepsis on broad-spectrum antibiotics, MAP 70, lactate trending down.", details: ["Total volume 30 ml/kg", "Norepinephrine 0.08 mcg/kg/min"], date: now - 5_400),
                DemoEvolutionNote(author: "Dr. Taylor", role: "Emergency", text: "Cultures collected; reassess fluids after repeat lactate.", details: ["Blood cultures x2", "Lactate 2.1"], date: now - 14_400)
            ]
        default:
            return [
                DemoEvolutionNote(author: "Dr. Smith", role: "Internal Medicine", text: "Patient stable; continue diet, analgesia, and assisted ambulation.", details: ["BP 118x76", "Afebrile"], date: now - 8_000),
                DemoEvolutionNote(author: "Nurse Parker", role: "Nursing", text: "Dressing clean and dry; no pain complaints.", details: ["Dressing dry", "Pain 0/10"], date: now - 16_000)
            ]
        }
    }

    public static func anamnesis(for patientID: PatientID) -> DemoAnamnesisEntry? {
        demoAnamnesis.first { $0.patientID == patientID }
    }

    public static func diagnoses(for patientID: PatientID) -> [DemoDiagnosisEntry] {
        demoDiagnoses.filter { $0.patientID == patientID }
    }

    public static func allergies(for patientID: PatientID) -> [DemoAllergyEntry] {
        demoAllergies.filter { $0.patientID == patientID }
    }

    public static func exams(for patientID: PatientID) -> [DemoExamEntry] {
        demoExams.filter { $0.patientID == patientID }
    }

    // MARK: - Private mocks
    private static func baseline() -> [DemoPrescriptionSectionData] {
        [
            DemoPrescriptionSectionData(
                title: "IV Fluids",
                items: [
                    DemoPrescriptionLine(type: "NS 0.9%", description: "500 ml", quantity: "1 bag", frequency: "q6h", route: "IV", duration: "2d"),
                    DemoPrescriptionLine(type: "Dextrose 5% with KCl 10 mEq", description: "500 ml", quantity: "1 bag", frequency: "q12h", route: "IV", duration: "2d")
                ]
            ),
            DemoPrescriptionSectionData(
                title: "Medications",
                items: [
                    DemoPrescriptionLine(type: "Metamizole", description: "1 g", quantity: "1 amp", frequency: "q6h", route: "IV", duration: "2d"),
                    DemoPrescriptionLine(type: "Omeprazole", description: "40 mg", quantity: "1 tab", frequency: "daily", route: "PO", duration: "5d")
                ]
            )
        ]
    }

    private static func cardio() -> [DemoPrescriptionSectionData] {
        [
            DemoPrescriptionSectionData(
                title: "IV Fluids",
                items: [
                    DemoPrescriptionLine(type: "NS 0.9%", description: "1000 ml", quantity: "1 bag", frequency: "q8h", route: "IV", duration: "1d")
                ]
            ),
            DemoPrescriptionSectionData(
                title: "Medications",
                items: [
                    DemoPrescriptionLine(type: "Aspirin", description: "100 mg", quantity: "1 tab", frequency: "daily", route: "PO", duration: "indef."),
                    DemoPrescriptionLine(type: "Clopidogrel", description: "75 mg", quantity: "1 tab", frequency: "daily", route: "PO", duration: "indef."),
                    DemoPrescriptionLine(type: "Enoxaparin", description: "60 mg", quantity: "1 syringe", frequency: "q12h", route: "SC", duration: "5d")
                ]
            )
        ]
    }

    private static func sepsis() -> [DemoPrescriptionSectionData] {
        [
            DemoPrescriptionSectionData(
                title: "Antibiotics",
                items: [
                    DemoPrescriptionLine(type: "Piperacillin/Tazobactam", description: "4.5 g", quantity: "1 vial", frequency: "q6h", route: "IV", duration: "7d"),
                    DemoPrescriptionLine(type: "Vancomycin", description: "1 g", quantity: "1 vial", frequency: "q12h", route: "IV", duration: "5d")
                ]
            ),
            DemoPrescriptionSectionData(
                title: "Support",
                items: [
                    DemoPrescriptionLine(type: "NS 0.9%", description: "500 ml", quantity: "1 bag", frequency: "q4h", route: "IV", duration: "1d")
                ]
            )
        ]
    }

    private static func neuro() -> [DemoPrescriptionSectionData] {
        [
            DemoPrescriptionSectionData(
                title: "Medications",
                items: [
                    DemoPrescriptionLine(type: "Levetiracetam", description: "500 mg", quantity: "1 tab", frequency: "q12h", route: "PO", duration: "10d"),
                    DemoPrescriptionLine(type: "Amlodipine", description: "5 mg", quantity: "1 tab", frequency: "daily", route: "PO", duration: "indef.")
                ]
            )
        ]
    }

    private static let demoAnamnesis: [DemoAnamnesisEntry] = [
        DemoAnamnesisEntry(
            patientID: PatientID("demo-001"),
            chiefComplaint: "Chest pain for 2h",
            presentIllness: "Tight pain radiating to left arm, partially relieved at rest.",
            pastHistory: ["Hypertension", "Type 2 diabetes"],
            recordedDate: Date().addingTimeInterval(-86_400)
        ),
        DemoAnamnesisEntry(
            patientID: PatientID("demo-012"),
            chiefComplaint: "Fever and hypotension",
            presentIllness: "Started 12h ago with vomiting; probable pulmonary source.",
            pastHistory: ["COPD"],
            recordedDate: Date().addingTimeInterval(-36_000)
        )
    ]

    private static let demoDiagnoses: [DemoDiagnosisEntry] = [
        DemoDiagnosisEntry(
            patientID: PatientID("demo-001"),
            code: "I21.9",
            description: "Acute myocardial infarction",
            status: .active,
            recordedDate: Date()
        ),
        DemoDiagnosisEntry(
            patientID: PatientID("demo-012"),
            code: "A41.9",
            description: "Sepsis of unclear source",
            status: .active,
            recordedDate: Date().addingTimeInterval(-18_000)
        ),
        DemoDiagnosisEntry(
            patientID: PatientID("demo-005"),
            code: "E10.65",
            description: "Type 1 diabetes with ketoacidosis",
            status: .resolved,
            recordedDate: Date().addingTimeInterval(-172_800)
        )
    ]

    private static let demoAllergies: [DemoAllergyEntry] = [
        DemoAllergyEntry(
            patientID: PatientID("demo-001"),
            allergen: "Penicilina",
            reaction: "Rash and pruritus",
            severity: .moderate,
            recordedDate: Date().addingTimeInterval(-31_536_000)
        ),
        DemoAllergyEntry(
            patientID: PatientID("demo-009"),
            allergen: "Amendoim",
            reaction: "Lip swelling",
            severity: .severe,
            recordedDate: Date().addingTimeInterval(-5_184_000)
        )
    ]

    private static let demoExams: [DemoExamEntry] = [
        DemoExamEntry(
            patientID: PatientID("demo-001"),
            name: "ECG",
            details: "ST elevation in V2-V4",
            status: .completed,
            requestedDate: Date()
        ),
        DemoExamEntry(
            patientID: PatientID("demo-001"),
            name: "Troponin",
            details: "0.34 ng/mL",
            status: .completed,
            requestedDate: Date().addingTimeInterval(-3_600)
        ),
        DemoExamEntry(
            patientID: PatientID("demo-012"),
            name: "Blood culture",
            details: "Collected, pending result",
            status: .pending,
            requestedDate: Date().addingTimeInterval(-7_200)
        )
    ]

    private static let demoPrescriptionHistoryDefault: [DemoPrescriptionHistory] = [
        DemoPrescriptionHistory(
            date: Date().addingTimeInterval(-86_400),
            summary: "Clinical review; maintained analgesia",
            medicationCount: 3,
            solutionCount: 1,
            items: [
                DemoPrescriptionLine(type: "Metamizole", description: "1 g", quantity: "1 amp", frequency: "q6h", route: "IV", duration: "2d"),
                DemoPrescriptionLine(type: "Omeprazole", description: "40 mg", quantity: "1 tab", frequency: "daily", route: "PO", duration: "5d")
            ]
        ),
        DemoPrescriptionHistory(
            date: Date().addingTimeInterval(-172_800),
            summary: "PPI and diet adjusted",
            medicationCount: 2,
            solutionCount: 0,
            items: [
                DemoPrescriptionLine(type: "Omeprazole", description: "40 mg", quantity: "1 tab", frequency: "daily", route: "PO", duration: "5d"),
                DemoPrescriptionLine(type: "Soft diet", description: "Low sodium", quantity: "Ad libitum", frequency: "—", route: "PO", duration: "5d")
            ]
        )
    ]

    private static let demoPrescriptionHistoryCardio: [DemoPrescriptionHistory] = [
        DemoPrescriptionHistory(
            date: Date().addingTimeInterval(-14_400),
            summary: "Started dual antiplatelet therapy",
            medicationCount: 4,
            solutionCount: 1,
            items: [
                DemoPrescriptionLine(type: "Aspirin", description: "100 mg", quantity: "1 tab", frequency: "daily", route: "PO", duration: "indef."),
                DemoPrescriptionLine(type: "Clopidogrel", description: "75 mg", quantity: "1 tab", frequency: "daily", route: "PO", duration: "indef."),
                DemoPrescriptionLine(type: "Enoxaparin", description: "60 mg", quantity: "1 syringe", frequency: "q12h", route: "SC", duration: "5d")
            ]
        ),
        DemoPrescriptionHistory(
            date: Date().addingTimeInterval(-64_800),
            summary: "Aspirin load and nitrate",
            medicationCount: 3,
            solutionCount: 1,
            items: [
                DemoPrescriptionLine(type: "Aspirin", description: "300 mg loading", quantity: "1", frequency: "once", route: "PO", duration: "1x"),
                DemoPrescriptionLine(type: "Nitroglycerin", description: "10 mcg/min", quantity: "IV infusion", frequency: "continuous", route: "IV", duration: "6h")
            ]
        )
    ]

    private static let demoPrescriptionHistorySepsis: [DemoPrescriptionHistory] = [
        DemoPrescriptionHistory(
            date: Date().addingTimeInterval(-10_800),
            summary: "Started broad spectrum + fluids",
            medicationCount: 5,
            solutionCount: 2,
            items: [
                DemoPrescriptionLine(type: "Pip/Tazo", description: "4.5 g", quantity: "1 vial", frequency: "q6h", route: "IV", duration: "7d"),
                DemoPrescriptionLine(type: "Vancomycin", description: "1 g", quantity: "1 vial", frequency: "q12h", route: "IV", duration: "5d"),
                DemoPrescriptionLine(type: "NS 0.9%", description: "500 ml", quantity: "1 bag", frequency: "q4h", route: "IV", duration: "1d")
            ]
        ),
        DemoPrescriptionHistory(
            date: Date().addingTimeInterval(-36_000),
            summary: "Antibiotic adjustment per protocol",
            medicationCount: 4,
            solutionCount: 2,
            items: [
                DemoPrescriptionLine(type: "Meropenem", description: "1 g", quantity: "1 vial", frequency: "q8h", route: "IV", duration: "7d"),
                DemoPrescriptionLine(type: "NS 0.9%", description: "500 ml", quantity: "1 bag", frequency: "q6h", route: "IV", duration: "1d")
            ]
        )
    ]
}
