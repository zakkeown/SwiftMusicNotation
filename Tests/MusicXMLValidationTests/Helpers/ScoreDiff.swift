import Foundation
import MusicNotationCore

/// A structured representation of differences between two scores.
public struct ScoreDiff: Sendable {
    /// Whether the two scores are considered equal.
    public let isEqual: Bool

    /// The list of differences found.
    public let differences: [Difference]

    /// Creates a diff indicating equality.
    public static var equal: ScoreDiff {
        ScoreDiff(isEqual: true, differences: [])
    }

    /// Creates a diff with the given differences.
    public init(isEqual: Bool, differences: [Difference]) {
        self.isEqual = isEqual
        self.differences = differences
    }

    /// Creates a diff from a list of differences.
    public init(differences: [Difference]) {
        self.differences = differences
        self.isEqual = differences.isEmpty
    }

    /// Generates a human-readable report of the differences.
    public func report() -> String {
        if isEqual {
            return "Scores are equal"
        }

        var lines: [String] = ["Score differences found: \(differences.count)"]
        lines.append(String(repeating: "-", count: 50))

        for (index, diff) in differences.enumerated() {
            lines.append("\(index + 1). \(diff.description)")
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Difference Types

extension ScoreDiff {
    /// A single difference between two scores.
    public enum Difference: Sendable, CustomStringConvertible {
        // Structural differences
        case partCountMismatch(expected: Int, actual: Int)
        case measureCountMismatch(partIndex: Int, partName: String, expected: Int, actual: Int)
        case elementCountMismatch(location: MeasureLocation, expected: Int, actual: Int)

        // Part differences
        case partNameMismatch(partIndex: Int, expected: String, actual: String)
        case partIdMismatch(partIndex: Int, expected: String, actual: String)

        // Metadata differences
        case metadataMismatch(field: String, expected: String?, actual: String?)

        // Note differences
        case noteDifference(location: NoteLocation, diff: NoteDiff)
        case noteCountMismatch(location: MeasureLocation, expected: Int, actual: Int)

        // Attribute differences
        case attributeDifference(location: MeasureLocation, diff: AttributeDiff)

        // Direction differences
        case directionDifference(location: MeasureLocation, diff: DirectionDiff)

        // Barline differences
        case barlineDifference(location: MeasureLocation, side: BarlineSide, diff: BarlineDiff)

        // Generic element difference
        case elementTypeMismatch(location: MeasureLocation, elementIndex: Int, expected: String, actual: String)

        public var description: String {
            switch self {
            case .partCountMismatch(let expected, let actual):
                return "Part count: expected \(expected), got \(actual)"

            case .measureCountMismatch(let partIndex, let partName, let expected, let actual):
                return "Measure count in part \(partIndex) (\(partName)): expected \(expected), got \(actual)"

            case .elementCountMismatch(let location, let expected, let actual):
                return "Element count at \(location): expected \(expected), got \(actual)"

            case .partNameMismatch(let partIndex, let expected, let actual):
                return "Part \(partIndex) name: expected '\(expected)', got '\(actual)'"

            case .partIdMismatch(let partIndex, let expected, let actual):
                return "Part \(partIndex) ID: expected '\(expected)', got '\(actual)'"

            case .metadataMismatch(let field, let expected, let actual):
                return "Metadata '\(field)': expected '\(expected ?? "nil")', got '\(actual ?? "nil")'"

            case .noteDifference(let location, let diff):
                return "Note at \(location): \(diff)"

            case .noteCountMismatch(let location, let expected, let actual):
                return "Note count at \(location): expected \(expected), got \(actual)"

            case .attributeDifference(let location, let diff):
                return "Attributes at \(location): \(diff)"

            case .directionDifference(let location, let diff):
                return "Direction at \(location): \(diff)"

            case .barlineDifference(let location, let side, let diff):
                return "\(side) barline at \(location): \(diff)"

            case .elementTypeMismatch(let location, let elementIndex, let expected, let actual):
                return "Element \(elementIndex) at \(location): expected \(expected), got \(actual)"
            }
        }
    }
}

// MARK: - Location Types

extension ScoreDiff {
    /// Location within a score by part and measure.
    public struct MeasureLocation: Sendable, CustomStringConvertible {
        public let partIndex: Int
        public let partName: String
        public let measureIndex: Int
        public let measureNumber: String

        public init(partIndex: Int, partName: String, measureIndex: Int, measureNumber: String) {
            self.partIndex = partIndex
            self.partName = partName
            self.measureIndex = measureIndex
            self.measureNumber = measureNumber
        }

        public var description: String {
            "part \(partIndex) (\(partName)), measure \(measureNumber)"
        }
    }

    /// Location of a specific note within a measure.
    public struct NoteLocation: Sendable, CustomStringConvertible {
        public let measureLocation: MeasureLocation
        public let noteIndex: Int
        public let voice: Int
        public let staff: Int

        public init(measureLocation: MeasureLocation, noteIndex: Int, voice: Int, staff: Int) {
            self.measureLocation = measureLocation
            self.noteIndex = noteIndex
            self.voice = voice
            self.staff = staff
        }

        public var description: String {
            "\(measureLocation), note \(noteIndex) (voice \(voice), staff \(staff))"
        }
    }
}

// MARK: - Specific Diff Types

extension ScoreDiff {
    /// Differences in a note.
    public enum NoteDiff: Sendable, CustomStringConvertible {
        case pitchMismatch(expected: PitchDescription, actual: PitchDescription)
        case durationMismatch(expected: Int, actual: Int)
        case typeMismatch(expected: String?, actual: String?)
        case dotsMismatch(expected: Int, actual: Int)
        case voiceMismatch(expected: Int, actual: Int)
        case staffMismatch(expected: Int, actual: Int)
        case restMismatch(expected: Bool, actual: Bool)
        case chordMismatch(expected: Bool, actual: Bool)
        case tieMismatch(expected: [String], actual: [String])
        case accidentalMismatch(expected: String?, actual: String?)
        case graceMismatch(expected: Bool, actual: Bool)

        public var description: String {
            switch self {
            case .pitchMismatch(let expected, let actual):
                return "pitch: expected \(expected), got \(actual)"
            case .durationMismatch(let expected, let actual):
                return "duration: expected \(expected), got \(actual)"
            case .typeMismatch(let expected, let actual):
                return "type: expected \(expected ?? "nil"), got \(actual ?? "nil")"
            case .dotsMismatch(let expected, let actual):
                return "dots: expected \(expected), got \(actual)"
            case .voiceMismatch(let expected, let actual):
                return "voice: expected \(expected), got \(actual)"
            case .staffMismatch(let expected, let actual):
                return "staff: expected \(expected), got \(actual)"
            case .restMismatch(let expected, let actual):
                return "isRest: expected \(expected), got \(actual)"
            case .chordMismatch(let expected, let actual):
                return "isChord: expected \(expected), got \(actual)"
            case .tieMismatch(let expected, let actual):
                return "ties: expected \(expected), got \(actual)"
            case .accidentalMismatch(let expected, let actual):
                return "accidental: expected \(expected ?? "none"), got \(actual ?? "none")"
            case .graceMismatch(let expected, let actual):
                return "isGrace: expected \(expected), got \(actual)"
            }
        }
    }

    /// Description of a pitch for comparison reporting.
    public struct PitchDescription: Sendable, CustomStringConvertible {
        public let step: String
        public let octave: Int
        public let alter: Double

        public init(step: String, octave: Int, alter: Double = 0) {
            self.step = step
            self.octave = octave
            self.alter = alter
        }

        public static var rest: PitchDescription {
            PitchDescription(step: "rest", octave: 0, alter: 0)
        }

        public static func unpitched(step: String, octave: Int) -> PitchDescription {
            PitchDescription(step: "unpitched:\(step)", octave: octave, alter: 0)
        }

        public var description: String {
            if step == "rest" {
                return "rest"
            }
            if step.hasPrefix("unpitched:") {
                let actualStep = String(step.dropFirst("unpitched:".count))
                return "unpitched \(actualStep)\(octave)"
            }
            let alterStr: String
            if alter > 0 {
                alterStr = "#"
            } else if alter < 0 {
                alterStr = "b"
            } else {
                alterStr = ""
            }
            return "\(step)\(alterStr)\(octave)"
        }
    }

    /// Differences in measure attributes.
    public enum AttributeDiff: Sendable, CustomStringConvertible {
        case divisionsMismatch(expected: Int?, actual: Int?)
        case keyMismatch(expected: String, actual: String)
        case timeMismatch(expected: String, actual: String)
        case clefMismatch(expected: String, actual: String)
        case stavesMismatch(expected: Int, actual: Int)

        public var description: String {
            switch self {
            case .divisionsMismatch(let expected, let actual):
                return "divisions: expected \(expected.map(String.init) ?? "nil"), got \(actual.map(String.init) ?? "nil")"
            case .keyMismatch(let expected, let actual):
                return "key: expected \(expected), got \(actual)"
            case .timeMismatch(let expected, let actual):
                return "time: expected \(expected), got \(actual)"
            case .clefMismatch(let expected, let actual):
                return "clef: expected \(expected), got \(actual)"
            case .stavesMismatch(let expected, let actual):
                return "staves: expected \(expected), got \(actual)"
            }
        }
    }

    /// Differences in directions.
    public enum DirectionDiff: Sendable, CustomStringConvertible {
        case dynamicsMismatch(expected: [String], actual: [String])
        case wedgeMismatch(expected: String?, actual: String?)
        case tempoMismatch(expected: Double?, actual: Double?)
        case wordsMismatch(expected: String?, actual: String?)
        case typeMismatch(expected: String, actual: String)

        public var description: String {
            switch self {
            case .dynamicsMismatch(let expected, let actual):
                return "dynamics: expected \(expected), got \(actual)"
            case .wedgeMismatch(let expected, let actual):
                return "wedge: expected \(expected ?? "none"), got \(actual ?? "none")"
            case .tempoMismatch(let expected, let actual):
                let expectedStr = expected.map { String(format: "%.1f", $0) } ?? "nil"
                let actualStr = actual.map { String(format: "%.1f", $0) } ?? "nil"
                return "tempo: expected \(expectedStr), got \(actualStr)"
            case .wordsMismatch(let expected, let actual):
                return "words: expected \(expected ?? "nil"), got \(actual ?? "nil")"
            case .typeMismatch(let expected, let actual):
                return "type: expected \(expected), got \(actual)"
            }
        }
    }

    /// Side of a barline.
    public enum BarlineSide: String, Sendable {
        case left
        case right
    }

    /// Differences in barlines.
    public enum BarlineDiff: Sendable, CustomStringConvertible {
        case styleMismatch(expected: String?, actual: String?)
        case repeatMismatch(expected: String?, actual: String?)
        case endingMismatch(expected: String?, actual: String?)

        public var description: String {
            switch self {
            case .styleMismatch(let expected, let actual):
                return "style: expected \(expected ?? "none"), got \(actual ?? "none")"
            case .repeatMismatch(let expected, let actual):
                return "repeat: expected \(expected ?? "none"), got \(actual ?? "none")"
            case .endingMismatch(let expected, let actual):
                return "ending: expected \(expected ?? "none"), got \(actual ?? "none")"
            }
        }
    }
}

// MARK: - Diff Builder

extension ScoreDiff {
    /// Builder for accumulating differences.
    public final class Builder {
        private var differences: [Difference] = []

        public init() {}

        public func add(_ difference: Difference) {
            differences.append(difference)
        }

        public func addAll(_ diffs: [Difference]) {
            differences.append(contentsOf: diffs)
        }

        public var isEmpty: Bool {
            differences.isEmpty
        }

        public var count: Int {
            differences.count
        }

        public func build() -> ScoreDiff {
            ScoreDiff(differences: differences)
        }
    }
}
