import SwiftUI
import SwiftMusicNotation
import MusicXMLExport

struct ContentView: View {
    @State private var score: Score?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showingExportSettings = false

    // Export settings
    @State private var selectedPreset: ExportPreset = .standard
    @State private var customVersion = "4.0"
    @State private var includeDoctype = true
    @State private var addSignature = true

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
                        Button("Export Settings...") {
                            showingExportSettings = true
                        }
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    .disabled(score == nil)
                }
            }
            .sheet(isPresented: $showingExportSettings) {
                NavigationStack {
                    ExportSettingsView(
                        selectedPreset: $selectedPreset,
                        customVersion: $customVersion,
                        includeDoctype: $includeDoctype,
                        addSignature: $addSignature
                    )
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") {
                                showingExportSettings = false
                            }
                        }
                    }
                }
            }
        }
        .task {
            await loadScore()
        }
    }

    private func exportToMusicXML() {
        guard let score else { return }

        // Build configuration from current settings
        var config = ExportConfiguration()
        config.musicXMLVersion = customVersion
        config.includeDoctype = includeDoctype
        config.addEncodingSignature = addSignature

        let exporter = MusicXMLExporter(config: config)

        // ... export implementation
    }

    private func loadScore() async {
        // ... loading code unchanged
    }
}
