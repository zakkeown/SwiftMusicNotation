import Foundation

/// A part in a musical score representing an instrument or voice.
///
/// A `Part` contains all the measures for a single instrument or vocal line. Parts can
/// have multiple staves (like piano with treble and bass), and can be grouped together
/// (like a string section in an orchestra).
///
/// ## Structure
///
/// ```
/// Part
/// ├── id: String (e.g., "P1")
/// ├── name: String (e.g., "Violin I")
/// ├── staffCount: Int (1 for most, 2 for piano)
/// ├── instruments: [Instrument] (sound/playback info)
/// └── measures: [Measure]
///     └── elements: [MeasureElement]
/// ```
///
/// ## Accessing Measures
///
/// ```swift
/// // By index
/// let firstMeasure = part.measures[0]
///
/// // By measure number (string to handle pickups like "0", "1a")
/// if let pickup = part.measure(number: "0") {
///     print("Has pickup measure")
/// }
///
/// // Safely by index
/// if let measure = part.measure(at: 15) {
///     // Process measure 16
/// }
/// ```
///
/// ## Multi-Staff Parts
///
/// Piano and other instruments use multiple staves:
///
/// ```swift
/// let piano = Part(
///     id: "P1",
///     name: "Piano",
///     staffCount: 2  // Treble and bass staves
/// )
///
/// // Elements in measures specify their staff
/// let note = Note(
///     pitch: Pitch(step: .c, octave: 4),
///     duration: Duration(base: .quarter),
///     staff: 2  // Bass staff
/// )
/// ```
///
/// ## Percussion Parts
///
/// Percussion parts use special notation and MIDI mapping:
///
/// ```swift
/// if part.isPercussion {
///     let map = part.effectivePercussionMap
///     // Map handles staff position → instrument → notehead → MIDI
/// }
/// ```
///
/// - SeeAlso: ``Score`` for the containing score
/// - SeeAlso: ``Measure`` for measure contents
/// - SeeAlso: ``PercussionMap`` for percussion handling
public final class Part: Identifiable, Sendable {
    /// Unique identifier for this part.
    public let id: String

    /// The display name of the part (e.g., "Violin I").
    public var name: String

    /// Abbreviated name for the part (e.g., "Vln. I").
    public var abbreviation: String?

    /// The number of staves in this part.
    public var staffCount: Int

    /// The measures in this part.
    public var measures: [Measure]

    /// Instrument definitions for this part.
    public var instruments: [Instrument]

    /// MIDI settings for playback.
    public var midiInstruments: [MIDIInstrument]

    /// Percussion map for this part.
    ///
    /// If this part uses a percussion clef, this map defines how staff positions
    /// map to percussion instruments, noteheads, and MIDI notes.
    public var percussionMap: PercussionMap?

    /// Creates a new part.
    public init(
        id: String,
        name: String,
        abbreviation: String? = nil,
        staffCount: Int = 1,
        measures: [Measure] = [],
        instruments: [Instrument] = [],
        midiInstruments: [MIDIInstrument] = [],
        percussionMap: PercussionMap? = nil
    ) {
        self.id = id
        self.name = name
        self.abbreviation = abbreviation
        self.staffCount = staffCount
        self.measures = measures
        self.instruments = instruments
        self.midiInstruments = midiInstruments
        self.percussionMap = percussionMap
    }

    /// Whether this part uses percussion notation.
    ///
    /// Returns true if a percussion map is set, or if the first measure
    /// uses a percussion clef.
    public var isPercussion: Bool {
        if percussionMap != nil {
            return true
        }
        // Check if first measure has percussion clef
        if let firstMeasure = measures.first {
            for element in firstMeasure.elements {
                if case .attributes(let attrs) = element,
                   let clef = attrs.clefs.first,
                   clef.sign == .percussion {
                    return true
                }
            }
        }
        return false
    }

    /// Gets the effective percussion map for this part.
    ///
    /// Returns the explicitly set percussion map, or a standard drum kit
    /// map if this is a percussion part without an explicit map.
    public var effectivePercussionMap: PercussionMap? {
        if let map = percussionMap {
            return map
        }
        if isPercussion {
            return .standardDrumKit
        }
        return nil
    }

    /// Returns the measure at the specified index.
    public func measure(at index: Int) -> Measure? {
        guard measures.indices.contains(index) else { return nil }
        return measures[index]
    }

    /// Returns the measure with the specified number.
    public func measure(number: String) -> Measure? {
        measures.first { $0.number == number }
    }
}

// MARK: - Instrument

/// An instrument definition within a part.
///
/// `Instrument` describes a musical instrument for display and playback purposes.
/// A part may contain multiple instruments (e.g., a woodwind player doubling on
/// flute and piccolo).
///
/// ## Example
///
/// ```swift
/// let flute = Instrument(
///     id: "I1",
///     name: "Flute",
///     abbreviation: "Fl.",
///     sound: "wind.flutes.flute"
/// )
/// ```
///
/// The `sound` property uses MusicXML sound IDs for playback mapping.
public struct Instrument: Codable, Sendable {
    /// Unique identifier for this instrument.
    public let id: String

    /// The instrument name.
    public var name: String

    /// Abbreviated instrument name.
    public var abbreviation: String?

    /// The instrument sound (for playback).
    public var sound: String?

    /// Whether this is a solo instrument.
    public var solo: Bool

    /// Whether this is an ensemble/section.
    public var ensemble: Bool

    public init(
        id: String,
        name: String,
        abbreviation: String? = nil,
        sound: String? = nil,
        solo: Bool = false,
        ensemble: Bool = false
    ) {
        self.id = id
        self.name = name
        self.abbreviation = abbreviation
        self.sound = sound
        self.solo = solo
        self.ensemble = ensemble
    }
}

// MARK: - MIDI Instrument

/// MIDI settings for an instrument.
///
/// `MIDIInstrument` defines how an instrument should sound during playback,
/// including channel assignment, program (patch) selection, and mix settings.
///
/// ## Example
///
/// ```swift
/// let midiSettings = MIDIInstrument(
///     instrumentId: "I1",
///     midiChannel: 1,
///     midiProgram: 73,  // Flute in General MIDI
///     volume: 80,
///     pan: 0  // Center
/// )
/// ```
///
/// ## General MIDI Programs
///
/// Common program numbers (0-indexed):
/// - 0-7: Piano
/// - 24-31: Guitar
/// - 32-39: Bass
/// - 40-47: Strings
/// - 56-63: Brass
/// - 64-71: Reed
/// - 72-79: Pipe (including 73: Flute)
public struct MIDIInstrument: Codable, Sendable {
    /// The instrument ID this applies to.
    public var instrumentId: String?

    /// MIDI channel (1-16).
    public var midiChannel: Int?

    /// MIDI program number (0-127).
    public var midiProgram: Int?

    /// MIDI bank number.
    public var midiBank: Int?

    /// Volume (0-100).
    public var volume: Double?

    /// Pan position (-90 to +90).
    public var pan: Double?

    public init(
        instrumentId: String? = nil,
        midiChannel: Int? = nil,
        midiProgram: Int? = nil,
        midiBank: Int? = nil,
        volume: Double? = nil,
        pan: Double? = nil
    ) {
        self.instrumentId = instrumentId
        self.midiChannel = midiChannel
        self.midiProgram = midiProgram
        self.midiBank = midiBank
        self.volume = volume
        self.pan = pan
    }
}

// MARK: - Part Group

/// A group of parts (e.g., orchestral sections).
public struct PartGroup: Codable, Sendable {
    /// The group number.
    public var number: Int

    /// Group symbol type.
    public var groupSymbol: GroupSymbol?

    /// Group name.
    public var groupName: String?

    /// Abbreviated group name.
    public var groupAbbreviation: String?

    /// Whether barlines are connected.
    public var groupBarline: GroupBarline?

    public init(
        number: Int,
        groupSymbol: GroupSymbol? = nil,
        groupName: String? = nil,
        groupAbbreviation: String? = nil,
        groupBarline: GroupBarline? = nil
    ) {
        self.number = number
        self.groupSymbol = groupSymbol
        self.groupName = groupName
        self.groupAbbreviation = groupAbbreviation
        self.groupBarline = groupBarline
    }
}

/// Symbol used to group parts.
public enum GroupSymbol: String, Codable, Sendable {
    case none
    case brace
    case line
    case bracket
    case square
}

/// Barline grouping style.
public enum GroupBarline: String, Codable, Sendable {
    case yes
    case no
    case mensurstrich  // Barlines between staves only
}
