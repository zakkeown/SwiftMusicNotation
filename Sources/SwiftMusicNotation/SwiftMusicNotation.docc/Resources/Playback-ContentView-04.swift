import SwiftUI
import SwiftMusicNotation

struct ContentView: View {
    @State private var score: Score?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var playbackReady = false

    @StateObject private var playbackEngine = PlaybackEngine()

    let layoutContext = LayoutContext.letterSize(staffHeight: 40)

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading score...")
            } else if let score {
                VStack {
                    ScoreViewRepresentable(
                        score: .constant(score),
                        layoutContext: layoutContext
                    )

                    // Show playback status
                    if playbackReady {
                        Text("Playback ready")
                            .foregroundStyle(.green)
                    } else {
                        Text("Playback not available")
                            .foregroundStyle(.secondary)
                    }
                }
            } else if let error = errorMessage {
                ContentUnavailableView(
                    "Unable to Load Score",
                    systemImage: "music.note",
                    description: Text(error)
                )
            }
        }
        .task {
            await loadScore()
        }
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

            // Load into playback engine (may fail without affecting score display)
            do {
                try await playbackEngine.load(loadedScore)
                playbackReady = true
            } catch PlaybackEngine.PlaybackError.soundBankNotFound {
                // Sound bank not available - playback won't work but score still displays
                print("Playback unavailable: Sound bank not found")
            } catch PlaybackEngine.PlaybackError.audioEngineError(let message) {
                // Audio system issue
                print("Playback unavailable: \(message)")
            }

        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
