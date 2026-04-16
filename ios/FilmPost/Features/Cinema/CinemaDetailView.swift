import SwiftUI

// MARK: - Navigation context models

struct DirectorContext: Hashable {
    let name: String
    let directorNote: String
    let filmMood: String
    let emotionalGoal: String
}

struct FilmContext: Hashable {
    let title: String
    let director: String
    let sceneAnchor: String
    let whyItConnects: String
    let borrowedTechnique: String
    let filmMood: String
    let directorNote: String
    let emotionalGoal: String
}

enum CinemaDetailDestination: Hashable {
    case director(DirectorContext)
    case film(FilmContext)
}

// MARK: - Shared layout constants

private enum CinemaDetailLayout {
    static let horizontalPadding: CGFloat = 28
    static let cardPadding: CGFloat = 18
    static let cardCornerRadius: CGFloat = 20
    static let sectionSpacing: CGFloat = 22
}

// MARK: - Decorative hero badge

/// A circular emoji "stamp" used as a decorative hero element on the detail pages.
private struct EmojiBadge: View {
    let emoji: String
    var size: CGFloat = 64

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            FilmPostTheme.amber.opacity(0.18),
                            FilmPostTheme.amber.opacity(0.05),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Circle()
                        .stroke(FilmPostTheme.amber.opacity(0.45), lineWidth: 1)
                )
                .frame(width: size, height: size)

            Text(emoji)
                .font(.system(size: size * 0.5))
        }
        .accessibilityHidden(true)
    }
}

/// A small inline emoji that sits to the left of a section kicker.
private struct EmojiKicker: View {
    let emoji: String
    let text: String

    var body: some View {
        HStack(spacing: 8) {
            Text(emoji)
                .font(.system(size: 14))
            Kicker(text: text)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(text)
    }
}

// MARK: - Movie poster (Wikipedia)

private struct FilmPosterCard: View {
    let title: String
    let state: FilmPosterLoader.LoadState
    private let posterSize = CGSize(width: 230, height: 340)

    var body: some View {
        posterContent
            .frame(width: posterSize.width, height: posterSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(FilmPostTheme.paper)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(FilmPostTheme.hairline, lineWidth: 1)
                    )
                    .shadow(color: FilmPostTheme.shadow.opacity(1.4), radius: 22, x: 0, y: 12)
            )
            .accessibilityLabel("\(title) movie poster")
    }

    @ViewBuilder
    private var posterContent: some View {
        switch state {
        case .loaded(let url):
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure, .empty:
                    placeholder(showSpinner: phase.isEmpty)
                @unknown default:
                    placeholder(showSpinner: false)
                }
            }
        case .loading, .idle:
            placeholder(showSpinner: true)
        case .failed:
            placeholder(showSpinner: false)
        }
    }

    @ViewBuilder
    private func placeholder(showSpinner: Bool) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    FilmPostTheme.mist,
                    FilmPostTheme.panel.opacity(0.6),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 12) {
                Text("🎟")
                    .font(.system(size: 56))
                if showSpinner {
                    ProgressView()
                        .tint(FilmPostTheme.amber)
                }
            }
        }
    }
}

private extension AsyncImagePhase {
    var isEmpty: Bool {
        if case .empty = self { return true }
        return false
    }
}

// MARK: - Director portrait (Wikipedia)

private struct DirectorPortraitCard: View {
    let name: String
    let state: DirectorProfileLoader.LoadState
    private let portraitSize = CGSize(width: 180, height: 220)

    var body: some View {
        portraitContent
            .frame(width: portraitSize.width, height: portraitSize.height)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .padding(10)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(FilmPostTheme.paper)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(FilmPostTheme.hairline, lineWidth: 1)
                    )
                    .shadow(color: FilmPostTheme.shadow.opacity(1.4), radius: 22, x: 0, y: 12)
            )
            .accessibilityLabel("\(name) portrait")
    }

    @ViewBuilder
    private var portraitContent: some View {
        switch state {
        case .loaded(let profile):
            if let url = profile.portraitURL {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    case .failure, .empty:
                        placeholder(showSpinner: phase.isEmpty)
                    @unknown default:
                        placeholder(showSpinner: false)
                    }
                }
            } else {
                placeholder(showSpinner: false)
            }
        case .loading, .idle:
            placeholder(showSpinner: true)
        case .failed:
            placeholder(showSpinner: false)
        }
    }

    @ViewBuilder
    private func placeholder(showSpinner: Bool) -> some View {
        ZStack {
            LinearGradient(
                colors: [
                    FilmPostTheme.mist,
                    FilmPostTheme.panel.opacity(0.6),
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 12) {
                Text("🎬")
                    .font(.system(size: 56))
                if showSpinner {
                    ProgressView()
                        .tint(FilmPostTheme.amber)
                }
            }
        }
    }
}

// MARK: - Director detail

struct DirectorDetailView: View {
    let context: DirectorContext
    @State private var profileLoader = DirectorProfileLoader()

    var body: some View {
        ZStack(alignment: .top) {
            CinematicBackdrop().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: CinemaDetailLayout.sectionSpacing) {
                    heroHeader
                    Hairline()
                    if let bio = currentBio, !bio.isEmpty {
                        bioCard(text: bio)
                    }
                    if !context.directorNote.isEmpty {
                        infoCard(emoji: "📝", kicker: "Style for this shot", text: context.directorNote)
                    }
                    if !context.filmMood.isEmpty || !context.emotionalGoal.isEmpty {
                        moodGoalCard
                    }
                    signatureCard
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, CinemaDetailLayout.horizontalPadding)
                .padding(.top, 16)
                .padding(.bottom, 36)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(FilmPostTheme.paper.opacity(0.94), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            await profileLoader.load(directorName: context.name)
        }
    }

    private var currentBio: String? {
        if case .loaded(let profile) = profileLoader.state { return profile.bio }
        return nil
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 18) {
            DirectorPortraitCard(name: context.name, state: profileLoader.state)
                .frame(maxWidth: .infinity, alignment: .center)

            VStack(alignment: .leading, spacing: 6) {
                EmojiKicker(emoji: "🎥", text: "Directorial Voice")
                Text(context.name)
                    .font(FilmPostType.display(.largeTitle, weight: .semibold))
                    .foregroundStyle(FilmPostTheme.ink)
                    .kerning(-0.5)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Borrowed for your frame")
                    .font(FilmPostType.body(.footnote))
                    .italic()
                    .foregroundStyle(FilmPostTheme.slate)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func bioCard(text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            EmojiKicker(emoji: "📖", text: "Brief biography")
            Text(text)
                .font(FilmPostType.body(.subheadline))
                .foregroundStyle(FilmPostTheme.ink)
                .lineSpacing(3)
                .lineLimit(6)
                .fixedSize(horizontal: false, vertical: true)
            Text("Source: Wikipedia")
                .font(FilmPostType.label(.caption2, weight: .semibold))
                .foregroundStyle(FilmPostTheme.slate.opacity(0.75))
                .textCase(.uppercase)
                .tracking(FilmPostType.labelTracking)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(CinemaDetailLayout.cardPadding)
        .editorialCard(cornerRadius: CinemaDetailLayout.cardCornerRadius)
    }

    private var moodGoalCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            EmojiKicker(emoji: "🎨", text: "Tonal palette")

            if !context.filmMood.isEmpty {
                metaRow(emoji: "🌅", label: "Film mood", value: context.filmMood)
            }
            if !context.filmMood.isEmpty && !context.emotionalGoal.isEmpty {
                Hairline()
            }
            if !context.emotionalGoal.isEmpty {
                metaRow(emoji: "💫", label: "Emotional goal", value: context.emotionalGoal)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(CinemaDetailLayout.cardPadding)
        .editorialCard(cornerRadius: CinemaDetailLayout.cardCornerRadius)
    }

    private var signatureCard: some View {
        HStack(spacing: 14) {
            Text("🎞")
                .font(.system(size: 28))
            VStack(alignment: .leading, spacing: 3) {
                Text("Carry the voice")
                    .font(FilmPostType.label(.caption, weight: .semibold))
                    .foregroundStyle(FilmPostTheme.slate)
                    .textCase(.uppercase)
                    .tracking(FilmPostType.labelTracking)
                Text("Apply this director's instincts to your own shoot.")
                    .font(FilmPostType.body(.footnote))
                    .italic()
                    .foregroundStyle(FilmPostTheme.ink)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(CinemaDetailLayout.cardPadding)
        .background(
            RoundedRectangle(cornerRadius: CinemaDetailLayout.cardCornerRadius, style: .continuous)
                .fill(FilmPostTheme.mist.opacity(0.55))
                .overlay(
                    RoundedRectangle(cornerRadius: CinemaDetailLayout.cardCornerRadius, style: .continuous)
                        .stroke(FilmPostTheme.line, lineWidth: 1)
                )
        )
    }

    private func infoCard(emoji: String, kicker: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            EmojiKicker(emoji: emoji, text: kicker)
            Text(text)
                .font(FilmPostType.body(.subheadline))
                .foregroundStyle(FilmPostTheme.ink)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(CinemaDetailLayout.cardPadding)
        .editorialCard(cornerRadius: CinemaDetailLayout.cardCornerRadius)
    }

    private func metaRow(emoji: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Text(emoji).font(.system(size: 12))
                Text(label)
                    .font(FilmPostType.label(.caption, weight: .semibold))
                    .foregroundStyle(FilmPostTheme.slate)
                    .textCase(.uppercase)
                    .tracking(FilmPostType.labelTracking)
            }
            Text(value)
                .font(FilmPostType.body(.subheadline))
                .foregroundStyle(FilmPostTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Film detail

struct FilmDetailView: View {
    let context: FilmContext
    @State private var posterLoader = FilmPosterLoader()

    var body: some View {
        ZStack(alignment: .top) {
            CinematicBackdrop().ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: CinemaDetailLayout.sectionSpacing) {
                    heroHeader
                    Hairline()
                    if !context.filmMood.isEmpty {
                        moodPill
                    }
                    if !context.sceneAnchor.isEmpty {
                        infoCard(emoji: "🎞", kicker: "Scene context", text: context.sceneAnchor)
                    }
                    if !context.whyItConnects.isEmpty {
                        infoCard(emoji: "✨", kicker: "Why it connects", text: context.whyItConnects)
                    }
                    if !context.borrowedTechnique.isEmpty {
                        infoCard(emoji: "💡", kicker: "Technique to borrow", text: context.borrowedTechnique)
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, CinemaDetailLayout.horizontalPadding)
                .padding(.top, 16)
                .padding(.bottom, 36)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(FilmPostTheme.paper.opacity(0.94), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .task {
            await posterLoader.load(filmTitle: context.title)
        }
    }

    private var heroHeader: some View {
        VStack(alignment: .leading, spacing: 18) {
            FilmPosterCard(title: context.title, state: posterLoader.state)
                .frame(maxWidth: .infinity, alignment: .center)

            VStack(alignment: .leading, spacing: 10) {
                EmojiKicker(emoji: "🎬", text: "Cinema Reference")

                Text(context.title)
                    .font(FilmPostType.display(.largeTitle, weight: .semibold))
                    .italic()
                    .foregroundStyle(FilmPostTheme.ink)
                    .kerning(-0.5)
                    .fixedSize(horizontal: false, vertical: true)

                directorCapsule
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var directorCapsule: some View {
        NavigationLink(value: CinemaDetailDestination.director(
            DirectorContext(
                name: context.director,
                directorNote: context.directorNote,
                filmMood: context.filmMood,
                emotionalGoal: context.emotionalGoal
            )
        )) {
            HStack(spacing: 6) {
                Text("🎭")
                    .font(.system(size: 12))
                Text("Directed by")
                    .font(FilmPostType.body(.footnote))
                    .foregroundStyle(FilmPostTheme.slate)
                Text(context.director)
                    .font(FilmPostType.body(.footnote, weight: .semibold))
                    .foregroundStyle(FilmPostTheme.rust)
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(FilmPostTheme.rust.opacity(0.75))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(
                Capsule(style: .continuous)
                    .fill(FilmPostTheme.rust.opacity(0.08))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(FilmPostTheme.rust.opacity(0.25), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
        .accessibilityHint("Opens the director profile")
    }

    private var moodPill: some View {
        HStack(spacing: 6) {
            Text("🎨").font(.system(size: 13))
            Text(context.filmMood)
                .font(FilmPostType.label(.caption2, weight: .semibold))
                .foregroundStyle(FilmPostTheme.verdigris)
                .textCase(.uppercase)
                .tracking(FilmPostType.labelTracking)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 8)
        .background(
            Capsule(style: .continuous)
                .fill(FilmPostTheme.verdigris.opacity(0.10))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(FilmPostTheme.verdigris.opacity(0.28), lineWidth: 1)
                )
        )
    }

    private func infoCard(emoji: String, kicker: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            EmojiKicker(emoji: emoji, text: kicker)
            Text(text)
                .font(FilmPostType.body(.subheadline))
                .foregroundStyle(FilmPostTheme.ink)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(CinemaDetailLayout.cardPadding)
        .editorialCard(cornerRadius: CinemaDetailLayout.cardCornerRadius)
    }
}
