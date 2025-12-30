import SwiftUI
import SwiftMusicNotation

struct ContentView: View {
    @State private var score: Score?
    @State private var isLoading = true
    @State private var errorMessage: String?

    @Environment(\.colorScheme) private var colorScheme

    let layoutContext = LayoutContext.letterSize(staffHeight: 40)

    // Custom color scheme with sepia/cream background
    var sepiaConfig: RenderConfiguration {
        var config = RenderConfiguration()

        // Warm cream background (like aged paper)
        config.backgroundColor = CGColor(
            red: 0.98, green: 0.96, blue: 0.90, alpha: 1
        )

        // Dark brown for notation (softer than pure black)
        let notationColor = CGColor(
            red: 0.2, green: 0.15, blue: 0.1, alpha: 1
        )
        config.noteColor = notationColor
        config.barlineColor = notationColor

        // Slightly lighter brown for staff lines
        config.staffLineColor = CGColor(
            red: 0.35, green: 0.3, blue: 0.25, alpha: 1
        )

        return config
    }

    // High contrast for accessibility
    var highContrastConfig: RenderConfiguration {
        var config = RenderConfiguration()

        // Pure white background
        config.backgroundColor = CGColor(gray: 1, alpha: 1)

        // Pure black for all elements
        let black = CGColor(gray: 0, alpha: 1)
        config.noteColor = black
        config.staffLineColor = black
        config.barlineColor = black

        // Thicker lines for visibility
        config.staffLineThickness = 1.2
        config.stemThickness = 1.0
        config.thinBarlineThickness = 1.0

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
                    renderConfiguration: sepiaConfig  // Try different configs
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
