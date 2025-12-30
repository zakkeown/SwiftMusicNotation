import SwiftUI
import SwiftMusicNotation

struct ContentView: View {
    @State private var score: Score?
    @State private var isLoading = true
    @State private var errorMessage: String?

    // US Letter size with 1-inch margins and 40pt staff height
    let letterContext = LayoutContext.letterSize(staffHeight: 40)

    // A4 size with 1-inch margins and 40pt staff height
    let a4Context = LayoutContext.a4Size(staffHeight: 40)

    // Smaller staff for dense scores
    let denseContext = LayoutContext.letterSize(staffHeight: 30)

    // Larger staff for educational or easy-read scores
    let largeContext = LayoutContext.letterSize(staffHeight: 50)

    // Use Letter size by default
    var layoutContext: LayoutContext { letterContext }

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
