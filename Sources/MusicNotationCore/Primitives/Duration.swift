import Foundation

/// The base rhythmic value of a note or rest.
///
/// `DurationBase` represents the fundamental note value before augmentation dots
/// or tuplet modification. Values range from the rare maxima (8 whole notes) to
/// the tiny 256th note.
///
/// ## Common Values
///
/// | Value | Name | Beats (4/4) |
/// |-------|------|-------------|
/// | `.whole` | Whole note | 4 |
/// | `.half` | Half note | 2 |
/// | `.quarter` | Quarter note | 1 |
/// | `.eighth` | Eighth note | 1/2 |
/// | `.sixteenth` | Sixteenth note | 1/4 |
///
/// ## Fractional Value
///
/// Get the duration as a fraction:
///
/// ```swift
/// DurationBase.quarter.wholeNoteValue   // 1/4
/// DurationBase.eighth.quarterNoteValue  // 1/2
/// DurationBase.half.beamCount           // 0 (no beams)
/// DurationBase.sixteenth.beamCount      // 2
/// ```
///
/// ## MusicXML Names
///
/// Convert to/from MusicXML type names:
///
/// ```swift
/// DurationBase.sixteenth.musicXMLTypeName  // "16th"
/// DurationBase(musicXMLTypeName: "32nd")   // .thirtySecond
/// ```
public enum DurationBase: Int, Codable, CaseIterable, Comparable, Sendable {
    case maxima = 8          // 8 whole notes
    case longa = 4           // 4 whole notes
    case breve = 2           // 2 whole notes (double whole)
    case whole = 1           // 1 whole note
    case half = -1           // 1/2 whole note
    case quarter = -2        // 1/4 whole note
    case eighth = -3         // 1/8 whole note
    case sixteenth = -4      // 1/16 whole note
    case thirtySecond = -5   // 1/32 whole note
    case sixtyFourth = -6    // 1/64 whole note
    case oneHundredTwentyEighth = -7  // 1/128 whole note
    case twoHundredFiftySixth = -8    // 1/256 whole note

    /// The duration as a fraction of a whole note.
    public var wholeNoteValue: Rational {
        if rawValue >= 1 {
            return Rational(rawValue, 1)
        } else {
            // For negative rawValues: half=-1 -> 1/2, quarter=-2 -> 1/4, etc.
            return Rational(1, 1 << -rawValue)
        }
    }

    /// The duration as a fraction of a quarter note.
    public var quarterNoteValue: Rational {
        wholeNoteValue * 4
    }

    /// The number of beams/flags for this duration (0 for quarter and longer).
    public var beamCount: Int {
        max(0, -rawValue - 2)
    }

    /// The MusicXML type name for this duration.
    public var musicXMLTypeName: String {
        switch self {
        case .maxima: return "maxima"
        case .longa: return "long"
        case .breve: return "breve"
        case .whole: return "whole"
        case .half: return "half"
        case .quarter: return "quarter"
        case .eighth: return "eighth"
        case .sixteenth: return "16th"
        case .thirtySecond: return "32nd"
        case .sixtyFourth: return "64th"
        case .oneHundredTwentyEighth: return "128th"
        case .twoHundredFiftySixth: return "256th"
        }
    }

    /// Creates a DurationBase from a MusicXML type name.
    public init?(musicXMLTypeName: String) {
        switch musicXMLTypeName {
        case "maxima": self = .maxima
        case "long": self = .longa
        case "breve": self = .breve
        case "whole": self = .whole
        case "half": self = .half
        case "quarter": self = .quarter
        case "eighth": self = .eighth
        case "16th": self = .sixteenth
        case "32nd": self = .thirtySecond
        case "64th": self = .sixtyFourth
        case "128th": self = .oneHundredTwentyEighth
        case "256th": self = .twoHundredFiftySixth
        default: return nil
        }
    }

    public static func < (lhs: DurationBase, rhs: DurationBase) -> Bool {
        // Longer durations have higher raw values
        lhs.rawValue < rhs.rawValue
    }
}

/// A tuplet ratio defining non-standard note groupings.
///
/// `TupletRatio` represents rhythmic modifications like triplets (3 notes in the
/// time of 2) or quintuplets (5 notes in the time of 4). The ratio affects the
/// actual duration of each note.
///
/// ## Common Tuplets
///
/// ```swift
/// TupletRatio.triplet     // 3:2 (triplet)
/// TupletRatio.duplet      // 2:3 (duplet in compound meter)
/// TupletRatio.quintuplet  // 5:4
/// TupletRatio.sextuplet   // 6:4
/// TupletRatio.septuplet   // 7:4
/// ```
///
/// ## Custom Ratios
///
/// ```swift
/// // 5 eighth notes in the time of 3
/// let custom = TupletRatio(actual: 5, normal: 3, actualType: .eighth)
/// ```
///
/// ## Duration Effect
///
/// Each tuplet note is shorter by the ratio factor:
///
/// ```swift
/// let tripletEighth = Duration(base: .eighth, tupletRatio: .triplet)
/// // Duration = 1/8 × (2/3) = 1/12 of a whole note
/// ```
public struct TupletRatio: Hashable, Codable, Sendable {
    /// The actual number of notes played.
    public let actual: Int

    /// The normal number of notes in that time span.
    public let normal: Int

    /// The note type of the actual notes (optional).
    public let actualType: DurationBase?

    /// The note type of the normal notes (optional).
    public let normalType: DurationBase?

    /// Creates a tuplet ratio.
    public init(actual: Int, normal: Int, actualType: DurationBase? = nil, normalType: DurationBase? = nil) {
        precondition(actual > 0, "Actual notes must be positive")
        precondition(normal > 0, "Normal notes must be positive")
        self.actual = actual
        self.normal = normal
        self.actualType = actualType
        self.normalType = normalType
    }

    /// The ratio as a Rational (normal/actual, since tuplet notes are shorter).
    public var ratio: Rational {
        Rational(normal, actual)
    }

    /// Common tuplet: triplet (3:2)
    public static let triplet = TupletRatio(actual: 3, normal: 2)

    /// Common tuplet: duplet (2:3, used in compound meter)
    public static let duplet = TupletRatio(actual: 2, normal: 3)

    /// Common tuplet: quintuplet (5:4)
    public static let quintuplet = TupletRatio(actual: 5, normal: 4)

    /// Common tuplet: sextuplet (6:4)
    public static let sextuplet = TupletRatio(actual: 6, normal: 4)

    /// Common tuplet: septuplet (7:4)
    public static let septuplet = TupletRatio(actual: 7, normal: 4)
}

/// A complete rhythmic duration including dots and tuplet modifications.
///
/// `Duration` combines a base note value with augmentation dots and optional tuplet
/// ratios to represent any rhythmic duration. Use this for calculating actual timing
/// and for layout spacing.
///
/// ## Creating Durations
///
/// ```swift
/// // Simple durations
/// let quarter = Duration(base: .quarter)
/// let half = Duration(base: .half)
///
/// // Dotted durations
/// let dottedQuarter = Duration(base: .quarter, dots: 1)  // 1.5 beats
/// let doubleDottedHalf = Duration(base: .half, dots: 2)  // 3.5 beats
///
/// // Tuplet durations
/// let tripletEighth = Duration(
///     base: .eighth,
///     tupletRatio: .triplet
/// )
/// ```
///
/// ## Using Preset Durations
///
/// Common durations are available as static properties:
///
/// ```swift
/// Duration.quarter
/// Duration.dottedQuarter
/// Duration.eighth
/// Duration.dottedEighth
/// Duration.sixteenth
/// ```
///
/// ## Calculating Value
///
/// Get the duration as a fraction:
///
/// ```swift
/// Duration.quarter.quarterNoteValue      // 1/1
/// Duration.dottedQuarter.quarterNoteValue // 3/2
/// Duration.eighth.wholeNoteValue          // 1/8
/// ```
///
/// ## MusicXML Divisions
///
/// Convert to/from MusicXML's division-based timing:
///
/// ```swift
/// // divisions="2" means 2 divisions per quarter note
/// let divs = duration.divisions(perQuarter: 2)
///
/// // Reconstruct from divisions
/// let duration = Duration.from(divisions: 3, perQuarter: 2, type: .quarter, dots: 1)
/// ```
///
/// - SeeAlso: ``DurationBase`` for base note values
/// - SeeAlso: ``TupletRatio`` for tuplet modifications
public struct Duration: Hashable, Codable, Comparable, Sendable {
    /// The base rhythmic value.
    public var base: DurationBase

    /// The number of augmentation dots (each dot adds half the previous value).
    public var dots: Int

    /// Optional tuplet modification.
    public var tupletRatio: TupletRatio?

    /// Creates a duration with the specified components.
    public init(base: DurationBase, dots: Int = 0, tupletRatio: TupletRatio? = nil) {
        precondition(dots >= 0, "Dots cannot be negative")
        self.base = base
        self.dots = dots
        self.tupletRatio = tupletRatio
    }

    /// The duration as a fraction of a quarter note, accounting for dots and tuplets.
    public var quarterNoteValue: Rational {
        var value = base.quarterNoteValue

        // Apply dots: each dot adds half of the previous value
        // dotted = 1 + 1/2 + 1/4 + ... = (2^(dots+1) - 1) / 2^dots
        if dots > 0 {
            let dotMultiplier = Rational((1 << (dots + 1)) - 1, 1 << dots)
            value = value * dotMultiplier
        }

        // Apply tuplet ratio
        if let ratio = tupletRatio {
            value = value * ratio.ratio
        }

        return value
    }

    /// The duration as a fraction of a whole note.
    public var wholeNoteValue: Rational {
        quarterNoteValue / 4
    }

    /// The duration in MusicXML divisions (given divisions per quarter note).
    public func divisions(perQuarter: Int) -> Int {
        let quarterNotes = quarterNoteValue
        return Int((quarterNotes * Rational(perQuarter, 1)).doubleValue.rounded())
    }

    /// Creates a duration from MusicXML divisions.
    public static func from(divisions: Int, perQuarter: Int, type: DurationBase? = nil, dots: Int = 0) -> Duration {
        // If type is provided, use it directly
        if let base = type {
            return Duration(base: base, dots: dots)
        }

        // Otherwise, try to infer from the division count
        let quarterNoteValue = Rational(divisions, perQuarter)

        // Find the closest base duration
        for base in DurationBase.allCases.reversed() {
            if base.quarterNoteValue == quarterNoteValue {
                return Duration(base: base, dots: 0)
            }
            // Check for dotted values
            let dottedValue = base.quarterNoteValue * Rational(3, 2)
            if dottedValue == quarterNoteValue {
                return Duration(base: base, dots: 1)
            }
            let doubleDottedValue = base.quarterNoteValue * Rational(7, 4)
            if doubleDottedValue == quarterNoteValue {
                return Duration(base: base, dots: 2)
            }
        }

        // Fallback to quarter note
        return Duration(base: .quarter, dots: 0)
    }

    // MARK: - Comparable

    public static func < (lhs: Duration, rhs: Duration) -> Bool {
        lhs.quarterNoteValue < rhs.quarterNoteValue
    }

    // MARK: - Common Durations

    public static let maxima = Duration(base: .maxima)
    public static let longa = Duration(base: .longa)
    public static let breve = Duration(base: .breve)
    public static let whole = Duration(base: .whole)
    public static let dottedWhole = Duration(base: .whole, dots: 1)
    public static let half = Duration(base: .half)
    public static let dottedHalf = Duration(base: .half, dots: 1)
    public static let quarter = Duration(base: .quarter)
    public static let dottedQuarter = Duration(base: .quarter, dots: 1)
    public static let eighth = Duration(base: .eighth)
    public static let dottedEighth = Duration(base: .eighth, dots: 1)
    public static let sixteenth = Duration(base: .sixteenth)
    public static let dottedSixteenth = Duration(base: .sixteenth, dots: 1)
    public static let thirtySecond = Duration(base: .thirtySecond)
    public static let sixtyFourth = Duration(base: .sixtyFourth)
    public static let oneHundredTwentyEighth = Duration(base: .oneHundredTwentyEighth)
    public static let twoHundredFiftySixth = Duration(base: .twoHundredFiftySixth)
}

// MARK: - CustomStringConvertible

extension Duration: CustomStringConvertible {
    public var description: String {
        var result = base.musicXMLTypeName
        if dots > 0 {
            result += String(repeating: ".", count: dots)
        }
        if let ratio = tupletRatio {
            result += " (\(ratio.actual):\(ratio.normal))"
        }
        return result
    }
}

extension TupletRatio: CustomStringConvertible {
    public var description: String {
        "\(actual):\(normal)"
    }
}
