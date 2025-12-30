import Foundation
import MusicNotationCore

/// Tracks tie start/stop pairs during MusicXML import, matching by pitch.
///
/// `TieTracker` correlates tie start and stop events across notes by matching
/// on the exact pitch (including alteration), voice, and staff. Unlike slurs which
/// use a number attribute, ties are semantically bound to specific pitches.
///
/// ## Tie Matching
///
/// Ties are matched using a composite key of:
/// - **pitch**: The exact pitch including step, octave, and alteration
/// - **voice**: The voice number of the note
/// - **staff**: The staff number of the note
///
/// This ensures that in chords, each pitch's tie is tracked independently.
///
/// ## Continue Type
///
/// MusicXML's `continue` tie type indicates a note that both stops one tie and
/// starts another (common in syncopations across barlines). The tracker handles
/// this by completing the pending tie and starting a new one.
///
/// ## Let Ring
///
/// Guitar notation uses `let-ring` ties that start but may not explicitly stop.
/// These are tracked as starts and may appear as orphaned warnings.
///
/// ## Usage
///
/// ```swift
/// let tracker = TieTracker()
/// for (index, note) in notes.enumerated() {
///     tracker.process(note: note, noteIndex: index, measureIndex: measureIdx)
/// }
/// tracker.finalize()
/// let tiePairs = tracker.completedTies
/// ```
///
/// - SeeAlso: ``SlurTracker`` for slur span tracking (matched by number)
/// - SeeAlso: ``BeamGrouper`` for beam group tracking
/// - SeeAlso: ``TiePair`` for the output model
public final class TieTracker {
    /// Pending tie starts keyed by (pitch, voice, staff).
    private var pendingTies: [TieKey: TieStart] = [:]

    /// Completed tie pairs connecting start and stop notes.
    public private(set) var completedTies: [TiePair] = []

    /// Warnings for orphaned or mismatched ties.
    public private(set) var warnings: [String] = []

    public init() {}

    /// Processes a note that may start or stop ties.
    ///
    /// Only pitched notes are processed; rests and unpitched notes are ignored.
    /// Handles all tie types: start, stop, continue, and let-ring.
    ///
    /// - Parameters:
    ///   - note: The note to process (extracts pitch and ties from it)
    ///   - noteIndex: The index of this note within its measure
    ///   - measureIndex: The index of the containing measure
    public func process(note: Note, noteIndex: Int, measureIndex: Int) {
        guard case .pitched(let pitch) = note.noteType else { return }

        let key = TieKey(pitch: pitch, voice: note.voice, staff: note.staff)

        for tie in note.ties {
            switch tie.type {
            case .start:
                pendingTies[key] = TieStart(
                    noteIndex: noteIndex,
                    measureIndex: measureIndex,
                    pitch: pitch
                )

            case .stop:
                if let start = pendingTies.removeValue(forKey: key) {
                    completedTies.append(TiePair(
                        startNoteIndex: start.noteIndex,
                        startMeasureIndex: start.measureIndex,
                        stopNoteIndex: noteIndex,
                        stopMeasureIndex: measureIndex,
                        pitch: pitch
                    ))
                } else {
                    warnings.append("Tie stop without matching start for \(pitch) at measure \(measureIndex)")
                }

            case .continue:
                // Continue means both stop and start
                if let start = pendingTies.removeValue(forKey: key) {
                    completedTies.append(TiePair(
                        startNoteIndex: start.noteIndex,
                        startMeasureIndex: start.measureIndex,
                        stopNoteIndex: noteIndex,
                        stopMeasureIndex: measureIndex,
                        pitch: pitch
                    ))
                }
                pendingTies[key] = TieStart(
                    noteIndex: noteIndex,
                    measureIndex: measureIndex,
                    pitch: pitch
                )

            case .letRing:
                // Let ring - treat as start
                pendingTies[key] = TieStart(
                    noteIndex: noteIndex,
                    measureIndex: measureIndex,
                    pitch: pitch
                )
            }
        }
    }

    /// Finalizes tracking and reports orphaned ties.
    public func finalize() {
        for (key, start) in pendingTies {
            warnings.append("Orphaned tie start for \(key.pitch) at measure \(start.measureIndex)")
        }
        pendingTies.removeAll()
    }

    /// Resets the tracker.
    public func reset() {
        pendingTies.removeAll()
        completedTies.removeAll()
        warnings.removeAll()
    }
}

// MARK: - Supporting Types

private struct TieKey: Hashable {
    let pitch: Pitch
    let voice: Int
    let staff: Int
}

private struct TieStart {
    let noteIndex: Int
    let measureIndex: Int
    let pitch: Pitch
}

/// A completed tie pair.
public struct TiePair: Sendable {
    public let startNoteIndex: Int
    public let startMeasureIndex: Int
    public let stopNoteIndex: Int
    public let stopMeasureIndex: Int
    public let pitch: Pitch
}
