import FilmPostCore
import SwiftUI

struct ResultsView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let horizontalPageInset: CGFloat = 16
    private let cardWidthInset: CGFloat = 26
    let analysis: AnalysisResponse
    let subjectPhoto: SelectedPhoto?
    let backgroundPhoto: SelectedPhoto?
    let onAnalyzeAnother: () -> Void
    let onResetAll: () -> Void

    @State private var selectedID: Recommendation.ID?

    var body: some View {
        GeometryReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    topBar

                    header

                    cardsCarousel(cardWidth: cardWidth(for: proxy.size.width))

                    ContextSummaryCard(
                        summary: analysis.contextSummary,
                        subjectPhoto: subjectPhoto,
                        backgroundPhoto: backgroundPhoto
                    )

                    actions
                }
                .padding(.top, 10)
                .padding(.horizontal, horizontalPageInset)
                .padding(.bottom, 28)
            }
        }
        .navigationDestination(for: CinemaDetailDestination.self) { destination in
            switch destination {
            case .director(let ctx):
                DirectorDetailView(context: ctx)
            case .film(let ctx):
                FilmDetailView(context: ctx)
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        HStack {
            Button("Back to photo selection", systemImage: "chevron.left", action: onResetAll)
            .labelStyle(.iconOnly)
            .buttonStyle(CircleIconButtonStyle())

            Spacer()

            if let selectedID,
               let index = analysis.recommendations.firstIndex(where: { $0.id == selectedID }) {
                Text("Look \(index + 1) of \(analysis.recommendations.count)")
                    .font(FilmPostType.label(.caption, weight: .semibold))
                    .foregroundStyle(FilmPostTheme.verdigris)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(FilmPostTheme.verdigris.opacity(0.10))
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(FilmPostTheme.verdigris.opacity(0.25), lineWidth: 1)
                            )
                    )
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Kicker(text: "Cinematic directions")

            Text("Three looks tied to classic cinema.")
                .font(FilmPostType.display(.title2, weight: .semibold))
                .foregroundStyle(FilmPostTheme.ink)
                .lineLimit(2)
                .kerning(-0.4)
                .accessibilityAddTraits(.isHeader)

            Text("Swipe for director-style guidance, emotional intent, and on-set direction grounded in this location.")
                .font(FilmPostType.body(.subheadline))
                .foregroundStyle(FilmPostTheme.slate)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if let selectedRecommendation {
                Text("Current reference: \(selectedRecommendation.cinemaReference.filmTitle)")
                    .font(FilmPostType.label(.caption, weight: .semibold))
                    .foregroundStyle(FilmPostTheme.rust)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(FilmPostTheme.rust.opacity(0.08))
                            .overlay(
                                Capsule(style: .continuous)
                                    .stroke(FilmPostTheme.rust.opacity(0.22), lineWidth: 1)
                            )
                    )
            }
        }
    }

    private func cardsCarousel(cardWidth: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(Array(analysis.recommendations.enumerated()), id: \.element.id) { index, recommendation in
                        RecommendationCard(
                            recommendation: recommendation,
                            index: index,
                            total: analysis.recommendations.count,
                            backgroundPreview: backgroundPhoto?.previewImage
                        )
                        .frame(width: cardWidth)
                        .scrollTransition(.interactive, axis: .horizontal) { [reduceMotion] content, phase in
                            content
                                .opacity(phase.isIdentity ? 1 : (reduceMotion ? 0.82 : 0.55))
                                .scaleEffect(reduceMotion ? 1 : (phase.isIdentity ? 1 : 0.94))
                                .blur(radius: reduceMotion ? 0 : (phase.isIdentity ? 0 : 2))
                        }
                        .id(recommendation.id)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollPosition(id: $selectedID)
            .scrollClipDisabled()

            PageDots(
                count: analysis.recommendations.count,
                activeIndex: analysis.recommendations.firstIndex(where: { $0.id == selectedID }) ?? 0
            )
            .frame(maxWidth: .infinity)
        }
        .onAppear {
            updateSelectedIDIfNeeded()
        }
    }

    // MARK: - Actions

    private var actions: some View {
        VStack(spacing: 10) {
            Button("Adjust this pair", action: onAnalyzeAnother)
                .buttonStyle(PrimaryButtonStyle())
                .accessibilityInputLabels(["Adjust this pair", "Analyze again", "Regenerate looks"])

            Button("Choose new photos", action: onResetAll)
                .buttonStyle(SecondaryButtonStyle())
        }
    }

    private func updateSelectedIDIfNeeded() {
        if selectedID == nil {
            selectedID = analysis.recommendations.first?.id
        }
    }

    private func cardWidth(for availableWidth: CGFloat) -> CGFloat {
        let contentWidth = availableWidth - (horizontalPageInset * 2)
        return max(292, contentWidth - cardWidthInset)
    }

    private var selectedRecommendation: Recommendation? {
        guard let selectedID else { return analysis.recommendations.first }
        return analysis.recommendations.first(where: { $0.id == selectedID }) ?? analysis.recommendations.first
    }
}

private struct ContextSummaryCard: View {
    let summary: String
    let subjectPhoto: SelectedPhoto?
    let backgroundPhoto: SelectedPhoto?
    @State private var isExpanded = false

    var body: some View {
        Button(action: toggleExpanded) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(spacing: 10) {
                    preview(for: subjectPhoto, label: "Subject")
                    preview(for: backgroundPhoto, label: "Location")
                }
                .frame(maxWidth: .infinity)

                VStack(alignment: .leading, spacing: 10) {
                    Kicker(text: "Scene read")

                    Text(displaySummary)
                        .font(FilmPostType.body(.subheadline))
                        .foregroundStyle(FilmPostTheme.ink)
                        .lineSpacing(2)
                        .lineLimit(isExpanded ? nil : 3)
                        .fixedSize(horizontal: false, vertical: true)

                    if showsExpansionControl {
                        HStack(spacing: 6) {
                            Text(isExpanded ? "Show less" : "Read full scene read")
                                .font(FilmPostType.body(.footnote, weight: .semibold))
                            Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(FilmPostTheme.rust)
                    }
                }
            }
            .padding(16)
            .editorialCard(cornerRadius: 24)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Scene read")
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
        .accessibilityHint(showsExpansionControl
            ? (isExpanded ? "Double tap to collapse the full scene read" : "Double tap to expand the full scene read")
            : "Shows a short scene summary")
    }

    private var compactSummary: String {
        SummaryCompressor.compact(summary)
    }

    private var normalizedSummary: String {
        SummaryCompressor.normalize(summary)
    }

    private var displaySummary: String {
        isExpanded ? normalizedSummary : compactSummary
    }

    private var showsExpansionControl: Bool {
        normalizedSummary != compactSummary
    }

    private func toggleExpanded() {
        guard showsExpansionControl else { return }
        withAnimation(.smooth(duration: 0.24)) {
            isExpanded.toggle()
        }
    }

    @ViewBuilder
    private func preview(for photo: SelectedPhoto?, label: String) -> some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let photo {
                    Image(uiImage: photo.previewImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(FilmPostTheme.mist)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

            Text(label)
                .font(FilmPostType.label(.caption, weight: .semibold))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(.black.opacity(0.30), in: Capsule(style: .continuous))
                .padding(6)
        }
        .accessibilityLabel("\(label) image preview")
    }
}

private enum SummaryCompressor {
    static func compact(_ summary: String, maxWords: Int = 20) -> String {
        let cleaned = normalize(summary)

        guard !cleaned.isEmpty else { return "" }

        let firstSentence = cleaned
            .split(whereSeparator: { ".!?".contains($0) })
            .first
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }

        if let firstSentence {
            let words = firstSentence.split(whereSeparator: \.isWhitespace)
            if words.count <= maxWords {
                return firstSentence.hasSuffix(".") ? firstSentence : "\(firstSentence)."
            }
        }

        let words = cleaned.split(whereSeparator: \.isWhitespace)
        let clipped = words.prefix(maxWords).joined(separator: " ")
        if words.count > maxWords {
            return "\(clipped)..."
        }

        return cleaned.hasSuffix(".") ? cleaned : "\(cleaned)."
    }

    static func normalize(_ summary: String) -> String {
        summary
            .replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct PageDots: View {
    let count: Int
    let activeIndex: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<count, id: \.self) { i in
                Rectangle()
                    .fill(i == activeIndex ? FilmPostTheme.ink : FilmPostTheme.slate.opacity(0.35))
                    .frame(width: i == activeIndex ? 22 : 8, height: 2)
                    .animation(.smooth(duration: 0.25), value: activeIndex)
            }
        }
        .accessibilityHidden(true)
    }
}
