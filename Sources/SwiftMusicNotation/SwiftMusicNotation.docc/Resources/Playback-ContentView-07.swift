import SwiftUI
import SwiftMusicNotation
import Combine

struct ContentView: View {
    @State private var score: Score?
    @State private var isLoading = true
    @State private var errorMessage: String?

    @StateObject private var playbackEngine = PlaybackEngine()

    // Store Combine subscriptions
    @State private var cancellables = Set<AnyCancellable>()

    let layoutContext = LayoutContext.letterSize(staffHeight: 40)

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading score...")
                } else if let score {
                    VStack {
                        ScoreViewRepresentable(
                            score: .constant(score),
                            layoutContext: layoutContext
                        )

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
                case .started:
                    print("Playback started")

                case .paused:
                    print("Playback paused")

                case .stopped:
                    print("Playback stopped")

                case .positionChanged(let measure, let beat):
                    print("Position: measure \(measure), beat \(beat)")

                case .tempoChanged(let bpm):
                    print("Tempo changed to \(bpm) BPM")

                case .error(let error):
                    print("Playback error: \(error)")
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
