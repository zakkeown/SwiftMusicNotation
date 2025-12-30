import Foundation

/// A mapping between staff positions and percussion instruments.
///
/// PercussionMap defines how percussion notes are displayed on a staff
/// and how they map to MIDI note numbers for playback. Each entry
/// specifies the staff position, instrument, notehead style, and MIDI note.
public struct PercussionMap: Codable, Sendable, Equatable {

    /// The entries in this percussion map.
    public var entries: [PercussionMapEntry]

    /// Creates a percussion map with the given entries.
    public init(entries: [PercussionMapEntry] = []) {
        self.entries = entries
    }

    // MARK: - Lookup Methods

    /// Finds the percussion map entry for a given staff position.
    ///
    /// - Parameters:
    ///   - step: The pitch step (display position)
    ///   - octave: The octave (display position)
    /// - Returns: The matching entry, or nil if not found
    public func entry(at step: PitchStep, octave: Int) -> PercussionMapEntry? {
        entries.first { $0.displayStep == step && $0.displayOctave == octave }
    }

    /// Finds the percussion instrument for a given staff position.
    ///
    /// - Parameters:
    ///   - step: The pitch step (display position)
    ///   - octave: The octave (display position)
    /// - Returns: The instrument at that position, or nil if not found
    public func instrument(at step: PitchStep, octave: Int) -> PercussionInstrument? {
        entry(at: step, octave: octave)?.instrument
    }

    /// Finds the notehead for a given staff position.
    ///
    /// - Parameters:
    ///   - step: The pitch step (display position)
    ///   - octave: The octave (display position)
    /// - Returns: The notehead style, or nil if not found
    public func notehead(at step: PitchStep, octave: Int) -> PercussionNotehead? {
        entry(at: step, octave: octave)?.notehead
    }

    /// Finds the MIDI note for a given staff position.
    ///
    /// - Parameters:
    ///   - step: The pitch step (display position)
    ///   - octave: The octave (display position)
    /// - Returns: The MIDI note number, or nil if not found
    public func midiNote(at step: PitchStep, octave: Int) -> UInt8? {
        entry(at: step, octave: octave)?.midiNote
    }

    /// Finds the entry for a given instrument.
    ///
    /// - Parameter instrument: The percussion instrument to find
    /// - Returns: The first entry for that instrument, or nil if not found
    public func entry(for instrument: PercussionInstrument) -> PercussionMapEntry? {
        entries.first { $0.instrument == instrument }
    }

    /// Finds the entry for a given MIDI note.
    ///
    /// - Parameter midiNote: The MIDI note number
    /// - Returns: The entry for that MIDI note, or nil if not found
    public func entry(forMidiNote midiNote: UInt8) -> PercussionMapEntry? {
        entries.first { $0.midiNote == midiNote }
    }

    // MARK: - Standard Maps

    /// Standard General MIDI drum kit percussion map.
    ///
    /// This map provides the standard 5-line drum kit notation used in
    /// popular music, with bass drum on the bottom, snare in the middle,
    /// hi-hat and cymbals on top.
    public static var standardDrumKit: PercussionMap {
        PercussionMap(entries: [
            // Bass drum - space below bottom line (F4)
            PercussionMapEntry(
                displayStep: .f, displayOctave: 4,
                instrument: .bassDrum,
                notehead: .normal,
                midiNote: 36,
                stemDirection: .down
            ),

            // Floor tom - bottom space (A4)
            PercussionMapEntry(
                displayStep: .a, displayOctave: 4,
                instrument: .floorTom,
                notehead: .normal,
                midiNote: 43,
                stemDirection: .down
            ),

            // Low tom - bottom line (B4)
            PercussionMapEntry(
                displayStep: .b, displayOctave: 4,
                instrument: .lowTom,
                notehead: .normal,
                midiNote: 45,
                stemDirection: .up
            ),

            // Snare drum - middle line (C5)
            PercussionMapEntry(
                displayStep: .c, displayOctave: 5,
                instrument: .snareDrum,
                notehead: .normal,
                midiNote: 38,
                stemDirection: .up
            ),

            // Side stick - same position as snare, different notehead
            PercussionMapEntry(
                displayStep: .c, displayOctave: 5,
                instrument: .sideStick,
                notehead: .plus,
                midiNote: 37,
                stemDirection: .up
            ),

            // Mid tom - space above middle (D5)
            PercussionMapEntry(
                displayStep: .d, displayOctave: 5,
                instrument: .midTom,
                notehead: .normal,
                midiNote: 47,
                stemDirection: .up
            ),

            // High tom - second line from top (E5)
            PercussionMapEntry(
                displayStep: .e, displayOctave: 5,
                instrument: .highTom,
                notehead: .normal,
                midiNote: 50,
                stemDirection: .up
            ),

            // Ride cymbal - second space from top (F5)
            PercussionMapEntry(
                displayStep: .f, displayOctave: 5,
                instrument: .rideCymbal,
                notehead: .x,
                midiNote: 51,
                stemDirection: .up
            ),

            // Ride bell - same as ride, diamond notehead
            PercussionMapEntry(
                displayStep: .f, displayOctave: 5,
                instrument: .rideBell,
                notehead: .diamond,
                midiNote: 53,
                stemDirection: .up
            ),

            // Closed hi-hat - top space (G5)
            PercussionMapEntry(
                displayStep: .g, displayOctave: 5,
                instrument: .hiHatClosed,
                notehead: .x,
                midiNote: 42,
                stemDirection: .up
            ),

            // Open hi-hat - same position, circle-x notehead
            PercussionMapEntry(
                displayStep: .g, displayOctave: 5,
                instrument: .hiHatOpen,
                notehead: .circleX,
                midiNote: 46,
                stemDirection: .up
            ),

            // Hi-hat pedal - below staff (D4)
            PercussionMapEntry(
                displayStep: .d, displayOctave: 4,
                instrument: .hiHatPedal,
                notehead: .x,
                midiNote: 44,
                stemDirection: .down
            ),

            // Crash cymbal - above staff (A5)
            PercussionMapEntry(
                displayStep: .a, displayOctave: 5,
                instrument: .crashCymbal,
                notehead: .x,
                midiNote: 49,
                stemDirection: .up
            ),
        ])
    }

    /// Extended drum kit map with additional instruments.
    public static var extendedDrumKit: PercussionMap {
        var map = standardDrumKit
        map.entries.append(contentsOf: [
            // Cowbell - above crash (B5)
            PercussionMapEntry(
                displayStep: .b, displayOctave: 5,
                instrument: .cowbell,
                notehead: .diamond,
                midiNote: 56,
                stemDirection: .up
            ),

            // Tambourine - above cowbell (C6)
            PercussionMapEntry(
                displayStep: .c, displayOctave: 6,
                instrument: .tambourine,
                notehead: .diamond,
                midiNote: 54,
                stemDirection: .up
            ),

            // Splash cymbal - same as crash, different MIDI
            PercussionMapEntry(
                displayStep: .a, displayOctave: 5,
                instrument: .splashCymbal,
                notehead: .x,
                midiNote: 55,
                stemDirection: .up
            ),

            // China cymbal
            PercussionMapEntry(
                displayStep: .b, displayOctave: 5,
                instrument: .chinaCymbal,
                notehead: .x,
                midiNote: 52,
                stemDirection: .up
            ),

            // Acoustic bass drum (lower than standard kick)
            PercussionMapEntry(
                displayStep: .e, displayOctave: 4,
                instrument: .acousticBassDrum,
                notehead: .normal,
                midiNote: 35,
                stemDirection: .down
            ),
        ])
        return map
    }

    /// Latin percussion map for bongos, congas, and timbales.
    public static var latinPercussion: PercussionMap {
        PercussionMap(entries: [
            // Bongos
            PercussionMapEntry(
                displayStep: .e, displayOctave: 5,
                instrument: .highBongo,
                notehead: .normal,
                midiNote: 60,
                stemDirection: .up
            ),
            PercussionMapEntry(
                displayStep: .c, displayOctave: 5,
                instrument: .lowBongo,
                notehead: .normal,
                midiNote: 61,
                stemDirection: .up
            ),

            // Congas
            PercussionMapEntry(
                displayStep: .g, displayOctave: 5,
                instrument: .openHighConga,
                notehead: .normal,
                midiNote: 63,
                stemDirection: .up
            ),
            PercussionMapEntry(
                displayStep: .g, displayOctave: 5,
                instrument: .muteHighConga,
                notehead: .plus,
                midiNote: 62,
                stemDirection: .up
            ),
            PercussionMapEntry(
                displayStep: .a, displayOctave: 4,
                instrument: .lowConga,
                notehead: .normal,
                midiNote: 64,
                stemDirection: .down
            ),

            // Timbales
            PercussionMapEntry(
                displayStep: .f, displayOctave: 5,
                instrument: .highTimbale,
                notehead: .normal,
                midiNote: 65,
                stemDirection: .up
            ),
            PercussionMapEntry(
                displayStep: .b, displayOctave: 4,
                instrument: .lowTimbale,
                notehead: .normal,
                midiNote: 66,
                stemDirection: .up
            ),

            // Cowbell
            PercussionMapEntry(
                displayStep: .d, displayOctave: 5,
                instrument: .cowbell,
                notehead: .diamond,
                midiNote: 56,
                stemDirection: .up
            ),
        ])
    }
}

// MARK: - Percussion Map Entry

/// A single entry in a percussion map.
///
/// Each entry defines how one percussion instrument is displayed
/// on the staff and what MIDI note it produces.
public struct PercussionMapEntry: Codable, Sendable, Equatable {

    /// The display step (line or space on the staff).
    public var displayStep: PitchStep

    /// The display octave.
    public var displayOctave: Int

    /// The percussion instrument for this entry.
    public var instrument: PercussionInstrument

    /// The notehead style to use.
    public var notehead: PercussionNotehead

    /// The MIDI note number for playback.
    public var midiNote: UInt8

    /// The preferred stem direction, or nil for automatic.
    public var stemDirection: StemDirection?

    /// Optional voice assignment for multi-voice notation.
    public var voice: Int?

    /// Creates a percussion map entry.
    public init(
        displayStep: PitchStep,
        displayOctave: Int,
        instrument: PercussionInstrument,
        notehead: PercussionNotehead,
        midiNote: UInt8,
        stemDirection: StemDirection? = nil,
        voice: Int? = nil
    ) {
        self.displayStep = displayStep
        self.displayOctave = displayOctave
        self.instrument = instrument
        self.notehead = notehead
        self.midiNote = midiNote
        self.stemDirection = stemDirection
        self.voice = voice
    }
}

