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
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Plan the image before you take it.")
                        .font(.system(size: 31, weight: .semibold, design: .rounded))
                        .foregroundStyle(FilmPostTheme.ink)

                    Text("Pair one subject photo with one location photo. FilmPost turns that combination into three cinematic directions with pose, framing, distance, and light.")
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(FilmPostTheme.slate)
                        .lineSpacing(3)
                }

                HStack(spacing: 10) {
                    Label("No filters", systemImage: "camera.aperture")
                    Label("3 clear directions", systemImage: "rectangle.on.rectangle.angled")
                }
                .font(.system(.caption, design: .rounded, weight: .semibold))
                .foregroundStyle(FilmPostTheme.slate)
#if DEBUG
                .contentShape(Rectangle())
                .onLongPressGesture(minimumDuration: 0.9) {
                    Task {
                        await model.loadDebugSamplesAndAnalyze()
                    }
                }
#endif

                PhotosPicker(
                    selection: $subjectPickerItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    ImageSlotCard(role: .subject, photo: subjectPhoto)
                }
                .buttonStyle(.plain)

                PhotosPicker(
                    selection: $backgroundPickerItem,
                    matching: .images,
                    photoLibrary: .shared()
                ) {
                    ImageSlotCard(role: .background, photo: backgroundPhoto)
                }
                .buttonStyle(.plain)

                Button {
                    Task {
                        await model.analyze()
                    }
                } label: {
                    HStack(spacing: 10) {
                        Text("Analyze")
                        Image(systemName: "sparkles")
                    }
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(
                        LinearGradient(
                            colors: [FilmPostTheme.ink, FilmPostTheme.slate.opacity(0.92)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                    )
                    .foregroundStyle(Color.white)
                    .shadow(color: FilmPostTheme.ink.opacity(0.12), radius: 14, x: 0, y: 9)
                }
                .buttonStyle(.plain)
                .disabled(!canAnalyze)
                .opacity(canAnalyze ? 1 : 0.45)

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
}
