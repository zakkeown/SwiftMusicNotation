import Foundation

/// A musical direction element (tempo markings, dynamics, rehearsal marks, etc.).
///
/// Directions are instructions to performers that don't directly correspond to notes
/// but affect how music is played or interpreted. They include tempo indications,
/// dynamic markings, expression text, and structural markers like rehearsal letters.
///
/// ## Direction Types
///
/// Directions contain one or more ``DirectionType`` values:
///
/// - **Rehearsal**: Section markers like "A", "B", or numbered rehearsal marks
/// - **Dynamics**: Volume indicators (p, f, mf, crescendo, etc.)
/// - **Wedge**: Crescendo/diminuendo hairpins
/// - **Words**: Text expressions ("dolce", "allegro con brio")
/// - **Metronome**: Tempo markings with BPM values
/// - **Pedal**: Piano pedaling instructions
/// - **Octave Shift**: 8va/8vb markings
/// - **Segno/Coda**: Navigation markers for repeats
///
/// ## Example
///
/// ```swift
/// // Create a tempo marking
/// let tempoDirection = Direction(
///     placement: .above,
///     types: [
///         .metronome(Metronome(
///             beatUnit: .quarter,
///             perMinute: "120"
///         ))
///     ]
/// )
///
/// // Create a dynamic marking
/// let dynamicDirection = Direction(
///     placement: .below,
///     types: [
///         .dynamics(DynamicsDirection(values: [.mf]))
///     ]
/// )
/// ```
///
/// - Note: Directions can have an offset from the current position to allow
///   placement between beats.
public struct Direction: Codable, Sendable {
    /// Placement above or below the staff.
    public var placement: Placement?

    /// Whether this is a directive-style marking.
    public var directive: Bool

    /// Voice assignment.
    public var voice: Int?

    /// Staff assignment.
    public var staff: Int

    /// Direction type content.
    public var types: [DirectionType]

    /// Offset from current position (in divisions).
    public var offset: Int?

    /// Sound information for playback.
    public var sound: Sound?

    public init(
        placement: Placement? = nil,
        directive: Bool = false,
        voice: Int? = nil,
        staff: Int = 1,
        types: [DirectionType] = [],
        offset: Int? = nil,
        sound: Sound? = nil
    ) {
        self.placement = placement
        self.directive = directive
        self.voice = voice
        self.staff = staff
        self.types = types
        self.offset = offset
        self.sound = sound
    }
}

// MARK: - Direction Type

/// Types of direction content.
public enum DirectionType: Codable, Sendable {
    case rehearsal(Rehearsal)
    case segno(Segno)
    case coda(Coda)
    case words(Words)
    case wedge(Wedge)
    case dynamics(DynamicsDirection)
    case dashes(Dashes)
    case bracket(DirectionBracket)
    case pedal(Pedal)
    case metronome(Metronome)
    case octaveShift(OctaveShift)
    case harpPedals(HarpPedals)
    case principalVoice(PrincipalVoice)
    case accordionRegistration(AccordionRegistration)
    case percussion(PercussionDirection)
    case otherDirection(OtherDirection)

    private enum CodingKeys: String, CodingKey {
        case type
        case value
    }

    private enum TypeKey: String, Codable {
        case rehearsal, segno, coda, words, wedge, dynamics, dashes, bracket
        case pedal, metronome, octaveShift, harpPedals, principalVoice
        case accordionRegistration, percussion, otherDirection
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(TypeKey.self, forKey: .type)
        switch type {
        case .rehearsal:
            self = .rehearsal(try container.decode(Rehearsal.self, forKey: .value))
        case .segno:
            self = .segno(try container.decode(Segno.self, forKey: .value))
        case .coda:
            self = .coda(try container.decode(Coda.self, forKey: .value))
        case .words:
            self = .words(try container.decode(Words.self, forKey: .value))
        case .wedge:
            self = .wedge(try container.decode(Wedge.self, forKey: .value))
        case .dynamics:
            self = .dynamics(try container.decode(DynamicsDirection.self, forKey: .value))
        case .dashes:
            self = .dashes(try container.decode(Dashes.self, forKey: .value))
        case .bracket:
            self = .bracket(try container.decode(DirectionBracket.self, forKey: .value))
        case .pedal:
            self = .pedal(try container.decode(Pedal.self, forKey: .value))
        case .metronome:
            self = .metronome(try container.decode(Metronome.self, forKey: .value))
        case .octaveShift:
            self = .octaveShift(try container.decode(OctaveShift.self, forKey: .value))
        case .harpPedals:
            self = .harpPedals(try container.decode(HarpPedals.self, forKey: .value))
        case .principalVoice:
            self = .principalVoice(try container.decode(PrincipalVoice.self, forKey: .value))
        case .accordionRegistration:
            self = .accordionRegistration(try container.decode(AccordionRegistration.self, forKey: .value))
        case .percussion:
            self = .percussion(try container.decode(PercussionDirection.self, forKey: .value))
        case .otherDirection:
            self = .otherDirection(try container.decode(OtherDirection.self, forKey: .value))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .rehearsal(let value):
            try container.encode(TypeKey.rehearsal, forKey: .type)
            try container.encode(value, forKey: .value)
        case .segno(let value):
            try container.encode(TypeKey.segno, forKey: .type)
            try container.encode(value, forKey: .value)
        case .coda(let value):
            try container.encode(TypeKey.coda, forKey: .type)
            try container.encode(value, forKey: .value)
        case .words(let value):
            try container.encode(TypeKey.words, forKey: .type)
            try container.encode(value, forKey: .value)
        case .wedge(let value):
            try container.encode(TypeKey.wedge, forKey: .type)
            try container.encode(value, forKey: .value)
        case .dynamics(let value):
            try container.encode(TypeKey.dynamics, forKey: .type)
            try container.encode(value, forKey: .value)
        case .dashes(let value):
            try container.encode(TypeKey.dashes, forKey: .type)
            try container.encode(value, forKey: .value)
        case .bracket(let value):
            try container.encode(TypeKey.bracket, forKey: .type)
            try container.encode(value, forKey: .value)
        case .pedal(let value):
            try container.encode(TypeKey.pedal, forKey: .type)
            try container.encode(value, forKey: .value)
        case .metronome(let value):
            try container.encode(TypeKey.metronome, forKey: .type)
            try container.encode(value, forKey: .value)
        case .octaveShift(let value):
            try container.encode(TypeKey.octaveShift, forKey: .type)
            try container.encode(value, forKey: .value)
        case .harpPedals(let value):
            try container.encode(TypeKey.harpPedals, forKey: .type)
            try container.encode(value, forKey: .value)
        case .principalVoice(let value):
            try container.encode(TypeKey.principalVoice, forKey: .type)
            try container.encode(value, forKey: .value)
        case .accordionRegistration(let value):
            try container.encode(TypeKey.accordionRegistration, forKey: .type)
            try container.encode(value, forKey: .value)
        case .percussion(let value):
            try container.encode(TypeKey.percussion, forKey: .type)
            try container.encode(value, forKey: .value)
        case .otherDirection(let value):
            try container.encode(TypeKey.otherDirection, forKey: .type)
            try container.encode(value, forKey: .value)
        }
    }
}

// MARK: - Rehearsal

/// Rehearsal mark.
public struct Rehearsal: Codable, Sendable {
    /// The rehearsal text/number.
    public var text: String

    /// Whether to show in a box.
    public var enclosure: Enclosure?

    public init(text: String, enclosure: Enclosure? = .rectangle) {
        self.text = text
        self.enclosure = enclosure
    }
}

/// Enclosure shape.
public enum Enclosure: String, Codable, Sendable {
    case rectangle
    case square
    case oval
    case circle
    case bracket
    case triangle
    case diamond
    case pentagon
    case hexagon
    case heptagon
    case octagon
    case nonagon
    case decagon
    case none
}

// MARK: - Segno and Coda

/// Segno marker.
public struct Segno: Codable, Sendable {
    public var id: String?

    public init(id: String? = nil) {
        self.id = id
    }
}

/// Coda marker.
public struct Coda: Codable, Sendable {
    public var id: String?

    public init(id: String? = nil) {
        self.id = id
    }
}

// MARK: - Words

/// Text direction (tempo markings, expression text, etc.).
public struct Words: Codable, Sendable {
    /// The text content.
    public var text: String

    /// Font specification.
    public var font: FontSpecification?

    /// Text justification.
    public var justify: Justification?

    public init(
        text: String,
        font: FontSpecification? = nil,
        justify: Justification? = nil
    ) {
        self.text = text
        self.font = font
        self.justify = justify
    }
}

// MARK: - Wedge (Hairpin)

/// Crescendo/diminuendo wedge (hairpin).
public struct Wedge: Codable, Sendable {
    /// Wedge type.
    public var type: WedgeType

    /// Number for distinguishing overlapping wedges.
    public var number: Int

    /// Opening spread in tenths.
    public var spread: Double?

    /// Whether this ends at niente.
    public var niente: Bool

    public init(
        type: WedgeType,
        number: Int = 1,
        spread: Double? = nil,
        niente: Bool = false
    ) {
        self.type = type
        self.number = number
        self.spread = spread
        self.niente = niente
    }
}

/// Wedge type.
public enum WedgeType: String, Codable, Sendable {
    case crescendo
    case diminuendo
    case stop
    case `continue`
}

// MARK: - Dynamics Direction

/// Dynamics direction.
public struct DynamicsDirection: Codable, Sendable {
    /// Dynamic values.
    public var values: [DynamicValue]

    public init(values: [DynamicValue]) {
        self.values = values
    }
}

/// Dynamic marking value.
public enum DynamicValue: String, Codable, Sendable {
    case p
    case pp
    case ppp
    case pppp
    case ppppp
    case pppppp
    case f
    case ff
    case fff
    case ffff
    case fffff
    case ffffff
    case mp
    case mf
    case sf
    case sfp
    case sfpp
    case fp
    case rf
    case rfz
    case sfz
    case sffz
    case fz
    case n  // niente
    case pf
    case sfzp
}

// MARK: - Dashes

/// Dashed line direction.
public struct Dashes: Codable, Sendable {
    public var type: StartStopContinue
    public var number: Int

    public init(type: StartStopContinue, number: Int = 1) {
        self.type = type
        self.number = number
    }
}

// MARK: - Direction Bracket

/// Bracket direction.
public struct DirectionBracket: Codable, Sendable {
    public var type: StartStopContinue
    public var number: Int
    public var lineEnd: LineEnd?

    public init(type: StartStopContinue, number: Int = 1, lineEnd: LineEnd? = nil) {
        self.type = type
        self.number = number
        self.lineEnd = lineEnd
    }
}

/// Line ending style.
public enum LineEnd: String, Codable, Sendable {
    case up
    case down
    case both
    case arrow
    case none
}

// MARK: - Pedal

/// Pedal direction.
public struct Pedal: Codable, Sendable {
    public var type: PedalType
    public var line: Bool?
    public var sign: Bool?

    public init(type: PedalType, line: Bool? = nil, sign: Bool? = nil) {
        self.type = type
        self.line = line
        self.sign = sign
    }
}

/// Pedal type.
public enum PedalType: String, Codable, Sendable {
    case start
    case stop
    case sostenuto
    case change
    case `continue`
}

// MARK: - Metronome

/// Metronome marking.
public struct Metronome: Codable, Sendable {
    /// Beat unit.
    public var beatUnit: DurationBase

    /// Dots on beat unit.
    public var beatUnitDots: Int

    /// Per minute tempo.
    public var perMinute: String?

    /// Second beat unit (for metric modulation).
    public var beatUnit2: DurationBase?

    /// Dots on second beat unit.
    public var beatUnit2Dots: Int

    /// Whether to show in parentheses.
    public var parentheses: Bool

    public init(
        beatUnit: DurationBase,
        beatUnitDots: Int = 0,
        perMinute: String? = nil,
        beatUnit2: DurationBase? = nil,
        beatUnit2Dots: Int = 0,
        parentheses: Bool = false
    ) {
        self.beatUnit = beatUnit
        self.beatUnitDots = beatUnitDots
        self.perMinute = perMinute
        self.beatUnit2 = beatUnit2
        self.beatUnit2Dots = beatUnit2Dots
        self.parentheses = parentheses
    }
}

// MARK: - Octave Shift

/// Octave shift (8va, 8vb, etc.).
public struct OctaveShift: Codable, Sendable {
    public var type: OctaveShiftType
    public var number: Int
    public var size: Int  // 8 or 15

    public init(type: OctaveShiftType, number: Int = 1, size: Int = 8) {
        self.type = type
        self.number = number
        self.size = size
    }
}

/// Octave shift type.
public enum OctaveShiftType: String, Codable, Sendable {
    case up
    case down
    case stop
    case `continue`
}

// MARK: - Placeholder Types

/// Harp pedal diagram.
public struct HarpPedals: Codable, Sendable {
    public var pedalTuning: [HarpPedalTuning]

    public init(pedalTuning: [HarpPedalTuning] = []) {
        self.pedalTuning = pedalTuning
    }
}

/// Harp pedal tuning.
public struct HarpPedalTuning: Codable, Sendable {
    public var pedalStep: PitchStep
    public var pedalAlter: Double

    public init(pedalStep: PitchStep, pedalAlter: Double) {
        self.pedalStep = pedalStep
        self.pedalAlter = pedalAlter
    }
}

/// Principal voice marking.
public struct PrincipalVoice: Codable, Sendable {
    public var type: StartStop
    public var symbol: PrincipalVoiceSymbol?

    public init(type: StartStop, symbol: PrincipalVoiceSymbol? = nil) {
        self.type = type
        self.symbol = symbol
    }
}

/// Principal voice symbol.
public enum PrincipalVoiceSymbol: String, Codable, Sendable {
    case hauptstimme = "Hauptstimme"
    case nebenstimme = "Nebenstimme"
    case plain
    case none
}

/// Accordion registration.
public struct AccordionRegistration: Codable, Sendable {
    public var accordionHigh: Bool?
    public var accordionMiddle: Int?
    public var accordionLow: Bool?

    public init(accordionHigh: Bool? = nil, accordionMiddle: Int? = nil, accordionLow: Bool? = nil) {
        self.accordionHigh = accordionHigh
        self.accordionMiddle = accordionMiddle
        self.accordionLow = accordionLow
    }
}

/// Percussion direction.
///
/// Represents MusicXML percussion elements that indicate specific percussion
/// instruments, beaters, sticks, or effects to be used.
public struct PercussionDirection: Codable, Sendable {
    /// The percussion content type.
    public var type: PercussionDirectionType

    /// Display text (if different from type).
    public var text: String?

    public init(type: PercussionDirectionType, text: String? = nil) {
        self.type = type
        self.text = text
    }

    /// Creates a simple text-based percussion direction.
    public init(value: String) {
        self.type = .other(value)
        self.text = nil
    }
}

/// The type of percussion direction.
public enum PercussionDirectionType: Codable, Sendable, Equatable {
    /// Timpani tuning indication with pitch information.
    case timpani(TimpaniTuning?)

    /// Membrane (drum) instrument specification.
    case membrane(MembraneType)

    /// Metal instrument specification.
    case metal(MetalType)

    /// Wood instrument specification.
    case wood(WoodType)

    /// Pitched percussion specification.
    case pitched(PitchedPercussionType)

    /// Glass instrument specification.
    case glass(GlassType)

    /// General effect specification.
    case effect(PercussionEffect)

    /// Beater type specification.
    case beater(BeaterType)

    /// Stick specification.
    case stick(StickSpecification)

    /// Stick location specification.
    case stickLocation(StickLocation)

    /// Generic/other percussion text.
    case other(String)
}

/// Other direction type.
public struct OtherDirection: Codable, Sendable {
    public var text: String

    public init(text: String) {
        self.text = text
    }
}
