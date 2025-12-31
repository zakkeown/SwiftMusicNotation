import Foundation

/// A note or rest in a musical score.
///
/// `Note` represents any rhythmic event: pitched notes, unpitched percussion notes, or rests.
/// It contains comprehensive information about duration, pitch, appearance, and attached
/// notations like articulations, dynamics, and lyrics.
///
/// ## Note Types
///
/// Notes are categorized by their content:
///
/// ```swift
/// // Pitched note (most common)
/// let cNote = Note(
///     noteType: .pitched(Pitch(step: .c, octave: 4)),
///     durationDivisions: 1,
///     type: .quarter
/// )
///
/// // Rest
/// let rest = Note(
///     noteType: .rest(RestInfo(measureRest: true)),
///     durationDivisions: 4,
///     type: .whole
/// )
///
/// // Unpitched (percussion)
/// let snare = Note(
///     noteType: .unpitched(UnpitchedNote(
///         displayStep: .c,
///         displayOctave: 5,
///         percussionInstrument: .snare
///     )),
///     durationDivisions: 1,
///     type: .quarter
/// )
/// ```
///
/// ## Accessing Pitch
///
/// Use convenience properties to access note content:
///
/// ```swift
/// if let pitch = note.pitch {
///     print("\(pitch.step)\(pitch.octave)")  // "C4"
/// } else if note.isRest {
///     print("Rest")
/// }
/// ```
///
/// ## Chords
///
/// Chord tones share the same rhythmic position:
///
/// ```swift
/// // First note establishes position
/// let c = Note(noteType: .pitched(cPitch), ...)
///
/// // Chord tones have isChordTone = true
/// let e = Note(noteType: .pitched(ePitch), isChordTone: true, ...)
/// let g = Note(noteType: .pitched(gPitch), isChordTone: true, ...)
/// ```
///
/// ## Notations
///
/// Access articulations, dynamics, ornaments, and other notations:
///
/// ```swift
/// for notation in note.notations {
///     switch notation {
///     case .articulations(let marks):
///         // Staccato, accent, etc.
///     case .dynamics(let dynamics):
///         // p, f, sfz, etc.
///     case .slur(let slur):
///         // Slur start/stop
///     case .fermata(let fermata):
///         // Hold marking
///     default:
///         break
///     }
/// }
/// ```
///
/// ## Grace Notes
///
/// Grace notes have no rhythmic duration but modify timing:
///
/// ```swift
/// let graceNote = Note(
///     noteType: .pitched(pitch),
///     type: .eighth,
///     grace: GraceNote(slash: true)  // Acciaccatura
/// )
///
/// if note.isGraceNote {
///     print("Grace note")
/// }
/// ```
///
/// - SeeAlso: ``Pitch`` for pitch representation
/// - SeeAlso: ``Duration`` for rhythmic values
/// - SeeAlso: ``Notation`` for attached notations
public struct Note: Identifiable, Sendable {
    /// Unique identifier for this note.
    public let id: UUID

    /// The type of note content.
    public var noteType: NoteContent

    /// Duration in divisions (MusicXML time units).
    public var durationDivisions: Int

    /// The visual note type (quarter, eighth, etc.).
    public var type: DurationBase?

    /// Number of augmentation dots.
    public var dots: Int

    /// Voice assignment (for multiple voices per staff).
    public var voice: Int

    /// Staff assignment (for multi-staff parts like piano).
    public var staff: Int

    /// Whether this is part of a chord (shares duration with previous note).
    public var isChordTone: Bool

    /// Grace note properties, if this is a grace note.
    public var grace: GraceNote?

    /// Whether this is a cue-sized note.
    public var cue: Bool

    /// Stem direction.
    public var stemDirection: StemDirection?

    /// Notehead type and properties.
    public var notehead: NoteheadInfo?

    /// Beam connections.
    public var beams: [BeamValue]

    /// Tie information.
    public var ties: [Tie]

    /// Accidental display.
    public var accidental: AccidentalMark?

    /// Notations attached to this note.
    public var notations: [Notation]

    /// Lyrics attached to this note.
    public var lyrics: [Lyric]

    /// Time modification for tuplets.
    public var timeModification: TupletRatio?

    /// Whether to print this note.
    public var printObject: Bool

    /// Creates a new note.
    public init(
        id: UUID = UUID(),
        noteType: NoteContent,
        durationDivisions: Int = 0,
        type: DurationBase? = nil,
        dots: Int = 0,
        voice: Int = 1,
        staff: Int = 1,
        isChordTone: Bool = false,
        grace: GraceNote? = nil,
        cue: Bool = false,
        stemDirection: StemDirection? = nil,
        notehead: NoteheadInfo? = nil,
        beams: [BeamValue] = [],
        ties: [Tie] = [],
        accidental: AccidentalMark? = nil,
        notations: [Notation] = [],
        lyrics: [Lyric] = [],
        timeModification: TupletRatio? = nil,
        printObject: Bool = true
    ) {
        self.id = id
        self.noteType = noteType
        self.durationDivisions = durationDivisions
        self.type = type
        self.dots = dots
        self.voice = voice
        self.staff = staff
        self.isChordTone = isChordTone
        self.grace = grace
        self.cue = cue
        self.stemDirection = stemDirection
        self.notehead = notehead
        self.beams = beams
        self.ties = ties
        self.accidental = accidental
        self.notations = notations
        self.lyrics = lyrics
        self.timeModification = timeModification
        self.printObject = printObject
    }

    /// The pitch of this note, if it's a pitched note.
    public var pitch: Pitch? {
        if case .pitched(let p) = noteType { return p }
        return nil
    }

    /// The unpitched note info, if this is an unpitched note.
    public var unpitched: UnpitchedNote? {
        if case .unpitched(let u) = noteType { return u }
        return nil
    }

    /// Whether this is a rest.
    public var isRest: Bool {
        if case .rest = noteType { return true }
        return false
    }

    /// Whether this is a grace note.
    public var isGraceNote: Bool {
        grace != nil
    }

    /// The duration object for this note.
    public var duration: Duration? {
        guard let base = type else { return nil }
        return Duration(base: base, dots: dots, tupletRatio: timeModification)
    }
}

// MARK: - Note Content

/// The content type of a note.
public enum NoteContent: Sendable {
    /// A pitched note.
    case pitched(Pitch)

    /// An unpitched note (e.g., percussion).
    case unpitched(UnpitchedNote)

    /// A rest.
    case rest(RestInfo)
}

/// Information about an unpitched note (e.g., percussion).
public struct UnpitchedNote: Codable, Sendable {
    /// Display step (for visual placement on staff).
    public var displayStep: PitchStep

    /// Display octave (for visual placement on staff).
    public var displayOctave: Int

    /// The MusicXML instrument ID reference.
    ///
    /// This corresponds to the id attribute of a score-instrument element
    /// in the part-list. Used to look up the specific percussion instrument.
    public var instrumentId: String?

    /// The resolved percussion instrument type.
    ///
    /// This may be set directly or resolved from the instrumentId via the
    /// part's percussion map.
    public var percussionInstrument: PercussionInstrument?

    /// Override for the notehead style.
    ///
    /// If nil, the notehead is determined by the percussion map or
    /// the instrument's default notehead.
    public var noteheadOverride: PercussionNotehead?

    /// Creates an unpitched note with display position only.
    public init(displayStep: PitchStep, displayOctave: Int) {
        self.displayStep = displayStep
        self.displayOctave = displayOctave
        self.instrumentId = nil
        self.percussionInstrument = nil
        self.noteheadOverride = nil
    }

    /// Creates an unpitched note with full percussion information.
    public init(
        displayStep: PitchStep,
        displayOctave: Int,
        instrumentId: String? = nil,
        percussionInstrument: PercussionInstrument? = nil,
        noteheadOverride: PercussionNotehead? = nil
    ) {
        self.displayStep = displayStep
        self.displayOctave = displayOctave
        self.instrumentId = instrumentId
        self.percussionInstrument = percussionInstrument
        self.noteheadOverride = noteheadOverride
    }

    /// The effective notehead for this unpitched note.
    ///
    /// Returns the override if set, otherwise returns the instrument's default
    /// notehead, or `.normal` if no instrument is set.
    public var effectiveNotehead: PercussionNotehead {
        if let override = noteheadOverride {
            return override
        }
        if let instrument = percussionInstrument {
            return instrument.defaultNotehead
        }
        return .normal
    }
}

/// Information about a rest.
public struct RestInfo: Codable, Sendable {
    /// Whether this is a full-measure rest.
    public var measureRest: Bool

    /// Display step for positioned rests.
    public var displayStep: PitchStep?

    /// Display octave for positioned rests.
    public var displayOctave: Int?

    public init(
        measureRest: Bool = false,
        displayStep: PitchStep? = nil,
        displayOctave: Int? = nil
    ) {
        self.measureRest = measureRest
        self.displayStep = displayStep
        self.displayOctave = displayOctave
    }
}

// MARK: - Stem Direction

/// Stem direction for a note.
public enum StemDirection: String, Codable, Sendable {
    case up
    case down
    case double  // Both directions (e.g., for cross-staff notation)
    case none    // No stem (used for whole notes, etc.)
}

// MARK: - Grace Note

/// Grace note properties.
public struct GraceNote: Codable, Sendable {
    /// Whether to steal time from the previous note.
    public var stealTimePrevious: Double?

    /// Whether to steal time from the following note.
    public var stealTimeFollowing: Double?

    /// Whether this is a slashed grace note (acciaccatura).
    public var slash: Bool

    public init(
        stealTimePrevious: Double? = nil,
        stealTimeFollowing: Double? = nil,
        slash: Bool = true
    ) {
        self.stealTimePrevious = stealTimePrevious
        self.stealTimeFollowing = stealTimeFollowing
        self.slash = slash
    }
}

// MARK: - Notehead Info

/// Notehead appearance information.
public struct NoteheadInfo: Codable, Sendable {
    /// The notehead shape.
    public var type: NoteheadType

    /// Whether the notehead is filled.
    public var filled: Bool?

    /// Whether to show parentheses.
    public var parentheses: Bool

    public init(
        type: NoteheadType = .normal,
        filled: Bool? = nil,
        parentheses: Bool = false
    ) {
        self.type = type
        self.filled = filled
        self.parentheses = parentheses
    }
}

/// Notehead shape types.
public enum NoteheadType: String, Codable, Sendable {
    case normal
    case diamond
    case triangle
    case square
    case cross
    case circleX = "circle-x"
    case slash
    case x
    case none
    // Add more as needed
}

// MARK: - Beam Value

/// Beam connection for a note.
public struct BeamValue: Codable, Sendable {
    /// Beam level (1 = primary beam, 2+ = secondary beams).
    public var number: Int

    /// Beam connection type.
    public var value: BeamType

    public init(number: Int, value: BeamType) {
        self.number = number
        self.value = value
    }
}

/// Beam connection type.
public enum BeamType: String, Codable, Sendable {
    case begin
    case `continue`
    case end
    case forwardHook = "forward hook"
    case backwardHook = "backward hook"
}

// MARK: - Tie

/// Tie information.
public struct Tie: Codable, Sendable {
    /// Tie type (start or stop).
    public var type: TieType

    public init(type: TieType) {
        self.type = type
    }
}

/// Tie type.
public enum TieType: String, Codable, Sendable {
    case start
    case stop
    case `continue`
    case letRing = "let-ring"
}

// MARK: - Accidental Mark

/// Visual accidental marking.
public struct AccidentalMark: Codable, Sendable {
    /// The accidental type.
    public var accidental: Accidental

    /// Whether to show in parentheses.
    public var parentheses: Bool

    /// Whether to show in brackets.
    public var brackets: Bool

    /// Whether this is editorial.
    public var editorial: Bool

    /// Whether this is cautionary.
    public var cautionary: Bool

    public init(
        accidental: Accidental,
        parentheses: Bool = false,
        brackets: Bool = false,
        editorial: Bool = false,
        cautionary: Bool = false
    ) {
        self.accidental = accidental
        self.parentheses = parentheses
        self.brackets = brackets
        self.editorial = editorial
        self.cautionary = cautionary
    }
}

// MARK: - Notation

/// Notations attached to a note (articulations, ornaments, etc.).
public enum Notation: Sendable {
    case tied(TiedNotation)
    case slur(SlurNotation)
    case tuplet(TupletNotation)
    case articulations([ArticulationMark])
    case dynamics([DynamicMark])
    case ornaments([Ornament])
    case technical([TechnicalMark])
    case fermata(Fermata)
    case arpeggiate(Arpeggiate)
    case glissando(Glissando)
    case slide(Slide)
    case accidentalMark(AccidentalMark)
}

/// Tied notation (visual tie).
public struct TiedNotation: Codable, Sendable {
    public var type: TieType
    public var number: Int?
    public var placement: Placement?

    public init(type: TieType, number: Int? = nil, placement: Placement? = nil) {
        self.type = type
        self.number = number
        self.placement = placement
    }
}

/// Slur notation.
public struct SlurNotation: Codable, Sendable {
    public var type: StartStopContinue
    public var number: Int
    public var placement: Placement?

    public init(type: StartStopContinue, number: Int = 1, placement: Placement? = nil) {
        self.type = type
        self.number = number
        self.placement = placement
    }
}

/// Tuplet notation.
public struct TupletNotation: Codable, Sendable {
    public var type: StartStop
    public var number: Int
    public var bracket: Bool?
    public var showNumber: ShowTuplet?
    public var showType: ShowTuplet?

    public init(
        type: StartStop,
        number: Int = 1,
        bracket: Bool? = nil,
        showNumber: ShowTuplet? = nil,
        showType: ShowTuplet? = nil
    ) {
        self.type = type
        self.number = number
        self.bracket = bracket
        self.showNumber = showNumber
        self.showType = showType
    }
}

/// Tuplet display options.
public enum ShowTuplet: String, Codable, Sendable {
    case actual
    case both
    case none
}

// MARK: - Lyric

/// Lyric syllable attached to a note.
public struct Lyric: Codable, Sendable {
    /// Lyric number/verse.
    public var number: String?

    /// Syllable text.
    public var text: String

    /// Syllabic type.
    public var syllabic: Syllabic?

    /// Whether this has an extending line.
    public var extend: Bool

    public init(
        number: String? = nil,
        text: String,
        syllabic: Syllabic? = nil,
        extend: Bool = false
    ) {
        self.number = number
        self.text = text
        self.syllabic = syllabic
        self.extend = extend
    }
}

/// Syllabic type for lyrics.
public enum Syllabic: String, Codable, Sendable {
    case single
    case begin
    case end
    case middle
}

// MARK: - Common Types

/// Placement above or below.
public enum Placement: String, Codable, Sendable {
    case above
    case below
}

/// Start or stop.
public enum StartStop: String, Codable, Sendable {
    case start
    case stop
}

/// Start, stop, or continue.
public enum StartStopContinue: String, Codable, Sendable {
    case start
    case stop
    case `continue`
}

// MARK: - Articulations

/// Articulation marking with placement information.
///
/// This struct wraps the ``Articulation`` enum for note attachments, providing
/// placement information for rendering. See ``Articulation`` for the full
/// list of articulation types and their SMuFL glyph mappings.
public struct ArticulationMark: Codable, Sendable {
    /// The type of articulation.
    public var articulation: Articulation
    /// Placement above or below the note.
    public var placement: Placement?

    public init(articulation: Articulation, placement: Placement? = nil) {
        self.articulation = articulation
        self.placement = placement
    }

    /// Initializer for MusicXML element names (for backwards compatibility).
    public init(type: String, placement: Placement? = nil) {
        self.articulation = Articulation(musicXMLName: type) ?? .accent
        self.placement = placement
    }

    /// The effective placement (explicit or default based on articulation type).
    public var effectivePlacement: Placement {
        placement ?? articulation.defaultPlacement
    }
}

// MARK: - Dynamics (Note-attached)

/// Dynamic marking attached to a note.
public struct DynamicMark: Codable, Sendable {
    /// The dynamic value.
    public var dynamic: Dynamic
    /// Placement above or below the note.
    public var placement: Placement?

    public init(dynamic: Dynamic, placement: Placement? = nil) {
        self.dynamic = dynamic
        self.placement = placement
    }

    /// Legacy initializer for string-based type (for backwards compatibility).
    public init(type: String, placement: Placement? = nil) {
        self.dynamic = Dynamic(musicXMLName: type) ?? .mf
        self.placement = placement
    }
}

// MARK: - Ornaments

/// Types of ornament markings.
public enum OrnamentType: String, Codable, Sendable, CaseIterable {
    /// Trill - rapid alternation with the note above.
    case trill
    /// Turn - main note, note above, main note, note below, main note.
    case turn
    /// Delayed turn - turn that starts after the main note.
    case delayedTurn
    /// Inverted turn - main note, note below, main note, note above, main note.
    case invertedTurn
    /// Delayed inverted turn.
    case delayedInvertedTurn
    /// Vertical turn.
    case verticalTurn
    /// Shake - a type of trill.
    case shake
    /// Mordent (upper) - rapid alternation: main, upper, main.
    case mordent
    /// Inverted mordent (lower) - rapid alternation: main, lower, main.
    case invertedMordent
    /// Schleifer - Baroque slide ornament.
    case schleifer
    /// Tremolo - rapid repetition of a single note or alternation between two.
    case tremolo
    /// Appoggiatura - grace note that takes time from the main note.
    case appoggiatura
    /// Acciaccatura - crushed grace note played quickly before the beat.
    case acciaccatura

    /// Creates an OrnamentType from a MusicXML element name.
    public init?(musicXMLName: String) {
        switch musicXMLName {
        case "trill-mark": self = .trill
        case "turn": self = .turn
        case "delayed-turn": self = .delayedTurn
        case "inverted-turn": self = .invertedTurn
        case "delayed-inverted-turn": self = .delayedInvertedTurn
        case "vertical-turn": self = .verticalTurn
        case "shake": self = .shake
        case "mordent": self = .mordent
        case "inverted-mordent": self = .invertedMordent
        case "schleifer": self = .schleifer
        case "tremolo": self = .tremolo
        default: return nil
        }
    }

    /// The MusicXML element name for this ornament.
    public var musicXMLName: String {
        switch self {
        case .trill: return "trill-mark"
        case .turn: return "turn"
        case .delayedTurn: return "delayed-turn"
        case .invertedTurn: return "inverted-turn"
        case .delayedInvertedTurn: return "delayed-inverted-turn"
        case .verticalTurn: return "vertical-turn"
        case .shake: return "shake"
        case .mordent: return "mordent"
        case .invertedMordent: return "inverted-mordent"
        case .schleifer: return "schleifer"
        case .tremolo: return "tremolo"
        case .appoggiatura: return "appoggiatura"
        case .acciaccatura: return "acciaccatura"
        }
    }
}

/// Ornament marking with placement and optional properties.
public struct Ornament: Codable, Sendable {
    /// The type of ornament.
    public var type: OrnamentType
    /// Placement above or below the note.
    public var placement: Placement?
    /// For trills: whether to show a wavy line extension.
    public var hasWavyLine: Bool?
    /// For tremolos: number of tremolo marks (1 = 8th, 2 = 16th, 3 = 32nd).
    public var tremoloMarks: Int?
    /// Accidental for the auxiliary note (the note alternated with).
    public var accidental: Accidental?

    public init(
        type: OrnamentType,
        placement: Placement? = nil,
        hasWavyLine: Bool? = nil,
        tremoloMarks: Int? = nil,
        accidental: Accidental? = nil
    ) {
        self.type = type
        self.placement = placement
        self.hasWavyLine = hasWavyLine
        self.tremoloMarks = tremoloMarks
        self.accidental = accidental
    }

    /// Legacy initializer for string-based type (for backwards compatibility).
    public init(type: String, placement: Placement? = nil) {
        self.type = OrnamentType(musicXMLName: type) ?? .trill
        self.placement = placement
        self.hasWavyLine = nil
        self.tremoloMarks = nil
        self.accidental = nil
    }
}

// MARK: - Technical Markings

/// Types of technical markings (instrument-specific performance instructions).
public enum TechnicalMarkType: String, Codable, Sendable, CaseIterable {
    // MARK: String Techniques
    /// Up-bow (strings) - bow moves away from the hand.
    case upBow
    /// Down-bow (strings) - bow moves toward the hand.
    case downBow
    /// Natural harmonic (strings).
    case harmonic
    /// Open string (strings) - played without fingering.
    case openString
    /// Stopped note (strings/brass).
    case stopped
    /// Snap/Bartók pizzicato (strings) - string snaps against fingerboard.
    case snapPizzicato

    // MARK: Fingering
    /// Fingering number (for any instrument).
    case fingering
    /// String number indication (strings).
    case string
    /// Fret number (fretted strings).
    case fret

    // MARK: Guitar/Fretted String Techniques
    /// Hammer-on (guitar) - sound note by hammering finger down.
    case hammerOn
    /// Pull-off (guitar) - sound note by pulling finger away.
    case pullOff
    /// Bend (guitar) - bend string to raise pitch.
    case bend
    /// Tap (guitar) - tap string on fretboard.
    case tap

    // MARK: Pedal Techniques
    /// Heel (organ/harp).
    case heel
    /// Toe (organ/harp).
    case toe

    /// Creates a TechnicalMarkType from a MusicXML element name.
    public init?(musicXMLName: String) {
        switch musicXMLName {
        case "up-bow": self = .upBow
        case "down-bow": self = .downBow
        case "harmonic": self = .harmonic
        case "open-string": self = .openString
        case "stopped": self = .stopped
        case "snap-pizzicato": self = .snapPizzicato
        case "fingering": self = .fingering
        case "string": self = .string
        case "fret": self = .fret
        case "hammer-on": self = .hammerOn
        case "pull-off": self = .pullOff
        case "bend": self = .bend
        case "tap": self = .tap
        case "heel": self = .heel
        case "toe": self = .toe
        default: return nil
        }
    }

    /// The MusicXML element name for this technical marking.
    public var musicXMLName: String {
        switch self {
        case .upBow: return "up-bow"
        case .downBow: return "down-bow"
        case .harmonic: return "harmonic"
        case .openString: return "open-string"
        case .stopped: return "stopped"
        case .snapPizzicato: return "snap-pizzicato"
        case .fingering: return "fingering"
        case .string: return "string"
        case .fret: return "fret"
        case .hammerOn: return "hammer-on"
        case .pullOff: return "pull-off"
        case .bend: return "bend"
        case .tap: return "tap"
        case .heel: return "heel"
        case .toe: return "toe"
        }
    }
}

/// Technical marking with associated value information.
public struct TechnicalMark: Codable, Sendable {
    /// The type of technical marking.
    public var type: TechnicalMarkType
    /// Placement above or below the note.
    public var placement: Placement?
    /// Text value (for fingering: "1", "2", etc.; for string: "I", "II", etc.).
    public var text: String?
    /// Numeric value (for fret numbers, string numbers as integers).
    public var number: Int?

    public init(
        type: TechnicalMarkType,
        placement: Placement? = nil,
        text: String? = nil,
        number: Int? = nil
    ) {
        self.type = type
        self.placement = placement
        self.text = text
        self.number = number
    }

    /// Legacy initializer for string-based type (for backwards compatibility).
    public init(type: String) {
        self.type = TechnicalMarkType(musicXMLName: type) ?? .fingering
        self.placement = nil
        self.text = nil
        self.number = nil
    }
}

/// Fermata.
public struct Fermata: Codable, Sendable {
    public var shape: FermataShape
    public var type: FermataType

    public init(shape: FermataShape = .normal, type: FermataType = .upright) {
        self.shape = shape
        self.type = type
    }
}

public enum FermataShape: String, Codable, Sendable {
    case normal
    case angled
    case square
    case short = "short"
    case long = "long"
}

public enum FermataType: String, Codable, Sendable {
    case upright
    case inverted
}

/// Arpeggiate marking.
public struct Arpeggiate: Codable, Sendable {
    public var direction: ArpeggiateDirection?
    public var number: Int?

    public init(direction: ArpeggiateDirection? = nil, number: Int? = nil) {
        self.direction = direction
        self.number = number
    }
}

public enum ArpeggiateDirection: String, Codable, Sendable {
    case up
    case down
}

/// Glissando marking.
public struct Glissando: Codable, Sendable {
    public var type: StartStop
    public var number: Int?
    public var text: String?

    public init(type: StartStop, number: Int? = nil, text: String? = nil) {
        self.type = type
        self.number = number
        self.text = text
    }
}

/// Slide marking.
public struct Slide: Codable, Sendable {
    public var type: StartStop
    public var number: Int?

    public init(type: StartStop, number: Int? = nil) {
        self.type = type
        self.number = number
    }
}
