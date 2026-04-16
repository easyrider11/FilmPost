import SwiftUI
import UIKit

struct ImageSlotCard: View {
    let role: ImageRole
    let photo: SelectedPhoto?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            preview
        }
        .padding(18)
        .editorialCard(cornerRadius: 24)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline, spacing: 12) {
                Text(role.title)
                    .font(FilmPostType.body(.title3, weight: .semibold))
                    .foregroundStyle(FilmPostTheme.ink)
                    .layoutPriority(1)

                Spacer(minLength: 12)

                statusPill
            }

            Text(photo == nil ? emptyHint : filledHint)
                .font(FilmPostType.body(.subheadline))
                .foregroundStyle(FilmPostTheme.slate)
                .lineSpacing(2)
                .multilineTextAlignment(.leading)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var statusPill: some View {
        let isReady = photo != nil
        return Text(isReady ? "Selected" : "Required")
            .font(FilmPostType.label(.caption, weight: .semibold))
            .foregroundStyle(isReady ? FilmPostTheme.ink : FilmPostTheme.amber)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                Capsule(style: .continuous)
                    .fill(isReady ? FilmPostTheme.panel.opacity(0.7) : FilmPostTheme.amber.opacity(0.12))
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(isReady ? FilmPostTheme.hairline : FilmPostTheme.amber.opacity(0.45), lineWidth: 1)
                    )
            )
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var preview: some View {
        if let photo {
            Image(uiImage: photo.previewImage)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity)
                .frame(height: 172)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(alignment: .bottomLeading) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Replace photo")
                            .font(FilmPostType.label(.caption, weight: .semibold))
                    }
                        .foregroundStyle(Color.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(.black.opacity(0.34), in: Capsule(style: .continuous))
                        .padding(12)
                }
                .accessibilityLabel("Selected \(role.title.lowercased()) image")
        } else {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(FilmPostTheme.panel.opacity(0.58))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [7, 6]))
                        .foregroundStyle(FilmPostTheme.slate.opacity(0.30))
                )
                .frame(height: 172)
                .overlay {
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(FilmPostTheme.card.opacity(0.78))
                                .frame(width: 54, height: 54)

                            Image(systemName: role == .subject ? "person.crop.square" : "photo.on.rectangle.angled")
                                .font(.system(size: 24, weight: .regular))
                                .foregroundStyle(FilmPostTheme.slate.opacity(0.82))
                        }

                        Text("Choose \(role.title.lowercased()) photo")
                            .font(FilmPostType.body(.headline, weight: .medium))
                            .foregroundStyle(FilmPostTheme.ink)

                        Text(emptyHint)
                            .font(FilmPostType.body(.caption))
                            .foregroundStyle(FilmPostTheme.slate)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }
                }
                .accessibilityHidden(true)
        }
    }

    private var emptyHint: String {
        switch role {
        case .subject:
            return "A clear portrait or person works best."
        case .background:
            return "Pick the place or environment you want to shoot in."
        }
    }

    private var filledHint: String {
        switch role {
        case .subject:
            return "We will read posture, eyeline, and how the subject sits in frame."
        case .background:
            return "We will read perspective, depth, color, and available light."
        }
    }
}

struct AspectRatioTag: View {
    let text: String

    var body: some View {
        Text(text)
            .font(FilmPostType.mono(.caption, weight: .semibold))
            .foregroundStyle(Color.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 4)
            .background(.black.opacity(0.45), in: Capsule(style: .continuous))
            .accessibilityHidden(true)
    }
}
