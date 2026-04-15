import FilmPostCore
import SwiftUI

struct RecommendationCard: View {
    let recommendation: Recommendation
    let index: Int
    let total: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(recommendation.style)
                        .font(.system(size: 24, weight: .semibold, design: .rounded))
                        .foregroundStyle(FilmPostTheme.ink)

                    Text("Direction \(index + 1) of \(total)")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(FilmPostTheme.slate)
                }

                Spacer()

                Text("\(index + 1)")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(FilmPostTheme.ink)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(FilmPostTheme.panel, in: Capsule())
            }

            Text(recommendation.whyThisMatches)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(FilmPostTheme.ink)
                .fixedSize(horizontal: false, vertical: true)

            Divider().background(FilmPostTheme.line)

            VStack(alignment: .leading, spacing: 10) {
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
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(Color.white.opacity(0.88))
                .overlay(
                    RoundedRectangle(cornerRadius: 26, style: .continuous)
                        .stroke(FilmPostTheme.line, lineWidth: 1)
                )
                .shadow(color: FilmPostTheme.shadow, radius: 20, x: 0, y: 10)
        )
        .overlay(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [FilmPostTheme.amber.opacity(0.10), .clear],
                        startPoint: .topLeading,
                        endPoint: .center
                    )
                )
        }
    }
}

private struct InlineSpec: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(FilmPostTheme.slate)
                .frame(width: 78, alignment: .leading)

            Text(value)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(FilmPostTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
