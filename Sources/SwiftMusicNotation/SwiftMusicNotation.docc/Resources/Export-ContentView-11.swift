import SwiftUI
import SwiftMusicNotation
import MusicNotationRenderer

struct ContentView: View {
    @State private var score: Score?
    @State private var engravedScore: EngravedScore?
    @State private var exportError: String?

    var body: some View {
        NavigationStack {
            // ... score view

            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Section("MusicXML") {
                            Button("Export MusicXML") { exportToMusicXML() }
                        }
                        Section("PDF") {
                            Button("Export PDF") { exportToPDF() }
                        }
                        Section("Images") {
                            Button("Export PNG") { exportToPNG() }
                        }
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    private func exportToPNG() {
        guard let engravedScore,
              let font = SMuFLFontManager.shared.currentFont else {
            return
        }

        do {
            let exportEngine = ExportEngine(
                engravedScore: engravedScore,
                font: font
            )

            // Export first page at 2x resolution (retina)
            let pngData = try exportEngine.exportPNG(
                pageIndex: 0,
                scale: 2.0
            )

            // Save to file
            let documentsURL = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first!

            let filename = (score?.metadata.workTitle ?? "Score") + "_page1.png"
            let outputURL = documentsURL.appendingPathComponent(filename)

            try pngData.write(to: outputURL)
            print("Exported PNG to: \(outputURL.path)")

        } catch let error as ExportError {
            switch error {
            case .invalidPageIndex(let index):
                exportError = "Page \(index + 1) doesn't exist"
            case .contextCreationFailed:
                exportError = "Failed to create image context"
            case .imageEncodingFailed:
                exportError = "Failed to encode PNG"
            default:
                exportError = error.localizedDescription
            }
        } catch {
            exportError = error.localizedDescription
        }
    }

    // ... other methods
}
