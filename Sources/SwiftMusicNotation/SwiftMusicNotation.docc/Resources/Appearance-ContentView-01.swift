import SwiftUI
import SwiftMusicNotation

struct ContentView: View {
    @State private var score: Score?
    @State private var isLoading = true
    @State private var errorMessage: String?

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
