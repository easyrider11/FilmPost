import SwiftUI
import UIKit

/// Color tokens for FilmPost.
///
/// Direction: **refined cinematheque editorial** — bone whites, deep graphite ink,
/// a single warm accent (ochre) and a sharp wine accent for highlights. The
/// surface family is tightly stepped so cards register without competing with
/// the content layer.
enum FilmPostTheme {
    // Surface family — four tones, each with a clear job.
    static let paper  = dynamicColor(light: 0xECE8DD, dark: 0x0B0B09) // canvas
    static let haze   = dynamicColor(light: 0xE3DED1, dark: 0x131210) // recessed
    static let panel  = dynamicColor(light: 0xD8D2C2, dark: 0x191714) // grouped controls
    static let card   = dynamicColor(light: 0xF6F3E9, dark: 0x171513) // raised cards
    static let mist   = dynamicColor(light: 0xFFFFFF, dark: 0x23211D, lightAlpha: 0.55, darkAlpha: 0.42)

    // Type and structure.
    static let ink      = dynamicColor(light: 0x0E0D0B, dark: 0xEEE9DC)
    static let slate    = dynamicColor(light: 0x595446, dark: 0xA29B89)
    static let hairline = dynamicColor(light: 0x0E0D0B, dark: 0xEEE9DC, lightAlpha: 0.10, darkAlpha: 0.16)
    static let line     = dynamicColor(light: 0x0E0D0B, dark: 0xEEE9DC, lightAlpha: 0.06, darkAlpha: 0.10)

    // Accents — warm ochre as primary brand note, oxblood as the sharp highlight.
    static let amber  = dynamicColor(light: 0xA06A2C, dark: 0xCE9651)
    static let rust   = dynamicColor(light: 0x5C231F, dark: 0xB75D4B)

    /// Cool counterpoint — verdigris/sage for "atmosphere" and "mood" tones,
    /// thought of as aged copper or film leader. Use sparingly to balance
    /// the dominant warm palette.
    static let verdigris = dynamicColor(light: 0x3F6B62, dark: 0x88B6AB)

    // Depth.
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

/// Typography helpers.
///
/// Hierarchy is intentional: a serif display voice for editorial moments, a
/// disciplined sans body, and a tightly tracked uppercase label for kickers.
/// Display callers should also apply `displayKerning` for the chiseled feel.
enum FilmPostType {
    /// Display serif. Use for hero titles only.
    static func display(_ style: Font.TextStyle = .largeTitle, weight: Font.Weight = .semibold) -> Font {
        .system(style, design: .serif, weight: weight)
    }

    /// Optional italic display variant for editorial accents (e.g. film titles).
    static func displayItalic(_ style: Font.TextStyle = .title2, weight: Font.Weight = .semibold) -> Font {
        .system(style, design: .serif, weight: weight).italic()
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

    /// Tightened tracking for display headlines.
    static let displayKerning: CGFloat = -0.7
    /// Tracking for uppercase kickers and metadata labels.
    static let labelTracking: CGFloat = 1.4
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
            .font(FilmPostType.label(.caption2, weight: .bold))
            .foregroundStyle(FilmPostTheme.slate)
            .textCase(.uppercase)
            .tracking(FilmPostType.labelTracking)
            .accessibilityAddTraits(.isHeader)
    }
}

/// Background for the app. A single warm focal point at the top, then a quiet
/// gradient down to a slightly deeper haze. The grain is barely there — just
/// enough texture to keep flat surfaces from looking digital.
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

            // One focal warm glow at the top — the "projector".
            Circle()
                .fill(
                    RadialGradient(
                        colors: [FilmPostTheme.amber.opacity(0.14), .clear],
                        center: .center,
                        startRadius: 4,
                        endRadius: 260
                    )
                )
                .frame(width: 360, height: 360)
                .offset(x: 0, y: -300)
                .blendMode(.plusLighter)

            FilmGrain()
        }
        .accessibilityHidden(true)
    }
}

/// Tiny deterministic grain layer drawn with Canvas. Kept intentionally subtle.
struct FilmGrain: View {
    var density: Int = 320

    var body: some View {
        Canvas(rendersAsynchronously: true) { ctx, size in
            var rng = SystemRandomNumberGenerator()
            for _ in 0..<density {
                let x = CGFloat.random(in: 0..<size.width, using: &rng)
                let y = CGFloat.random(in: 0..<size.height, using: &rng)
                let a = Double.random(in: 0.015...0.04, using: &rng)
                let s = CGFloat.random(in: 0.4...0.9, using: &rng)
                let rect = CGRect(x: x, y: y, width: s, height: s)
                ctx.fill(Path(ellipseIn: rect), with: .color(.black.opacity(a)))
            }
        }
        .blendMode(.multiply)
        .opacity(0.14)
        .allowsHitTesting(false)
    }
}

struct EditorialCardModifier: ViewModifier {
    var cornerRadius: CGFloat = 22

    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(FilmPostTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                            .stroke(FilmPostTheme.hairline, lineWidth: 0.6)
                    )
                    .shadow(color: FilmPostTheme.shadow, radius: 14, x: 0, y: 6)
            )
    }
}

extension View {
    func editorialCard(cornerRadius: CGFloat = 22) -> some View {
        modifier(EditorialCardModifier(cornerRadius: cornerRadius))
    }

    func glassCard(cornerRadius: CGFloat = 22) -> some View {
        modifier(EditorialCardModifier(cornerRadius: cornerRadius))
    }
}
