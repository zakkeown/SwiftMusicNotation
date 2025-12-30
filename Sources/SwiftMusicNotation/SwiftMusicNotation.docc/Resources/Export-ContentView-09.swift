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
    @State private var pdfDataToShare: Data?
    @State private var showingShareSheet = false

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
                        Button("Share PDF...") {
                            sharePDF()
                        }
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .disabled(score == nil)
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let pdfData = pdfDataToShare {
                    ShareSheet(items: [pdfData])
                }
            }
        }
        .task {
            await loadScore()
        }
    }

    private func sharePDF() {
        guard let engravedScore,
              let font = SMuFLFontManager.shared.currentFont else {
            return
        }

        do {
            let exportEngine = ExportEngine(
                engravedScore: engravedScore,
                font: font
            )
            pdfDataToShare = try exportEngine.exportPDF()
            showingShareSheet = true
        } catch {
            exportError = error.localizedDescription
        }
    }

    // ... other methods
}

// MARK: - Share Sheet

#if os(iOS)
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#elseif os(macOS)
struct ShareSheet: View {
    let items: [Any]

    var body: some View {
        // On macOS, use NSSavePanel instead
        Text("Use File > Save As to save the PDF")
            .padding()
    }
}
#endif
