import Foundation
import MusicNotationCore

/// Maps musical instruments from scores to General MIDI program numbers and channels.
///
/// `InstrumentMapper` analyzes part names and abbreviations to determine appropriate
/// MIDI programs, channels, and transpositions. It handles the full range of orchestral
/// and band instruments following General MIDI conventions.
///
/// ## Instrument Detection
///
/// The mapper uses name-based matching to identify instruments. It checks:
/// 1. Full part name (e.g., "Violin I")
/// 2. Abbreviation (e.g., "Vln. I")
/// 3. Common alternate spellings
///
/// ## MIDI Channel Assignment
///
/// Per General MIDI:
/// - Channels 1-9, 11-16: Melodic instruments
/// - Channel 10 (index 9): Percussion only
///
/// Parts are assigned channels sequentially, skipping channel 10 for melodic instruments.
///
/// ## Transposing Instruments
///
/// Many instruments are transposing (written pitch differs from sounding pitch):
/// - B♭ Clarinet: sounds a major 2nd lower
/// - F Horn: sounds a perfect 5th lower
/// - Guitar: sounds an octave lower
///
/// Use ``transposition(for:)`` to get the semitone offset for correct MIDI pitch.
///
/// ## Usage
///
/// ```swift
/// let mapper = InstrumentMapper()
///
/// // Get MIDI program for a violin part
/// let program = mapper.midiProgram(for: violinPart)  // Returns 40 (Violin)
///
/// // Get transposition for Bb clarinet
/// let semitones = mapper.transposition(for: clarinetPart)  // Returns -2
///
/// // Check if part is percussion
/// if mapper.isPercussionPart(drumsPart) {
///     // Use channel 10
/// }
/// ```
///
/// - SeeAlso: ``GeneralMIDI`` for program number constants
/// - SeeAlso: ``GeneralMIDIPercussion`` for percussion note numbers
/// - SeeAlso: ``ScoreSequencer`` for using the mapper during playback
public struct InstrumentMapper: Sendable {

    // MARK: - Initialization

    public init() {}

    // MARK: - Public Methods

    /// Gets the MIDI program number for a part.
    /// - Parameter part: The part to map.
    /// - Returns: MIDI program number (0-127).
    public func midiProgram(for part: Part) -> UInt8 {
        // First check the part name for common instruments
        let name = part.name.lowercased()

        if let program = programFromName(name) {
            return program
        }

        // Check abbreviation
        let abbrev = (part.abbreviation ?? "").lowercased()
        if let program = programFromName(abbrev) {
            return program
        }

        // Check MIDI instrument in score-part if available
        // For now, default to acoustic grand piano
        return GeneralMIDI.acousticGrandPiano.rawValue
    }

    /// Gets the MIDI channel for a part.
    /// - Parameters:
    ///   - part: The part.
    ///   - partIndex: The index of the part in the score.
    /// - Returns: MIDI channel (0-15).
    public func midiChannel(for part: Part, partIndex: Int) -> UInt8 {
        let name = part.name.lowercased()

        // Percussion uses channel 10 (index 9)
        if isPercussion(name) {
            return 9
        }

        // Avoid channel 10 for melodic instruments
        var channel = UInt8(partIndex % 16)
        if channel == 9 {
            channel = 10  // Skip to next available
        }

        return channel
    }

    /// Gets the transposition for a part (in semitones).
    /// - Parameter part: The part.
    /// - Returns: Transposition in semitones (positive = sounds higher than written).
    public func transposition(for part: Part) -> Int {
        let name = part.name.lowercased()

        // Common transposing instruments
        if name.contains("b♭") || name.contains("bb") || name.contains("b-flat") {
            if name.contains("clarinet") || name.contains("trumpet") || name.contains("soprano sax") {
                return -2  // Sounds a major 2nd lower
            }
            if name.contains("tenor sax") {
                return -14  // Sounds a major 9th lower
            }
        }

        if name.contains("e♭") || name.contains("eb") || name.contains("e-flat") {
            if name.contains("alto sax") || name.contains("baritone sax") {
                return -9  // Sounds a major 6th lower (alto)
            }
            if name.contains("clarinet") {
                return 3   // Sounds a minor 3rd higher
            }
        }

        if name.contains("french horn") || name.contains("horn in f") {
            return -7  // Sounds a perfect 5th lower
        }

        if name.contains("piccolo") {
            return 12  // Sounds an octave higher
        }

        if name.contains("contrabass") || name.contains("double bass") || name.contains("bass guitar") {
            return -12  // Sounds an octave lower
        }

        if name.contains("guitar") && !name.contains("bass") {
            return -12  // Guitar sounds an octave lower than written
        }

        if name.contains("glockenspiel") {
            return 24  // Sounds two octaves higher
        }

        if name.contains("xylophone") {
            return 12  // Sounds an octave higher
        }

        if name.contains("celesta") {
            return 12  // Sounds an octave higher
        }

        return 0  // Concert pitch
    }

    // MARK: - Percussion MIDI Mapping

    /// Gets the MIDI note number for an unpitched (percussion) note.
    ///
    /// - Parameters:
    ///   - unpitched: The unpitched note.
    ///   - part: The part containing the note.
    /// - Returns: MIDI note number (35-81 for GM percussion), or 60 as fallback.
    public func midiNoteNumber(for unpitched: UnpitchedNote, in part: Part) -> UInt8 {
        // 1. Try resolved percussion instrument
        if let instrument = unpitched.percussionInstrument,
           let midiNote = instrument.midiNote {
            return midiNote
        }

        // 2. Look up from part's percussion map
        if let map = part.effectivePercussionMap,
           let midiNote = map.midiNote(at: unpitched.displayStep, octave: unpitched.displayOctave) {
            return midiNote
        }

        // 3. Fall back to display position -> MIDI mapping
        // Use standard drum kit positions
        return midiNoteFromDisplayPosition(step: unpitched.displayStep, octave: unpitched.displayOctave)
    }

    /// Converts a display position to a MIDI note using standard drum kit conventions.
    private func midiNoteFromDisplayPosition(step: PitchStep, octave: Int) -> UInt8 {
        // Standard drum kit mapping based on staff position
        // These correspond to common drum notation practices
        switch (step, octave) {
        // Below staff
        case (.d, 4):
            return GeneralMIDIPercussion.pedalHiHat.rawValue
        case (.e, 4):
            return GeneralMIDIPercussion.acousticBassDrum.rawValue
        case (.f, 4):
            return GeneralMIDIPercussion.bassDrum1.rawValue

        // Lower staff
        case (.g, 4):
            return GeneralMIDIPercussion.lowFloorTom.rawValue
        case (.a, 4):
            return GeneralMIDIPercussion.highFloorTom.rawValue
        case (.b, 4):
            return GeneralMIDIPercussion.lowTom.rawValue

        // Middle staff
        case (.c, 5):
            return GeneralMIDIPercussion.acousticSnare.rawValue
        case (.d, 5):
            return GeneralMIDIPercussion.lowMidTom.rawValue
        case (.e, 5):
            return GeneralMIDIPercussion.highTom.rawValue

        // Upper staff
        case (.f, 5):
            return GeneralMIDIPercussion.rideCymbal1.rawValue
        case (.g, 5):
            return GeneralMIDIPercussion.closedHiHat.rawValue
        case (.a, 5):
            return GeneralMIDIPercussion.crashCymbal1.rawValue
        case (.b, 5):
            return GeneralMIDIPercussion.cowbell.rawValue

        // Above staff
        case (.c, 6):
            return GeneralMIDIPercussion.tambourine.rawValue

        default:
            // Default to snare drum
            return GeneralMIDIPercussion.acousticSnare.rawValue
        }
    }

    /// Checks if a part is a percussion part.
    ///
    /// - Parameter part: The part to check.
    /// - Returns: True if the part is a percussion part.
    public func isPercussionPart(_ part: Part) -> Bool {
        return part.isPercussion || isPercussion(part.name.lowercased())
    }

    // MARK: - Private Methods

    private func programFromName(_ name: String) -> UInt8? {
        // Piano family
        if name.contains("piano") || name.contains("pno") {
            if name.contains("electric") || name.contains("elec") {
                return GeneralMIDI.electricPiano1.rawValue
            }
            return GeneralMIDI.acousticGrandPiano.rawValue
        }

        // Chromatic percussion
        if name.contains("celesta") || name.contains("celeste") {
            return GeneralMIDI.celesta.rawValue
        }
        if name.contains("glockenspiel") || name.contains("glock") {
            return GeneralMIDI.glockenspiel.rawValue
        }
        if name.contains("music box") {
            return GeneralMIDI.musicBox.rawValue
        }
        if name.contains("vibraphone") || name.contains("vibes") {
            return GeneralMIDI.vibraphone.rawValue
        }
        if name.contains("marimba") {
            return GeneralMIDI.marimba.rawValue
        }
        if name.contains("xylophone") || name.contains("xylo") {
            return GeneralMIDI.xylophone.rawValue
        }
        if name.contains("tubular") || name.contains("chimes") {
            return GeneralMIDI.tubularBells.rawValue
        }

        // Organ
        if name.contains("organ") {
            if name.contains("church") || name.contains("pipe") {
                return GeneralMIDI.churchOrgan.rawValue
            }
            return GeneralMIDI.drawbarOrgan.rawValue
        }
        if name.contains("accordion") {
            return GeneralMIDI.accordion.rawValue
        }
        if name.contains("harmonica") {
            return GeneralMIDI.harmonica.rawValue
        }

        // Guitar
        if name.contains("guitar") || name.contains("gtr") {
            if name.contains("electric") || name.contains("elec") {
                if name.contains("distort") || name.contains("overdrive") {
                    return GeneralMIDI.distortionGuitar.rawValue
                }
                return GeneralMIDI.electricGuitarClean.rawValue
            }
            if name.contains("nylon") || name.contains("classical") {
                return GeneralMIDI.acousticGuitarNylon.rawValue
            }
            return GeneralMIDI.acousticGuitarSteel.rawValue
        }

        // Bass
        if name.contains("bass") && !name.contains("bassoon") {
            if name.contains("electric") || name.contains("elec") {
                return GeneralMIDI.electricBassFinger.rawValue
            }
            if name.contains("synth") {
                return GeneralMIDI.synthBass1.rawValue
            }
            return GeneralMIDI.acousticBass.rawValue
        }

        // Strings
        if name.contains("violin") || name.contains("vln") || name.contains("vn") {
            return GeneralMIDI.violin.rawValue
        }
        if name.contains("viola") || name.contains("vla") || name.contains("va") {
            return GeneralMIDI.viola.rawValue
        }
        if name.contains("cello") || name.contains("violoncello") || name.contains("vc") {
            return GeneralMIDI.cello.rawValue
        }
        if name.contains("contrabass") || name.contains("double bass") || name.contains("cb") {
            return GeneralMIDI.contrabass.rawValue
        }
        if name.contains("harp") {
            return GeneralMIDI.orchestralHarp.rawValue
        }
        if name.contains("string") && (name.contains("ensemble") || name.contains("section")) {
            return GeneralMIDI.stringEnsemble1.rawValue
        }

        // Brass
        if name.contains("trumpet") || name.contains("tpt") || name.contains("trp") {
            if name.contains("muted") {
                return GeneralMIDI.mutedTrumpet.rawValue
            }
            return GeneralMIDI.trumpet.rawValue
        }
        if name.contains("trombone") || name.contains("tbn") || name.contains("trb") {
            return GeneralMIDI.trombone.rawValue
        }
        if name.contains("french horn") || name.contains("horn") {
            return GeneralMIDI.frenchHorn.rawValue
        }
        if name.contains("tuba") {
            return GeneralMIDI.tuba.rawValue
        }
        if name.contains("brass") && name.contains("section") {
            return GeneralMIDI.brassSection.rawValue
        }

        // Woodwinds
        if name.contains("flute") || name.contains("fl") {
            if name.contains("pan") {
                return GeneralMIDI.panFlute.rawValue
            }
            return GeneralMIDI.flute.rawValue
        }
        if name.contains("piccolo") || name.contains("picc") {
            return GeneralMIDI.piccolo.rawValue
        }
        if name.contains("oboe") || name.contains("ob") {
            return GeneralMIDI.oboe.rawValue
        }
        if name.contains("english horn") || name.contains("cor anglais") {
            return GeneralMIDI.englishHorn.rawValue
        }
        if name.contains("clarinet") || name.contains("cl") {
            return GeneralMIDI.clarinet.rawValue
        }
        if name.contains("bassoon") || name.contains("bsn") || name.contains("fg") {
            return GeneralMIDI.bassoon.rawValue
        }
        if name.contains("recorder") {
            return GeneralMIDI.recorder.rawValue
        }

        // Saxophones
        if name.contains("saxophone") || name.contains("sax") {
            if name.contains("soprano") {
                return GeneralMIDI.sopranoSax.rawValue
            }
            if name.contains("alto") {
                return GeneralMIDI.altoSax.rawValue
            }
            if name.contains("tenor") {
                return GeneralMIDI.tenorSax.rawValue
            }
            if name.contains("baritone") || name.contains("bari") {
                return GeneralMIDI.baritoneSax.rawValue
            }
            return GeneralMIDI.altoSax.rawValue  // Default to alto
        }

        // Choir/Voice
        if name.contains("soprano") && !name.contains("sax") {
            return GeneralMIDI.choirAahs.rawValue
        }
        if name.contains("alto") && !name.contains("sax") {
            return GeneralMIDI.choirAahs.rawValue
        }
        if name.contains("tenor") && !name.contains("sax") {
            return GeneralMIDI.choirAahs.rawValue
        }
        if name.contains("baritone") && !name.contains("sax") {
            return GeneralMIDI.choirAahs.rawValue
        }
        if name.contains("choir") || name.contains("voice") || name.contains("vocal") {
            return GeneralMIDI.choirAahs.rawValue
        }

        // Timpani
        if name.contains("timpani") || name.contains("timp") || name.contains("kettledrum") {
            return GeneralMIDI.timpani.rawValue
        }

        return nil
    }

    private func isPercussion(_ name: String) -> Bool {
        let percussionNames = [
            "percussion", "drum", "drums", "snare", "bass drum", "cymbal",
            "triangle", "tambourine", "wood block", "temple block",
            "claves", "castanets", "maracas", "cabasa", "guiro",
            "bongo", "conga", "timbale", "cowbell", "agogo",
            "hi-hat", "ride", "crash", "tom", "kit"
        ]

        for percName in percussionNames {
            if name.contains(percName) {
                return true
            }
        }

        return false
    }
}

// MARK: - General MIDI Program Numbers

/// General MIDI instrument program numbers.
public enum GeneralMIDI: UInt8, Sendable {

    // Piano (0-7)
    case acousticGrandPiano = 0
    case brightAcousticPiano = 1
    case electricGrandPiano = 2
    case honkyTonkPiano = 3
    case electricPiano1 = 4
    case electricPiano2 = 5
    case harpsichord = 6
    case clavinet = 7

    // Chromatic Percussion (8-15)
    case celesta = 8
    case glockenspiel = 9
    case musicBox = 10
    case vibraphone = 11
    case marimba = 12
    case xylophone = 13
    case tubularBells = 14
    case dulcimer = 15

    // Organ (16-23)
    case drawbarOrgan = 16
    case percussiveOrgan = 17
    case rockOrgan = 18
    case churchOrgan = 19
    case reedOrgan = 20
    case accordion = 21
    case harmonica = 22
    case tangoAccordion = 23

    // Guitar (24-31)
    case acousticGuitarNylon = 24
    case acousticGuitarSteel = 25
    case electricGuitarJazz = 26
    case electricGuitarClean = 27
    case electricGuitarMuted = 28
    case overdrivenGuitar = 29
    case distortionGuitar = 30
    case guitarHarmonics = 31

    // Bass (32-39)
    case acousticBass = 32
    case electricBassFinger = 33
    case electricBassPick = 34
    case fretlessBass = 35
    case slapBass1 = 36
    case slapBass2 = 37
    case synthBass1 = 38
    case synthBass2 = 39

    // Strings (40-47)
    case violin = 40
    case viola = 41
    case cello = 42
    case contrabass = 43
    case tremoloStrings = 44
    case pizzicatoStrings = 45
    case orchestralHarp = 46
    case timpani = 47

    // Ensemble (48-55)
    case stringEnsemble1 = 48
    case stringEnsemble2 = 49
    case synthStrings1 = 50
    case synthStrings2 = 51
    case choirAahs = 52
    case voiceOohs = 53
    case synthVoice = 54
    case orchestraHit = 55

    // Brass (56-63)
    case trumpet = 56
    case trombone = 57
    case tuba = 58
    case mutedTrumpet = 59
    case frenchHorn = 60
    case brassSection = 61
    case synthBrass1 = 62
    case synthBrass2 = 63

    // Reed (64-71)
    case sopranoSax = 64
    case altoSax = 65
    case tenorSax = 66
    case baritoneSax = 67
    case oboe = 68
    case englishHorn = 69
    case bassoon = 70
    case clarinet = 71

    // Pipe (72-79)
    case piccolo = 72
    case flute = 73
    case recorder = 74
    case panFlute = 75
    case blownBottle = 76
    case shakuhachi = 77
    case whistle = 78
    case ocarina = 79

    // Synth Lead (80-87)
    case lead1Square = 80
    case lead2Sawtooth = 81
    case lead3Calliope = 82
    case lead4Chiff = 83
    case lead5Charang = 84
    case lead6Voice = 85
    case lead7Fifths = 86
    case lead8BassLead = 87

    // Synth Pad (88-95)
    case pad1NewAge = 88
    case pad2Warm = 89
    case pad3Polysynth = 90
    case pad4Choir = 91
    case pad5Bowed = 92
    case pad6Metallic = 93
    case pad7Halo = 94
    case pad8Sweep = 95

    // Synth Effects (96-103)
    case fx1Rain = 96
    case fx2Soundtrack = 97
    case fx3Crystal = 98
    case fx4Atmosphere = 99
    case fx5Brightness = 100
    case fx6Goblins = 101
    case fx7Echoes = 102
    case fx8SciFi = 103

    // Ethnic (104-111)
    case sitar = 104
    case banjo = 105
    case shamisen = 106
    case koto = 107
    case kalimba = 108
    case bagpipe = 109
    case fiddle = 110
    case shanai = 111

    // Percussive (112-119)
    case tinkleBell = 112
    case agogo = 113
    case steelDrums = 114
    case woodblock = 115
    case taikoDrum = 116
    case melodicTom = 117
    case synthDrum = 118
    case reverseCymbal = 119

    // Sound Effects (120-127)
    case guitarFretNoise = 120
    case breathNoise = 121
    case seashore = 122
    case birdTweet = 123
    case telephoneRing = 124
    case helicopter = 125
    case applause = 126
    case gunshot = 127
}

// MARK: - General MIDI Percussion

/// General MIDI percussion note numbers (channel 10).
public enum GeneralMIDIPercussion: UInt8, Sendable {
    case acousticBassDrum = 35
    case bassDrum1 = 36
    case sideStick = 37
    case acousticSnare = 38
    case handClap = 39
    case electricSnare = 40
    case lowFloorTom = 41
    case closedHiHat = 42
    case highFloorTom = 43
    case pedalHiHat = 44
    case lowTom = 45
    case openHiHat = 46
    case lowMidTom = 47
    case hiMidTom = 48
    case crashCymbal1 = 49
    case highTom = 50
    case rideCymbal1 = 51
    case chineseCymbal = 52
    case rideBell = 53
    case tambourine = 54
    case splashCymbal = 55
    case cowbell = 56
    case crashCymbal2 = 57
    case vibraslap = 58
    case rideCymbal2 = 59
    case hiBongo = 60
    case lowBongo = 61
    case muteHiConga = 62
    case openHiConga = 63
    case lowConga = 64
    case highTimbale = 65
    case lowTimbale = 66
    case highAgogo = 67
    case lowAgogo = 68
    case cabasa = 69
    case maracas = 70
    case shortWhistle = 71
    case longWhistle = 72
    case shortGuiro = 73
    case longGuiro = 74
    case claves = 75
    case hiWoodBlock = 76
    case lowWoodBlock = 77
    case muteCuica = 78
    case openCuica = 79
    case muteTriangle = 80
    case openTriangle = 81
}
