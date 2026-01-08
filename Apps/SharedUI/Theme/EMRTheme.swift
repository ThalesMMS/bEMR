import SwiftUI
#if canImport(UIKit)
import UIKit
#endif
#if canImport(AppKit)
import AppKit
#endif

// MARK: - Theme Model

public struct EMRTheme {
    public struct Colors {
        public let primary: Color
        public let secondary: Color
        public let background: Color
        public let surface: Color
        public let surfaceSecondary: Color
        public let border: Color
        public let textPrimary: Color
        public let textSecondary: Color
        public let textTertiary: Color
        public let success: Color
        public let warning: Color
        public let danger: Color
        public let info: Color
    }

    public struct Typography {
        public let display: Font
        public let title1: Font
        public let title2: Font
        public let title3: Font
        public let headline: Font
        public let body: Font
        public let callout: Font
        public let caption: Font
        public let mono: Font
    }

    public struct Metrics {
        public let radiusSmall: CGFloat
        public let radiusMedium: CGFloat
        public let radiusLarge: CGFloat
        public let spacingXXS: CGFloat
        public let spacingXS: CGFloat
        public let spacingSM: CGFloat
        public let spacingMD: CGFloat
        public let spacingLG: CGFloat
        public let spacingXL: CGFloat
        public let spacingXXL: CGFloat
    }

    public let colors: Colors
    public let typography: Typography
    public let metrics: Metrics

    public static var `default`: EMRTheme {
        baseTheme
    }

    /// Uses platform system colors so the UI adapts automatically to light/dark.
    public static var adaptive: EMRTheme {
        let base = baseTheme
        return EMRTheme(
            colors: Colors(
                primary: platformPrimary,
                secondary: platformTextSecondary,
                background: platformBackground,
                surface: platformSurface,
                surfaceSecondary: platformSurfaceSecondary,
                border: platformBorder,
                textPrimary: platformTextPrimary,
                textSecondary: platformTextSecondary,
                textTertiary: platformTextTertiary,
                success: platformSuccess,
                warning: platformWarning,
                danger: platformDanger,
                info: platformInfo
            ),
            typography: base.typography,
            metrics: base.metrics
        )
    }

    private static var baseTheme: EMRTheme {
        EMRTheme(
            colors: Colors(
                primary: Color(hex: "2B5F8C"),
                secondary: Color(hex: "475569"), // Slate 600
                background: Color(hex: "F1F5F9"), // Light Gray Background
                surface: Color.white,
                surfaceSecondary: Color(hex: "E2E8F0"), // Lighter Gray for headers
                border: Color(hex: "CBD5E1"),
                textPrimary: Color(hex: "1E293B"), // Slate 800
                textSecondary: Color(hex: "64748B"), // Slate 500
                textTertiary: Color(hex: "94A3B8"),
                success: Color(hex: "10B981"), // Emerald 500
                warning: Color(hex: "F59E0B"), // Amber 500
                danger: Color(hex: "EF4444"), // Red 500
                info: Color(hex: "3B82F6") // Blue 500
            ),
            typography: Typography(
                display: .system(size: 32, weight: .bold, design: .rounded),
                title1: .system(size: 24, weight: .bold, design: .rounded),
                title2: .system(size: 20, weight: .semibold, design: .rounded),
                title3: .system(size: 18, weight: .semibold, design: .rounded),
                headline: .system(size: 16, weight: .semibold, design: .default),
                body: .system(size: 16, weight: .regular, design: .default),
                callout: .system(size: 14, weight: .medium, design: .default),
                caption: .system(size: 12, weight: .medium, design: .default),
                mono: .system(size: 14, weight: .regular, design: .monospaced)
            ),
            metrics: Metrics(
                radiusSmall: 6,
                radiusMedium: 12,
                radiusLarge: 20,
                spacingXXS: 2,
                spacingXS: 4,
                spacingSM: 8,
                spacingMD: 16,
                spacingLG: 24,
                spacingXL: 32,
                spacingXXL: 48
            )
        )
    }

    // MARK: - Platform Specific Colors
    
    private static var platformBackground: Color {
        #if os(macOS)
        return Color(nsColor: .windowBackgroundColor)
        #else
        return Color(uiColor: .systemGroupedBackground)
        #endif
    }

    private static var platformSurface: Color {
        #if os(macOS)
        return Color(nsColor: .textBackgroundColor)
        #else
        return Color(uiColor: .secondarySystemGroupedBackground)
        #endif
    }
    
    private static var platformSurfaceSecondary: Color {
        #if os(macOS)
        return Color(nsColor: .underPageBackgroundColor)
        #else
        return Color(uiColor: .tertiarySystemGroupedBackground)
        #endif
    }

    private static var platformBorder: Color {
        #if os(macOS)
        return Color(nsColor: .separatorColor)
        #else
        return Color(uiColor: .separator)
        #endif
    }
    
    private static var platformTextPrimary: Color {
        #if os(macOS)
        return Color(nsColor: .labelColor)
        #else
        return Color(uiColor: .label)
        #endif
    }
    
    private static var platformTextSecondary: Color {
        #if os(macOS)
        return Color(nsColor: .secondaryLabelColor)
        #else
        return Color(uiColor: .secondaryLabel)
        #endif
    }
    
    private static var platformTextTertiary: Color {
        #if os(macOS)
        return Color(nsColor: .tertiaryLabelColor)
        #else
        return Color(uiColor: .tertiaryLabel)
        #endif
    }

    private static var platformPrimary: Color {
        #if os(macOS)
        return Color(nsColor: .controlAccentColor)
        #else
        return Color.accentColor
        #endif
    }

    private static var platformSuccess: Color {
        #if os(macOS)
        return Color(nsColor: .systemGreen)
        #else
        return Color(uiColor: .systemGreen)
        #endif
    }

    private static var platformWarning: Color {
        #if os(macOS)
        return Color(nsColor: .systemOrange)
        #else
        return Color(uiColor: .systemOrange)
        #endif
    }

    private static var platformDanger: Color {
        #if os(macOS)
        return Color(nsColor: .systemRed)
        #else
        return Color(uiColor: .systemRed)
        #endif
    }

    private static var platformInfo: Color {
        #if os(macOS)
        return Color(nsColor: .systemBlue)
        #else
        return Color(uiColor: .systemBlue)
        #endif
    }
}

// MARK: - Color Hex Extension
// MARK: - Color Hex Extension
public extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Environment

private struct EMRThemeKey: EnvironmentKey {
    static let defaultValue: EMRTheme = .default
}

public extension EnvironmentValues {
    var emrTheme: EMRTheme {
        get { self[EMRThemeKey.self] }
        set { self[EMRThemeKey.self] = newValue }
    }
}

public extension View {
    func emrTheme(_ theme: EMRTheme) -> some View {
        environment(\.emrTheme, theme)
    }
}
