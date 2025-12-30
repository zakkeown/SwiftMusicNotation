import SwiftUI
import SwiftMusicNotation

struct ContentView: View {
    @State private var score: Score?
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var loadedFont: LoadedSMuFLFont?

    // Available fonts in the app bundle
    let availableFonts = ["Bravura", "Petaluma", "Leland"]

    // User's font selection (stored in UserDefaults)
    @AppStorage("selectedFont") private var selectedFont = "Bravura"

    let layoutContext = LayoutContext.letterSize(staffHeight: 40)

    var body: some View {
        VStack {
            // Font picker in toolbar
            HStack {
                Text("Font:")
                Picker("Font", selection: $selectedFont) {
                    ForEach(availableFonts, id: \.self) { font in
                        Text(font).tag(font)
                    }
                }
                .pickerStyle(.menu)
                .onChange(of: selectedFont) { _, newFont in
                    Task {
                        await switchFont(to: newFont)
                    }
                }

                Spacer()
            }
            .padding()

            // Score view
            Group {
                if isLoading {
                    ProgressView("Loading score...")
                } else if let score {
                    ScoreViewRepresentable(
                        score: .constant(score),
                        layoutContext: layoutContext
                    )
                } else if let error = errorMessage {
                    Text(error)
                        .foregroundStyle(.red)
                }
            }
        }
        .task {
            await loadFontAndScore()
        }
    }

    private func loadFontAndScore() async {
        do {
            loadedFont = try SMuFLFontManager.shared.loadFont(named: selectedFont)

            let importer = MusicXMLImporter()
            guard let url = Bundle.main.url(forResource: "sample", withExtension: "musicxml") else {
                errorMessage = "File not found"
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

    private func switchFont(to fontName: String) async {
        do {
            loadedFont = try SMuFLFontManager.shared.loadFont(named: fontName)
            // Force view refresh by triggering a layout recalculation
        } catch {
            errorMessage = "Failed to load font: \(error.localizedDescription)"
        }
    }
}
