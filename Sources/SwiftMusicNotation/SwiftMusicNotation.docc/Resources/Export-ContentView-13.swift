import SwiftUI
import SwiftMusicNotation
import MusicXMLExport
import MusicNotationRenderer
import MusicNotationLayout

struct ContentView: View {
    @State private var score: Score?
    @State private var engravedScore: EngravedScore?
    @State private var isLoading = true
    @State private var errorMessage: String?

    @StateObject private var exportManager: ExportManager?

    let layoutContext = LayoutContext.letterSize(staffHeight: 40)

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading score...")
                } else if let score {
                    ScoreViewRepresentable(
                        score: .constant(score),
                        layoutContext: layoutContext
                    )
                } else if let error = errorMessage {
                    ContentUnavailableView(
                        "Unable to Load Score",
                        systemImage: "music.note",
                        description: Text(error)
                    )
                }
            }
            .navigationTitle(score?.metadata.workTitle ?? "Score Viewer")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    if let exportManager {
                        ExportMenu(exportManager: exportManager)
                    }
                }
            }
        }
        .task {
            await loadScore()
        }
    }

    private func loadScore() async {
        do {
            let font = try SMuFLFontManager.shared.loadFont(named: "Bravura")

            let importer = MusicXMLImporter()
            guard let url = Bundle.main.url(forResource: "sample", withExtension: "musicxml") else {
                errorMessage = "Sample file not found"
                isLoading = false
                return
            }

            let loadedScore = try importer.importScore(from: url)
            score = loadedScore

            // Compute the engraved score for PDF/image export
            let layoutEngine = LayoutEngine()
            let engraved = layoutEngine.layout(score: loadedScore, context: layoutContext)
            engravedScore = engraved

            // Initialize the export manager
            _exportManager = StateObject(wrappedValue: ExportManager(
                score: loadedScore,
                engravedScore: engraved,
                font: font
            ))

            isLoading = false

        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
}

#Preview {
    ContentView()
}
