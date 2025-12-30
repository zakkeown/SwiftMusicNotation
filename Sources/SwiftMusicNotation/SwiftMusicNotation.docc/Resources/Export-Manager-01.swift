import Foundation
import SwiftMusicNotation
import MusicXMLExport
import MusicNotationRenderer
import MusicNotationLayout

/// Centralized export manager for all export operations
@MainActor
class ExportManager: ObservableObject {
    // MARK: - Properties

    @Published var isExporting = false
    @Published var lastError: String?

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

    func exportMusicXML(config: ExportConfiguration = ExportConfiguration()) throws -> URL {
        let exporter = MusicXMLExporter(config: config)
        let data = try exporter.export(score)

        let url = outputURL(extension: "musicxml")
        try data.write(to: url)
        return url
    }

    // MARK: - PDF Export

    func exportPDF(config: MusicNotationRenderer.ExportConfiguration = .init()) throws -> URL {
        let engine = ExportEngine(
            engravedScore: engravedScore,
            font: font,
            config: config
        )

        let data = try engine.exportPDF()
        let url = outputURL(extension: "pdf")
        try data.write(to: url)
        return url
    }

    // MARK: - Image Export

    func exportPNG(pageIndex: Int = 0, scale: CGFloat = 2.0) throws -> URL {
        let engine = ExportEngine(engravedScore: engravedScore, font: font)
        let data = try engine.exportPNG(pageIndex: pageIndex, scale: scale)

        let url = outputURL(extension: "png", suffix: "_page\(pageIndex + 1)")
        try data.write(to: url)
        return url
    }

    func exportJPEG(pageIndex: Int = 0, scale: CGFloat = 2.0, quality: CGFloat = 0.9) throws -> URL {
        let engine = ExportEngine(engravedScore: engravedScore, font: font)
        let data = try engine.exportJPEG(pageIndex: pageIndex, scale: scale, quality: quality)

        let url = outputURL(extension: "jpg", suffix: "_page\(pageIndex + 1)")
        try data.write(to: url)
        return url
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
