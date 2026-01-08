import SwiftUI
import SharedPresentation
import CoreDomain

public enum PatientDestination: Hashable {
    case patient(PatientID)
}

public struct PatientListView: View {
    @Environment(\.emrTheme) private var theme
    @StateObject private var viewModel: PatientListViewModel
    @State private var searchText: String = ""
    @State private var selectedFilter: PatientStatus? = nil
    private enum QuickFilter: Hashable { case all, withRx, withoutRx, urgent, alerts }
    @State private var quickFilter: QuickFilter = .all
    @State private var hasAppeared = false

    private let summaryFactory: (PatientID) -> PatientSummaryView
    private let navigationPath: Binding<[PatientDestination]>?
    private let onSelect: ((PatientID) -> Void)?

    public init(
        viewModel: PatientListViewModel,
        navigationPath: Binding<[PatientDestination]>? = nil,
        onSelect: ((PatientID) -> Void)? = nil,
        summaryFactory: @escaping (PatientID) -> PatientSummaryView
    ) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.navigationPath = navigationPath
        self.onSelect = onSelect
        self.summaryFactory = summaryFactory
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header / Filters
            VStack(spacing: 0) {
                HStack(spacing: theme.metrics.spacingMD) {
                    Text("Patient List")
                        .font(theme.typography.title3)
                        .foregroundStyle(theme.colors.primary)
                    
                    HStack(spacing: theme.metrics.spacingSM) {
                        EMRBadge("\(totalCount) encounters", style: .neutral)
                        EMRBadge("\(withPrescriptionCount) with prescriptions", style: .info)
                        EMRBadge("\(withoutPrescriptionCount) without prescriptions", style: .warning)
                        EMRBadge("\(withDischargeCount) discharge orders", style: .success)
                    }

                    Spacer()

                    EMRInput("Search", text: $searchText, prompt: "Name, MRN...")
                        .frame(maxWidth: 300)
                }
                .padding(theme.metrics.spacingMD)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: theme.metrics.spacingSM) {
                        ForEach(quickFilters, id: \.filter) { item in
                            quickFilterChip(title: item.title, count: item.count, systemImage: item.icon, filter: item.filter)
                        }
                    }
                    .padding(.horizontal, theme.metrics.spacingMD)
                    .padding(.bottom, theme.metrics.spacingSM)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: theme.metrics.spacingSM) {
                        filterButton("All", status: nil)
                        ForEach(PatientStatus.allCases, id: \.self) { status in
                            filterButton(status.rawValue, status: status)
                        }
                    }
                    .padding(.horizontal, theme.metrics.spacingMD)
                    .padding(.bottom, theme.metrics.spacingMD)
                }
            }
            .background(theme.colors.surface)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(theme.colors.border),
                alignment: .bottom
            )

            // Table + List wrapped in horizontal scroll to avoid squishing text on iPad
            ScrollView(.horizontal, showsIndicators: true) {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        headerCell("Pri", width: 40)
                        Divider()
                        headerCell("Time", width: 70)
                        Divider()
                        headerCell("Patient", width: 220)
                        Divider()
                        headerCell("Age", width: 70)
                        Divider()
                        headerCell("Unit/Bed", width: 180)
                        Divider()
                        headerCell("Procedure", width: 200)
                        Divider()
                        headerCell("Diagnosis", width: 220)
                        Divider()
                        headerCell("Days", width: 70)
                        Divider()
                        headerCell("Rx/Discharge", width: 140)
                        Divider()
                        headerCell("Status", width: 140)
                    }
                    .frame(height: 38)
                    .background(theme.colors.surfaceSecondary)
                    .overlay(
                        Rectangle()
                            .stroke(theme.colors.border.opacity(0.7), lineWidth: 1)
                    )

                    ScrollView {
                        LazyVStack(spacing: 0) {
                            if viewModel.patients.isEmpty && !viewModel.isLoading && viewModel.errorMessage == nil {
                                EMREmptyStateView(
                                    systemImage: "person.crop.rectangle.badge.plus",
                                    title: "No patients",
                                    message: searchText.isEmpty ? "Add patients to see them here." : "No patients found."
                                )
                                .padding(.top, theme.metrics.spacingLG)
                            }

                            ForEach(filteredPatients) { row in
                                rowContent(row)
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                    .background(theme.colors.background)
                }
            }
        }
        .navigationTitle("Medical Care")
        .task {
            guard !hasAppeared else { return }
            hasAppeared = true
            viewModel.load()
        }
        .overlay {
            if viewModel.isLoading {
                EMRLoadingOverlay(message: "Loading patients...")
            }
        }
        .alert("Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    @ViewBuilder
    private func filterButton(_ title: String, status: PatientStatus?) -> some View {
        Button {
            selectedFilter = status
        } label: {
            Text(title)
                .font(theme.typography.callout)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(selectedFilter == status ? theme.colors.primary.opacity(0.1) : Color.clear)
                .foregroundStyle(selectedFilter == status ? theme.colors.primary : theme.colors.textSecondary)
                .cornerRadius(theme.metrics.radiusSmall)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.metrics.radiusSmall)
                        .stroke(selectedFilter == status ? theme.colors.primary : theme.colors.border, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func rowContent(_ row: PatientRowViewModel) -> some View {
        if navigationPath != nil {
            NavigationLink(destination: summaryFactory(row.id)) {
                patientRow(row)
            }
        } else if let onSelect {
            Button { onSelect(row.id) } label: {
                patientRow(row)
            }
        } else {
            NavigationLink(destination: summaryFactory(row.id)) {
                patientRow(row)
            }
        }
    }

    private func patientRow(_ row: PatientRowViewModel) -> some View {
        HStack(spacing: 0) {
            // Priority
            cell(width: 40) {
                Circle()
                    .fill(Color(hex: row.priority.colorHex))
                    .frame(width: 12, height: 12)
            }
            Divider()
            
            // Time
            cell(width: 70) {
                Text(row.receptionTime)
                    .font(theme.typography.body.monospacedDigit())
                    .foregroundStyle(theme.colors.textPrimary)
            }
            Divider()
            
            // Name & MRN
            cell(width: 220) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: theme.metrics.spacingSM) {
                        Text(row.displayName)
                            .font(theme.typography.body.weight(.semibold))
                            .foregroundStyle(theme.colors.textPrimary)
                        if row.hasAlerts {
                            EMRBadge("Alert", style: .warning, icon: "bell.badge")
                        }
                        if row.hasPrescriptionToday {
                            EMRBadge("Rx", style: .info, icon: "pills")
                        }
                    }
                    if let mrn = row.mrn {
                        Text(mrn)
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }
            }
            Divider()
            
            // Age
            cell(width: 70) {
                Text(row.age)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textSecondary)
            }
            Divider()

            // Sector / Bed
            cell(width: 180) {
                let location = [row.sector, row.bed].compactMap { $0 }.joined(separator: " · ")
                Text(location.isEmpty ? "—" : location)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textSecondary)
                    .lineLimit(1)
            }
            Divider()

            // Procedure
            cell(width: 200) {
                Text(row.procedure ?? "—")
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textSecondary)
                    .lineLimit(1)
            }
            Divider()

            // Diagnosis
            cell(width: 220) {
                Text(row.diagnosis ?? "—")
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textSecondary)
                    .lineLimit(1)
            }
            Divider()

            // Days admitted
            cell(width: 70) {
                Text(row.admittedDaysText ?? "—")
                    .font(theme.typography.body.monospacedDigit())
                    .foregroundStyle(theme.colors.textPrimary)
            }
            Divider()

            // Indicators (prescription today / discharge)
            cell(width: 140) {
                HStack(spacing: theme.metrics.spacingSM) {
                    if row.hasPrescriptionToday {
                        Label("Presc", systemImage: "pills")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.primary)
                    }
                    if row.hasDischargeOrder {
                        Label("Discharge", systemImage: "checkmark.seal")
                            .font(theme.typography.caption)
                            .foregroundStyle(Color.green)
                    }
                }
            }
            Divider()

            // Status
            cell(width: 140) {
                EMRBadge(row.status.rawValue, style: statusBadgeStyle(row.status))
            }
        }
        .frame(height: 58)
        .background(rowBackground(row))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(theme.colors.border.opacity(0.25)),
            alignment: .bottom
        )
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color(hex: row.priority.colorHex))
                .frame(width: 4)
        }
    }
    
    private func headerCell(_ text: String, width: CGFloat?) -> some View {
        Text(text)
            .font(theme.typography.caption.weight(.semibold))
            .foregroundStyle(theme.colors.textSecondary)
            .padding(.horizontal, theme.metrics.spacingSM)
            .frame(width: width, alignment: .leading)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }

    private func cell<Content: View>(width: CGFloat?, @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, theme.metrics.spacingSM)
            .frame(width: width, alignment: .leading)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }
    
    private func statusBadgeStyle(_ status: PatientStatus) -> EMRBadgeStyle {
        switch status {
        case .waiting: return .warning
        case .inAttendance: return .info
        case .attended: return .success
        case .discharged: return .neutral
        }
    }

    private var filteredPatients: [PatientRowViewModel] {
        var result = viewModel.patients

        switch quickFilter {
        case .all: break
        case .withRx: result = result.filter { $0.hasPrescriptionToday }
        case .withoutRx: result = result.filter { !$0.hasPrescriptionToday }
        case .urgent: result = result.filter { $0.needsAttention }
        case .alerts: result = result.filter { $0.hasAlerts }
        }

        if let selectedFilter {
            result = result.filter { $0.status == selectedFilter }
        }
        
        if !searchText.isEmpty {
            result = result.filter { $0.displayName.lowercased().contains(searchText.lowercased()) }
        }
        
        return result
    }

    private var quickFilters: [(filter: QuickFilter, title: String, count: Int, icon: String)] {
        [
            (.all, "All", totalCount, "rectangle.stack"),
            (.withRx, "With prescriptions", withPrescriptionCount, "pills"),
            (.withoutRx, "Without prescriptions", withoutPrescriptionCount, "pills"),
            (.urgent, "Urgent", urgentCount, "exclamationmark.triangle"),
            (.alerts, "Alerts", alertsCount, "bell.badge")
        ]
    }

    @ViewBuilder
    private func quickFilterChip(title: String, count: Int, systemImage: String, filter: QuickFilter) -> some View {
        let isActive = quickFilter == filter
        HStack(spacing: 6) {
            Image(systemName: systemImage)
            Text(title)
            EMRBadge("\(count)", style: .neutral)
        }
        .font(theme.typography.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(isActive ? theme.colors.primary.opacity(0.12) : theme.colors.surface)
        .foregroundStyle(isActive ? theme.colors.primary : theme.colors.textSecondary)
        .cornerRadius(theme.metrics.radiusMedium)
        .overlay(
            RoundedRectangle(cornerRadius: theme.metrics.radiusMedium)
                .stroke(isActive ? theme.colors.primary : theme.colors.border.opacity(0.7), lineWidth: 1)
        )
        .onTapGesture { quickFilter = filter }
    }

    private func rowBackground(_ row: PatientRowViewModel) -> Color {
        if row.priority == .emergency { return Color(hex: row.priority.colorHex).opacity(0.10) }
        if row.priority == .urgent { return Color(hex: row.priority.colorHex).opacity(0.08) }
        switch row.status {
        case .waiting: return theme.colors.surface
        case .inAttendance: return theme.colors.surfaceSecondary.opacity(0.4)
        case .attended: return theme.colors.surfaceSecondary.opacity(0.25)
        case .discharged: return theme.colors.surface
        }
    }

    private var totalCount: Int { viewModel.patients.count }
    private var withPrescriptionCount: Int { viewModel.patients.filter { $0.hasPrescriptionToday }.count }
    private var withoutPrescriptionCount: Int { max(0, totalCount - withPrescriptionCount) }
    private var withDischargeCount: Int { viewModel.patients.filter { $0.hasDischargeOrder }.count }
    private var urgentCount: Int { viewModel.patients.filter { $0.needsAttention }.count }
    private var alertsCount: Int { viewModel.patients.filter { $0.hasAlerts }.count }
}

// Helper for UnboundedRange type inference
private typealias UnboundedRange_ = UnboundedRange

#if DEBUG
#Preview("Patient list demo (macOS)") {
    let env = DemoComposition.make()
    PatientListView(
        viewModel: env.patientListViewModel,
        summaryFactory: { PatientSummaryView(patientID: $0, viewModel: env.summaryViewModelFactory()) }
    )
    .frame(width: 1280, height: 720)
    .emrTheme(.default)
}
#endif
