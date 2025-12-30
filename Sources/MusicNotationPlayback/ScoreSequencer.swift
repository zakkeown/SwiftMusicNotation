import Foundation
import MusicNotationCore

/// Converts a Score into timed playback events for MIDI synthesis.
///
/// `ScoreSequencer` is the core component that transforms musical notation into a timeline
/// of discrete MIDI events. It processes the score structure, handles timing calculations,
/// and produces events that can be consumed by ``MIDISynthesizer`` or exported as MIDI files.
///
/// ## Conversion Process
///
/// The sequencer processes the score in several stages:
/// 1. **Part Processing**: Each part is assigned a MIDI channel (percussion uses channel 10)
/// 2. **Tempo Tracking**: Tempo changes from direction elements update timing calculations
/// 3. **Note Conversion**: Notes are converted to note-on/note-off pairs with timing
/// 4. **Tie Handling**: Tied notes are merged (no re-trigger on tie continuation)
///
/// ## Timing Calculation
///
/// Musical timing is converted to absolute seconds using:
/// - **Divisions**: MusicXML's division unit (divisions per quarter note)
/// - **Tempo**: Current BPM from tempo markings
/// - Formula: `seconds = (divisions_value / divisions) * (60 / tempo)`
///
/// ## Usage
///
/// ```swift
/// let sequencer = ScoreSequencer(score: score)
/// try sequencer.buildSequence()
///
/// // During playback loop:
/// let events = sequencer.eventsUpTo(time: currentTime)
/// for event in events {
///     switch event.type {
///     case .noteOn(let note, let velocity, let channel):
///         synthesizer.noteOn(note: note, velocity: velocity, channel: channel)
///     case .noteOff(let note, let channel):
///         synthesizer.noteOff(note: note, channel: channel)
///     // ... handle other events
///     }
/// }
/// ```
///
/// ## Position Seeking
///
/// The sequencer supports seeking to specific musical positions:
///
/// ```swift
/// // Seek to measure 10, beat 1
/// let time = sequencer.timeForPosition(measure: 10, beat: 1.0)
/// sequencer.seek(to: time)
/// ```
///
/// - SeeAlso: ``MIDISynthesizer`` for audio synthesis
/// - SeeAlso: ``PlaybackEngine`` for high-level playback control
/// - SeeAlso: ``InstrumentMapper`` for MIDI program assignment
/// - SeeAlso: ``DynamicsInterpreter`` for velocity calculation
public final class ScoreSequencer: @unchecked Sendable {

    // MARK: - Types

    /// A playback event with timing information.
    public struct PlaybackEvent: Sendable {
        /// Time in seconds from the start.
        public let time: TimeInterval

        /// The event type.
        public let type: EventType

        /// The source element ID (for highlighting).
        public let sourceId: String?
    }

    /// Types of playback events.
    public enum EventType: Sendable {
        case noteOn(note: UInt8, velocity: UInt8, channel: UInt8)
        case noteOff(note: UInt8, channel: UInt8)
        case programChange(program: UInt8, channel: UInt8)
        case controlChange(controller: UInt8, value: UInt8, channel: UInt8)
        case tempoChange(bpm: Double)
    }

    // MARK: - Properties

    /// The score being sequenced.
    public let score: Score

    /// Current tempo in BPM.
    public var tempo: Double = 120.0

    /// Whether the sequence has completed.
    public private(set) var isComplete: Bool = false

    // MARK: - Private Properties

    private var events: [PlaybackEvent] = []
    private var currentEventIndex: Int = 0
    private var startTime: TimeInterval = 0
    private var pausedTime: TimeInterval = 0

    private let instrumentMapper = InstrumentMapper()
    private let dynamicsInterpreter = DynamicsInterpreter()

    // MARK: - Initialization

    public init(score: Score) {
        self.score = score
    }

    // MARK: - Public Methods

    /// Builds the event sequence from the score.
    public func buildSequence() throws {
        events.removeAll()
        currentEventIndex = 0
        isComplete = false

        // Process each part
        for (partIndex, part) in score.parts.enumerated() {
            // Use channel 10 (index 9) for percussion parts
            let channel: UInt8
            if instrumentMapper.isPercussionPart(part) {
                channel = 9  // MIDI channel 10 (0-indexed as 9)
            } else {
                // Avoid channel 10 for melodic instruments
                var ch = UInt8(partIndex % 16)
                if ch == 9 {
                    ch = 10
                }
                channel = ch
            }

            // Set up instrument (only for non-percussion parts)
            if !instrumentMapper.isPercussionPart(part) {
                let program = instrumentMapper.midiProgram(for: part)
                events.append(PlaybackEvent(
                    time: 0,
                    type: .programChange(program: program, channel: channel),
                    sourceId: part.id
                ))
            }

            // Process measures
            try processPart(part, channel: channel)
        }

        // Sort events by time
        events.sort { $0.time < $1.time }
    }

    /// Resets the sequencer to the beginning.
    public func reset() {
        currentEventIndex = 0
        isComplete = false
        startTime = 0
        pausedTime = 0
    }

    /// Seeks to a specific time position.
    /// - Parameter time: Time in seconds.
    public func seek(to time: TimeInterval) {
        startTime = -time
        currentEventIndex = events.firstIndex { $0.time >= time } ?? events.count
        isComplete = currentEventIndex >= events.count
    }

    /// Returns events up to the specified time.
    /// - Parameter time: Current playback time.
    /// - Returns: Array of events to process.
    public func eventsUpTo(time: TimeInterval) -> [PlaybackEvent] {
        var result: [PlaybackEvent] = []

        while currentEventIndex < events.count {
            let event = events[currentEventIndex]

            if event.time <= time {
                result.append(event)
                currentEventIndex += 1
            } else {
                break
            }
        }

        if currentEventIndex >= events.count {
            isComplete = true
        }

        return result
    }

    /// Calculates the time for a given position.
    /// - Parameters:
    ///   - measure: Measure number (1-based).
    ///   - beat: Beat within the measure (1-based).
    /// - Returns: Time in seconds.
    public func timeForPosition(measure: Int, beat: Double) -> TimeInterval {
        // Calculate cumulative time to reach this position
        var time: TimeInterval = 0
        var currentTempo = tempo
        var currentDivisions = 1

        guard let firstPart = score.parts.first else { return 0 }

        for (index, scoreMeasure) in firstPart.measures.enumerated() {
            let measureNumber = index + 1

            // Update divisions if specified
            if let divisions = scoreMeasure.attributes?.divisions {
                currentDivisions = divisions
            }

            // Check for tempo changes in this measure
            for element in scoreMeasure.elements {
                if case .direction(let direction) = element,
                   let sound = direction.sound, let newTempo = sound.tempo {
                    currentTempo = newTempo
                }
            }

            if measureNumber == measure {
                // Calculate time for partial measure
                let beatsPerMeasure = beatsInMeasure(scoreMeasure, divisions: currentDivisions)
                let beatFraction = (beat - 1.0) / beatsPerMeasure
                let measureDuration = (60.0 / currentTempo) * beatsPerMeasure
                time += measureDuration * beatFraction
                break
            } else if measureNumber < measure {
                // Add full measure duration
                let beatsPerMeasure = beatsInMeasure(scoreMeasure, divisions: currentDivisions)
                let measureDuration = (60.0 / currentTempo) * beatsPerMeasure
                time += measureDuration
            }
        }

        return time
    }

    // MARK: - Private Methods

    private func processPart(_ part: Part, channel: UInt8) throws {
        var currentTime: TimeInterval = 0
        var currentDivisions = 1
        var currentTempo = tempo
        var currentDynamicVelocity: UInt8 = 80 // mf default

        for measure in part.measures {
            // Update divisions if specified
            if let divisions = measure.attributes?.divisions {
                currentDivisions = divisions
            }

            // Process directions for tempo and dynamics
            for element in measure.elements {
                guard case .direction(let direction) = element else { continue }

                // Check for tempo changes
                if let sound = direction.sound, let newTempo = sound.tempo {
                    currentTempo = newTempo
                    events.append(PlaybackEvent(
                        time: currentTime,
                        type: .tempoChange(bpm: newTempo),
                        sourceId: nil
                    ))
                }

                // Check for dynamics
                for directionType in direction.types {
                    if case .dynamics(let dynamicsDirection) = directionType {
                        if let firstDynamic = dynamicsDirection.values.first {
                            currentDynamicVelocity = dynamicsInterpreter.velocityFor(dynamic: firstDynamic)
                        }
                    }
                }
            }

            // Process elements
            var measurePosition: TimeInterval = 0

            for element in measure.elements {
                switch element {
                case .note(let note):
                    try processNote(
                        note,
                        at: currentTime + measurePosition,
                        channel: channel,
                        part: part,
                        divisions: currentDivisions,
                        tempo: currentTempo,
                        baseVelocity: currentDynamicVelocity
                    )

                    // Advance position (unless it's a chord tone)
                    if !note.isChordTone && !note.isGraceNote {
                        let duration = noteDuration(note, divisions: currentDivisions, tempo: currentTempo)
                        measurePosition += duration
                    }

                case .forward(let forward):
                    let duration = divisionsToDuration(forward.duration, divisions: currentDivisions, tempo: currentTempo)
                    measurePosition += duration

                case .backup(let backup):
                    let duration = divisionsToDuration(backup.duration, divisions: currentDivisions, tempo: currentTempo)
                    measurePosition = max(0, measurePosition - duration)

                default:
                    break
                }
            }

            // Move to next measure
            let measureDuration = beatsInMeasure(measure, divisions: currentDivisions) * (60.0 / currentTempo)
            currentTime += measureDuration
        }
    }

    private func processNote(
        _ note: Note,
        at time: TimeInterval,
        channel: UInt8,
        part: Part,
        divisions: Int,
        tempo: Double,
        baseVelocity: UInt8
    ) throws {
        // Skip rests
        if note.isRest { return }

        // Get MIDI note number
        let midiNote: UInt8
        if let pitch = note.pitch {
            midiNote = UInt8(clamping: pitch.midiNoteNumber)
        } else if let unpitched = note.unpitched {
            // Handle unpitched (percussion) notes
            midiNote = instrumentMapper.midiNoteNumber(for: unpitched, in: part)
        } else {
            return  // No pitch or unpitched data
        }

        // Calculate velocity (considering articulations)
        var velocity = baseVelocity
        velocity = dynamicsInterpreter.adjustVelocityForArticulations(velocity, notations: note.notations)

        // Calculate duration
        let duration = noteDuration(note, divisions: divisions, tempo: tempo)

        // Handle ties - don't re-trigger tied notes
        let hasTieStop = note.ties.contains { $0.type == .stop }
        let hasTieStart = note.ties.contains { $0.type == .start }

        if !hasTieStop {
            // Note on
            events.append(PlaybackEvent(
                time: time,
                type: .noteOn(note: midiNote, velocity: velocity, channel: channel),
                sourceId: note.id.uuidString
            ))
        }

        if !hasTieStart {
            // Note off (only if not tied to next)
            events.append(PlaybackEvent(
                time: time + duration,
                type: .noteOff(note: midiNote, channel: channel),
                sourceId: note.id.uuidString
            ))
        }
    }

    private func noteDuration(_ note: Note, divisions: Int, tempo: Double) -> TimeInterval {
        // Grace notes have zero duration for playback purposes
        if note.isGraceNote { return 0 }

        return divisionsToDuration(note.durationDivisions, divisions: divisions, tempo: tempo)
    }

    private func divisionsToDuration(_ noteDivisions: Int, divisions: Int, tempo: Double) -> TimeInterval {
        // divisions = divisions per quarter note
        // duration in quarter notes = noteDivisions / divisions
        // duration in seconds = (duration in quarter notes) * (60 / tempo)
        let quarterNotes = Double(noteDivisions) / Double(divisions)
        return quarterNotes * (60.0 / tempo)
    }

    private func beatsInMeasure(_ measure: Measure, divisions: Int) -> Double {
        // Get time signature
        if let timeSignatures = measure.attributes?.timeSignatures,
           let time = timeSignatures.first,
           let beats = Int(time.beats),
           let beatType = Int(time.beatType) {
            // Convert to quarter note beats
            // e.g., 4/4 = 4 beats, 6/8 = 3 quarter beats, 3/4 = 3 beats
            return Double(beats) * (4.0 / Double(beatType))
        }

        // Default to 4/4
        return 4.0
    }
}
