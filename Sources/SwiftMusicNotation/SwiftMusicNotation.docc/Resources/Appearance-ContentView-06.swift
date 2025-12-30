import SwiftUI
import SwiftMusicNotation

struct ContentView: View {
    @State private var score: Score?
    @State private var isLoading = true
    @State private var errorMessage: String?

    let layoutContext = LayoutContext.letterSize(staffHeight: 40)

    // Create a custom render configuration
    var renderConfig: RenderConfiguration {
        var config = RenderConfiguration()

        // Light mode defaults (black on white)
        config.backgroundColor = CGColor(gray: 1, alpha: 1)  // White
        config.staffLineColor = CGColor(gray: 0, alpha: 1)   // Black
        config.barlineColor = CGColor(gray: 0, alpha: 1)     // Black
        config.noteColor = CGColor(gray: 0, alpha: 1)        // Black

        return config
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading score...")
            } else if let score {
                ScoreViewRepresentable(
                    score: .constant(score),
                    layoutContext: layoutContext,
                    renderConfiguration: renderConfig
                )
            } else if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
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
                errorMessage = "File not found"
                isLoading = false
                return
            }
            score = try importer.importScore(from: url)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}
