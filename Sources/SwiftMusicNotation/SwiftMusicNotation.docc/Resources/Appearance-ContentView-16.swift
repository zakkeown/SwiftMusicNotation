import SwiftUI
import SwiftMusicNotation

struct ContentView: View {
    @State private var score: Score?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var showSettings = false
    @State private var refreshTrigger = UUID()

    // Shared appearance settings
    @State private var settings = AppearanceSettings()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("Loading score...")
                } else if let score {
                    ScoreViewRepresentable(
                        score: .constant(score),
                        layoutContext: settings.layoutContext,
                        layoutConfiguration: settings.layoutConfiguration,
                        renderConfiguration: settings.renderConfiguration
                    )
                    .id(refreshTrigger)  // Force refresh when settings change
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
                    Button {
                        showSettings = true
                    } label: {
                        Label("Settings", systemImage: "gear")
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                // Refresh the score view when settings sheet is dismissed
                refreshTrigger = UUID()
            } content: {
                SettingsView(settings: settings)
            }
        }
        .task {
            await loadScore()
        }
    }

    private func loadScore() async {
        do {
            // Load the selected font
            _ = try SMuFLFontManager.shared.loadFont(named: settings.selectedFontName)

            // Load the score
            let importer = MusicXMLImporter()
            guard let url = Bundle.main.url(forResource: "sample", withExtension: "musicxml") else {
                errorMessage = "Sample file not found in bundle"
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

#Preview {
    ContentView()
}
