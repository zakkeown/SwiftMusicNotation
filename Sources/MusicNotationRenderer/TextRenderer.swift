import Foundation
import CoreGraphics
import CoreText
import MusicNotationCore
import SMuFLKit

// MARK: - Text Renderer

/// Renders text elements in music notation including lyrics, dynamics, tempo markings, and directions.
public final class TextRenderer {
    /// Configuration for text rendering.
    public var config: TextRenderConfiguration

    /// Cached fonts for performance.
    private var fontCache: [FontCacheKey: CTFont] = [:]

    public init(config: TextRenderConfiguration = TextRenderConfiguration()) {
        self.config = config
    }

    // MARK: - Basic Text Rendering

    /// Renders simple text.
    public func renderText(
        _ text: String,
        at position: CGPoint,
        fontSize: CGFloat,
        fontName: String? = nil,
        color: CGColor,
        in context: CGContext
    ) {
        let font = getFont(name: fontName ?? config.defaultFontName, size: fontSize)
        renderText(text, at: position, font: font, color: color, in: context)
    }

    /// Renders text with a CTFont.
    public func renderText(
        _ text: String,
        at position: CGPoint,
        font: CTFont,
        color: CGColor,
        in context: CGContext
    ) {
        context.saveGState()
        context.setFillColor(color)

        let attributes: [CFString: Any] = [
            kCTFontAttributeName: font,
            kCTForegroundColorFromContextAttributeName: true
        ]

        let attributedString = CFAttributedStringCreate(nil, text as CFString, attributes as CFDictionary)!
        let line = CTLineCreateWithAttributedString(attributedString)

        context.textPosition = position
        CTLineDraw(line, context)

        context.restoreGState()
    }

    /// Renders text with alignment.
    public func renderAlignedText(
        _ text: String,
        at position: CGPoint,
        fontSize: CGFloat,
        fontName: String? = nil,
        alignment: TextAlignment,
        color: CGColor,
        in context: CGContext
    ) {
        let font = getFont(name: fontName ?? config.defaultFontName, size: fontSize)
        let bounds = measureText(text, font: font)

        var drawPosition = position
        switch alignment {
        case .left:
            break
        case .center:
            drawPosition.x -= bounds.width / 2
        case .right:
            drawPosition.x -= bounds.width
        }

        renderText(text, at: drawPosition, font: font, color: color, in: context)
    }

    // MARK: - Lyrics Rendering

    /// Renders a lyric syllable.
    public func renderLyric(
        _ lyric: LyricRenderInfo,
        color: CGColor,
        in context: CGContext
    ) {
        // Render syllable text
        renderAlignedText(
            lyric.text,
            at: lyric.position,
            fontSize: config.lyricFontSize,
            fontName: config.lyricFontName,
            alignment: .center,
            color: color,
            in: context
        )

        // Render syllable connector (hyphen or extender)
        if let connector = lyric.connector {
            renderLyricConnector(connector, color: color, in: context)
        }
    }

    /// Renders a lyric connector (hyphen or extender line).
    public func renderLyricConnector(
        _ connector: LyricConnector,
        color: CGColor,
        in context: CGContext
    ) {
        context.saveGState()

        switch connector.type {
        case .hyphen:
            // Draw hyphen centered between syllables
            let hyphenText = "-"
            let centerX = (connector.startX + connector.endX) / 2
            renderAlignedText(
                hyphenText,
                at: CGPoint(x: centerX, y: connector.y),
                fontSize: config.lyricFontSize,
                fontName: config.lyricFontName,
                alignment: .center,
                color: color,
                in: context
            )

        case .extender:
            // Draw extender line
            context.setStrokeColor(color)
            context.setLineWidth(config.lyricExtenderThickness)
            context.move(to: CGPoint(x: connector.startX, y: connector.y))
            context.addLine(to: CGPoint(x: connector.endX, y: connector.y))
            context.strokePath()

        case .elision:
            // Draw elision character (undertie)
            let elisionText = "‿" // Undertie character
            let centerX = (connector.startX + connector.endX) / 2
            renderAlignedText(
                elisionText,
                at: CGPoint(x: centerX, y: connector.y),
                fontSize: config.lyricFontSize,
                alignment: .center,
                color: color,
                in: context
            )
        }

        context.restoreGState()
    }

    /// Renders multiple verses of lyrics.
    public func renderLyricVerses(
        verses: [[LyricRenderInfo]],
        color: CGColor,
        in context: CGContext
    ) {
        for verse in verses {
            for lyric in verse {
                renderLyric(lyric, color: color, in: context)
            }
        }
    }

    // MARK: - Dynamic Text Rendering

    /// Renders a text dynamic marking.
    public func renderDynamicText(
        _ text: String,
        at position: CGPoint,
        color: CGColor,
        in context: CGContext
    ) {
        // Dynamics use italic for text expressions like "cresc." or "dim."
        renderAlignedText(
            text,
            at: position,
            fontSize: config.dynamicFontSize,
            fontName: config.dynamicFontName,
            alignment: .center,
            color: color,
            in: context
        )
    }

    // MARK: - Tempo Markings

    /// Renders a tempo marking.
    public func renderTempoMarking(
        _ tempo: TempoRenderInfo,
        color: CGColor,
        in context: CGContext
    ) {
        var currentX = tempo.position.x

        // Render text (e.g., "Allegro")
        if let text = tempo.text {
            let font = getFont(
                name: config.tempoFontName,
                size: config.tempoFontSize,
                traits: .traitBold
            )
            renderText(text, at: CGPoint(x: currentX, y: tempo.position.y), font: font, color: color, in: context)

            let textWidth = measureText(text, font: font).width
            currentX += textWidth + config.tempoSpacing
        }

        // Render metronome marking (if present)
        if let metronome = tempo.metronome {
            // Note: The note glyph should be rendered using GlyphRenderer
            // Here we just render the "= BPM" part
            let bpmText = "= \(metronome.bpm)"
            renderText(
                bpmText,
                at: CGPoint(x: currentX, y: tempo.position.y),
                fontSize: config.tempoFontSize,
                color: color,
                in: context
            )
        }
    }

    // MARK: - Direction Text

    /// Renders a text direction (words element).
    public func renderDirection(
        _ direction: DirectionTextRenderInfo,
        color: CGColor,
        in context: CGContext
    ) {
        var traits: CTFontSymbolicTraits = []
        if direction.isItalic {
            traits.insert(.traitItalic)
        }
        if direction.isBold {
            traits.insert(.traitBold)
        }

        let fontSize = direction.fontSize ?? config.directionFontSize
        // Note: traits are built but renderAlignedText doesn't use them directly
        // Future enhancement: pass traits to renderAlignedText
        _ = traits

        renderAlignedText(
            direction.text,
            at: direction.position,
            fontSize: fontSize,
            fontName: direction.fontName ?? config.directionFontName,
            alignment: direction.alignment,
            color: color,
            in: context
        )
    }

    // MARK: - Rehearsal Marks

    /// Renders a rehearsal mark.
    public func renderRehearsalMark(
        _ mark: RehearsalMarkRenderInfo,
        color: CGColor,
        backgroundColor: CGColor?,
        in context: CGContext
    ) {
        let font = getFont(
            name: config.rehearsalFontName,
            size: config.rehearsalFontSize,
            traits: .traitBold
        )

        let textBounds = measureText(mark.text, font: font)

        // Draw enclosure if needed
        if let enclosure = mark.enclosure {
            let padding = config.rehearsalPadding
            let enclosureRect = CGRect(
                x: mark.position.x - textBounds.width / 2 - padding,
                y: mark.position.y - textBounds.height - padding,
                width: textBounds.width + padding * 2,
                height: textBounds.height + padding * 2
            )

            context.saveGState()

            // Fill background
            if let bgColor = backgroundColor {
                context.setFillColor(bgColor)
                fillEnclosure(enclosure, rect: enclosureRect, in: context)
            }

            // Draw border
            context.setStrokeColor(color)
            context.setLineWidth(config.rehearsalBorderThickness)
            strokeEnclosure(enclosure, rect: enclosureRect, in: context)

            context.restoreGState()
        }

        // Draw text
        renderAlignedText(
            mark.text,
            at: mark.position,
            fontSize: config.rehearsalFontSize,
            fontName: config.rehearsalFontName,
            alignment: .center,
            color: color,
            in: context
        )
    }

    private func fillEnclosure(_ enclosure: EnclosureType, rect: CGRect, in context: CGContext) {
        switch enclosure {
        case .rectangle, .square:
            context.fill(rect)
        case .circle, .oval:
            context.fillEllipse(in: rect)
        case .diamond:
            let path = diamondPath(for: rect)
            context.addPath(path)
            context.fillPath()
        case .triangle:
            let path = trianglePath(for: rect)
            context.addPath(path)
            context.fillPath()
        case .none:
            break
        }
    }

    private func strokeEnclosure(_ enclosure: EnclosureType, rect: CGRect, in context: CGContext) {
        switch enclosure {
        case .rectangle, .square:
            context.stroke(rect)
        case .circle, .oval:
            context.strokeEllipse(in: rect)
        case .diamond:
            let path = diamondPath(for: rect)
            context.addPath(path)
            context.strokePath()
        case .triangle:
            let path = trianglePath(for: rect)
            context.addPath(path)
            context.strokePath()
        case .none:
            break
        }
    }

    private func diamondPath(for rect: CGRect) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY))
        path.closeSubpath()
        return path
    }

    private func trianglePath(for rect: CGRect) -> CGPath {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }

    // MARK: - Credits (Title, Composer, etc.)

    /// Renders score credits.
    public func renderCredit(
        _ credit: CreditRenderInfo,
        color: CGColor,
        in context: CGContext
    ) {
        var traits: CTFontSymbolicTraits = []
        if credit.isItalic {
            traits.insert(.traitItalic)
        }
        if credit.isBold {
            traits.insert(.traitBold)
        }

        // Note: traits are built but renderAlignedText doesn't use them directly
        // Future enhancement: pass traits to renderAlignedText
        _ = traits

        renderAlignedText(
            credit.text,
            at: credit.position,
            fontSize: credit.fontSize,
            fontName: credit.fontName ?? config.creditFontName,
            alignment: credit.alignment,
            color: color,
            in: context
        )
    }

    // MARK: - Text Measurement

    /// Measures the bounds of text.
    public func measureText(_ text: String, fontSize: CGFloat, fontName: String? = nil) -> CGRect {
        let font = getFont(name: fontName ?? config.defaultFontName, size: fontSize)
        return measureText(text, font: font)
    }

    /// Measures the bounds of text with a CTFont.
    public func measureText(_ text: String, font: CTFont) -> CGRect {
        let attributes: [CFString: Any] = [kCTFontAttributeName: font]
        let attributedString = CFAttributedStringCreate(nil, text as CFString, attributes as CFDictionary)!
        let line = CTLineCreateWithAttributedString(attributedString)
        let bounds = CTLineGetBoundsWithOptions(line, [])
        return bounds
    }

    // MARK: - Font Management

    /// Gets or creates a font.
    private func getFont(name: String, size: CGFloat, traits: CTFontSymbolicTraits = []) -> CTFont {
        let key = FontCacheKey(name: name, size: size, traits: traits.rawValue)

        if let cached = fontCache[key] {
            return cached
        }

        var font = CTFontCreateWithName(name as CFString, size, nil)

        // Apply traits if needed
        if !traits.isEmpty {
            let descriptor = CTFontCopyFontDescriptor(font)
            let traitsDict: [CFString: Any] = [
                kCTFontSymbolicTrait: traits.rawValue
            ]
            let newDescriptor = CTFontDescriptorCreateCopyWithAttributes(
                descriptor,
                [kCTFontTraitsAttribute: traitsDict] as CFDictionary
            )
            font = CTFontCreateWithFontDescriptor(newDescriptor, size, nil)
        }

        fontCache[key] = font
        return font
    }

    /// Clears the font cache.
    public func clearFontCache() {
        fontCache.removeAll()
    }
}

// MARK: - Font Cache Key

private struct FontCacheKey: Hashable {
    let name: String
    let size: CGFloat
    let traits: UInt32
}

// MARK: - Text Render Configuration

/// Configuration for text rendering.
public struct TextRenderConfiguration: Sendable {
    /// Default font name.
    public var defaultFontName: String = "Helvetica"

    /// Lyric font name.
    public var lyricFontName: String = "Times New Roman"

    /// Lyric font size.
    public var lyricFontSize: CGFloat = 10

    /// Lyric extender line thickness.
    public var lyricExtenderThickness: CGFloat = 0.5

    /// Dynamic font name.
    public var dynamicFontName: String = "Times New Roman"

    /// Dynamic font size.
    public var dynamicFontSize: CGFloat = 12

    /// Tempo font name.
    public var tempoFontName: String = "Helvetica"

    /// Tempo font size.
    public var tempoFontSize: CGFloat = 12

    /// Spacing between tempo text and metronome.
    public var tempoSpacing: CGFloat = 5

    /// Direction font name.
    public var directionFontName: String = "Times New Roman"

    /// Direction font size.
    public var directionFontSize: CGFloat = 10

    /// Rehearsal mark font name.
    public var rehearsalFontName: String = "Helvetica"

    /// Rehearsal mark font size.
    public var rehearsalFontSize: CGFloat = 14

    /// Rehearsal mark padding.
    public var rehearsalPadding: CGFloat = 3

    /// Rehearsal mark border thickness.
    public var rehearsalBorderThickness: CGFloat = 1

    /// Credit font name.
    public var creditFontName: String = "Times New Roman"

    public init() {}
}

// MARK: - Text Alignment

/// Text alignment options.
public enum TextAlignment: String, Sendable {
    case left
    case center
    case right
}

// MARK: - Render Info Types

/// Information for rendering a lyric.
public struct LyricRenderInfo: Sendable {
    /// Syllable text.
    public var text: String

    /// Position (centered on note).
    public var position: CGPoint

    /// Verse number.
    public var verse: Int

    /// Connector to next syllable.
    public var connector: LyricConnector?

    public init(text: String, position: CGPoint, verse: Int = 1, connector: LyricConnector? = nil) {
        self.text = text
        self.position = position
        self.verse = verse
        self.connector = connector
    }
}

/// Connector between lyric syllables.
public struct LyricConnector: Sendable {
    /// Connector type.
    public var type: LyricConnectorType

    /// Start X position.
    public var startX: CGFloat

    /// End X position.
    public var endX: CGFloat

    /// Y position.
    public var y: CGFloat

    public init(type: LyricConnectorType, startX: CGFloat, endX: CGFloat, y: CGFloat) {
        self.type = type
        self.startX = startX
        self.endX = endX
        self.y = y
    }
}

/// Type of lyric connector.
public enum LyricConnectorType: String, Sendable {
    case hyphen
    case extender
    case elision
}

/// Information for rendering a tempo marking.
public struct TempoRenderInfo: Sendable {
    /// Position.
    public var position: CGPoint

    /// Text (e.g., "Allegro").
    public var text: String?

    /// Metronome marking.
    public var metronome: MetronomeInfo?

    public init(position: CGPoint, text: String? = nil, metronome: MetronomeInfo? = nil) {
        self.position = position
        self.text = text
        self.metronome = metronome
    }
}

/// Metronome marking info.
public struct MetronomeInfo: Sendable {
    /// Beat unit glyph.
    public var beatUnitGlyph: SMuFLGlyphName

    /// Number of dots on beat unit.
    public var dots: Int

    /// Beats per minute.
    public var bpm: Int

    public init(beatUnitGlyph: SMuFLGlyphName, dots: Int = 0, bpm: Int) {
        self.beatUnitGlyph = beatUnitGlyph
        self.dots = dots
        self.bpm = bpm
    }
}

/// Information for rendering direction text.
public struct DirectionTextRenderInfo: Sendable {
    /// Text.
    public var text: String

    /// Position.
    public var position: CGPoint

    /// Alignment.
    public var alignment: TextAlignment

    /// Font name.
    public var fontName: String?

    /// Font size.
    public var fontSize: CGFloat?

    /// Whether to use italic.
    public var isItalic: Bool

    /// Whether to use bold.
    public var isBold: Bool

    public init(
        text: String,
        position: CGPoint,
        alignment: TextAlignment = .left,
        fontName: String? = nil,
        fontSize: CGFloat? = nil,
        isItalic: Bool = true,
        isBold: Bool = false
    ) {
        self.text = text
        self.position = position
        self.alignment = alignment
        self.fontName = fontName
        self.fontSize = fontSize
        self.isItalic = isItalic
        self.isBold = isBold
    }
}

/// Information for rendering a rehearsal mark.
public struct RehearsalMarkRenderInfo: Sendable {
    /// Mark text.
    public var text: String

    /// Position.
    public var position: CGPoint

    /// Enclosure type.
    public var enclosure: EnclosureType?

    public init(text: String, position: CGPoint, enclosure: EnclosureType? = .rectangle) {
        self.text = text
        self.position = position
        self.enclosure = enclosure
    }
}

/// Enclosure types for text.
public enum EnclosureType: String, Sendable {
    case rectangle
    case square
    case circle
    case oval
    case diamond
    case triangle
    case none
}

/// Information for rendering score credits.
public struct CreditRenderInfo: Sendable {
    /// Credit text.
    public var text: String

    /// Position.
    public var position: CGPoint

    /// Font size.
    public var fontSize: CGFloat

    /// Alignment.
    public var alignment: TextAlignment

    /// Font name.
    public var fontName: String?

    /// Whether to use italic.
    public var isItalic: Bool

    /// Whether to use bold.
    public var isBold: Bool

    public init(
        text: String,
        position: CGPoint,
        fontSize: CGFloat,
        alignment: TextAlignment = .center,
        fontName: String? = nil,
        isItalic: Bool = false,
        isBold: Bool = false
    ) {
        self.text = text
        self.position = position
        self.fontSize = fontSize
        self.alignment = alignment
        self.fontName = fontName
        self.isItalic = isItalic
        self.isBold = isBold
    }
}
