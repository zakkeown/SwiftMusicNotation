import SwiftUI
import SwiftMusicNotation
import MusicXMLExport

struct ContentView: View {
    @State private var score: Score?
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
                    Button("Export") {
                        exportToMusicXML()
                    }
                    .disabled(score == nil)
                }
            }
        }
        .task {
            await loadScore()
        }
    }

    private func exportToMusicXML() {
        guard let score else { return }

        let exporter = MusicXMLExporter()

        // Get the Documents directory
        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!

        // Create the output filename
        let filename = (score.metadata.workTitle ?? "Untitled") + ".musicxml"
        let outputURL = documentsURL.appendingPathComponent(filename)

        // Export the score
        try? exporter.export(score, to: outputURL)

        print("Exported to: \(outputURL.path)")
    }

    private func loadScore() async {
        // ... loading code unchanged
    }
}
