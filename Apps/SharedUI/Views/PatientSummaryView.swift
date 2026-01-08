import SwiftUI
import SharedPresentation
import CoreDomain

public struct PatientSummaryView: View {
    @Environment(\.emrTheme) private var theme
    @StateObject private var viewModel: PatientSummaryViewModel
    private let patientID: PatientID
    
    @State private var selectedTab: SummaryTab = .prescription
    @State private var anamnesis: DemoAnamnesisEntry?
    @State private var diagnoses: [DemoDiagnosisEntry] = []
    @State private var allergies: [DemoAllergyEntry] = []
    @State private var exams: [DemoExamEntry] = []
    @StateObject private var rxService: PrescriptionServiceBox
    @StateObject private var evoService: EvolutionServiceBox

    public enum SummaryTab: String, CaseIterable, Identifiable {
        case anamnesis = "History"
        case diagnosis = "Diagnoses"
        case allergies = "Allergies"
        case prescription = "Medications"
        case evolution = "Progress Notes"
        case exams = "Exams"
        
        public var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .anamnesis: return "doc.text"
            case .diagnosis: return "stethoscope"
            case .allergies: return "exclamationmark.shield"
            case .prescription: return "pills"
            case .evolution: return "note.text"
            case .exams: return "waveform.path.ecg"
            }
        }
    }

    public init(
        patientID: PatientID,
        viewModel: PatientSummaryViewModel,
        prescriptionService: (any PrescriptionService)? = nil,
        evolutionService: (any EvolutionService)? = nil
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.patientID = patientID
        let rxBase = prescriptionService ?? DemoPrescriptionService(patientID: patientID)
        let evoBase = evolutionService ?? DemoEvolutionService(patientID: patientID)
        _rxService = StateObject(wrappedValue: PrescriptionServiceBox(rxBase))
        _evoService = StateObject(wrappedValue: EvolutionServiceBox(evoBase))
    }

    public var body: some View {
        HStack(spacing: 0) {
            // Sidebar
            VStack(spacing: theme.metrics.spacingXS) {
                ForEach(SummaryTab.allCases) { tab in
                    sidebarButton(tab)
                }
                Spacer()
            }
            .padding(theme.metrics.spacingSM)
            .frame(width: 200)
            .background(theme.colors.surface)
            .overlay(
                Rectangle()
                    .frame(width: 1)
                    .foregroundStyle(theme.colors.border),
                alignment: .trailing
            )
            
            // Main Content
            VStack(spacing: 0) {
                if let summary = viewModel.summary {
                    // Patient Header
                    PatientHeaderView(
                        patient: summary.patient,
                        subtitle: selectedTab.rawValue,
                        badges: [
                            EMRBadge("Inpatient", style: .info),
                            EMRBadge("Fall Risk", style: .warning)
                        ]
                    )
                    .padding(theme.metrics.spacingMD)
                    .background(theme.colors.surface)
                    .shadow(color: Color.black.opacity(0.02), radius: 2, y: 1)
                    .zIndex(1)
                    
                    // Content
                    contentView(for: selectedTab)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(theme.colors.background)
                } else if viewModel.isLoading {
                    EMRLoadingOverlay(message: "Loading patient data")
                } else {
                    EMREmptyStateView(
                        systemImage: "person.text.rectangle",
                        title: "No Data",
                        message: "Unable to load patient data."
                    )
                }
            }
        }
        .navigationTitle("Medical Care")
        .task {
            viewModel.load(patientID: patientID)
            anamnesis = DemoSummaryRegistry.anamnesis(for: patientID)
            diagnoses = DemoSummaryRegistry.diagnoses(for: patientID)
            allergies = DemoSummaryRegistry.allergies(for: patientID)
            exams = DemoSummaryRegistry.exams(for: patientID)
            await rxService.load()
            await evoService.load()
        }
    }
    
    @ViewBuilder
    private func sidebarButton(_ tab: SummaryTab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            HStack(spacing: theme.metrics.spacingSM) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18))
                    .frame(width: 24)
                Text(tab.rawValue)
                    .font(theme.typography.body.weight(.medium))
                Spacer()
                if selectedTab == tab {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(selectedTab == tab ? theme.colors.primary.opacity(0.1) : Color.clear)
            .foregroundStyle(selectedTab == tab ? theme.colors.primary : theme.colors.textSecondary)
            .cornerRadius(theme.metrics.radiusMedium)
        }
        .buttonStyle(.plain)
    }
    
    @ViewBuilder
    private func contentView(for tab: SummaryTab) -> some View {
        switch tab {
        case .prescription:
            PrescriptionView(store: rxService.store)
        case .evolution:
            EvolutionView(store: evoService.store)
        case .anamnesis:
            AnamnesisView(entry: anamnesis)
        case .diagnosis:
            DiagnosisView(items: diagnoses)
        case .allergies:
            AllergiesView(items: allergies)
        case .exams:
            ExamsView(items: exams)
        }
    }
}

// MARK: - Anamnesis
struct AnamnesisView: View {
    @Environment(\.emrTheme) private var theme
    let entry: DemoAnamnesisEntry?

    var body: some View {
        ScrollView {
            VStack(spacing: theme.metrics.spacingMD) {
                if let entry {
                    EMRSection("Chief Complaint") {
                        Text(entry.chiefComplaint)
                            .font(theme.typography.body)
                    }
                    EMRSection("History of Present Illness") {
                        Text(entry.presentIllness)
                            .font(theme.typography.body)
                    }
                    EMRSection("Past Medical History") {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(entry.pastHistory, id: \.self) { item in
                                Text("• \(item)")
                                    .font(theme.typography.body)
                            }
                        }
                    }
                    Text("Recorded on \(entry.recordedDate.formatted(date: .abbreviated, time: .shortened))")
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textTertiary)
                } else {
                    EMREmptyStateView(
                        systemImage: "doc.text",
                        title: "No demo anamnesis",
                        message: "Add demo records in DemoSummaryRegistry."
                    )
                }
            }
            .padding(theme.metrics.spacingMD)
        }
        .background(theme.colors.background)
    }
}

// MARK: - Diagnosis
struct DiagnosisView: View {
    @Environment(\.emrTheme) private var theme
    let items: [DemoDiagnosisEntry]

    var body: some View {
        List(items) { dx in
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(dx.description)
                        .font(theme.typography.body.weight(.semibold))
                    Spacer()
                    EMRBadge(dx.code, style: .info)
                }
                HStack(spacing: 8) {
                    EMRBadge(dx.status.rawValue.capitalized, style: dx.status == .active ? .warning : .neutral)
                    Text(dx.recordedDate, style: .date)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }
            .listRowBackground(theme.colors.surface)
        }
        .background(theme.colors.background)
    }
}

// MARK: - Allergies
struct AllergiesView: View {
    @Environment(\.emrTheme) private var theme
    let items: [DemoAllergyEntry]

    var body: some View {
        List(items) { allergy in
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(allergy.allergen)
                        .font(theme.typography.body.weight(.semibold))
                    Text(allergy.reaction)
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                }
                Spacer()
                EMRBadge(allergy.severity.rawValue.capitalized, style: badgeStyle(allergy.severity))
            }
            .listRowBackground(theme.colors.surface)
        }
        .background(theme.colors.background)
    }

    private func badgeStyle(_ severity: DemoAllergyEntry.Severity) -> EMRBadgeStyle {
        switch severity {
        case .mild: return .neutral
        case .moderate: return .warning
        case .severe: return .danger
        }
    }
}

// MARK: - Exams
struct ExamsView: View {
    @Environment(\.emrTheme) private var theme
    let items: [DemoExamEntry]

    var body: some View {
        ScrollView {
            VStack(spacing: theme.metrics.spacingSM) {
                ForEach(items) { exam in
                    TimelineRow(date: exam.requestedDate) {
                        EMRCard {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(exam.name)
                                        .font(theme.typography.body.weight(.semibold))
                                    Spacer()
                                    EMRBadge(exam.status.rawValue.capitalized, style: badgeStyle(exam.status))
                                }
                                Text(exam.details)
                                    .font(theme.typography.caption)
                                    .foregroundStyle(theme.colors.textSecondary)
                                Text(exam.requestedDate, style: .date)
                                    .font(theme.typography.caption)
                                    .foregroundStyle(theme.colors.textTertiary)
                            }
                        }
                    }
                }
            }
            .padding(theme.metrics.spacingMD)
        }
        .background(theme.colors.background)
    }

    private func badgeStyle(_ status: DemoExamEntry.Status) -> EMRBadgeStyle {
        switch status {
        case .pending: return .warning
        case .completed: return .info
        case .reviewed: return .success
        }
    }
}

// MARK: - Timeline helper
private struct TimelineRow<Content: View>: View {
    @Environment(\.emrTheme) private var theme
    let date: Date
    let content: Content

    init(date: Date, @ViewBuilder content: () -> Content) {
        self.date = date
        self.content = content()
    }

    var body: some View {
        HStack(alignment: .top, spacing: theme.metrics.spacingSM) {
            VStack(spacing: 4) {
                Circle()
                    .fill(theme.colors.primary)
                    .frame(width: 10, height: 10)
                Rectangle()
                    .fill(theme.colors.border.opacity(0.6))
                    .frame(width: 2)
                    .frame(maxHeight: .infinity)
            }
            .frame(height: 40, alignment: .top)

            VStack(alignment: .leading, spacing: 4) {
                Text(date, style: .relative)
                    .font(theme.typography.caption)
                    .foregroundStyle(theme.colors.textSecondary)
                content
            }
        }
    }
}

// MARK: - Evolution View
struct EvolutionView: View {
    @Environment(\.emrTheme) private var theme
    @State private var text: String = "Patient reports pain improved after analgesia."
    @State private var alertMessage: String?
    @ObservedObject var store: DemoEvolutionStore
    
    var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.spacingMD) {
            EMRCard {
                VStack(alignment: .leading, spacing: theme.metrics.spacingSM) {
                    Text("New Progress Note")
                        .font(theme.typography.headline)
                    
                    TextEditor(text: $text)
                        .font(theme.typography.body)
                        .padding(theme.metrics.spacingSM)
                        .frame(minHeight: 160)
                        .background(theme.colors.background)
                        .cornerRadius(theme.metrics.radiusSmall)
                        .overlay(
                            RoundedRectangle(cornerRadius: theme.metrics.radiusSmall)
                                .stroke(theme.colors.border, lineWidth: 1)
                        )
                    
                    HStack {
                        Spacer()
                        Button("Save draft") {
                            alertMessage = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Enter text" : "Demo: draft saved"
                        }
                        .buttonStyle(EMRSecondaryButtonStyle())
                        Button("Sign") {
                            let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                            if trimmed.isEmpty {
                                alertMessage = "Text required to sign"
                            } else {
                                store.sign(text: trimmed)
                                alertMessage = "Demo: note signed"
                                text = ""
                            }
                        }
                        .buttonStyle(EMRPrimaryButtonStyle())
                    }
                }
            }

            EMRSection("Previous notes") {
                VStack(spacing: theme.metrics.spacingSM) {
                    ForEach(store.notes) { note in
                        TimelineRow(date: note.date) {
                            EMRCard {
                                HStack(alignment: .top, spacing: theme.metrics.spacingSM) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(note.author) · \(note.role)")
                                            .font(theme.typography.callout.weight(.semibold))
                                        Text(note.text)
                                            .font(theme.typography.body)
                                            .foregroundStyle(theme.colors.textSecondary)
                                            .fixedSize(horizontal: false, vertical: true)
                                        if let details = note.details {
                                            VStack(alignment: .leading, spacing: 2) {
                                                ForEach(details, id: \.self) { line in
                                                    Text("• \(line)")
                                                        .font(theme.typography.caption)
                                                        .foregroundStyle(theme.colors.textTertiary)
                                                }
                                            }
                                        }
                                    }
                                    Spacer()
                                    Text(note.date, style: .relative)
                                        .font(theme.typography.caption)
                                        .foregroundStyle(theme.colors.textTertiary)
                                }
                            }
                        }
                    }
                    if !store.audit.isEmpty {
                        EMRSection("Audit") {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(store.audit) { entry in
                                    Text("\(entry.date, style: .relative) · \(entry.action)")
                                        .font(theme.typography.caption)
                                        .foregroundStyle(theme.colors.textSecondary)
                                }
                            }
                        }
                    }
                    if !store.audit.isEmpty {
                        EMRSection("Audit") {
                            VStack(alignment: .leading, spacing: 4) {
                                ForEach(store.audit) { entry in
                                    HStack(spacing: 8) {
                                        EMRBadge(entry.action, style: .neutral, icon: "clock.arrow.circlepath")
                                        Text(entry.date, style: .relative)
                                            .font(theme.typography.caption)
                                            .foregroundStyle(theme.colors.textSecondary)
                                        Text(entry.text)
                                            .font(theme.typography.caption)
                                            .foregroundStyle(theme.colors.textTertiary)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(theme.metrics.spacingMD)
        .background(theme.colors.background)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Demo action", isPresented: Binding(get: { alertMessage != nil }, set: { _ in alertMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }
}

private extension Encounter {
    var classCodeDisplay: String {
        switch classCode {
        case .inpatient: return "Inpatient"
        case .outpatient: return "Outpatient"
        case .emergency: return "Emergency"
        case .homeHealth: return "Home Health"
        case .virtual: return "Virtual"
        case .unknown: return "Unknown"
        }
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

private extension Observation {
    var effectiveDisplay: String {
        if let effective = effectiveDate {
            return DateFormatter.localizedString(from: effective, dateStyle: .medium, timeStyle: .short)
        }
        return ""
    }
}

private extension Encounter {
    var startDisplay: String {
        guard let start else { return "" }
        return DateFormatter.localizedString(from: start, dateStyle: .medium, timeStyle: .short)
    }
}

#if DEBUG
#Preview("Patient summary demo - cardio") {
    let env = DemoComposition.make()
    PatientSummaryView(patientID: PatientID("demo-001"), viewModel: env.summaryViewModelFactory())
        .frame(width: 1280, height: 720)
        .emrTheme(.default)
}

#Preview("Patient summary demo - sepsis") {
    let env = DemoComposition.make()
    PatientSummaryView(patientID: PatientID("demo-012"), viewModel: env.summaryViewModelFactory())
        .frame(width: 1280, height: 720)
        .emrTheme(.default)
}
#endif
