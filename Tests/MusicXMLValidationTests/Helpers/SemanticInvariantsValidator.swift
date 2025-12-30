import Foundation
import MusicNotationCore

/// Validates semantic invariants that must hold for any well-formed musical score.
public struct SemanticInvariantsValidator {

    // MARK: - Types

    /// Result of validation.
    public struct ValidationResult: Sendable {
        public var violations: [Violation]
        public var passed: Bool { violations.isEmpty }

        public init(violations: [Violation] = []) {
            self.violations = violations
        }
    }

    /// A semantic invariant violation.
    public enum Violation: CustomStringConvertible, Sendable {
        /// Measure duration doesn't match time signature.
        case measureDurationMismatch(
            partIndex: Int,
            measureNumber: String,
            voice: Int,
            expected: Rational,
            actual: Rational
        )

        /// Tie start pitch doesn't match tie stop pitch.
        case tiePitchMismatch(
            partIndex: Int,
            measureNumber: String,
            startPitch: String,
            endPitch: String
        )

        /// Tie start without corresponding stop.
        case orphanedTieStart(
            partIndex: Int,
            measureNumber: String,
            pitch: String,
            voice: Int
        )

        /// Tie stop without corresponding start.
        case orphanedTieStop(
            partIndex: Int,
            measureNumber: String,
            pitch: String,
            voice: Int
        )

        /// Beam group has invalid structure.
        case beamContinuityError(
            partIndex: Int,
            measureNumber: String,
            level: Int,
            message: String
        )

        /// Chord tones have inconsistent voice/staff.
        case chordVoiceMismatch(
            partIndex: Int,
            measureNumber: String,
            noteIndex: Int,
            expectedVoice: Int,
            actualVoice: Int
        )

        /// Invalid tuplet ratio.
        case invalidTupletRatio(
            partIndex: Int,
            measureNumber: String,
            actual: Int,
            normal: Int
        )

        /// Staff number out of valid range.
        case invalidStaffNumber(
            partIndex: Int,
            measureNumber: String,
            staff: Int,
            maxStaff: Int
        )

        /// Note has both pitch and is marked as rest.
        case inconsistentNoteType(
            partIndex: Int,
            measureNumber: String,
            noteIndex: Int,
            message: String
        )

        public var description: String {
            switch self {
            case .measureDurationMismatch(let part, let measure, let voice, let expected, let actual):
                return "Part \(part), measure \(measure), voice \(voice): duration mismatch - expected \(expected), got \(actual)"

            case .tiePitchMismatch(let part, let measure, let start, let end):
                return "Part \(part), measure \(measure): tie pitch mismatch - start \(start), end \(end)"

            case .orphanedTieStart(let part, let measure, let pitch, let voice):
                return "Part \(part), measure \(measure): orphaned tie start on \(pitch) in voice \(voice)"

            case .orphanedTieStop(let part, let measure, let pitch, let voice):
                return "Part \(part), measure \(measure): orphaned tie stop on \(pitch) in voice \(voice)"

            case .beamContinuityError(let part, let measure, let level, let message):
                return "Part \(part), measure \(measure): beam level \(level) - \(message)"

            case .chordVoiceMismatch(let part, let measure, let noteIndex, let expected, let actual):
                return "Part \(part), measure \(measure), note \(noteIndex): chord voice mismatch - expected \(expected), got \(actual)"

            case .invalidTupletRatio(let part, let measure, let actual, let normal):
                return "Part \(part), measure \(measure): invalid tuplet ratio \(actual):\(normal)"

            case .invalidStaffNumber(let part, let measure, let staff, let maxStaff):
                return "Part \(part), measure \(measure): staff \(staff) exceeds max \(maxStaff)"

            case .inconsistentNoteType(let part, let measure, let noteIndex, let message):
                return "Part \(part), measure \(measure), note \(noteIndex): \(message)"
            }
        }
    }

    // MARK: - Properties

    /// Options for validation.
    public struct Options {
        /// Whether to validate measure durations.
        public var validateDurations: Bool = true

        /// Whether to validate tie matching.
        public var validateTies: Bool = true

        /// Whether to validate beam continuity.
        public var validateBeams: Bool = true

        /// Whether to validate chord coherence.
        public var validateChords: Bool = true

        /// Whether to validate tuplet ratios.
        public var validateTuplets: Bool = true

        /// Whether to validate staff numbers.
        public var validateStaffNumbers: Bool = true

        /// Tolerance for duration comparison (in divisions).
        public var durationTolerance: Int = 0

        public static let all = Options()

        public static let durationOnly = Options(
            validateDurations: true,
            validateTies: false,
            validateBeams: false,
            validateChords: false,
            validateTuplets: false,
            validateStaffNumbers: false
        )

        public init(
            validateDurations: Bool = true,
            validateTies: Bool = true,
            validateBeams: Bool = true,
            validateChords: Bool = true,
            validateTuplets: Bool = true,
            validateStaffNumbers: Bool = true,
            durationTolerance: Int = 0
        ) {
            self.validateDurations = validateDurations
            self.validateTies = validateTies
            self.validateBeams = validateBeams
            self.validateChords = validateChords
            self.validateTuplets = validateTuplets
            self.validateStaffNumbers = validateStaffNumbers
            self.durationTolerance = durationTolerance
        }
    }

    private let options: Options

    // MARK: - Initialization

    public init(options: Options = .all) {
        self.options = options
    }

    // MARK: - Public Methods

    /// Validates all semantic invariants in a score.
    public func validate(_ score: Score) -> ValidationResult {
        var violations: [Violation] = []

        for (partIndex, part) in score.parts.enumerated() {
            let partViolations = validatePart(part, partIndex: partIndex)
            violations.append(contentsOf: partViolations)
        }

        return ValidationResult(violations: violations)
    }

    // MARK: - Part Validation

    private func validatePart(_ part: Part, partIndex: Int) -> [Violation] {
        var violations: [Violation] = []
        var currentDivisions: Int = 1
        var currentTimeSignature: TimeSignature?
        let maxStaff = part.staffCount

        // Track pending ties across measures
        var pendingTies: [TieKey: PendingTie] = [:]

        for measure in part.measures {
            // Update divisions if present
            if let divisions = measure.attributes?.divisions {
                currentDivisions = divisions
            }

            // Update time signature if present
            if let time = measure.attributes?.timeSignatures.first {
                currentTimeSignature = time
            }

            // Validate measure
            let measureViolations = validateMeasure(
                measure,
                partIndex: partIndex,
                divisions: currentDivisions,
                timeSignature: currentTimeSignature,
                maxStaff: maxStaff,
                pendingTies: &pendingTies
            )
            violations.append(contentsOf: measureViolations)
        }

        // Report any remaining pending ties as orphaned
        if options.validateTies {
            for (_, pending) in pendingTies {
                violations.append(.orphanedTieStart(
                    partIndex: partIndex,
                    measureNumber: pending.measureNumber,
                    pitch: pending.pitchDescription,
                    voice: pending.voice
                ))
            }
        }

        return violations
    }

    // MARK: - Measure Validation

    private func validateMeasure(
        _ measure: Measure,
        partIndex: Int,
        divisions: Int,
        timeSignature: TimeSignature?,
        maxStaff: Int,
        pendingTies: inout [TieKey: PendingTie]
    ) -> [Violation] {
        var violations: [Violation] = []

        let notes = measure.notes

        // Validate measure durations per voice
        if options.validateDurations, let time = timeSignature {
            let durationViolations = validateMeasureDurations(
                measure: measure,
                partIndex: partIndex,
                divisions: divisions,
                timeSignature: time
            )
            violations.append(contentsOf: durationViolations)
        }

        // Validate ties
        if options.validateTies {
            let tieViolations = validateTies(
                notes: notes,
                partIndex: partIndex,
                measureNumber: measure.number,
                pendingTies: &pendingTies
            )
            violations.append(contentsOf: tieViolations)
        }

        // Validate beams
        if options.validateBeams {
            let beamViolations = validateBeams(
                notes: notes,
                partIndex: partIndex,
                measureNumber: measure.number
            )
            violations.append(contentsOf: beamViolations)
        }

        // Validate chords
        if options.validateChords {
            let chordViolations = validateChords(
                notes: notes,
                partIndex: partIndex,
                measureNumber: measure.number
            )
            violations.append(contentsOf: chordViolations)
        }

        // Validate tuplets
        if options.validateTuplets {
            let tupletViolations = validateTuplets(
                notes: notes,
                partIndex: partIndex,
                measureNumber: measure.number
            )
            violations.append(contentsOf: tupletViolations)
        }

        // Validate staff numbers
        if options.validateStaffNumbers && maxStaff > 0 {
            let staffViolations = validateStaffNumbers(
                notes: notes,
                partIndex: partIndex,
                measureNumber: measure.number,
                maxStaff: maxStaff
            )
            violations.append(contentsOf: staffViolations)
        }

        return violations
    }

    // MARK: - Duration Validation

    private func validateMeasureDurations(
        measure: Measure,
        partIndex: Int,
        divisions: Int,
        timeSignature: TimeSignature
    ) -> [Violation] {
        var violations: [Violation] = []

        // Calculate expected measure duration in divisions
        guard let beats = Int(timeSignature.beats),
              let beatType = Int(timeSignature.beatType) else {
            // Complex time signatures (like 3+2/8) - skip validation
            return []
        }

        // Expected duration = beats * (divisions * 4 / beatType)
        // e.g., 4/4: 4 * (divisions * 4 / 4) = 4 * divisions
        // e.g., 3/4: 3 * (divisions * 4 / 4) = 3 * divisions
        // e.g., 6/8: 6 * (divisions * 4 / 8) = 6 * (divisions / 2) = 3 * divisions
        let expectedDivisionsPerBeat = divisions * 4 / beatType
        let expectedTotalDivisions = beats * expectedDivisionsPerBeat

        // Group notes by voice and calculate durations
        var voiceDurations: [Int: Int] = [:]
        var currentPosition: [Int: Int] = [:]

        for element in measure.elements {
            switch element {
            case .note(let note):
                // Skip grace notes (0 duration)
                if note.isGraceNote { continue }

                // Skip chord tones (share duration with previous)
                if note.isChordTone { continue }

                let voice = note.voice
                let duration = note.durationDivisions

                voiceDurations[voice, default: 0] += duration
                currentPosition[voice, default: 0] += duration

            case .backup(let backup):
                // Backup affects all voices - reset to earlier position
                for voice in currentPosition.keys {
                    currentPosition[voice, default: 0] -= backup.duration
                }

            case .forward(let forward):
                if let voice = forward.voice {
                    voiceDurations[voice, default: 0] += forward.duration
                    currentPosition[voice, default: 0] += forward.duration
                }

            default:
                break
            }
        }

        // Check each voice's duration
        for (voice, actualDuration) in voiceDurations {
            // Allow for implicit measures (pickup) which may be shorter
            if measure.implicit { continue }

            let difference = abs(actualDuration - expectedTotalDivisions)
            if difference > options.durationTolerance {
                let expected = Rational(expectedTotalDivisions, divisions)
                let actual = Rational(actualDuration, divisions)
                violations.append(.measureDurationMismatch(
                    partIndex: partIndex,
                    measureNumber: measure.number,
                    voice: voice,
                    expected: expected,
                    actual: actual
                ))
            }
        }

        return violations
    }

    // MARK: - Tie Validation

    private struct TieKey: Hashable {
        let pitch: String
        let voice: Int
        let staff: Int
    }

    private struct PendingTie {
        let measureNumber: String
        let pitchDescription: String
        let voice: Int
    }

    private func validateTies(
        notes: [Note],
        partIndex: Int,
        measureNumber: String,
        pendingTies: inout [TieKey: PendingTie]
    ) -> [Violation] {
        var violations: [Violation] = []

        for note in notes {
            guard let pitch = note.pitch else { continue }
            let pitchDesc = pitchDescription(pitch)
            let key = TieKey(pitch: pitchDesc, voice: note.voice, staff: note.staff)

            for tie in note.ties {
                switch tie.type {
                case .start:
                    // Check for duplicate starts
                    if pendingTies[key] != nil {
                        // Already have a pending tie - this might be re-articulation
                    }
                    pendingTies[key] = PendingTie(
                        measureNumber: measureNumber,
                        pitchDescription: pitchDesc,
                        voice: note.voice
                    )

                case .stop:
                    if let pending = pendingTies.removeValue(forKey: key) {
                        // Verify pitch matches
                        if pending.pitchDescription != pitchDesc {
                            violations.append(.tiePitchMismatch(
                                partIndex: partIndex,
                                measureNumber: measureNumber,
                                startPitch: pending.pitchDescription,
                                endPitch: pitchDesc
                            ))
                        }
                    } else {
                        // Orphaned stop
                        violations.append(.orphanedTieStop(
                            partIndex: partIndex,
                            measureNumber: measureNumber,
                            pitch: pitchDesc,
                            voice: note.voice
                        ))
                    }

                case .continue, .letRing:
                    // Continue is valid if there's a pending tie
                    break
                }
            }
        }

        return violations
    }

    private func pitchDescription(_ pitch: Pitch) -> String {
        var desc = pitch.step.rawValue
        if pitch.alter > 0 {
            desc += "#"
        } else if pitch.alter < 0 {
            desc += "b"
        }
        desc += "\(pitch.octave)"
        return desc
    }

    // MARK: - Beam Validation

    private func validateBeams(
        notes: [Note],
        partIndex: Int,
        measureNumber: String
    ) -> [Violation] {
        var violations: [Violation] = []

        // Track beam state per level per voice
        var beamState: [Int: [Int: BeamState]] = [:]  // voice -> level -> state

        for note in notes {
            guard !note.beams.isEmpty else { continue }

            let voice = note.voice

            for beam in note.beams {
                let level = beam.number
                let beamType = beam.value

                if beamState[voice] == nil {
                    beamState[voice] = [:]
                }

                let currentState = beamState[voice]?[level] ?? .none

                switch beamType {
                case .begin:
                    if currentState == .inBeam {
                        violations.append(.beamContinuityError(
                            partIndex: partIndex,
                            measureNumber: measureNumber,
                            level: level,
                            message: "begin without end"
                        ))
                    }
                    beamState[voice]?[level] = .inBeam

                case .continue:
                    if currentState != .inBeam {
                        violations.append(.beamContinuityError(
                            partIndex: partIndex,
                            measureNumber: measureNumber,
                            level: level,
                            message: "continue without begin"
                        ))
                    }

                case .end:
                    if currentState != .inBeam {
                        violations.append(.beamContinuityError(
                            partIndex: partIndex,
                            measureNumber: measureNumber,
                            level: level,
                            message: "end without begin"
                        ))
                    }
                    beamState[voice]?[level] = BeamState.none

                case .forwardHook, .backwardHook:
                    // Hooks are valid within beams
                    break
                }

                // Check for contiguous levels (level 2 requires level 1)
                if level > 1 {
                    let lowerLevelState = beamState[voice]?[level - 1] ?? BeamState.none
                    if lowerLevelState != .inBeam && beamType != .end {
                        violations.append(.beamContinuityError(
                            partIndex: partIndex,
                            measureNumber: measureNumber,
                            level: level,
                            message: "level \(level) without level \(level - 1)"
                        ))
                    }
                }
            }
        }

        // Check for unclosed beams at end of measure
        for (_, levels) in beamState {
            for (level, state) in levels {
                if state == .inBeam {
                    violations.append(.beamContinuityError(
                        partIndex: partIndex,
                        measureNumber: measureNumber,
                        level: level,
                        message: "beam not closed at end of measure"
                    ))
                }
            }
        }

        return violations
    }

    private enum BeamState {
        case none
        case inBeam
    }

    // MARK: - Chord Validation

    private func validateChords(
        notes: [Note],
        partIndex: Int,
        measureNumber: String
    ) -> [Violation] {
        var violations: [Violation] = []

        var previousNote: Note?

        for (index, note) in notes.enumerated() {
            if note.isChordTone {
                guard let prev = previousNote else {
                    violations.append(.inconsistentNoteType(
                        partIndex: partIndex,
                        measureNumber: measureNumber,
                        noteIndex: index,
                        message: "chord tone without preceding note"
                    ))
                    continue
                }

                // Chord tones should share voice and staff with previous
                if note.voice != prev.voice {
                    violations.append(.chordVoiceMismatch(
                        partIndex: partIndex,
                        measureNumber: measureNumber,
                        noteIndex: index,
                        expectedVoice: prev.voice,
                        actualVoice: note.voice
                    ))
                }
            }

            previousNote = note
        }

        return violations
    }

    // MARK: - Tuplet Validation

    private func validateTuplets(
        notes: [Note],
        partIndex: Int,
        measureNumber: String
    ) -> [Violation] {
        var violations: [Violation] = []

        for note in notes {
            if let tuplet = note.timeModification {
                // Basic sanity checks
                if tuplet.actual <= 0 || tuplet.normal <= 0 {
                    violations.append(.invalidTupletRatio(
                        partIndex: partIndex,
                        measureNumber: measureNumber,
                        actual: tuplet.actual,
                        normal: tuplet.normal
                    ))
                }

                // Check for unusual ratios that might indicate errors
                let ratio = Double(tuplet.actual) / Double(tuplet.normal)
                if ratio > 10 || ratio < 0.1 {
                    violations.append(.invalidTupletRatio(
                        partIndex: partIndex,
                        measureNumber: measureNumber,
                        actual: tuplet.actual,
                        normal: tuplet.normal
                    ))
                }
            }
        }

        return violations
    }

    // MARK: - Staff Number Validation

    private func validateStaffNumbers(
        notes: [Note],
        partIndex: Int,
        measureNumber: String,
        maxStaff: Int
    ) -> [Violation] {
        var violations: [Violation] = []

        for note in notes {
            if note.staff < 1 || note.staff > maxStaff {
                violations.append(.invalidStaffNumber(
                    partIndex: partIndex,
                    measureNumber: measureNumber,
                    staff: note.staff,
                    maxStaff: maxStaff
                ))
            }
        }

        return violations
    }
}

// MARK: - Report Generation

extension SemanticInvariantsValidator.ValidationResult {
    /// Generates a human-readable report.
    public func report() -> String {
        if passed {
            return "All semantic invariants validated successfully."
        }

        var lines: [String] = [
            "Semantic Invariant Violations: \(violations.count)",
            String(repeating: "-", count: 50)
        ]

        for (index, violation) in violations.enumerated() {
            lines.append("\(index + 1). \(violation.description)")
        }

        return lines.joined(separator: "\n")
    }
}
