import SwiftUI

struct ContentView: View {
    @State private var model = AppModel()
    @State private var hasStartedDebugAutoDemo = false

    var body: some View {
        NavigationStack {
            ZStack(alignment: .top) {
                CinematicBackdrop()
                    .ignoresSafeArea()

                Group {
                    switch model.currentScreen {
                    case .upload:
                        UploadView(model: model)
                    case .loading:
                        AnalysisLoadingView(subjectPhoto: model.subjectPhoto, backgroundPhoto: model.backgroundPhoto)
                    case .results:
                        if let analysis = model.analysis {
                            ResultsView(
                                analysis: analysis,
                                subjectPhoto: model.subjectPhoto,
                                backgroundPhoto: model.backgroundPhoto,
                                onAnalyzeAnother: model.startOver,
                                onResetAll: model.resetSelections
                            )
                        }
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 24)
                .animation(.snappy(duration: 0.35), value: model.currentScreen)
            }
            .task {
#if DEBUG
                guard !hasStartedDebugAutoDemo, DebugLaunchOptions.shouldAutoRunDemo() else { return }
                hasStartedDebugAutoDemo = true
                await model.loadDebugSamplesAndAnalyze()
#endif
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("FilmPost")
                        .font(.system(.title3, design: .rounded, weight: .semibold))
                        .foregroundStyle(FilmPostTheme.ink)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    if model.currentScreen == .upload, model.subjectPhoto != nil || model.backgroundPhoto != nil {
                        Button("Reset") {
                            model.resetSelections()
                        }
                        .tint(FilmPostTheme.ink)
                    }
                }
            }
        }
        .alert(
            "Analysis couldn't finish",
            isPresented: Binding(
                get: { model.errorMessage != nil },
                set: { if !$0 { model.errorMessage = nil } }
            ),
            actions: {
                if model.canAnalyze {
                    Button("Retry") {
                        Task {
                            await model.analyze()
                        }
                    }
                }

                Button("OK", role: .cancel) {}
            },
            message: {
                Text(model.errorMessage ?? "")
            }
        )
    }
}

#Preview {
    ContentView()
}
