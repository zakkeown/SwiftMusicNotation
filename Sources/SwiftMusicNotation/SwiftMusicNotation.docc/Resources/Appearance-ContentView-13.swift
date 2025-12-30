import SwiftUI
import SwiftMusicNotation

struct ContentView: View {
    @State private var score: Score?
    @State private var isLoading = true
    @State private var errorMessage: String?

    let layoutContext = LayoutContext.letterSize(staffHeight: 40)

    // Customize horizontal spacing
    var spacingConfig: SpacingConfiguration {
        var config = SpacingConfiguration()

        // Base width for a quarter note (in points)
        config.quarterNoteSpacing = 35.0  // Default is 30.0

        // Logarithmic spacing factor
        // 0.0 = linear (all durations spaced equally)
        // 0.7 = standard (default)
        // 1.0+ = more contrast between short and long notes
        config.spacingFactor = 0.8

        // Minimum space between any two events
        config.minimumNoteSpacing = 15.0  // Default is 12.0

        // Padding at measure boundaries
        config.measureLeftPadding = 6.0   // Default is 4.0
        config.measureRightPadding = 6.0  // Default is 4.0

        return config
    }

    var layoutConfig: LayoutConfiguration {
        var config = LayoutConfiguration()
        config.spacingConfig = spacingConfig
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
                    layoutConfiguration: layoutConfig
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
