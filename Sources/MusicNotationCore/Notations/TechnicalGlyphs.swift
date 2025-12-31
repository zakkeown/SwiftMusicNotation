import Foundation
import SMuFLKit

// MARK: - SMuFL Glyph Mapping for Technical Markings

extension TechnicalMarkType {
    /// The SMuFL glyph name for this technical marking.
    public var glyph: SMuFLGlyphName? {
        switch self {
        // String techniques
        case .upBow: return .stringsUpBow
        case .downBow: return .stringsDownBow
        case .harmonic: return .stringsHarmonic
        case .openString: return .stringsHarmonic  // Same glyph (circle)
        case .stopped: return nil  // Uses + symbol, typically text
        case .snapPizzicato: return .stringsSnapPizzicatoAbove

        // Fingering - these typically use text numbers, not specific glyphs
        case .fingering: return nil
        case .string: return nil
        case .fret: return nil

        // Guitar techniques - these are typically text or custom symbols
        case .hammerOn: return nil
        case .pullOff: return nil
        case .bend: return nil
        case .tap: return nil

        // Pedal techniques
        case .heel: return nil  // Uses U or ^ symbol
        case .toe: return nil   // Uses ^ symbol
        }
    }

    /// Default placement for this technical marking.
    public var defaultPlacement: Placement {
        switch self {
        case .upBow, .downBow:
            return .above
        case .harmonic, .openString:
            return .above
        case .fingering:
            return .above  // Fingerings typically above for piano, varies for strings
        default:
            return .above
        }
    }

    /// Whether this technical marking uses text content.
    public var usesTextContent: Bool {
        switch self {
        case .fingering, .string, .fret, .hammerOn, .pullOff:
            return true
        default:
            return false
        }
    }

    /// Whether this technical marking is primarily for string instruments.
    public var isStringTechnique: Bool {
        switch self {
        case .upBow, .downBow, .harmonic, .openString, .stopped,
             .snapPizzicato, .string:
            return true
        default:
            return false
        }
    }

    /// Whether this technical marking is primarily for fretted instruments.
    public var isFrettedTechnique: Bool {
        switch self {
        case .fret, .hammerOn, .pullOff, .bend, .tap:
            return true
        default:
            return false
        }
    }
}

// MARK: - TechnicalMark Display Properties

extension TechnicalMark {
    /// The SMuFL glyph for rendering this technical marking.
    public var glyph: SMuFLGlyphName? {
        type.glyph
    }

    /// The effective placement (explicit or default).
    public var effectivePlacement: Placement {
        placement ?? type.defaultPlacement
    }

    /// The display text for this technical marking (for fingerings, etc.).
    public var displayText: String? {
        if let text = text {
            return text
        }
        if let number = number {
            return String(number)
        }
        return nil
    }
}
