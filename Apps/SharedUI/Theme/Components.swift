import SwiftUI
import CoreDomain

// MARK: - Card

public struct EMRCard<Content: View>: View {
    @Environment(\.emrTheme) private var theme
    private let content: Content
    private let padding: CGFloat?

    public init(padding: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding ?? theme.metrics.spacingMD)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.colors.surface)
            .cornerRadius(theme.metrics.radiusMedium)
            .shadow(color: Color.black.opacity(0.05), radius: 4, y: 1)
            .overlay(
                RoundedRectangle(cornerRadius: theme.metrics.radiusMedium)
                    .stroke(theme.colors.border.opacity(0.5), lineWidth: 0.5)
            )
    }
}

// MARK: - Section

public struct EMRSection<Content: View>: View {
    @Environment(\.emrTheme) private var theme
    private let title: String
    private let actionTitle: String?
    private let action: (() -> Void)?
    private let content: Content

    public init(_ title: String, actionTitle: String? = nil, action: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.actionTitle = actionTitle
        self.action = action
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.spacingSM) {
            HStack {
                Text(title)
                    .font(theme.typography.headline)
                    .foregroundStyle(theme.colors.textPrimary)
                Spacer()
                if let actionTitle, let action {
                    Button(actionTitle, action: action)
                        .font(theme.typography.callout)
                        .foregroundStyle(theme.colors.primary)
                }
            }
            content
        }
        .padding(.vertical, theme.metrics.spacingSM)
    }
}

// MARK: - Badge

public enum EMRBadgeStyle {
    case info, success, warning, danger, neutral

    func background(theme: EMRTheme) -> Color {
        switch self {
        case .info: return theme.colors.info.opacity(0.1)
        case .success: return theme.colors.success.opacity(0.1)
        case .warning: return theme.colors.warning.opacity(0.1)
        case .danger: return theme.colors.danger.opacity(0.1)
        case .neutral: return theme.colors.secondary.opacity(0.1)
        }
    }

    func foreground(theme: EMRTheme) -> Color {
        switch self {
        case .info: return theme.colors.info
        case .success: return theme.colors.success
        case .warning: return theme.colors.warning
        case .danger: return theme.colors.danger
        case .neutral: return theme.colors.secondary
        }
    }
}

public struct EMRBadge: View {
    @Environment(\.emrTheme) private var theme
    private let text: String
    private let style: EMRBadgeStyle
    private let icon: String?

    public init(_ text: String, style: EMRBadgeStyle = .neutral, icon: String? = nil) {
        self.text = text
        self.style = style
        self.icon = icon
    }

    public var body: some View {
        HStack(spacing: 4) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .bold))
            }
            Text(text)
                .font(theme.typography.caption.weight(.medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(style.background(theme: theme))
        .foregroundStyle(style.foreground(theme: theme))
        .cornerRadius(4)
    }
}

// MARK: - Inputs

public struct EMRInput: View {
    @Environment(\.emrTheme) private var theme
    let title: String
    @Binding var text: String
    let prompt: String

    public init(_ title: String, text: Binding<String>, prompt: String = "") {
        self.title = title
        self._text = text
        self.prompt = prompt
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: theme.metrics.spacingXS) {
            Text(title)
                .font(theme.typography.callout)
                .foregroundStyle(theme.colors.textSecondary)
            
            TextField(prompt, text: $text)
                .textFieldStyle(.plain)
                .padding(theme.metrics.spacingSM)
                .background(theme.colors.surface)
                .cornerRadius(theme.metrics.radiusSmall)
                .overlay(
                    RoundedRectangle(cornerRadius: theme.metrics.radiusSmall)
                        .stroke(theme.colors.border, lineWidth: 1)
                )
        }
    }
}

// MARK: - Buttons

public struct EMRPrimaryButtonStyle: ButtonStyle {
    @Environment(\.emrTheme) private var theme
    
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(theme.typography.callout.weight(.semibold))
            .padding(.vertical, theme.metrics.spacingSM)
            .padding(.horizontal, theme.metrics.spacingMD)
            .background(theme.colors.primary)
            .foregroundStyle(.white)
            .cornerRadius(theme.metrics.radiusMedium)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.98 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

public struct EMRSecondaryButtonStyle: ButtonStyle {
    @Environment(\.emrTheme) private var theme
    
    public init() {}
    
    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(theme.typography.callout.weight(.medium))
            .padding(.vertical, theme.metrics.spacingSM)
            .padding(.horizontal, theme.metrics.spacingMD)
            .background(theme.colors.surface)
            .foregroundStyle(theme.colors.textPrimary)
            .overlay(
                RoundedRectangle(cornerRadius: theme.metrics.radiusMedium)
                    .stroke(theme.colors.border, lineWidth: 1)
            )
            .cornerRadius(theme.metrics.radiusMedium)
            .opacity(configuration.isPressed ? 0.8 : 1)
    }
}

// MARK: - Loading & Empty

public struct EMRLoadingOverlay: View {
    @Environment(\.emrTheme) private var theme
    private let message: String?

    public init(message: String? = nil) {
        self.message = message
    }

    public var body: some View {
        ZStack {
            theme.colors.background.opacity(0.5).ignoresSafeArea()
            VStack(spacing: theme.metrics.spacingSM) {
                ProgressView()
                    .controlSize(.large)
                if let message {
                    Text(message)
                        .font(theme.typography.callout)
                        .foregroundStyle(theme.colors.textSecondary)
                }
            }
            .padding(theme.metrics.spacingLG)
            .background(.ultraThinMaterial)
            .cornerRadius(theme.metrics.radiusLarge)
            .shadow(radius: 10)
        }
    }
}

public struct EMREmptyStateView: View {
    @Environment(\.emrTheme) private var theme
    private let systemImage: String
    private let title: String
    private let message: String
    private let actionTitle: String?
    private let action: (() -> Void)?

    public init(systemImage: String = "tray", title: String, message: String, actionTitle: String? = nil, action: (() -> Void)? = nil) {
        self.systemImage = systemImage
        self.title = title
        self.message = message
        self.actionTitle = actionTitle
        self.action = action
    }

    public var body: some View {
        VStack(spacing: theme.metrics.spacingMD) {
            Image(systemName: systemImage)
                .font(.system(size: 48))
                .foregroundStyle(theme.colors.textTertiary)
            
            VStack(spacing: theme.metrics.spacingXS) {
                Text(title)
                    .font(theme.typography.title3)
                    .foregroundStyle(theme.colors.textPrimary)
                Text(message)
                    .font(theme.typography.body)
                    .foregroundStyle(theme.colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(EMRPrimaryButtonStyle())
                    .padding(.top, theme.metrics.spacingSM)
            }
        }
        .padding(theme.metrics.spacingXL)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Patient Header

public struct PatientHeaderView: View {
    @Environment(\.emrTheme) private var theme
    private let patient: Patient
    private let badges: [EMRBadge]
    private let subtitle: String?

    public init(patient: Patient, subtitle: String? = nil, badges: [EMRBadge] = []) {
        self.patient = patient
        self.subtitle = subtitle
        self.badges = badges
    }

    public var body: some View {
        HStack(alignment: .center, spacing: theme.metrics.spacingMD) {
            AvatarView(initials: initials(for: patient))
            
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(patient.name.given) \(patient.name.family)")
                        .font(theme.typography.title2)
                        .foregroundStyle(theme.colors.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                    
                    if let subtitle {
                        Text("•")
                            .foregroundStyle(theme.colors.textTertiary)
                        Text(subtitle)
                            .font(theme.typography.body)
                            .foregroundStyle(theme.colors.textSecondary)
                    }
                }
                
                HStack(spacing: theme.metrics.spacingMD) {
                    InfoLabel(label: "MRN", value: patient.mrn ?? "--")
                    InfoLabel(label: "Gender", value: patient.genderDisplay)
                    if let provider = patient.primaryProvider {
                        InfoLabel(label: "Provider", value: provider.displayName)
                    }
                }
                .font(theme.typography.caption)
            }
            
            Spacer()
            
            if !badges.isEmpty {
                HStack(spacing: theme.metrics.spacingXS) {
                    ForEach(Array(badges.enumerated()), id: \.offset) { $0.element }
                }
            }
        }
        .padding(theme.metrics.spacingMD)
        .background(theme.colors.surface)
        .cornerRadius(theme.metrics.radiusMedium)
        .shadow(color: Color.black.opacity(0.03), radius: 3, y: 1)
        .overlay(
            RoundedRectangle(cornerRadius: theme.metrics.radiusMedium)
                .stroke(theme.colors.border, lineWidth: 1)
        )
    }

    private func initials(for patient: Patient) -> String {
        let given = patient.name.given.first.map(String.init) ?? ""
        let family = patient.name.family.first.map(String.init) ?? ""
        return "\(given)\(family)"
    }
}

private struct InfoLabel: View {
    @Environment(\.emrTheme) private var theme
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label + ":")
                .font(theme.typography.caption)
                .foregroundStyle(theme.colors.textTertiary)
            Text(value)
                .font(theme.typography.caption.weight(.medium))
                .foregroundStyle(theme.colors.textSecondary)
        }
    }
}

private struct AvatarView: View {
    @Environment(\.emrTheme) private var theme
    let initials: String

    var body: some View {
        Text(initials)
            .font(theme.typography.title3)
            .frame(width: 56, height: 56)
            .background(theme.colors.primary.opacity(0.1))
            .foregroundStyle(theme.colors.primary)
            .clipShape(Circle())
            .overlay(
                Circle()
                    .stroke(theme.colors.primary.opacity(0.2), lineWidth: 1)
            )
    }
}

private extension Patient {
    var genderDisplay: String {
        switch gender {
        case .male: return "Male"
        case .female: return "Female"
        case .other: return "Other"
        case .unknown: return "Unknown"
        }
    }
}
