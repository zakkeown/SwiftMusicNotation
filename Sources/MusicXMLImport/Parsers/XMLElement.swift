import Foundation

/// Lightweight XML element representation for parsing.
public final class XMLElement {
    /// Element name (tag).
    public let name: String

    /// Element attributes.
    public private(set) var attributes: [String: String] = [:]

    /// Child elements.
    public private(set) var children: [XMLElement] = []

    /// Text content (concatenated from all text nodes).
    public var textContent: String?

    /// Parent element (weak to avoid retain cycles).
    public weak var parent: XMLElement?

    public init(name: String) {
        self.name = name
    }

    /// Gets an attribute value by name.
    public func attribute(named name: String) -> String? {
        attributes[name]
    }

    /// Sets an attribute value.
    public func setAttribute(_ value: String, forKey key: String) {
        attributes[key] = value
    }

    /// Adds a child element.
    public func addChild(_ child: XMLElement) {
        child.parent = self
        children.append(child)
    }

    /// Gets the first child with a given name.
    public func child(named name: String) -> XMLElement? {
        children.first { $0.name == name }
    }

    /// Gets all children with a given name.
    public func children(named name: String) -> [XMLElement] {
        children.filter { $0.name == name }
    }

    /// Gets the next sibling with a given name.
    public func nextSibling(named name: String) -> XMLElement? {
        guard let parent = parent,
              let myIndex = parent.children.firstIndex(where: { $0 === self }) else {
            return nil
        }

        for i in (myIndex + 1)..<parent.children.count {
            if parent.children[i].name == name {
                return parent.children[i]
            }
        }
        return nil
    }

    /// Gets the previous sibling with a given name.
    public func previousSibling(named name: String) -> XMLElement? {
        guard let parent = parent,
              let myIndex = parent.children.firstIndex(where: { $0 === self }),
              myIndex > 0 else {
            return nil
        }

        for i in stride(from: myIndex - 1, through: 0, by: -1) {
            if parent.children[i].name == name {
                return parent.children[i]
            }
        }
        return nil
    }

    /// Finds all descendants matching a predicate.
    public func descendants(where predicate: (XMLElement) -> Bool) -> [XMLElement] {
        var results: [XMLElement] = []

        for child in children {
            if predicate(child) {
                results.append(child)
            }
            results.append(contentsOf: child.descendants(where: predicate))
        }

        return results
    }

    /// Finds all descendants with a given name.
    public func descendants(named name: String) -> [XMLElement] {
        descendants { $0.name == name }
    }
}

// MARK: - XML Tree Builder

/// Builds an XMLElement tree from XML data using Foundation's XMLParser.
public final class XMLTreeBuilder: NSObject, XMLParserDelegate {
    private var root: XMLElement?
    private var elementStack: [XMLElement] = []
    private var currentText: String = ""
    private var parseError: Error?

    /// Parses XML data and returns the root element.
    public func parse(data: Data) throws -> XMLElement {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.shouldProcessNamespaces = false
        parser.shouldReportNamespacePrefixes = false

        let success = parser.parse()

        if let error = parseError {
            throw error
        }

        if !success {
            throw MusicXMLError.xmlParsingFailed(
                line: parser.lineNumber,
                column: parser.columnNumber,
                message: parser.parserError?.localizedDescription ?? "Unknown error"
            )
        }

        guard let root = root else {
            throw MusicXMLError.invalidXMLStructure("No root element found")
        }

        return root
    }

    // MARK: - XMLParserDelegate

    public func parserDidStartDocument(_ parser: XMLParser) {
        root = nil
        elementStack.removeAll()
        currentText = ""
        parseError = nil
    }

    public func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        // Flush any accumulated text to the current element
        flushText()

        let element = XMLElement(name: elementName)
        for (key, value) in attributeDict {
            element.setAttribute(value, forKey: key)
        }

        if let current = elementStack.last {
            current.addChild(element)
        } else {
            root = element
        }

        elementStack.append(element)
    }

    public func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        flushText()
        _ = elementStack.popLast()
    }

    public func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    public func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = MusicXMLError.xmlParsingFailed(
            line: parser.lineNumber,
            column: parser.columnNumber,
            message: parseError.localizedDescription
        )
    }

    private func flushText() {
        let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty, let current = elementStack.last {
            if let existing = current.textContent {
                current.textContent = existing + trimmed
            } else {
                current.textContent = trimmed
            }
        }
        currentText = ""
    }
}
