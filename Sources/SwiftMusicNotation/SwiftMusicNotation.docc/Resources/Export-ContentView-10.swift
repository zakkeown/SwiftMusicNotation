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

    // PDF export settings
    @State private var pdfBackgroundColor: Color = .white
    @State private var pdfStaffHeight: Double = 40

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
                        Button("Export PDF") {
                            exportToPDF()
                        }
                        Button("Export PDF (Sepia)") {
                            exportToPDF(background: CGColor(red: 1, green: 0.98, blue: 0.9, alpha: 1))
                        }
                        Button("Export PDF (Large Print)") {
                            exportToPDF(staffHeight: 55)
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

    private func exportToPDF(
        background: CGColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1),
        staffHeight: CGFloat = 40
    ) {
        guard let score,
              let font = SMuFLFontManager.shared.currentFont else {
            return
        }

        do {
            // Re-layout if staff height changed
            let context = LayoutContext.letterSize(staffHeight: staffHeight)
            let layoutEngine = LayoutEngine()
            let layoutScore = layoutEngine.layout(score: score, context: context)

            // Configure export appearance
            var exportConfig = MusicNotationRenderer.ExportConfiguration()
            exportConfig.backgroundColor = background
            exportConfig.foregroundColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
            exportConfig.staffHeight = staffHeight

            let exportEngine = ExportEngine(
                engravedScore: layoutScore,
                font: font,
                config: exportConfig
            )

            let pdfData = try exportEngine.exportPDF()

            // Save to file
            let documentsURL = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first!

            let filename = (score.metadata.workTitle ?? "Score") + ".pdf"
            let outputURL = documentsURL.appendingPathComponent(filename)

            try pdfData.write(to: outputURL)

        } catch {
            exportError = error.localizedDescription
        }
    }

    private func loadScore() async {
        // ... loading code
    }
}
