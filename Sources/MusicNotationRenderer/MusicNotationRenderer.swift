// MusicNotationRenderer Module
// Core Graphics rendering for music notation

import Foundation
import CoreGraphics
import CoreText
import MusicNotationCore
import MusicNotationLayout
import SMuFLKit

// MARK: - Music Renderer Protocol

/// Protocol for music renderers, enabling dependency injection and testing.
///
/// Conform to this protocol to create custom renderers or mock
/// implementations for testing without actual Core Graphics rendering.
public protocol MusicRendererProtocol {
    /// The rendering configuration controlling colors and line thicknesses.
    var config: RenderConfiguration { get set }

    /// The SMuFL font used for rendering musical glyphs.
    var font: LoadedSMuFLFont? { get set }

    /// Renders a single page from an engraved score to a Core Graphics context.
    ///
    /// - Parameters:
    ///   - score: The engraved score containing layout information.
    ///   - pageIndex: The zero-based index of the page to render.
    ///   - context: The Core Graphics context to render into.
    func render(score: EngravedScore, pageIndex: Int, in context: CGContext)
}

// MARK: - Music Renderer

/// Renders engraved music notation to Core Graphics contexts.
///
/// `MusicRenderer` is the core rendering engine that draws engraved scores using
/// Core Graphics. It handles all notation elements including notes, rests, clefs,
/// key signatures, time signatures, barlines, and more.
///
/// The renderer works with `EngravedScore` objects produced by `LayoutEngine`.
/// It uses SMuFL-compliant fonts for musical glyphs, ensuring professional-quality
/// output suitable for print or display.
///
/// ## Usage
///
/// Basic rendering to a Core Graphics context:
///
/// ```swift
/// // Set up renderer with custom configuration
/// var config = RenderConfiguration()
/// config.backgroundColor = CGColor(gray: 1, alpha: 1)
/// config.noteColor = CGColor(gray: 0, alpha: 1)
///
/// let renderer = MusicRenderer(config: config)
/// renderer.font = loadedFont
///
/// // Render a specific page
/// renderer.render(score: engravedScore, pageIndex: 0, in: cgContext)
/// ```
///
/// ## Integration with SwiftUI
///
/// For SwiftUI apps, use `ScoreViewRepresentable` which handles rendering internally:
///
/// ```swift
/// ScoreViewRepresentable(
///     score: $score,
///     layoutContext: LayoutContext.letterSize(staffHeight: 40)
/// )
/// ```
///
/// ## Customization
///
/// Customize appearance through `RenderConfiguration`:
/// - Colors for staff lines, notes, barlines, and background
/// - Line thicknesses for staff lines, barlines, stems, and brackets
///
/// ## Thread Safety
///
/// `MusicRenderer` is not thread-safe. Each rendering context should use its own
/// renderer instance, or rendering calls should be serialized.
///
/// - SeeAlso: `RenderConfiguration` for customizing visual appearance
/// - SeeAlso: `RenderContext` for per-render state
/// - SeeAlso: `ScoreViewRepresentable` for SwiftUI integration
public final class MusicRenderer: MusicRendererProtocol {
    /// The rendering configuration controlling colors and line thicknesses.
    ///
    /// Modify this property to change the visual appearance of rendered scores.
    /// Changes take effect on the next render call.
    public var config: RenderConfiguration

    /// The SMuFL font used for rendering musical glyphs.
    ///
    /// This must be set before rendering. Load a font using `SMuFLFontManager`:
    ///
    /// ```swift
    /// let font = try SMuFLFontManager.shared.loadFont(named: "Bravura")
    /// renderer.font = font
    /// ```
    ///
    /// If `nil`, glyph rendering will be skipped but staff lines and barlines
    /// will still be drawn.
    public var font: LoadedSMuFLFont?

    /// Creates a new music renderer with the specified configuration.
    ///
    /// - Parameter config: The rendering configuration. Defaults to standard
    ///   black-on-white rendering with typical line thicknesses.
    public init(config: RenderConfiguration = RenderConfiguration()) {
        self.config = config
    }

    /// Renders a single page from an engraved score to a Core Graphics context.
    ///
    /// This is the primary entry point for rendering. The method draws all elements
    /// on the specified page, including:
    /// - Page background
    /// - Title and credit text
    /// - Staff systems with staff lines
    /// - Barlines and measure content
    /// - All notation elements (notes, rests, clefs, etc.)
    ///
    /// - Parameters:
    ///   - score: The engraved score containing layout information.
    ///   - pageIndex: The zero-based index of the page to render.
    ///   - context: The Core Graphics context to render into.
    ///
    /// - Note: If the page index is out of bounds, this method returns silently
    ///   without rendering anything.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Render all pages
    /// for pageIndex in 0..<engravedScore.pages.count {
    ///     cgContext.beginPage(mediaBox: &pageRect)
    ///     renderer.render(score: engravedScore, pageIndex: pageIndex, in: cgContext)
    ///     cgContext.endPage()
    /// }
    /// ```
    public func render(score: EngravedScore, pageIndex: Int, in context: CGContext) {
        guard pageIndex < score.pages.count else { return }
        let page = score.pages[pageIndex]

        let renderContext = RenderContext(
            font: font,
            scaling: score.scaling,
            config: config,
            visibleRect: CGRect(origin: .zero, size: page.frame.size)
        )

        renderPage(page, in: context, renderContext: renderContext)
    }

    /// Renders a single engraved page to a Core Graphics context.
    ///
    /// This method renders a complete page including background fill, credits
    /// (title, composer), and all staff systems. Use this for lower-level control
    /// when you need to render individual pages with custom render context settings.
    ///
    /// - Parameters:
    ///   - page: The engraved page to render.
    ///   - context: The Core Graphics context to render into.
    ///   - renderContext: The render context providing font, scaling, and configuration.
    ///
    /// - Note: This method modifies the graphics state but saves and restores it,
    ///   leaving the context in its original state after rendering.
    public func renderPage(_ page: EngravedPage, in context: CGContext, renderContext: RenderContext) {
        context.saveGState()

        // Fill background
        if let bgColor = config.backgroundColor {
            context.setFillColor(bgColor)
            context.fill(page.frame)
        }

        // Render credits (titles, composer)
        for credit in page.credits {
            renderCredit(credit, in: context, renderContext: renderContext)
        }

        // Render systems
        for system in page.systems {
            renderSystem(system, in: context, renderContext: renderContext)
        }

        context.restoreGState()
    }

    // MARK: - System Rendering

    private func renderSystem(_ system: EngravedSystem, in context: CGContext, renderContext: RenderContext) {
        context.saveGState()
        context.translateBy(x: system.frame.origin.x, y: system.frame.origin.y)

        // Render staff lines
        for staff in system.staves {
            renderStaffLines(staff, in: context, renderContext: renderContext)
        }

        // Render staff groupings (brackets, braces)
        for grouping in system.groupings {
            renderStaffGrouping(grouping, staves: system.staves, in: context, renderContext: renderContext)
        }

        // Render system barlines
        for barline in system.systemBarlines {
            renderSystemBarline(barline, in: context, renderContext: renderContext)
        }

        // Render measures
        for measure in system.measures {
            renderMeasure(measure, in: context, renderContext: renderContext)
        }

        context.restoreGState()
    }

    private func renderStaffLines(_ staff: EngravedStaff, in context: CGContext, renderContext: RenderContext) {
        context.saveGState()

        let lineWidth = renderContext.config.staffLineThickness
        context.setLineWidth(lineWidth)
        context.setStrokeColor(config.staffLineColor)

        let staffSpacing = staff.staffHeight / CGFloat(staff.lineCount - 1)

        for i in 0..<staff.lineCount {
            let y = staff.frame.origin.y + CGFloat(i) * staffSpacing
            context.move(to: CGPoint(x: staff.frame.minX, y: y))
            context.addLine(to: CGPoint(x: staff.frame.maxX, y: y))
        }

        context.strokePath()
        context.restoreGState()
    }

    private func renderStaffGrouping(_ grouping: EngravedStaffGrouping, staves: [EngravedStaff], in context: CGContext, renderContext: RenderContext) {
        // Calculate Y positions from staff indices
        guard grouping.topStaffIndex < staves.count,
              grouping.bottomStaffIndex < staves.count else {
            return
        }

        let topStaff = staves[grouping.topStaffIndex]
        let bottomStaff = staves[grouping.bottomStaffIndex]
        let topY = topStaff.frame.minY
        let bottomY = bottomStaff.frame.maxY

        switch grouping.symbol {
        case .brace:
            // Render brace glyph using GlyphRenderer
            if let font = renderContext.font {
                let glyphRenderer = GlyphRenderer(font: font)
                glyphRenderer.renderBrace(
                    at: grouping.x,
                    topY: topY,
                    bottomY: bottomY,
                    color: config.staffLineColor,
                    in: context
                )
            }

        case .bracket:
            // Draw bracket using GlyphRenderer
            if let font = renderContext.font {
                let glyphRenderer = GlyphRenderer(font: font)
                glyphRenderer.renderBracket(
                    at: grouping.x,
                    topY: topY,
                    bottomY: bottomY,
                    thickness: renderContext.config.bracketThickness,
                    color: config.staffLineColor,
                    in: context
                )
            }

        case .line, .square, .none:
            break
        }
    }

    private func renderSystemBarline(_ barline: EngravedSystemBarline, in context: CGContext, renderContext: RenderContext) {
        context.saveGState()
        context.setStrokeColor(config.barlineColor)
        context.setLineWidth(renderContext.config.thinBarlineThickness)

        context.move(to: CGPoint(x: barline.x, y: barline.topY))
        context.addLine(to: CGPoint(x: barline.x, y: barline.bottomY))
        context.strokePath()

        context.restoreGState()
    }

    // MARK: - Measure Rendering

    private func renderMeasure(_ measure: EngravedMeasure, in context: CGContext, renderContext: RenderContext) {
        context.saveGState()
        context.translateBy(x: measure.frame.origin.x, y: measure.frame.origin.y)

        // Render barlines
        renderBarline(at: measure.leftBarlineX - measure.frame.origin.x, style: .regular, height: measure.frame.height, in: context, renderContext: renderContext)
        renderBarline(at: measure.rightBarlineX - measure.frame.origin.x, style: .regular, height: measure.frame.height, in: context, renderContext: renderContext)

        // Render elements by staff
        for (_, elements) in measure.elementsByStaff {
            for element in elements {
                renderElement(element, in: context, renderContext: renderContext)
            }
        }

        context.restoreGState()
    }

    private func renderBarline(at x: CGFloat, style: BarStyle, height: CGFloat, in context: CGContext, renderContext: RenderContext) {
        context.saveGState()
        context.setStrokeColor(config.barlineColor)

        switch style {
        case .regular:
            context.setLineWidth(renderContext.config.thinBarlineThickness)
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: height))
            context.strokePath()

        case .lightHeavy:
            // Thin bar
            context.setLineWidth(renderContext.config.thinBarlineThickness)
            context.move(to: CGPoint(x: x - 4, y: 0))
            context.addLine(to: CGPoint(x: x - 4, y: height))
            context.strokePath()
            // Thick bar
            context.setLineWidth(renderContext.config.thickBarlineThickness)
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: height))
            context.strokePath()

        case .heavyLight:
            // Thick bar
            context.setLineWidth(renderContext.config.thickBarlineThickness)
            context.move(to: CGPoint(x: x - 4, y: 0))
            context.addLine(to: CGPoint(x: x - 4, y: height))
            context.strokePath()
            // Thin bar
            context.setLineWidth(renderContext.config.thinBarlineThickness)
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: height))
            context.strokePath()

        default:
            // Default to regular
            context.setLineWidth(renderContext.config.thinBarlineThickness)
            context.move(to: CGPoint(x: x, y: 0))
            context.addLine(to: CGPoint(x: x, y: height))
            context.strokePath()
        }

        context.restoreGState()
    }

    // MARK: - Element Rendering

    private func renderElement(_ element: EngravedElement, in context: CGContext, renderContext: RenderContext) {
        switch element {
        case .note(let note):
            renderNote(note, in: context, renderContext: renderContext)
        case .rest(let rest):
            renderRest(rest, in: context, renderContext: renderContext)
        case .chord(let chord):
            renderChord(chord, in: context, renderContext: renderContext)
        case .clef(let clef):
            renderClef(clef, in: context, renderContext: renderContext)
        case .keySignature(let keySig):
            renderKeySignature(keySig, in: context, renderContext: renderContext)
        case .timeSignature(let timeSig):
            renderTimeSignature(timeSig, in: context, renderContext: renderContext)
        case .barline(let barline):
            renderBarline(at: barline.frame.origin.x, style: barline.style, height: barline.frame.height, in: context, renderContext: renderContext)
        case .direction(let direction):
            renderDirection(direction, in: context, renderContext: renderContext)
        }
    }

    private func renderNote(_ note: EngravedNote, in context: CGContext, renderContext: RenderContext) {
        guard let font = renderContext.font else { return }

        // Render accidental if present
        if let accidentalGlyph = note.accidentalGlyph {
            let accidentalPos = CGPoint(
                x: note.position.x + note.accidentalOffset,
                y: note.position.y
            )
            renderGlyph(accidentalGlyph, at: accidentalPos, font: font, in: context)
        }

        // Render notehead
        renderGlyph(note.noteheadGlyph, at: note.position, font: font, in: context)

        // Render stem
        if let stem = note.stem {
            renderStem(stem, in: context, renderContext: renderContext)
        }

        // Render flag
        if let flagGlyph = note.flagGlyph, let stem = note.stem {
            let flagPos = stem.direction == .up ? stem.end : stem.start
            renderGlyph(flagGlyph, at: flagPos, font: font, in: context)
        }

        // Render dots
        for dotPos in note.dots {
            renderGlyph(.augmentationDot, at: dotPos, font: font, in: context)
        }
    }

    private func renderRest(_ rest: EngravedRest, in context: CGContext, renderContext: RenderContext) {
        guard let font = renderContext.font else { return }
        renderGlyph(rest.glyph, at: rest.position, font: font, in: context)
    }

    private func renderChord(_ chord: EngravedChord, in context: CGContext, renderContext: RenderContext) {
        // Render all notes in the chord
        for note in chord.notes {
            renderNote(note, in: context, renderContext: renderContext)
        }
    }

    private func renderClef(_ clef: EngravedClef, in context: CGContext, renderContext: RenderContext) {
        guard let font = renderContext.font else { return }
        renderGlyph(clef.glyph, at: clef.position, font: font, in: context)
    }

    private func renderKeySignature(_ keySig: EngravedKeySignature, in context: CGContext, renderContext: RenderContext) {
        guard let font = renderContext.font else { return }
        for (glyph, position) in keySig.accidentals {
            renderGlyph(glyph, at: position, font: font, in: context)
        }
    }

    private func renderTimeSignature(_ timeSig: EngravedTimeSignature, in context: CGContext, renderContext: RenderContext) {
        guard let font = renderContext.font else { return }

        // Render symbol if present (common/cut time)
        if let symbolGlyph = timeSig.symbolGlyph {
            renderGlyph(symbolGlyph, at: timeSig.position, font: font, in: context)
        } else {
            // Render numerator and denominator
            for (glyph, position) in timeSig.topGlyphs {
                renderGlyph(glyph, at: position, font: font, in: context)
            }
            for (glyph, position) in timeSig.bottomGlyphs {
                renderGlyph(glyph, at: position, font: font, in: context)
            }
        }
    }

    private func renderDirection(_ direction: EngravedDirection, in context: CGContext, renderContext: RenderContext) {
        guard let font = renderContext.font else { return }

        switch direction.content {
        case .text(let text):
            renderText(text, at: direction.position, fontSize: 12, in: context)

        case .dynamic(let glyph):
            renderGlyph(glyph, at: direction.position, font: font, in: context)

        case .wedge(let wedge):
            renderWedge(wedge, at: direction.position.y, in: context, renderContext: renderContext)

        case .metronome(let metronome):
            // Simplified metronome rendering
            renderText("\(metronome.bpm)", at: direction.position, fontSize: 12, in: context)
        }
    }

    private func renderStem(_ stem: EngravedStem, in context: CGContext, renderContext: RenderContext) {
        context.saveGState()
        context.setStrokeColor(config.noteColor)
        context.setLineWidth(stem.thickness)
        context.move(to: stem.start)
        context.addLine(to: stem.end)
        context.strokePath()
        context.restoreGState()
    }

    private func renderWedge(_ wedge: WedgeContent, at y: CGFloat, in context: CGContext, renderContext: RenderContext) {
        context.saveGState()
        context.setStrokeColor(config.noteColor)
        context.setLineWidth(1)

        if wedge.isCresc {
            // Crescendo: < shape opening to the right
            context.move(to: CGPoint(x: wedge.startX, y: y))
            context.addLine(to: CGPoint(x: wedge.endX, y: y - wedge.spreadEnd / 2))
            context.move(to: CGPoint(x: wedge.startX, y: y))
            context.addLine(to: CGPoint(x: wedge.endX, y: y + wedge.spreadEnd / 2))
        } else {
            // Diminuendo: > shape closing to the right
            context.move(to: CGPoint(x: wedge.startX, y: y - wedge.spreadStart / 2))
            context.addLine(to: CGPoint(x: wedge.endX, y: y))
            context.move(to: CGPoint(x: wedge.startX, y: y + wedge.spreadStart / 2))
            context.addLine(to: CGPoint(x: wedge.endX, y: y))
        }

        context.strokePath()
        context.restoreGState()
    }

    // MARK: - Credit Rendering

    private func renderCredit(_ credit: EngravedCredit, in context: CGContext, renderContext: RenderContext) {
        renderText(credit.text, at: credit.position, fontSize: credit.fontSize, alignment: credit.justification, in: context)
    }

    // MARK: - Primitive Rendering

    private func renderGlyph(_ glyphName: SMuFLGlyphName, at position: CGPoint, font: LoadedSMuFLFont, in context: CGContext) {
        let ctFont = font.ctFont

        // Get glyph name as string
        let glyphNameString = glyphName.rawValue as CFString
        var glyph = CTFontGetGlyphWithName(ctFont, glyphNameString)

        if glyph != 0 {
            context.saveGState()
            context.setFillColor(config.noteColor)

            var glyphPosition = position
            CTFontDrawGlyphs(ctFont, &glyph, &glyphPosition, 1, context)

            context.restoreGState()
        }
    }

    private func renderText(_ text: String, at position: CGPoint, fontSize: CGFloat, alignment: Justification? = nil, in context: CGContext) {
        context.saveGState()

        let font = CTFontCreateWithName("Helvetica" as CFString, fontSize, nil)
        let attributes: [CFString: Any] = [
            kCTFontAttributeName: font,
            kCTForegroundColorFromContextAttributeName: true
        ]

        guard let attributedString = CFAttributedStringCreate(nil, text as CFString, attributes as CFDictionary) else {
            context.restoreGState()
            return
        }
        let line = CTLineCreateWithAttributedString(attributedString)

        var drawPosition = position

        // Adjust for alignment
        if let alignment = alignment {
            let bounds = CTLineGetBoundsWithOptions(line, [])
            switch alignment {
            case .center:
                drawPosition.x -= bounds.width / 2
            case .right:
                drawPosition.x -= bounds.width
            case .left:
                break
            }
        }

        context.textPosition = drawPosition
        context.setFillColor(config.noteColor)
        CTLineDraw(line, context)

        context.restoreGState()
    }
}

// MARK: - Render Context

/// Encapsulates state for a single rendering operation.
///
/// `RenderContext` bundles together the font, scaling information, configuration,
/// and viewport data needed during rendering. It's typically created by `MusicRenderer`
/// for each render call, but can be created manually for custom rendering scenarios.
///
/// ## Usage
///
/// Create a render context for custom rendering:
///
/// ```swift
/// let context = RenderContext(
///     font: loadedFont,
///     scaling: engravedScore.scaling,
///     config: RenderConfiguration(),
///     visibleRect: viewBounds
/// )
/// ```
///
/// ## Visibility Culling
///
/// The `visibleRect` property enables rendering optimization by skipping elements
/// outside the visible area. This is particularly useful for large scores where
/// only a portion is visible on screen.
///
/// - SeeAlso: `MusicRenderer` for the main rendering class
/// - SeeAlso: `RenderConfiguration` for visual settings
public struct RenderContext: Sendable {
    /// The loaded SMuFL font for rendering musical glyphs.
    ///
    /// If `nil`, glyph rendering calls will be skipped.
    public var font: LoadedSMuFLFont?

    /// The scaling context providing unit conversion factors.
    ///
    /// This contains the relationship between staff spaces, tenths, and points,
    /// enabling accurate positioning of elements based on the layout engine's output.
    public var scaling: ScalingContext

    /// The rendering configuration for colors and line thicknesses.
    public var config: RenderConfiguration

    /// The visible rectangle for culling optimization.
    ///
    /// Elements entirely outside this rectangle may be skipped during rendering.
    /// Use `.infinite` to render all elements regardless of position.
    public var visibleRect: CGRect

    /// Creates a new render context.
    ///
    /// - Parameters:
    ///   - font: The SMuFL font for glyphs. Pass `nil` if only rendering structural
    ///     elements like staff lines and barlines.
    ///   - scaling: The scaling context from the layout engine. Defaults to a
    ///     standard scaling if not specified.
    ///   - config: The rendering configuration. Defaults to standard black-on-white.
    ///   - visibleRect: The visible area for culling. Defaults to `.infinite`
    ///     (no culling).
    public init(
        font: LoadedSMuFLFont? = nil,
        scaling: ScalingContext = ScalingContext(),
        config: RenderConfiguration = RenderConfiguration(),
        visibleRect: CGRect = .infinite
    ) {
        self.font = font
        self.scaling = scaling
        self.config = config
        self.visibleRect = visibleRect
    }

    /// The size of one staff space in points.
    ///
    /// A staff space is the distance between two adjacent staff lines. This is
    /// the fundamental unit of measurement in music notation. Multiply by this
    /// value to convert staff-space units to points for rendering.
    public var staffSpace: CGFloat {
        scaling.pointsPerStaffSpace
    }
}

// MARK: - Render Configuration

/// Controls the visual appearance of rendered music notation.
///
/// `RenderConfiguration` provides fine-grained control over colors and line
/// thicknesses used when rendering scores. The default values produce standard
/// black-on-white engraving suitable for most use cases.
///
/// ## Usage
///
/// Create a custom configuration:
///
/// ```swift
/// var config = RenderConfiguration()
///
/// // Custom colors
/// config.backgroundColor = CGColor(red: 1, green: 0.98, blue: 0.94, alpha: 1) // Cream
/// config.noteColor = CGColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1) // Dark blue
///
/// // Thicker lines for large displays
/// config.staffLineThickness = 1.2
/// config.stemThickness = 1.0
///
/// let renderer = MusicRenderer(config: config)
/// ```
///
/// ## Dark Mode Support
///
/// For dark mode interfaces, invert the colors:
///
/// ```swift
/// var darkConfig = RenderConfiguration()
/// darkConfig.backgroundColor = CGColor(gray: 0.1, alpha: 1)
/// darkConfig.staffLineColor = CGColor(gray: 0.9, alpha: 1)
/// darkConfig.barlineColor = CGColor(gray: 0.9, alpha: 1)
/// darkConfig.noteColor = CGColor(gray: 0.95, alpha: 1)
/// ```
///
/// ## Transparent Background
///
/// For compositing over other content, use a transparent background:
///
/// ```swift
/// var config = RenderConfiguration()
/// config.backgroundColor = nil // Transparent
/// ```
///
/// - SeeAlso: `MusicRenderer` for applying configuration
/// - SeeAlso: `ExportConfiguration` for export-specific settings
public struct RenderConfiguration: Sendable {
    /// Background color for the rendered page.
    ///
    /// Set to `nil` for a transparent background, useful when compositing
    /// notation over other content.
    ///
    /// Default: White (`CGColor(gray: 1, alpha: 1)`)
    public var backgroundColor: CGColor?

    /// Color for staff lines.
    ///
    /// Default: Black (`CGColor(gray: 0, alpha: 1)`)
    public var staffLineColor: CGColor

    /// Color for barlines.
    ///
    /// Default: Black (`CGColor(gray: 0, alpha: 1)`)
    public var barlineColor: CGColor

    /// Color for notes, rests, and other glyphs.
    ///
    /// This affects noteheads, stems, flags, rests, accidentals, clefs,
    /// dynamics, and other SMuFL glyphs.
    ///
    /// Default: Black (`CGColor(gray: 0, alpha: 1)`)
    public var noteColor: CGColor

    /// Thickness of staff lines in points.
    ///
    /// Standard engraving typically uses thin staff lines (0.5-1.0 points).
    /// Increase for better visibility on screens or in small sizes.
    ///
    /// Default: 0.8 points
    public var staffLineThickness: CGFloat

    /// Thickness of thin barlines in points.
    ///
    /// Used for regular barlines and the thin component of double barlines.
    ///
    /// Default: 0.8 points
    public var thinBarlineThickness: CGFloat

    /// Thickness of thick barlines in points.
    ///
    /// Used for final barlines and the thick component of start/end repeat signs.
    ///
    /// Default: 3.0 points
    public var thickBarlineThickness: CGFloat

    /// Thickness of staff brackets in points.
    ///
    /// Staff brackets connect staves that belong to the same instrument group
    /// (e.g., all woodwinds, all strings).
    ///
    /// Default: 2.0 points
    public var bracketThickness: CGFloat

    /// Thickness of note stems in points.
    ///
    /// Default: 0.8 points
    public var stemThickness: CGFloat

    /// Creates a render configuration with the specified appearance settings.
    ///
    /// All parameters have sensible defaults for standard black-on-white engraving.
    /// Customize only the properties you need to change.
    ///
    /// - Parameters:
    ///   - backgroundColor: Page background color, or `nil` for transparent.
    ///   - staffLineColor: Color for the five staff lines.
    ///   - barlineColor: Color for measure barlines.
    ///   - noteColor: Color for notes, rests, and musical glyphs.
    ///   - staffLineThickness: Width of staff lines in points.
    ///   - thinBarlineThickness: Width of thin barlines in points.
    ///   - thickBarlineThickness: Width of thick barlines in points.
    ///   - bracketThickness: Width of staff brackets in points.
    ///   - stemThickness: Width of note stems in points.
    public init(
        backgroundColor: CGColor? = CGColor(gray: 1, alpha: 1),
        staffLineColor: CGColor = CGColor(gray: 0, alpha: 1),
        barlineColor: CGColor = CGColor(gray: 0, alpha: 1),
        noteColor: CGColor = CGColor(gray: 0, alpha: 1),
        staffLineThickness: CGFloat = 0.8,
        thinBarlineThickness: CGFloat = 0.8,
        thickBarlineThickness: CGFloat = 3.0,
        bracketThickness: CGFloat = 2.0,
        stemThickness: CGFloat = 0.8
    ) {
        self.backgroundColor = backgroundColor
        self.staffLineColor = staffLineColor
        self.barlineColor = barlineColor
        self.noteColor = noteColor
        self.staffLineThickness = staffLineThickness
        self.thinBarlineThickness = thinBarlineThickness
        self.thickBarlineThickness = thickBarlineThickness
        self.bracketThickness = bracketThickness
        self.stemThickness = stemThickness
    }
}
