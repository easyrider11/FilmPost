import SwiftUI

struct AnalysisLoadingView: View {
    let subjectPhoto: SelectedPhoto?
    let backgroundPhoto: SelectedPhoto?

    @State private var animatePulse = false
    @State private var activeStepIndex = 0

    private let steps = [
        "Scanning subject posture",
        "Matching location to framing",
        "Formatting direction cards",
    ]

    var body: some View {
        VStack(spacing: 22) {
            Spacer(minLength: 12)

            HStack(spacing: 14) {
                LoadingPreviewCard(title: "Subject", photo: subjectPhoto)
                LoadingPreviewCard(title: "Background", photo: backgroundPhoto)
            }

            VStack(spacing: 14) {
                spinner

                Text("Building three shootable directions")
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(FilmPostTheme.ink)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                Text("Reading posture, environment, perspective, and light so the advice stays grounded in both images.")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(FilmPostTheme.slate)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 10)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Analyzing your photos")
            .accessibilityAddTraits(.updatesFrequently)

            VStack(alignment: .leading, spacing: 12) {
                ForEach(steps.indices, id: \.self) { index in
                    LoadingStep(
                        label: steps[index],
                        state: stepState(for: index)
                    )
                }
            }
            .padding(18)
            .glassCard()

            Spacer()
        }
        .onAppear {
            withAnimation(.linear(duration: 1.4).repeatForever(autoreverses: false)) {
                animatePulse = true
            }
            advanceSteps()
        }
    }

    private var spinner: some View {
        ZStack {
            Circle()
                .stroke(FilmPostTheme.slate.opacity(0.14), lineWidth: 12)

            Circle()
                .trim(from: 0.05, to: 0.82)
                .stroke(
                    AngularGradient(
                        colors: [FilmPostTheme.ink, FilmPostTheme.amber, FilmPostTheme.ink],
                        center: .center
                    ),
                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                )
                .rotationEffect(.degrees(animatePulse ? 360 : 0))
        }
        .frame(width: 78, height: 78)
        .padding(.bottom, 4)
    }

    private func stepState(for index: Int) -> LoadingStep.State {
        if index < activeStepIndex { return .complete }
        if index == activeStepIndex { return .active }
        return .pending
    }

    private func advanceSteps() {
        guard activeStepIndex < steps.count else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
            withAnimation(.smooth(duration: 0.35)) {
                if activeStepIndex < steps.count {
                    activeStepIndex += 1
                }
            }
            advanceSteps()
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
                .textCase(.uppercase)
                .tracking(0.6)

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
                                .font(.system(size: 22))
                                .foregroundStyle(FilmPostTheme.slate.opacity(0.7))
                        }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 152)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .accessibilityLabel("\(title) image")
        }
        .padding(14)
        .glassCard()
    }
}

private struct LoadingStep: View {
    enum State { case pending, active, complete }

    let label: String
    let state: State

    var body: some View {
        HStack(spacing: 12) {
            indicator
                .frame(width: 18, height: 18)

            Text(label)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(state == .pending ? FilmPostTheme.slate.opacity(0.55) : FilmPostTheme.ink)
                .strikethrough(state == .complete, color: FilmPostTheme.slate.opacity(0.35))
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var indicator: some View {
        switch state {
        case .pending:
            Circle()
                .stroke(FilmPostTheme.slate.opacity(0.35), lineWidth: 1.5)
        case .active:
            Circle()
                .fill(FilmPostTheme.amber)
                .overlay(
                    Circle()
                        .stroke(FilmPostTheme.amber.opacity(0.35), lineWidth: 6)
                        .scaleEffect(1.6)
                )
        case .complete:
            ZStack {
                Circle().fill(FilmPostTheme.ink)
                Image(systemName: "checkmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.white)
            }
        }
    }
}
