import Foundation

/// A percussion instrument with its standard properties.
///
/// This enum represents common percussion instruments used in drum kit and orchestral
/// percussion notation. Each instrument has associated MIDI mapping, default notehead
/// style, and standard staff position.
public enum PercussionInstrument: String, Codable, Sendable, CaseIterable {

    // MARK: - Drum Kit - Drums

    /// Acoustic bass drum (kick drum)
    case acousticBassDrum

    /// Electric/standard bass drum
    case bassDrum

    /// Acoustic snare drum
    case acousticSnare

    /// Snare drum (general)
    case snareDrum

    /// Electric snare
    case electricSnare

    /// Side stick (rim click)
    case sideStick

    /// Low floor tom
    case lowFloorTom

    /// High floor tom
    case highFloorTom

    /// Floor tom (general)
    case floorTom

    /// Low tom
    case lowTom

    /// Low-mid tom
    case lowMidTom

    /// High-mid tom
    case highMidTom

    /// Mid tom (general)
    case midTom

    /// High tom
    case highTom

    // MARK: - Drum Kit - Cymbals

    /// Closed hi-hat
    case hiHatClosed

    /// Pedal hi-hat
    case hiHatPedal

    /// Open hi-hat
    case hiHatOpen

    /// Ride cymbal
    case rideCymbal

    /// Ride cymbal bell
    case rideBell

    /// Crash cymbal 1
    case crashCymbal1

    /// Crash cymbal 2
    case crashCymbal2

    /// Crash cymbal (general)
    case crashCymbal

    /// Splash cymbal
    case splashCymbal

    /// China cymbal
    case chinaCymbal

    // MARK: - Latin Percussion

    /// Cowbell
    case cowbell

    /// High bongo
    case highBongo

    /// Low bongo
    case lowBongo

    /// Bongo (general)
    case bongo

    /// Mute high conga
    case muteHighConga

    /// Open high conga
    case openHighConga

    /// Low conga
    case lowConga

    /// Conga (general)
    case conga

    /// High timbale
    case highTimbale

    /// Low timbale
    case lowTimbale

    /// Timbales (general)
    case timbales

    /// High agogo
    case highAgogo

    /// Low agogo
    case lowAgogo

    /// Cabasa
    case cabasa

    /// Maracas
    case maracas

    /// Short whistle
    case shortWhistle

    /// Long whistle
    case longWhistle

    /// Short guiro
    case shortGuiro

    /// Long guiro
    case longGuiro

    /// Guiro (general)
    case guiro

    /// Claves
    case claves

    /// High wood block
    case highWoodBlock

    /// Low wood block
    case lowWoodBlock

    /// Wood block (general)
    case woodblock

    /// Mute cuica
    case muteCuica

    /// Open cuica
    case openCuica

    /// Cuica (general)
    case cuica

    /// Mute triangle
    case muteTriangle

    /// Open triangle
    case openTriangle

    /// Triangle (general)
    case triangle

    /// Tambourine
    case tambourine

    /// Shaker
    case shaker

    /// Vibraslap
    case vibraslap

    // MARK: - Orchestral Percussion

    /// Timpani
    case timpani

    /// Orchestral bass drum
    case orchestralBassDrum

    /// Concert snare drum
    case concertSnare

    /// Suspended cymbal
    case suspendedCymbal

    /// Tam-tam (gong)
    case tamTam

    /// Gong
    case gong

    /// Chimes (tubular bells)
    case chimes

    /// Xylophone
    case xylophone

    /// Marimba
    case marimba

    /// Vibraphone
    case vibraphone

    /// Glockenspiel
    case glockenspiel

    /// Crotales
    case crotales

    /// Bell tree
    case bellTree

    /// Mark tree (wind chimes)
    case markTree

    /// Castanets
    case castanets

    /// Finger cymbals
    case fingerCymbals

    /// Sleigh bells
    case sleighBells

    // MARK: - Properties

    /// The General MIDI percussion note number for this instrument.
    ///
    /// Based on the General MIDI Level 1 percussion map (channel 10).
    /// Returns nil for instruments not in the standard GM map.
    public var midiNote: UInt8? {
        switch self {
        // Bass drums (35-36)
        case .acousticBassDrum: return 35
        case .bassDrum: return 36

        // Snares and rim (37-40)
        case .sideStick: return 37
        case .acousticSnare: return 38
        case .snareDrum: return 38
        case .electricSnare: return 40

        // Toms (41-48, 50)
        case .lowFloorTom: return 41
        case .highFloorTom: return 43
        case .floorTom: return 43
        case .lowTom: return 45
        case .lowMidTom: return 47
        case .midTom: return 47
        case .highMidTom: return 48
        case .highTom: return 50

        // Hi-hats (42, 44, 46)
        case .hiHatClosed: return 42
        case .hiHatPedal: return 44
        case .hiHatOpen: return 46

        // Cymbals (49, 51-53, 55, 57)
        case .crashCymbal1: return 49
        case .crashCymbal: return 49
        case .rideCymbal: return 51
        case .chinaCymbal: return 52
        case .rideBell: return 53
        case .splashCymbal: return 55
        case .crashCymbal2: return 57

        // Latin - Tambourine/Cowbell (54, 56)
        case .tambourine: return 54
        case .cowbell: return 56

        // Latin - Bongos (60-61)
        case .highBongo: return 60
        case .lowBongo: return 61
        case .bongo: return 60

        // Latin - Congas (62-64)
        case .muteHighConga: return 62
        case .openHighConga: return 63
        case .lowConga: return 64
        case .conga: return 63

        // Latin - Timbales (65-66)
        case .highTimbale: return 65
        case .lowTimbale: return 66
        case .timbales: return 65

        // Latin - Agogo (67-68)
        case .highAgogo: return 67
        case .lowAgogo: return 68

        // Latin - Other (69-82)
        case .cabasa: return 69
        case .maracas: return 70
        case .shortWhistle: return 71
        case .longWhistle: return 72
        case .shortGuiro: return 73
        case .longGuiro: return 74
        case .guiro: return 74
        case .claves: return 75
        case .highWoodBlock: return 76
        case .lowWoodBlock: return 77
        case .woodblock: return 76
        case .muteCuica: return 78
        case .openCuica: return 79
        case .cuica: return 79
        case .muteTriangle: return 80
        case .openTriangle: return 81
        case .triangle: return 81

        case .shaker: return 82
        case .vibraslap: return 58

        // Orchestral - no standard GM mapping
        case .timpani: return nil
        case .orchestralBassDrum: return 36
        case .concertSnare: return 38
        case .suspendedCymbal: return 49
        case .tamTam: return nil
        case .gong: return nil
        case .chimes: return nil
        case .xylophone: return nil
        case .marimba: return nil
        case .vibraphone: return nil
        case .glockenspiel: return nil
        case .crotales: return nil
        case .bellTree: return nil
        case .markTree: return nil
        case .castanets: return nil
        case .fingerCymbals: return nil
        case .sleighBells: return 83
        }
    }

    /// The default notehead style for this instrument.
    public var defaultNotehead: PercussionNotehead {
        switch self {
        // Cymbals use X noteheads
        case .hiHatClosed, .hiHatPedal, .rideCymbal, .rideBell,
             .crashCymbal1, .crashCymbal2, .crashCymbal, .splashCymbal,
             .chinaCymbal, .suspendedCymbal:
            return .x

        // Open hi-hat uses circle-X
        case .hiHatOpen:
            return .circleX

        // Triangle uses triangle notehead
        case .triangle, .muteTriangle, .openTriangle:
            return .triangle

        // Cowbell and ride bell use diamond
        case .cowbell:
            return .diamond

        // Side stick uses plus (cross)
        case .sideStick:
            return .plus

        // Most drums use normal noteheads
        default:
            return .normal
        }
    }

    /// The default staff position for this instrument in a standard drum kit.
    ///
    /// Returns a staff position where 0 is the middle line (B4 in treble clef).
    /// Positive values go up, negative go down.
    public var defaultStaffPosition: Int? {
        switch self {
        // Bass drum - below staff
        case .acousticBassDrum, .bassDrum, .orchestralBassDrum:
            return -4  // F4

        // Snare - middle
        case .snareDrum, .acousticSnare, .electricSnare, .concertSnare:
            return 0   // C5

        // Side stick - same as snare
        case .sideStick:
            return 0   // C5

        // Hi-hat - top of staff
        case .hiHatClosed, .hiHatOpen, .hiHatPedal:
            return 4   // G5

        // Ride cymbal
        case .rideCymbal, .rideBell:
            return 3   // F5

        // Crash cymbal - above staff
        case .crashCymbal, .crashCymbal1, .crashCymbal2:
            return 5   // A5

        // Floor tom
        case .floorTom, .lowFloorTom, .highFloorTom:
            return -3  // A4

        // Low tom
        case .lowTom, .lowMidTom:
            return -1  // B4

        // Mid/High tom
        case .midTom, .highMidTom:
            return 1   // D5

        // High tom
        case .highTom:
            return 2   // E5

        // Other - no default position
        default:
            return nil
        }
    }

    /// A human-readable display name for the instrument.
    public var displayName: String {
        switch self {
        case .acousticBassDrum: return "Acoustic Bass Drum"
        case .bassDrum: return "Bass Drum"
        case .acousticSnare: return "Acoustic Snare"
        case .snareDrum: return "Snare Drum"
        case .electricSnare: return "Electric Snare"
        case .sideStick: return "Side Stick"
        case .lowFloorTom: return "Low Floor Tom"
        case .highFloorTom: return "High Floor Tom"
        case .floorTom: return "Floor Tom"
        case .lowTom: return "Low Tom"
        case .lowMidTom: return "Low-Mid Tom"
        case .highMidTom: return "High-Mid Tom"
        case .midTom: return "Mid Tom"
        case .highTom: return "High Tom"
        case .hiHatClosed: return "Closed Hi-Hat"
        case .hiHatPedal: return "Pedal Hi-Hat"
        case .hiHatOpen: return "Open Hi-Hat"
        case .rideCymbal: return "Ride Cymbal"
        case .rideBell: return "Ride Bell"
        case .crashCymbal1: return "Crash Cymbal 1"
        case .crashCymbal2: return "Crash Cymbal 2"
        case .crashCymbal: return "Crash Cymbal"
        case .splashCymbal: return "Splash Cymbal"
        case .chinaCymbal: return "China Cymbal"
        case .cowbell: return "Cowbell"
        case .highBongo: return "High Bongo"
        case .lowBongo: return "Low Bongo"
        case .bongo: return "Bongo"
        case .muteHighConga: return "Mute High Conga"
        case .openHighConga: return "Open High Conga"
        case .lowConga: return "Low Conga"
        case .conga: return "Conga"
        case .highTimbale: return "High Timbale"
        case .lowTimbale: return "Low Timbale"
        case .timbales: return "Timbales"
        case .highAgogo: return "High Agogo"
        case .lowAgogo: return "Low Agogo"
        case .cabasa: return "Cabasa"
        case .maracas: return "Maracas"
        case .shortWhistle: return "Short Whistle"
        case .longWhistle: return "Long Whistle"
        case .shortGuiro: return "Short Guiro"
        case .longGuiro: return "Long Guiro"
        case .guiro: return "Guiro"
        case .claves: return "Claves"
        case .highWoodBlock: return "High Wood Block"
        case .lowWoodBlock: return "Low Wood Block"
        case .woodblock: return "Wood Block"
        case .muteCuica: return "Mute Cuica"
        case .openCuica: return "Open Cuica"
        case .cuica: return "Cuica"
        case .muteTriangle: return "Mute Triangle"
        case .openTriangle: return "Open Triangle"
        case .triangle: return "Triangle"
        case .tambourine: return "Tambourine"
        case .shaker: return "Shaker"
        case .vibraslap: return "Vibraslap"
        case .timpani: return "Timpani"
        case .orchestralBassDrum: return "Orchestral Bass Drum"
        case .concertSnare: return "Concert Snare"
        case .suspendedCymbal: return "Suspended Cymbal"
        case .tamTam: return "Tam-Tam"
        case .gong: return "Gong"
        case .chimes: return "Chimes"
        case .xylophone: return "Xylophone"
        case .marimba: return "Marimba"
        case .vibraphone: return "Vibraphone"
        case .glockenspiel: return "Glockenspiel"
        case .crotales: return "Crotales"
        case .bellTree: return "Bell Tree"
        case .markTree: return "Mark Tree"
        case .castanets: return "Castanets"
        case .fingerCymbals: return "Finger Cymbals"
        case .sleighBells: return "Sleigh Bells"
        }
    }
}
