import SwiftUI

/// Primary CTA. Dark filled pill with subtle press feedback.
struct PrimaryButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.headline, design: .rounded, weight: .semibold))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                LinearGradient(
                    colors: [FilmPostTheme.ink, FilmPostTheme.ink.opacity(0.92)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                in: RoundedRectangle(cornerRadius: 18, style: .continuous)
            )
            .foregroundStyle(Color.white)
            .shadow(color: FilmPostTheme.ink.opacity(0.18), radius: 14, x: 0, y: 8)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .opacity(isEnabled ? 1 : 0.45)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}

/// Quiet text-only button used for secondary actions like "Replace Images".
struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(.subheadline, design: .rounded, weight: .semibold))
            .foregroundStyle(FilmPostTheme.slate)
            .padding(.vertical, 8)
            .opacity(configuration.isPressed ? 0.5 : 1)
    }
}

/// Round chevron / icon button used in toolbars and header rows.
struct CircleIconButtonStyle: ButtonStyle {
    var diameter: CGFloat = 40

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(FilmPostTheme.ink)
            .frame(width: diameter, height: diameter)
            .background(FilmPostTheme.panel, in: Circle())
            .overlay(Circle().stroke(FilmPostTheme.line, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.94 : 1)
            .animation(.snappy(duration: 0.18), value: configuration.isPressed)
    }
}
