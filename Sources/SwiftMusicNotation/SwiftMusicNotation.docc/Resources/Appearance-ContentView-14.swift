import SwiftUI
import SwiftMusicNotation

struct ContentView: View {
    @State private var score: Score?
    @State private var isLoading = true
    @State private var errorMessage: String?

    let layoutContext = LayoutContext.letterSize(staffHeight: 40)

    // Customize vertical spacing
    var verticalConfig: VerticalSpacingConfiguration {
        var config = VerticalSpacingConfiguration()

        // Distance between staves within a part (e.g., piano grand staff)
        config.staffDistance = 70.0  // Default is 60.0

        // Distance between different parts
        config.partDistance = 90.0   // Default is 80.0

        // Distance between systems (lines of music)
        config.systemDistance = 90.0 // Default is 80.0

        // Padding above and below system content
        config.systemTopPadding = 25.0    // Default is 20.0
        config.systemBottomPadding = 25.0 // Default is 20.0

        // Minimum clearance between staves (for collision avoidance)
        config.minimumStaffClearance = 15.0  // Default is 10.0

        return config
    }

    var layoutConfig: LayoutConfiguration {
        var config = LayoutConfiguration()
        config.verticalConfig = verticalConfig

        // Extra space at top of first page for title
        config.firstPageTopOffset = 80  // Default is 60

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
