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
    @State private var exportError: String?

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
            .alert("Export Failed", isPresented: .constant(exportError != nil)) {
                Button("OK") { exportError = nil }
            } message: {
                Text(exportError ?? "Unknown error")
            }
        }
        .task {
            await loadScore()
        }
    }

    private func exportToPDF() {
        guard let engravedScore,
              let font = SMuFLFontManager.shared.currentFont else {
            exportError = "Score not ready for export"
            return
        }

        do {
            // Create the export engine
            let exportEngine = ExportEngine(
                engravedScore: engravedScore,
                font: font
            )

            // Generate PDF data
            let pdfData = try exportEngine.exportPDF()

            // Save to Documents directory
            let documentsURL = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first!

            let filename = (score?.metadata.workTitle ?? "Score") + ".pdf"
            let outputURL = documentsURL.appendingPathComponent(filename)

            try pdfData.write(to: outputURL)
            print("Exported PDF to: \(outputURL.path)")

        } catch let error as ExportError {
            exportError = error.localizedDescription
        } catch {
            exportError = error.localizedDescription
        }
    }

    private func loadScore() async {
        // ... loading code
    }

    private func exportToMusicXML() {
        // ... MusicXML export
    }
}
