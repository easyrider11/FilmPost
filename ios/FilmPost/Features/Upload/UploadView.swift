import PhotosUI
import SwiftUI

struct UploadView: View {
    @Bindable var model: AppModel
    @State private var subjectPickerItem: PhotosPickerItem?
    @State private var backgroundPickerItem: PhotosPickerItem?

    var body: some View {
        let subjectPhoto = model.subjectPhoto
        let backgroundPhoto = model.backgroundPhoto
        let canAnalyze = model.canAnalyze

        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 20) {
                header

                tagRow

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

                Button {
                    Task { await model.analyze() }
                } label: {
                    HStack(spacing: 10) {
                        Text("Analyze")
                        Image(systemName: "sparkles")
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(!canAnalyze)
                .accessibilityHint(canAnalyze
                    ? "Sends both images to FilmPost for cinematic direction"
                    : "Pick a subject and a background photo first")

                Text("Each result stays short enough to use on set and specific enough to actually direct.")
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(FilmPostTheme.slate.opacity(0.92))
                    .padding(.horizontal, 4)
            }
            .padding(.top, 8)
        }
        .task(id: subjectPickerItem) {
            guard subjectPickerItem != nil else { return }
            await model.loadPhoto(from: subjectPickerItem, role: .subject)
        }
        .task(id: backgroundPickerItem) {
            guard backgroundPickerItem != nil else { return }
            await model.loadPhoto(from: backgroundPickerItem, role: .background)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Plan the image before you take it.")
                .font(.system(.largeTitle, design: .rounded, weight: .semibold))
                .foregroundStyle(FilmPostTheme.ink)
                .lineLimit(3)

            Text("Pair one subject photo with one location photo. FilmPost turns that combination into three cinematic directions with pose, framing, distance, and light.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(FilmPostTheme.slate)
                .lineSpacing(3)
        }
    }

    private var tagRow: some View {
        HStack(spacing: 12) {
            Label("No filters", systemImage: "camera.aperture")
            Label("3 clear directions", systemImage: "rectangle.on.rectangle.angled")
        }
        .font(.system(.caption, design: .rounded, weight: .semibold))
        .foregroundStyle(FilmPostTheme.slate)
        .accessibilityElement(children: .combine)
#if DEBUG
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.9) {
            Task { await model.loadDebugSamplesAndAnalyze() }
        }
#endif
    }
}
