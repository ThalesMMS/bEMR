import Foundation
import CoreDomain

/// Demo-only metadata used to enrich PatientRowViewModel without touching core domain models.
struct DemoPatientListMetadata: Sendable {
    let priority: PatientPriority
    let status: PatientStatus
    let receptionTime: String
    let specialty: String
    let admissionDate: Date?
    let sector: String?
    let bed: String?
    let procedure: String?
    let diagnosis: String?
    let hasPrescriptionToday: Bool
    let hasDischargeOrder: Bool
    let hasAlerts: Bool
}

enum DemoPatientMetadataRegistry {
    /// Central lookup so UI can stay deterministic during demo runs.
    static let list: [PatientID: DemoPatientListMetadata] = {
        let now = Date()
        let day: TimeInterval = 86_400

        return [
            "demo-001": DemoPatientListMetadata(
                priority: .normal,
                status: .waiting,
                receptionTime: "08:15",
                specialty: "Internal Medicine",
                admissionDate: now - day * 1,
                sector: "7th Floor",
                bed: "701-B",
            procedure: "Clinic visit",
            diagnosis: "E11.9 - Type 2 diabetes",
            hasPrescriptionToday: true,
            hasDischargeOrder: false,
            hasAlerts: false
        ),
            "demo-002": DemoPatientListMetadata(
                priority: .urgent,
                status: .inAttendance,
                receptionTime: "08:40",
                specialty: "Cardiology",
                admissionDate: now - day * 2,
                sector: "ICU 2",
                bed: "12",
            procedure: "Chest pain",
            diagnosis: "I21.4 - Acute MI",
            hasPrescriptionToday: true,
            hasDischargeOrder: false,
            hasAlerts: true
        ),
            "demo-003": DemoPatientListMetadata(
                priority: .emergency,
                status: .waiting,
                receptionTime: "09:05",
                specialty: "Emergency",
                admissionDate: now - day * 0,
                sector: "Emergency Department",
                bed: "Box 3",
            procedure: "Trauma",
            diagnosis: "S06.0 - Mild TBI",
            hasPrescriptionToday: false,
            hasDischargeOrder: false,
            hasAlerts: true
        ),
            "demo-004": DemoPatientListMetadata(
                priority: .normal,
                status: .attended,
                receptionTime: "10:10",
                specialty: "Telemedicine",
                admissionDate: now - day * 5,
                sector: "Telehealth",
                bed: nil,
            procedure: "Follow-up",
            diagnosis: "J45 - Asthma",
            hasPrescriptionToday: true,
            hasDischargeOrder: false,
            hasAlerts: false
        ),
            "demo-005": DemoPatientListMetadata(
                priority: .urgent,
                status: .waiting,
                receptionTime: "11:00",
                specialty: "Endocrinology",
                admissionDate: now - day * 3,
                sector: "10th Floor",
                bed: "1008-A",
            procedure: "Glycemic decompensation",
            diagnosis: "E10.65 - Type 1 DM with ketoacidosis",
            hasPrescriptionToday: true,
            hasDischargeOrder: false,
            hasAlerts: false
        ),
            "demo-006": DemoPatientListMetadata(
                priority: .normal,
                status: .inAttendance,
                receptionTime: "11:25",
                specialty: "Geriatrics",
                admissionDate: now - day * 7,
                sector: "9th Floor",
                bed: "903",
            procedure: "Delirium",
            diagnosis: "F05 - Delirium",
            hasPrescriptionToday: true,
            hasDischargeOrder: true,
            hasAlerts: true
        ),
            "demo-007": DemoPatientListMetadata(
                priority: .normal,
                status: .discharged,
                receptionTime: "07:55",
                specialty: "Orthopedics",
                admissionDate: now - day * 4,
                sector: "6th Floor",
                bed: "602",
            procedure: "Post-op",
            diagnosis: "Z47.1 - Post-surgical care",
            hasPrescriptionToday: false,
            hasDischargeOrder: true,
            hasAlerts: false
        ),
            "demo-008": DemoPatientListMetadata(
                priority: .urgent,
                status: .waiting,
                receptionTime: "12:10",
                specialty: "Oncology",
                admissionDate: now - day * 10,
                sector: "Oncology 1",
                bed: "15",
            procedure: "Chemo D3",
            diagnosis: "C50 - Breast cancer",
            hasPrescriptionToday: true,
            hasDischargeOrder: false,
            hasAlerts: false
        ),
            "demo-009": DemoPatientListMetadata(
                priority: .normal,
                status: .waiting,
                receptionTime: "13:05",
                specialty: "Pediatrics",
                admissionDate: now - day * 1,
                sector: "Pediatrics",
                bed: "P-12",
            procedure: "Bronchiolitis",
            diagnosis: "J21 - Bronchiolitis",
            hasPrescriptionToday: true,
            hasDischargeOrder: false,
            hasAlerts: false
        ),
            "demo-010": DemoPatientListMetadata(
                priority: .urgent,
                status: .inAttendance,
                receptionTime: "13:40",
                specialty: "Neurology",
                admissionDate: now - day * 6,
                sector: "Neuro ICU",
                bed: "N-04",
            procedure: "Ischemic stroke",
            diagnosis: "I63.9",
            hasPrescriptionToday: true,
            hasDischargeOrder: false,
            hasAlerts: true
        ),
            "demo-011": DemoPatientListMetadata(
                priority: .normal,
                status: .attended,
                receptionTime: "14:10",
                specialty: "Rheumatology",
                admissionDate: now - day * 9,
                sector: "8th Floor",
                bed: "805",
            procedure: "SLE flare",
            diagnosis: "M32.1",
            hasPrescriptionToday: false,
            hasDischargeOrder: false,
            hasAlerts: false
        ),
            "demo-012": DemoPatientListMetadata(
                priority: .emergency,
                status: .waiting,
                receptionTime: "14:35",
                specialty: "Emergency",
                admissionDate: now - day * 0,
                sector: "Red Zone",
                bed: "VR-2",
            procedure: "Sepsis",
            diagnosis: "A41.9",
            hasPrescriptionToday: true,
            hasDischargeOrder: false,
            hasAlerts: true
        ),
            "demo-013": DemoPatientListMetadata(
                priority: .normal,
                status: .waiting,
                receptionTime: "15:00",
                specialty: "Gastroenterology",
                admissionDate: now - day * 2,
                sector: "5th Floor",
                bed: "510",
            procedure: "GI bleed",
            diagnosis: "K92.2",
            hasPrescriptionToday: true,
            hasDischargeOrder: false,
            hasAlerts: false
        ),
            "demo-014": DemoPatientListMetadata(
                priority: .urgent,
                status: .inAttendance,
                receptionTime: "15:20",
                specialty: "Infectious Diseases",
                admissionDate: now - day * 12,
                sector: "Isolation",
                bed: "ISO-3",
            procedure: "Pneumonia",
            diagnosis: "J18.9",
            hasPrescriptionToday: true,
            hasDischargeOrder: false,
            hasAlerts: true
        ),
            "demo-015": DemoPatientListMetadata(
                priority: .normal,
                status: .attended,
                receptionTime: "16:00",
                specialty: "Dermatology",
                admissionDate: now - day * 14,
                sector: "4th Floor",
                bed: "402",
            procedure: "Psoriasis",
            diagnosis: "L40",
            hasPrescriptionToday: false,
            hasDischargeOrder: false,
            hasAlerts: false
        ),
            "demo-016": DemoPatientListMetadata(
                priority: .normal,
                status: .waiting,
                receptionTime: "16:25",
                specialty: "Obstetrics",
                admissionDate: now - day * 1,
                sector: "Maternity",
                bed: "M-07",
            procedure: "High-risk prenatal care",
            diagnosis: "O24.4",
            hasPrescriptionToday: true,
            hasDischargeOrder: false,
            hasAlerts: false
        ),
            "demo-017": DemoPatientListMetadata(
                priority: .urgent,
                status: .waiting,
                receptionTime: "17:05",
                specialty: "Nephrology",
                admissionDate: now - day * 8,
                sector: "Hemodialysis",
                bed: "HD-2",
            procedure: "Tunneled catheter",
            diagnosis: "N18.5",
            hasPrescriptionToday: true,
            hasDischargeOrder: false,
            hasAlerts: false
        ),
            "demo-018": DemoPatientListMetadata(
                priority: .normal,
                status: .discharged,
                receptionTime: "17:40",
                specialty: "Ophthalmology",
                admissionDate: now - day * 0,
                sector: "Day Clinic",
                bed: "DC-1",
            procedure: "Post-cataract",
            diagnosis: "H26",
            hasPrescriptionToday: false,
            hasDischargeOrder: true,
            hasAlerts: false
        ),
            "demo-019": DemoPatientListMetadata(
                priority: .normal,
                status: .waiting,
                receptionTime: "18:05",
                specialty: "Otolaryngology",
                admissionDate: now - day * 3,
                sector: "ENT Clinic",
                bed: nil,
            procedure: "Chronic sinusitis",
            diagnosis: "J32.9",
            hasPrescriptionToday: true,
            hasDischargeOrder: false,
            hasAlerts: false
        ),
            "demo-020": DemoPatientListMetadata(
                priority: .emergency,
                status: .inAttendance,
                receptionTime: "18:30",
                specialty: "Emergency",
                admissionDate: now - day * 0,
                sector: "Yellow Zone",
                bed: "A-2",
            procedure: "Dyspnea",
            diagnosis: "J96.0",
            hasPrescriptionToday: true,
            hasDischargeOrder: false,
            hasAlerts: true
        )
        ].reduce(into: [PatientID: DemoPatientListMetadata]()) { dict, element in
            dict[PatientID(element.key)] = element.value
        }
    }()
}
