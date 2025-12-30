import Foundation

/// Attributes that can change at measure boundaries (clef, key, time).
public struct MeasureAttributes: Codable, Sendable {
    /// Divisions per quarter note (for duration calculations).
    public var divisions: Int?

    /// Key signatures (per staff).
    public var keySignatures: [KeySignature]

    /// Time signatures (per staff).
    public var timeSignatures: [TimeSignature]

    /// Number of staves in the part.
    public var staves: Int?

    /// Clefs (per staff).
    public var clefs: [Clef]

    /// Transposition settings.
    public var transposes: [Transpose]

    /// Staff details.
    public var staffDetails: [StaffDetails]

    /// Measure styles (multi-rest, etc.).
    public var measureStyle: MeasureStyle?

    public init(
        divisions: Int? = nil,
        keySignatures: [KeySignature] = [],
        timeSignatures: [TimeSignature] = [],
        staves: Int? = nil,
        clefs: [Clef] = [],
        transposes: [Transpose] = [],
        staffDetails: [StaffDetails] = [],
        measureStyle: MeasureStyle? = nil
    ) {
        self.divisions = divisions
        self.keySignatures = keySignatures
        self.timeSignatures = timeSignatures
        self.staves = staves
        self.clefs = clefs
        self.transposes = transposes
        self.staffDetails = staffDetails
        self.measureStyle = measureStyle
    }
}

// MARK: - Key Signature

/// A key signature definition.
public struct KeySignature: Codable, Sendable {
    /// The number of sharps (positive) or flats (negative).
    public var fifths: Int

    /// The mode of the key.
    public var mode: KeyMode?

    /// The staff this applies to.
    public var staffNumber: Int?

    public init(fifths: Int, mode: KeyMode? = nil, staffNumber: Int? = nil) {
        self.fifths = fifths
        self.mode = mode
        self.staffNumber = staffNumber
    }

    /// Common key signature presets
    public static let cMajor = KeySignature(fifths: 0, mode: .major)
    public static let gMajor = KeySignature(fifths: 1, mode: .major)
    public static let dMajor = KeySignature(fifths: 2, mode: .major)
    public static let fMajor = KeySignature(fifths: -1, mode: .major)
    public static let bbMajor = KeySignature(fifths: -2, mode: .major)
    public static let aMinor = KeySignature(fifths: 0, mode: .minor)
}

/// Key mode.
public enum KeyMode: String, Codable, Sendable {
    case major
    case minor
    case dorian
    case phrygian
    case lydian
    case mixolydian
    case aeolian
    case ionian
    case locrian
    case none
}

// MARK: - Time Signature

/// A time signature definition.
public struct TimeSignature: Codable, Sendable {
    /// The beat count (numerator).
    public var beats: String

    /// The beat unit (denominator).
    public var beatType: String

    /// Symbol to use (common, cut, single-number, etc.).
    public var symbol: TimeSymbol?

    /// The staff this applies to.
    public var staffNumber: Int?

    public init(
        beats: String,
        beatType: String,
        symbol: TimeSymbol? = nil,
        staffNumber: Int? = nil
    ) {
        self.beats = beats
        self.beatType = beatType
        self.symbol = symbol
        self.staffNumber = staffNumber
    }

    /// Common time signatures
    public static let common = TimeSignature(beats: "4", beatType: "4", symbol: .common)
    public static let cut = TimeSignature(beats: "2", beatType: "2", symbol: .cut)
    public static let fourFour = TimeSignature(beats: "4", beatType: "4")
    public static let threeFour = TimeSignature(beats: "3", beatType: "4")
    public static let twoFour = TimeSignature(beats: "2", beatType: "4")
    public static let sixEight = TimeSignature(beats: "6", beatType: "8")
}

/// Time signature symbol type.
public enum TimeSymbol: String, Codable, Sendable {
    case common
    case cut
    case singleNumber = "single-number"
    case normal
    case note
    case dottedNote = "dotted-note"
}

// MARK: - Clef

/// A clef definition.
public struct Clef: Codable, Sendable {
    /// The clef sign (G, F, C, etc.).
    public var sign: ClefSign

    /// The line the clef sits on (1 = bottom line).
    public var line: Int

    /// Octave transposition (-1 = 8vb, +1 = 8va).
    public var clefOctaveChange: Int?

    /// The staff this applies to.
    public var staffNumber: Int?

    /// Whether this is an additional clef (not the primary).
    public var additional: Bool

    public init(
        sign: ClefSign,
        line: Int,
        clefOctaveChange: Int? = nil,
        staffNumber: Int? = nil,
        additional: Bool = false
    ) {
        self.sign = sign
        self.line = line
        self.clefOctaveChange = clefOctaveChange
        self.staffNumber = staffNumber
        self.additional = additional
    }

    /// Common clef presets
    public static let treble = Clef(sign: .g, line: 2)
    public static let bass = Clef(sign: .f, line: 4)
    public static let alto = Clef(sign: .c, line: 3)
    public static let tenor = Clef(sign: .c, line: 4)
    public static let treble8vb = Clef(sign: .g, line: 2, clefOctaveChange: -1)
    public static let treble8va = Clef(sign: .g, line: 2, clefOctaveChange: 1)
    public static let bass8vb = Clef(sign: .f, line: 4, clefOctaveChange: -1)
    public static let percussion = Clef(sign: .percussion, line: 3)
    public static let tab = Clef(sign: .tab, line: 5)
}

/// Clef sign type.
public enum ClefSign: String, Codable, Sendable {
    case g = "G"
    case f = "F"
    case c = "C"
    case percussion
    case tab = "TAB"
    case none
}

// MARK: - Barline

/// A barline definition.
public struct Barline: Codable, Sendable {
    /// The barline location (left, right, middle).
    public var location: BarlineLocation

    /// The bar style.
    public var barStyle: BarStyle

    /// Repeat direction.
    public var repeatDirection: RepeatDirection?

    /// Number of times to repeat.
    public var repeatTimes: Int?

    /// Ending/volta information.
    public var ending: Ending?

    /// Fermata on the barline.
    public var fermata: Fermata?

    public init(
        location: BarlineLocation = .right,
        barStyle: BarStyle = .regular,
        repeatDirection: RepeatDirection? = nil,
        repeatTimes: Int? = nil,
        ending: Ending? = nil,
        fermata: Fermata? = nil
    ) {
        self.location = location
        self.barStyle = barStyle
        self.repeatDirection = repeatDirection
        self.repeatTimes = repeatTimes
        self.ending = ending
        self.fermata = fermata
    }
}

/// Barline location.
public enum BarlineLocation: String, Codable, Sendable {
    case left
    case right
    case middle
}

/// Bar style.
public enum BarStyle: String, Codable, Sendable {
    case regular
    case dotted
    case dashed
    case heavy
    case lightLight = "light-light"
    case lightHeavy = "light-heavy"
    case heavyLight = "heavy-light"
    case heavyHeavy = "heavy-heavy"
    case tick
    case short
    case none
}

/// Repeat direction.
public enum RepeatDirection: String, Codable, Sendable {
    case forward
    case backward
}

/// Ending (volta) information.
public struct Ending: Codable, Sendable {
    /// The ending number(s) (e.g., "1", "1, 2").
    public var number: String

    /// The ending type.
    public var type: EndingType

    /// Display text.
    public var text: String?

    public init(number: String, type: EndingType, text: String? = nil) {
        self.number = number
        self.type = type
        self.text = text
    }
}

/// Ending type.
public enum EndingType: String, Codable, Sendable {
    case start
    case stop
    case discontinue
}

// MARK: - Transpose

/// Transposition settings.
public struct Transpose: Codable, Sendable {
    /// Diatonic steps to transpose.
    public var diatonic: Int?

    /// Chromatic semitones to transpose.
    public var chromatic: Int

    /// Octave change.
    public var octaveChange: Int?

    /// Whether to double in the octave.
    public var double: Bool

    /// Staff number.
    public var staffNumber: Int?

    public init(
        diatonic: Int? = nil,
        chromatic: Int,
        octaveChange: Int? = nil,
        double: Bool = false,
        staffNumber: Int? = nil
    ) {
        self.diatonic = diatonic
        self.chromatic = chromatic
        self.octaveChange = octaveChange
        self.double = double
        self.staffNumber = staffNumber
    }
}

// MARK: - Staff Details

/// Detailed staff settings.
public struct StaffDetails: Codable, Sendable {
    /// Staff number.
    public var staffNumber: Int?

    /// Number of lines (default 5).
    public var staffLines: Int?

    /// Staff type.
    public var staffType: StaffType?

    /// Whether to show time signature.
    public var showTimeSignature: Bool?

    public init(
        staffNumber: Int? = nil,
        staffLines: Int? = nil,
        staffType: StaffType? = nil,
        showTimeSignature: Bool? = nil
    ) {
        self.staffNumber = staffNumber
        self.staffLines = staffLines
        self.staffType = staffType
        self.showTimeSignature = showTimeSignature
    }
}

/// Staff type.
public enum StaffType: String, Codable, Sendable {
    case ossia
    case cue
    case editorial
    case regular
    case alternate
}

// MARK: - Measure Style

/// Measure-level styles.
public struct MeasureStyle: Codable, Sendable {
    /// Multi-rest count.
    public var multipleRest: Int?

    /// Whether to use slash notation.
    public var slash: SlashNotation?

    /// Beat repeat notation.
    public var beatRepeat: BeatRepeat?

    /// Measure repeat notation.
    public var measureRepeat: MeasureRepeat?

    public init(
        multipleRest: Int? = nil,
        slash: SlashNotation? = nil,
        beatRepeat: BeatRepeat? = nil,
        measureRepeat: MeasureRepeat? = nil
    ) {
        self.multipleRest = multipleRest
        self.slash = slash
        self.beatRepeat = beatRepeat
        self.measureRepeat = measureRepeat
    }
}

/// Slash notation settings.
public struct SlashNotation: Codable, Sendable {
    public var type: StartStop
    public var useDots: Bool
    public var useStems: Bool

    public init(type: StartStop, useDots: Bool = false, useStems: Bool = false) {
        self.type = type
        self.useDots = useDots
        self.useStems = useStems
    }
}

/// Beat repeat settings.
public struct BeatRepeat: Codable, Sendable {
    public var type: StartStop
    public var slashes: Int?

    public init(type: StartStop, slashes: Int? = nil) {
        self.type = type
        self.slashes = slashes
    }
}

/// Measure repeat settings.
public struct MeasureRepeat: Codable, Sendable {
    public var type: StartStop
    public var slashes: Int?

    public init(type: StartStop, slashes: Int? = nil) {
        self.type = type
        self.slashes = slashes
    }
}
