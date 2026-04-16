import PhotosUI
import SwiftUI

struct UploadView: View {
    private let horizontalContentInset: CGFloat = 12
    private let analyzeButtonTextOffset: CGFloat = 6
    @Bindable var model: AppModel
    @State private var subjectPickerItem: PhotosPickerItem?
    @State private var backgroundPickerItem: PhotosPickerItem?

    var body: some View {
        let subjectPhoto = model.subjectPhoto
        let backgroundPhoto = model.backgroundPhoto
        let canAnalyze = model.canAnalyze

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                masthead

                featureHighlights

                PhotosPicker(
                    selection: $subjectPickerItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    ImageSlotCard(role: .subject, photo: subjectPhoto)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(subjectPhoto == nil
                    ? "Choose a subject photo"
                    : "Subject photo selected, tap to replace")

                PhotosPicker(
                    selection: $backgroundPickerItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    ImageSlotCard(role: .background, photo: backgroundPhoto)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(backgroundPhoto == nil
                    ? "Choose a background photo"
                    : "Background photo selected, tap to replace")

                Button(action: analyzeImages) {
                    HStack(spacing: 10) {
                        Text("Analyze images")
                            .padding(.leading, analyzeButtonTextOffset)
                        Spacer()
                        Image(systemName: "arrow.right")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canAnalyze)
                .accessibilityHint(canAnalyze
                    ? "Sends both images for cinematic direction"
                    : "Pick a subject and a background photo first")
                .accessibilityInputLabels(["Analyze", "Analyze images", "Develop direction"])

                Text("FilmPost gives practical direction for the shoot itself, not a look layered on afterward.")
                    .font(FilmPostType.body(.footnote, weight: .regular))
                    .foregroundStyle(FilmPostTheme.slate)
                    .padding(.horizontal, 4)
            }
            .padding(.top, 16)
            .padding(.horizontal, horizontalContentInset)
        }
        .task(id: subjectPickerItem) {
            await loadSubjectPhotoIfNeeded()
        }
        .task(id: backgroundPickerItem) {
            await loadBackgroundPhotoIfNeeded()
        }
    }

    private var masthead: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Kicker(text: "Cinematic photo coach")
                Spacer()
                Text("iOS MVP")
                    .font(FilmPostType.mono(.caption))
                    .foregroundStyle(FilmPostTheme.slate)
            }

            Text("Build the shot\nbefore you shoot.")
                .font(FilmPostType.display(.largeTitle, weight: .semibold))
                .foregroundStyle(FilmPostTheme.ink)
                .lineSpacing(2)
                .kerning(FilmPostType.displayKerning)

            Text("Choose one subject photo and one background photo. FilmPost turns the pair into three cinematic directions with pose, framing, color, distance, and light.")
                .font(FilmPostType.body(.subheadline, weight: .regular))
                .foregroundStyle(FilmPostTheme.slate)
                .lineSpacing(4)
                .padding(.top, 4)
        }
    }

    private var featureHighlights: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 10) {
                FeatureBadge(
                    icon: "camera.aperture",
                    title: "Coach, not filter",
                    subtitle: "Advice before the shutter."
                )
                FeatureBadge(
                    icon: "rectangle.3.group",
                    title: "Three tailored looks",
                    subtitle: "Grounded in both images."
                )
            }

            VStack(spacing: 10) {
                FeatureBadge(
                    icon: "camera.aperture",
                    title: "Coach, not filter",
                    subtitle: "Advice before the shutter."
                )
                FeatureBadge(
                    icon: "rectangle.3.group",
                    title: "Three tailored looks",
                    subtitle: "Grounded in both images."
                )
            }
        }
        .accessibilityElement(children: .combine)
#if DEBUG
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.9) {
            runDebugDemo()
        }
#endif
    }

    private func analyzeImages() {
        Task { await model.analyze() }
    }

    private func loadSubjectPhotoIfNeeded() async {
        guard subjectPickerItem != nil else { return }
        await model.loadPhoto(from: subjectPickerItem, role: .subject)
    }

    private func loadBackgroundPhotoIfNeeded() async {
        guard backgroundPickerItem != nil else { return }
        await model.loadPhoto(from: backgroundPickerItem, role: .background)
    }

    private func runDebugDemo() {
        Task { await model.loadDebugSamplesAndAnalyze() }
    }
}

private struct FeatureBadge: View {
    let icon: String
    let title: String
    let subtitle: String

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(FilmPostTheme.amber)
                .frame(width: 28, height: 28)
                .background(
                    Circle()
                        .fill(FilmPostTheme.panel.opacity(0.62))
                )

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(FilmPostType.body(.footnote, weight: .semibold))
                    .foregroundStyle(FilmPostTheme.ink)

                Text(subtitle)
                    .font(FilmPostType.body(.caption))
                    .foregroundStyle(FilmPostTheme.slate)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .editorialCard(cornerRadius: 20)
    }
}
