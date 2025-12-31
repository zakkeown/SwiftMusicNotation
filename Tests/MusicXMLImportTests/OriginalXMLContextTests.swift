import XCTest
@testable import MusicXMLImport

// Note: MusicXMLElement typealias is defined in DirectionMapperTests.swift

final class OriginalXMLContextTests: XCTestCase {

    // MARK: - Helper Methods

    /// Creates an XMLElement with the specified properties.
    private func createXMLElement(
        name: String,
        attributes: [String: String] = [:],
        textContent: String? = nil,
        children: [MusicXMLElement] = []
    ) -> MusicXMLElement {
        let element = MusicXMLElement(name: name)
        for (key, value) in attributes {
            element.setAttribute(value, forKey: key)
        }
        element.textContent = textContent
        for child in children {
            element.addChild(child)
        }
        return element
    }

    // MARK: - Initialization Tests

    func testInitialState() {
        let context = OriginalXMLContext()

        XCTAssertEqual(context.encoding, .utf8)
        XCTAssertEqual(context.xmlVersion, "1.0")
        XCTAssertNil(context.doctype)
        XCTAssertNil(context.musicXMLVersion)
        XCTAssertEqual(context.preservedElementCount, 0)
        XCTAssertEqual(context.preservedAttributeCount, 0)
        XCTAssertFalse(context.hasPreservedData)
    }

    func testEncodingProperty() {
        let context = OriginalXMLContext()
        context.encoding = .utf16
        XCTAssertEqual(context.encoding, .utf16)
    }

    func testXmlVersionProperty() {
        let context = OriginalXMLContext()
        context.xmlVersion = "1.1"
        XCTAssertEqual(context.xmlVersion, "1.1")
    }

    func testDoctypeProperty() {
        let context = OriginalXMLContext()
        context.doctype = "<!DOCTYPE score-partwise PUBLIC \"-//Recordare//DTD MusicXML 4.0 Partwise//EN\">"
        XCTAssertEqual(context.doctype, "<!DOCTYPE score-partwise PUBLIC \"-//Recordare//DTD MusicXML 4.0 Partwise//EN\">")
    }

    func testMusicXMLVersionProperty() {
        let context = OriginalXMLContext()
        context.musicXMLVersion = "4.0"
        XCTAssertEqual(context.musicXMLVersion, "4.0")
    }

    // MARK: - Element Preservation Tests

    func testPreserveElementSimple() {
        let context = OriginalXMLContext()
        let element = createXMLElement(name: "custom-element", textContent: "test content")

        context.preserveElement(element, parentPath: "score-partwise/part/measure")

        XCTAssertEqual(context.preservedElementCount, 1)
        XCTAssertTrue(context.hasPreservedData)
    }

    func testPreserveElementWithAttributes() {
        let context = OriginalXMLContext()
        let element = createXMLElement(
            name: "custom-element",
            attributes: ["id": "123", "type": "special"]
        )

        context.preserveElement(element, parentPath: "score-partwise")

        let preserved = context.preservedElements(forPath: "score-partwise")
        XCTAssertEqual(preserved.count, 1)
        XCTAssertEqual(preserved[0].name, "custom-element")
        XCTAssertEqual(preserved[0].attributes["id"], "123")
        XCTAssertEqual(preserved[0].attributes["type"], "special")
    }

    func testPreserveElementWithChildren() {
        let context = OriginalXMLContext()
        let child = createXMLElement(name: "child", textContent: "child content")
        let element = createXMLElement(name: "parent", children: [child])

        context.preserveElement(element, parentPath: "root")

        let preserved = context.preservedElements(forPath: "root")
        XCTAssertEqual(preserved.count, 1)
        XCTAssertEqual(preserved[0].children.count, 1)
        XCTAssertEqual(preserved[0].children[0].name, "child")
        XCTAssertEqual(preserved[0].children[0].textContent, "child content")
    }

    func testPreserveElementWithOrdering() {
        let context = OriginalXMLContext()
        let element = createXMLElement(name: "test")

        context.preserveElement(element, parentPath: "root", beforeElement: "note", afterElement: "attributes")

        let preserved = context.preservedElements(forPath: "root")
        XCTAssertEqual(preserved[0].beforeElement, "note")
        XCTAssertEqual(preserved[0].afterElement, "attributes")
    }

    func testPreserveMultipleElements() {
        let context = OriginalXMLContext()

        let element1 = createXMLElement(name: "custom1")
        let element2 = createXMLElement(name: "custom2")
        let element3 = createXMLElement(name: "other")

        context.preserveElement(element1, parentPath: "path1")
        context.preserveElement(element2, parentPath: "path1")
        context.preserveElement(element3, parentPath: "path2")

        XCTAssertEqual(context.preservedElementCount, 3)
        XCTAssertEqual(context.preservedElements(forPath: "path1").count, 2)
        XCTAssertEqual(context.preservedElements(forPath: "path2").count, 1)
    }

    func testPreservedElementsForNonexistentPath() {
        let context = OriginalXMLContext()
        let elements = context.preservedElements(forPath: "nonexistent")
        XCTAssertTrue(elements.isEmpty)
    }

    // MARK: - Attribute Preservation Tests

    func testPreserveAttributes() {
        let context = OriginalXMLContext()

        context.preserveAttributes(
            ["custom-attr": "value", "other": "data"],
            elementPath: "note",
            elementId: "note-1"
        )

        XCTAssertEqual(context.preservedAttributeCount, 1)
        XCTAssertTrue(context.hasPreservedData)
    }

    func testRetrievePreservedAttributes() {
        let context = OriginalXMLContext()

        context.preserveAttributes(
            ["custom-attr": "value", "other": "data"],
            elementPath: "note",
            elementId: "note-1"
        )

        let preserved = context.preservedAttributes(forPath: "note", elementId: "note-1")
        XCTAssertEqual(preserved.count, 2)

        let attrNames = Set(preserved.map { $0.name })
        XCTAssertTrue(attrNames.contains("custom-attr"))
        XCTAssertTrue(attrNames.contains("other"))
    }

    func testPreservedAttributesForNonexistentPath() {
        let context = OriginalXMLContext()
        let attrs = context.preservedAttributes(forPath: "nonexistent", elementId: "id")
        XCTAssertTrue(attrs.isEmpty)
    }

    func testMultipleAttributeSets() {
        let context = OriginalXMLContext()

        context.preserveAttributes(["a": "1"], elementPath: "note", elementId: "note-1")
        context.preserveAttributes(["b": "2"], elementPath: "note", elementId: "note-2")
        context.preserveAttributes(["c": "3"], elementPath: "measure", elementId: "m-1")

        XCTAssertEqual(context.preservedAttributeCount, 3)

        let noteAttrs1 = context.preservedAttributes(forPath: "note", elementId: "note-1")
        XCTAssertEqual(noteAttrs1.count, 1)
        XCTAssertEqual(noteAttrs1[0].value, "1")
    }

    // MARK: - Processing Instruction Tests

    func testPreserveProcessingInstruction() {
        let context = OriginalXMLContext()

        context.preserveProcessingInstruction(
            target: "xml-stylesheet",
            data: "type=\"text/xsl\" href=\"style.xsl\"",
            location: .documentStart
        )

        let instructions = context.processingInstructions(at: .documentStart)
        XCTAssertEqual(instructions.count, 1)
        XCTAssertEqual(instructions[0].target, "xml-stylesheet")
        XCTAssertEqual(instructions[0].data, "type=\"text/xsl\" href=\"style.xsl\"")
        XCTAssertTrue(context.hasPreservedData)
    }

    func testProcessingInstructionWithoutData() {
        let context = OriginalXMLContext()

        context.preserveProcessingInstruction(
            target: "simple",
            data: nil,
            location: .beforeRoot
        )

        let instructions = context.processingInstructions(at: .beforeRoot)
        XCTAssertEqual(instructions.count, 1)
        XCTAssertNil(instructions[0].data)
    }

    func testMultipleProcessingInstructions() {
        let context = OriginalXMLContext()

        context.preserveProcessingInstruction(target: "pi1", data: "data1", location: .documentStart)
        context.preserveProcessingInstruction(target: "pi2", data: "data2", location: .documentStart)
        context.preserveProcessingInstruction(target: "pi3", data: "data3", location: .afterRoot)

        XCTAssertEqual(context.processingInstructions(at: .documentStart).count, 2)
        XCTAssertEqual(context.processingInstructions(at: .afterRoot).count, 1)
    }

    // MARK: - Comment Tests

    func testPreserveComment() {
        let context = OriginalXMLContext()

        context.preserveComment(text: "This is a comment", location: .documentStart)

        let comments = context.comments(at: .documentStart)
        XCTAssertEqual(comments.count, 1)
        XCTAssertEqual(comments[0].text, "This is a comment")
        XCTAssertTrue(context.hasPreservedData)
    }

    func testMultipleComments() {
        let context = OriginalXMLContext()

        context.preserveComment(text: "Comment 1", location: .documentStart)
        context.preserveComment(text: "Comment 2", location: .documentStart)
        context.preserveComment(text: "Comment 3", location: .documentEnd)

        XCTAssertEqual(context.comments(at: .documentStart).count, 2)
        XCTAssertEqual(context.comments(at: .documentEnd).count, 1)
    }

    func testCommentsForEmptyLocation() {
        let context = OriginalXMLContext()
        let comments = context.comments(at: .documentEnd)
        XCTAssertTrue(comments.isEmpty)
    }

    // MARK: - Clear Tests

    func testClear() {
        let context = OriginalXMLContext()

        // Add various preserved data
        let element = createXMLElement(name: "test")
        context.preserveElement(element, parentPath: "root")
        context.preserveAttributes(["a": "1"], elementPath: "note", elementId: "n1")
        context.preserveProcessingInstruction(target: "pi", data: "data", location: .documentStart)
        context.preserveComment(text: "comment", location: .documentStart)

        XCTAssertTrue(context.hasPreservedData)

        context.clear()

        XCTAssertFalse(context.hasPreservedData)
        XCTAssertEqual(context.preservedElementCount, 0)
        XCTAssertEqual(context.preservedAttributeCount, 0)
        XCTAssertTrue(context.processingInstructions(at: .documentStart).isEmpty)
        XCTAssertTrue(context.comments(at: .documentStart).isEmpty)
    }

    // MARK: - Statistics Tests

    func testPreservedElementCount() {
        let context = OriginalXMLContext()
        XCTAssertEqual(context.preservedElementCount, 0)

        let element = createXMLElement(name: "test")
        context.preserveElement(element, parentPath: "path1")
        XCTAssertEqual(context.preservedElementCount, 1)

        context.preserveElement(element, parentPath: "path2")
        XCTAssertEqual(context.preservedElementCount, 2)
    }

    func testPreservedAttributeCount() {
        let context = OriginalXMLContext()
        XCTAssertEqual(context.preservedAttributeCount, 0)

        context.preserveAttributes(["a": "1"], elementPath: "path", elementId: "id1")
        XCTAssertEqual(context.preservedAttributeCount, 1)

        context.preserveAttributes(["b": "2"], elementPath: "path", elementId: "id2")
        XCTAssertEqual(context.preservedAttributeCount, 2)
    }

    func testHasPreservedData() {
        let context = OriginalXMLContext()
        XCTAssertFalse(context.hasPreservedData)

        // Test with element
        let element = createXMLElement(name: "test")
        context.preserveElement(element, parentPath: "root")
        XCTAssertTrue(context.hasPreservedData)

        context.clear()
        XCTAssertFalse(context.hasPreservedData)

        // Test with attributes
        context.preserveAttributes(["a": "1"], elementPath: "note", elementId: "n1")
        XCTAssertTrue(context.hasPreservedData)

        context.clear()
        XCTAssertFalse(context.hasPreservedData)

        // Test with PI
        context.preserveProcessingInstruction(target: "pi", data: nil, location: .documentStart)
        XCTAssertTrue(context.hasPreservedData)

        context.clear()
        XCTAssertFalse(context.hasPreservedData)

        // Test with comment
        context.preserveComment(text: "comment", location: .documentEnd)
        XCTAssertTrue(context.hasPreservedData)
    }
}

// MARK: - PreservedElement Tests

final class PreservedElementTests: XCTestCase {

    func testToXMLStringSelfClosing() {
        let element = PreservedElement(name: "empty", attributes: [:])
        let xml = element.toXMLString()
        XCTAssertEqual(xml, "<empty/>")
    }

    func testToXMLStringWithTextContent() {
        let element = PreservedElement(
            name: "text",
            attributes: [:],
            textContent: "Hello World"
        )
        let xml = element.toXMLString()
        XCTAssertEqual(xml, "<text>Hello World</text>")
    }

    func testToXMLStringWithAttributes() {
        let element = PreservedElement(
            name: "elem",
            attributes: ["id": "123", "type": "test"]
        )
        let xml = element.toXMLString()
        // Attributes are sorted alphabetically
        XCTAssertTrue(xml.contains("id=\"123\""))
        XCTAssertTrue(xml.contains("type=\"test\""))
    }

    func testToXMLStringWithChildren() {
        let child = PreservedElement(name: "child", attributes: [:], textContent: "content")
        let parent = PreservedElement(
            name: "parent",
            attributes: [:],
            textContent: nil,
            children: [child]
        )
        let xml = parent.toXMLString()
        XCTAssertTrue(xml.contains("<parent>"))
        XCTAssertTrue(xml.contains("<child>content</child>"))
        XCTAssertTrue(xml.contains("</parent>"))
    }

    func testToXMLStringWithIndentation() {
        let child = PreservedElement(name: "child", attributes: [:])
        let parent = PreservedElement(
            name: "parent",
            attributes: [:],
            textContent: nil,
            children: [child]
        )
        let xml = parent.toXMLString(indent: 1)
        XCTAssertTrue(xml.hasPrefix("  ")) // 1 level of indentation = 2 spaces
    }

    func testToXMLStringEscapesText() {
        let element = PreservedElement(
            name: "text",
            attributes: [:],
            textContent: "<script>&dangerous</script>"
        )
        let xml = element.toXMLString()
        XCTAssertTrue(xml.contains("&lt;script&gt;"))
        XCTAssertTrue(xml.contains("&amp;dangerous"))
    }

    func testToXMLStringEscapesAttributes() {
        let element = PreservedElement(
            name: "elem",
            attributes: ["quote": "He said \"hello\""]
        )
        let xml = element.toXMLString()
        XCTAssertTrue(xml.contains("&quot;hello&quot;"))
    }
}

// MARK: - PreservedAttribute Tests

final class PreservedAttributeTests: XCTestCase {

    func testInitialization() {
        let attr = PreservedAttribute(name: "test-attr", value: "test-value")
        XCTAssertEqual(attr.name, "test-attr")
        XCTAssertEqual(attr.value, "test-value")
    }
}

// MARK: - PreservedProcessingInstruction Tests

final class PreservedProcessingInstructionTests: XCTestCase {

    func testToXMLStringWithData() {
        let pi = PreservedProcessingInstruction(
            target: "xml-stylesheet",
            data: "type=\"text/xsl\" href=\"style.xsl\"",
            location: .documentStart
        )
        let xml = pi.toXMLString()
        XCTAssertEqual(xml, "<?xml-stylesheet type=\"text/xsl\" href=\"style.xsl\"?>")
    }

    func testToXMLStringWithoutData() {
        let pi = PreservedProcessingInstruction(
            target: "simple",
            data: nil,
            location: .documentStart
        )
        let xml = pi.toXMLString()
        XCTAssertEqual(xml, "<?simple?>")
    }
}

// MARK: - PreservedComment Tests

final class PreservedCommentTests: XCTestCase {

    func testToXMLString() {
        let comment = PreservedComment(
            text: "This is a test comment",
            location: .documentStart
        )
        let xml = comment.toXMLString()
        XCTAssertEqual(xml, "<!-- This is a test comment -->")
    }
}

// MARK: - PreservationLocation Tests

final class PreservationLocationTests: XCTestCase {

    func testCustomLocation() {
        let location = PreservationLocation(path: "score/part/measure", position: "before-note-5")
        XCTAssertEqual(location.path, "score/part/measure")
        XCTAssertEqual(location.position, "before-note-5")
    }

    func testDocumentStartLocation() {
        let location = PreservationLocation.documentStart
        XCTAssertEqual(location.path, "")
        XCTAssertEqual(location.position, "start")
    }

    func testDocumentEndLocation() {
        let location = PreservationLocation.documentEnd
        XCTAssertEqual(location.path, "")
        XCTAssertEqual(location.position, "end")
    }

    func testBeforeRootLocation() {
        let location = PreservationLocation.beforeRoot
        XCTAssertEqual(location.path, "")
        XCTAssertEqual(location.position, "beforeRoot")
    }

    func testAfterRootLocation() {
        let location = PreservationLocation.afterRoot
        XCTAssertEqual(location.path, "")
        XCTAssertEqual(location.position, "afterRoot")
    }

    func testLocationEquality() {
        let loc1 = PreservationLocation(path: "a", position: "b")
        let loc2 = PreservationLocation(path: "a", position: "b")
        let loc3 = PreservationLocation(path: "a", position: "c")

        XCTAssertEqual(loc1, loc2)
        XCTAssertNotEqual(loc1, loc3)
    }

    func testLocationHashable() {
        let loc1 = PreservationLocation(path: "a", position: "b")
        let loc2 = PreservationLocation(path: "a", position: "b")

        var set = Set<PreservationLocation>()
        set.insert(loc1)
        set.insert(loc2)

        XCTAssertEqual(set.count, 1)
    }
}

// MARK: - KnownElementsRegistry Tests

final class KnownElementsRegistryTests: XCTestCase {

    func testKnownElements() {
        // Document structure
        XCTAssertTrue(KnownElementsRegistry.isKnown("score-partwise"))
        XCTAssertTrue(KnownElementsRegistry.isKnown("score-timewise"))
        XCTAssertTrue(KnownElementsRegistry.isKnown("part"))
        XCTAssertTrue(KnownElementsRegistry.isKnown("measure"))

        // Note elements
        XCTAssertTrue(KnownElementsRegistry.isKnown("note"))
        XCTAssertTrue(KnownElementsRegistry.isKnown("rest"))
        XCTAssertTrue(KnownElementsRegistry.isKnown("pitch"))
        XCTAssertTrue(KnownElementsRegistry.isKnown("duration"))

        // Attributes
        XCTAssertTrue(KnownElementsRegistry.isKnown("attributes"))
        XCTAssertTrue(KnownElementsRegistry.isKnown("clef"))
        XCTAssertTrue(KnownElementsRegistry.isKnown("key"))
        XCTAssertTrue(KnownElementsRegistry.isKnown("time"))

        // Notations
        XCTAssertTrue(KnownElementsRegistry.isKnown("tied"))
        XCTAssertTrue(KnownElementsRegistry.isKnown("slur"))
        XCTAssertTrue(KnownElementsRegistry.isKnown("dynamics"))

        // Directions
        XCTAssertTrue(KnownElementsRegistry.isKnown("direction"))
        XCTAssertTrue(KnownElementsRegistry.isKnown("metronome"))
        XCTAssertTrue(KnownElementsRegistry.isKnown("wedge"))
    }

    func testUnknownElements() {
        XCTAssertFalse(KnownElementsRegistry.isKnown("custom-element"))
        XCTAssertFalse(KnownElementsRegistry.isKnown("unknown"))
        XCTAssertFalse(KnownElementsRegistry.isKnown("proprietary"))
        XCTAssertFalse(KnownElementsRegistry.isKnown(""))
    }
}
