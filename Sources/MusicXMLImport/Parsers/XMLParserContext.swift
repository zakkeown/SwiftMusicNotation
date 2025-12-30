import Foundation
import MusicNotationCore

/// Shared context during XML parsing.
public final class XMLParserContext {
    /// Current divisions value (duration units per quarter note).
    public var divisions: Int = 1

    /// Current part being parsed.
    public var currentPartId: String?

    /// Current measure number.
    public var currentMeasureNumber: String?

    /// Current staff number (1-based).
    public var currentStaff: Int = 1

    /// Current voice number.
    public var currentVoice: Int = 1

    /// Active attributes (clef, key, time) by staff.
    public var activeAttributes: [Int: ActiveMeasureAttributes] = [:]

    /// Accumulated warnings during parsing.
    public private(set) var warnings: [MusicXMLWarning] = []

    /// Part name lookup by ID.
    public var partNames: [String: String] = [:]

    /// Part abbreviations by ID.
    public var partAbbreviations: [String: String] = [:]

    /// Staff count per part.
    public var partStaffCounts: [String: Int] = [:]

    /// Instrument definitions per part.
    public var partInstruments: [String: [Instrument]] = [:]

    /// MIDI instrument settings per part.
    public var partMidiInstruments: [String: [MIDIInstrument]] = [:]

    public init() {}

    /// Adds a warning.
    public func addWarning(_ message: String, at location: SourceLocation? = nil) {
        warnings.append(MusicXMLWarning(message: message, location: location))
    }

    /// Resets state for a new part.
    public func resetForNewPart() {
        divisions = 1
        currentStaff = 1
        currentVoice = 1
        activeAttributes.removeAll()
    }

    /// Resets state for a new measure.
    public func resetForNewMeasure() {
        currentStaff = 1
        currentVoice = 1
    }

    /// Gets or creates active attributes for a staff.
    public func attributes(forStaff staff: Int) -> ActiveMeasureAttributes {
        if let existing = activeAttributes[staff] {
            return existing
        }
        let new = ActiveMeasureAttributes()
        activeAttributes[staff] = new
        return new
    }

    /// Updates active attributes for a staff.
    public func updateAttributes(_ attrs: ActiveMeasureAttributes, forStaff staff: Int) {
        activeAttributes[staff] = attrs
    }
}

/// Tracks active measure attributes (carried forward until changed).
public class ActiveMeasureAttributes {
    public var clef: Clef?
    public var keySignature: KeySignature?
    public var timeSignature: TimeSignature?
    public var divisions: Int?

    public init() {}

    public func copy() -> ActiveMeasureAttributes {
        let copy = ActiveMeasureAttributes()
        copy.clef = clef
        copy.keySignature = keySignature
        copy.timeSignature = timeSignature
        copy.divisions = divisions
        return copy
    }
}

/// Element path tracker for error reporting.
public struct ElementPath {
    private var elements: [String] = []

    public var path: String {
        elements.joined(separator: "/")
    }

    public var current: String? {
        elements.last
    }

    public var parent: String? {
        guard elements.count >= 2 else { return nil }
        return elements[elements.count - 2]
    }

    public mutating func push(_ element: String) {
        elements.append(element)
    }

    public mutating func pop() {
        _ = elements.popLast()
    }
}
