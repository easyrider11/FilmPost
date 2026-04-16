import SwiftUI

struct ContentView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var model = AppModel()
    @State private var hasStartedDebugAutoDemo = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                CinematicBackdrop()
                    .ignoresSafeArea()

                screen
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                    .animation(reduceMotion ? .easeInOut(duration: 0.18) : .smooth(duration: 0.32), value: model.currentScreen)
            }
            .task {
                await runDebugAutoDemoIfNeeded()
            }
            .toolbarBackground(FilmPostTheme.paper.opacity(0.94), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("FilmPost")
                        .font(FilmPostType.body(.subheadline, weight: .semibold))
                        .foregroundStyle(FilmPostTheme.ink)
                        .accessibilityAddTraits(.isHeader)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if model.currentScreen == .upload, model.subjectPhoto != nil || model.backgroundPhoto != nil {
                        Button("Reset", action: resetSelections)
                        .font(FilmPostType.body(.footnote, weight: .medium))
                        .tint(FilmPostTheme.ink)
                        .accessibilityHint("Clears the selected subject and background images")
                    }
                }
            }
        }
        .alert(
            "Couldn't develop that take",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            ),
            actions: {
                if model.canAnalyze {
                    Button("Retry", action: retryAnalysis)
                }
                Button("OK", role: .cancel) {}
            },
            message: {
                Text(model.errorMessage ?? "")
            }
        )
    }

    @ViewBuilder
    private var screen: some View {
        switch model.currentScreen {
        case .upload:
            UploadView(model: model)
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .leading)))
        case .loading:
            AnalysisLoadingView(
                subjectPhoto: model.subjectPhoto,
                backgroundPhoto: model.backgroundPhoto
            )
            .transition(.opacity)
        case .results:
            if let analysis = model.analysis {
                ResultsView(
                    analysis: analysis,
                    subjectPhoto: model.subjectPhoto,
                    backgroundPhoto: model.backgroundPhoto,
                    onAnalyzeAnother: model.startOver,
                    onResetAll: model.resetSelections
                )
                .transition(reduceMotion ? .opacity : .opacity.combined(with: .move(edge: .trailing)))
            }
        }
    }

    private func retryAnalysis() {
        Task { await model.analyze() }
    }

    private func resetSelections() {
        model.resetSelections()
    }

    private func runDebugAutoDemoIfNeeded() async {
#if DEBUG
        guard !hasStartedDebugAutoDemo, DebugLaunchOptions.shouldAutoRunDemo() else { return }
        hasStartedDebugAutoDemo = true
        await model.loadDebugSamplesAndAnalyze()
#endif
    }
}

#Preview {
    ContentView()
}
