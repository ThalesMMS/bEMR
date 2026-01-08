import Foundation
import Combine
import CoreUseCases
import CoreDomain

@MainActor
public final class PatientListViewModel: ObservableObject {
    @Published public private(set) var patients: [PatientRowViewModel] = []
    @Published public private(set) var isLoading = false
    @Published public var errorMessage: String?

    private let loadPatientList: LoadPatientListUseCase

    public init(loadPatientList: LoadPatientListUseCase) {
        self.loadPatientList = loadPatientList
    }

    public func load(query: String? = nil, page: Int = 0) {
        Task {
            await executeLoad(query: query, page: page)
        }
    }

    private func executeLoad(query: String?, page: Int) async {
        isLoading = true
        defer { isLoading = false }
        do {
            let result = try await loadPatientList.execute(query: query, page: page)
            patients = result.map(PatientRowViewModel.init)
            errorMessage = nil
        } catch {
            errorMessage = "Unable to load patients."
        }
    }
}

public struct PatientRowViewModel: Identifiable, Sendable {
    public let id: PatientID
    public let displayName: String
    public let mrn: String?
    public let age: String
    public let gender: String
    public let priority: PatientPriority
    public let status: PatientStatus
    public let receptionTime: String
    public let specialty: String
    public let sector: String?
    public let bed: String?
    public let procedure: String?
    public let diagnosis: String?
    public let hasPrescriptionToday: Bool
    public let hasDischargeOrder: Bool
    public let admittedDaysText: String?
    public let hasAlerts: Bool
    public var needsAttention: Bool { priority == .emergency || priority == .urgent }

    public init(patient: Patient) {
        self.id = patient.id
        self.displayName = "\(patient.name.family), \(patient.name.given)"
        self.mrn = patient.mrn
        
        // Derived/Mocked data for UI demo purposes
        self.age = patient.birthDate.map {
            let ageComponents = Calendar.current.dateComponents([.year], from: $0, to: Date())
            return "\(ageComponents.year ?? 0) Years"
        } ?? "--"
        
        self.gender = patient.gender.rawValue.capitalized
        
        // Demo-only metadata to keep the UI deterministic.
        if let meta = DemoPatientMetadataRegistry.list[patient.id] {
            self.priority = meta.priority
            self.status = meta.status
            self.receptionTime = meta.receptionTime
            self.specialty = meta.specialty
            self.sector = meta.sector
            self.bed = meta.bed
            self.procedure = meta.procedure
            self.diagnosis = meta.diagnosis
            self.hasPrescriptionToday = meta.hasPrescriptionToday
            self.hasDischargeOrder = meta.hasDischargeOrder
            self.hasAlerts = meta.hasAlerts
            if let admissionDate = meta.admissionDate {
                let days = Calendar.current.dateComponents([.day], from: admissionDate, to: Date()).day ?? 0
                self.admittedDaysText = days > 0 ? "\(days)d" : "<1d"
            } else {
                self.admittedDaysText = nil
            }
        } else {
            self.priority = PatientPriority.allCases.randomElement() ?? .normal
            self.status = PatientStatus.allCases.randomElement() ?? .waiting
            self.receptionTime = Date().addingTimeInterval(Double.random(in: -3600...0)).formatted(date: .omitted, time: .shortened)
            self.specialty = ["Cardiology", "General", "Orthopedics", "Pediatrics"].randomElement() ?? "General"
            self.sector = nil
            self.bed = nil
            self.procedure = nil
            self.diagnosis = nil
            self.hasPrescriptionToday = false
            self.hasDischargeOrder = false
            self.hasAlerts = false
            self.admittedDaysText = nil
        }
    }
}

public enum PatientPriority: String, CaseIterable, Sendable {
    case emergency, urgent, normal
    
    public var colorHex: String {
        switch self {
        case .emergency: return "EF4444" // Red
        case .urgent: return "F59E0B" // Orange
        case .normal: return "10B981" // Green
        }
    }
}

public enum PatientStatus: String, CaseIterable, Sendable {
    case waiting = "Waiting"
    case inAttendance = "In Attendance"
    case attended = "Attended"
    case discharged = "Discharged"
}
