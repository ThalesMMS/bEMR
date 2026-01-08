import SwiftUI
import Combine
import CoreDomain
import SharedPresentation
import AppSharedUI
import AppKit

@main
@MainActor
struct EMRMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let environment = AppEnvironmentFactory.makeDefault()

    var body: some Scene {
        WindowGroup {
            MacRootView(environment: environment)
                .frame(minWidth: 1000, minHeight: 700)
                .onAppear {
                    maximizeToVisibleScreen()
                }
        }
    }
    
    private func maximizeToVisibleScreen() {
        guard let screen = NSScreen.main else { return }
        // Expand the main window to fill the visible frame (respecting menu bar/dock).
        DispatchQueue.main.async {
            NSApplication.shared.windows
                .first(where: { $0.isKeyWindow })?
                .setFrame(screen.visibleFrame, display: true, animate: true)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Ensure the initial window starts maximized even if created slightly after launch.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let screen = NSScreen.main {
                NSApplication.shared.windows
                    .first(where: { $0.isKeyWindow })?
                    .setFrame(screen.visibleFrame, display: true, animate: true)
            }
        }
    }
}

@MainActor
private struct MacRootView: View {
    fileprivate enum SidebarItem: Hashable, CaseIterable {
        case summary, medicalCare, exams, hospitalization, opinion, nursing, discharge, records
    }

    fileprivate enum ServiceMode: String, CaseIterable, Identifiable {
        case demo, mockLive
        var id: String { rawValue }
        var label: String { rawValue == "demo" ? "Demo" : "Mock Live" }
    }

    @State private var selection: SidebarItem = .medicalCare
    @State private var serviceMode: ServiceMode = .demo
    @State private var navigationPath: [PatientDestination] = []
    @StateObject private var patientList: PatientListViewModel
    @State private var selectedPatientID: PatientID?
    @StateObject private var agendaService: AgendaServiceBox
    @StateObject private var chartReviewService: ChartReviewServiceBox
    @State private var didResizeWindow = false
    private let environment: AppEnvironment

    init(environment: AppEnvironment, agendaService: (any AgendaService)? = nil) {
        _patientList = StateObject(wrappedValue: environment.patientListViewModel)
        let agendaBase = agendaService ?? DemoAgendaService()
        _agendaService = StateObject(wrappedValue: AgendaServiceBox(agendaBase))
        _chartReviewService = StateObject(wrappedValue: ChartReviewServiceBox(DemoChartReviewService()))
        self.environment = environment
        if let saved = UserDefaults.standard.string(forKey: "emrmac.serviceMode"), let mode = ServiceMode(rawValue: saved) {
            _serviceMode = State(initialValue: mode)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Top Toolbar
            TopToolbarView(selection: $selection, serviceMode: $serviceMode)
            
            // Main Content
            NavigationStack(path: $navigationPath) {
                switch selection {
                case .summary:
                    AgendaSplitView(items: agendaService.items, onSelect: { _ in })
                        .onReceive(timer) { _ in agendaService.advanceStatuses() }
                case .medicalCare:
                    PatientListView(
                        viewModel: patientList,
                        navigationPath: $navigationPath,
                        summaryFactory: { id in
                            PatientSummaryView(
                                patientID: id,
                                viewModel: environment.summaryViewModelFactory(),
                                prescriptionService: prescriptionService(for: id),
                                evolutionService: evolutionService(for: id)
                            )
                        }
                    )
                    .onAppear { patientList.load() }
                case .hospitalization:
                    HospitalizationRequestDemoView()
                case .opinion:
                    OpinionDemoView()
                case .nursing:
                    NursingRecordsDemoView()
                case .discharge:
                    DischargeDemoView()
                case .records:
                    ChartReviewDemoView(service: chartReviewService)
                default:
                    EMREmptyStateView(
                        systemImage: "hammer",
                        title: "Em Construção",
                        message: "Esta funcionalidade estará disponível em breve."
                    )
                }
            }
            .navigationDestination(for: PatientDestination.self) { destination in
                switch destination {
                case .patient(let id):
                    PatientSummaryView(
                        patientID: id,
                        viewModel: environment.summaryViewModelFactory(),
                        prescriptionService: prescriptionService(for: id),
                        evolutionService: evolutionService(for: id)
                    )
                }
            }
        }
        .onChange(of: serviceMode) { newMode in
            persistServiceMode(newMode)
            applyServiceMode(newMode)
        }
        .task {
            applyServiceMode(serviceMode)
        }
        .emrTheme(.adaptive)
        .background(
            WindowAccessor(onResolve: { window in
                guard !didResizeWindow, let window else { return }
                if let screen = window.screen ?? NSScreen.main {
                    window.setFrame(screen.visibleFrame, display: true, animate: true)
                    didResizeWindow = true
                }
            })
        )
    }
    private var timer: Publishers.Autoconnect<Timer.TimerPublisher> { Timer.publish(every: 15, on: .main, in: .common).autoconnect() }

    private func applyServiceMode(_ mode: ServiceMode) {
        switch mode {
        case .demo:
            agendaService.updateBase(DemoAgendaService())
            chartReviewService.updateBase(DemoChartReviewService())
        case .mockLive:
            agendaService.updateBase(MockLiveAgendaService())
            chartReviewService.updateBase(MockLiveChartReviewService())
        }
    }

    private func persistServiceMode(_ mode: ServiceMode) {
        UserDefaults.standard.set(mode.rawValue, forKey: "emrmac.serviceMode")
    }

    private func prescriptionService(for patientID: PatientID) -> any PrescriptionService {
        switch serviceMode {
        case .demo:
            return DemoPrescriptionService(patientID: patientID)
        case .mockLive:
            return MockLivePrescriptionService(patientID: patientID)
        }
    }

    private func evolutionService(for patientID: PatientID) -> any EvolutionService {
        switch serviceMode {
        case .demo:
            return DemoEvolutionService(patientID: patientID)
        case .mockLive:
            return MockLiveEvolutionService(patientID: patientID)
        }
    }
}

private struct TopToolbarView: View {
    @Binding var selection: MacRootView.SidebarItem
    @Binding var serviceMode: MacRootView.ServiceMode
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
                    ForEach(MacRootView.SidebarItem.allCases, id: \.self) { item in
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
            
            Spacer()
            
            // Service Mode Picker
            Picker("Source", selection: $serviceMode) {
                ForEach(MacRootView.ServiceMode.allCases) { mode in
                    Text(mode.label).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .frame(width: 200)
            .padding(.trailing, theme.metrics.spacingMD)
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

private extension MacRootView.SidebarItem {
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

// Helper to access the underlying NSWindow from SwiftUI hierarchy.
private struct WindowAccessor: NSViewRepresentable {
    var onResolve: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { onResolve(view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { onResolve(nsView.window) }
    }
}
