import Foundation

/// A tie connecting two notes of the same pitch.
/// Unlike slurs, ties indicate that the notes should be played as a single sustained note.
public struct TieConnection: Identifiable, Codable, Sendable {
    /// Unique identifier for this tie.
    public let id: UUID

    /// The starting note ID.
    public var startNoteId: UUID

    /// The ending note ID.
    public var endNoteId: UUID

    /// The pitch being tied.
    public var pitch: Pitch

    /// Placement above or below.
    public var placement: Placement?

    /// Orientation of the curve.
    public var orientation: CurveOrientation?

    /// Bezier control points for custom shaping.
    public var bezierPoints: BezierPoints?

    public init(
        id: UUID = UUID(),
        startNoteId: UUID,
        endNoteId: UUID,
        pitch: Pitch,
        placement: Placement? = nil,
        orientation: CurveOrientation? = nil,
        bezierPoints: BezierPoints? = nil
    ) {
        self.id = id
        self.startNoteId = startNoteId
        self.endNoteId = endNoteId
        self.pitch = pitch
        self.placement = placement
        self.orientation = orientation
        self.bezierPoints = bezierPoints
    }
}

// MARK: - Tie Chain

/// A chain of ties connecting multiple notes of the same pitch.
/// Used for notes tied across multiple measures.
public struct TieChain: Identifiable, Sendable {
    /// Unique identifier.
    public let id: UUID

    /// The pitch being tied throughout the chain.
    public var pitch: Pitch

    /// Note IDs in order from first to last.
    public var noteIds: [UUID]

    /// Individual tie connections.
    public var ties: [TieConnection]

    public init(
        id: UUID = UUID(),
        pitch: Pitch,
        noteIds: [UUID] = [],
        ties: [TieConnection] = []
    ) {
        self.id = id
        self.pitch = pitch
        self.noteIds = noteIds
        self.ties = ties
    }

    /// Total number of notes in the chain.
    public var noteCount: Int {
        noteIds.count
    }

    /// Number of tie connections.
    public var tieCount: Int {
        ties.count
    }

    /// The first note in the chain.
    public var firstNoteId: UUID? {
        noteIds.first
    }

    /// The last note in the chain.
    public var lastNoteId: UUID? {
        noteIds.last
    }

    /// Adds a note to the chain and creates the tie connection.
    public mutating func addNote(id: UUID) {
        if let lastId = noteIds.last {
            let tie = TieConnection(
                startNoteId: lastId,
                endNoteId: id,
                pitch: pitch
            )
            ties.append(tie)
        }
        noteIds.append(id)
    }
}

// MARK: - Tie Types (from Note.swift, re-exported here for convenience)

/// Re-export tie-related types for convenient access.
/// The actual Tie and TieType are defined in Note.swift.

// MARK: - Tie Tracking Utilities

/// Key for tracking ties by pitch, voice, and staff.
public struct TieTrackingKey: Hashable, Sendable {
    public var pitch: Pitch
    public var voice: Int
    public var staff: Int

    public init(pitch: Pitch, voice: Int, staff: Int) {
        self.pitch = pitch
        self.voice = voice
        self.staff = staff
    }
}

/// Information about a pending tie start.
public struct PendingTie: Sendable {
    public var noteId: UUID
    public var measureIndex: Int
    public var noteIndex: Int
    public var pitch: Pitch
    public var voice: Int
    public var staff: Int

    public init(
        noteId: UUID,
        measureIndex: Int,
        noteIndex: Int,
        pitch: Pitch,
        voice: Int,
        staff: Int
    ) {
        self.noteId = noteId
        self.measureIndex = measureIndex
        self.noteIndex = noteIndex
        self.pitch = pitch
        self.voice = voice
        self.staff = staff
    }

    /// Creates a tracking key from this pending tie.
    public var trackingKey: TieTrackingKey {
        TieTrackingKey(pitch: pitch, voice: voice, staff: staff)
    }
}

/// A completed tie from parsing.
public struct CompletedTie: Sendable {
    public var startNoteId: UUID
    public var endNoteId: UUID
    public var startMeasureIndex: Int
    public var startNoteIndex: Int
    public var endMeasureIndex: Int
    public var endNoteIndex: Int
    public var pitch: Pitch

    public init(
        startNoteId: UUID,
        endNoteId: UUID,
        startMeasureIndex: Int,
        startNoteIndex: Int,
        endMeasureIndex: Int,
        endNoteIndex: Int,
        pitch: Pitch
    ) {
        self.startNoteId = startNoteId
        self.endNoteId = endNoteId
        self.startMeasureIndex = startMeasureIndex
        self.startNoteIndex = startNoteIndex
        self.endMeasureIndex = endMeasureIndex
        self.endNoteIndex = endNoteIndex
        self.pitch = pitch
    }

    /// Creates a TieConnection from this completed tie.
    public func toTieConnection() -> TieConnection {
        TieConnection(
            startNoteId: startNoteId,
            endNoteId: endNoteId,
            pitch: pitch
        )
    }

    /// Whether this tie spans multiple measures.
    public var crossesMeasure: Bool {
        startMeasureIndex != endMeasureIndex
    }
}

// MARK: - Let Ring Tie

/// Represents a "let ring" indication where a note sustains indefinitely.
public struct LetRing: Codable, Sendable {
    /// The note that should ring.
    public var noteId: UUID

    /// The pitch ringing.
    public var pitch: Pitch

    public init(noteId: UUID, pitch: Pitch) {
        self.noteId = noteId
        self.pitch = pitch
    }
}
