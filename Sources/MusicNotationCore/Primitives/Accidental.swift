import Foundation

/// Represents a visual accidental marking on a note.
///
/// `Accidental` covers the full range of Western and microtonal accidentals,
/// from standard sharps and flats through quarter-tone and arrow accidentals.
///
/// Note: This represents the visual accidental displayed on the score,
/// which may differ from the pitch alteration (e.g., courtesy accidentals,
/// or accidentals inherited from the key signature).
///
/// ## Categories
///
/// - **Standard**: natural, sharp, flat, double sharp, double flat
/// - **Combination**: natural-sharp, natural-flat (cancellation before new accidental)
/// - **Triple**: triple sharp, triple flat (extremely rare)
/// - **Microtonal (Stein-Zimmermann)**: quarter-tone sharps and flats
/// - **Microtonal (Gould)**: arrow modifications to standard accidentals
/// - **Persian**: sori and koron for Persian classical music
///
/// - SeeAlso: ``Pitch`` for pitch representation with alterations
public enum Accidental: String, Codable, CaseIterable, Sendable {
    // MARK: Standard Accidentals

    /// Cancels previous accidental, returns to natural pitch.
    case natural

    /// Raises pitch by one semitone.
    case sharp

    /// Lowers pitch by one semitone.
    case flat

    /// Raises pitch by two semitones (displayed as × or ##).
    case doubleSharp

    /// Lowers pitch by two semitones (displayed as 𝄫).
    case doubleFlat

    // MARK: Combination Accidentals

    /// Natural followed by sharp—cancels previous alteration then raises.
    case naturalSharp

    /// Natural followed by flat—cancels previous alteration then lowers.
    case naturalFlat

    // MARK: Triple Accidentals

    /// Raises pitch by three semitones (extremely rare).
    case tripleSharp

    /// Lowers pitch by three semitones (extremely rare).
    case tripleFlat

    // MARK: Microtonal - Stein-Zimmermann System

    /// Raises pitch by one quarter tone (half sharp).
    case quarterToneSharp

    /// Lowers pitch by one quarter tone (half flat, reversed flat symbol).
    case quarterToneFlat

    /// Raises pitch by three quarter tones (sharp and a half).
    case threeQuarterToneSharp

    /// Lowers pitch by three quarter tones (flat and a half).
    case threeQuarterToneFlat

    // MARK: Microtonal - Gould Arrow System

    /// Sharp with upward arrow (raises slightly more than sharp).
    case sharpArrowUp

    /// Sharp with downward arrow (raises slightly less than sharp).
    case sharpArrowDown

    /// Flat with upward arrow (lowers slightly less than flat).
    case flatArrowUp

    /// Flat with downward arrow (lowers slightly more than flat).
    case flatArrowDown

    /// Natural with upward arrow (raises slightly above natural).
    case naturalArrowUp

    /// Natural with downward arrow (lowers slightly below natural).
    case naturalArrowDown

    /// Double sharp with upward arrow.
    case doubleSharpArrowUp

    /// Double sharp with downward arrow.
    case doubleSharpArrowDown

    /// Double flat with upward arrow.
    case doubleFlatArrowUp

    /// Double flat with downward arrow.
    case doubleFlatArrowDown

    // MARK: Persian Accidentals

    /// Sori—quarter tone sharp in Persian classical music.
    case sori

    /// Koron—quarter tone flat in Persian classical music.
    case koron

    /// The alteration value in semitones that this accidental represents.
    public var semitoneAlteration: Double {
        switch self {
        case .natural:
            return 0
        case .sharp:
            return 1
        case .flat:
            return -1
        case .doubleSharp:
            return 2
        case .doubleFlat:
            return -2
        case .naturalSharp:
            return 1
        case .naturalFlat:
            return -1
        case .tripleSharp:
            return 3
        case .tripleFlat:
            return -3
        case .quarterToneSharp, .sori:
            return 0.5
        case .quarterToneFlat, .koron:
            return -0.5
        case .threeQuarterToneSharp:
            return 1.5
        case .threeQuarterToneFlat:
            return -1.5
        case .sharpArrowUp:
            return 1.25  // Approximate
        case .sharpArrowDown:
            return 0.75
        case .flatArrowUp:
            return -0.75
        case .flatArrowDown:
            return -1.25
        case .naturalArrowUp:
            return 0.25
        case .naturalArrowDown:
            return -0.25
        case .doubleSharpArrowUp:
            return 2.25
        case .doubleSharpArrowDown:
            return 1.75
        case .doubleFlatArrowUp:
            return -1.75
        case .doubleFlatArrowDown:
            return -2.25
        }
    }

    /// The MusicXML accidental value name.
    public var musicXMLName: String {
        switch self {
        case .natural: return "natural"
        case .sharp: return "sharp"
        case .flat: return "flat"
        case .doubleSharp: return "double-sharp"
        case .doubleFlat: return "flat-flat"
        case .naturalSharp: return "natural-sharp"
        case .naturalFlat: return "natural-flat"
        case .tripleSharp: return "triple-sharp"
        case .tripleFlat: return "triple-flat"
        case .quarterToneSharp: return "quarter-sharp"
        case .quarterToneFlat: return "quarter-flat"
        case .threeQuarterToneSharp: return "three-quarters-sharp"
        case .threeQuarterToneFlat: return "three-quarters-flat"
        case .sharpArrowUp: return "sharp-up"
        case .sharpArrowDown: return "sharp-down"
        case .flatArrowUp: return "flat-up"
        case .flatArrowDown: return "flat-down"
        case .naturalArrowUp: return "natural-up"
        case .naturalArrowDown: return "natural-down"
        case .doubleSharpArrowUp: return "double-sharp-up"
        case .doubleSharpArrowDown: return "double-sharp-down"
        case .doubleFlatArrowUp: return "flat-flat-up"
        case .doubleFlatArrowDown: return "flat-flat-down"
        case .sori: return "sori"
        case .koron: return "koron"
        }
    }

    /// Creates an Accidental from a MusicXML accidental value name.
    public init?(musicXMLName: String) {
        switch musicXMLName {
        case "natural": self = .natural
        case "sharp": self = .sharp
        case "flat": self = .flat
        case "double-sharp", "sharp-sharp": self = .doubleSharp
        case "flat-flat", "double-flat": self = .doubleFlat
        case "natural-sharp": self = .naturalSharp
        case "natural-flat": self = .naturalFlat
        case "triple-sharp": self = .tripleSharp
        case "triple-flat": self = .tripleFlat
        case "quarter-sharp": self = .quarterToneSharp
        case "quarter-flat": self = .quarterToneFlat
        case "three-quarters-sharp": self = .threeQuarterToneSharp
        case "three-quarters-flat": self = .threeQuarterToneFlat
        case "sharp-up": self = .sharpArrowUp
        case "sharp-down": self = .sharpArrowDown
        case "flat-up": self = .flatArrowUp
        case "flat-down": self = .flatArrowDown
        case "natural-up": self = .naturalArrowUp
        case "natural-down": self = .naturalArrowDown
        case "double-sharp-up": self = .doubleSharpArrowUp
        case "double-sharp-down": self = .doubleSharpArrowDown
        case "flat-flat-up": self = .doubleFlatArrowUp
        case "flat-flat-down": self = .doubleFlatArrowDown
        case "sori": self = .sori
        case "koron": self = .koron
        default: return nil
        }
    }

    /// Creates an Accidental from a pitch alteration value.
    public init?(fromAlteration alter: Double) {
        switch alter {
        case 0: self = .natural
        case 1: self = .sharp
        case -1: self = .flat
        case 2: self = .doubleSharp
        case -2: self = .doubleFlat
        case 0.5: self = .quarterToneSharp
        case -0.5: self = .quarterToneFlat
        case 1.5: self = .threeQuarterToneSharp
        case -1.5: self = .threeQuarterToneFlat
        case 3: self = .tripleSharp
        case -3: self = .tripleFlat
        default: return nil
        }
    }

    /// Whether this accidental raises the pitch.
    public var isSharpening: Bool {
        semitoneAlteration > 0
    }

    /// Whether this accidental lowers the pitch.
    public var isFlattening: Bool {
        semitoneAlteration < 0
    }

    /// Whether this is a microtonal accidental.
    public var isMicrotonal: Bool {
        let alter = semitoneAlteration
        return alter != alter.rounded()
    }
}

// MARK: - Accidental Display Properties

extension Accidental {
    /// Whether this accidental should typically be displayed in parentheses (courtesy accidental).
    public struct DisplayProperties: OptionSet, Codable, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        /// Display in parentheses.
        public static let parentheses = DisplayProperties(rawValue: 1 << 0)

        /// Display in brackets.
        public static let brackets = DisplayProperties(rawValue: 1 << 1)

        /// Editorial accidental (typically smaller or in special notation).
        public static let editorial = DisplayProperties(rawValue: 1 << 2)

        /// Cautionary accidental (reminder of key signature).
        public static let cautionary = DisplayProperties(rawValue: 1 << 3)
    }
}

// MARK: - CustomStringConvertible

extension Accidental: CustomStringConvertible {
    public var description: String {
        switch self {
        case .natural: return "♮"
        case .sharp: return "♯"
        case .flat: return "♭"
        case .doubleSharp: return "𝄪"
        case .doubleFlat: return "𝄫"
        case .naturalSharp: return "♮♯"
        case .naturalFlat: return "♮♭"
        case .tripleSharp: return "♯𝄪"
        case .tripleFlat: return "♭𝄫"
        case .quarterToneSharp: return "𝄲"
        case .quarterToneFlat: return "𝄳"
        case .threeQuarterToneSharp: return "𝄰"
        case .threeQuarterToneFlat: return "𝄱"
        case .sori: return "سُری"
        case .koron: return "کُرُن"
        default: return musicXMLName
        }
    }
}
