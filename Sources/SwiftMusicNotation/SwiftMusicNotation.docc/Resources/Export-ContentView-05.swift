import SwiftUI
import SwiftMusicNotation
import MusicXMLExport

struct ContentView: View {
    @State private var score: Score?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var exportError: String?
    @State private var showingExportSuccess = false

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
            .alert("Export Successful", isPresented: $showingExportSuccess) {
                Button("OK", role: .cancel) { }
            }
            .alert("Export Failed", isPresented: .constant(exportError != nil)) {
                Button("OK", role: .cancel) { exportError = nil }
            } message: {
                Text(exportError ?? "Unknown error")
            }
        }
        .task {
            await loadScore()
        }
    }

    private func exportToMusicXML() {
        guard let score else { return }

        do {
            // Configure the exporter
            var config = ExportConfiguration()
            config.musicXMLVersion = "4.0"        // Latest version
            config.includeDoctype = true           // Include DOCTYPE declaration
            config.addEncodingSignature = true     // Add software signature

            let exporter = MusicXMLExporter(config: config)

            let documentsURL = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first!

            let filename = (score.metadata.workTitle ?? "Untitled") + ".musicxml"
            let outputURL = documentsURL.appendingPathComponent(filename)

            try exporter.export(score, to: outputURL)
            showingExportSuccess = true

        } catch let error as MusicXMLExportError {
            exportError = error.localizedDescription
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func loadScore() async {
        // ... loading code unchanged
    }
}
