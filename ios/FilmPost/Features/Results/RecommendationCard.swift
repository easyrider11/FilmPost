import FilmPostCore
import SwiftUI
import UIKit

struct RecommendationCard: View {
    let recommendation: Recommendation
    let index: Int
    let total: Int
    let backgroundPreview: UIImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            hero

            VStack(alignment: .leading, spacing: 16) {
                DirectorBriefCard(
                    directorNote: recommendation.directorNote,
                    emotionalGoal: recommendation.emotionalGoal,
                    filmMood: recommendation.referenceFilmMood
                )

                CinemaAnchorCard(
                    cinemaReference: recommendation.cinemaReference,
                    whyThisMatches: recommendation.whyThisMatches,
                    directorNote: recommendation.directorNote,
                    filmMood: recommendation.referenceFilmMood,
                    emotionalGoal: recommendation.emotionalGoal
                )

                DetailSection(
                    title: "Blocking",
                    items: [
                        DetailItem(label: "Pose", value: recommendation.pose),
                        DetailItem(label: "Composition", value: recommendation.composition),
                    ]
                )

                DetailSection(
                    title: "On set",
                    items: [
                        DetailItem(label: "Color direction", value: recommendation.colorDirection),
                        DetailItem(label: "Camera distance", value: recommendation.cameraDistance),
                        DetailItem(label: "Lighting tip", value: recommendation.lightingTip),
                    ]
                )
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .editorialCard(cornerRadius: 28)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Direction \(index + 1) of \(total): \(recommendation.style). Inspired by \(recommendation.cinemaReference.filmTitle)."
        )
    }

    private var hero: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let backgroundPreview {
                    Image(uiImage: backgroundPreview)
                        .resizable()
                        .scaledToFill()
                } else {
                    LinearGradient(
                        colors: [FilmPostTheme.ink, FilmPostTheme.panel],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 154)
            .overlay(
                LinearGradient(
                    colors: [.black.opacity(0.10), .black.opacity(0.12), .black.opacity(0.58)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 28,
                    bottomLeadingRadius: 0,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 28,
                    style: .continuous
                )
            )

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Look \(index + 1)")
                        .font(FilmPostType.label(.caption, weight: .semibold))
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.black.opacity(0.18), in: Capsule(style: .continuous))

                    Spacer()

                    Text("\(index + 1) / \(total)")
                        .font(FilmPostType.mono(.caption, weight: .semibold))
                        .foregroundStyle(Color.white.opacity(0.82))
                }

                Text(recommendation.cinemaReference.filmTitle)
                    .font(FilmPostType.label(.caption, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.82))
                    .lineLimit(1)

                Text(recommendation.style)
                    .font(FilmPostType.display(.title2, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .lineLimit(2)
                    .minimumScaleFactor(0.84)

                Text("Directed in the spirit of \(recommendation.cinemaReference.director)")
                    .font(FilmPostType.body(.footnote, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.76))
                    .lineLimit(1)
            }
            .padding(18)
        }
        .accessibilityHidden(true)
    }
}

private struct DirectorBriefCard: View {
    let directorNote: String
    let emotionalGoal: String
    let filmMood: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Kicker(text: "Director's note")

            Text(directorNote)
                .font(FilmPostType.body(.subheadline))
                .foregroundStyle(FilmPostTheme.ink)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            Hairline()

            VStack(alignment: .leading, spacing: 8) {
                CompactMetaRow(label: "Emotional goal", value: emotionalGoal)
                CompactMetaRow(label: "Film mood", value: filmMood)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            FilmPostTheme.panel.opacity(0.78),
                            FilmPostTheme.card.opacity(0.92),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(FilmPostTheme.line, lineWidth: 1)
                )
        )
    }
}

private struct CinemaAnchorCard: View {
    let cinemaReference: CinemaReference
    let whyThisMatches: String
    let directorNote: String
    let filmMood: String
    let emotionalGoal: String

    private var filmContext: FilmContext {
        FilmContext(
            title: cinemaReference.filmTitle,
            director: cinemaReference.director,
            sceneAnchor: cinemaReference.sceneAnchor,
            whyItConnects: cinemaReference.whyItConnects,
            borrowedTechnique: cinemaReference.borrowedTechnique,
            filmMood: filmMood,
            directorNote: directorNote,
            emotionalGoal: emotionalGoal
        )
    }

    private var directorContext: DirectorContext {
        DirectorContext(
            name: cinemaReference.director,
            directorNote: directorNote,
            filmMood: filmMood,
            emotionalGoal: emotionalGoal
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Kicker(text: "Cinema anchor")

            VStack(alignment: .leading, spacing: 6) {
                // Film title — tappable link
                NavigationLink(value: CinemaDetailDestination.film(filmContext)) {
                    HStack(spacing: 5) {
                        Text(cinemaReference.filmTitle)
                            .font(FilmPostType.display(.headline, weight: .semibold))
                            .foregroundStyle(FilmPostTheme.ink)
                            .multilineTextAlignment(.leading)
                        Image(systemName: "film")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(FilmPostTheme.amber)
                    }
                }
                .buttonStyle(.plain)

                // Director — tappable link
                NavigationLink(value: CinemaDetailDestination.director(directorContext)) {
                    HStack(spacing: 4) {
                        Text(cinemaReference.director)
                            .font(FilmPostType.body(.footnote, weight: .medium))
                            .foregroundStyle(FilmPostTheme.rust)
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundStyle(FilmPostTheme.rust.opacity(0.75))
                    }
                }
                .buttonStyle(.plain)
            }

            Text(cinemaReference.sceneAnchor)
                .font(FilmPostType.label(.caption, weight: .semibold))
                .foregroundStyle(FilmPostTheme.ink)
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule(style: .continuous)
                        .fill(FilmPostTheme.mist)
                )

            VStack(alignment: .leading, spacing: 8) {
                CompactMetaRow(label: "Why it connects", value: cinemaReference.whyItConnects)
                CompactMetaRow(label: "This version", value: whyThisMatches)
                CompactMetaRow(label: "Borrow", value: cinemaReference.borrowedTechnique)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(FilmPostTheme.panel.opacity(0.58))
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(FilmPostTheme.line, lineWidth: 1)
                )
        )
    }
}

private struct CompactMetaRow: View {
    let label: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(FilmPostType.label(.caption, weight: .semibold))
                .foregroundStyle(FilmPostTheme.slate)
                .textCase(.uppercase)
                .tracking(FilmPostType.labelTracking)

            Text(value)
                .font(FilmPostType.body(.footnote))
                .foregroundStyle(FilmPostTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

private struct DetailSection: View {
    let title: String
    let items: [DetailItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Kicker(text: title)

            VStack(spacing: 10) {
                ForEach(items) { item in
                    DetailBlock(item: item)
                }
            }
        }
    }
}

private struct DetailItem: Identifiable {
    let label: String
    let value: String

    var id: String { label }
}

private struct DetailBlock: View {
    let item: DetailItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.label)
                .font(FilmPostType.label(.caption, weight: .semibold))
                .foregroundStyle(FilmPostTheme.slate)
                .textCase(.uppercase)
                .tracking(FilmPostType.labelTracking)

            Text(item.value)
                .font(FilmPostType.body(.subheadline))
                .foregroundStyle(FilmPostTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(FilmPostTheme.card.opacity(0.72))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(FilmPostTheme.line, lineWidth: 1)
                )
        )
    }
}
