import Foundation
import MusicNotationCore

/// Groups notes by beam connections during MusicXML import.
///
/// `BeamGrouper` implements a state machine that tracks beam start/continue/end events
/// across notes to build complete beam groups. MusicXML encodes beams per-note with
/// level numbers (1 = primary beam, 2 = secondary, etc.), and this class correlates
/// those events into coherent beam groups.
///
/// ## State Machine
///
/// For each beam level, the grouper tracks:
/// - **begin**: Starts a new beam group at that level
/// - **continue**: Adds a note to the active beam at that level
/// - **end**: Completes the beam group and moves it to `completedGroups`
/// - **forward hook** / **backward hook**: Partial beams attached to the previous level
///
/// ## Multi-Level Beams
///
/// Notes can have multiple beam levels (e.g., sixteenth notes have levels 1 and 2).
/// Each level is tracked independently, allowing proper nesting of beam groups.
///
/// ## Usage
///
/// The grouper is typically used during import by processing each note's beam values:
///
/// ```swift
/// let grouper = BeamGrouper()
/// for (index, note) in notes.enumerated() {
///     grouper.process(beams: note.beams, noteIndex: index,
///                     measureIndex: measureIdx, voice: note.voice, staff: note.staff)
/// }
/// grouper.finalize()
/// let beamGroups = grouper.completedGroups
/// ```
///
/// ## Warnings
///
/// Orphaned beams (begin without end, or end without begin) generate warnings
/// but don't cause failures. Partial groups are still completed for resilience.
///
/// - SeeAlso: ``SlurTracker`` for slur span tracking
/// - SeeAlso: ``TieTracker`` for tie pair tracking
/// - SeeAlso: ``BeamGroup`` for the output model
public final class BeamGrouper {
    /// Current beam groups being built, keyed by beam level number.
    private var activeBeams: [Int: BeamGroupBuilder] = [:]

    /// Completed beam groups ready for use.
    public private(set) var completedGroups: [BeamGroup] = []

    /// Warnings generated during processing (orphaned beams, mismatched events).
    public private(set) var warnings: [String] = []

    public init() {}

    /// Processes beam values from a note, updating internal state.
    ///
    /// Call this method for each note in sequence. The method handles begin/continue/end
    /// transitions for each beam level, building up beam groups incrementally.
    ///
    /// - Parameters:
    ///   - beams: The beam values from the note (may include multiple levels)
    ///   - noteIndex: The index of this note within its measure
    ///   - measureIndex: The index of the containing measure
    ///   - voice: The voice number for this note
    ///   - staff: The staff number for this note
    public func process(beams: [BeamValue], noteIndex: Int, measureIndex: Int, voice: Int, staff: Int) {
        guard !beams.isEmpty else { return }

        // Process each beam (each has a number/level)
        for beam in beams {
            let level = beam.number

            switch beam.value {
            case .begin:
                // Start a new beam group at this level
                let builder = BeamGroupBuilder(level: level, voice: voice, staff: staff)
                builder.addNote(index: noteIndex, measureIndex: measureIndex)
                activeBeams[level] = builder

            case .continue:
                // Continue the existing beam
                if let builder = activeBeams[level] {
                    builder.addNote(index: noteIndex, measureIndex: measureIndex)
                } else {
                    warnings.append("Beam continue without begin at level \(level), measure \(measureIndex)")
                }

            case .end:
                // End the beam group
                if let builder = activeBeams.removeValue(forKey: level) {
                    builder.addNote(index: noteIndex, measureIndex: measureIndex)
                    completedGroups.append(builder.build())
                } else {
                    warnings.append("Beam end without begin at level \(level), measure \(measureIndex)")
                }

            case .forwardHook, .backwardHook:
                // Hooks are single-note partial beams, attach to current group
                if let builder = activeBeams[level - 1] ?? activeBeams[level] {
                    builder.addNote(index: noteIndex, measureIndex: measureIndex, hook: beam.value)
                }
            }
        }
    }

    /// Finalizes tracking at end of measure/part.
    public func finalize() {
        for (level, builder) in activeBeams {
            warnings.append("Orphaned beam at level \(level)")
            // Still complete the partial group
            completedGroups.append(builder.build())
        }
        activeBeams.removeAll()
    }

    /// Resets the grouper.
    public func reset() {
        activeBeams.removeAll()
        completedGroups.removeAll()
        warnings.removeAll()
    }
}

// MARK: - Supporting Types

/// Builder for a beam group.
private class BeamGroupBuilder {
    let level: Int
    let voice: Int
    let staff: Int
    private var noteIndices: [(index: Int, measureIndex: Int, hook: BeamType?)] = []

    init(level: Int, voice: Int, staff: Int) {
        self.level = level
        self.voice = voice
        self.staff = staff
    }

    func addNote(index: Int, measureIndex: Int, hook: BeamType? = nil) {
        noteIndices.append((index, measureIndex, hook))
    }

    func build() -> BeamGroup {
        BeamGroup(
            level: level,
            voice: voice,
            staff: staff,
            notes: noteIndices.map { BeamGroupNote(noteIndex: $0.index, measureIndex: $0.measureIndex, hook: $0.hook) }
        )
    }
}

/// A note in a beam group.
public struct BeamGroupNote: Sendable {
    public let noteIndex: Int
    public let measureIndex: Int
    public let hook: BeamType?
}

/// A completed beam group.
public struct BeamGroup: Sendable {
    public let level: Int
    public let voice: Int
    public let staff: Int
    public let notes: [BeamGroupNote]

    public var startNoteIndex: Int? { notes.first?.noteIndex }
    public var endNoteIndex: Int? { notes.last?.noteIndex }
    public var noteCount: Int { notes.count }
}
