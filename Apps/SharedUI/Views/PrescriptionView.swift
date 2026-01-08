import SwiftUI
import CoreDomain
import SharedPresentation

public struct PrescriptionView: View {
    @Environment(\.emrTheme) private var theme
    
    @ObservedObject private var store: DemoPrescriptionStore
    @State private var searchText = ""
    @State private var alertMessage: String?
    @State private var errorMessage: String?
    @State private var editingItem: (sectionID: UUID, item: Item)? = nil
    @State private var draftDescription: String = ""
    @State private var draftQuantity: String = "1"
    @State private var draftFrequency: String = "q8h"
    @State private var draftRoute: String = "PO"
    @State private var draftDuration: String = "3d"
    
    public init(store: DemoPrescriptionStore) {
        self.store = store
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Search / Add Bar
            HStack(spacing: theme.metrics.spacingMD) {
                Text("Medication Orders")
                    .font(theme.typography.title3)
                    .foregroundStyle(theme.colors.primary)
                
                Spacer()
                
                HStack(spacing: theme.metrics.spacingSM) {
                    EMRInput("Add Item", text: $searchText, prompt: "Search medication, diet...")
                        .frame(width: 300)
                    
                    Button {
                        store.addMedicationPlaceholder()
                        alertMessage = "Demo: item added"
                    } label: {
                        Image(systemName: "plus")
                    }
                    .buttonStyle(EMRPrimaryButtonStyle())
                    .padding(.top, 24)
                }
            }
            .padding(theme.metrics.spacingMD)
            .background(theme.colors.surface)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundStyle(theme.colors.border),
                alignment: .bottom
            )
            
            // Grid Header
            HStack(spacing: 0) {
                headerCell("Description", width: nil)
                Divider()
                headerCell("Qty", width: 60)
                Divider()
                headerCell("Route", width: 80)
                Divider()
                headerCell("Freq", width: 80)
                Divider()
                headerCell("Actions", width: 80)
            }
            .frame(height: 40)
            .background(theme.colors.surfaceSecondary)
            .overlay(
                Rectangle()
                    .stroke(theme.colors.border, lineWidth: 1)
            )
            
            // List
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(store.sections) { section in
                        PrescriptionSectionView(
                            section: section,
                            onRemove: { itemID in store.remove(itemID: itemID, in: section.id) },
                            onToggle: { store.toggleSection(section.id) },
                            onEdit: { item in startEditing(sectionID: section.id, item: item) }
                        )
                    }
                }
                .padding(.bottom, theme.metrics.spacingLG)

                if !store.history.isEmpty {
                    EMRSection("Prescription history") {
                        VStack(alignment: .leading, spacing: theme.metrics.spacingSM) {
                            ForEach(store.history) { snap in
                                TimelineRow(date: snap.date) {
                                    EMRCard {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(snap.summary)
                                                    .font(theme.typography.body)
                                                Text("Meds: \(snap.medicationCount)  ·  Solutions: \(snap.solutionCount)")
                                                    .font(theme.typography.caption)
                                                    .foregroundStyle(theme.colors.textSecondary)
                                                if !snap.items.isEmpty {
                                                    VStack(alignment: .leading, spacing: 2) {
                                                        ForEach(snap.items, id: \.id) { item in
                                                            Text("• \(item.type) \(item.description) \(item.frequency) \(item.route)")
                                                                .font(theme.typography.caption)
                                                                .foregroundStyle(theme.colors.textTertiary)
                                                        }
                                                    }
                                                }
                                            }
                                            Spacer()
                                        }
                                    }
                                }
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
                                    Text(entry.itemDescription)
                                        .font(theme.typography.caption)
                                        .foregroundStyle(theme.colors.textTertiary)
                                }
                            }
                        }
                    }
                }
            }
            .background(theme.colors.background)
        }
        .alert("Demo action", isPresented: Binding(get: { alertMessage != nil }, set: { _ in alertMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
        .alert("Error", isPresented: Binding(get: { errorMessage != nil }, set: { _ in errorMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage ?? "")
        }
        .sheet(item: Binding(
            get: { editingItem.map { EditDraft(sectionID: $0.sectionID, itemID: $0.item.id) } },
            set: { _ in editingItem = nil }
        )) { _ in
            editSheet
        }
    }
    
private func headerCell(_ text: String, width: CGFloat?) -> some View {
        Text(text)
            .font(theme.typography.caption.weight(.semibold))
            .foregroundStyle(theme.colors.textSecondary)
            .padding(.horizontal, theme.metrics.spacingMD)
            .frame(width: width, alignment: .leading)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }
    
private func cell<Content: View>(width: CGFloat?, @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, theme.metrics.spacingMD)
            .frame(width: width, alignment: .leading)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }
}

// Helper for UnboundedRange type inference
private typealias UnboundedRange_ = UnboundedRange
typealias Section = DemoPrescriptionStore.Section
typealias Item = DemoPrescriptionStore.Item

struct PrescriptionSectionView: View {
    @Environment(\.emrTheme) private var theme
    let section: Section
    let onRemove: (UUID) -> Void
    let onToggle: () -> Void
    let onEdit: (Item) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // Section Header
            Button {
                withAnimation { onToggle() }
            } label: {
                HStack {
                    Image(systemName: section.isExpanded ? "chevron.down" : "chevron.right")
                        .foregroundStyle(theme.colors.textSecondary)
                        .frame(width: 20)
                    
                    Text(section.title)
                        .font(theme.typography.headline)
                        .foregroundStyle(theme.colors.textPrimary)
                    
                    Spacer()
                    
                    if !section.items.isEmpty {
                        Text("\(section.items.count) items")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }
                .padding(.vertical, theme.metrics.spacingSM)
                .padding(.horizontal, theme.metrics.spacingMD)
                .background(theme.colors.surfaceSecondary.opacity(0.5))
            }
            .buttonStyle(.plain)
            
            Divider()
            
            // Items
            if section.isExpanded {
                if section.items.isEmpty {
                    Text("Tap to add \(section.title.lowercased())")
                        .font(theme.typography.body)
                        .foregroundStyle(theme.colors.textTertiary)
                        .padding(theme.metrics.spacingMD)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(theme.colors.surface)
                        .overlay(
                            Rectangle()
                                .frame(height: 1)
                                .foregroundStyle(theme.colors.border.opacity(0.5)),
                            alignment: .bottom
                        )
                } else {
                    ForEach(section.items) { item in
                        PrescriptionItemRow(item: item) {
                            onRemove(item.id)
                        } onEdit: {
                            onEdit(item)
                        }
                    }
                }
            }
        }
    }
}

struct PrescriptionItemRow: View {
    @Environment(\.emrTheme) private var theme
    let item: Item
    let onDelete: () -> Void
    let onEdit: () -> Void
    @State private var alertMessage: String?

    var body: some View {
        HStack(spacing: 0) {
            cell(width: nil) {
                VStack(alignment: .leading) {
                    Text(item.description)
                        .font(theme.typography.body.weight(.medium))
                        .foregroundStyle(theme.colors.textPrimary)
                    if !item.duration.isEmpty {
                        Text("Duration: \(item.duration)")
                            .font(theme.typography.caption)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }
            }
            Divider()
            
            cell(width: 60) {
                Text(item.quantity)
                    .font(theme.typography.body)
            }
            Divider()
            
            cell(width: 80) {
                Text(item.route)
                    .font(theme.typography.body)
            }
            Divider()
            
            cell(width: 80) {
                Text(item.frequency)
                    .font(theme.typography.body)
            }
            Divider()
            
            cell(width: 80) {
                HStack(spacing: 16) {
                    Button(action: onEdit) {
                        Image(systemName: "pencil")
                            .foregroundStyle(theme.colors.primary)
                    }
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .foregroundStyle(theme.colors.danger)
                    }
                }
            }
        }
        .frame(minHeight: 44)
        .background(theme.colors.surface)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundStyle(theme.colors.border.opacity(0.5)),
            alignment: .bottom
        )
        .alert("Demo action", isPresented: Binding(get: { alertMessage != nil }, set: { _ in alertMessage = nil })) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage ?? "")
        }
    }

    private func cell<Content: View>(width: CGFloat?, @ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(.horizontal, theme.metrics.spacingMD)
            .frame(width: width, alignment: .leading)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }

    private func alertDemo(_ message: String) {
        alertMessage = message
    }
}

private struct EditDraft: Identifiable { let id = UUID(); let sectionID: UUID; let itemID: UUID }

private extension PrescriptionView {
    private func startEditing(sectionID: UUID, item: Item) {
        editingItem = (sectionID, item)
        draftDescription = item.description
        draftQuantity = item.quantity
        draftFrequency = item.frequency
        draftRoute = item.route
        draftDuration = item.duration
    }

    private var editSheet: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: theme.metrics.spacingMD) {
                EMRSection("Medication") {
                    VStack(alignment: .leading, spacing: theme.metrics.spacingSM) {
                        TextField("Description", text: $draftDescription)
                        TextField("Quantity", text: $draftQuantity)
                        TextField("Frequency", text: $draftFrequency)
                        TextField("Route", text: $draftRoute)
                        TextField("Duration", text: $draftDuration)
                    }
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Edit item")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { editingItem = nil }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        guard let ctx = editingItem else { return }
                        let desc = draftDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                        let qty = draftQuantity.trimmingCharacters(in: .whitespacesAndNewlines)
                        let freq = draftFrequency.trimmingCharacters(in: .whitespacesAndNewlines)
                        let route = draftRoute.trimmingCharacters(in: .whitespacesAndNewlines)
                        let dur = draftDuration.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !desc.isEmpty, !qty.isEmpty, !freq.isEmpty, !route.isEmpty else {
                            errorMessage = "Fill description, quantity, frequency, and route."
                            return
                        }
                        store.update(
                            itemID: ctx.item.id,
                            in: ctx.sectionID,
                            description: desc,
                            quantity: qty,
                            frequency: freq,
                            route: route,
                            duration: dur
                        )
                        alertMessage = "Item updated"
                        editingItem = nil
                    }
                    .disabled(draftDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// MARK: - Timeline helper (local to prescription view)
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
