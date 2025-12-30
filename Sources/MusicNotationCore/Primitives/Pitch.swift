import Foundation

/// The letter name (step) of a musical pitch.
///
/// `PitchStep` represents the seven natural notes in Western music: C, D, E, F, G, A, B.
/// Combined with an alteration and octave in ``Pitch``, it defines a specific pitch.
///
/// ## Chromatic vs. Diatonic
///
/// ```swift
/// // Chromatic: semitones from C (0-11)
/// PitchStep.c.chromaticOffset  // 0
/// PitchStep.d.chromaticOffset  // 2
/// PitchStep.e.chromaticOffset  // 4
///
/// // Diatonic: scale position (0-6)
/// PitchStep.c.diatonicPosition  // 0
/// PitchStep.d.diatonicPosition  // 1
/// PitchStep.e.diatonicPosition  // 2
/// ```
///
/// ## Step Arithmetic
///
/// ```swift
/// let c = PitchStep.c
/// c.adding(diatonicSteps: 2)  // .e (third above)
/// c.adding(diatonicSteps: 4)  // .g (fifth above)
/// c.adding(diatonicSteps: 7)  // .c (octave, wraps)
/// ```
public enum PitchStep: String, Codable, CaseIterable, Comparable, Sendable {
    case c = "C"
    case d = "D"
    case e = "E"
    case f = "F"
    case g = "G"
    case a = "A"
    case b = "B"

    /// The chromatic offset from C within an octave (C=0, D=2, E=4, F=5, G=7, A=9, B=11).
    public var chromaticOffset: Int {
        switch self {
        case .c: return 0
        case .d: return 2
        case .e: return 4
        case .f: return 5
        case .g: return 7
        case .a: return 9
        case .b: return 11
        }
    }

    /// The diatonic position within an octave (C=0, D=1, E=2, F=3, G=4, A=5, B=6).
    public var diatonicPosition: Int {
        switch self {
        case .c: return 0
        case .d: return 1
        case .e: return 2
        case .f: return 3
        case .g: return 4
        case .a: return 5
        case .b: return 6
        }
    }

    public static func < (lhs: PitchStep, rhs: PitchStep) -> Bool {
        lhs.diatonicPosition < rhs.diatonicPosition
    }

    /// Returns the step a given number of diatonic steps above this one.
    public func adding(diatonicSteps: Int) -> PitchStep {
        let newPosition = (diatonicPosition + diatonicSteps) %% 7
        return PitchStep.allCases[newPosition]
    }
}

/// A musical pitch with step, alteration, and octave.
///
/// `Pitch` represents an exact musical pitch using scientific pitch notation where
/// middle C is C4. It supports standard accidentals (sharp, flat, natural) as well
/// as microtonal alterations (quarter tones).
///
/// ## Creating Pitches
///
/// ```swift
/// // Natural note
/// let middleC = Pitch(step: .c, octave: 4)
///
/// // With accidental
/// let fSharp = Pitch(step: .f, alter: 1, octave: 4)  // F♯4
/// let bFlat = Pitch(step: .b, alter: -1, octave: 3)  // B♭3
///
/// // Double accidentals
/// let cDoubleSharp = Pitch(step: .c, alter: 2, octave: 4)  // C𝄪4
///
/// // Microtonal (quarter tones)
/// let quarterSharp = Pitch(step: .d, alter: 0.5, octave: 4)  // D𝄲4
/// ```
///
/// ## MIDI Conversion
///
/// Convert to/from MIDI note numbers (middle C = 60):
///
/// ```swift
/// let pitch = Pitch(step: .c, octave: 4)
/// pitch.midiNoteNumber  // 60
///
/// let fromMidi = Pitch(midiNoteNumber: 69)  // A4 (concert A)
/// ```
///
/// ## Frequency
///
/// Get the frequency in Hz (A4 = 440 Hz standard):
///
/// ```swift
/// Pitch.concertA.frequency  // 440.0
/// Pitch.middleC.frequency   // ~261.63
/// ```
///
/// ## Enharmonic Equivalents
///
/// Work with different spellings of the same pitch:
///
/// ```swift
/// let cSharp = Pitch(step: .c, alter: 1, octave: 4)
/// let dFlat = cSharp.enharmonic(withStep: .d)  // D♭4
///
/// cSharp.isEnharmonic(with: dFlat)  // true
/// ```
///
/// ## Comparison
///
/// Pitches are ordered by MIDI number, then enharmonic spelling:
///
/// ```swift
/// Pitch.middleC < Pitch(step: .d, octave: 4)  // true
/// ```
///
/// - SeeAlso: ``PitchStep`` for letter names
/// - SeeAlso: ``Accidental`` for visual accidental marks
public struct Pitch: Hashable, Codable, Comparable, Sendable {
    /// The letter name of the pitch (C through B).
    public var step: PitchStep

    /// The chromatic alteration in semitones.
    /// - 0.0 = natural
    /// - 1.0 = sharp
    /// - -1.0 = flat
    /// - 2.0 = double sharp
    /// - -2.0 = double flat
    /// - 0.5 = quarter-tone sharp
    /// - -0.5 = quarter-tone flat
    public var alter: Double

    /// The octave number in scientific pitch notation (middle C = octave 4).
    public var octave: Int

    /// Creates a pitch with the specified step, alteration, and octave.
    public init(step: PitchStep, alter: Double = 0, octave: Int) {
        self.step = step
        self.alter = alter
        self.octave = octave
    }

    /// Creates a pitch from a MIDI note number.
    /// Note: This assumes equal temperament and returns the simplest enharmonic spelling.
    public init(midiNoteNumber: Int) {
        let noteInOctave = midiNoteNumber %% 12
        let octave = (midiNoteNumber / 12) - 1

        // Use sharps for black keys by default
        let (step, alter): (PitchStep, Double) = switch noteInOctave {
        case 0:  (.c, 0)
        case 1:  (.c, 1)
        case 2:  (.d, 0)
        case 3:  (.d, 1)
        case 4:  (.e, 0)
        case 5:  (.f, 0)
        case 6:  (.f, 1)
        case 7:  (.g, 0)
        case 8:  (.g, 1)
        case 9:  (.a, 0)
        case 10: (.a, 1)
        case 11: (.b, 0)
        default: (.c, 0) // Should never happen
        }

        self.step = step
        self.alter = alter
        self.octave = octave
    }

    /// The MIDI note number for this pitch.
    /// Middle C (C4) = 60.
    public var midiNoteNumber: Int {
        let baseNote = (octave + 1) * 12 + step.chromaticOffset
        return baseNote + Int(alter.rounded())
    }

    /// The frequency in Hz using A4 = 440 Hz standard tuning.
    public var frequency: Double {
        let semitonesFromA4 = Double(midiNoteNumber - 69) + (alter - alter.rounded())
        return 440.0 * pow(2.0, semitonesFromA4 / 12.0)
    }

    /// The diatonic pitch class (0-6, where C=0).
    public var diatonicPitchClass: Int {
        step.diatonicPosition
    }

    /// The chromatic pitch class (0-11, where C=0).
    public var chromaticPitchClass: Int {
        (step.chromaticOffset + Int(alter.rounded())) %% 12
    }

    /// Returns the interval in semitones from this pitch to another.
    public func semitones(to other: Pitch) -> Int {
        other.midiNoteNumber - self.midiNoteNumber
    }

    /// Returns an enharmonic equivalent using the specified step.
    public func enharmonic(withStep targetStep: PitchStep) -> Pitch {
        let targetChromaticOffset = targetStep.chromaticOffset
        let currentChromatic = step.chromaticOffset + Int(alter.rounded())

        var difference = currentChromatic - targetChromaticOffset
        var targetOctave = octave

        // Handle octave wrapping
        if difference > 6 {
            difference -= 12
            targetOctave += 1
        } else if difference < -6 {
            difference += 12
            targetOctave -= 1
        }

        return Pitch(step: targetStep, alter: Double(difference), octave: targetOctave)
    }

    /// Returns true if this pitch is enharmonically equivalent to another.
    public func isEnharmonic(with other: Pitch) -> Bool {
        self.midiNoteNumber == other.midiNoteNumber
    }

    // MARK: - Comparable

    public static func < (lhs: Pitch, rhs: Pitch) -> Bool {
        if lhs.midiNoteNumber != rhs.midiNoteNumber {
            return lhs.midiNoteNumber < rhs.midiNoteNumber
        }
        // For enharmonic pitches, use diatonic ordering (C# < Db)
        if lhs.octave != rhs.octave {
            return lhs.octave < rhs.octave
        }
        if lhs.step != rhs.step {
            return lhs.step < rhs.step
        }
        return lhs.alter < rhs.alter
    }

    // MARK: - Common Pitches

    /// Middle C (C4)
    public static let middleC = Pitch(step: .c, octave: 4)

    /// Concert A (A4 = 440 Hz)
    public static let concertA = Pitch(step: .a, octave: 4)
}

// MARK: - CustomStringConvertible

extension Pitch: CustomStringConvertible {
    public var description: String {
        let alterString: String
        switch alter {
        case 0:
            alterString = ""
        case 1:
            alterString = "♯"
        case -1:
            alterString = "♭"
        case 2:
            alterString = "𝄪"
        case -2:
            alterString = "𝄫"
        case 0.5:
            alterString = "𝄲"  // Quarter-tone sharp
        case -0.5:
            alterString = "𝄳"  // Quarter-tone flat
        default:
            alterString = alter > 0 ? "+\(alter)" : "\(alter)"
        }
        return "\(step.rawValue)\(alterString)\(octave)"
    }
}

// MARK: - Helpers

/// Modulo operation that always returns a non-negative result.
infix operator %%: MultiplicationPrecedence

func %% (lhs: Int, rhs: Int) -> Int {
    let result = lhs % rhs
    return result >= 0 ? result : result + rhs
}
