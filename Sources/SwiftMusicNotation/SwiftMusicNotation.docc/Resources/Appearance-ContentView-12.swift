import SwiftUI
import SwiftMusicNotation

struct ContentView: View {
    @State private var score: Score?
    @State private var isLoading = true
    @State private var errorMessage: String?

    // Custom layout context for a landscape tablet display
    var tabletContext: LayoutContext {
        LayoutContext(
            pageSize: CGSize(width: 1024, height: 768),  // Landscape iPad
            margins: EdgeInsets(top: 40, left: 50, bottom: 40, right: 50),
            staffHeight: 45,
            fontName: "Bravura"
        )
    }

    // Custom context for single-page continuous scroll
    var scrollContext: LayoutContext {
        LayoutContext(
            pageSize: CGSize(width: 800, height: 10000),  // Tall page
            margins: EdgeInsets(top: 20, left: 30, bottom: 20, right: 30),
            staffHeight: 40,
            fontName: "Bravura"
        )
    }

    // Custom context for a small widget or thumbnail
    var thumbnailContext: LayoutContext {
        LayoutContext(
            pageSize: CGSize(width: 300, height: 200),
            margins: EdgeInsets(all: 10),
            staffHeight: 20,  // Small staff for compact display
            fontName: "Bravura"
        )
    }

    var layoutContext: LayoutContext { tabletContext }

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
