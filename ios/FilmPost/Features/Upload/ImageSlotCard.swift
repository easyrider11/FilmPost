import SwiftUI
import UIKit

struct ImageSlotCard: View {
    let role: ImageRole
    let photo: SelectedPhoto?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(role.subtitle)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(FilmPostTheme.slate)
                        .textCase(.uppercase)
                        .tracking(0.6)

                    Text(role.title)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundStyle(FilmPostTheme.ink)
                }

                Spacer()

                statusPill
            }

            preview
        }
        .padding(18)
        .glassCard()
    }

    private var statusPill: some View {
        let isReady = photo != nil
        return Text(isReady ? "Ready" : "Add")
            .font(.system(.footnote, design: .rounded, weight: .semibold))
            .foregroundStyle(isReady ? FilmPostTheme.ink : FilmPostTheme.amber)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                (isReady ? FilmPostTheme.panel : FilmPostTheme.amber.opacity(0.16)),
                in: Capsule()
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
                .frame(height: 152)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay(alignment: .bottomLeading) {
                    Text("Tap to replace")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 7)
                        .background(.ultraThinMaterial, in: Capsule())
                        .padding(10)
                }
                .accessibilityLabel("Selected \(role.title.lowercased()) image")
        } else {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(FilmPostTheme.panel.opacity(0.65))
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [7, 6]))
                        .foregroundStyle(FilmPostTheme.slate.opacity(0.28))
                )
                .frame(height: 152)
                .overlay {
                    VStack(spacing: 10) {
                        Image(systemName: role == .subject ? "person.crop.square" : "photo.on.rectangle.angled")
                            .font(.system(size: 26, weight: .regular))
                            .foregroundStyle(FilmPostTheme.slate.opacity(0.7))

                        Text("Choose \(role.title.lowercased()) image")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                            .foregroundStyle(FilmPostTheme.slate)
                    }
                }
                .accessibilityHidden(true)
        }
    }
}
