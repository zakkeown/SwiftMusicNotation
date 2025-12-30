import Foundation
import MusicNotationCore
import MusicNotationPlayback

/// Compares MIDI events between two scores for playback equivalence.
public struct MIDIComparator: Sendable {

    // MARK: - Types

    /// A simplified MIDI event for comparison.
    public struct MIDIEvent: Equatable, Sendable {
        public let time: Double  // In seconds
        public let type: EventType
        public let pitch: UInt8?
        public let velocity: UInt8?
        public let channel: UInt8?

        public enum EventType: Equatable, Sendable {
            case noteOn
            case noteOff
            case programChange
            case controlChange
            case tempo
        }

        public init(time: Double, type: EventType, pitch: UInt8? = nil, velocity: UInt8? = nil, channel: UInt8? = nil) {
            self.time = time
            self.type = type
            self.pitch = pitch
            self.velocity = velocity
            self.channel = channel
        }
    }

    /// Result of comparing two event sequences.
    public struct ComparisonResult: Sendable {
        public var matchedEvents: Int = 0
        public var mismatchedEvents: Int = 0
        public var missingEvents: Int = 0
        public var extraEvents: Int = 0
        public var mismatches: [Mismatch] = []

        public var passed: Bool {
            mismatchedEvents == 0 && missingEvents == 0 && extraEvents == 0
        }

        public var similarity: Double {
            let total = matchedEvents + mismatchedEvents + missingEvents + extraEvents
            guard total > 0 else { return 1.0 }
            return Double(matchedEvents) / Double(total)
        }

        public func report() -> String {
            var lines: [String] = []
            lines.append("MIDI Comparison: \(passed ? "PASSED" : "FAILED")")
            lines.append("  Matched: \(matchedEvents)")
            lines.append("  Mismatched: \(mismatchedEvents)")
            lines.append("  Missing: \(missingEvents)")
            lines.append("  Extra: \(extraEvents)")
            lines.append("  Similarity: \(String(format: "%.1f", similarity * 100))%")

            if !mismatches.isEmpty {
                lines.append("  First mismatches:")
                for mismatch in mismatches.prefix(5) {
                    lines.append("    - \(mismatch)")
                }
            }

            return lines.joined(separator: "\n")
        }
    }

    /// A mismatch between expected and actual events.
    public struct Mismatch: CustomStringConvertible, Sendable {
        public let expected: MIDIEvent?
        public let actual: MIDIEvent?
        public let reason: String

        public var description: String {
            if let exp = expected, let act = actual {
                return "At \(String(format: "%.3f", exp.time))s: \(reason)"
            } else if let exp = expected {
                return "Missing at \(String(format: "%.3f", exp.time))s: \(reason)"
            } else if let act = actual {
                return "Extra at \(String(format: "%.3f", act.time))s: \(reason)"
            } else {
                return reason
            }
        }
    }

    // MARK: - Properties

    /// Time tolerance for matching events (in seconds).
    public var timeTolerance: Double = 0.001

    // MARK: - Initialization

    public init(timeTolerance: Double = 0.001) {
        self.timeTolerance = timeTolerance
    }

    // MARK: - Public Methods

    /// Extracts MIDI events from a score.
    public func extractEvents(from score: Score) throws -> [MIDIEvent] {
        // Extract MIDI events directly from the score
        return extractEventsDirectly(from: score)
    }

    /// Compares two sequences of MIDI events.
    public func compare(_ events1: [MIDIEvent], _ events2: [MIDIEvent]) -> ComparisonResult {
        var result = ComparisonResult()

        // Sort events by time for comparison
        let sorted1 = events1.sorted { $0.time < $1.time }
        let sorted2 = events2.sorted { $0.time < $1.time }

        // Use a greedy matching algorithm
        var matched2: Set<Int> = []

        for event1 in sorted1 {
            var foundMatch = false

            for (index2, event2) in sorted2.enumerated() {
                guard !matched2.contains(index2) else { continue }

                if eventsMatch(event1, event2) {
                    result.matchedEvents += 1
                    matched2.insert(index2)
                    foundMatch = true
                    break
                }
            }

            if !foundMatch {
                result.missingEvents += 1
                result.mismatches.append(Mismatch(
                    expected: event1,
                    actual: nil,
                    reason: "Event not found in second sequence"
                ))
            }
        }

        // Check for extra events
        for (index2, event2) in sorted2.enumerated() {
            if !matched2.contains(index2) {
                result.extraEvents += 1
                result.mismatches.append(Mismatch(
                    expected: nil,
                    actual: event2,
                    reason: "Event not found in first sequence"
                ))
            }
        }

        return result
    }

    /// Compares two scores for MIDI equivalence.
    public func compare(_ score1: Score, _ score2: Score) throws -> ComparisonResult {
        let events1 = try extractEvents(from: score1)
        let events2 = try extractEvents(from: score2)
        return compare(events1, events2)
    }

    // MARK: - Private Methods

    /// Extracts MIDI events directly from score without using ScoreSequencer.
    private func extractEventsDirectly(from score: Score) -> [MIDIEvent] {
        var events: [MIDIEvent] = []

        // Default tempo
        var currentTempo: Double = 120.0
        var quartersPerSecond = currentTempo / 60.0

        for (partIndex, part) in score.parts.enumerated() {
            var currentTime: Double = 0.0
            let channel = UInt8(partIndex % 16)

            // Get divisions from first measure with attributes
            var divisions: Int = 1
            for measure in part.measures {
                if let div = measure.attributes?.divisions, div > 0 {
                    divisions = div
                    break
                }
            }

            for measure in part.measures {
                // Update divisions if changed
                if let div = measure.attributes?.divisions, div > 0 {
                    divisions = div
                }

                // Update tempo from directions
                for element in measure.elements {
                    if case .direction(let direction) = element {
                        if let sound = direction.sound, let tempo = sound.tempo {
                            currentTempo = tempo
                            quartersPerSecond = currentTempo / 60.0
                            events.append(MIDIEvent(
                                time: currentTime,
                                type: .tempo,
                                pitch: nil,
                                velocity: nil,
                                channel: nil
                            ))
                        }
                    }
                }

                for note in measure.notes {
                    // Skip rests
                    guard !note.isRest else {
                        if !note.isChordTone {
                            // Advance time for non-chord rests
                            let durationQuarters = Double(note.durationDivisions) / Double(divisions)
                            currentTime += durationQuarters / quartersPerSecond
                        }
                        continue
                    }

                    // Get MIDI pitch
                    let midiPitch: UInt8
                    if let pitch = note.pitch {
                        midiPitch = pitchToMIDI(pitch)
                    } else if let unpitched = note.unpitched {
                        midiPitch = unpitchedToMIDI(unpitched)
                    } else {
                        continue
                    }

                    // Calculate duration in seconds
                    let durationQuarters = Double(note.durationDivisions) / Double(divisions)
                    let durationSeconds = durationQuarters / quartersPerSecond

                    // Default velocity
                    let velocity: UInt8 = 80

                    // Note on
                    events.append(MIDIEvent(
                        time: currentTime,
                        type: .noteOn,
                        pitch: midiPitch,
                        velocity: velocity,
                        channel: channel
                    ))

                    // Note off
                    events.append(MIDIEvent(
                        time: currentTime + durationSeconds,
                        type: .noteOff,
                        pitch: midiPitch,
                        velocity: 0,
                        channel: channel
                    ))

                    // Advance time only for non-chord notes
                    if !note.isChordTone {
                        currentTime += durationSeconds
                    }
                }
            }
        }

        return events.sorted { $0.time < $1.time }
    }

    private func eventsMatch(_ e1: MIDIEvent, _ e2: MIDIEvent) -> Bool {
        // Time must be within tolerance
        guard abs(e1.time - e2.time) <= timeTolerance else { return false }

        // Type must match
        guard e1.type == e2.type else { return false }

        // For note events, pitch must match
        if e1.type == .noteOn || e1.type == .noteOff {
            guard e1.pitch == e2.pitch else { return false }
        }

        return true
    }

    private func pitchToMIDI(_ pitch: Pitch) -> UInt8 {
        let stepValue: Int
        switch pitch.step {
        case .c: stepValue = 0
        case .d: stepValue = 2
        case .e: stepValue = 4
        case .f: stepValue = 5
        case .g: stepValue = 7
        case .a: stepValue = 9
        case .b: stepValue = 11
        }

        // MIDI note number: (octave + 1) * 12 + step + alter
        let midi = (pitch.octave + 1) * 12 + stepValue + Int(pitch.alter)
        return UInt8(clamping: midi)
    }

    private func unpitchedToMIDI(_ unpitched: UnpitchedNote) -> UInt8 {
        // Map unpitched notes to General MIDI drum map
        // Default to bass drum if no specific mapping
        return UInt8(clamping: 35 + unpitched.displayOctave * 12 + unpitched.displayStep.midiOffset)
    }
}

// MARK: - Helper Extension

private extension PitchStep {
    var midiOffset: Int {
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
}
