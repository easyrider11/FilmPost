import SwiftUI

enum FilmPostTheme {
    static let paper = Color(red: 0.972, green: 0.963, blue: 0.943)
    static let haze = Color(red: 0.942, green: 0.925, blue: 0.892)
    static let ink = Color(red: 0.137, green: 0.149, blue: 0.180)
    static let slate = Color(red: 0.403, green: 0.420, blue: 0.456)
    static let amber = Color(red: 0.741, green: 0.572, blue: 0.337)
    static let mist = Color.white.opacity(0.76)
    static let card = Color.white.opacity(0.84)
    static let panel = Color(red: 0.958, green: 0.944, blue: 0.917)
    static let line = Color.white.opacity(0.78)
    static let shadow = Color.black.opacity(0.06)
}

struct CinematicBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    FilmPostTheme.paper,
                    Color.white.opacity(0.92),
                    FilmPostTheme.haze.opacity(0.88),
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            Ellipse()
                .fill(
                    RadialGradient(
                        colors: [FilmPostTheme.amber.opacity(0.14), .clear],
                        center: .center,
                        startRadius: 8,
                        endRadius: 200
                    )
                )
                .frame(width: 300, height: 260)
                .offset(x: 120, y: -300)

            RoundedRectangle(cornerRadius: 80, style: .continuous)
                .fill(
                    RadialGradient(
                        colors: [FilmPostTheme.slate.opacity(0.05), .clear],
                        center: .center,
                        startRadius: 4,
                        endRadius: 260
                    )
                )
                .frame(width: 320, height: 320)
                .offset(x: -150, y: 340)
        }
    }
}

struct GlassCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(FilmPostTheme.card)
                    .overlay(
                        RoundedRectangle(cornerRadius: 24, style: .continuous)
                            .stroke(FilmPostTheme.line, lineWidth: 1)
                    )
                    .shadow(color: FilmPostTheme.shadow, radius: 20, x: 0, y: 10)
            )
    }
}

extension View {
    func glassCard() -> some View {
        modifier(GlassCardModifier())
    }
}
