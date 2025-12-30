import Foundation
import SwiftMusicNotation
import MusicXMLExport
import MusicNotationRenderer
import MusicNotationLayout
import Combine

/// Centralized export manager with progress tracking
@MainActor
class ExportManager: ObservableObject {
    // MARK: - Published Properties

    @Published var isExporting = false
    @Published var progress: Double = 0
    @Published var currentOperation: String = ""
    @Published var lastError: String?
    @Published var lastExportedURL: URL?

    // MARK: - Private Properties

    private let score: Score
    private let engravedScore: EngravedScore
    private let font: LoadedSMuFLFont

    // MARK: - Initialization

    init(score: Score, engravedScore: EngravedScore, font: LoadedSMuFLFont) {
        self.score = score
        self.engravedScore = engravedScore
        self.font = font
    }

    // MARK: - MusicXML Export

    func exportMusicXML(config: ExportConfiguration = ExportConfiguration()) async throws -> URL {
        isExporting = true
        currentOperation = "Generating MusicXML..."
        progress = 0

        defer {
            isExporting = false
            progress = 1.0
        }

        let exporter = MusicXMLExporter(config: config)
        progress = 0.3

        let data = try exporter.export(score)
        progress = 0.7

        let url = outputURL(extension: "musicxml")
        try data.write(to: url)
        progress = 1.0

        lastExportedURL = url
        return url
    }

    // MARK: - PDF Export

    func exportPDF(config: MusicNotationRenderer.ExportConfiguration = .init()) async throws -> URL {
        isExporting = true
        currentOperation = "Generating PDF..."
        progress = 0

        defer {
            isExporting = false
            progress = 1.0
        }

        let engine = ExportEngine(
            engravedScore: engravedScore,
            font: font,
            config: config
        )
        progress = 0.2

        currentOperation = "Rendering pages..."
        let data = try engine.exportPDF()
        progress = 0.8

        currentOperation = "Saving file..."
        let url = outputURL(extension: "pdf")
        try data.write(to: url)
        progress = 1.0

        lastExportedURL = url
        return url
    }

    // MARK: - Batch Image Export

    func exportAllPages(
        format: ImageFormat,
        scale: CGFloat = 2.0,
        quality: CGFloat = 0.9
    ) async throws -> [URL] {
        isExporting = true
        progress = 0

        defer {
            isExporting = false
            progress = 1.0
        }

        let engine = ExportEngine(engravedScore: engravedScore, font: font)
        var urls: [URL] = []

        let totalPages = engravedScore.pages.count

        for pageIndex in 0..<totalPages {
            currentOperation = "Exporting page \(pageIndex + 1) of \(totalPages)..."

            let data: Data
            let ext: String

            switch format {
            case .png:
                data = try engine.exportPNG(pageIndex: pageIndex, scale: scale)
                ext = "png"
            case .jpeg:
                data = try engine.exportJPEG(pageIndex: pageIndex, scale: scale, quality: quality)
                ext = "jpg"
            }

            let url = outputURL(extension: ext, suffix: "_page\(pageIndex + 1)")
            try data.write(to: url)
            urls.append(url)

            progress = Double(pageIndex + 1) / Double(totalPages)
        }

        lastExportedURL = urls.first
        return urls
    }

    // MARK: - Types

    enum ImageFormat {
        case png
        case jpeg
    }

    // MARK: - Helpers

    private var baseName: String {
        score.metadata.workTitle ?? "Untitled"
    }

    private func outputURL(extension ext: String, suffix: String = "") -> URL {
        let documentsURL = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!

        let sanitizedName = baseName
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")

        return documentsURL.appendingPathComponent("\(sanitizedName)\(suffix).\(ext)")
    }
}
