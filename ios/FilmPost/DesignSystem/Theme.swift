import SwiftUI
import UIKit

/// Color tokens for FilmPost. The palette stays warm and cinematic, but the
/// surfaces are softer so the app still feels native and calm on iPhone.
enum FilmPostTheme {
    static let paper  = dynamicColor(light: 0xF7F4ED, dark: 0x11100E)
    static let haze   = dynamicColor(light: 0xEEE8DD, dark: 0x181713)
    static let panel  = dynamicColor(light: 0xEAE4D7, dark: 0x201F1A)
    static let card   = dynamicColor(light: 0xFFFCF6, dark: 0x1B1916, lightAlpha: 0.94, darkAlpha: 0.96)
    static let mist   = dynamicColor(light: 0xFFFFFF, dark: 0x2A2722, lightAlpha: 0.66, darkAlpha: 0.46)

    static let ink      = dynamicColor(light: 0x171613, dark: 0xF5F1E7)
    static let slate    = dynamicColor(light: 0x686256, dark: 0xB0A898)
    static let hairline = dynamicColor(light: 0x171613, dark: 0xF5F1E7, lightAlpha: 0.09, darkAlpha: 0.18)
    static let line     = dynamicColor(light: 0x171613, dark: 0xF5F1E7, lightAlpha: 0.06, darkAlpha: 0.12)

    static let amber  = dynamicColor(light: 0xC58A45, dark: 0xE0A867)
    static let rust   = dynamicColor(light: 0x8E4324, dark: 0xC7774F)
    static let shadow = Color.black.opacity(0.10)

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

/// Typography helpers. Display text keeps a small serif note; everything else
/// stays system-led for readability and a more native feel.
enum FilmPostType {
    static func display(_ style: Font.TextStyle = .largeTitle, weight: Font.Weight = .semibold) -> Font {
        .system(style, design: .serif, weight: weight)
    }

    static func body(_ style: Font.TextStyle = .body, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .default, weight: weight)
    }

    static func label(_ style: Font.TextStyle = .caption, weight: Font.Weight = .semibold) -> Font {
        .system(style, design: .default, weight: weight)
    }

    static func mono(_ style: Font.TextStyle = .caption, weight: Font.Weight = .semibold) -> Font {
        .system(style, design: .monospaced, weight: weight).monospacedDigit()
    }
}

/// A thin divider shared across cards and sections.
struct Hairline: View {
    var body: some View {
        Rectangle()
            .fill(FilmPostTheme.hairline)
            .frame(height: 1)
            .accessibilityHidden(true)
    }
}

/// Tiny section label used to introduce groups of content.
struct Kicker: View {
    let text: String

    var body: some View {
        Text(text)
            .font(FilmPostType.label(.caption, weight: .bold))
            .foregroundStyle(FilmPostTheme.slate)
            .textCase(.uppercase)
            .tracking(1.1)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Background for the app. It stays minimal, with a soft warmth rather than a
/// heavy "movie poster" treatment.
struct CinematicBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    FilmPostTheme.paper,
                    FilmPostTheme.haze,
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Circle()
                .fill(
                    RadialGradient(
                        colors: [FilmPostTheme.amber.opacity(0.16), .clear],
                        center: .center,
                        startRadius: 8,
                        endRadius: 240
                    )
                )
                .frame(width: 320, height: 320)
                .offset(x: 136, y: -290)

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
                .offset(x: -170, y: 350)

            FilmGrain()
        }
        .accessibilityHidden(true)
    }
}

/// Tiny deterministic grain layer drawn with Canvas. Kept intentionally subtle.
struct FilmGrain: View {
    var density: Int = 760

    var body: some View {
        Canvas(rendersAsynchronously: true) { ctx, size in
            var rng = SystemRandomNumberGenerator()
            for _ in 0..<density {
                let x = CGFloat.random(in: 0..<size.width, using: &rng)
                let y = CGFloat.random(in: 0..<size.height, using: &rng)
                let a = Double.random(in: 0.02...0.06, using: &rng)
                let s = CGFloat.random(in: 0.4...1.1, using: &rng)
                let rect = CGRect(x: x, y: y, width: s, height: s)
                ctx.fill(Path(ellipseIn: rect), with: .color(.black.opacity(a)))
            }
        }
        .blendMode(.multiply)
        .opacity(0.22)
        .allowsHitTesting(false)
    }
}

struct EditorialCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 26

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                FilmPostTheme.card,
                                FilmPostTheme.card.opacity(0.96),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(FilmPostTheme.hairline, lineWidth: 1)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(Color.white.opacity(0.18), lineWidth: 1)
                            .blendMode(.overlay)
                    )
                    .shadow(color: FilmPostTheme.shadow, radius: 18, x: 0, y: 8)
            )
    }
}

extension View {
    func editorialCard(cornerRadius: CGFloat = 26) -> some View {
        modifier(EditorialCardModifier(cornerRadius: cornerRadius))
    }

    func glassCard(cornerRadius: CGFloat = 26) -> some View {
        modifier(EditorialCardModifier(cornerRadius: cornerRadius))
    }
}
