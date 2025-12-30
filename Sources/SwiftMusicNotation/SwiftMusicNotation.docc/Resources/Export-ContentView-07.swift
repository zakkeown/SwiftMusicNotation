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
            .navigationTitle("Score Viewer")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button("Export MusicXML") {
                            exportToMusicXML()
                        }
                        Divider()
                        Button("Export PDF") {
                            exportToPDF()
                        }
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .disabled(score == nil)
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

            // Also compute the engraved score for PDF export
            let layoutEngine = LayoutEngine()
            engravedScore = layoutEngine.layout(score: loadedScore, context: layoutContext)

            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    private func exportToMusicXML() {
        // ... MusicXML export implementation
    }

    private func exportToPDF() {
        // PDF export implementation coming next
    }
}
