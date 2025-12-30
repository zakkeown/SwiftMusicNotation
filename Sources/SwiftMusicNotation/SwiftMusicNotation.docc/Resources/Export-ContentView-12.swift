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
                            Button("Export PNG (High Quality)") {
                                exportToImage(format: .png, scale: 3.0)
                            }
                            Button("Export PNG (Standard)") {
                                exportToImage(format: .png, scale: 2.0)
                            }
                            Divider()
                            Button("Export JPEG (High Quality)") {
                                exportToImage(format: .jpeg, scale: 2.0, quality: 0.95)
                            }
                            Button("Export JPEG (Small File)") {
                                exportToImage(format: .jpeg, scale: 1.5, quality: 0.7)
                            }
                        }
                    } label: {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                }
            }
        }
    }

    enum ImageFormat {
        case png
        case jpeg
    }

    private func exportToImage(
        format: ImageFormat,
        pageIndex: Int = 0,
        scale: CGFloat = 2.0,
        quality: CGFloat = 0.9
    ) {
        guard let engravedScore,
              let font = SMuFLFontManager.shared.currentFont else {
            return
        }

        do {
            let exportEngine = ExportEngine(
                engravedScore: engravedScore,
                font: font
            )

            let imageData: Data
            let fileExtension: String

            switch format {
            case .png:
                imageData = try exportEngine.exportPNG(
                    pageIndex: pageIndex,
                    scale: scale
                )
                fileExtension = "png"

            case .jpeg:
                imageData = try exportEngine.exportJPEG(
                    pageIndex: pageIndex,
                    scale: scale,
                    quality: quality
                )
                fileExtension = "jpg"
            }

            // Save to file
            let documentsURL = FileManager.default.urls(
                for: .documentDirectory,
                in: .userDomainMask
            ).first!

            let baseName = score?.metadata.workTitle ?? "Score"
            let filename = "\(baseName)_page\(pageIndex + 1).\(fileExtension)"
            let outputURL = documentsURL.appendingPathComponent(filename)

            try imageData.write(to: outputURL)
            print("Exported to: \(outputURL.path)")

        } catch {
            exportError = error.localizedDescription
        }
    }

    // ... other methods
}
