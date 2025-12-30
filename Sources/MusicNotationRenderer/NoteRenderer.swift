import Foundation
import CoreGraphics
import MusicNotationCore
import SMuFLKit

// MARK: - Note Renderer

/// Renders noteheads, accidentals, stems, flags, and dots.
///
/// `NoteRenderer` is the central component for rendering individual notes and chords.
/// It coordinates the rendering of all note components: noteheads, accidentals, stems,
/// flags, and augmentation dots.
///
/// ## Component Rendering Order
///
/// Notes are rendered in a specific order to ensure proper layering:
/// 1. Accidentals (leftmost, drawn first)
/// 2. Noteheads
/// 3. Stems
/// 4. Flags (at stem end for unbeamed notes)
/// 5. Augmentation dots (rightmost)
///
/// ## Notehead Selection
///
/// The renderer maps note durations and notehead types to appropriate SMuFL glyphs:
/// - Whole/Breve: Hollow noteheads without stems
/// - Half notes: Hollow noteheads with stems
/// - Quarter notes and shorter: Filled noteheads with stems
///
/// Special notehead shapes (diamond, triangle, x, etc.) are supported via ``NoteheadType``.
///
/// ## Stem Direction and Length
///
/// Stems extend from the notehead based on direction:
/// - **Up stems**: Attach to right side of notehead, extend upward
/// - **Down stems**: Attach to left side of notehead, extend downward
///
/// Default stem length is 3.5 staff spaces, with a minimum of 2.5 spaces.
///
/// ## Usage
///
/// ```swift
/// let glyphRenderer = GlyphRenderer(fontManager: fontManager, scaling: scaling)
/// let noteRenderer = NoteRenderer(glyphRenderer: glyphRenderer)
///
/// // Render a single note
/// let noteInfo = NoteRenderInfo(
///     position: CGPoint(x: 100, y: 100),
///     staffPosition: 0,
///     noteheadGlyph: .noteheadBlack,
///     stem: stemInfo,
///     dots: [dotPosition]
/// )
/// noteRenderer.renderNote(noteInfo, color: CGColor.black, in: context)
/// ```
///
/// - SeeAlso: ``GlyphRenderer`` for SMuFL glyph rendering
/// - SeeAlso: ``BeamRenderer`` for beamed note groups
/// - SeeAlso: ``StaffRenderer`` for staff and ledger line rendering
public final class NoteRenderer {
    /// Glyph renderer for SMuFL glyphs.
    public var glyphRenderer: GlyphRenderer

    /// Configuration for note rendering.
    public var config: NoteRenderConfiguration

    public init(glyphRenderer: GlyphRenderer, config: NoteRenderConfiguration = NoteRenderConfiguration()) {
        self.glyphRenderer = glyphRenderer
        self.config = config
    }

    // MARK: - Complete Note Rendering

    /// Renders a complete note with all components.
    public func renderNote(
        _ note: NoteRenderInfo,
        color: CGColor,
        in context: CGContext
    ) {
        // 1. Render accidental
        if let accidental = note.accidental {
            renderAccidental(
                accidental.glyph,
                at: accidental.position,
                color: color,
                in: context
            )
        }

        // 2. Render notehead
        renderNotehead(
            note.noteheadGlyph,
            at: note.position,
            color: color,
            in: context
        )

        // 3. Render stem
        if let stem = note.stem {
            renderStem(stem, color: color, in: context)
        }

        // 4. Render flag
        if let flag = note.flag {
            renderFlag(flag.glyph, at: flag.position, color: color, in: context)
        }

        // 5. Render dots
        for dotPosition in note.dots {
            renderDot(at: dotPosition, color: color, in: context)
        }
    }

    /// Renders a chord (multiple notes sharing a stem).
    public func renderChord(
        _ chord: ChordRenderInfo,
        color: CGColor,
        in context: CGContext
    ) {
        // Render accidentals (already positioned to avoid collisions)
        for (glyph, position) in chord.accidentals {
            renderAccidental(glyph, at: position, color: color, in: context)
        }

        // Render noteheads
        for (glyph, position) in chord.noteheads {
            renderNotehead(glyph, at: position, color: color, in: context)
        }

        // Render stem
        if let stem = chord.stem {
            renderStem(stem, color: color, in: context)
        }

        // Render flag
        if let flag = chord.flag {
            renderFlag(flag.glyph, at: flag.position, color: color, in: context)
        }

        // Render dots
        for dotPosition in chord.dots {
            renderDot(at: dotPosition, color: color, in: context)
        }
    }

    // MARK: - Notehead Rendering

    /// Renders a notehead glyph.
    public func renderNotehead(
        _ glyph: SMuFLGlyphName,
        at position: CGPoint,
        color: CGColor,
        in context: CGContext
    ) {
        glyphRenderer.renderGlyph(glyph, at: position, color: color, in: context)
    }

    /// Renders a notehead with a specified type.
    public func renderNotehead(
        type: NoteheadType,
        at position: CGPoint,
        color: CGColor,
        in context: CGContext
    ) {
        let glyph = glyphForNotehead(type)
        renderNotehead(glyph, at: position, color: color, in: context)
    }

    /// Gets the SMuFL glyph for a notehead type.
    public func glyphForNotehead(_ type: NoteheadType) -> SMuFLGlyphName {
        switch type {
        case .normal:
            return .noteheadBlack
        case .diamond:
            return .noteheadDiamondBlack
        case .square:
            return .noteheadDoubleWholeSquare  // Use square breve glyph
        case .triangle:
            return .noteheadTriangleUpBlack
        case .slash:
            return .noteheadSlashDiamondWhite  // Use slash diamond glyph
        case .cross:
            return .noteheadXBlack
        case .x:
            return .noteheadXBlack  // Use standard X notehead
        case .circleX:
            return .noteheadCircleX
        case .none:
            return .noteheadNull
        }
    }

    /// Gets the glyph for a hollow (half/whole) notehead.
    public func glyphForHollowNotehead(_ type: NoteheadType, isWhole: Bool) -> SMuFLGlyphName {
        switch type {
        case .normal:
            return isWhole ? .noteheadWhole : .noteheadHalf
        case .diamond:
            return isWhole ? .noteheadDiamondWhole : .noteheadDiamondHalf
        case .square:
            return .noteheadDoubleWholeSquare  // Use square breve for hollow square
        case .triangle:
            return isWhole ? .noteheadTriangleUpWhole : .noteheadTriangleUpHalf
        default:
            return isWhole ? .noteheadWhole : .noteheadHalf
        }
    }

    // MARK: - Accidental Rendering

    /// Renders an accidental glyph.
    public func renderAccidental(
        _ glyph: SMuFLGlyphName,
        at position: CGPoint,
        color: CGColor,
        in context: CGContext
    ) {
        glyphRenderer.renderGlyph(glyph, at: position, color: color, in: context)
    }

    /// Renders an accidental by type.
    public func renderAccidental(
        type: Accidental,
        at position: CGPoint,
        color: CGColor,
        in context: CGContext
    ) {
        let glyph = glyphForAccidental(type)
        renderAccidental(glyph, at: position, color: color, in: context)
    }

    /// Gets the SMuFL glyph for an accidental type.
    public func glyphForAccidental(_ type: Accidental) -> SMuFLGlyphName {
        switch type {
        // Standard accidentals
        case .sharp:
            return .accidentalSharp
        case .flat:
            return .accidentalFlat
        case .natural:
            return .accidentalNatural
        case .doubleSharp:
            return .accidentalDoubleSharp
        case .doubleFlat:
            return .accidentalDoubleFlat
        case .tripleSharp:
            return .accidentalTripleSharp
        case .tripleFlat:
            return .accidentalTripleFlat

        // Combination accidentals
        case .naturalSharp:
            return .accidentalNaturalSharp
        case .naturalFlat:
            return .accidentalNaturalFlat

        // Microtonal - Stein-Zimmermann system
        case .quarterToneSharp:
            return .accidentalQuarterToneSharpStein
        case .quarterToneFlat:
            return .accidentalQuarterToneFlatStein
        case .threeQuarterToneSharp:
            return .accidentalThreeQuarterTonesSharpStein
        case .threeQuarterToneFlat:
            return .accidentalThreeQuarterTonesFlatZimmermann

        // Microtonal - Gould arrow system
        case .sharpArrowUp:
            return .accidentalSharpOneArrowUp
        case .sharpArrowDown:
            return .accidentalSharpOneArrowDown
        case .flatArrowUp:
            return .accidentalFlatOneArrowUp
        case .flatArrowDown:
            return .accidentalFlatOneArrowDown
        case .naturalArrowUp:
            return .accidentalNaturalOneArrowUp
        case .naturalArrowDown:
            return .accidentalNaturalOneArrowDown
        case .doubleSharpArrowUp:
            return .accidentalDoubleSharpOneArrowUp
        case .doubleSharpArrowDown:
            return .accidentalDoubleSharpOneArrowDown
        case .doubleFlatArrowUp:
            return .accidentalDoubleFlatOneArrowUp
        case .doubleFlatArrowDown:
            return .accidentalDoubleFlatOneArrowDown

        // Persian accidentals
        case .sori:
            return .accidentalSori
        case .koron:
            return .accidentalKoron
        }
    }

    /// Gets the width of an accidental glyph.
    public func accidentalWidth(for type: Accidental) -> CGFloat {
        glyphRenderer.getAdvance(for: glyphForAccidental(type))
    }

    // MARK: - Stem Rendering

    /// Renders a stem.
    public func renderStem(
        _ stem: StemRenderInfo,
        color: CGColor,
        in context: CGContext
    ) {
        context.saveGState()
        context.setStrokeColor(color)
        context.setLineWidth(stem.thickness)
        context.setLineCap(.butt)

        context.move(to: stem.start)
        context.addLine(to: stem.end)
        context.strokePath()

        context.restoreGState()
    }

    /// Renders a stem from a notehead position.
    public func renderStem(
        noteheadPosition: CGPoint,
        direction: StemDirection,
        length: CGFloat,
        thickness: CGFloat,
        noteheadWidth: CGFloat,
        color: CGColor,
        in context: CGContext
    ) {
        let stemX: CGFloat
        let stemStart: CGPoint
        let stemEnd: CGPoint

        if direction == .up {
            // Stem on right side of notehead, going up
            stemX = noteheadPosition.x + noteheadWidth - thickness / 2
            stemStart = CGPoint(x: stemX, y: noteheadPosition.y)
            stemEnd = CGPoint(x: stemX, y: noteheadPosition.y - length)
        } else {
            // Stem on left side of notehead, going down
            stemX = noteheadPosition.x + thickness / 2
            stemStart = CGPoint(x: stemX, y: noteheadPosition.y)
            stemEnd = CGPoint(x: stemX, y: noteheadPosition.y + length)
        }

        let stem = StemRenderInfo(
            start: stemStart,
            end: stemEnd,
            direction: direction,
            thickness: thickness
        )

        renderStem(stem, color: color, in: context)
    }

    // MARK: - Flag Rendering

    /// Renders a flag glyph.
    public func renderFlag(
        _ glyph: SMuFLGlyphName,
        at position: CGPoint,
        color: CGColor,
        in context: CGContext
    ) {
        glyphRenderer.renderGlyph(glyph, at: position, color: color, in: context)
    }

    /// Gets the flag glyph for a duration and stem direction.
    public func flagGlyph(for duration: DurationBase, direction: StemDirection) -> SMuFLGlyphName? {
        switch duration {
        case .eighth:
            return direction == .up ? .flag8thUp : .flag8thDown
        case .sixteenth:
            return direction == .up ? .flag16thUp : .flag16thDown
        case .thirtySecond:
            return direction == .up ? .flag32ndUp : .flag32ndDown
        case .sixtyFourth:
            return direction == .up ? .flag64thUp : .flag64thDown
        case .oneHundredTwentyEighth:
            return direction == .up ? .flag128thUp : .flag128thDown
        case .twoHundredFiftySixth:
            return direction == .up ? .flag256thUp : .flag256thDown
        default:
            return nil
        }
    }

    // MARK: - Dot Rendering

    /// Renders an augmentation dot.
    public func renderDot(
        at position: CGPoint,
        color: CGColor,
        in context: CGContext
    ) {
        glyphRenderer.renderGlyph(.augmentationDot, at: position, color: color, in: context)
    }

    /// Calculates dot positions for a note.
    public func dotPositions(
        notePosition: CGPoint,
        noteheadWidth: CGFloat,
        staffPosition: Int,
        dotCount: Int,
        staffSpacing: CGFloat
    ) -> [CGPoint] {
        guard dotCount > 0 else { return [] }

        var positions: [CGPoint] = []
        var x = notePosition.x + noteheadWidth + config.dotNoteheadGap

        // If note is on a line, move dot to adjacent space
        let isOnLine = staffPosition % 2 == 0
        let yOffset: CGFloat = isOnLine ? staffSpacing / 4 : 0

        for _ in 0..<dotCount {
            positions.append(CGPoint(x: x, y: notePosition.y - yOffset))
            x += config.dotDotGap
        }

        return positions
    }
}

// MARK: - Note Render Configuration

/// Configuration for note rendering.
public struct NoteRenderConfiguration: Sendable {
    /// Default stem thickness.
    public var stemThickness: CGFloat = 0.12

    /// Default stem length (in staff spaces).
    public var defaultStemLength: CGFloat = 3.5

    /// Minimum stem length.
    public var minimumStemLength: CGFloat = 2.5

    /// Gap between notehead and first dot.
    public var dotNoteheadGap: CGFloat = 0.5

    /// Gap between dots.
    public var dotDotGap: CGFloat = 0.5

    /// Gap between accidental and notehead.
    public var accidentalNoteheadGap: CGFloat = 0.12

    /// Gap between accidentals in a chord.
    public var accidentalAccidentalGap: CGFloat = 0.15

    public init() {}
}

// MARK: - Render Info Types

/// Information for rendering a single note.
public struct NoteRenderInfo: Sendable {
    /// Position of the notehead.
    public var position: CGPoint

    /// Staff position (for ledger lines, dot adjustment).
    public var staffPosition: Int

    /// Notehead glyph.
    public var noteheadGlyph: SMuFLGlyphName

    /// Accidental info (if any).
    public var accidental: AccidentalInfo?

    /// Stem info (if any).
    public var stem: StemRenderInfo?

    /// Flag info (if any).
    public var flag: FlagInfo?

    /// Dot positions.
    public var dots: [CGPoint]

    public init(
        position: CGPoint,
        staffPosition: Int,
        noteheadGlyph: SMuFLGlyphName,
        accidental: AccidentalInfo? = nil,
        stem: StemRenderInfo? = nil,
        flag: FlagInfo? = nil,
        dots: [CGPoint] = []
    ) {
        self.position = position
        self.staffPosition = staffPosition
        self.noteheadGlyph = noteheadGlyph
        self.accidental = accidental
        self.stem = stem
        self.flag = flag
        self.dots = dots
    }
}

/// Information for rendering a chord.
public struct ChordRenderInfo: Sendable {
    /// Noteheads (glyph and position).
    public var noteheads: [(glyph: SMuFLGlyphName, position: CGPoint)]

    /// Staff positions for all notes.
    public var staffPositions: [Int]

    /// Accidentals (glyph and position).
    public var accidentals: [(glyph: SMuFLGlyphName, position: CGPoint)]

    /// Stem info.
    public var stem: StemRenderInfo?

    /// Flag info.
    public var flag: FlagInfo?

    /// Dot positions.
    public var dots: [CGPoint]

    public init(
        noteheads: [(glyph: SMuFLGlyphName, position: CGPoint)],
        staffPositions: [Int],
        accidentals: [(glyph: SMuFLGlyphName, position: CGPoint)] = [],
        stem: StemRenderInfo? = nil,
        flag: FlagInfo? = nil,
        dots: [CGPoint] = []
    ) {
        self.noteheads = noteheads
        self.staffPositions = staffPositions
        self.accidentals = accidentals
        self.stem = stem
        self.flag = flag
        self.dots = dots
    }
}

/// Information for rendering a stem.
public struct StemRenderInfo: Sendable {
    /// Start point of stem (at notehead).
    public var start: CGPoint

    /// End point of stem.
    public var end: CGPoint

    /// Stem direction.
    public var direction: StemDirection

    /// Stem thickness.
    public var thickness: CGFloat

    public init(start: CGPoint, end: CGPoint, direction: StemDirection, thickness: CGFloat) {
        self.start = start
        self.end = end
        self.direction = direction
        self.thickness = thickness
    }

    /// Length of the stem.
    public var length: CGFloat {
        abs(end.y - start.y)
    }
}

/// Information for an accidental.
public struct AccidentalInfo: Sendable {
    /// Accidental glyph.
    public var glyph: SMuFLGlyphName

    /// Position.
    public var position: CGPoint

    public init(glyph: SMuFLGlyphName, position: CGPoint) {
        self.glyph = glyph
        self.position = position
    }
}

/// Information for a flag.
public struct FlagInfo: Sendable {
    /// Flag glyph.
    public var glyph: SMuFLGlyphName

    /// Position (at stem end).
    public var position: CGPoint

    public init(glyph: SMuFLGlyphName, position: CGPoint) {
        self.glyph = glyph
        self.position = position
    }
}
