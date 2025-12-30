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
        // Export implementation coming next
    }

    private func loadScore() async {
        // ... loading code unchanged
    }
}
