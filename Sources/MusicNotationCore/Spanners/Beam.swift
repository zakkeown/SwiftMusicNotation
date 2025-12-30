import Foundation
import SMuFLKit

/// A beam connecting multiple notes.
/// Beams can have multiple levels (primary beam, secondary beams, etc.).
public struct Beam: Identifiable, Codable, Sendable {
    /// Unique identifier for this beam.
    public let id: UUID

    /// Beam level (1 = primary/eighth note beam, 2 = sixteenth, etc.).
    public var level: Int

    /// Notes in this beam group.
    public var noteIds: [UUID]

    /// Whether to show a partial beam (hook) at the start.
    public var hasForwardHook: Bool

    /// Whether to show a partial beam (hook) at the end.
    public var hasBackwardHook: Bool

    /// Fan beam type for accelerando/ritardando effects.
    public var fan: BeamFan?

    public init(
        id: UUID = UUID(),
        level: Int = 1,
        noteIds: [UUID] = [],
        hasForwardHook: Bool = false,
        hasBackwardHook: Bool = false,
        fan: BeamFan? = nil
    ) {
        self.id = id
        self.level = level
        self.noteIds = noteIds
        self.hasForwardHook = hasForwardHook
        self.hasBackwardHook = hasBackwardHook
        self.fan = fan
    }

    /// Number of notes in this beam.
    public var noteCount: Int {
        noteIds.count
    }

    /// Whether this beam has at least two notes.
    public var isValid: Bool {
        noteIds.count >= 2
    }
}

/// Fan beam types for feathered beaming.
public enum BeamFan: String, Codable, Sendable {
    /// Beam spreads out (accelerando).
    case accelerando = "accel"

    /// Beam converges (ritardando).
    case ritardando = "rit"

    /// No fan.
    case none
}

// MARK: - Beam Group

/// A complete beam group containing all beam levels for a set of notes.
public struct BeamGroup: Identifiable, Sendable {
    /// Unique identifier.
    public let id: UUID

    /// Notes in this beam group.
    public var noteIds: [UUID]

    /// Voice this beam belongs to.
    public var voice: Int

    /// Staff this beam belongs to.
    public var staff: Int

    /// Beams by level (1 = primary, 2 = secondary, etc.).
    public var beamsByLevel: [Int: Beam]

    /// Maximum beam level (determines fastest note value).
    public var maxLevel: Int {
        beamsByLevel.keys.max() ?? 1
    }

    public init(
        id: UUID = UUID(),
        noteIds: [UUID] = [],
        voice: Int = 1,
        staff: Int = 1,
        beamsByLevel: [Int: Beam] = [:]
    ) {
        self.id = id
        self.noteIds = noteIds
        self.voice = voice
        self.staff = staff
        self.beamsByLevel = beamsByLevel
    }

    /// The primary (level 1) beam.
    public var primaryBeam: Beam? {
        beamsByLevel[1]
    }

    /// All beam levels present.
    public var levels: [Int] {
        beamsByLevel.keys.sorted()
    }
}

// MARK: - Beam Calculations

extension BeamGroup {
    /// Returns the note duration base that corresponds to the max beam level.
    public var fastestNoteValue: DurationBase {
        switch maxLevel {
        case 1: return .eighth
        case 2: return .sixteenth
        case 3: return .thirtySecond
        case 4: return .sixtyFourth
        case 5: return .oneHundredTwentyEighth
        case 6: return .twoHundredFiftySixth
        default: return .eighth
        }
    }

    /// Returns the number of beams required for a given duration base.
    public static func beamCount(for duration: DurationBase) -> Int {
        switch duration {
        case .eighth: return 1
        case .sixteenth: return 2
        case .thirtySecond: return 3
        case .sixtyFourth: return 4
        case .oneHundredTwentyEighth: return 5
        case .twoHundredFiftySixth: return 6
        default: return 0
        }
    }
}

// MARK: - SMuFL Beam Glyphs

extension Beam {
    /// SMuFL glyph for the beam (used for tremolo beams).
    public var tremoloGlyph: SMuFLGlyphName? {
        switch level {
        case 1: return .tremolo1
        case 2: return .tremolo2
        case 3: return .tremolo3
        case 4: return .tremolo4
        case 5: return .tremolo5
        default: return nil
        }
    }
}

// MARK: - Beam Builder

/// Helper for building beam groups during parsing.
public class BeamGroupBuilder {
    private var noteIds: [UUID] = []
    private var beamValues: [[BeamType]] = []  // Per-note beam values
    private let voice: Int
    private let staff: Int

    public init(voice: Int, staff: Int) {
        self.voice = voice
        self.staff = staff
    }

    /// Adds a note with its beam values.
    public func addNote(id: UUID, beams: [BeamValue]) {
        noteIds.append(id)
        beamValues.append(beams.map { $0.value })
    }

    /// Builds the complete beam group.
    public func build() -> BeamGroup {
        var beamsByLevel: [Int: Beam] = [:]

        // Find all unique beam levels
        let allLevels = Set(beamValues.flatMap { values in
            values.enumerated().map { $0.offset + 1 }
        })

        for level in allLevels {
            var beam = Beam(level: level)
            beam.noteIds = noteIds
            beamsByLevel[level] = beam
        }

        return BeamGroup(
            noteIds: noteIds,
            voice: voice,
            staff: staff,
            beamsByLevel: beamsByLevel
        )
    }
}
