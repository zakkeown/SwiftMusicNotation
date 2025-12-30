import SwiftUI
import SwiftMusicNotation
import Combine

struct ContentView: View {
    @State private var score: Score?
    @State private var isLoading = true
    @State private var errorMessage: String?

    @StateObject private var playbackEngine = PlaybackEngine()

    @State private var cancellables = Set<AnyCancellable>()
    @State private var highlightedMeasure: Int = 0

    // ScrollView proxy for programmatic scrolling
    @Namespace private var scrollNamespace

    let layoutContext = LayoutContext.letterSize(staffHeight: 40)

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading score...")
                } else if let score {
                    VStack {
                        // Scrollable score view
                        ScrollViewReader { proxy in
                            ScrollView([.horizontal, .vertical]) {
                                ZStack {
                                    ScoreViewRepresentable(
                                        score: .constant(score),
                                        layoutContext: layoutContext
                                    )
                                    .id("score")

                                    // Measure highlights with IDs for scrolling
                                    ForEach(1...(score.parts.first?.measures.count ?? 1), id: \.self) { measure in
                                        Color.clear
                                            .frame(width: 1, height: 1)
                                            .id("measure-\(measure)")
                                    }

                                    if highlightedMeasure > 0 {
                                        MeasureHighlight(
                                            measureNumber: highlightedMeasure,
                                            totalMeasures: score.parts.first?.measures.count ?? 0
                                        )
                                    }
                                }
                            }
                            .onChange(of: highlightedMeasure) { _, newMeasure in
                                // Auto-scroll to keep current measure visible
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    proxy.scrollTo("measure-\(newMeasure)", anchor: .center)
                                }
                            }
                        }

                        Divider()

                        // Playback controls at the bottom
                        PlaybackControls(
                            engine: playbackEngine,
                            totalMeasures: score.parts.first?.measures.count ?? 0
                        )
                    }
                } else if let error = errorMessage {
                    ContentUnavailableView(
                        "Unable to Load Score",
                        systemImage: "music.note",
                        description: Text(error)
                    )
                }
            }
            .navigationTitle("Score Player")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    // Follow playback toggle
                    Toggle(isOn: .constant(true)) {
                        Label("Follow", systemImage: "scope")
                    }
                }
            }
        }
        .task {
            await loadScore()
        }
        .onAppear {
            subscribeToPlaybackEvents()
        }
    }

    private func subscribeToPlaybackEvents() {
        playbackEngine.events
            .receive(on: DispatchQueue.main)
            .sink { event in
                switch event {
                case .positionChanged(let measure, _):
                    highlightedMeasure = measure

                case .stopped:
                    highlightedMeasure = 0

                default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    private func loadScore() async {
        do {
            _ = try SMuFLFontManager.shared.loadFont(named: "Bravura")

            let importer = MusicXMLImporter()
            guard let url = Bundle.main.url(forResource: "sample", withExtension: "musicxml") else {
                errorMessage = "Sample file not found"
                isLoading = false
                return
            }
            let loadedScore = try importer.importScore(from: url)
            score = loadedScore
            isLoading = false

            try await playbackEngine.load(loadedScore)
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
