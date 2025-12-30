import Foundation
import MusicNotationCore

/// Parses and tracks tuplets during MusicXML import.
///
/// `TupletParser` handles the complex task of correlating tuplet start/stop events
/// with time-modification data to build complete ``Tuplet`` objects. It supports
/// nested tuplets (tuplet within tuplet) via the MusicXML number attribute (1-6).
///
/// ## Tuplet Representation in MusicXML
///
/// MusicXML represents tuplets in two complementary ways:
/// 1. **time-modification**: On each note, specifies actual/normal note ratio
/// 2. **tuplet notation**: In `<notations>`, specifies visual bracket and number display
///
/// The parser combines both sources, preferring explicit tuplet values when present.
///
/// ## Nested Tuplets
///
/// MusicXML supports up to 6 levels of nested tuplets via the `number` attribute.
/// Each level is tracked independently:
/// - Level 1: Outermost tuplet (e.g., triplet)
/// - Level 2+: Inner tuplets (e.g., quintuplet within triplet)
///
/// ## Ratio Calculation
///
/// Tuplet ratios express how many notes play in the time of others:
/// - **3:2** (triplet): 3 notes in the time of 2
/// - **5:4** (quintuplet): 5 notes in the time of 4
/// - **7:4** (septuplet): 7 notes in the time of 4
///
/// ## Usage
///
/// ```swift
/// let parser = TupletParser()
/// parser.setMeasureIndex(0)
///
/// for note in notes {
///     // Process explicit tuplet notations
///     if let tupletElement = note.notationsElement?.child(named: "tuplet") {
///         parser.processTupletElement(tupletElement, noteId: note.id,
///                                     timeModification: note.timeModificationElement)
///     } else if parser.hasActiveTuplets {
///         // Add to active tuplets if note has time-modification
///         parser.addNoteToActiveTuplets(noteId: note.id)
///     }
/// }
///
/// parser.forceCompleteAll()
/// let tuplets = parser.harvestCompletedTuplets()
/// ```
///
/// - SeeAlso: ``BeamGrouper`` for beam group tracking
/// - SeeAlso: ``Tuplet`` for the output model
public class TupletParser {
    /// Active tuplets by number, supporting up to 6 nesting levels.
    private var activeTuplets: [Int: TupletStart] = [:]

    /// Completed tuplets ready for harvest.
    private var completedTuplets: [Tuplet] = []

    /// Current measure index for tracking tuplet position.
    private var currentMeasureIndex: Int = 0

    public init() {}

    // MARK: - Public API

    /// Resets the parser state.
    public func reset() {
        activeTuplets.removeAll()
        completedTuplets.removeAll()
        currentMeasureIndex = 0
    }

    /// Sets the current measure index.
    public func setMeasureIndex(_ index: Int) {
        currentMeasureIndex = index
    }

    /// Processes a tuplet element from a note's notations.
    /// - Parameters:
    ///   - element: The <tuplet> XML element.
    ///   - noteId: The ID of the note this tuplet is on.
    ///   - timeModification: Optional time-modification element for actual/normal values.
    public func processTupletElement(
        _ element: XMLElement,
        noteId: UUID,
        timeModification: XMLElement?
    ) {
        let typeStr = element.attribute(named: "type") ?? "start"
        let number = element.attribute(named: "number").flatMap(Int.init) ?? 1

        switch typeStr {
        case "start":
            startTuplet(element: element, number: number, noteId: noteId, timeModification: timeModification)
        case "stop":
            stopTuplet(number: number, noteId: noteId)
        default:
            break
        }
    }

    /// Adds a note to all active tuplets.
    /// Call this for notes that have time-modification but no explicit tuplet start/stop.
    public func addNoteToActiveTuplets(noteId: UUID) {
        for number in activeTuplets.keys {
            activeTuplets[number]?.addNote(id: noteId)
        }
    }

    /// Returns all completed tuplets and clears the list.
    public func harvestCompletedTuplets() -> [Tuplet] {
        let result = completedTuplets
        completedTuplets.removeAll()
        return result
    }

    /// Returns tuplets that are currently active (started but not stopped).
    public var activeCount: Int {
        activeTuplets.count
    }

    /// Checks if there are any active tuplets.
    public var hasActiveTuplets: Bool {
        !activeTuplets.isEmpty
    }

    /// Forces completion of all active tuplets (e.g., at end of measure if needed).
    public func forceCompleteAll() {
        for (_, tupletStart) in activeTuplets {
            completedTuplets.append(tupletStart.toTuplet())
        }
        activeTuplets.removeAll()
    }

    // MARK: - Private Methods

    private func startTuplet(
        element: XMLElement,
        number: Int,
        noteId: UUID,
        timeModification: XMLElement?
    ) {
        // Parse tuplet-actual and tuplet-normal if present
        var actualNotes = 3
        var normalNotes = 2
        var actualType: DurationBase?
        var normalType: DurationBase?

        // First, try to get values from time-modification (more reliable)
        if let timeMod = timeModification {
            if let actualStr = timeMod.child(named: "actual-notes")?.textContent,
               let actual = Int(actualStr) {
                actualNotes = actual
            }
            if let normalStr = timeMod.child(named: "normal-notes")?.textContent,
               let normal = Int(normalStr) {
                normalNotes = normal
            }
            if let normalTypeStr = timeMod.child(named: "normal-type")?.textContent {
                normalType = DurationBase(musicXMLTypeName: normalTypeStr)
            }
        }

        // Then override with explicit tuplet values if present
        if let tupletActual = element.child(named: "tuplet-actual") {
            if let actualNumberStr = tupletActual.child(named: "tuplet-number")?.textContent,
               let actual = Int(actualNumberStr) {
                actualNotes = actual
            }
            if let actualTypeStr = tupletActual.child(named: "tuplet-type")?.textContent {
                actualType = DurationBase(musicXMLTypeName: actualTypeStr)
            }
        }

        if let tupletNormal = element.child(named: "tuplet-normal") {
            if let normalNumberStr = tupletNormal.child(named: "tuplet-number")?.textContent,
               let normal = Int(normalNumberStr) {
                normalNotes = normal
            }
            if let normalTypeStr = tupletNormal.child(named: "tuplet-type")?.textContent {
                normalType = DurationBase(musicXMLTypeName: normalTypeStr)
            }
        }

        // Parse display options
        let showBracket: Bool?
        if let bracketStr = element.attribute(named: "bracket") {
            showBracket = bracketStr == "yes"
        } else {
            showBracket = nil
        }

        let showNumber: TupletDisplay
        if let showNumberStr = element.attribute(named: "show-number") {
            showNumber = TupletDisplay(rawValue: showNumberStr) ?? .actual
        } else {
            showNumber = .actual
        }

        let showType: TupletDisplay
        if let showTypeStr = element.attribute(named: "show-type") {
            showType = TupletDisplay(rawValue: showTypeStr) ?? .none
        } else {
            showType = .none
        }

        // Parse placement
        let placementStr = element.attribute(named: "placement")
        let placement = placementStr.flatMap { Placement(rawValue: $0) }

        // Create tuplet start tracking
        var tupletStart = TupletStart(
            number: number,
            actualNotes: actualNotes,
            normalNotes: normalNotes,
            actualType: actualType,
            normalType: normalType,
            showBracket: showBracket,
            showNumber: showNumber,
            showType: showType,
            placement: placement,
            startMeasureIndex: currentMeasureIndex
        )

        // Add the starting note
        tupletStart.addNote(id: noteId)

        // Store in active tuplets
        activeTuplets[number] = tupletStart
    }

    private func stopTuplet(number: Int, noteId: UUID) {
        guard var tupletStart = activeTuplets[number] else {
            // No matching start found - ignore
            return
        }

        // Add the final note
        tupletStart.addNote(id: noteId)

        // Create completed tuplet
        let tuplet = tupletStart.toTuplet()
        completedTuplets.append(tuplet)

        // Remove from active
        activeTuplets.removeValue(forKey: number)
    }
}

// MARK: - Tuplet Validation

extension Tuplet {
    /// Validates that the tuplet has the expected number of notes.
    public var isComplete: Bool {
        noteIds.count >= actualNotes
    }

    /// Validates the tuplet ratio.
    public var isValidRatio: Bool {
        actualNotes > 0 && normalNotes > 0 && actualNotes != normalNotes
    }
}

// MARK: - Time Modification Extraction

extension TupletParser {
    /// Extracts time modification from a note element and returns actual/normal values.
    public static func extractTimeModification(from noteElement: XMLElement) -> (actual: Int, normal: Int)? {
        guard let timeMod = noteElement.child(named: "time-modification") else {
            return nil
        }

        guard let actualStr = timeMod.child(named: "actual-notes")?.textContent,
              let actual = Int(actualStr),
              let normalStr = timeMod.child(named: "normal-notes")?.textContent,
              let normal = Int(normalStr) else {
            return nil
        }

        return (actual, normal)
    }

    /// Checks if a note has time modification (is part of a tuplet).
    public static func hasTimeModification(_ noteElement: XMLElement) -> Bool {
        noteElement.child(named: "time-modification") != nil
    }
}

// MARK: - Tuplet Grouping Utilities

extension Array where Element == Tuplet {
    /// Groups tuplets by their number for handling nested tuplets.
    public func groupedByNumber() -> [Int: [Tuplet]] {
        Dictionary(grouping: self, by: { $0.number })
    }

    /// Returns only the outermost tuplets (number == 1).
    public var outermostTuplets: [Tuplet] {
        filter { $0.number == 1 }
    }

    /// Finds tuplets that contain the given note ID.
    public func containing(noteId: UUID) -> [Tuplet] {
        filter { $0.noteIds.contains(noteId) }
    }
}
