import SwiftUI
import SwiftMusicNotation
import MusicNotationRenderer

struct ExportPanelView: View {
    let engravedScore: EngravedScore
    let font: LoadedSMuFLFont
    let scoreName: String

    @Environment(\.dismiss) private var dismiss

    @State private var selectedFormat: ExportFormat = .png
    @State private var exportAllPages = false
    @State private var selectedPage: Int = 0
    @State private var scale: Double = 2.0
    @State private var jpegQuality: Double = 0.9
    @State private var isExporting = false
    @State private var exportProgress: Double = 0
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

                Section("Pages") {
                    Toggle("Export All Pages", isOn: $exportAllPages)

                    if !exportAllPages {
                        Picker("Page", selection: $selectedPage) {
                            ForEach(0..<engravedScore.pages.count, id: \.self) { index in
                                Text("Page \(index + 1)").tag(index)
                            }
                        }
                    } else {
                        Text("\(engravedScore.pages.count) pages will be exported")
                            .font(.caption)
                            .foregroundColor(.secondary)
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
                }

                if isExporting {
                    Section("Progress") {
                        ProgressView(value: exportProgress)
                        Text("Exporting page \(Int(exportProgress * Double(engravedScore.pages.count)) + 1) of \(engravedScore.pages.count)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Export Images")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isExporting)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Export") {
                        Task {
                            await exportImages()
                        }
                    }
                    .disabled(isExporting)
                }
            }
        }
    }

    private func exportImages() async {
        isExporting = true
        exportProgress = 0

        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let engine = ExportEngine(engravedScore: engravedScore, font: font)

        let pagesToExport = exportAllPages ? Array(0..<engravedScore.pages.count) : [selectedPage]

        for (index, pageIndex) in pagesToExport.enumerated() {
            do {
                let data: Data
                switch selectedFormat {
                case .png:
                    data = try engine.exportPNG(pageIndex: pageIndex, scale: scale)
                case .jpeg:
                    data = try engine.exportJPEG(pageIndex: pageIndex, scale: scale, quality: jpegQuality)
                }

                let filename = "\(scoreName)_page\(pageIndex + 1).\(selectedFormat.fileExtension)"
                let outputURL = documentsURL.appendingPathComponent(filename)
                try data.write(to: outputURL)

                await MainActor.run {
                    exportProgress = Double(index + 1) / Double(pagesToExport.count)
                }

            } catch {
                await MainActor.run {
                    exportError = "Failed to export page \(pageIndex + 1): \(error.localizedDescription)"
                }
                break
            }
        }

        await MainActor.run {
            isExporting = false
            if exportError == nil {
                dismiss()
            }
        }
    }
}
