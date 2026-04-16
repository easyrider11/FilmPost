import SwiftUI
import UIKit

/// Color tokens for FilmPost. Each token resolves differently in light vs dark mode
/// so the app reads correctly in either appearance.
enum FilmPostTheme {
    static let paper  = dynamicColor(light: 0xF8F6F1, dark: 0x111114)
    static let haze   = dynamicColor(light: 0xF0EDE3, dark: 0x16161B)
    static let panel  = dynamicColor(light: 0xF4F1EA, dark: 0x1C1C22)
    static let card   = dynamicColor(light: 0xFFFFFF, dark: 0x1F1F26, lightAlpha: 0.86, darkAlpha: 0.92)
    static let mist   = dynamicColor(light: 0xFFFFFF, dark: 0x2A2A33, lightAlpha: 0.74, darkAlpha: 0.55)
    static let line   = dynamicColor(light: 0xFFFFFF, dark: 0x3A3A45, lightAlpha: 0.78, darkAlpha: 0.55)
    static let ink    = dynamicColor(light: 0x232631, dark: 0xF1F1F4)
    static let slate  = dynamicColor(light: 0x676C74, dark: 0x9DA1AC)
    static let amber  = dynamicColor(light: 0xBD9256, dark: 0xD9A968)
    static let shadow = Color.black.opacity(0.08)

    private static func dynamicColor(
        light: UInt32,
        dark: UInt32,
        lightAlpha: CGFloat = 1,
        darkAlpha: CGFloat = 1
    ) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? uiColor(hex: dark, alpha: darkAlpha)
                : uiColor(hex: light, alpha: lightAlpha)
        })
    }

    private static func uiColor(hex: UInt32, alpha: CGFloat) -> UIColor {
        UIColor(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: alpha
        )
    }
}

/// Soft, layered backdrop. Decorative — hidden from accessibility.
struct CinematicBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    FilmPostTheme.paper,
                    FilmPostTheme.haze.opacity(0.92),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [FilmPostTheme.amber.opacity(0.16), .clear],
                        center: .center,
                        startRadius: 8,
                        endRadius: 220
                    )
                )
                .frame(width: 320, height: 280)
                .offset(x: 130, y: -300)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [FilmPostTheme.slate.opacity(0.08), .clear],
                        center: .center,
                        startRadius: 4,
                        endRadius: 260
                    )
                )
                .frame(width: 360, height: 360)
                .offset(x: -160, y: 360)
        }
        .accessibilityHidden(true)
    }
}

struct GlassCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 24

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(FilmPostTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(FilmPostTheme.line, lineWidth: 1)
                    )
                    .shadow(color: FilmPostTheme.shadow, radius: 18, x: 0, y: 8)
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 24) -> some View {
        modifier(GlassCardModifier(cornerRadius: cornerRadius))
    }
}
