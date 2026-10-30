import SwiftUI
import UIKit

/// Colour tokens from design spec §3 (monochrome; only warning and error carry colour).
enum Theme {
    static let background = dynamic(light: 0xF3F3F3, dark: 0x000000)
    static let card = dynamic(light: 0xFFFFFF, dark: 0x141414)
    static let label = dynamic(light: 0x0A0A0A, dark: 0xF5F5F5)
    static let secondaryLabel = dynamic(light: 0x6B6B6B, dark: 0x9A9A9A)
    static let hairline = dynamic(light: 0xECECEC, dark: 0x262626)
    static let primaryButton = dynamic(light: 0x0A0A0A, dark: 0xF5F5F5)
    static let primaryButtonLabel = dynamic(light: 0xFFFFFF, dark: 0x0A0A0A)
    static let lintWarn = dynamic(light: 0xB45309, dark: 0xFFB224)
    static let lintError = dynamic(light: 0xC2001F, dark: 0xFF4245)

    static let cardRadius: CGFloat = 30

    static func uiDynamic(light: UInt32, dark: UInt32) -> UIColor {
        UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
                           blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
        }
    }

    private static func dynamic(light: UInt32, dark: UInt32) -> Color {
        Color(uiColor: uiDynamic(light: light, dark: dark))
    }
}

/// Large black pill button (design spec §3, PrimaryButton).
struct PillButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .frame(maxWidth: .infinity, minHeight: 52)
            .foregroundStyle(Theme.primaryButtonLabel)
            .background(Theme.primaryButton, in: Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

/// White rounded card that groups rows.
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Theme.card, in: RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
    }
}

extension View {
    func card() -> some View { modifier(CardBackground()) }
}
