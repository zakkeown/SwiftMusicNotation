import Foundation
import SMuFLKit

// MARK: - SMuFL Glyph Mapping for Ornaments

extension OrnamentType {
    /// The SMuFL glyph name for this ornament when placed above the staff.
    public var glyphAbove: SMuFLGlyphName? {
        switch self {
        case .trill: return .ornamentTrill
        case .turn: return .ornamentTurn
        case .delayedTurn: return .ornamentTurn  // Same glyph, different timing
        case .invertedTurn: return .ornamentTurnInverted
        case .delayedInvertedTurn: return .ornamentTurnInverted
        case .verticalTurn: return .ornamentTurnSlash
        case .shake: return .ornamentShortTrill
        case .mordent: return .ornamentMordent
        case .invertedMordent: return .ornamentMordentInverted
        case .schleifer: return .ornamentPrallTriller
        case .tremolo: return nil  // Tremolo uses beam-like marks, not a single glyph
        case .appoggiatura: return nil  // Grace notes are rendered as small notes
        case .acciaccatura: return nil  // Grace notes with slash are rendered as small notes
        }
    }

    /// The SMuFL glyph name for this ornament when placed below the staff.
    public var glyphBelow: SMuFLGlyphName? {
        // Most ornaments use the same glyph below as above
        glyphAbove
    }

    /// Returns the appropriate glyph for the given placement.
    public func glyph(for placement: Placement) -> SMuFLGlyphName? {
        switch placement {
        case .above: return glyphAbove
        case .below: return glyphBelow
        }
    }

    /// Default placement for this ornament.
    public var defaultPlacement: Placement {
        .above  // All ornaments default to above the staff
    }

    /// Whether this ornament uses a wavy line extension (trills).
    public var supportsWavyLine: Bool {
        switch self {
        case .trill, .shake:
            return true
        default:
            return false
        }
    }

    /// Whether this ornament is a grace note type.
    public var isGraceNote: Bool {
        switch self {
        case .appoggiatura, .acciaccatura:
            return true
        default:
            return false
        }
    }
}

// MARK: - Ornament Display Properties

extension Ornament {
    /// The SMuFL glyph for rendering this ornament.
    public var glyph: SMuFLGlyphName? {
        type.glyph(for: effectivePlacement)
    }

    /// The effective placement (explicit or default).
    public var effectivePlacement: Placement {
        placement ?? type.defaultPlacement
    }
}
