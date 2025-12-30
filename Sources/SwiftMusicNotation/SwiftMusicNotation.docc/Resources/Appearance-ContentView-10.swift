import SwiftUI
import SwiftMusicNotation

struct ContentView: View {
    @State private var score: Score?
    @State private var isLoading = true
    @State private var errorMessage: String?

    let layoutContext = LayoutContext.letterSize(staffHeight: 40)

    // Configuration for screen display (thicker lines)
    var screenConfig: RenderConfiguration {
        var config = RenderConfiguration()
        config.backgroundColor = CGColor(gray: 1, alpha: 1)
        config.staffLineColor = CGColor(gray: 0, alpha: 1)
        config.barlineColor = CGColor(gray: 0, alpha: 1)
        config.noteColor = CGColor(gray: 0, alpha: 1)

        // Thicker lines for screen visibility
        config.staffLineThickness = 1.0      // Default is 0.8
        config.stemThickness = 1.0           // Default is 0.8
        config.thinBarlineThickness = 1.0    // Default is 0.8
        config.thickBarlineThickness = 3.5   // Default is 3.0
        config.bracketThickness = 2.5        // Default is 2.0

        return config
    }

    // Configuration for print (thinner, crisper lines)
    var printConfig: RenderConfiguration {
        var config = RenderConfiguration()
        config.backgroundColor = nil  // Transparent for print
        config.staffLineColor = CGColor(gray: 0, alpha: 1)
        config.barlineColor = CGColor(gray: 0, alpha: 1)
        config.noteColor = CGColor(gray: 0, alpha: 1)

        // Standard engraving thicknesses for print
        config.staffLineThickness = 0.5
        config.stemThickness = 0.7
        config.thinBarlineThickness = 0.5
        config.thickBarlineThickness = 2.5
        config.bracketThickness = 1.5

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
                    renderConfiguration: screenConfig
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
