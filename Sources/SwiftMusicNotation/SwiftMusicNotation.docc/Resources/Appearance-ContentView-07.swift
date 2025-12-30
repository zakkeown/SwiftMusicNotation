import SwiftUI
import SwiftMusicNotation

struct ContentView: View {
    @State private var score: Score?
    @State private var isLoading = true
    @State private var errorMessage: String?

    let layoutContext = LayoutContext.letterSize(staffHeight: 40)

    // Light mode configuration
    var lightModeConfig: RenderConfiguration {
        var config = RenderConfiguration()
        config.backgroundColor = CGColor(gray: 1, alpha: 1)       // White
        config.staffLineColor = CGColor(gray: 0, alpha: 1)        // Black
        config.barlineColor = CGColor(gray: 0, alpha: 1)          // Black
        config.noteColor = CGColor(gray: 0, alpha: 1)             // Black
        return config
    }

    // Dark mode configuration
    var darkModeConfig: RenderConfiguration {
        var config = RenderConfiguration()
        config.backgroundColor = CGColor(gray: 0.1, alpha: 1)     // Dark gray
        config.staffLineColor = CGColor(gray: 0.85, alpha: 1)     // Light gray
        config.barlineColor = CGColor(gray: 0.85, alpha: 1)       // Light gray
        config.noteColor = CGColor(gray: 0.95, alpha: 1)          // Near white
        return config
    }

    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading score...")
            } else if let score {
                // For now, use dark mode config
                ScoreViewRepresentable(
                    score: .constant(score),
                    layoutContext: layoutContext,
                    renderConfiguration: darkModeConfig
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
