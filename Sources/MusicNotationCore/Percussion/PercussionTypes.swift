import Foundation

// MARK: - Beater Types

/// The type of beater used for percussion instruments.
///
/// Based on MusicXML beater element values.
public enum BeaterType: String, Codable, Sendable, CaseIterable {
    case bow
    case chimeHammer = "chime hammer"
    case coin
    case drumStick = "drum stick"
    case finger
    case fingernail
    case fist
    case guiroScraper = "guiro scraper"
    case hammer
    case hand
    case jazzStick = "jazz stick"
    case knittingNeedle = "knitting needle"
    case metalHammer = "metal hammer"
    case snareStick = "snare stick"
    case spoonMallet = "spoon mallet"
    case superball
    case triangleBeater = "triangle beater"
    case triangleBeaterPlain = "triangle beater plain"
    case wireBrush = "wire brush"

    /// Creates a BeaterType from a MusicXML string value.
    public init?(musicXMLValue: String) {
        if let type = BeaterType(rawValue: musicXMLValue) {
            self = type
        } else {
            // Try matching with dashes converted to spaces
            let normalized = musicXMLValue.replacingOccurrences(of: "-", with: " ")
            if let type = BeaterType(rawValue: normalized) {
                self = type
            } else {
                return nil
            }
        }
    }

    /// The MusicXML string value for this beater type.
    public var musicXMLValue: String {
        rawValue.replacingOccurrences(of: " ", with: "-")
    }
}

// MARK: - Stick Types

/// The material of a percussion stick/mallet.
///
/// Based on MusicXML stick-material element values.
public enum StickMaterial: String, Codable, Sendable, CaseIterable {
    case soft
    case medium
    case hard
    case shaded
    case x
}

/// The type of percussion stick/mallet.
///
/// Based on MusicXML stick-type element values.
public enum StickType: String, Codable, Sendable, CaseIterable {
    case bassDrum = "bass drum"
    case doubleBassDrum = "double bass drum"
    case glockenspiel
    case gum
    case hammer
    case superball
    case timpani
    case xylophone
    case yarn

    /// Creates a StickType from a MusicXML string value.
    public init?(musicXMLValue: String) {
        if let type = StickType(rawValue: musicXMLValue) {
            self = type
        } else {
            let normalized = musicXMLValue.replacingOccurrences(of: "-", with: " ")
            if let type = StickType(rawValue: normalized) {
                self = type
            } else {
                return nil
            }
        }
    }

    /// The MusicXML string value for this stick type.
    public var musicXMLValue: String {
        rawValue.replacingOccurrences(of: " ", with: "-")
    }
}

/// The location where a stick strikes.
public enum StickLocation: String, Codable, Sendable, CaseIterable {
    case center
    case rim
    case cymbalBell = "cymbal bell"
    case cymbalEdge = "cymbal edge"
}

// MARK: - Membrane Instruments

/// Membrane percussion instruments (drums with skin heads).
///
/// Based on MusicXML membrane element values.
public enum MembraneType: String, Codable, Sendable, CaseIterable {
    case bassDrum = "bass drum"
    case bassDrumOnSide = "bass drum on side"
    case bongo
    case chineseTomtom = "Chinese tomtom"
    case conga
    case cuica
    case gobletDrum = "goblet drum"
    case indoAmericanTomtom = "Indo-American tomtom"
    case japaneseTomtom = "Japanese tomtom"
    case kazoo
    case kettledrum
    case lionRoar = "lion roar"
    case militaryDrum = "military drum"
    case snareDrum = "snare drum"
    case snareDrumSnaresOff = "snare drum snares off"
    case tabla
    case tambourine
    case tenorDrum = "tenor drum"
    case timbales
    case tomtom

    /// Creates a MembraneType from a MusicXML string value.
    public init?(musicXMLValue: String) {
        if let type = MembraneType(rawValue: musicXMLValue) {
            self = type
        } else {
            let normalized = musicXMLValue.replacingOccurrences(of: "-", with: " ")
            if let type = MembraneType(rawValue: normalized) {
                self = type
            } else {
                return nil
            }
        }
    }

    /// The MusicXML string value for this membrane type.
    public var musicXMLValue: String {
        rawValue.replacingOccurrences(of: " ", with: "-")
    }
}

// MARK: - Metal Instruments

/// Metal percussion instruments.
///
/// Based on MusicXML metal element values.
public enum MetalType: String, Codable, Sendable, CaseIterable {
    case agogo
    case almglocken
    case bell
    case bellPlate = "bell plate"
    case bellTree = "bell tree"
    case brakeDrum = "brake drum"
    case cencerro
    case chainRattle = "chain rattle"
    case chineseCymbal = "Chinese cymbal"
    case cowbell
    case crashCymbals = "crash cymbals"
    case crotale
    case cymbalTongs = "cymbal tongs"
    case domedGong = "domed gong"
    case fingerCymbals = "finger cymbals"
    case flexatone
    case gong
    case handbell
    case hiHat = "hi-hat"
    case highHatCymbals = "high-hat cymbals"
    case jawHarp = "jaw harp"
    case jingleBells = "jingle bells"
    case musicalSaw = "musical saw"
    case shellBells = "shell bells"
    case sistrum
    case sizzleCymbal = "sizzle cymbal"
    case sleighBells = "sleigh bells"
    case suspendedCymbal = "suspended cymbal"
    case tamTam = "tam tam"
    case triangleInstrument = "triangle"
    case vietnameseHat = "Vietnamese hat"

    /// Creates a MetalType from a MusicXML string value.
    public init?(musicXMLValue: String) {
        if let type = MetalType(rawValue: musicXMLValue) {
            self = type
        } else {
            let normalized = musicXMLValue.replacingOccurrences(of: "-", with: " ")
            if let type = MetalType(rawValue: normalized) {
                self = type
            } else {
                return nil
            }
        }
    }

    /// The MusicXML string value for this metal type.
    public var musicXMLValue: String {
        rawValue.replacingOccurrences(of: " ", with: "-")
    }
}

// MARK: - Wood Instruments

/// Wood/wooden percussion instruments.
///
/// Based on MusicXML wood element values.
public enum WoodType: String, Codable, Sendable, CaseIterable {
    case bambooScraper = "bamboo scraper"
    case boardClapper = "board clapper"
    case cabasa
    case castanets
    case castanetsWithHandle = "castanets with handle"
    case claves
    case footballRattle = "football rattle"
    case guiro
    case logDrum = "log drum"
    case maraca
    case maracas
    case quijada
    case rainstick
    case ratchet
    case recoReco = "reco-reco"
    case sandpaperBlocks = "sandpaper blocks"
    case slitDrum = "slit drum"
    case templeBlock = "temple block"
    case vibraslap
    case whip
    case woodBlock = "wood block"

    /// Creates a WoodType from a MusicXML string value.
    public init?(musicXMLValue: String) {
        if let type = WoodType(rawValue: musicXMLValue) {
            self = type
        } else {
            let normalized = musicXMLValue.replacingOccurrences(of: "-", with: " ")
            if let type = WoodType(rawValue: normalized) {
                self = type
            } else {
                return nil
            }
        }
    }

    /// The MusicXML string value for this wood type.
    public var musicXMLValue: String {
        rawValue.replacingOccurrences(of: " ", with: "-")
    }
}

// MARK: - Pitched Percussion

/// Pitched percussion instruments.
///
/// Based on MusicXML pitched element values.
public enum PitchedPercussionType: String, Codable, Sendable, CaseIterable {
    case celesta
    case chimes
    case glockenspiel
    case lithophone
    case mallet
    case marimba
    case steelDrums = "steel drums"
    case tubaphone
    case tubularChimes = "tubular chimes"
    case vibraphone
    case xylophone
}

// MARK: - Glass Instruments

/// Glass percussion instruments.
///
/// Based on MusicXML glass element values.
public enum GlassType: String, Codable, Sendable, CaseIterable {
    case glassHarmonica = "glass harmonica"
    case glassHarp = "glass harp"
    case windChimes = "wind chimes"

    /// Creates a GlassType from a MusicXML string value.
    public init?(musicXMLValue: String) {
        if let type = GlassType(rawValue: musicXMLValue) {
            self = type
        } else {
            let normalized = musicXMLValue.replacingOccurrences(of: "-", with: " ")
            if let type = GlassType(rawValue: normalized) {
                self = type
            } else {
                return nil
            }
        }
    }

    /// The MusicXML string value for this glass type.
    public var musicXMLValue: String {
        rawValue.replacingOccurrences(of: " ", with: "-")
    }
}

// MARK: - Effect Instruments

/// General percussion effect instruments.
///
/// Based on MusicXML effect element values.
public enum PercussionEffect: String, Codable, Sendable, CaseIterable {
    case anvil
    case bellTree = "bell tree"
    case birdWhistle = "bird whistle"
    case cannon
    case duckCall = "duck call"
    case gunShot = "gun shot"
    case klaxonHorn = "klaxon horn"
    case lionsRoar = "lions roar"
    case lotusFlute = "lotus flute"
    case megaphone
    case policeWhistle = "police whistle"
    case siren
    case sirenWhistle = "siren whistle"
    case slideWhistle = "slide whistle"
    case thunderSheet = "thunder sheet"
    case windMachine = "wind machine"
    case windWhistle = "wind whistle"

    /// Creates a PercussionEffect from a MusicXML string value.
    public init?(musicXMLValue: String) {
        if let type = PercussionEffect(rawValue: musicXMLValue) {
            self = type
        } else {
            let normalized = musicXMLValue.replacingOccurrences(of: "-", with: " ")
            if let type = PercussionEffect(rawValue: normalized) {
                self = type
            } else {
                return nil
            }
        }
    }

    /// The MusicXML string value for this effect type.
    public var musicXMLValue: String {
        rawValue.replacingOccurrences(of: " ", with: "-")
    }
}

// MARK: - Timpani

/// Timpani tuning information.
public struct TimpaniTuning: Codable, Sendable, Equatable {
    /// The pitch step.
    public var step: PitchStep

    /// The chromatic alteration (-2 to +2).
    public var alter: Double?

    /// The octave (typically 2-4 for timpani).
    public var octave: Int?

    public init(step: PitchStep, alter: Double? = nil, octave: Int? = nil) {
        self.step = step
        self.alter = alter
        self.octave = octave
    }
}

// MARK: - Stick Specification

/// Complete specification for a percussion stick/beater.
public struct StickSpecification: Codable, Sendable, Equatable {
    /// The stick material.
    public var material: StickMaterial?

    /// The stick type.
    public var type: StickType?

    /// The tip orientation (up, down, left, right, etc.).
    public var tip: TipDirection?

    public init(material: StickMaterial? = nil, type: StickType? = nil, tip: TipDirection? = nil) {
        self.material = material
        self.type = type
        self.tip = tip
    }
}

/// The direction/orientation of a stick tip.
public enum TipDirection: String, Codable, Sendable, CaseIterable {
    case up
    case down
    case left
    case right
    case northwest
    case northeast
    case southeast
    case southwest
}
