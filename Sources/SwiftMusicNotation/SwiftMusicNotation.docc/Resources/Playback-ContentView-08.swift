import SwiftUI
import SwiftMusicNotation
import Combine

struct ContentView: View {
    @State private var score: Score?
    @State private var isLoading = true
    @State private var errorMessage: String?

    @StateObject private var playbackEngine = PlaybackEngine()

    @State private var cancellables = Set<AnyCancellable>()

    // Track the currently highlighted measure
    @State private var highlightedMeasure: Int = 0

    let layoutContext = LayoutContext.letterSize(staffHeight: 40)

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading score...")
                } else if let score {
                    VStack {
                        ZStack {
                            ScoreViewRepresentable(
                                score: .constant(score),
                                layoutContext: layoutContext
                            )

                            // Overlay highlighting the current measure
                            if highlightedMeasure > 0 {
                                MeasureHighlight(
                                    measureNumber: highlightedMeasure,
                                    totalMeasures: score.parts.first?.measures.count ?? 0
                                )
                            }
                        }

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
                    // Update the highlighted measure
                    highlightedMeasure = measure

                case .stopped:
                    // Clear highlight when stopped
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
