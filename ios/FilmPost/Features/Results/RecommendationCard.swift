import FilmPostCore
import SwiftUI

struct RecommendationCard: View {
    let recommendation: Recommendation
    let index: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            Text(recommendation.whyThisMatches)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(FilmPostTheme.ink)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Divider().background(FilmPostTheme.line)

            VStack(alignment: .leading, spacing: 11) {
                InlineSpec(label: "Pose", value: recommendation.pose)
                InlineSpec(label: "Composition", value: recommendation.composition)
                InlineSpec(label: "Color", value: recommendation.colorDirection)
                InlineSpec(label: "Distance", value: recommendation.cameraDistance)
                InlineSpec(label: "Light", value: recommendation.lightingTip)
                InlineSpec(label: "Mood", value: recommendation.referenceFilmMood)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            ZStack {
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(FilmPostTheme.card)

                // soft amber wash on the upper-left corner only
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [FilmPostTheme.amber.opacity(0.10), .clear],
                            startPoint: .topLeading,
                            endPoint: .center
                        )
                    )
                    .allowsHitTesting(false)

                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .stroke(FilmPostTheme.line, lineWidth: 1)
            }
            .compositingGroup()
            .shadow(color: FilmPostTheme.shadow, radius: 18, x: 0, y: 10)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Direction \(index + 1) of \(total): \(recommendation.style)")
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Direction \(index + 1) of \(total)")
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(FilmPostTheme.slate)
                .textCase(.uppercase)
                .tracking(0.8)

            Text(recommendation.style)
                .font(.system(.title2, design: .rounded, weight: .semibold))
                .foregroundStyle(FilmPostTheme.ink)
                .lineLimit(2)
                .minimumScaleFactor(0.85)
        }
    }
}

private struct InlineSpec: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 12) {
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(FilmPostTheme.slate)
                .textCase(.uppercase)
                .tracking(0.6)
                .frame(width: 104, alignment: .leading)

            Text(value)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(FilmPostTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
