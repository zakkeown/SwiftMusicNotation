import Foundation
import SMuFLKit

/// Articulation markings that modify how a note is played.
public enum Articulation: String, Codable, Sendable, CaseIterable {
    // Standard articulations
    case accent
    case strongAccent  // marcato
    case staccato
    case tenuto
    case detachedLegato  // mezzo-staccato / portato
    case staccatissimo
    case spiccato

    // Stress marks
    case stress
    case unstress

    // Breath marks
    case breathMark
    case caesura

    // Bowing articulations
    case upBow
    case downBow

    // Harmonic marks
    case harmonic
    case openString

    // Thumb position
    case thumbPosition

    // Plucking
    case pluck
    case doubleTongue
    case tripleTongue
    case stopped
    case snapPizzicato  // Bartók pizzicato

    // Organ
    case heel
    case toe

    // String specific
    case fingernails
    case brass
    case softAccent  // sfzp/sforzando-piano

    // Other
    case scoop
    case plop
    case doit
    case falloff
}

// MARK: - SMuFL Glyph Mapping

extension Articulation {
    /// The SMuFL glyph name for this articulation when placed above the staff.
    public var glyphAbove: SMuFLGlyphName? {
        switch self {
        case .accent: return .articAccentAbove
        case .strongAccent: return .articMarcatoAbove
        case .staccato: return .articStaccatoAbove
        case .tenuto: return .articTenutoAbove
        case .detachedLegato: return .articTenutoStaccatoAbove
        case .staccatissimo: return .articStaccatissimoAbove
        case .spiccato: return .articStaccatissimoAbove  // Same glyph typically
        case .stress: return .articStressAbove
        case .unstress: return .articUnstressAbove
        case .breathMark: return .breathMarkComma
        case .caesura: return .caesura
        case .upBow: return nil  // TODO: Add stringsUpBow to SMuFLGlyphName
        case .downBow: return nil  // TODO: Add stringsDownBow to SMuFLGlyphName
        case .harmonic: return nil  // TODO: Add stringsHarmonic to SMuFLGlyphName
        case .openString: return nil  // Uses "o" or circle
        case .thumbPosition: return nil  // TODO: Add stringsThumbPosition to SMuFLGlyphName
        case .snapPizzicato: return nil  // Bartók pizz
        case .softAccent: return .articSoftAccentAbove
        default: return nil
        }
    }

    /// The SMuFL glyph name for this articulation when placed below the staff.
    public var glyphBelow: SMuFLGlyphName? {
        switch self {
        case .accent: return .articAccentBelow
        case .strongAccent: return .articMarcatoBelow
        case .staccato: return .articStaccatoBelow
        case .tenuto: return .articTenutoBelow
        case .detachedLegato: return .articTenutoStaccatoBelow
        case .staccatissimo: return .articStaccatissimoBelow
        case .spiccato: return .articStaccatissimoBelow
        case .stress: return .articStressBelow
        case .unstress: return .articUnstressBelow
        case .softAccent: return .articSoftAccentBelow
        default: return glyphAbove  // Many don't have separate below variants
        }
    }

    /// Returns the appropriate glyph for the given placement.
    public func glyph(for placement: Placement) -> SMuFLGlyphName? {
        switch placement {
        case .above: return glyphAbove
        case .below: return glyphBelow
        }
    }

    /// Default placement for this articulation.
    public var defaultPlacement: Placement {
        switch self {
        case .staccato, .tenuto, .detachedLegato, .staccatissimo:
            return .above  // These typically follow stem direction
        case .accent, .strongAccent, .stress:
            return .above
        case .breathMark, .caesura:
            return .above
        case .upBow, .downBow, .harmonic, .thumbPosition:
            return .above
        default:
            return .above
        }
    }
}

// MARK: - Articulation Display

/// An articulation with its placement information.
public struct ArticulationDisplay: Codable, Sendable {
    /// The articulation type.
    public var articulation: Articulation

    /// Placement relative to the note.
    public var placement: Placement?

    /// Whether this is editorial (added by editor, not in original).
    public var editorial: Bool

    public init(
        articulation: Articulation,
        placement: Placement? = nil,
        editorial: Bool = false
    ) {
        self.articulation = articulation
        self.placement = placement
        self.editorial = editorial
    }

    /// The effective placement (explicit or default).
    public var effectivePlacement: Placement {
        placement ?? articulation.defaultPlacement
    }

    /// The SMuFL glyph for rendering.
    public var glyph: SMuFLGlyphName? {
        articulation.glyph(for: effectivePlacement)
    }
}

// MARK: - Articulation Categories

extension Articulation {
    /// Category of articulation for grouping.
    public var category: ArticulationCategory {
        switch self {
        case .accent, .strongAccent, .stress, .unstress, .softAccent:
            return .accent
        case .staccato, .staccatissimo, .spiccato:
            return .staccato
        case .tenuto, .detachedLegato:
            return .tenuto
        case .breathMark, .caesura:
            return .breath
        case .upBow, .downBow:
            return .bowing
        case .harmonic, .openString, .snapPizzicato, .fingernails:
            return .string
        case .scoop, .plop, .doit, .falloff:
            return .jazz
        default:
            return .other
        }
    }
}

/// Categories of articulations.
public enum ArticulationCategory: String, Sendable {
    case accent
    case staccato
    case tenuto
    case breath
    case bowing
    case string
    case jazz
    case other
}

// MARK: - MusicXML Mapping

extension Articulation {
    /// Creates an Articulation from a MusicXML element name.
    public init?(musicXMLName: String) {
        switch musicXMLName {
        case "accent": self = .accent
        case "strong-accent": self = .strongAccent
        case "staccato": self = .staccato
        case "tenuto": self = .tenuto
        case "detached-legato": self = .detachedLegato
        case "staccatissimo": self = .staccatissimo
        case "spiccato": self = .spiccato
        case "stress": self = .stress
        case "unstress": self = .unstress
        case "breath-mark": self = .breathMark
        case "caesura": self = .caesura
        case "up-bow": self = .upBow
        case "down-bow": self = .downBow
        case "harmonic": self = .harmonic
        case "open-string": self = .openString
        case "thumb-position": self = .thumbPosition
        case "pluck": self = .pluck
        case "double-tongue": self = .doubleTongue
        case "triple-tongue": self = .tripleTongue
        case "stopped": self = .stopped
        case "snap-pizzicato": self = .snapPizzicato
        case "heel": self = .heel
        case "toe": self = .toe
        case "fingernails": self = .fingernails
        case "brass-bend": self = .brass
        case "soft-accent": self = .softAccent
        case "scoop": self = .scoop
        case "plop": self = .plop
        case "doit": self = .doit
        case "falloff": self = .falloff
        default: return nil
        }
    }

    /// The MusicXML element name for this articulation.
    public var musicXMLName: String {
        switch self {
        case .accent: return "accent"
        case .strongAccent: return "strong-accent"
        case .staccato: return "staccato"
        case .tenuto: return "tenuto"
        case .detachedLegato: return "detached-legato"
        case .staccatissimo: return "staccatissimo"
        case .spiccato: return "spiccato"
        case .stress: return "stress"
        case .unstress: return "unstress"
        case .breathMark: return "breath-mark"
        case .caesura: return "caesura"
        case .upBow: return "up-bow"
        case .downBow: return "down-bow"
        case .harmonic: return "harmonic"
        case .openString: return "open-string"
        case .thumbPosition: return "thumb-position"
        case .pluck: return "pluck"
        case .doubleTongue: return "double-tongue"
        case .tripleTongue: return "triple-tongue"
        case .stopped: return "stopped"
        case .snapPizzicato: return "snap-pizzicato"
        case .heel: return "heel"
        case .toe: return "toe"
        case .fingernails: return "fingernails"
        case .brass: return "brass-bend"
        case .softAccent: return "soft-accent"
        case .scoop: return "scoop"
        case .plop: return "plop"
        case .doit: return "doit"
        case .falloff: return "falloff"
        }
    }
}
