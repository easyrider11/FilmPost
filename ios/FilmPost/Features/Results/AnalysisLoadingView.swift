import SwiftUI

struct AnalysisLoadingView: View {
    let subjectPhoto: SelectedPhoto?
    let backgroundPhoto: SelectedPhoto?

    @State private var animatePulse = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 12)

            HStack(spacing: 14) {
                LoadingPreviewCard(title: "Subject", photo: subjectPhoto)
                LoadingPreviewCard(title: "Background", photo: backgroundPhoto)
            }

            VStack(spacing: 12) {
                ZStack {
                    Circle()
                        .stroke(FilmPostTheme.slate.opacity(0.16), lineWidth: 14)
                        .frame(width: 86, height: 86)

                    Circle()
                        .trim(from: 0.05, to: 0.82)
                        .stroke(
                            AngularGradient(
                                colors: [FilmPostTheme.ink, FilmPostTheme.amber, FilmPostTheme.ink],
                                center: .center
                            ),
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .frame(width: 86, height: 86)
                        .rotationEffect(.degrees(animatePulse ? 360 : 0))
                }
                .padding(.bottom, 8)

                Text("Building three shootable directions")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(FilmPostTheme.ink)

                Text("Reading posture, environment, perspective, and light so the advice stays grounded in both images.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(FilmPostTheme.slate)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 10)
            }

            VStack(alignment: .leading, spacing: 12) {
                LoadingStep(label: "Scanning subject posture and expression")
                LoadingStep(label: "Matching the location to cinematic framing options")
                LoadingStep(label: "Formatting three concise result cards")
            }
            .padding(18)
            .glassCard()

            Spacer()
        }
        .onAppear {
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                animatePulse = true
            }
        }
    }
}

private struct LoadingPreviewCard: View {
    let title: String
    let photo: SelectedPhoto?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(.footnote, design: .rounded, weight: .semibold))
                .foregroundStyle(FilmPostTheme.slate)

            Group {
                if let photo {
                    Image(uiImage: photo.previewImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    Rectangle()
                        .fill(FilmPostTheme.mist)
                        .overlay {
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundStyle(FilmPostTheme.slate.opacity(0.7))
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 156)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        }
        .padding(16)
        .glassCard()
    }
}

private struct LoadingStep: View {
    let label: String

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(FilmPostTheme.amber.opacity(0.9))
                .frame(width: 8, height: 8)

            Text(label)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(FilmPostTheme.ink)
        }
    }
}
