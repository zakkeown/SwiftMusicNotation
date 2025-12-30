import Foundation
import MusicNotationCore

/// Stores original XML data for elements that may not be fully modeled,
/// enabling lossless round-trip import/export.
///
/// This captures:
/// - Unknown elements that aren't mapped to model types
/// - Unknown attributes on known elements
/// - Processing instructions and comments
/// - Formatting/whitespace (optional)
/// - Original element order
public final class OriginalXMLContext: @unchecked Sendable {
    /// Unknown elements by their parent path (e.g., "score-partwise/part/measure").
    private var unknownElements: [String: [PreservedElement]] = [:]

    /// Unknown attributes by element path and element ID.
    private var unknownAttributes: [String: [String: [PreservedAttribute]]] = [:]

    /// Processing instructions by location.
    private var processingInstructions: [PreservedProcessingInstruction] = []

    /// Comments by location.
    private var comments: [PreservedComment] = []

    /// Original document encoding.
    public var encoding: String.Encoding = .utf8

    /// Original XML version.
    public var xmlVersion: String = "1.0"

    /// Original DOCTYPE if present.
    public var doctype: String?

    /// MusicXML version from the root element.
    public var musicXMLVersion: String?

    private let lock = NSLock()

    public init() {}

    // MARK: - Element Preservation

    /// Stores an unknown element for later export.
    public func preserveElement(
        _ element: XMLElement,
        parentPath: String,
        beforeElement: String? = nil,
        afterElement: String? = nil
    ) {
        lock.lock()
        defer { lock.unlock() }

        let preserved = PreservedElement(
            name: element.name,
            attributes: element.attributes,
            textContent: element.textContent,
            children: element.children.map { preserveElementRecursively($0) },
            beforeElement: beforeElement,
            afterElement: afterElement
        )

        if unknownElements[parentPath] == nil {
            unknownElements[parentPath] = []
        }
        unknownElements[parentPath]?.append(preserved)
    }

    private func preserveElementRecursively(_ element: XMLElement) -> PreservedElement {
        PreservedElement(
            name: element.name,
            attributes: element.attributes,
            textContent: element.textContent,
            children: element.children.map { preserveElementRecursively($0) },
            beforeElement: nil,
            afterElement: nil
        )
    }

    /// Retrieves preserved elements for a parent path.
    public func preservedElements(forPath path: String) -> [PreservedElement] {
        lock.lock()
        defer { lock.unlock() }
        return unknownElements[path] ?? []
    }

    // MARK: - Attribute Preservation

    /// Stores unknown attributes from an element.
    public func preserveAttributes(
        _ attributes: [String: String],
        elementPath: String,
        elementId: String
    ) {
        lock.lock()
        defer { lock.unlock() }

        let preserved = attributes.map { PreservedAttribute(name: $0.key, value: $0.value) }

        if unknownAttributes[elementPath] == nil {
            unknownAttributes[elementPath] = [:]
        }
        unknownAttributes[elementPath]?[elementId] = preserved
    }

    /// Retrieves preserved attributes for an element.
    public func preservedAttributes(
        forPath path: String,
        elementId: String
    ) -> [PreservedAttribute] {
        lock.lock()
        defer { lock.unlock() }
        return unknownAttributes[path]?[elementId] ?? []
    }

    // MARK: - Processing Instructions

    /// Stores a processing instruction.
    public func preserveProcessingInstruction(
        target: String,
        data: String?,
        location: PreservationLocation
    ) {
        lock.lock()
        defer { lock.unlock() }

        processingInstructions.append(PreservedProcessingInstruction(
            target: target,
            data: data,
            location: location
        ))
    }

    /// Retrieves processing instructions for a location.
    public func processingInstructions(at location: PreservationLocation) -> [PreservedProcessingInstruction] {
        lock.lock()
        defer { lock.unlock() }
        return processingInstructions.filter { $0.location == location }
    }

    // MARK: - Comments

    /// Stores a comment.
    public func preserveComment(
        text: String,
        location: PreservationLocation
    ) {
        lock.lock()
        defer { lock.unlock() }

        comments.append(PreservedComment(text: text, location: location))
    }

    /// Retrieves comments for a location.
    public func comments(at location: PreservationLocation) -> [PreservedComment] {
        lock.lock()
        defer { lock.unlock() }
        return comments.filter { $0.location == location }
    }

    // MARK: - Clearing

    /// Clears all preserved data.
    public func clear() {
        lock.lock()
        defer { lock.unlock() }

        unknownElements.removeAll()
        unknownAttributes.removeAll()
        processingInstructions.removeAll()
        comments.removeAll()
    }

    // MARK: - Statistics

    /// Number of preserved elements.
    public var preservedElementCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return unknownElements.values.reduce(0) { $0 + $1.count }
    }

    /// Number of preserved attribute sets.
    public var preservedAttributeCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return unknownAttributes.values.reduce(0) { $0 + $1.count }
    }

    /// Whether any data is preserved.
    public var hasPreservedData: Bool {
        lock.lock()
        defer { lock.unlock() }
        return !unknownElements.isEmpty ||
               !unknownAttributes.isEmpty ||
               !processingInstructions.isEmpty ||
               !comments.isEmpty
    }
}

// MARK: - Preserved Types

/// A preserved XML element.
public struct PreservedElement: Codable, Sendable {
    /// Element name.
    public let name: String

    /// Element attributes.
    public let attributes: [String: String]

    /// Text content.
    public let textContent: String?

    /// Child elements.
    public let children: [PreservedElement]

    /// Element that this should appear before (for ordering).
    public let beforeElement: String?

    /// Element that this should appear after (for ordering).
    public let afterElement: String?

    public init(
        name: String,
        attributes: [String: String] = [:],
        textContent: String? = nil,
        children: [PreservedElement] = [],
        beforeElement: String? = nil,
        afterElement: String? = nil
    ) {
        self.name = name
        self.attributes = attributes
        self.textContent = textContent
        self.children = children
        self.beforeElement = beforeElement
        self.afterElement = afterElement
    }

    /// Reconstructs the XML string for this element.
    public func toXMLString(indent: Int = 0) -> String {
        let indentStr = String(repeating: "  ", count: indent)
        var result = "\(indentStr)<\(name)"

        // Add attributes
        for (key, value) in attributes.sorted(by: { $0.key < $1.key }) {
            let escapedValue = escapeXMLAttribute(value)
            result += " \(key)=\"\(escapedValue)\""
        }

        if children.isEmpty && textContent == nil {
            result += "/>"
        } else {
            result += ">"

            if let text = textContent {
                result += escapeXMLText(text)
            }

            if !children.isEmpty {
                result += "\n"
                for child in children {
                    result += child.toXMLString(indent: indent + 1) + "\n"
                }
                result += indentStr
            }

            result += "</\(name)>"
        }

        return result
    }

    private func escapeXMLText(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private func escapeXMLAttribute(_ value: String) -> String {
        escapeXMLText(value)
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}

/// A preserved XML attribute.
public struct PreservedAttribute: Codable, Sendable {
    /// Attribute name.
    public let name: String

    /// Attribute value.
    public let value: String

    public init(name: String, value: String) {
        self.name = name
        self.value = value
    }
}

/// A preserved processing instruction.
public struct PreservedProcessingInstruction: Codable, Sendable {
    /// PI target (e.g., "xml-stylesheet").
    public let target: String

    /// PI data.
    public let data: String?

    /// Location in the document.
    public let location: PreservationLocation

    public init(target: String, data: String?, location: PreservationLocation) {
        self.target = target
        self.data = data
        self.location = location
    }

    /// Reconstructs the PI string.
    public func toXMLString() -> String {
        if let data = data {
            return "<?\(target) \(data)?>"
        } else {
            return "<?\(target)?>"
        }
    }
}

/// A preserved comment.
public struct PreservedComment: Codable, Sendable {
    /// Comment text.
    public let text: String

    /// Location in the document.
    public let location: PreservationLocation

    public init(text: String, location: PreservationLocation) {
        self.text = text
        self.location = location
    }

    /// Reconstructs the comment string.
    public func toXMLString() -> String {
        "<!-- \(text) -->"
    }
}

/// Location reference for preserved items.
public struct PreservationLocation: Codable, Sendable, Hashable {
    /// Parent element path.
    public let path: String

    /// Position within parent (index or ID).
    public let position: String

    public init(path: String, position: String) {
        self.path = path
        self.position = position
    }

    /// Creates a location at the document root.
    public static let documentStart = PreservationLocation(path: "", position: "start")
    public static let documentEnd = PreservationLocation(path: "", position: "end")
    public static let beforeRoot = PreservationLocation(path: "", position: "beforeRoot")
    public static let afterRoot = PreservationLocation(path: "", position: "afterRoot")
}

// MARK: - Known Elements Registry

/// Registry of known MusicXML elements for determining what to preserve.
public struct KnownElementsRegistry {
    /// Known MusicXML elements that are mapped to model types.
    public static let knownElements: Set<String> = [
        // Document structure
        "score-partwise", "score-timewise", "part", "measure",

        // Part list
        "part-list", "score-part", "part-name", "part-abbreviation",
        "score-instrument", "midi-instrument", "midi-device",

        // Measure contents
        "note", "rest", "pitch", "unpitched", "duration", "voice", "type",
        "dot", "stem", "staff", "beam", "accidental", "time-modification",
        "notations", "lyric", "chord",

        // Attributes
        "attributes", "divisions", "key", "time", "staves", "clef",
        "transpose", "staff-details", "measure-style",
        "fifths", "mode", "beats", "beat-type", "sign", "line",

        // Notations
        "tied", "slur", "tuplet", "glissando", "slide",
        "ornaments", "technical", "articulations", "dynamics", "fermata",
        "arpeggiate", "non-arpeggiate", "accidental-mark",

        // Directions
        "direction", "direction-type", "sound",
        "rehearsal", "segno", "coda", "words", "wedge",
        "dashes", "bracket", "pedal", "metronome", "octave-shift",
        "harp-pedals", "pedal-tuning", "principal-voice",
        "accordion-registration", "percussion", "other-direction",

        // Barlines
        "barline", "bar-style", "repeat", "ending",

        // Forward/Backup
        "forward", "backup",

        // Harmony
        "harmony", "root", "bass", "degree", "kind", "frame",

        // Print
        "print", "system-layout", "page-layout", "staff-layout",

        // Work/Identification
        "work", "work-number", "work-title", "movement-number", "movement-title",
        "identification", "creator", "rights", "encoding", "source",

        // Defaults
        "defaults", "scaling", "page-margins", "system-margins",
        "appearance", "music-font", "word-font", "lyric-font"
    ]

    /// Checks if an element name is known.
    public static func isKnown(_ elementName: String) -> Bool {
        knownElements.contains(elementName)
    }
}

// MARK: - Extension for XMLParserContext

private var preservationContextKey: UInt8 = 0

extension XMLParserContext {
    /// Optional preservation context for round-trip support.
    public var preservationContext: OriginalXMLContext? {
        get { objc_getAssociatedObject(self, &preservationContextKey) as? OriginalXMLContext }
        set { objc_setAssociatedObject(self, &preservationContextKey, newValue, .OBJC_ASSOCIATION_RETAIN) }
    }
}
