import Foundation
import SMuFLKit

/// A tuplet grouping notes with a modified rhythm.
/// For example, a triplet plays 3 notes in the time of 2.
public struct Tuplet: Identifiable, Codable, Sendable {
    /// Unique identifier.
    public let id: UUID

    /// Tuplet number for nested tuplets (1-6 in MusicXML).
    public var number: Int

    /// The actual number of notes played.
    public var actualNotes: Int

    /// The normal number of notes in that time span.
    public var normalNotes: Int

    /// The note type for actual notes (e.g., eighth).
    public var actualType: DurationBase?

    /// The note type for normal notes.
    public var normalType: DurationBase?

    /// Note IDs in this tuplet.
    public var noteIds: [UUID]

    /// Whether to show the tuplet bracket.
    public var showBracket: Bool?

    /// Whether to show the tuplet number.
    public var showNumber: TupletDisplay

    /// Whether to show the tuplet type (note value).
    public var showType: TupletDisplay

    /// Placement above or below.
    public var placement: Placement?

    public init(
        id: UUID = UUID(),
        number: Int = 1,
        actualNotes: Int = 3,
        normalNotes: Int = 2,
        actualType: DurationBase? = nil,
        normalType: DurationBase? = nil,
        noteIds: [UUID] = [],
        showBracket: Bool? = nil,
        showNumber: TupletDisplay = .actual,
        showType: TupletDisplay = .none,
        placement: Placement? = nil
    ) {
        self.id = id
        self.number = number
        self.actualNotes = actualNotes
        self.normalNotes = normalNotes
        self.actualType = actualType
        self.normalType = normalType
        self.noteIds = noteIds
        self.showBracket = showBracket
        self.showNumber = showNumber
        self.showType = showType
        self.placement = placement
    }

    /// The tuplet ratio as a string (e.g., "3:2").
    public var ratioString: String {
        "\(actualNotes):\(normalNotes)"
    }

    /// The multiplier for duration calculation.
    /// For triplets (3:2), this is 2/3.
    public var durationMultiplier: Double {
        Double(normalNotes) / Double(actualNotes)
    }

    /// Whether this is a standard triplet (3:2).
    public var isTriplet: Bool {
        actualNotes == 3 && normalNotes == 2
    }

    /// Whether this is a duplet (2:3).
    public var isDuplet: Bool {
        actualNotes == 2 && normalNotes == 3
    }

    /// Number of notes in this tuplet.
    public var noteCount: Int {
        noteIds.count
    }
}

/// Display options for tuplet numbers and types.
public enum TupletDisplay: String, Codable, Sendable {
    /// Show the actual number (e.g., "3" for triplet).
    case actual

    /// Show both actual and normal (e.g., "3:2").
    case both

    /// Don't show.
    case none
}

// MARK: - Common Tuplet Ratios

extension Tuplet {
    /// Creates a triplet (3 in the time of 2).
    public static func triplet(noteIds: [UUID] = [], type: DurationBase? = nil) -> Tuplet {
        Tuplet(
            actualNotes: 3,
            normalNotes: 2,
            actualType: type,
            normalType: type,
            noteIds: noteIds
        )
    }

    /// Creates a duplet (2 in the time of 3, common in compound meter).
    public static func duplet(noteIds: [UUID] = [], type: DurationBase? = nil) -> Tuplet {
        Tuplet(
            actualNotes: 2,
            normalNotes: 3,
            actualType: type,
            normalType: type,
            noteIds: noteIds
        )
    }

    /// Creates a quintuplet (5 in the time of 4).
    public static func quintuplet(noteIds: [UUID] = [], type: DurationBase? = nil) -> Tuplet {
        Tuplet(
            actualNotes: 5,
            normalNotes: 4,
            actualType: type,
            normalType: type,
            noteIds: noteIds
        )
    }

    /// Creates a sextuplet (6 in the time of 4).
    public static func sextuplet(noteIds: [UUID] = [], type: DurationBase? = nil) -> Tuplet {
        Tuplet(
            actualNotes: 6,
            normalNotes: 4,
            actualType: type,
            normalType: type,
            noteIds: noteIds
        )
    }

    /// Creates a septuplet (7 in the time of 4).
    public static func septuplet(noteIds: [UUID] = [], type: DurationBase? = nil) -> Tuplet {
        Tuplet(
            actualNotes: 7,
            normalNotes: 4,
            actualType: type,
            normalType: type,
            noteIds: noteIds
        )
    }
}

// MARK: - SMuFL Tuplet Glyphs

extension Tuplet {
    /// SMuFL glyph for the tuplet number.
    public var numberGlyph: SMuFLGlyphName? {
        switch actualNotes {
        case 2: return .tuplet2
        case 3: return .tuplet3
        case 4: return .tuplet4
        case 5: return .tuplet5
        case 6: return .tuplet6
        case 7: return .tuplet7
        case 8: return .tuplet8
        case 9: return .tuplet9
        default: return nil
        }
    }

    /// SMuFL glyph for the colon in ratio display.
    public var colonGlyph: SMuFLGlyphName {
        .tupletColon
    }
}

// MARK: - Tuplet Tracking

/// Tracks tuplet start/stop during parsing.
public struct TupletStart: Sendable {
    public var number: Int
    public var actualNotes: Int
    public var normalNotes: Int
    public var actualType: DurationBase?
    public var normalType: DurationBase?
    public var showBracket: Bool?
    public var showNumber: TupletDisplay
    public var showType: TupletDisplay
    public var placement: Placement?
    public var noteIds: [UUID]
    public var startMeasureIndex: Int

    public init(
        number: Int,
        actualNotes: Int,
        normalNotes: Int,
        actualType: DurationBase? = nil,
        normalType: DurationBase? = nil,
        showBracket: Bool? = nil,
        showNumber: TupletDisplay = .actual,
        showType: TupletDisplay = .none,
        placement: Placement? = nil,
        startMeasureIndex: Int = 0
    ) {
        self.number = number
        self.actualNotes = actualNotes
        self.normalNotes = normalNotes
        self.actualType = actualType
        self.normalType = normalType
        self.showBracket = showBracket
        self.showNumber = showNumber
        self.showType = showType
        self.placement = placement
        self.noteIds = []
        self.startMeasureIndex = startMeasureIndex
    }

    /// Adds a note to this tuplet.
    public mutating func addNote(id: UUID) {
        noteIds.append(id)
    }

    /// Creates a Tuplet from this tracking info.
    public func toTuplet() -> Tuplet {
        Tuplet(
            number: number,
            actualNotes: actualNotes,
            normalNotes: normalNotes,
            actualType: actualType,
            normalType: normalType,
            noteIds: noteIds,
            showBracket: showBracket,
            showNumber: showNumber,
            showType: showType,
            placement: placement
        )
    }
}

// MARK: - Nested Tuplets

/// Represents a nested tuplet structure.
public struct NestedTuplet: Sendable {
    /// The outer tuplet.
    public var outer: Tuplet

    /// Inner tuplets.
    public var inner: [Tuplet]

    public init(outer: Tuplet, inner: [Tuplet] = []) {
        self.outer = outer
        self.inner = inner
    }

    /// Total duration multiplier accounting for nesting.
    public var totalMultiplier: Double {
        inner.reduce(outer.durationMultiplier) { result, tuplet in
            result * tuplet.durationMultiplier
        }
    }
}
