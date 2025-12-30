import SwiftUI
import SwiftMusicNotation

struct ContentView: View {
    @State private var score: Score?
    @State private var isLoading = true
    @State private var errorMessage: String?

    @StateObject private var playbackEngine = PlaybackEngine()

    let layoutContext = LayoutContext.letterSize(staffHeight: 40)

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading score...")
                } else if let score {
                    ScoreViewRepresentable(
                        score: .constant(score),
                        layoutContext: layoutContext
                    )
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
                ToolbarItemGroup(placement: .primaryAction) {
                    if playbackEngine.isLoaded {
                        // Stop button
                        Button {
                            playbackEngine.stop()
                        } label: {
                            Image(systemName: "stop.fill")
                        }
                        .disabled(playbackEngine.state == .stopped)

                        // Play/Pause button
                        Button {
                            togglePlayback()
                        } label: {
                            Image(systemName: playbackEngine.state == .playing ? "pause.fill" : "play.fill")
                        }
                    }
                }
            }
        }
        .task {
            await loadScore()
        }
    }

    private func togglePlayback() {
        do {
            if playbackEngine.state == .playing {
                playbackEngine.pause()
            } else {
                try playbackEngine.play()
            }
        } catch {
            print("Playback error: \(error)")
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

            try await playbackEngine.load(loadedScore)
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
