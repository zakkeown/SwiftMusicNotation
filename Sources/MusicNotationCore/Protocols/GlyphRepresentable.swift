import Foundation
import SMuFLKit

/// Protocol for types that can be represented by SMuFL glyphs.
public protocol GlyphRepresentable {
    /// The primary SMuFL glyph for this element.
    var glyph: SMuFLGlyphName? { get }
}

/// Protocol for types that have placement-dependent glyphs.
public protocol PlacementGlyphRepresentable: GlyphRepresentable {
    /// The SMuFL glyph when placed above.
    var glyphAbove: SMuFLGlyphName? { get }

    /// The SMuFL glyph when placed below.
    var glyphBelow: SMuFLGlyphName? { get }

    /// Returns the glyph for a specific placement.
    func glyph(for placement: Placement) -> SMuFLGlyphName?
}

extension PlacementGlyphRepresentable {
    /// Default implementation uses above glyph.
    public var glyph: SMuFLGlyphName? {
        glyphAbove
    }

    /// Default implementation selects based on placement.
    public func glyph(for placement: Placement) -> SMuFLGlyphName? {
        switch placement {
        case .above: return glyphAbove
        case .below: return glyphBelow
        }
    }
}

/// Protocol for types composed of multiple glyphs.
public protocol CompositeGlyphRepresentable: GlyphRepresentable {
    /// The component glyphs that make up this element.
    var componentGlyphs: [SMuFLGlyphName] { get }
}

// MARK: - Glyph with Alternates

/// Protocol for types with alternate glyph representations.
public protocol AlternateGlyphRepresentable: GlyphRepresentable {
    /// Alternate glyphs that can be used.
    var alternateGlyphs: [SMuFLGlyphName] { get }

    /// Selects a glyph based on style preference.
    func glyph(style: GlyphStyle) -> SMuFLGlyphName?
}

/// Glyph style preferences.
public enum GlyphStyle: String, Sendable {
    case standard
    case small
    case large
    case editorial
    case handwritten
}

extension AlternateGlyphRepresentable {
    /// Default returns alternates array.
    public var alternateGlyphs: [SMuFLGlyphName] {
        if let primary = glyph {
            return [primary]
        }
        return []
    }

    /// Default uses primary glyph.
    public func glyph(style: GlyphStyle) -> SMuFLGlyphName? {
        glyph
    }
}

// MARK: - Conformances

extension Articulation: PlacementGlyphRepresentable {}

extension Dynamic: GlyphRepresentable, CompositeGlyphRepresentable {}

// MARK: - Clef Glyph Extension

extension Clef: GlyphRepresentable {
    /// The SMuFL glyph for this clef.
    public var glyph: SMuFLGlyphName? {
        switch sign {
        case .g:
            if clefOctaveChange == -1 {
                return .gClef8vb
            } else if clefOctaveChange == 1 {
                return .gClef8va
            }
            return .gClef
        case .f:
            if clefOctaveChange == -1 {
                return .fClef8vb
            } else if clefOctaveChange == 1 {
                return .fClef8va
            }
            return .fClef
        case .c:
            return .cClef
        case .percussion:
            return .unpitchedPercussionClef1
        case .tab:
            return nil  // Tab clef typically uses text
        case .none:
            return nil
        }
    }
}

// MARK: - Accidental Glyph Extension

extension Accidental: GlyphRepresentable {
    /// The SMuFL glyph for this accidental.
    public var glyph: SMuFLGlyphName? {
        switch self {
        case .natural: return .accidentalNatural
        case .sharp: return .accidentalSharp
        case .flat: return .accidentalFlat
        case .doubleSharp: return .accidentalDoubleSharp
        case .doubleFlat: return .accidentalDoubleFlat
        case .tripleSharp: return .accidentalTripleSharp
        case .tripleFlat: return .accidentalTripleFlat
        case .naturalSharp: return .accidentalNaturalSharp
        case .naturalFlat: return .accidentalNaturalFlat
        case .quarterToneSharp: return .accidentalQuarterToneSharpStein
        case .quarterToneFlat: return .accidentalQuarterToneFlatStein
        case .threeQuarterToneSharp: return .accidentalThreeQuarterTonesSharpStein
        case .threeQuarterToneFlat: return .accidentalThreeQuarterTonesFlatZimmermann
        // Arrow accidentals, sori/koron - TODO: add SMuFL glyph mappings
        default: return nil
        }
    }
}

// MARK: - Rest Glyph Extension

extension DurationBase {
    /// The SMuFL rest glyph for this duration.
    public var restGlyph: SMuFLGlyphName? {
        switch self {
        case .maxima: return .restMaxima
        case .longa: return .restLonga
        case .breve: return .restDoubleWhole
        case .whole: return .restWhole
        case .half: return .restHalf
        case .quarter: return .restQuarter
        case .eighth: return .rest8th
        case .sixteenth: return .rest16th
        case .thirtySecond: return .rest32nd
        case .sixtyFourth: return .rest64th
        case .oneHundredTwentyEighth: return .rest128th
        case .twoHundredFiftySixth: return .rest256th
        }
    }

    /// The SMuFL notehead glyph for this duration (for standard black/white noteheads).
    public var noteheadGlyph: SMuFLGlyphName {
        switch self {
        case .maxima, .longa, .breve:
            return .noteheadDoubleWhole
        case .whole:
            return .noteheadWhole
        case .half:
            return .noteheadHalf
        default:
            return .noteheadBlack
        }
    }

    /// The SMuFL flag glyph for this duration (stem up).
    public var flagUpGlyph: SMuFLGlyphName? {
        switch self {
        case .eighth: return .flag8thUp
        case .sixteenth: return .flag16thUp
        case .thirtySecond: return .flag32ndUp
        case .sixtyFourth: return .flag64thUp
        case .oneHundredTwentyEighth: return .flag128thUp
        case .twoHundredFiftySixth: return .flag256thUp
        default: return nil
        }
    }

    /// The SMuFL flag glyph for this duration (stem down).
    public var flagDownGlyph: SMuFLGlyphName? {
        switch self {
        case .eighth: return .flag8thDown
        case .sixteenth: return .flag16thDown
        case .thirtySecond: return .flag32ndDown
        case .sixtyFourth: return .flag64thDown
        case .oneHundredTwentyEighth: return .flag128thDown
        case .twoHundredFiftySixth: return .flag256thDown
        default: return nil
        }
    }
}

// MARK: - Percussion Notehead Glyph Extension

extension PercussionNotehead: GlyphRepresentable {
    /// The SMuFL glyph for this percussion notehead at quarter note duration.
    ///
    /// For duration-specific glyphs, use `glyph(for:)` instead.
    public var glyph: SMuFLGlyphName? {
        // Default to quarter note (black notehead equivalent)
        glyph(for: .quarter)
    }

    /// Gets the notehead glyph for a specific duration.
    ///
    /// - Parameter duration: The duration base.
    /// - Returns: The appropriate SMuFL glyph for this notehead and duration.
    public func noteheadGlyph(for duration: DurationBase) -> SMuFLGlyphName {
        glyph(for: duration)
    }
}

// MARK: - Time Signature Glyph Extension

extension TimeSignature {
    /// Gets SMuFL glyph for common/cut time symbols.
    public var symbolGlyph: SMuFLGlyphName? {
        guard let sym = symbol else { return nil }
        switch sym {
        case .common: return .timeSigCommon
        case .cut: return .timeSigCutCommon
        default: return nil
        }
    }

    /// Gets SMuFL glyphs for time signature numbers.
    public static func numberGlyphs(for number: Int) -> [SMuFLGlyphName] {
        let digits = String(number).compactMap { Int(String($0)) }
        return digits.compactMap { digitGlyph(for: $0) }
    }

    /// Gets the SMuFL glyph for a single digit.
    public static func digitGlyph(for digit: Int) -> SMuFLGlyphName? {
        switch digit {
        case 0: return .timeSig0
        case 1: return .timeSig1
        case 2: return .timeSig2
        case 3: return .timeSig3
        case 4: return .timeSig4
        case 5: return .timeSig5
        case 6: return .timeSig6
        case 7: return .timeSig7
        case 8: return .timeSig8
        case 9: return .timeSig9
        default: return nil
        }
    }
}
