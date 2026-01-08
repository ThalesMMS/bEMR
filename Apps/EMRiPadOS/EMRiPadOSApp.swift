import SwiftUI
import SharedPresentation
import CoreDomain
import AppSharedUI

@main
struct EMRiPadOSApp: App {
    private let environment = AppEnvironmentFactory.makeDefault()

    var body: some Scene {
        WindowGroup {
            SplitRootView(environment: environment)
        }
    }
}

struct SplitRootView: View {
    enum NavigationItem: Hashable, CaseIterable {
        case summary, medicalCare, exams, hospitalization, opinion, nursing, discharge, records
        
        var label: String {
            switch self {
            case .summary: return "Intake Summary"
            case .medicalCare: return "Medical Care"
            case .exams: return "Test Results"
            case .hospitalization: return "Admission Request"
            case .opinion: return "Consult"
            case .nursing: return "Nursing Notes"
            case .discharge: return "Discharge"
            case .records: return "Chart Review"
            }
        }
        
        var icon: String {
            switch self {
            case .summary: return "text.book.closed"
            case .medicalCare: return "stethoscope"
            case .exams: return "waveform.path.ecg"
            case .hospitalization: return "bed.double"
            case .opinion: return "doc.text"
            case .nursing: return "cross.case"
            case .discharge: return "figure.walk.departure"
            case .records: return "person.text.rectangle"
            }
        }
    }

    @State private var selection: NavigationItem = .medicalCare
    @State private var path: [PatientDestination] = []
    @StateObject private var patientList: PatientListViewModel
    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        _patientList = StateObject(wrappedValue: environment.patientListViewModel)
        self.environment = environment
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Toolbar
            TopToolbarView(selection: $selection)
            
            // Main Content
            NavigationStack(path: $path) {
                switch selection {
                case .summary:
                    AgendaView(items: demoItems, onSelect: { _ in })
                case .medicalCare:
                    PatientListView(
                        viewModel: patientList,
                        navigationPath: $path,
                        summaryFactory: { id in
                            PatientSummaryView(
                                patientID: id,
                                viewModel: environment.summaryViewModelFactory()
                            )
                        }
                    )
                    .onAppear { patientList.load() }
                default:
                    EMREmptyStateView(
                        systemImage: "hammer",
                        title: "Under Construction",
                        message: "This feature will be available soon."
                    )
                }
            }
            .navigationDestination(for: PatientDestination.self) { destination in
                switch destination {
                case .patient(let id):
                    PatientSummaryView(
                        patientID: id,
                        viewModel: environment.summaryViewModelFactory()
                    )
                }
            }
        }
        .emrTheme(.default)
    }

    private var demoItems: [AgendaItem] {
        [
            .init(time: "08:30", patientName: "Amelia Rogers", reason: "Follow up", location: "Room 1", patientID: PatientID("demo-001")),
            .init(time: "09:15", patientName: "Brian Sanders", reason: "Diabetes check", location: "Room 2", patientID: PatientID("demo-002")),
            .init(time: "10:00", patientName: "Charles Lane", reason: "Cardio consult", location: "Room 3", patientID: PatientID("demo-003")),
            .init(time: "11:30", patientName: "Danielle Parker", reason: "Telehealth review", location: "Telehealth", patientID: PatientID("demo-004")),
            .init(time: "13:00", patientName: "Edward Coleman", reason: "Lab results", location: "Room 4", patientID: PatientID("demo-005")),
            .init(time: "14:30", patientName: "Fiona Allen", reason: "ER follow-up", location: "Room 5", patientID: PatientID("demo-006"))
        ]
    }
}

private struct TopToolbarView: View {
    @Binding var selection: SplitRootView.NavigationItem
    @Environment(\.emrTheme) private var theme
    
    var body: some View {
        HStack(spacing: theme.metrics.spacingMD) {
            // Brand
            HStack(spacing: 8) {
                Image(systemName: "cross.case.fill")
                    .font(.title3)
                    .foregroundStyle(Color(hex: "E36025"))
                Text("bEMR")
                    .font(theme.typography.title3.weight(.bold))
                    .foregroundStyle(theme.colors.textPrimary)
            }
            .padding(.leading, theme.metrics.spacingMD)
            .padding(.trailing, theme.metrics.spacingSM)
            
            Divider()
                .frame(height: 24)
            
            // Navigation Items
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: theme.metrics.spacingXS) {
                    ForEach(SplitRootView.NavigationItem.allCases, id: \.self) { item in
                        Button {
                            selection = item
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: item.icon)
                                Text(item.label)
                            }
                            .font(theme.typography.callout.weight(selection == item ? .semibold : .regular))
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(selection == item ? theme.colors.primary.opacity(0.1) : Color.clear)
                            .foregroundStyle(selection == item ? theme.colors.primary : theme.colors.textSecondary)
                            .cornerRadius(theme.metrics.radiusMedium)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, theme.metrics.spacingSM)
            }
        }
        .background(theme.colors.surface)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(theme.colors.border),
            alignment: .bottom
        )
    }
}
