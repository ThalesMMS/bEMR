import SwiftUI

public struct HospitalizationRequestDemoView: View {
    @Environment(\.emrTheme) private var theme
    @State private var unit: String = "Internal Medicine"
    @State private var justification: String = "Clinical status requires continuous monitoring"
    @State private var priority: String = "Urgent"
    @State private var alertMessage: String?
    @State private var errorMessage: String?
    public init() {}

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.spacingMD) {
            EMRSection("Admission Request") {
                VStack(alignment: .leading, spacing: theme.metrics.spacingSM) {
                    EMRInput("Destination unit", text: $unit)
                    EMRInput("Justification", text: $justification)
                    EMRInput("Priority", text: $priority)
                    Button("Submit request") {
                        let u = unit.trimmingCharacters(in: .whitespacesAndNewlines)
                        let j = justification.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !u.isEmpty, !j.isEmpty else {
                            errorMessage = "Fill destination unit and justification"
                            return
                        }
                        alertMessage = "Request recorded (demo)"
                    }
                    .buttonStyle(EMRPrimaryButtonStyle())
                }
            }
            if let alertMessage {
                EMRBadge(alertMessage, style: .success, icon: "checkmark")
            }
            if let errorMessage {
                EMRBadge(errorMessage, style: .warning, icon: "exclamationmark.triangle")
            }
        }
        .padding(theme.metrics.spacingMD)
        .background(theme.colors.background)
    }
}

public struct OpinionDemoView: View {
    @Environment(\.emrTheme) private var theme
    @State private var specialty: String = "Cardiology"
    @State private var reason: String = "Assess antiplatelet adjustment"
    @State private var alertMessage: String?
    @State private var errorMessage: String?
    public init() {}

    public var body: some View {
        VStack(spacing: theme.metrics.spacingMD) {
            EMRSection("Consult Request") {
                VStack(alignment: .leading, spacing: theme.metrics.spacingSM) {
                    EMRInput("Specialty", text: $specialty)
                    EMRInput("Reason", text: $reason)
                    Button("Request") {
                        let s = specialty.trimmingCharacters(in: .whitespacesAndNewlines)
                        let r = reason.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !s.isEmpty, !r.isEmpty else {
                            errorMessage = "Fill specialty and reason"
                            return
                        }
                        alertMessage = "Consult requested (demo)"
                    }
                    .buttonStyle(EMRPrimaryButtonStyle())
                }
            }
            if let alertMessage { EMRBadge(alertMessage, style: .success, icon: "checkmark") }
            if let errorMessage { EMRBadge(errorMessage, style: .warning, icon: "exclamationmark.triangle") }
        }
        .padding(theme.metrics.spacingMD)
        .background(theme.colors.background)
    }
}

public struct NursingRecordsDemoView: View {
    @Environment(\.emrTheme) private var theme
    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: theme.metrics.spacingSM) {
                ForEach(demoNotes, id: \.date) { note in
                    PlaceholderTimelineRow(date: note.date) {
                        EMRCard {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(note.title)
                                    .font(theme.typography.body.weight(.semibold))
                                Text(note.detail)
                                    .font(theme.typography.caption)
                                    .foregroundStyle(theme.colors.textSecondary)
                            }
                        }
                    }
                }
            }
            .padding(theme.metrics.spacingMD)
        }
        .background(theme.colors.background)
    }

    private var demoNotes: [(date: Date, title: String, detail: String)] {
        [
            (Date().addingTimeInterval(-2_700), "Vitals", "BP 120x80, HR 84, RR 16"),
            (Date().addingTimeInterval(-14_400), "Dressing", "Dressing clean and dry, no erythema"),
            (Date().addingTimeInterval(-21_600), "Ambulation", "Assisted ambulation, no complaints")
        ]
    }
}

public struct DischargeDemoView: View {
    @Environment(\.emrTheme) private var theme
    @State private var checklist: [String: Bool] = [
        "Discharge prescription generated": false,
        "Discharge instructions delivered": false,
        "Follow-up visit scheduled": false
    ]
    @State private var alertMessage: String?
    public init() {}

    public var body: some View {
        VStack(spacing: theme.metrics.spacingMD) {
            EMRSection("Discharge Plan") {
                VStack(alignment: .leading, spacing: theme.metrics.spacingSM) {
                    Text("Expected date: tomorrow")
                    Text("Instructions: continue aspirin, return in 7 days")
                }
                .font(theme.typography.body)
                .foregroundStyle(theme.colors.textSecondary)
            }
            EMRSection("Checklist") {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(checklist.keys.sorted(), id: \.self) { key in
                        HStack {
                            Toggle(isOn: Binding(get: { checklist[key] ?? false }, set: { checklist[key] = $0 })) {
                                Text(key)
                            }
                        }
                    }
                    Button("Complete discharge") {
                        let allDone = checklist.values.allSatisfy { $0 }
                        alertMessage = allDone ? "Discharge completed (demo)" : "Complete all items"
                    }
                    .buttonStyle(EMRPrimaryButtonStyle())
                }
            }
            if let alertMessage { EMRBadge(alertMessage, style: .info, icon: "checkmark") }
        }
        .padding(theme.metrics.spacingMD)
        .background(theme.colors.background)
    }
}

public struct ChartReviewDemoView: View {
    @Environment(\.emrTheme) private var theme
    @StateObject private var service: ChartReviewServiceBox
    @State private var newNote: String = ""
    @State private var alertMessage: String?

    public init(service: (any ChartReviewService)? = nil) {
        _service = StateObject(wrappedValue: ChartReviewServiceBox(service ?? DemoChartReviewService()))
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: theme.metrics.spacingSM) {
                ForEach(service.items) { item in
                    PlaceholderTimelineRow(date: item.date) {
                        EMRCard {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(item.title)
                                        .font(theme.typography.body.weight(.semibold))
                                    Text(item.detail)
                                        .font(theme.typography.caption)
                                        .foregroundStyle(theme.colors.textSecondary)
                                }
                                Spacer()
                                Text(item.date, style: .relative)
                                    .font(theme.typography.caption)
                                    .foregroundStyle(theme.colors.textTertiary)
                            }
                        }
                    }
                }
                Divider().padding(.vertical, theme.metrics.spacingSM)
                EMRSection("Legend") {
                    HStack(spacing: theme.metrics.spacingSM) {
                        EMRBadge("Progress", style: .info)
                        EMRBadge("Prescription", style: .warning)
                        EMRBadge("Exam", style: .success)
                        EMRBadge("Note", style: .neutral)
                    }
                }
                EMRSection("Add note") {
                    VStack(alignment: .leading, spacing: 8) {
                        TextField("New note", text: $newNote)
                        Button("Add") {
                            let trimmed = newNote.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            service.addDemoNote(detail: trimmed)
                            newNote = ""
                            alertMessage = "Note added (demo)"
                        }
                        .buttonStyle(EMRPrimaryButtonStyle())
                    }
                }
                if let alertMessage { EMRBadge(alertMessage, style: .success, icon: "checkmark") }
            }
            .padding(theme.metrics.spacingMD)
        }
        .task { await service.refresh() }
        .background(theme.colors.background)
    }
}

private struct PlaceholderTimelineRow<Content: View>: View {
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
