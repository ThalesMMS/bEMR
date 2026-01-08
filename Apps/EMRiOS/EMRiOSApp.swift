import SwiftUI
import CoreDomain
import SharedPresentation
import AppSharedUI

@main
struct EMRiOSApp: App {
    private let environment = AppEnvironmentFactory.makeDefault()

    var body: some Scene {
        WindowGroup {
            IOSRootView(environment: environment)
        }
    }
}

private struct IOSRootView: View {
    private enum Tab { case agenda, patients, tasks }

    @State private var selectedTab: Tab = .agenda
    @State private var agendaPath: [PatientDestination] = []
    @State private var patientPath: [PatientDestination] = []
    private let environment: AppEnvironment

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $agendaPath) {
                AgendaView(items: demoItems) { item in
                    guard let id = item.patientID else { return }
                    agendaPath = [.patient(id)]
                    selectedTab = .patients
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
            .tabItem { Label("Schedule", systemImage: "calendar") }
            .tag(Tab.agenda)

            NavigationStack(path: $patientPath) {
                PatientListView(
                    viewModel: environment.patientListViewModel,
                    navigationPath: $patientPath,
                    summaryFactory: { id in
                        PatientSummaryView(
                            patientID: id,
                            viewModel: environment.summaryViewModelFactory()
                        )
                    }
                )
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
            .tabItem { Label("Patients", systemImage: "person.2") }
            .tag(Tab.patients)

            NavigationStack { Text("Tasks coming soon") }
                .tabItem { Label("Tasks", systemImage: "checklist") }
                .tag(Tab.tasks)
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
