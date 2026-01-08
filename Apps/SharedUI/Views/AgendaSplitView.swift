import SwiftUI
import CoreDomain

public struct AgendaSplitView: View {
    @Environment(\.emrTheme) private var theme
    private let items: [AgendaItem]
    private let onSelect: (AgendaItem) -> Void
    @State private var selected: AgendaItem?

    public init(items: [AgendaItem], onSelect: @escaping (AgendaItem) -> Void) {
        self.items = items
        self.onSelect = onSelect
        _selected = State(initialValue: items.first)
    }

    public var body: some View {
        HStack(spacing: 0) {
            AgendaView(items: items, onSelect: { item in
                selected = item
                onSelect(item)
            })
            .frame(width: 420)
            .overlay(
                Rectangle()
                    .fill(theme.colors.border.opacity(0.6))
                    .frame(width: 1),
                alignment: .trailing
            )

            if let selected {
                detail(for: selected)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(theme.colors.background)
            } else {
                EMREmptyStateView(
                    systemImage: "calendar.badge.clock",
                    title: "Select a schedule",
                    message: "Choose an item on the left to view details"
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }

    private func detail(for item: AgendaItem) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: theme.metrics.spacingMD) {
                EMRCard {
                    VStack(alignment: .leading, spacing: theme.metrics.spacingSM) {
                        HStack {
                            Text(item.patientName)
                                .font(theme.typography.title3)
                            Spacer()
                    EMRBadge(item.status.rawValue.capitalized, style: item.status.badgeStyle)
                }
                        Text(item.reason)
                            .font(theme.typography.body)
                            .foregroundStyle(theme.colors.textSecondary)
                        HStack(spacing: theme.metrics.spacingSM) {
                            Label(item.time, systemImage: "clock")
                            Label(item.location, systemImage: "mappin.circle")
                        }
                        .font(theme.typography.caption)
                        .foregroundStyle(theme.colors.textSecondary)
                    }
                }

                EMRSection("Next steps") {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Check-in, triage, direct to clinic room")
                        Text("Log a quick progress note after the visit")
                    }
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textSecondary)
                }

                EMRSection("Actions") {
                    HStack(spacing: theme.metrics.spacingSM) {
                        EMRBadge("Live queue demo", style: .info, icon: "clock")
                        Text("Queue refreshes every 15s to simulate movement.")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }

                EMRSection("Patient context") {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ID: \(item.patientID?.rawValue ?? "—")")
                        Text("Status: \(item.status.rawValue.capitalized)")
                    }
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textSecondary)
                }
            }
            .padding(theme.metrics.spacingMD)
        }
    }
}
