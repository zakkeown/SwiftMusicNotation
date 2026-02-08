import Foundation
import CoreGraphics
import MusicNotationCore
import MusicNotationLayout
import SMuFLKit

#if os(macOS)
import AppKit
#elseif os(iOS) || os(visionOS)
import UIKit
#endif

// MARK: - Export Engine

/// Exports engraved scores to PDF, PNG, JPEG, and SVG formats.
///
/// `ExportEngine` renders engraved scores to various file formats suitable for
/// printing, sharing, or embedding in documents. It supports multi-page PDF export
/// and single-page raster (PNG, JPEG) and vector (SVG) exports.
///
/// ## Usage
///
/// Export a score to PDF:
///
/// ```swift
/// let engine = ExportEngine(
///     engravedScore: engravedScore,
///     font: loadedFont
/// )
///
/// // Export to Data
/// let pdfData = try engine.exportPDF()
///
/// // Or export directly to file
/// try engine.exportPDF(to: documentsURL.appendingPathComponent("score.pdf"))
/// ```
///
/// Export a single page to PNG:
///
/// ```swift
/// // High-resolution export for printing
/// let pngData = try engine.exportPNG(pageIndex: 0, scale: 3.0)
///
/// // Save to file
/// try engine.exportPNG(pageIndex: 0, scale: 2.0, to: imageURL)
/// ```
///
/// ## Export Formats
///
/// | Format | Method | Use Case |
/// |--------|--------|----------|
/// | PDF | `exportPDF()` | Multi-page documents, printing, archival |
/// | PNG | `exportPNG()` | Web images, transparency support |
/// | JPEG | `exportJPEG()` | Photos, smaller file size |
/// | SVG | `exportSVG()` | Scalable web graphics |
///
/// ## Customization
///
/// Use `ExportConfiguration` to control appearance:
///
/// ```swift
/// var config = ExportConfiguration()
/// config.backgroundColor = CGColor(red: 1, green: 1, blue: 0.95, alpha: 1)
/// config.staffHeight = 50  // Larger staff for better readability
///
/// let engine = ExportEngine(engravedScore: score, font: font, config: config)
/// ```
///
/// - SeeAlso: `ExportConfiguration` for customization options
/// - SeeAlso: `ExportError` for error handling
public final class ExportEngine {
    /// The engraved score to export.
    ///
    /// This must be a fully laid-out score from `LayoutEngine`.
    public var engravedScore: EngravedScore

    /// The SMuFL font used for rendering musical glyphs.
    public var font: LoadedSMuFLFont

    /// Configuration controlling export appearance.
    public var config: ExportConfiguration

    /// Creates a new export engine.
    ///
    /// - Parameters:
    ///   - engravedScore: The laid-out score to export.
    ///   - font: The SMuFL font for rendering glyphs.
    ///   - config: Export configuration. Defaults to standard settings.
    public init(
        engravedScore: EngravedScore,
        font: LoadedSMuFLFont,
        config: ExportConfiguration = ExportConfiguration()
    ) {
        self.engravedScore = engravedScore
        self.font = font
        self.config = config
    }

    // MARK: - PDF Export

    /// Exports the entire score to PDF data.
    ///
    /// Creates a multi-page PDF document containing all pages in the score.
    /// The PDF is suitable for printing or viewing in PDF readers.
    ///
    /// - Returns: The PDF document as `Data`.
    /// - Throws: `ExportError.emptyScore` if the score has no pages.
    ///   `ExportError.contextCreationFailed` if PDF context creation fails.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let pdfData = try engine.exportPDF()
    ///
    /// // Share via UIActivityViewController (iOS)
    /// let activityVC = UIActivityViewController(
    ///     activityItems: [pdfData],
    ///     applicationActivities: nil
    /// )
    /// ```
    public func exportPDF() throws -> Data {
        let totalBounds = engravedScore.totalBounds
        guard totalBounds.width > 0, totalBounds.height > 0 else {
            throw ExportError.emptyScore
        }

        let pdfData = NSMutableData()

        #if os(macOS)
        var mediaBox = CGRect(origin: .zero, size: totalBounds.size)

        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let pdfContext = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
            throw ExportError.contextCreationFailed
        }

        // Render each page
        for page in engravedScore.pages {
            var pageRect = CGRect(origin: .zero, size: page.frame.size)
            pdfContext.beginPage(mediaBox: &pageRect)

            // Set up coordinate system (flip for top-left origin)
            pdfContext.translateBy(x: 0, y: page.frame.height)
            pdfContext.scaleBy(x: 1, y: -1)

            // Render the page
            renderPage(page, in: pdfContext)

            pdfContext.endPage()
        }

        pdfContext.closePDF()

        #elseif os(iOS) || os(visionOS)
        let renderer = UIGraphicsPDFRenderer(bounds: CGRect(origin: .zero, size: totalBounds.size))

        let renderedData = renderer.pdfData { context in
            for page in self.engravedScore.pages {
                context.beginPage(withBounds: CGRect(origin: .zero, size: page.frame.size), pageInfo: [:])
                self.renderPage(page, in: context.cgContext)
            }
        }

        pdfData.append(renderedData)
        #endif

        return pdfData as Data
    }

    /// Exports the score to a PDF file at the specified URL.
    ///
    /// - Parameter url: The file URL where the PDF will be saved.
    /// - Throws: `ExportError` if export fails, or file system errors if
    ///   the file cannot be written.
    public func exportPDF(to url: URL) throws {
        let data = try exportPDF()
        try data.write(to: url)
    }

    // MARK: - Image Export

    /// Exports a single page to PNG image data.
    ///
    /// PNG format supports transparency and lossless compression, making it
    /// ideal for web display and embedding in documents.
    ///
    /// - Parameters:
    ///   - pageIndex: The zero-based index of the page to export. Defaults to 0.
    ///   - scale: Resolution multiplier. 1.0 = 72 DPI, 2.0 = 144 DPI, etc.
    ///     Defaults to 2.0 for crisp display on retina screens.
    /// - Returns: PNG image data.
    /// - Throws: `ExportError.invalidPageIndex` if the page doesn't exist.
    ///
    /// ## Scale Guidelines
    ///
    /// | Scale | DPI | Use Case |
    /// |-------|-----|----------|
    /// | 1.0 | 72 | Screen preview |
    /// | 2.0 | 144 | Retina displays |
    /// | 3.0 | 216 | High-quality print |
    /// | 4.0 | 288 | Professional print |
    public func exportPNG(pageIndex: Int = 0, scale: CGFloat = 2.0) throws -> Data {
        guard pageIndex >= 0, pageIndex < engravedScore.pages.count else {
            throw ExportError.invalidPageIndex(pageIndex)
        }

        let page = engravedScore.pages[pageIndex]
        let size = CGSize(
            width: page.frame.width * scale,
            height: page.frame.height * scale
        )

        #if os(macOS)
        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw ExportError.contextCreationFailed
        }

        guard let context = NSGraphicsContext(bitmapImageRep: bitmapRep) else {
            throw ExportError.contextCreationFailed
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context

        let cgContext = context.cgContext

        // Fill background
        cgContext.setFillColor(config.backgroundColor)
        cgContext.fill(CGRect(origin: .zero, size: size))

        // Scale for resolution
        cgContext.scaleBy(x: scale, y: scale)

        // Flip coordinate system
        cgContext.translateBy(x: 0, y: page.frame.height)
        cgContext.scaleBy(x: 1, y: -1)

        // Render
        renderPage(page, in: cgContext)

        NSGraphicsContext.restoreGraphicsState()

        guard let data = bitmapRep.representation(using: .png, properties: [:]) else {
            throw ExportError.imageEncodingFailed
        }

        return data

        #elseif os(iOS) || os(visionOS)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: page.frame.width, height: page.frame.height), format: format)

        let image = renderer.image { context in
            // Fill background
            context.cgContext.setFillColor(self.config.backgroundColor)
            context.cgContext.fill(CGRect(origin: .zero, size: page.frame.size))

            // Render
            self.renderPage(page, in: context.cgContext)
        }

        guard let data = image.pngData() else {
            throw ExportError.imageEncodingFailed
        }

        return data
        #endif
    }

    /// Exports a single page to a PNG file at the specified URL.
    ///
    /// - Parameters:
    ///   - pageIndex: The zero-based page index. Defaults to 0.
    ///   - scale: Resolution multiplier. Defaults to 2.0.
    ///   - url: The file URL where the image will be saved.
    /// - Throws: `ExportError` if export fails, or file system errors.
    public func exportPNG(pageIndex: Int = 0, scale: CGFloat = 2.0, to url: URL) throws {
        let data = try exportPNG(pageIndex: pageIndex, scale: scale)
        try data.write(to: url)
    }

    /// Exports a single page to JPEG image data.
    ///
    /// JPEG is a lossy format with smaller file sizes than PNG. It does not
    /// support transparency. Best for sharing and web use where file size matters.
    ///
    /// - Parameters:
    ///   - pageIndex: The zero-based index of the page to export. Defaults to 0.
    ///   - scale: Resolution multiplier. Defaults to 2.0.
    ///   - quality: JPEG compression quality from 0.0 (most compressed) to 1.0
    ///     (least compressed). Defaults to 0.9 for good quality with reasonable size.
    /// - Returns: JPEG image data.
    /// - Throws: `ExportError.invalidPageIndex` if the page doesn't exist.
    public func exportJPEG(pageIndex: Int = 0, scale: CGFloat = 2.0, quality: CGFloat = 0.9) throws -> Data {
        guard pageIndex >= 0, pageIndex < engravedScore.pages.count else {
            throw ExportError.invalidPageIndex(pageIndex)
        }

        let page = engravedScore.pages[pageIndex]
        let size = CGSize(
            width: page.frame.width * scale,
            height: page.frame.height * scale
        )

        #if os(macOS)
        guard let bitmapRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(size.width),
            pixelsHigh: Int(size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: false,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else {
            throw ExportError.contextCreationFailed
        }

        guard let context = NSGraphicsContext(bitmapImageRep: bitmapRep) else {
            throw ExportError.contextCreationFailed
        }

        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = context

        let cgContext = context.cgContext

        // Fill background (white for JPEG)
        cgContext.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        cgContext.fill(CGRect(origin: .zero, size: size))

        cgContext.scaleBy(x: scale, y: scale)
        cgContext.translateBy(x: 0, y: page.frame.height)
        cgContext.scaleBy(x: 1, y: -1)

        renderPage(page, in: cgContext)

        NSGraphicsContext.restoreGraphicsState()

        guard let data = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: quality]) else {
            throw ExportError.imageEncodingFailed
        }

        return data

        #elseif os(iOS) || os(visionOS)
        let format = UIGraphicsImageRendererFormat()
        format.scale = scale
        format.opaque = true

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: page.frame.width, height: page.frame.height), format: format)

        let image = renderer.image { context in
            // Fill white background for JPEG
            context.cgContext.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
            context.cgContext.fill(CGRect(origin: .zero, size: page.frame.size))

            self.renderPage(page, in: context.cgContext)
        }

        guard let data = image.jpegData(compressionQuality: quality) else {
            throw ExportError.imageEncodingFailed
        }

        return data
        #endif
    }

    /// Exports a single page to a JPEG file at the specified URL.
    ///
    /// - Parameters:
    ///   - pageIndex: The zero-based page index. Defaults to 0.
    ///   - scale: Resolution multiplier. Defaults to 2.0.
    ///   - quality: JPEG compression quality (0.0-1.0). Defaults to 0.9.
    ///   - url: The file URL where the image will be saved.
    /// - Throws: `ExportError` if export fails, or file system errors.
    public func exportJPEG(pageIndex: Int = 0, scale: CGFloat = 2.0, quality: CGFloat = 0.9, to url: URL) throws {
        let data = try exportJPEG(pageIndex: pageIndex, scale: scale, quality: quality)
        try data.write(to: url)
    }

    // MARK: - SVG Export

    /// Exports a single page to SVG (Scalable Vector Graphics) string.
    ///
    /// SVG is a vector format that scales perfectly to any size without
    /// quality loss. Ideal for web embedding where users may zoom.
    ///
    /// - Parameter pageIndex: The zero-based index of the page to export.
    /// - Returns: The SVG document as a string.
    /// - Throws: `ExportError.invalidPageIndex` if the page doesn't exist.
    ///
    /// - Note: Current implementation exports staff lines only. Full notation
    ///   export requires glyph-to-path conversion.
    public func exportSVG(pageIndex: Int = 0) throws -> String {
        guard pageIndex >= 0, pageIndex < engravedScore.pages.count else {
            throw ExportError.invalidPageIndex(pageIndex)
        }

        let page = engravedScore.pages[pageIndex]
        var svg = """
        <?xml version="1.0" encoding="UTF-8"?>
        <svg xmlns="http://www.w3.org/2000/svg"
             width="\(page.frame.width)"
             height="\(page.frame.height)"
             viewBox="0 0 \(page.frame.width) \(page.frame.height)">
          <rect width="100%" height="100%" fill="white"/>
          <g transform="translate(0, 0)">

        """

        // Add staff lines and basic elements
        // This is a simplified SVG export - full implementation would render all elements
        for system in page.systems {
            svg += "    <!-- System at \(system.frame.origin) -->\n"
            for staff in system.staves {
                let staffY = system.frame.origin.y + staff.frame.origin.y
                let staffWidth = staff.frame.width
                let staffSpacing = staff.staffHeight / 4

                // Draw staff lines
                for line in 0..<staff.lineCount {
                    let y = staffY + CGFloat(line) * staffSpacing
                    svg += """
                        <line x1="\(system.frame.origin.x + staff.frame.origin.x)"
                              y1="\(y)"
                              x2="\(system.frame.origin.x + staff.frame.origin.x + staffWidth)"
                              y2="\(y)"
                              stroke="black"
                              stroke-width="0.5"/>

                    """
                }
            }
        }

        svg += """
          </g>
        </svg>
        """

        return svg
    }

    /// Exports a single page to an SVG file at the specified URL.
    ///
    /// - Parameters:
    ///   - pageIndex: The zero-based page index. Defaults to 0.
    ///   - url: The file URL where the SVG will be saved.
    /// - Throws: `ExportError` if export fails, or file system errors.
    public func exportSVG(pageIndex: Int = 0, to url: URL) throws {
        let svg = try exportSVG(pageIndex: pageIndex)
        try svg.write(to: url, atomically: true, encoding: .utf8)
    }

    // MARK: - Rendering

    private func renderPage(_ page: EngravedPage, in context: CGContext) {
        // Initialize renderers
        let renderState = ScoreRenderState()
        renderState.initializeRenderers(with: font)
        renderState.staffHeight = config.staffHeight

        // Draw page background
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(origin: .zero, size: page.frame.size))

        // Draw systems
        for system in page.systems {
            context.saveGState()
            context.translateBy(x: system.frame.origin.x, y: system.frame.origin.y)

            // Draw staff groupings (braces, brackets)
            renderGroupings(system.groupings, staves: system.staves, renderState: renderState, in: context)

            // Draw staves
            for staff in system.staves {
                renderStaff(staff, renderState: renderState, in: context)
            }

            // Draw system barlines
            renderSystemBarlines(system.systemBarlines, renderState: renderState, in: context)

            // Draw measures (elements, beams, barlines)
            for measure in system.measures {
                renderMeasure(measure, renderState: renderState, in: context)
            }

            context.restoreGState()
        }

        // Draw credits
        for credit in page.credits {
            renderCredit(credit, renderState: renderState, in: context)
        }
    }

    private func renderStaff(_ staff: EngravedStaff, renderState: ScoreRenderState, in context: CGContext) {
        guard let staffRenderer = renderState.staffRenderer else { return }

        context.saveGState()
        context.translateBy(x: staff.frame.origin.x, y: staff.frame.origin.y)

        let staffSpacing = staff.staffHeight / 4
        staffRenderer.renderStaffLines(
            at: .zero,
            width: staff.frame.width,
            lineCount: staff.lineCount,
            staffSpacing: staffSpacing,
            color: config.foregroundColor,
            in: context
        )

        context.restoreGState()
    }

    private func renderMeasure(_ measure: EngravedMeasure, renderState: ScoreRenderState, in context: CGContext) {
        guard let staffRenderer = renderState.staffRenderer else { return }

        context.saveGState()
        context.translateBy(x: measure.frame.origin.x, y: measure.frame.origin.y)

        // Draw barlines
        let staffHeight = renderState.staffHeight
        staffRenderer.renderBarline(
            at: measure.rightBarlineX - measure.frame.origin.x,
            topY: 0,
            bottomY: staffHeight,
            color: config.foregroundColor,
            in: context
        )

        // Draw elements
        for (_, elements) in measure.elementsByStaff {
            for element in elements {
                renderElement(element, renderState: renderState, in: context)
            }
        }

        // Draw beam groups
        if let beamRenderer = renderState.beamRenderer {
            for beamGroup in measure.beamGroups {
                let beamInfo = BeamGroupRenderInfo(
                    primaryBeamStart: beamGroup.startPoint,
                    primaryBeamEnd: beamGroup.endPoint,
                    beamThickness: beamGroup.thickness,
                    stemDirection: beamGroup.stemDirection,
                    slope: beamGroup.slope
                )
                beamRenderer.renderBeamGroup(beamInfo, color: config.foregroundColor, in: context)
            }
        }

        context.restoreGState()
    }

    private func renderElement(_ element: EngravedElement, renderState: ScoreRenderState, in context: CGContext) {
        guard let glyphRenderer = renderState.glyphRenderer else { return }
        let color = config.foregroundColor

        switch element {
        case .note(let note):
            renderNote(note, renderState: renderState, in: context)

        case .rest(let rest):
            glyphRenderer.renderGlyph(rest.glyph, at: rest.position, color: color, in: context)

        case .chord(let chord):
            renderChord(chord, renderState: renderState, in: context)

        case .clef(let clef):
            glyphRenderer.renderGlyph(clef.glyph, at: clef.position, color: color, in: context)

        case .keySignature(let keySig):
            for (glyph, pos) in keySig.accidentals {
                glyphRenderer.renderGlyph(glyph, at: pos, color: color, in: context)
            }

        case .timeSignature(let timeSig):
            if let symbol = timeSig.symbolGlyph {
                glyphRenderer.renderGlyph(symbol, at: timeSig.position, color: color, in: context)
            } else {
                for (glyph, pos) in timeSig.topGlyphs {
                    glyphRenderer.renderGlyph(glyph, at: pos, color: color, in: context)
                }
                for (glyph, pos) in timeSig.bottomGlyphs {
                    glyphRenderer.renderGlyph(glyph, at: pos, color: color, in: context)
                }
            }

        case .barline(let barline):
            if let staffRenderer = renderState.staffRenderer {
                staffRenderer.renderBarline(
                    style: barline.style,
                    at: barline.frame.origin.x,
                    topY: barline.frame.origin.y,
                    bottomY: barline.frame.maxY,
                    color: color,
                    in: context
                )
            }

        case .direction(let direction):
            renderDirection(direction, renderState: renderState, in: context)
        }
    }

    // MARK: - Note Rendering

    private func renderNote(_ note: EngravedNote, renderState: ScoreRenderState, in context: CGContext) {
        guard let noteRenderer = renderState.noteRenderer else { return }
        let color = config.foregroundColor

        // Build accidental info
        var accidentalInfo: AccidentalInfo? = nil
        if let accGlyph = note.accidentalGlyph {
            let accPos = CGPoint(x: note.position.x + note.accidentalOffset, y: note.position.y)
            accidentalInfo = AccidentalInfo(glyph: accGlyph, position: accPos)
        }

        // Build stem info
        var stemInfo: StemRenderInfo? = nil
        if let stem = note.stem {
            stemInfo = StemRenderInfo(
                start: stem.start,
                end: stem.end,
                direction: stem.direction,
                thickness: stem.thickness
            )
        }

        // Build flag info
        var flagInfo: FlagInfo? = nil
        if let flagGlyph = note.flagGlyph, let stem = note.stem {
            flagInfo = FlagInfo(glyph: flagGlyph, position: stem.end)
        }

        let noteInfo = NoteRenderInfo(
            position: note.position,
            staffPosition: note.staffPosition,
            noteheadGlyph: note.noteheadGlyph,
            accidental: accidentalInfo,
            stem: stemInfo,
            flag: flagInfo,
            dots: note.dots
        )

        noteRenderer.renderNote(noteInfo, color: color, in: context)
    }

    // MARK: - Chord Rendering

    private func renderChord(_ chord: EngravedChord, renderState: ScoreRenderState, in context: CGContext) {
        guard let noteRenderer = renderState.noteRenderer else { return }
        let color = config.foregroundColor

        // Build noteheads
        let noteheads: [(glyph: SMuFLGlyphName, position: CGPoint)] = chord.notes.map { note in
            (glyph: note.noteheadGlyph, position: note.position)
        }

        // Build accidentals
        let accidentals: [(glyph: SMuFLGlyphName, position: CGPoint)] = chord.notes.compactMap { note in
            guard let accGlyph = note.accidentalGlyph else { return nil }
            let accPos = CGPoint(x: note.position.x + note.accidentalOffset, y: note.position.y)
            return (glyph: accGlyph, position: accPos)
        }

        // Build stem info
        var stemInfo: StemRenderInfo? = nil
        if let stem = chord.stem {
            stemInfo = StemRenderInfo(
                start: stem.start,
                end: stem.end,
                direction: stem.direction,
                thickness: stem.thickness
            )
        }

        // Build flag info
        var flagInfo: FlagInfo? = nil
        if let flagGlyph = chord.flagGlyph, let stem = chord.stem {
            flagInfo = FlagInfo(glyph: flagGlyph, position: stem.end)
        }

        // Collect dots from all notes
        let dots = chord.notes.flatMap { $0.dots }

        let staffPositions = chord.notes.map { $0.staffPosition }

        let chordInfo = ChordRenderInfo(
            noteheads: noteheads,
            staffPositions: staffPositions,
            accidentals: accidentals,
            stem: stemInfo,
            flag: flagInfo,
            dots: dots
        )

        noteRenderer.renderChord(chordInfo, color: color, in: context)
    }

    // MARK: - Direction Rendering

    private func renderDirection(_ direction: EngravedDirection, renderState: ScoreRenderState, in context: CGContext) {
        let color = config.foregroundColor

        switch direction.content {
        case .text(let text):
            if let textRenderer = renderState.textRenderer {
                let dirInfo = DirectionTextRenderInfo(
                    text: text,
                    position: direction.position
                )
                textRenderer.renderDirection(dirInfo, color: color, in: context)
            }

        case .dynamic(let dynamicGlyph):
            if let glyphRenderer = renderState.glyphRenderer {
                glyphRenderer.renderGlyph(dynamicGlyph, at: direction.position, color: color, in: context)
            }

        case .wedge(let wedge):
            renderWedge(wedge, y: direction.position.y, color: color, in: context)

        case .metronome(let metronome):
            renderMetronome(metronome, at: direction.position, renderState: renderState, in: context)
        }
    }

    private func renderWedge(_ wedge: WedgeContent, y: CGFloat, color: CGColor, in context: CGContext) {
        context.saveGState()
        context.setStrokeColor(color)
        context.setLineWidth(0.16)
        context.setLineCap(.round)

        if wedge.isCresc {
            // Crescendo: converges from left to right opening
            context.move(to: CGPoint(x: wedge.startX, y: y))
            context.addLine(to: CGPoint(x: wedge.endX, y: y - wedge.spreadEnd / 2))
            context.move(to: CGPoint(x: wedge.startX, y: y))
            context.addLine(to: CGPoint(x: wedge.endX, y: y + wedge.spreadEnd / 2))
        } else {
            // Diminuendo: opens from left, converges to right
            context.move(to: CGPoint(x: wedge.startX, y: y - wedge.spreadStart / 2))
            context.addLine(to: CGPoint(x: wedge.endX, y: y))
            context.move(to: CGPoint(x: wedge.startX, y: y + wedge.spreadStart / 2))
            context.addLine(to: CGPoint(x: wedge.endX, y: y))
        }

        context.strokePath()
        context.restoreGState()
    }

    private func renderMetronome(_ metronome: MetronomeContent, at position: CGPoint, renderState: ScoreRenderState, in context: CGContext) {
        guard let textRenderer = renderState.textRenderer,
              let glyphRenderer = renderState.glyphRenderer else { return }
        let color = config.foregroundColor

        // Render beat unit glyph
        glyphRenderer.renderGlyphScaled(
            metronome.beatUnitGlyph,
            at: position,
            scale: 0.6,
            color: color,
            in: context
        )

        // Render dots
        let glyphAdvance = glyphRenderer.getAdvance(for: metronome.beatUnitGlyph) * 0.6
        var xOffset = glyphAdvance + 2

        for _ in 0..<metronome.beatUnitDots {
            glyphRenderer.renderGlyphScaled(
                .augmentationDot,
                at: CGPoint(x: position.x + xOffset, y: position.y),
                scale: 0.6,
                color: color,
                in: context
            )
            xOffset += 3
        }

        // Render " = BPM"
        let bpmText = " = \(metronome.bpm)"
        textRenderer.renderText(
            bpmText,
            at: CGPoint(x: position.x + xOffset, y: position.y),
            fontSize: 12,
            color: color,
            in: context
        )
    }

    // MARK: - System-Level Rendering

    private func renderSystemBarlines(_ barlines: [EngravedSystemBarline], renderState: ScoreRenderState, in context: CGContext) {
        guard let staffRenderer = renderState.staffRenderer else { return }

        for barline in barlines {
            staffRenderer.renderBarline(
                style: barline.style,
                at: barline.x,
                topY: barline.topY,
                bottomY: barline.bottomY,
                color: config.foregroundColor,
                in: context
            )
        }
    }

    private func renderGroupings(_ groupings: [EngravedStaffGrouping], staves: [EngravedStaff], renderState: ScoreRenderState, in context: CGContext) {
        guard let glyphRenderer = renderState.glyphRenderer else { return }

        for grouping in groupings {
            guard grouping.topStaffIndex < staves.count,
                  grouping.bottomStaffIndex < staves.count else { continue }

            let topStaff = staves[grouping.topStaffIndex]
            let bottomStaff = staves[grouping.bottomStaffIndex]
            let topY = topStaff.frame.origin.y
            let bottomY = bottomStaff.frame.origin.y + bottomStaff.staffHeight

            switch grouping.symbol {
            case .brace:
                glyphRenderer.renderBrace(
                    at: grouping.x,
                    topY: topY,
                    bottomY: bottomY,
                    color: config.foregroundColor,
                    in: context
                )

            case .bracket:
                glyphRenderer.renderBracket(
                    at: grouping.x,
                    topY: topY,
                    bottomY: bottomY,
                    thickness: 0.5,
                    color: config.foregroundColor,
                    in: context
                )

            case .line:
                context.saveGState()
                context.setStrokeColor(config.foregroundColor)
                context.setLineWidth(0.16)
                context.move(to: CGPoint(x: grouping.x, y: topY))
                context.addLine(to: CGPoint(x: grouping.x, y: bottomY))
                context.strokePath()
                context.restoreGState()

            case .square, .none:
                break
            }
        }
    }

    // MARK: - Credit Rendering

    private func renderCredit(_ credit: EngravedCredit, renderState: ScoreRenderState, in context: CGContext) {
        guard let textRenderer = renderState.textRenderer else { return }

        let alignment: TextAlignment
        switch credit.justification {
        case .left:
            alignment = .left
        case .right:
            alignment = .right
        case .center, .none:
            alignment = .center
        }

        let creditInfo = CreditRenderInfo(
            text: credit.text,
            position: credit.position,
            fontSize: credit.fontSize,
            alignment: alignment
        )

        textRenderer.renderCredit(creditInfo, color: config.foregroundColor, in: context)
    }
}

// MARK: - Export Configuration

/// Configuration options for score export operations.
///
/// Use `ExportConfiguration` to customize the appearance of exported scores.
/// All properties have sensible defaults for standard black-on-white output.
///
/// ## Example
///
/// ```swift
/// var config = ExportConfiguration()
/// config.backgroundColor = CGColor(red: 1, green: 0.98, blue: 0.9, alpha: 1) // Cream
/// config.staffHeight = 50  // Larger staff for better legibility
///
/// let engine = ExportEngine(engravedScore: score, font: font, config: config)
/// ```
public struct ExportConfiguration: Sendable {
    /// Background color for the exported page.
    ///
    /// Default: White (`CGColor(red: 1, green: 1, blue: 1, alpha: 1)`)
    public var backgroundColor: CGColor

    /// Color for notation elements (notes, staff lines, barlines, etc.).
    ///
    /// Default: Black (`CGColor(red: 0, green: 0, blue: 0, alpha: 1)`)
    public var foregroundColor: CGColor

    /// Staff height in points.
    ///
    /// Larger values produce more readable output at the cost of more pages.
    ///
    /// Default: 40 points
    public var staffHeight: CGFloat

    /// Target DPI (dots per inch) for image exports.
    ///
    /// This affects the resolution calculation for PNG and JPEG exports.
    /// Higher values produce larger, more detailed images.
    ///
    /// Default: 300 DPI (print quality)
    public var dpi: CGFloat

    /// Creates an export configuration with the specified settings.
    ///
    /// - Parameters:
    ///   - backgroundColor: Page background color.
    ///   - foregroundColor: Notation element color.
    ///   - staffHeight: Height of a five-line staff in points.
    ///   - dpi: Resolution for image exports.
    public init(
        backgroundColor: CGColor = CGColor(red: 1, green: 1, blue: 1, alpha: 1),
        foregroundColor: CGColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1),
        staffHeight: CGFloat = 40,
        dpi: CGFloat = 300
    ) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
        self.staffHeight = staffHeight
        self.dpi = dpi
    }
}

// MARK: - Export Errors

/// Errors that can occur during score export operations.
///
/// Handle these errors to provide meaningful feedback to users when export fails.
///
/// ## Example
///
/// ```swift
/// do {
///     let pdfData = try engine.exportPDF()
/// } catch let error as ExportError {
///     switch error {
///     case .emptyScore:
///         showAlert("No content to export")
///     case .invalidPageIndex(let index):
///         showAlert("Page \(index + 1) doesn't exist")
///     default:
///         showAlert(error.localizedDescription)
///     }
/// }
/// ```
public enum ExportError: Error, LocalizedError {
    /// The score has no pages to export.
    case emptyScore
    /// Failed to create a graphics context for rendering.
    case contextCreationFailed
    /// Failed to encode the rendered image to the target format.
    case imageEncodingFailed
    /// The requested page index is out of range.
    case invalidPageIndex(Int)
    /// Failed to write the exported file to disk.
    case fileWriteError(URL)

    public var errorDescription: String? {
        switch self {
        case .emptyScore:
            return "Cannot export an empty score"
        case .contextCreationFailed:
            return "Failed to create graphics context"
        case .imageEncodingFailed:
            return "Failed to encode image data"
        case .invalidPageIndex(let index):
            return "Invalid page index: \(index)"
        case .fileWriteError(let url):
            return "Failed to write file to \(url.path)"
        }
    }
}

// MARK: - EngravedScore Extension

public extension EngravedScore {
    /// Convenience method to export the score to PDF data.
    ///
    /// This creates an `ExportEngine` internally for one-off exports.
    /// For multiple exports, create an `ExportEngine` instance directly.
    ///
    /// - Parameters:
    ///   - font: The SMuFL font for rendering glyphs.
    ///   - config: Export configuration. Defaults to standard settings.
    /// - Returns: PDF document data.
    /// - Throws: `ExportError` if export fails.
    func exportPDF(font: LoadedSMuFLFont, config: ExportConfiguration = ExportConfiguration()) throws -> Data {
        let engine = ExportEngine(engravedScore: self, font: font, config: config)
        return try engine.exportPDF()
    }

    /// Convenience method to export a page to PNG image data.
    ///
    /// - Parameters:
    ///   - pageIndex: The zero-based page index. Defaults to 0.
    ///   - font: The SMuFL font for rendering glyphs.
    ///   - scale: Resolution multiplier. Defaults to 2.0.
    ///   - config: Export configuration. Defaults to standard settings.
    /// - Returns: PNG image data.
    /// - Throws: `ExportError` if export fails.
    func exportPNG(pageIndex: Int = 0, font: LoadedSMuFLFont, scale: CGFloat = 2.0, config: ExportConfiguration = ExportConfiguration()) throws -> Data {
        let engine = ExportEngine(engravedScore: self, font: font, config: config)
        return try engine.exportPNG(pageIndex: pageIndex, scale: scale)
    }
}
