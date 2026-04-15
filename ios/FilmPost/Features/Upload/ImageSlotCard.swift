import SwiftUI
import UIKit

struct ImageSlotCard: View {
    let role: ImageRole
    let photo: SelectedPhoto?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(role.subtitle)
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(FilmPostTheme.slate)

                    Text(role.title)
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundStyle(FilmPostTheme.ink)
                }

                Spacer()

                Text(photo == nil ? "Add" : "Ready")
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
                    .foregroundStyle(photo == nil ? FilmPostTheme.amber : FilmPostTheme.ink)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        (photo == nil ? FilmPostTheme.amber.opacity(0.12) : FilmPostTheme.panel.opacity(0.92)),
                        in: Capsule()
                    )
            }

            Group {
                if let photo {
                    Image(uiImage: photo.previewImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 148)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(alignment: .bottomLeading) {
                            Text("Tap to replace")
                                .font(.system(.caption, design: .rounded, weight: .semibold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 7)
                                .background(.ultraThinMaterial, in: Capsule())
                                .padding(10)
                        }
                } else {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(FilmPostTheme.panel.opacity(0.72))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [7, 6]))
                                .foregroundStyle(FilmPostTheme.slate.opacity(0.22))
                        )
                        .foregroundStyle(FilmPostTheme.slate.opacity(0.35))
                        .frame(height: 148)
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
                }
            }
        }
        .padding(18)
        .glassCard()
    }
}
