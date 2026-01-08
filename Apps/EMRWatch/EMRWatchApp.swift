import SwiftUI
import SharedPresentation
import AppSharedUI

@main
struct EMRWatchApp: App {
    private let environment = AppEnvironmentFactory.makeDefault()

    var body: some Scene {
        WindowGroup {
            WatchPatientListView(viewModel: environment.patientListViewModel)
        }
    }
}

private struct WatchPatientListView: View {
    @StateObject var viewModel: PatientListViewModel

    var body: some View {
        List(viewModel.patients) { patient in
            VStack(alignment: .leading) {
                Text(patient.displayName)
                    .font(.headline)
                if let mrn = patient.mrn {
                    Text(mrn)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .onAppear { viewModel.load() }
    }
}
