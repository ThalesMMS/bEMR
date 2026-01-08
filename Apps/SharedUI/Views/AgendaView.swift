import SwiftUI
import CoreDomain

public struct AgendaItem: Identifiable, Hashable {
    public let id = UUID()
    public let time: String
    public let patientName: String
    public let reason: String
    public let location: String
    public let patientID: PatientID?
    public let status: Status

    public enum Status: String, Hashable {
        case scheduled, inProgress, completed, missed

        var badgeStyle: EMRBadgeStyle {
            switch self {
            case .scheduled: return .info
            case .inProgress: return .warning
            case .completed: return .success
            case .missed: return .danger
            }
        }
    }

    // Public memberwise initializer so app targets can create agenda rows
    public init(
        time: String,
        patientName: String,
        reason: String,
        location: String,
        patientID: PatientID? = nil,
        status: Status = .scheduled
    ) {
        self.time = time
        self.patientName = patientName
        self.reason = reason
        self.location = location
        self.patientID = patientID
        self.status = status
    }
}

public struct AgendaView: View {
    @Environment(\.emrTheme) private var theme
    private let items: [AgendaItem]
    @State private var selectedStatus: AgendaItem.Status? = nil
    private let onSelect: (AgendaItem) -> Void

    public init(items: [AgendaItem], onSelect: @escaping (AgendaItem) -> Void) {
        self.items = items
        self.onSelect = onSelect
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.metrics.spacingMD) {
                Text("Today's Schedule")
                    .font(theme.typography.title2)
                    .foregroundStyle(theme.colors.textPrimary)
                    .padding(.horizontal, theme.metrics.spacingMD)
                    .padding(.top, theme.metrics.spacingMD)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: theme.metrics.spacingSM) {
                        statusChip(title: "All", status: nil)
                        ForEach([AgendaItem.Status.scheduled, .inProgress, .completed, .missed], id: \.self) { status in
                            statusChip(title: statusLabel(status), status: status)
                        }
                    }
                    .padding(.horizontal, theme.metrics.spacingMD)
                }
                
                if filtered.isEmpty {
                    EMREmptyStateView(
                        systemImage: "calendar.badge.clock",
                        title: "No appointments",
                        message: "Your schedule is clear today."
                    )
                    .padding(.top, theme.metrics.spacingLG)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 300), spacing: theme.metrics.spacingMD)], spacing: theme.metrics.spacingMD) {
                        ForEach(filtered) { item in
                            Button {
                                onSelect(item)
                            } label: {
                                agendaCard(item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, theme.metrics.spacingMD)
                }
            }
            .padding(.bottom, theme.metrics.spacingXL)
        }
        .background(theme.colors.background)
        .navigationTitle("Schedule")
    }

    private func agendaCard(_ item: AgendaItem) -> some View {
        VStack(alignment: .leading, spacing: theme.metrics.spacingSM) {
            HStack {
                Text(item.time)
                    .font(theme.typography.title3)
                    .foregroundStyle(theme.colors.primary)
                Spacer()
                EMRBadge(item.location, style: .info, icon: "mappin.circle")
                EMRBadge(item.status.rawValue.capitalized, style: item.status.badgeStyle)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.patientName)
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.colors.textPrimary)
                    .lineLimit(1)
                
                Text(item.reason)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textSecondary)
                    .lineLimit(2)
            }
            
            Spacer(minLength: 0)
            
            HStack {
                Spacer()
                Text("View Details")
                    .font(theme.typography.caption.weight(.semibold))
                    .foregroundStyle(theme.colors.primary)
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(theme.colors.primary)
            }
        }
        .padding(theme.metrics.spacingMD)
        .background(theme.colors.surface)
        .cornerRadius(theme.metrics.radiusMedium)
        .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
        .overlay(
            RoundedRectangle(cornerRadius: theme.metrics.radiusMedium)
                .stroke(theme.colors.border.opacity(0.5), lineWidth: 1)
        )
        .frame(height: 160)
    }

    private func statusChip(title: String, status: AgendaItem.Status?) -> some View {
        let isActive = selectedStatus == status
        return Button {
            selectedStatus = status
        } label: {
            HStack(spacing: 6) {
                Text(title)
                if let status {
                    EMRBadge(statusLabel(status), style: status.badgeStyle)
                }
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
        }
        .buttonStyle(.plain)
    }

    private var filtered: [AgendaItem] {
        guard let selectedStatus else { return items }
        return items.filter { $0.status == selectedStatus }
    }

    private func statusLabel(_ status: AgendaItem.Status) -> String {
        switch status {
        case .scheduled: return "Scheduled"
        case .inProgress: return "In progress"
        case .completed: return "Completed"
        case .missed: return "Missed"
        }
    }
}
