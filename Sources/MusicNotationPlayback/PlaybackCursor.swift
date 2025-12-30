import Foundation
import MusicNotationCore

/// Tracks the current playback position and provides position callbacks.
///
/// Maps between time-based playback position and score coordinates
/// (measure number, beat position) for UI synchronization.
public final class PlaybackCursor: @unchecked Sendable {

    // MARK: - Types

    /// Delegate protocol for position updates.
    public protocol Delegate: AnyObject {
        /// Called when the playback position changes.
        func cursorDidMove(to position: PlaybackPosition)

        /// Called when entering a new measure.
        func cursorDidEnterMeasure(_ measureNumber: Int)

        /// Called when playback reaches a specific element.
        func cursorDidReachElement(id: String, in measureNumber: Int)
    }

    // MARK: - Properties

    /// The score being tracked.
    public let score: Score

    /// Delegate for position updates.
    public weak var delegate: Delegate?

    /// Current position in the score.
    public private(set) var currentPosition: PlaybackPosition = .zero

    /// Current tempo in BPM.
    public var tempo: Double = 120.0

    // MARK: - Private Properties

    private var measureTimings: [MeasureTiming] = []
    private var currentMeasureIndex: Int = 0

    private struct MeasureTiming {
        let measureNumber: Int
        let startTime: TimeInterval
        let duration: TimeInterval
        let beatsPerMeasure: Double
        let tempo: Double
    }

    // MARK: - Initialization

    public init(score: Score) {
        self.score = score
        buildTimingMap()
    }

    // MARK: - Public Methods

    /// Resets the cursor to the beginning.
    public func reset() {
        currentPosition = .zero
        currentMeasureIndex = 0
    }

    /// Seeks to a specific position.
    /// - Parameters:
    ///   - measureNumber: Measure number (1-based).
    ///   - beat: Beat within the measure (1-based).
    public func seek(to measureNumber: Int, beat: Double = 1.0) {
        let time = timeForPosition(measure: measureNumber, beat: beat)
        currentPosition = PlaybackPosition(measure: measureNumber, beat: beat, timeInSeconds: time)

        // Update measure index
        currentMeasureIndex = measureTimings.firstIndex { $0.measureNumber == measureNumber } ?? 0
    }

    /// Gets the position at a given time.
    /// - Parameter time: Time in seconds from the start.
    /// - Returns: The position at that time.
    public func positionAt(time: TimeInterval) -> PlaybackPosition {
        // Find the measure containing this time
        var measureTiming: MeasureTiming?

        for (index, timing) in measureTimings.enumerated() {
            if time >= timing.startTime && time < timing.startTime + timing.duration {
                measureTiming = timing

                // Check if we entered a new measure
                if index != currentMeasureIndex {
                    currentMeasureIndex = index
                    delegate?.cursorDidEnterMeasure(timing.measureNumber)
                }
                break
            }
        }

        // Handle end of score
        if measureTiming == nil, let lastTiming = measureTimings.last {
            if time >= lastTiming.startTime + lastTiming.duration {
                return PlaybackPosition(
                    measure: lastTiming.measureNumber,
                    beat: lastTiming.beatsPerMeasure,
                    timeInSeconds: time
                )
            }
        }

        guard let timing = measureTiming else {
            return .zero
        }

        // Calculate beat within the measure
        let timeInMeasure = time - timing.startTime
        let secondsPerBeat = 60.0 / timing.tempo
        let beat = 1.0 + (timeInMeasure / secondsPerBeat)

        let position = PlaybackPosition(
            measure: timing.measureNumber,
            beat: min(beat, timing.beatsPerMeasure),
            timeInSeconds: time
        )

        // Notify delegate if position changed significantly
        if abs(position.beat - currentPosition.beat) > 0.1 ||
           position.measure != currentPosition.measure {
            currentPosition = position
            delegate?.cursorDidMove(to: position)
        }

        return position
    }

    /// Calculates the time for a given position.
    /// - Parameters:
    ///   - measure: Measure number (1-based).
    ///   - beat: Beat within the measure (1-based).
    /// - Returns: Time in seconds.
    public func timeForPosition(measure: Int, beat: Double) -> TimeInterval {
        guard let timing = measureTimings.first(where: { $0.measureNumber == measure }) else {
            return 0
        }

        let secondsPerBeat = 60.0 / timing.tempo
        let beatOffset = beat - 1.0
        return timing.startTime + (beatOffset * secondsPerBeat)
    }

    /// Gets the measure number at a given time.
    /// - Parameter time: Time in seconds.
    /// - Returns: Measure number (1-based).
    public func measureAt(time: TimeInterval) -> Int {
        for timing in measureTimings {
            if time >= timing.startTime && time < timing.startTime + timing.duration {
                return timing.measureNumber
            }
        }
        return measureTimings.last?.measureNumber ?? 1
    }

    /// Gets the total duration of the score.
    /// - Returns: Duration in seconds.
    public func totalDuration() -> TimeInterval {
        guard let lastTiming = measureTimings.last else { return 0 }
        return lastTiming.startTime + lastTiming.duration
    }

    /// Gets the total number of measures.
    /// - Returns: Number of measures.
    public func totalMeasures() -> Int {
        return measureTimings.count
    }

    // MARK: - Private Methods

    private func buildTimingMap() {
        measureTimings.removeAll()

        guard let firstPart = score.parts.first else { return }

        var currentTime: TimeInterval = 0
        var currentTempo = tempo
        var currentBeatsPerMeasure: Double = 4.0
        var currentBeatType: Double = 4.0

        for (index, measure) in firstPart.measures.enumerated() {
            let measureNumber = index + 1

            // Check for tempo changes
            for element in measure.elements {
                if case .direction(let direction) = element,
                   let sound = direction.sound, let newTempo = sound.tempo {
                    currentTempo = newTempo
                }
            }

            // Check for time signature changes
            if let timeSignatures = measure.attributes?.timeSignatures,
               let time = timeSignatures.first,
               let beats = Double(time.beats),
               let beatType = Double(time.beatType) {
                currentBeatsPerMeasure = beats
                currentBeatType = beatType
            }

            // Calculate measure duration
            // Beats per measure in terms of quarter notes
            let quarterNoteBeats = currentBeatsPerMeasure * (4.0 / currentBeatType)
            let measureDuration = quarterNoteBeats * (60.0 / currentTempo)

            measureTimings.append(MeasureTiming(
                measureNumber: measureNumber,
                startTime: currentTime,
                duration: measureDuration,
                beatsPerMeasure: currentBeatsPerMeasure,
                tempo: currentTempo
            ))

            currentTime += measureDuration
        }
    }

    /// Rebuilds timing map with a new tempo.
    public func updateTempo(_ newTempo: Double) {
        tempo = newTempo
        buildTimingMap()
    }
}

// MARK: - PlaybackCursor Extensions

extension PlaybackCursor {

    /// Returns the timing information for a specific measure.
    /// - Parameter measureNumber: The measure number (1-based).
    /// - Returns: A tuple with start time, duration, and beats per measure.
    public func timingForMeasure(_ measureNumber: Int) -> (startTime: TimeInterval, duration: TimeInterval, beats: Double)? {
        guard let timing = measureTimings.first(where: { $0.measureNumber == measureNumber }) else {
            return nil
        }
        return (timing.startTime, timing.duration, timing.beatsPerMeasure)
    }

    /// Returns an array of beat times for a specific measure.
    /// - Parameter measureNumber: The measure number (1-based).
    /// - Returns: Array of times (in seconds) for each beat.
    public func beatTimesForMeasure(_ measureNumber: Int) -> [TimeInterval] {
        guard let timing = measureTimings.first(where: { $0.measureNumber == measureNumber }) else {
            return []
        }

        let secondsPerBeat = 60.0 / timing.tempo
        var times: [TimeInterval] = []

        for beat in 0..<Int(timing.beatsPerMeasure) {
            times.append(timing.startTime + Double(beat) * secondsPerBeat)
        }

        return times
    }

    /// Calculates the percentage progress through the score.
    /// - Returns: Progress from 0.0 to 1.0.
    public func progress() -> Double {
        let total = totalDuration()
        guard total > 0 else { return 0 }
        return currentPosition.timeInSeconds / total
    }
}
