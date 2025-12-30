import Foundation
import SMuFLKit

/// Dynamic markings indicating volume/intensity.
public enum Dynamic: String, Codable, Sendable, CaseIterable {
    // Standard dynamics (quiet to loud)
    case pppppp
    case ppppp
    case pppp
    case ppp
    case pp
    case p
    case mp
    case mf
    case f
    case ff
    case fff
    case ffff
    case fffff
    case ffffff

    // Special dynamics
    case sf      // sforzando
    case sfp     // sforzando-piano
    case sfpp    // sforzando-pianissimo
    case fp      // forte-piano
    case rf      // rinforzando
    case rfz     // rinforzando with z
    case sfz     // sforzato
    case sffz    // sforzatissimo
    case fz      // forzando
    case n       // niente (nothing/silence)
    case pf      // piano-forte
    case sfzp    // sforzato-piano
}

// MARK: - SMuFL Glyph Mapping

extension Dynamic {
    /// The SMuFL glyph name for this dynamic.
    public var glyph: SMuFLGlyphName? {
        switch self {
        case .pppppp: return .dynamicPPPPPP
        case .ppppp: return .dynamicPPPPP
        case .pppp: return .dynamicPPPP
        case .ppp: return .dynamicPPP
        case .pp: return .dynamicPP
        case .p: return .dynamicPiano
        case .mp: return .dynamicMP
        case .mf: return .dynamicMF
        case .f: return .dynamicForte
        case .ff: return .dynamicFF
        case .fff: return .dynamicFFF
        case .ffff: return .dynamicFFFF
        case .fffff: return .dynamicFFFFF
        case .ffffff: return .dynamicFFFFFF
        case .sf: return .dynamicSforzando1
        case .sfp: return .dynamicSforzandoPiano
        case .sfpp: return .dynamicSforzandoPianissimo
        case .fp: return .dynamicFortePiano
        case .rf: return .dynamicRinforzando1
        case .rfz: return .dynamicRinforzando2
        case .sfz: return .dynamicSforzato
        case .sffz: return nil  // Use componentGlyphs for sffz
        case .fz: return .dynamicForzando
        case .n: return .dynamicNiente
        case .pf: return .dynamicPF
        case .sfzp: return .dynamicSforzatoFF
        }
    }

    /// Component glyphs for building the dynamic (alternative to combined glyph).
    public var componentGlyphs: [SMuFLGlyphName] {
        switch self {
        case .pppppp: return [.dynamicPiano, .dynamicPiano, .dynamicPiano, .dynamicPiano, .dynamicPiano, .dynamicPiano]
        case .ppppp: return [.dynamicPiano, .dynamicPiano, .dynamicPiano, .dynamicPiano, .dynamicPiano]
        case .pppp: return [.dynamicPiano, .dynamicPiano, .dynamicPiano, .dynamicPiano]
        case .ppp: return [.dynamicPiano, .dynamicPiano, .dynamicPiano]
        case .pp: return [.dynamicPiano, .dynamicPiano]
        case .p: return [.dynamicPiano]
        case .mp: return [.dynamicMezzo, .dynamicPiano]
        case .mf: return [.dynamicMezzo, .dynamicForte]
        case .f: return [.dynamicForte]
        case .ff: return [.dynamicForte, .dynamicForte]
        case .fff: return [.dynamicForte, .dynamicForte, .dynamicForte]
        case .ffff: return [.dynamicForte, .dynamicForte, .dynamicForte, .dynamicForte]
        case .fffff: return [.dynamicForte, .dynamicForte, .dynamicForte, .dynamicForte, .dynamicForte]
        case .ffffff: return [.dynamicForte, .dynamicForte, .dynamicForte, .dynamicForte, .dynamicForte, .dynamicForte]
        case .sf: return [.dynamicSforzando, .dynamicForte]
        case .sfp: return [.dynamicSforzando, .dynamicForte, .dynamicPiano]
        case .sfpp: return [.dynamicSforzando, .dynamicForte, .dynamicPiano, .dynamicPiano]
        case .fp: return [.dynamicForte, .dynamicPiano]
        case .rf: return [.dynamicRinforzando, .dynamicForte]
        case .rfz: return [.dynamicRinforzando, .dynamicForte, .dynamicZ]
        case .sfz: return [.dynamicSforzando, .dynamicForte, .dynamicZ]
        case .sffz: return [.dynamicSforzando, .dynamicForte, .dynamicForte, .dynamicZ]
        case .fz: return [.dynamicForte, .dynamicZ]
        case .n: return [.dynamicNiente]
        case .pf: return [.dynamicPiano, .dynamicForte]
        case .sfzp: return [.dynamicSforzando, .dynamicForte, .dynamicZ, .dynamicPiano]
        }
    }
}

// MARK: - Dynamic Properties

extension Dynamic {
    /// Approximate MIDI velocity for this dynamic (0-127).
    public var midiVelocity: Int {
        switch self {
        case .pppppp: return 8
        case .ppppp: return 16
        case .pppp: return 24
        case .ppp: return 32
        case .pp: return 40
        case .p: return 52
        case .mp: return 64
        case .mf: return 76
        case .f: return 88
        case .ff: return 100
        case .fff: return 112
        case .ffff: return 120
        case .fffff: return 124
        case .ffffff: return 127
        case .sf, .sfz, .fz: return 112
        case .sfp, .fp: return 100  // Initial attack
        case .sfpp: return 100
        case .rf, .rfz: return 100
        case .sffz: return 120
        case .n: return 0
        case .pf: return 52
        case .sfzp: return 112
        }
    }

    /// Whether this is an accent/attack dynamic (sfz, fp, etc.).
    public var isAccentDynamic: Bool {
        switch self {
        case .sf, .sfp, .sfpp, .fp, .rf, .rfz, .sfz, .sffz, .fz, .sfzp:
            return true
        default:
            return false
        }
    }

    /// Whether this is a standard graduated dynamic (p, mp, mf, f, etc.).
    public var isGraduatedDynamic: Bool {
        switch self {
        case .pppppp, .ppppp, .pppp, .ppp, .pp, .p, .mp, .mf, .f, .ff, .fff, .ffff, .fffff, .ffffff:
            return true
        default:
            return false
        }
    }

    /// Relative loudness level (0.0 = silence, 1.0 = maximum).
    public var relativeLoudness: Double {
        Double(midiVelocity) / 127.0
    }
}

// MARK: - Dynamic Display

/// A dynamic with display information.
public struct DynamicDisplay: Codable, Sendable {
    /// The dynamic type.
    public var dynamic: Dynamic

    /// Placement relative to the staff.
    public var placement: Placement?

    /// X offset from default position.
    public var defaultX: Double?

    /// Y offset from default position.
    public var defaultY: Double?

    /// Whether this is editorial.
    public var editorial: Bool

    public init(
        dynamic: Dynamic,
        placement: Placement? = nil,
        defaultX: Double? = nil,
        defaultY: Double? = nil,
        editorial: Bool = false
    ) {
        self.dynamic = dynamic
        self.placement = placement
        self.defaultX = defaultX
        self.defaultY = defaultY
        self.editorial = editorial
    }

    /// Default placement is below the staff.
    public var effectivePlacement: Placement {
        placement ?? .below
    }
}

// MARK: - MusicXML Mapping

extension Dynamic {
    /// Creates a Dynamic from a MusicXML element name.
    public init?(musicXMLName: String) {
        switch musicXMLName.lowercased() {
        case "pppppp": self = .pppppp
        case "ppppp": self = .ppppp
        case "pppp": self = .pppp
        case "ppp": self = .ppp
        case "pp": self = .pp
        case "p": self = .p
        case "mp": self = .mp
        case "mf": self = .mf
        case "f": self = .f
        case "ff": self = .ff
        case "fff": self = .fff
        case "ffff": self = .ffff
        case "fffff": self = .fffff
        case "ffffff": self = .ffffff
        case "sf": self = .sf
        case "sfp": self = .sfp
        case "sfpp": self = .sfpp
        case "fp": self = .fp
        case "rf": self = .rf
        case "rfz": self = .rfz
        case "sfz": self = .sfz
        case "sffz": self = .sffz
        case "fz": self = .fz
        case "n": self = .n
        case "pf": self = .pf
        case "sfzp": self = .sfzp
        default: return nil
        }
    }

    /// The MusicXML element name.
    public var musicXMLName: String {
        rawValue
    }
}

// MARK: - Dynamic Comparison

extension Dynamic: Comparable {
    /// Compares dynamics by loudness.
    public static func < (lhs: Dynamic, rhs: Dynamic) -> Bool {
        lhs.midiVelocity < rhs.midiVelocity
    }
}

