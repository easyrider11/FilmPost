import SwiftUI

struct AnalysisLoadingView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    private let horizontalContentInset: CGFloat = 12
    let subjectPhoto: SelectedPhoto?
    let backgroundPhoto: SelectedPhoto?
    /// Optional bail-out hook. Provided by `ContentView`; nil-ing it out (e.g.
    /// in previews) hides the Cancel button entirely so it doesn't render as
    /// a dead control.
    var onCancel: (() -> Void)? = nil

    @State private var scanProgress: CGFloat = 0
    @State private var activeStepIndex = 0
    @State private var didTapCancelCount = 0

    private let steps = [
        "Reading the subject",
        "Matching the location",
        "Writing the directions",
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 18) {
                loadingBadge

                header

                HStack(spacing: 12) {
                    DevelopingFrame(title: "Subject", photo: subjectPhoto, progress: scanProgress)
                    DevelopingFrame(title: "Location", photo: backgroundPhoto, progress: scanProgress)
                }

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(steps.indices, id: \.self) { index in
                        LoadingStep(
                            index: index,
                            label: steps[index],
                            state: stepState(for: index),
                            showsActivePulse: !reduceMotion
                        )

                        if index != steps.indices.last {
                            Hairline().padding(.vertical, 4)
                        }
                    }
                }
                .padding(18)
                .editorialCard(cornerRadius: 24)

                if let onCancel {
                    Button(role: .cancel) {
                        didTapCancelCount &+= 1
                        onCancel()
                    } label: {
                        Text("Cancel")
                            .font(FilmPostType.label(.subheadline, weight: .semibold))
                            .tracking(FilmPostType.labelTracking)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(FilmPostTheme.slate)
                    .overlay(
                        Capsule(style: .continuous)
                            .stroke(FilmPostTheme.slate.opacity(0.45), lineWidth: 1)
                    )
                    .padding(.top, 4)
                    .accessibilityHint("Stops the in-progress analysis and returns to your photos.")
                    // Light tactile confirmation that the cancel was heard,
                    // since the visual transition back to upload happens
                    // after the URLSession task is actually torn down.
                    .sensoryFeedback(.impact(weight: .light), trigger: didTapCancelCount)
                }
            }
            .padding(.top, 12)
            .padding(.horizontal, horizontalContentInset)
            .padding(.bottom, 24)
        }
        .onAppear {
            startScanAnimationIfNeeded()
            advanceSteps()
        }
    }

    private func stepState(for index: Int) -> LoadingStep.State {
        if index < activeStepIndex { return .complete }
        if index == activeStepIndex { return .active }
        return .pending
    }

    private func advanceSteps() {
        guard activeStepIndex < steps.count else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(reduceMotion ? .easeOut(duration: 0.16) : .smooth(duration: 0.35)) {
                if activeStepIndex < steps.count {
                    activeStepIndex += 1
                }
            }
            advanceSteps()
        }
    }

    private func startScanAnimationIfNeeded() {
        if reduceMotion {
            scanProgress = 0.52
            return
        }

        withAnimation(.linear(duration: 2.2).repeatForever(autoreverses: true)) {
            scanProgress = 1
        }
    }

    private var loadingBadge: some View {
        HStack(spacing: 10) {
            ProgressView()
                .tint(FilmPostTheme.amber)
                .scaleEffect(0.95)
            Text("ANALYZING")
                .font(FilmPostType.label(.caption, weight: .bold))
                .foregroundStyle(FilmPostTheme.ink)
                .tracking(FilmPostType.labelTracking)
            AnimatedDots()
                .foregroundStyle(FilmPostTheme.amber)
            Spacer()
            Text("~15s")
                .font(FilmPostType.mono(.caption2, weight: .semibold))
                .foregroundStyle(FilmPostTheme.slate)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            Capsule(style: .continuous)
                .fill(FilmPostTheme.amber.opacity(0.10))
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(FilmPostTheme.amber.opacity(0.45), lineWidth: 1)
                )
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Analyzing, please wait")
    }

    private var header: some View {
        Text("Three directions, coming up.")
            .font(FilmPostType.display(.title, weight: .semibold))
            .foregroundStyle(FilmPostTheme.ink)
            .kerning(-0.4)
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityAddTraits(.isHeader)
    }
}

private struct DevelopingFrame: View {
    let title: String
    let photo: SelectedPhoto?
    let progress: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(title)
                    .font(FilmPostType.body(.footnote, weight: .semibold))
                    .foregroundStyle(FilmPostTheme.ink)
                Spacer()
                AspectRatioTag(text: "DEV.")
            }

            GeometryReader { geo in
                ZStack(alignment: .topLeading) {
                    Group {
                        if let photo {
                            Image(uiImage: photo.previewImage)
                                .resizable()
                                .scaledToFill()
                                .saturation(0.40)
                                .overlay(FilmPostTheme.ink.opacity(0.38))
                        } else {
                            Rectangle()
                                .fill(FilmPostTheme.mist)
                        }
                    }
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))

                    // horizontal scan line
                    LinearGradient(
                        colors: [
                            FilmPostTheme.amber.opacity(0),
                            FilmPostTheme.amber.opacity(0.9),
                            FilmPostTheme.amber.opacity(0),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: geo.size.width, height: 22)
                    .offset(y: progress * (geo.size.height - 22))
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
                }
            }
            .frame(height: 144)
            .accessibilityLabel("\(title) image developing")
        }
        .padding(14)
        .editorialCard(cornerRadius: 22)
    }
}

private struct AnimatedDots: View {
    @State private var phase: Int = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .frame(width: 5, height: 5)
                    .opacity(opacity(for: i))
            }
        }
        .onAppear {
            guard !reduceMotion else { return }
            Timer.scheduledTimer(withTimeInterval: 0.45, repeats: true) { _ in
                phase = (phase + 1) % 3
            }
        }
        .accessibilityHidden(true)
    }

    private func opacity(for index: Int) -> Double {
        if reduceMotion { return 0.85 }
        return index == phase ? 1.0 : 0.30
    }
}

private struct LoadingStep: View {
    enum State { case pending, active, complete }

    let index: Int
    let label: String
    let state: State
    let showsActivePulse: Bool

    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            Text(String(format: "%02d", index + 1))
                .font(FilmPostType.mono(.caption, weight: .semibold))
                .foregroundStyle(state == .pending ? FilmPostTheme.slate.opacity(0.5) : FilmPostTheme.ink)
                .frame(width: 28, alignment: .leading)

            Text(label)
                .font(FilmPostType.body(.subheadline, weight: .medium))
                .foregroundStyle(state == .pending ? FilmPostTheme.slate.opacity(0.55) : FilmPostTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)

            indicator
        }
        .padding(.vertical, 8)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var indicator: some View {
        switch state {
        case .pending:
            Circle()
                .stroke(FilmPostTheme.slate.opacity(0.35), lineWidth: 1.2)
                .frame(width: 16, height: 16)
        case .active:
            ZStack {
                Circle()
                    .fill(FilmPostTheme.amber.opacity(0.18))
                    .frame(width: 24, height: 24)
                Circle()
                    .fill(FilmPostTheme.amber)
                    .frame(width: 10, height: 10)
            }
            .symbolEffect(.pulse, options: showsActivePulse ? .repeating : .nonRepeating)
        case .complete:
            ZStack {
                Circle()
                    .fill(FilmPostTheme.verdigris)
                    .frame(width: 20, height: 20)
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(FilmPostTheme.paper)
            }
        }
    }
}
