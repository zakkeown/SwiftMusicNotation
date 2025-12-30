import SwiftUI
import SwiftMusicNotation
import MusicNotationRenderer

struct ExportPanelView: View {
    let engravedScore: EngravedScore
    let font: LoadedSMuFLFont
    let scoreName: String

    @Environment(\.dismiss) private var dismiss

    @State private var selectedFormat: ExportFormat = .png
    @State private var selectedPage: Int = 0
    @State private var scale: Double = 2.0
    @State private var jpegQuality: Double = 0.9
    @State private var isExporting = false
    @State private var exportError: String?

    enum ExportFormat: String, CaseIterable {
        case png = "PNG"
        case jpeg = "JPEG"

        var fileExtension: String {
            switch self {
            case .png: return "png"
            case .jpeg: return "jpg"
            }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Format") {
                    Picker("Image Format", selection: $selectedFormat) {
                        ForEach(ExportFormat.allCases, id: \.self) { format in
                            Text(format.rawValue).tag(format)
                        }
                    }
                    .pickerStyle(.segmented)

                    if selectedFormat == .jpeg {
                        HStack {
                            Text("Quality")
                            Slider(value: $jpegQuality, in: 0.5...1.0)
                            Text("\(Int(jpegQuality * 100))%")
                                .monospacedDigit()
                                .frame(width: 45)
                        }
                    }
                }

                Section("Page") {
                    Picker("Page", selection: $selectedPage) {
                        ForEach(0..<engravedScore.pages.count, id: \.self) { index in
                            Text("Page \(index + 1)").tag(index)
                        }
                    }
                }

                Section("Resolution") {
                    HStack {
                        Text("Scale")
                        Slider(value: $scale, in: 1.0...4.0, step: 0.5)
                        Text("\(scale, specifier: "%.1f")x")
                            .monospacedDigit()
                            .frame(width: 40)
                    }

                    let pixelSize = calculatePixelSize()
                    Text("Output size: \(Int(pixelSize.width)) x \(Int(pixelSize.height)) pixels")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Export Image")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Export") {
                        exportImage()
                    }
                    .disabled(isExporting)
                }
            }
            .alert("Export Failed", isPresented: .constant(exportError != nil)) {
                Button("OK") { exportError = nil }
            } message: {
                Text(exportError ?? "")
            }
        }
    }

    private func calculatePixelSize() -> CGSize {
        let page = engravedScore.pages[selectedPage]
        return CGSize(
            width: page.frame.width * scale,
            height: page.frame.height * scale
        )
    }

    private func exportImage() {
        isExporting = true

        do {
            let engine = ExportEngine(engravedScore: engravedScore, font: font)

            let data: Data
            switch selectedFormat {
            case .png:
                data = try engine.exportPNG(pageIndex: selectedPage, scale: scale)
            case .jpeg:
                data = try engine.exportJPEG(pageIndex: selectedPage, scale: scale, quality: jpegQuality)
            }

            // Save to Documents
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            let filename = "\(scoreName)_page\(selectedPage + 1).\(selectedFormat.fileExtension)"
            let outputURL = documentsURL.appendingPathComponent(filename)

            try data.write(to: outputURL)
            dismiss()

        } catch {
            exportError = error.localizedDescription
        }

        isExporting = false
    }
}
