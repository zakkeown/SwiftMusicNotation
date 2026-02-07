import Foundation
import CoreGraphics
import MusicNotationCore
import SMuFLKit

// MARK: - Engraved Score

/// The complete layout of a score ready for rendering.
///
/// An `EngravedScore` is the output of the layout engine, containing all musical
/// elements positioned in absolute coordinates ready for rendering. The structure
/// mirrors the visual hierarchy of the printed page.
///
/// ## Hierarchy
///
/// ```
/// EngravedScore
/// └── EngravedPage (multiple)
///     ├── EngravedCredit (titles, composer, etc.)
///     └── EngravedSystem (lines of music)
///         ├── EngravedStaff (individual staves)
///         ├── EngravedMeasure (positioned measures)
///         │   └── EngravedElement (notes, rests, clefs, etc.)
///         ├── EngravedSystemBarline (connecting barlines)
///         └── EngravedStaffGrouping (brackets, braces)
/// ```
///
/// ## Usage
///
/// Create an engraved score using ``LayoutEngine``:
///
/// ```swift
/// let layoutEngine = LayoutEngine()
/// let context = LayoutContext.letterSize(staffHeight: 40)
/// let engravedScore = layoutEngine.layout(score: score, context: context)
///
/// // Access pages
/// for page in engravedScore.pages {
///     print("Page \(page.pageNumber): \(page.systems.count) systems")
/// }
/// ```
///
/// ## Coordinate System
///
/// All positions use a top-left origin coordinate system where:
/// - X increases to the right
/// - Y increases downward
/// - Units are points (1/72 inch)
///
/// Element positions are relative to their parent container. Use ``ScalingContext``
/// for unit conversions between staff spaces and points.
public struct EngravedScore: Sendable {
    /// The source score.
    public let score: Score

    /// Pages of the engraved score.
    public var pages: [EngravedPage]

    /// Scaling context for unit conversions.
    public var scaling: ScalingContext

    public init(score: Score, pages: [EngravedPage] = [], scaling: ScalingContext) {
        self.score = score
        self.pages = pages
        self.scaling = scaling
    }

    /// Total number of pages.
    public var pageCount: Int { pages.count }
}

// MARK: - Engraved Page

/// A single page of engraved music.
public struct EngravedPage: Sendable {
    /// Page number (1-indexed).
    public var pageNumber: Int

    /// Page frame in points.
    public var frame: CGRect

    /// Systems on this page.
    public var systems: [EngravedSystem]

    /// Credits displayed on this page (titles, composer, etc.).
    public var credits: [EngravedCredit]

    public init(
        pageNumber: Int = 1,
        frame: CGRect = .zero,
        systems: [EngravedSystem] = [],
        credits: [EngravedCredit] = []
    ) {
        self.pageNumber = pageNumber
        self.frame = frame
        self.systems = systems
        self.credits = credits
    }

    /// Content area (excluding margins).
    public var contentArea: CGRect {
        frame
    }
}

// MARK: - Engraved System

/// A system (one line of music across the page).
public struct EngravedSystem: Sendable {
    /// System frame relative to page.
    public var frame: CGRect

    /// Staves in this system.
    public var staves: [EngravedStaff]

    /// Measures in this system (system-wide spanning).
    public var measures: [EngravedMeasure]

    /// System barlines (connecting multiple staves).
    public var systemBarlines: [EngravedSystemBarline]

    /// Staff groupings (brackets, braces).
    public var groupings: [EngravedStaffGrouping]

    /// Range of measure numbers in this system.
    public var measureRange: ClosedRange<Int>

    public init(
        frame: CGRect = .zero,
        staves: [EngravedStaff] = [],
        measures: [EngravedMeasure] = [],
        systemBarlines: [EngravedSystemBarline] = [],
        groupings: [EngravedStaffGrouping] = [],
        measureRange: ClosedRange<Int> = 1...1
    ) {
        self.frame = frame
        self.staves = staves
        self.measures = measures
        self.systemBarlines = systemBarlines
        self.groupings = groupings
        self.measureRange = measureRange
    }
}

// MARK: - Engraved Staff

/// A single staff within a system.
public struct EngravedStaff: Sendable {
    /// Part this staff belongs to.
    public var partIndex: Int

    /// Staff number within the part (for multi-staff instruments).
    public var staffNumber: Int

    /// Staff frame relative to system.
    public var frame: CGRect

    /// Y position of the center line (staff line 3) in points.
    public var centerLineY: CGFloat

    /// Number of staff lines (typically 5).
    public var lineCount: Int

    /// Staff height in points.
    public var staffHeight: CGFloat

    /// Clef at the start of the system.
    public var clef: Clef?

    /// Key signature at the start of the system.
    public var keySignature: KeySignature?

    /// Time signature at the start of the system (if first system or changed).
    public var timeSignature: TimeSignature?

    public init(
        partIndex: Int = 0,
        staffNumber: Int = 1,
        frame: CGRect = .zero,
        centerLineY: CGFloat = 0,
        lineCount: Int = 5,
        staffHeight: CGFloat = 40,
        clef: Clef? = nil,
        keySignature: KeySignature? = nil,
        timeSignature: TimeSignature? = nil
    ) {
        self.partIndex = partIndex
        self.staffNumber = staffNumber
        self.frame = frame
        self.centerLineY = centerLineY
        self.lineCount = lineCount
        self.staffHeight = staffHeight
        self.clef = clef
        self.keySignature = keySignature
        self.timeSignature = timeSignature
    }

    /// Y positions of staff lines in points (from bottom to top).
    public var staffLineYPositions: [CGFloat] {
        let spacing = staffHeight / 4.0
        return (0..<lineCount).map { CGFloat($0) * spacing }
    }
}

// MARK: - Engraved Measure

/// An engraved measure containing positioned elements.
public struct EngravedMeasure: Sendable {
    /// Measure number.
    public var measureNumber: Int

    /// Measure frame relative to system.
    public var frame: CGRect

    /// Left barline X position.
    public var leftBarlineX: CGFloat

    /// Right barline X position.
    public var rightBarlineX: CGFloat

    /// Engraved elements in this measure by staff.
    public var elementsByStaff: [Int: [EngravedElement]]

    /// Time slots (rhythmic columns) in this measure.
    public var timeSlots: [TimeSlot]

    /// Beam groups connecting notes in this measure.
    public var beamGroups: [EngravedBeamGroup]

    public init(
        measureNumber: Int = 1,
        frame: CGRect = .zero,
        leftBarlineX: CGFloat = 0,
        rightBarlineX: CGFloat = 0,
        elementsByStaff: [Int: [EngravedElement]] = [:],
        timeSlots: [TimeSlot] = [],
        beamGroups: [EngravedBeamGroup] = []
    ) {
        self.measureNumber = measureNumber
        self.frame = frame
        self.leftBarlineX = leftBarlineX
        self.rightBarlineX = rightBarlineX
        self.elementsByStaff = elementsByStaff
        self.timeSlots = timeSlots
        self.beamGroups = beamGroups
    }
}

// MARK: - Time Slot

/// A rhythmic position (column) in a measure.
public struct TimeSlot: Sendable {
    /// Position in divisions from measure start.
    public var position: Int

    /// X position in points relative to measure start.
    public var x: CGFloat

    /// Minimum width needed for elements at this position.
    public var minWidth: CGFloat

    /// Elements at this time position.
    public var elements: [EngravedElement]

    public init(position: Int = 0, x: CGFloat = 0, minWidth: CGFloat = 0, elements: [EngravedElement] = []) {
        self.position = position
        self.x = x
        self.minWidth = minWidth
        self.elements = elements
    }
}

// MARK: - Engraved Element

/// A positioned musical element ready for rendering.
public enum EngravedElement: Sendable {
    case note(EngravedNote)
    case rest(EngravedRest)
    case chord(EngravedChord)
    case clef(EngravedClef)
    case keySignature(EngravedKeySignature)
    case timeSignature(EngravedTimeSignature)
    case barline(EngravedBarline)
    case direction(EngravedDirection)

    /// The bounding box of this element.
    public var boundingBox: CGRect {
        switch self {
        case .note(let n): return n.boundingBox
        case .rest(let r): return r.boundingBox
        case .chord(let c): return c.boundingBox
        case .clef(let c): return c.boundingBox
        case .keySignature(let k): return k.boundingBox
        case .timeSignature(let t): return t.boundingBox
        case .barline(let b): return b.frame
        case .direction(let d): return d.boundingBox
        }
    }
}

// MARK: - Engraved Note

/// A positioned note glyph.
public struct EngravedNote: Sendable {
    /// Reference to source note.
    public var noteId: UUID

    /// Notehead position (center of notehead).
    public var position: CGPoint

    /// Staff line/space position (-2 = bottom line, 0 = middle line, etc.).
    public var staffPosition: Int

    /// Notehead glyph.
    public var noteheadGlyph: SMuFLGlyphName

    /// Accidental glyph, if shown.
    public var accidentalGlyph: SMuFLGlyphName?

    /// Accidental X offset from notehead.
    public var accidentalOffset: CGFloat

    /// Stem, if present.
    public var stem: EngravedStem?

    /// Flag glyph, if present (for unbeamed notes).
    public var flagGlyph: SMuFLGlyphName?

    /// Dot positions for augmentation dots.
    public var dots: [CGPoint]

    /// Bounding box.
    public var boundingBox: CGRect

    public init(
        noteId: UUID,
        position: CGPoint = .zero,
        staffPosition: Int = 0,
        noteheadGlyph: SMuFLGlyphName = .noteheadBlack,
        accidentalGlyph: SMuFLGlyphName? = nil,
        accidentalOffset: CGFloat = 0,
        stem: EngravedStem? = nil,
        flagGlyph: SMuFLGlyphName? = nil,
        dots: [CGPoint] = [],
        boundingBox: CGRect = .zero
    ) {
        self.noteId = noteId
        self.position = position
        self.staffPosition = staffPosition
        self.noteheadGlyph = noteheadGlyph
        self.accidentalGlyph = accidentalGlyph
        self.accidentalOffset = accidentalOffset
        self.stem = stem
        self.flagGlyph = flagGlyph
        self.dots = dots
        self.boundingBox = boundingBox
    }
}

// MARK: - Engraved Stem

/// A stem attached to a note or chord.
public struct EngravedStem: Sendable {
    /// Start point (at notehead).
    public var start: CGPoint

    /// End point (away from notehead).
    public var end: CGPoint

    /// Stem direction.
    public var direction: StemDirection

    /// Stem thickness in points.
    public var thickness: CGFloat

    public init(start: CGPoint = .zero, end: CGPoint = .zero, direction: StemDirection = .up, thickness: CGFloat = 1) {
        self.start = start
        self.end = end
        self.direction = direction
        self.thickness = thickness
    }

    /// Stem length.
    public var length: CGFloat {
        abs(end.y - start.y)
    }
}

// MARK: - Engraved Rest

/// A positioned rest glyph.
public struct EngravedRest: Sendable {
    /// Rest position (center).
    public var position: CGPoint

    /// Rest glyph.
    public var glyph: SMuFLGlyphName

    /// Bounding box.
    public var boundingBox: CGRect

    public init(position: CGPoint = .zero, glyph: SMuFLGlyphName = .restQuarter, boundingBox: CGRect = .zero) {
        self.position = position
        self.glyph = glyph
        self.boundingBox = boundingBox
    }
}

// MARK: - Engraved Chord

/// A chord (multiple noteheads sharing a stem).
public struct EngravedChord: Sendable {
    /// Notes in the chord.
    public var notes: [EngravedNote]

    /// Shared stem.
    public var stem: EngravedStem?

    /// Flag glyph, if present.
    public var flagGlyph: SMuFLGlyphName?

    /// Bounding box.
    public var boundingBox: CGRect

    public init(notes: [EngravedNote] = [], stem: EngravedStem? = nil, flagGlyph: SMuFLGlyphName? = nil, boundingBox: CGRect = .zero) {
        self.notes = notes
        self.stem = stem
        self.flagGlyph = flagGlyph
        self.boundingBox = boundingBox
    }
}

// MARK: - Engraved Beam Group

/// A beam connecting a group of notes.
///
/// Layout-level geometry for a primary beam line. This is computed by the layout
/// engine and consumed by the renderer to draw beam lines connecting note stems.
public struct EngravedBeamGroup: Sendable {
    /// Left end of the primary beam.
    public var startPoint: CGPoint

    /// Right end of the primary beam.
    public var endPoint: CGPoint

    /// Beam thickness in points.
    public var thickness: CGFloat

    /// Beam slope (dy/dx).
    public var slope: CGFloat

    /// Direction of stems in this beam group.
    public var stemDirection: StemDirection

    /// Staff number this beam group belongs to.
    public var staffNumber: Int

    public init(
        startPoint: CGPoint,
        endPoint: CGPoint,
        thickness: CGFloat,
        slope: CGFloat,
        stemDirection: StemDirection,
        staffNumber: Int = 1
    ) {
        self.startPoint = startPoint
        self.endPoint = endPoint
        self.thickness = thickness
        self.slope = slope
        self.stemDirection = stemDirection
        self.staffNumber = staffNumber
    }
}

// MARK: - Engraved Clef

/// A positioned clef glyph.
public struct EngravedClef: Sendable {
    /// Clef data.
    public var clef: Clef

    /// Position.
    public var position: CGPoint

    /// Glyph.
    public var glyph: SMuFLGlyphName

    /// Bounding box.
    public var boundingBox: CGRect

    public init(clef: Clef, position: CGPoint = .zero, glyph: SMuFLGlyphName = .gClef, boundingBox: CGRect = .zero) {
        self.clef = clef
        self.position = position
        self.glyph = glyph
        self.boundingBox = boundingBox
    }
}

// MARK: - Engraved Key Signature

/// A positioned key signature.
public struct EngravedKeySignature: Sendable {
    /// Key signature data.
    public var keySignature: KeySignature

    /// Position of first accidental.
    public var position: CGPoint

    /// Accidental glyphs with their positions.
    public var accidentals: [(glyph: SMuFLGlyphName, position: CGPoint)]

    /// Bounding box.
    public var boundingBox: CGRect

    public init(
        keySignature: KeySignature,
        position: CGPoint = .zero,
        accidentals: [(glyph: SMuFLGlyphName, position: CGPoint)] = [],
        boundingBox: CGRect = .zero
    ) {
        self.keySignature = keySignature
        self.position = position
        self.accidentals = accidentals
        self.boundingBox = boundingBox
    }
}

// MARK: - Engraved Time Signature

/// A positioned time signature.
public struct EngravedTimeSignature: Sendable {
    /// Time signature data.
    public var timeSignature: TimeSignature

    /// Position.
    public var position: CGPoint

    /// Top number glyphs (for compound meters).
    public var topGlyphs: [(glyph: SMuFLGlyphName, position: CGPoint)]

    /// Bottom number glyphs.
    public var bottomGlyphs: [(glyph: SMuFLGlyphName, position: CGPoint)]

    /// Symbol glyph (for common/cut time).
    public var symbolGlyph: SMuFLGlyphName?

    /// Bounding box.
    public var boundingBox: CGRect

    public init(
        timeSignature: TimeSignature,
        position: CGPoint = .zero,
        topGlyphs: [(glyph: SMuFLGlyphName, position: CGPoint)] = [],
        bottomGlyphs: [(glyph: SMuFLGlyphName, position: CGPoint)] = [],
        symbolGlyph: SMuFLGlyphName? = nil,
        boundingBox: CGRect = .zero
    ) {
        self.timeSignature = timeSignature
        self.position = position
        self.topGlyphs = topGlyphs
        self.bottomGlyphs = bottomGlyphs
        self.symbolGlyph = symbolGlyph
        self.boundingBox = boundingBox
    }
}

// MARK: - Engraved Barline

/// A positioned barline.
public struct EngravedBarline: Sendable {
    /// Barline style.
    public var style: BarStyle

    /// Frame (x is position, height spans staff).
    public var frame: CGRect

    /// Whether this is a system barline (spans all staves).
    public var isSystemBarline: Bool

    public init(style: BarStyle = .regular, frame: CGRect = .zero, isSystemBarline: Bool = false) {
        self.style = style
        self.frame = frame
        self.isSystemBarline = isSystemBarline
    }
}

// MARK: - Engraved System Barline

/// A barline spanning multiple staves in a system.
public struct EngravedSystemBarline: Sendable {
    /// X position.
    public var x: CGFloat

    /// Top Y (highest staff).
    public var topY: CGFloat

    /// Bottom Y (lowest staff).
    public var bottomY: CGFloat

    /// Barline style.
    public var style: BarStyle

    public init(x: CGFloat = 0, topY: CGFloat = 0, bottomY: CGFloat = 0, style: BarStyle = .regular) {
        self.x = x
        self.topY = topY
        self.bottomY = bottomY
        self.style = style
    }
}

// MARK: - Engraved Staff Grouping

/// A bracket or brace grouping staves.
public struct EngravedStaffGrouping: Sendable {
    /// Grouping type.
    public var symbol: GroupSymbol

    /// X position.
    public var x: CGFloat

    /// Top staff index.
    public var topStaffIndex: Int

    /// Bottom staff index.
    public var bottomStaffIndex: Int

    /// Glyph for brace.
    public var braceGlyph: SMuFLGlyphName?

    public init(
        symbol: GroupSymbol = .bracket,
        x: CGFloat = 0,
        topStaffIndex: Int = 0,
        bottomStaffIndex: Int = 0,
        braceGlyph: SMuFLGlyphName? = nil
    ) {
        self.symbol = symbol
        self.x = x
        self.topStaffIndex = topStaffIndex
        self.bottomStaffIndex = bottomStaffIndex
        self.braceGlyph = braceGlyph
    }
}

/// Group symbol type.
public enum GroupSymbol: String, Codable, Sendable {
    case bracket
    case brace
    case line
    case square
    case none
}

// MARK: - Engraved Direction

/// A positioned direction (dynamics, text, etc.).
public struct EngravedDirection: Sendable {
    /// Position.
    public var position: CGPoint

    /// Content type.
    public var content: DirectionContent

    /// Bounding box.
    public var boundingBox: CGRect

    public init(position: CGPoint = .zero, content: DirectionContent = .text(""), boundingBox: CGRect = .zero) {
        self.position = position
        self.content = content
        self.boundingBox = boundingBox
    }
}

/// Direction content types.
public enum DirectionContent: Sendable {
    case text(String)
    case dynamic(SMuFLGlyphName)
    case wedge(WedgeContent)
    case metronome(MetronomeContent)
}

/// Wedge (crescendo/diminuendo) content.
public struct WedgeContent: Sendable {
    public var isCresc: Bool
    public var startX: CGFloat
    public var endX: CGFloat
    public var spreadStart: CGFloat
    public var spreadEnd: CGFloat

    public init(isCresc: Bool = true, startX: CGFloat = 0, endX: CGFloat = 0, spreadStart: CGFloat = 0, spreadEnd: CGFloat = 0) {
        self.isCresc = isCresc
        self.startX = startX
        self.endX = endX
        self.spreadStart = spreadStart
        self.spreadEnd = spreadEnd
    }
}

/// Metronome marking content.
public struct MetronomeContent: Sendable {
    public var beatUnitGlyph: SMuFLGlyphName
    public var bpm: Int
    public var beatUnitDots: Int

    public init(beatUnitGlyph: SMuFLGlyphName = .noteheadBlack, bpm: Int = 120, beatUnitDots: Int = 0) {
        self.beatUnitGlyph = beatUnitGlyph
        self.bpm = bpm
        self.beatUnitDots = beatUnitDots
    }
}

// MARK: - Engraved Credit

/// A positioned credit text.
public struct EngravedCredit: Sendable {
    /// Text content.
    public var text: String

    /// Position.
    public var position: CGPoint

    /// Font size in points.
    public var fontSize: CGFloat

    /// Justification.
    public var justification: Justification?

    /// Bounding box.
    public var boundingBox: CGRect

    public init(
        text: String = "",
        position: CGPoint = .zero,
        fontSize: CGFloat = 12,
        justification: Justification? = nil,
        boundingBox: CGRect = .zero
    ) {
        self.text = text
        self.position = position
        self.fontSize = fontSize
        self.justification = justification
        self.boundingBox = boundingBox
    }
}
