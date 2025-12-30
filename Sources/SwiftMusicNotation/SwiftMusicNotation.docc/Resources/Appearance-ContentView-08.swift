import SwiftUI
import SwiftMusicNotation

struct ContentView: View {
    @State private var score: Score?
    @State private var isLoading = true
    @State private var errorMessage: String?

    // Detect system color scheme
    @Environment(\.colorScheme) private var colorScheme

    let layoutContext = LayoutContext.letterSize(staffHeight: 40)

    // Choose configuration based on color scheme
    var renderConfig: RenderConfiguration {
        switch colorScheme {
        case .dark:
            return darkModeConfig
        case .light:
            return lightModeConfig
        @unknown default:
            return lightModeConfig
        }
    }

    var lightModeConfig: RenderConfiguration {
        var config = RenderConfiguration()
        config.backgroundColor = CGColor(gray: 1, alpha: 1)
        config.staffLineColor = CGColor(gray: 0, alpha: 1)
        config.barlineColor = CGColor(gray: 0, alpha: 1)
        config.noteColor = CGColor(gray: 0, alpha: 1)
        return config
    }

    var darkModeConfig: RenderConfiguration {
        var config = RenderConfiguration()
        config.backgroundColor = CGColor(gray: 0.1, alpha: 1)
        config.staffLineColor = CGColor(gray: 0.85, alpha: 1)
        config.barlineColor = CGColor(gray: 0.85, alpha: 1)
        config.noteColor = CGColor(gray: 0.95, alpha: 1)
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
