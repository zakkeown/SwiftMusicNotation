import SwiftUI
import SwiftMusicNotation

struct ContentView: View {
    @State private var score: Score?
    @State private var isLoading = true
    @State private var errorMessage: String?

    @StateObject private var playbackEngine = PlaybackEngine()

    let layoutContext = LayoutContext.letterSize(staffHeight: 40)

    var body: some View {
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

            // Load the score into the playback engine
            // This initializes the MIDI synthesizer and prepares the event sequence
            try await playbackEngine.load(loadedScore)

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
