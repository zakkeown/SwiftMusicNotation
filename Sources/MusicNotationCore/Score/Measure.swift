import Foundation

/// A measure (bar) in a musical score.
///
/// A `Measure` represents a single bar of music, containing notes, rests, directions,
/// and other musical elements. Measures are the primary containers for musical content
/// and define rhythmic boundaries.
///
/// ## Contents
///
/// Measures contain various element types through the ``MeasureElement`` enum:
///
/// ```swift
/// for element in measure.elements {
///     switch element {
///     case .note(let note):
///         print("Note: \(note.pitch?.description ?? "rest")")
///     case .direction(let direction):
///         print("Direction: \(direction.type)")
///     case .attributes(let attrs):
///         print("Clef change: \(attrs.clefs.first?.sign)")
///     default:
///         break
///     }
/// }
/// ```
///
/// ## Voices and Staves
///
/// Elements can be filtered by voice (for polyphonic music) or staff (for multi-staff parts):
///
/// ```swift
/// // Get soprano line (voice 1)
/// let soprano = measure.elements(forVoice: 1)
///
/// // Get bass staff content (staff 2)
/// let bassStaff = measure.elements(forStaff: 2)
///
/// // Get just the notes
/// let allNotes = measure.notes
/// ```
///
/// ## Measure Numbers
///
/// Measure numbers are strings to support:
/// - Pickup measures: "0"
/// - Standard numbering: "1", "2", "3"
/// - Split measures: "23a", "23b"
/// - Special numbering: "X" (for excluded measures)
///
/// ```swift
/// if measure.implicit {
///     print("Pickup measure (anacrusis)")
/// }
/// ```
///
/// ## Barlines
///
/// Measures can have left and right barlines with different styles:
///
/// ```swift
/// if let rightBar = measure.rightBarline,
///    rightBar.style == .lightHeavy {
///     print("End of piece")
/// }
/// ```
///
/// - SeeAlso: ``MeasureElement`` for the types of content
/// - SeeAlso: ``Note`` for note elements
/// - SeeAlso: ``MeasureAttributes`` for clef/key/time changes
public final class Measure: Identifiable, Sendable {
    /// Unique identifier for this measure.
    public let id: UUID

    /// The measure number (can be non-numeric, e.g., "1a", "X").
    public var number: String

    /// Whether this is an implicit measure (pickup/anacrusis).
    public var implicit: Bool

    /// Explicit width in tenths (optional).
    public var width: Double?

    /// The elements in this measure (notes, rests, directions, etc.).
    public var elements: [MeasureElement]

    /// Attributes at the start of this measure (clef, key, time changes).
    public var attributes: MeasureAttributes?

    /// Left barline.
    public var leftBarline: Barline?

    /// Right barline.
    public var rightBarline: Barline?

    /// Print/layout hints.
    public var printAttributes: PrintAttributes?

    /// Creates a new measure.
    public init(
        id: UUID = UUID(),
        number: String,
        implicit: Bool = false,
        width: Double? = nil,
        elements: [MeasureElement] = [],
        attributes: MeasureAttributes? = nil,
        leftBarline: Barline? = nil,
        rightBarline: Barline? = nil,
        printAttributes: PrintAttributes? = nil
    ) {
        self.id = id
        self.number = number
        self.implicit = implicit
        self.width = width
        self.elements = elements
        self.attributes = attributes
        self.leftBarline = leftBarline
        self.rightBarline = rightBarline
        self.printAttributes = printAttributes
    }

    /// Returns all notes in this measure.
    public var notes: [Note] {
        elements.compactMap { element in
            if case .note(let note) = element { return note }
            return nil
        }
    }

    /// Returns all elements for a specific voice.
    public func elements(forVoice voice: Int) -> [MeasureElement] {
        elements.filter { element in
            switch element {
            case .note(let note):
                return note.voice == voice
            case .forward(let forward):
                return forward.voice == voice
            default:
                return true  // Include non-voice-specific elements
            }
        }
    }

    /// Returns all elements for a specific staff.
    public func elements(forStaff staff: Int) -> [MeasureElement] {
        elements.filter { element in
            switch element {
            case .note(let note):
                return note.staff == staff
            case .forward(let forward):
                return forward.staff == staff
            case .direction(let direction):
                return direction.staff == staff
            default:
                return true  // Include non-staff-specific elements
            }
        }
    }
}

// MARK: - Measure Element

/// An element that can appear within a measure.
///
/// `MeasureElement` is an enum covering all types of content that can appear in a bar.
/// Use pattern matching to access the underlying values:
///
/// ```swift
/// for element in measure.elements {
///     switch element {
///     case .note(let note):
///         // Handle notes and rests
///     case .direction(let direction):
///         // Handle dynamics, tempo, text
///     case .attributes(let attrs):
///         // Handle clef, key, time changes
///     case .harmony(let chord):
///         // Handle chord symbols
///     case .barline(let bar):
///         // Handle mid-measure barlines
///     case .backup, .forward:
///         // Cursor movement for voices
///     case .print, .sound:
///         // Layout and playback hints
///     }
/// }
/// ```
public enum MeasureElement: Sendable {
    case note(Note)
    case backup(Backup)
    case forward(Forward)
    case direction(Direction)
    case attributes(MeasureAttributes)
    case harmony(Harmony)
    case barline(Barline)
    case print(PrintAttributes)
    case sound(Sound)
}

// MARK: - Backup and Forward

/// Moves the cursor backward in time (for multiple voices).
public struct Backup: Codable, Sendable {
    /// Duration to move backward (in divisions).
    public var duration: Int

    public init(duration: Int) {
        self.duration = duration
    }
}

/// Moves the cursor forward in time (for space/padding).
public struct Forward: Codable, Sendable {
    /// Duration to move forward (in divisions).
    public var duration: Int

    /// The voice this applies to.
    public var voice: Int?

    /// The staff this applies to.
    public var staff: Int?

    public init(duration: Int, voice: Int? = nil, staff: Int? = nil) {
        self.duration = duration
        self.voice = voice
        self.staff = staff
    }
}

// MARK: - Print Attributes

/// Print and layout hints for a measure.
public struct PrintAttributes: Codable, Sendable {
    /// Whether to start a new system.
    public var newSystem: Bool

    /// Whether to start a new page.
    public var newPage: Bool

    /// Blank page number before this.
    public var blankPage: Int?

    /// Page number to display.
    public var pageNumber: String?

    /// Staff spacing override.
    public var staffSpacing: Double?

    public init(
        newSystem: Bool = false,
        newPage: Bool = false,
        blankPage: Int? = nil,
        pageNumber: String? = nil,
        staffSpacing: Double? = nil
    ) {
        self.newSystem = newSystem
        self.newPage = newPage
        self.blankPage = blankPage
        self.pageNumber = pageNumber
        self.staffSpacing = staffSpacing
    }
}

// MARK: - Sound

/// Playback/sound settings.
public struct Sound: Codable, Sendable {
    /// Tempo in beats per minute.
    public var tempo: Double?

    /// Dynamics (0-127, like MIDI velocity).
    public var dynamics: Double?

    /// Whether to start a dacapo.
    public var dacapo: Bool

    /// Segno marker name.
    public var segno: String?

    /// Dal segno target.
    public var dalsegno: String?

    /// Coda marker name.
    public var coda: String?

    /// To coda target.
    public var tocoda: String?

    /// Forward repeat (play count).
    public var forwardRepeat: Bool

    /// Fine (end point).
    public var fine: Bool

    public init(
        tempo: Double? = nil,
        dynamics: Double? = nil,
        dacapo: Bool = false,
        segno: String? = nil,
        dalsegno: String? = nil,
        coda: String? = nil,
        tocoda: String? = nil,
        forwardRepeat: Bool = false,
        fine: Bool = false
    ) {
        self.tempo = tempo
        self.dynamics = dynamics
        self.dacapo = dacapo
        self.segno = segno
        self.dalsegno = dalsegno
        self.coda = coda
        self.tocoda = tocoda
        self.forwardRepeat = forwardRepeat
        self.fine = fine
    }
}

// MARK: - Harmony (Chord Symbols)

/// A chord symbol / harmony annotation.
public struct Harmony: Codable, Sendable {
    /// The root pitch of the chord.
    public var root: HarmonyRoot

    /// The chord kind (major, minor, etc.).
    public var kind: ChordKind

    /// Bass note (for slash chords).
    public var bass: HarmonyRoot?

    /// Chord degrees/alterations.
    public var degrees: [ChordDegree]

    /// Position offset.
    public var offset: Int?

    /// Staff assignment.
    public var staff: Int?

    public init(
        root: HarmonyRoot,
        kind: ChordKind,
        bass: HarmonyRoot? = nil,
        degrees: [ChordDegree] = [],
        offset: Int? = nil,
        staff: Int? = nil
    ) {
        self.root = root
        self.kind = kind
        self.bass = bass
        self.degrees = degrees
        self.offset = offset
        self.staff = staff
    }
}

/// Root or bass note of a chord.
public struct HarmonyRoot: Codable, Sendable {
    /// The pitch step.
    public var step: PitchStep

    /// Alteration.
    public var alter: Double?

    public init(step: PitchStep, alter: Double? = nil) {
        self.step = step
        self.alter = alter
    }
}

/// Chord quality/type.
public enum ChordKind: String, Codable, Sendable {
    case major
    case minor
    case augmented
    case diminished
    case dominant
    case majorSeventh = "major-seventh"
    case minorSeventh = "minor-seventh"
    case diminishedSeventh = "diminished-seventh"
    case augmentedSeventh = "augmented-seventh"
    case halfDiminished = "half-diminished"
    case majorMinor = "major-minor"
    case majorSixth = "major-sixth"
    case minorSixth = "minor-sixth"
    case dominantNinth = "dominant-ninth"
    case majorNinth = "major-ninth"
    case minorNinth = "minor-ninth"
    case dominant11th = "dominant-11th"
    case major11th = "major-11th"
    case minor11th = "minor-11th"
    case dominant13th = "dominant-13th"
    case major13th = "major-13th"
    case minor13th = "minor-13th"
    case suspended2nd = "suspended-second"
    case suspended4th = "suspended-fourth"
    case power
    case none
    case other
}

/// A chord degree alteration.
public struct ChordDegree: Codable, Sendable {
    /// The scale degree value.
    public var value: Int

    /// Alteration.
    public var alter: Double?

    /// Type of modification.
    public var type: DegreeType

    public init(value: Int, alter: Double? = nil, type: DegreeType) {
        self.value = value
        self.alter = alter
        self.type = type
    }
}

/// Type of chord degree modification.
public enum DegreeType: String, Codable, Sendable {
    case add
    case alter
    case subtract
}
