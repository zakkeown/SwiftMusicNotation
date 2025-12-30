import Foundation

/// A slur connecting two or more notes.
/// Slurs indicate legato playing and can nest using the number attribute.
public struct Slur: Identifiable, Codable, Sendable {
    /// Unique identifier for this slur.
    public let id: UUID

    /// Slur number for distinguishing nested slurs (1-6 in MusicXML).
    public var number: Int

    /// Start note reference.
    public var startNoteId: UUID?

    /// End note reference.
    public var endNoteId: UUID?

    /// Placement above or below the staff.
    public var placement: Placement?

    /// Bezier curve control points for custom shaping.
    public var bezierPoints: BezierPoints?

    /// Line type (solid, dashed, dotted).
    public var lineType: LineType

    /// Orientation (over or under).
    public var orientation: CurveOrientation?

    public init(
        id: UUID = UUID(),
        number: Int = 1,
        startNoteId: UUID? = nil,
        endNoteId: UUID? = nil,
        placement: Placement? = nil,
        bezierPoints: BezierPoints? = nil,
        lineType: LineType = .solid,
        orientation: CurveOrientation? = nil
    ) {
        self.id = id
        self.number = number
        self.startNoteId = startNoteId
        self.endNoteId = endNoteId
        self.placement = placement
        self.bezierPoints = bezierPoints
        self.lineType = lineType
        self.orientation = orientation
    }

    /// Whether this slur has both start and end defined.
    public var isComplete: Bool {
        startNoteId != nil && endNoteId != nil
    }
}

/// Bezier control points for curve shaping.
public struct BezierPoints: Codable, Sendable {
    /// X offset for the curve start.
    public var bezierX: Double?

    /// Y offset for the curve start.
    public var bezierY: Double?

    /// X offset for the second control point.
    public var bezierX2: Double?

    /// Y offset for the second control point.
    public var bezierY2: Double?

    /// X offset for the curve start point.
    public var bezierOffset: Double?

    /// Y offset for the curve start point.
    public var bezierOffset2: Double?

    public init(
        bezierX: Double? = nil,
        bezierY: Double? = nil,
        bezierX2: Double? = nil,
        bezierY2: Double? = nil,
        bezierOffset: Double? = nil,
        bezierOffset2: Double? = nil
    ) {
        self.bezierX = bezierX
        self.bezierY = bezierY
        self.bezierX2 = bezierX2
        self.bezierY2 = bezierY2
        self.bezierOffset = bezierOffset
        self.bezierOffset2 = bezierOffset2
    }
}

/// Line type for slurs and other curved lines.
public enum LineType: String, Codable, Sendable {
    case solid
    case dashed
    case dotted
    case wavy
}

/// Curve orientation (over or under).
public enum CurveOrientation: String, Codable, Sendable {
    case over
    case under
}

// MARK: - Slur Tracking

/// Tracks slur start/stop pairs during parsing.
public struct SlurStart: Sendable {
    public var noteId: UUID
    public var measureIndex: Int
    public var noteIndex: Int
    public var placement: Placement?

    public init(noteId: UUID, measureIndex: Int, noteIndex: Int, placement: Placement? = nil) {
        self.noteId = noteId
        self.measureIndex = measureIndex
        self.noteIndex = noteIndex
        self.placement = placement
    }
}

/// A completed slur pair.
public struct SlurPair: Sendable {
    public var slurNumber: Int
    public var startNoteId: UUID
    public var endNoteId: UUID
    public var startMeasureIndex: Int
    public var startNoteIndex: Int
    public var endMeasureIndex: Int
    public var endNoteIndex: Int
    public var placement: Placement?

    public init(
        slurNumber: Int,
        startNoteId: UUID,
        endNoteId: UUID,
        startMeasureIndex: Int,
        startNoteIndex: Int,
        endMeasureIndex: Int,
        endNoteIndex: Int,
        placement: Placement? = nil
    ) {
        self.slurNumber = slurNumber
        self.startNoteId = startNoteId
        self.endNoteId = endNoteId
        self.startMeasureIndex = startMeasureIndex
        self.startNoteIndex = startNoteIndex
        self.endMeasureIndex = endMeasureIndex
        self.endNoteIndex = endNoteIndex
        self.placement = placement
    }

    /// Creates a Slur from this pair.
    public func toSlur() -> Slur {
        Slur(
            number: slurNumber,
            startNoteId: startNoteId,
            endNoteId: endNoteId,
            placement: placement
        )
    }
}
