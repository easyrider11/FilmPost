import FilmPostCore
import SwiftUI

struct ResultsView: View {
    let analysis: AnalysisResponse
    let subjectPhoto: SelectedPhoto?
    let backgroundPhoto: SelectedPhoto?
    let onAnalyzeAnother: () -> Void
    let onResetAll: () -> Void

    @State private var selectedIndex = 0

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                HStack(spacing: 12) {
                    Button(action: onResetAll) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(FilmPostTheme.ink)
                            .frame(width: 40, height: 40)
                            .background(FilmPostTheme.panel, in: Circle())
                            .overlay(Circle().stroke(FilmPostTheme.line, lineWidth: 1))
                    }
                    .accessibilityLabel("Back to photo selection")

                    Spacer()
                }

                Text("Three cleaner ways to stage this shot.")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(FilmPostTheme.ink)

                ContextSummaryCard(
                    summary: analysis.contextSummary,
                    subjectPhoto: subjectPhoto,
                    backgroundPhoto: backgroundPhoto
                )

                VStack(alignment: .leading, spacing: 12) {
                    Text("Swipe through directions")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(FilmPostTheme.ink)

                    TabView(selection: $selectedIndex) {
                        ForEach(Array(analysis.recommendations.enumerated()), id: \.element.id) { index, recommendation in
                            RecommendationCard(
                                recommendation: recommendation,
                                index: index,
                                total: analysis.recommendations.count
                            )
                            .padding(.horizontal, 4)
                            .padding(.bottom, 32)
                            .tag(index)
                        }
                    }
                    .frame(height: 520)
                    .tabViewStyle(.page(indexDisplayMode: .always))
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                }

                VStack(spacing: 10) {
                    Button("Analyze Another Take") {
                        onAnalyzeAnother()
                    }
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(FilmPostTheme.ink, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .foregroundStyle(Color.white)

                    Button("Replace Images") {
                        onResetAll()
                    }
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(FilmPostTheme.slate)
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 28)
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

            VStack(alignment: .leading, spacing: 8) {
                Text("Scene Read")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(FilmPostTheme.slate)

                Text(summary)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(FilmPostTheme.ink)
                    .lineSpacing(3)
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

            Group {
                if let photo {
                    Image(uiImage: photo.previewImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(FilmPostTheme.mist)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
