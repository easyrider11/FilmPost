import FilmPostCore
import SwiftUI

struct ResultsView: View {
    let analysis: AnalysisResponse
    let subjectPhoto: SelectedPhoto?
    let backgroundPhoto: SelectedPhoto?
    let onAnalyzeAnother: () -> Void
    let onResetAll: () -> Void

    @State private var selectedID: Recommendation.ID?

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                topBar

                Text("Three cleaner ways to stage this shot.")
                    .font(.system(.title, design: .rounded, weight: .semibold))
                    .foregroundStyle(FilmPostTheme.ink)
                    .lineLimit(3)
                    .accessibilityAddTraits(.isHeader)

                ContextSummaryCard(
                    summary: analysis.contextSummary,
                    subjectPhoto: subjectPhoto,
                    backgroundPhoto: backgroundPhoto
                )

                cardsCarousel

                actions
            }
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: onResetAll) {
                Image(systemName: "chevron.left")
            }
            .buttonStyle(CircleIconButtonStyle())
            .accessibilityLabel("Back to photo selection")

            Spacer()
        }
    }

    private var cardsCarousel: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Swipe through directions")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(FilmPostTheme.ink)

                Spacer()

                if let selectedID,
                   let index = analysis.recommendations.firstIndex(where: { $0.id == selectedID }) {
                    Text("\(index + 1) / \(analysis.recommendations.count)")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(FilmPostTheme.slate)
                        .monospacedDigit()
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 16) {
                    ForEach(Array(analysis.recommendations.enumerated()), id: \.element.id) { index, recommendation in
                        RecommendationCard(
                            recommendation: recommendation,
                            index: index,
                            total: analysis.recommendations.count
                        )
                        .containerRelativeFrame(.horizontal)
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
            if selectedID == nil {
                selectedID = analysis.recommendations.first?.id
            }
        }
    }

    private var actions: some View {
        VStack(spacing: 8) {
            Button("Analyze Another Take", action: onAnalyzeAnother)
                .buttonStyle(PrimaryButtonStyle())

            Button("Replace Images", action: onResetAll)
                .buttonStyle(SecondaryButtonStyle())
        }
    }
}

private struct ContextSummaryCard: View {
    let summary: String
    let subjectPhoto: SelectedPhoto?
    let backgroundPhoto: SelectedPhoto?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                preview(for: subjectPhoto, label: "Subject")
                preview(for: backgroundPhoto, label: "Background")
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Scene Read")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(FilmPostTheme.slate)
                    .textCase(.uppercase)
                    .tracking(0.6)

                Text(summary)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(FilmPostTheme.ink)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .glassCard()
    }

    @ViewBuilder
    private func preview(for photo: SelectedPhoto?, label: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(FilmPostTheme.slate)
                .textCase(.uppercase)
                .tracking(0.6)

            Group {
                if let photo {
                    Image(uiImage: photo.previewImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(FilmPostTheme.mist)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .accessibilityLabel("\(label) image preview")
        }
    }
}

private struct PageDots: View {
    let count: Int
    let activeIndex: Int

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == activeIndex ? FilmPostTheme.ink : FilmPostTheme.slate.opacity(0.28))
                    .frame(width: i == activeIndex ? 22 : 7, height: 7)
                    .animation(.smooth(duration: 0.25), value: activeIndex)
            }
        }
        .accessibilityHidden(true)
    }
}
