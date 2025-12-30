import Foundation
import MusicNotationCore

/// Tracks slur start/stop pairs during MusicXML import.
///
/// `SlurTracker` matches slur start and stop events by their `number` attribute,
/// along with voice and staff context. MusicXML uses numbered slurs (1-6) to support
/// overlapping slurs on the same voice/staff.
///
/// ## Slur Matching
///
/// Slurs are matched using a composite key of:
/// - **number**: The slur number attribute (1-6, defaults to 1)
/// - **voice**: The voice number of the note
/// - **staff**: The staff number of the note
///
/// This allows multiple concurrent slurs in the same voice (nested or overlapping)
/// to be tracked independently.
///
/// ## Cross-Measure Slurs
///
/// Slurs commonly span multiple measures. The tracker maintains state across measures
/// until a matching stop event is encountered or `finalize()` is called.
///
/// ## Usage
///
/// ```swift
/// let tracker = SlurTracker()
/// for (index, note) in notes.enumerated() {
///     let slurs = note.notations.compactMap { $0.slur }
///     tracker.process(slurs: slurs, noteIndex: index,
///                     measureIndex: measureIdx, voice: note.voice, staff: note.staff)
/// }
/// tracker.finalize()
/// let slurSpans = tracker.completedSlurs
/// ```
///
/// ## Warnings
///
/// Orphaned slurs (start without stop, or stop without start) generate warnings
/// accessible via the ``warnings`` property.
///
/// - SeeAlso: ``TieTracker`` for tie pair tracking (matched by pitch)
/// - SeeAlso: ``BeamGrouper`` for beam group tracking
/// - SeeAlso: ``SlurSpan`` for the output model
public final class SlurTracker {
    /// Pending slur starts keyed by (number, voice, staff).
    private var pendingSlurs: [SlurKey: SlurStart] = [:]

    /// Completed slur spans connecting start and stop notes.
    public private(set) var completedSlurs: [SlurSpan] = []

    /// Warnings for orphaned or mismatched slurs.
    public private(set) var warnings: [String] = []

    public init() {}

    /// Processes slur notations from a note, updating internal state.
    ///
    /// - Parameters:
    ///   - slurs: The slur notations extracted from note's notations
    ///   - noteIndex: The index of this note within its measure
    ///   - measureIndex: The index of the containing measure
    ///   - voice: The voice number for this note
    ///   - staff: The staff number for this note
    public func process(slurs: [SlurNotation], noteIndex: Int, measureIndex: Int, voice: Int, staff: Int) {
        for slur in slurs {
            let key = SlurKey(number: slur.number, voice: voice, staff: staff)

            switch slur.type {
            case .start:
                pendingSlurs[key] = SlurStart(
                    noteIndex: noteIndex,
                    measureIndex: measureIndex,
                    placement: slur.placement
                )

            case .stop:
                if let start = pendingSlurs.removeValue(forKey: key) {
                    completedSlurs.append(SlurSpan(
                        number: slur.number,
                        startNoteIndex: start.noteIndex,
                        startMeasureIndex: start.measureIndex,
                        stopNoteIndex: noteIndex,
                        stopMeasureIndex: measureIndex,
                        placement: start.placement ?? slur.placement
                    ))
                } else {
                    warnings.append("Slur stop (number=\(slur.number)) without matching start at measure \(measureIndex)")
                }

            case .continue:
                // Continue extends the slur
                break
            }
        }
    }

    /// Finalizes tracking and reports orphaned slurs.
    public func finalize() {
        for (key, start) in pendingSlurs {
            warnings.append("Orphaned slur start (number=\(key.number)) at measure \(start.measureIndex)")
        }
        pendingSlurs.removeAll()
    }

    /// Resets the tracker.
    public func reset() {
        pendingSlurs.removeAll()
        completedSlurs.removeAll()
        warnings.removeAll()
    }
}

// MARK: - Supporting Types

private struct SlurKey: Hashable {
    let number: Int
    let voice: Int
    let staff: Int
}

private struct SlurStart {
    let noteIndex: Int
    let measureIndex: Int
    let placement: Placement?
}

/// A completed slur span.
public struct SlurSpan: Sendable {
    public let number: Int
    public let startNoteIndex: Int
    public let startMeasureIndex: Int
    public let stopNoteIndex: Int
    public let stopMeasureIndex: Int
    public let placement: Placement?
}
