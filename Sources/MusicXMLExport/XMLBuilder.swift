import Foundation

// MARK: - XML Builder

/// A fluent XML document builder for creating MusicXML output.
public final class XMLBuilder {
    /// Indentation level.
    private var indentLevel: Int = 0

    /// Characters per indent.
    private let indentSize: Int

    /// The accumulated XML content.
    private var content: String = ""

    /// Encoding to use.
    public let encoding: String.Encoding

    /// Creates a new XML builder.
    public init(encoding: String.Encoding = .utf8, indentSize: Int = 2) {
        self.encoding = encoding
        self.indentSize = indentSize
    }

    // MARK: - Document Structure

    /// Writes the XML declaration.
    public func writeXMLDeclaration(version: String = "1.0") {
        let encodingName: String
        switch encoding {
        case .utf8:
            encodingName = "UTF-8"
        case .utf16:
            encodingName = "UTF-16"
        case .isoLatin1:
            encodingName = "ISO-8859-1"
        default:
            encodingName = "UTF-8"
        }
        content += "<?xml version=\"\(version)\" encoding=\"\(encodingName)\"?>\n"
    }

    /// Writes the MusicXML DOCTYPE declaration.
    public func writeMusicXMLDoctype(version: String = "4.0") {
        let publicId: String
        let systemId: String

        switch version {
        case "4.0":
            publicId = "-//Recordare//DTD MusicXML 4.0 Partwise//EN"
            systemId = "http://www.musicxml.org/dtds/partwise.dtd"
        case "3.1":
            publicId = "-//Recordare//DTD MusicXML 3.1 Partwise//EN"
            systemId = "http://www.musicxml.org/dtds/partwise.dtd"
        default:
            publicId = "-//Recordare//DTD MusicXML 4.0 Partwise//EN"
            systemId = "http://www.musicxml.org/dtds/partwise.dtd"
        }

        content += "<!DOCTYPE score-partwise PUBLIC \"\(publicId)\" \"\(systemId)\">\n"
    }

    // MARK: - Element Writing

    /// Opens an element tag.
    public func openElement(_ name: String, attributes: [String: String] = [:]) {
        writeIndent()
        content += "<\(name)"
        writeAttributes(attributes)
        content += ">\n"
        indentLevel += 1
    }

    /// Closes an element tag.
    public func closeElement(_ name: String) {
        indentLevel -= 1
        writeIndent()
        content += "</\(name)>\n"
    }

    /// Writes a self-closing element.
    public func writeEmptyElement(_ name: String, attributes: [String: String] = [:]) {
        writeIndent()
        content += "<\(name)"
        writeAttributes(attributes)
        content += "/>\n"
    }

    /// Writes an element with text content.
    public func writeElement(_ name: String, text: String, attributes: [String: String] = [:]) {
        writeIndent()
        content += "<\(name)"
        writeAttributes(attributes)
        content += ">\(escapeText(text))</\(name)>\n"
    }

    /// Writes an element with integer content.
    public func writeElement(_ name: String, value: Int, attributes: [String: String] = [:]) {
        writeElement(name, text: String(value), attributes: attributes)
    }

    /// Writes an element with double content.
    public func writeElement(_ name: String, value: Double, attributes: [String: String] = [:]) {
        // Format doubles to avoid unnecessary decimal places
        let formatted = value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(value)
        writeElement(name, text: formatted, attributes: attributes)
    }

    /// Writes an optional element (only if value is non-nil).
    public func writeOptionalElement(_ name: String, text: String?, attributes: [String: String] = [:]) {
        guard let text = text else { return }
        writeElement(name, text: text, attributes: attributes)
    }

    /// Writes an optional element with integer value.
    public func writeOptionalElement(_ name: String, value: Int?, attributes: [String: String] = [:]) {
        guard let value = value else { return }
        writeElement(name, value: value, attributes: attributes)
    }

    /// Writes an optional element with double value.
    public func writeOptionalElement(_ name: String, value: Double?, attributes: [String: String] = [:]) {
        guard let value = value else { return }
        writeElement(name, value: value, attributes: attributes)
    }

    /// Writes a comment.
    public func writeComment(_ text: String) {
        writeIndent()
        content += "<!-- \(text) -->\n"
    }

    // MARK: - Block Writing

    /// Writes an element with a block of child content.
    @discardableResult
    public func element(_ name: String, attributes: [String: String] = [:], block: () -> Void) -> XMLBuilder {
        openElement(name, attributes: attributes)
        block()
        closeElement(name)
        return self
    }

    /// Conditionally writes an element.
    @discardableResult
    public func elementIf(_ condition: Bool, _ name: String, attributes: [String: String] = [:], block: () -> Void) -> XMLBuilder {
        guard condition else { return self }
        return element(name, attributes: attributes, block: block)
    }

    /// Writes an element if the optional has a value.
    @discardableResult
    public func elementIfLet<T>(_ value: T?, _ name: String, attributes: [String: String] = [:], block: (T) -> Void) -> XMLBuilder {
        guard let value = value else { return self }
        openElement(name, attributes: attributes)
        block(value)
        closeElement(name)
        return self
    }

    // MARK: - Output

    /// Returns the built XML string.
    public func build() -> String {
        content
    }

    /// Returns the XML as Data.
    public func buildData() -> Data {
        content.data(using: encoding) ?? Data()
    }

    /// Clears the builder for reuse.
    public func clear() {
        content = ""
        indentLevel = 0
    }

    // MARK: - Private Helpers

    private func writeIndent() {
        content += String(repeating: " ", count: indentLevel * indentSize)
    }

    private func writeAttributes(_ attributes: [String: String]) {
        // Sort for consistent output
        for (key, value) in attributes.sorted(by: { $0.key < $1.key }) {
            content += " \(key)=\"\(escapeAttribute(value))\""
        }
    }

    private func escapeText(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }

    private func escapeAttribute(_ value: String) -> String {
        escapeText(value)
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&apos;")
    }
}

// MARK: - Attribute Builder

/// Helper for building attribute dictionaries.
public struct XMLAttributes {
    private var attrs: [String: String] = [:]

    public init() {}

    /// Adds an attribute.
    @discardableResult
    public mutating func add(_ name: String, _ value: String) -> XMLAttributes {
        attrs[name] = value
        return self
    }

    /// Adds an integer attribute.
    @discardableResult
    public mutating func add(_ name: String, _ value: Int) -> XMLAttributes {
        attrs[name] = String(value)
        return self
    }

    /// Adds a double attribute.
    @discardableResult
    public mutating func add(_ name: String, _ value: Double) -> XMLAttributes {
        attrs[name] = String(value)
        return self
    }

    /// Adds an optional attribute.
    @discardableResult
    public mutating func addIfPresent(_ name: String, _ value: String?) -> XMLAttributes {
        if let value = value {
            attrs[name] = value
        }
        return self
    }

    /// Adds an optional integer attribute.
    @discardableResult
    public mutating func addIfPresent(_ name: String, _ value: Int?) -> XMLAttributes {
        if let value = value {
            attrs[name] = String(value)
        }
        return self
    }

    /// Adds an optional double attribute.
    @discardableResult
    public mutating func addIfPresent(_ name: String, _ value: Double?) -> XMLAttributes {
        if let value = value {
            attrs[name] = String(value)
        }
        return self
    }

    /// Adds a boolean attribute (only if true).
    @discardableResult
    public mutating func addIfTrue(_ name: String, _ value: Bool) -> XMLAttributes {
        if value {
            attrs[name] = "yes"
        }
        return self
    }

    /// Adds a boolean attribute with yes/no value.
    @discardableResult
    public mutating func addYesNo(_ name: String, _ value: Bool) -> XMLAttributes {
        attrs[name] = value ? "yes" : "no"
        return self
    }

    /// Returns the built dictionary.
    public func build() -> [String: String] {
        attrs
    }
}

// MARK: - XML Builder Extensions

public extension XMLBuilder {
    /// Creates attributes using a builder closure.
    func attributes(_ builder: (inout XMLAttributes) -> Void) -> [String: String] {
        var attrs = XMLAttributes()
        builder(&attrs)
        return attrs.build()
    }
}
