import XCTest
@testable import MusicXMLImport
@testable import MusicNotationCore

// MARK: - XMLElement Tests

final class XMLElementTests: XCTestCase {

    func testInitialization() {
        let element = MusicXMLImport.XMLElement(name: "note")
        XCTAssertEqual(element.name, "note")
        XCTAssertNil(element.textContent)
        XCTAssertTrue(element.children.isEmpty)
        XCTAssertNil(element.parent)
    }

    func testSetAttribute() {
        let element = MusicXMLImport.XMLElement(name: "note")
        element.setAttribute("1", forKey: "voice")
        element.setAttribute("2", forKey: "staff")

        XCTAssertEqual(element.attribute(named: "voice"), "1")
        XCTAssertEqual(element.attribute(named: "staff"), "2")
        XCTAssertNil(element.attribute(named: "nonexistent"))
    }

    func testAddChild() {
        let parent = MusicXMLImport.XMLElement(name: "measure")
        let child1 = MusicXMLImport.XMLElement(name: "note")
        let child2 = MusicXMLImport.XMLElement(name: "rest")

        parent.addChild(child1)
        parent.addChild(child2)

        XCTAssertEqual(parent.children.count, 2)
        XCTAssertTrue(child1.parent === parent)
        XCTAssertTrue(child2.parent === parent)
    }

    func testChildNamed() {
        let parent = MusicXMLImport.XMLElement(name: "measure")
        let note = MusicXMLImport.XMLElement(name: "note")
        let rest = MusicXMLImport.XMLElement(name: "rest")

        parent.addChild(note)
        parent.addChild(rest)

        XCTAssertTrue(parent.child(named: "note") === note)
        XCTAssertTrue(parent.child(named: "rest") === rest)
        XCTAssertNil(parent.child(named: "nonexistent"))
    }

    func testChildrenNamed() {
        let parent = MusicXMLImport.XMLElement(name: "measure")
        let note1 = MusicXMLImport.XMLElement(name: "note")
        let note2 = MusicXMLImport.XMLElement(name: "note")
        let rest = MusicXMLImport.XMLElement(name: "rest")

        parent.addChild(note1)
        parent.addChild(rest)
        parent.addChild(note2)

        let notes = parent.children(named: "note")
        XCTAssertEqual(notes.count, 2)
        XCTAssertTrue(notes[0] === note1)
        XCTAssertTrue(notes[1] === note2)

        let rests = parent.children(named: "rest")
        XCTAssertEqual(rests.count, 1)

        let backups = parent.children(named: "backup")
        XCTAssertTrue(backups.isEmpty)
    }

    func testNextSibling() {
        let parent = MusicXMLImport.XMLElement(name: "measure")
        let note1 = MusicXMLImport.XMLElement(name: "note")
        let rest = MusicXMLImport.XMLElement(name: "rest")
        let note2 = MusicXMLImport.XMLElement(name: "note")

        parent.addChild(note1)
        parent.addChild(rest)
        parent.addChild(note2)

        // From note1, next sibling named "rest" is rest
        XCTAssertTrue(note1.nextSibling(named: "rest") === rest)

        // From note1, next sibling named "note" is note2
        XCTAssertTrue(note1.nextSibling(named: "note") === note2)

        // From rest, next sibling named "note" is note2
        XCTAssertTrue(rest.nextSibling(named: "note") === note2)

        // From note2, no next sibling named "note"
        XCTAssertNil(note2.nextSibling(named: "note"))

        // Element without parent
        let orphan = MusicXMLImport.XMLElement(name: "orphan")
        XCTAssertNil(orphan.nextSibling(named: "anything"))
    }

    func testPreviousSibling() {
        let parent = MusicXMLImport.XMLElement(name: "measure")
        let note1 = MusicXMLImport.XMLElement(name: "note")
        let rest = MusicXMLImport.XMLElement(name: "rest")
        let note2 = MusicXMLImport.XMLElement(name: "note")

        parent.addChild(note1)
        parent.addChild(rest)
        parent.addChild(note2)

        // From note2, previous sibling named "rest" is rest
        XCTAssertTrue(note2.previousSibling(named: "rest") === rest)

        // From note2, previous sibling named "note" is note1
        XCTAssertTrue(note2.previousSibling(named: "note") === note1)

        // From rest, previous sibling named "note" is note1
        XCTAssertTrue(rest.previousSibling(named: "note") === note1)

        // From note1, no previous sibling named "note"
        XCTAssertNil(note1.previousSibling(named: "note"))

        // Element without parent
        let orphan = MusicXMLImport.XMLElement(name: "orphan")
        XCTAssertNil(orphan.previousSibling(named: "anything"))
    }

    func testDescendantsNamed() {
        // Build a tree:
        // measure
        //   note
        //     pitch
        //       step
        //   note
        //     pitch
        //       step
        let measure = MusicXMLImport.XMLElement(name: "measure")
        let note1 = MusicXMLImport.XMLElement(name: "note")
        let pitch1 = MusicXMLImport.XMLElement(name: "pitch")
        let step1 = MusicXMLImport.XMLElement(name: "step")
        let note2 = MusicXMLImport.XMLElement(name: "note")
        let pitch2 = MusicXMLImport.XMLElement(name: "pitch")
        let step2 = MusicXMLImport.XMLElement(name: "step")

        measure.addChild(note1)
        note1.addChild(pitch1)
        pitch1.addChild(step1)
        measure.addChild(note2)
        note2.addChild(pitch2)
        pitch2.addChild(step2)

        // Find all "note" descendants
        let notes = measure.descendants(named: "note")
        XCTAssertEqual(notes.count, 2)

        // Find all "pitch" descendants
        let pitches = measure.descendants(named: "pitch")
        XCTAssertEqual(pitches.count, 2)

        // Find all "step" descendants
        let steps = measure.descendants(named: "step")
        XCTAssertEqual(steps.count, 2)

        // Find non-existent
        let backups = measure.descendants(named: "backup")
        XCTAssertTrue(backups.isEmpty)
    }

    func testDescendantsWhere() {
        let parent = MusicXMLImport.XMLElement(name: "measure")
        let note1 = MusicXMLImport.XMLElement(name: "note")
        note1.setAttribute("1", forKey: "voice")
        let note2 = MusicXMLImport.XMLElement(name: "note")
        note2.setAttribute("2", forKey: "voice")
        let rest = MusicXMLImport.XMLElement(name: "rest")
        rest.setAttribute("1", forKey: "voice")

        parent.addChild(note1)
        parent.addChild(note2)
        parent.addChild(rest)

        // Find all elements with voice="1"
        let voice1Elements = parent.descendants { $0.attribute(named: "voice") == "1" }
        XCTAssertEqual(voice1Elements.count, 2)

        // Find all elements with voice="2"
        let voice2Elements = parent.descendants { $0.attribute(named: "voice") == "2" }
        XCTAssertEqual(voice2Elements.count, 1)
    }

    func testTextContent() {
        let element = MusicXMLImport.XMLElement(name: "step")
        XCTAssertNil(element.textContent)

        element.textContent = "C"
        XCTAssertEqual(element.textContent, "C")
    }
}

// MARK: - TupletParser Tests

final class TupletParserTests: XCTestCase {

    private var parser: TupletParser!

    override func setUp() {
        super.setUp()
        parser = TupletParser()
    }

    private func createElement(name: String, attributes: [String: String] = [:], text: String? = nil) -> MusicXMLImport.XMLElement {
        let element = MusicXMLImport.XMLElement(name: name)
        for (key, value) in attributes {
            element.setAttribute(value, forKey: key)
        }
        if let text = text {
            element.textContent = text
        }
        return element
    }

    private func createTimeModification(actual: Int, normal: Int) -> MusicXMLImport.XMLElement {
        let timeMod = createElement(name: "time-modification")
        let actualNotes = createElement(name: "actual-notes", text: "\(actual)")
        let normalNotes = createElement(name: "normal-notes", text: "\(normal)")
        timeMod.addChild(actualNotes)
        timeMod.addChild(normalNotes)
        return timeMod
    }

    // MARK: - Basic Tuplet Tests

    func testInitialState() {
        XCTAssertFalse(parser.hasActiveTuplets)
        XCTAssertEqual(parser.activeCount, 0)
        XCTAssertTrue(parser.harvestCompletedTuplets().isEmpty)
    }

    func testReset() {
        let tupletElement = createElement(name: "tuplet", attributes: ["type": "start"])
        let timeMod = createTimeModification(actual: 3, normal: 2)
        parser.processTupletElement(tupletElement, noteId: UUID(), timeModification: timeMod)

        XCTAssertTrue(parser.hasActiveTuplets)

        parser.reset()

        XCTAssertFalse(parser.hasActiveTuplets)
        XCTAssertEqual(parser.activeCount, 0)
    }

    func testSetMeasureIndex() {
        parser.setMeasureIndex(5)
        // This is primarily for internal tracking, we'll verify through tuplet output
        let tupletElement = createElement(name: "tuplet", attributes: ["type": "start"])
        let timeMod = createTimeModification(actual: 3, normal: 2)
        let noteId1 = UUID()
        parser.processTupletElement(tupletElement, noteId: noteId1, timeModification: timeMod)

        let stopElement = createElement(name: "tuplet", attributes: ["type": "stop"])
        let noteId2 = UUID()
        parser.processTupletElement(stopElement, noteId: noteId2, timeModification: nil)

        let tuplets = parser.harvestCompletedTuplets()
        XCTAssertEqual(tuplets.count, 1)
    }

    func testSimpleTriplet() {
        let startElement = createElement(name: "tuplet", attributes: ["type": "start"])
        let timeMod = createTimeModification(actual: 3, normal: 2)

        let noteId1 = UUID()
        let noteId2 = UUID()
        let noteId3 = UUID()

        parser.processTupletElement(startElement, noteId: noteId1, timeModification: timeMod)
        XCTAssertTrue(parser.hasActiveTuplets)
        XCTAssertEqual(parser.activeCount, 1)

        parser.addNoteToActiveTuplets(noteId: noteId2)

        let stopElement = createElement(name: "tuplet", attributes: ["type": "stop"])
        parser.processTupletElement(stopElement, noteId: noteId3, timeModification: nil)

        XCTAssertFalse(parser.hasActiveTuplets)

        let tuplets = parser.harvestCompletedTuplets()
        XCTAssertEqual(tuplets.count, 1)

        let tuplet = tuplets[0]
        XCTAssertEqual(tuplet.actualNotes, 3)
        XCTAssertEqual(tuplet.normalNotes, 2)
        XCTAssertEqual(tuplet.noteIds.count, 3)
        XCTAssertTrue(tuplet.noteIds.contains(noteId1))
        XCTAssertTrue(tuplet.noteIds.contains(noteId2))
        XCTAssertTrue(tuplet.noteIds.contains(noteId3))
    }

    func testQuintuplet() {
        let startElement = createElement(name: "tuplet", attributes: ["type": "start"])
        let timeMod = createTimeModification(actual: 5, normal: 4)

        let noteIds = (0..<5).map { _ in UUID() }

        parser.processTupletElement(startElement, noteId: noteIds[0], timeModification: timeMod)

        for i in 1..<4 {
            parser.addNoteToActiveTuplets(noteId: noteIds[i])
        }

        let stopElement = createElement(name: "tuplet", attributes: ["type": "stop"])
        parser.processTupletElement(stopElement, noteId: noteIds[4], timeModification: nil)

        let tuplets = parser.harvestCompletedTuplets()
        XCTAssertEqual(tuplets.count, 1)
        XCTAssertEqual(tuplets[0].actualNotes, 5)
        XCTAssertEqual(tuplets[0].normalNotes, 4)
        XCTAssertEqual(tuplets[0].noteIds.count, 5)
    }

    func testNestedTuplets() {
        // Start outer tuplet (number 1)
        let outerStart = createElement(name: "tuplet", attributes: ["type": "start", "number": "1"])
        let outerTimeMod = createTimeModification(actual: 3, normal: 2)
        let noteId1 = UUID()
        parser.processTupletElement(outerStart, noteId: noteId1, timeModification: outerTimeMod)

        // Start inner tuplet (number 2) while outer is active
        let innerStart = createElement(name: "tuplet", attributes: ["type": "start", "number": "2"])
        let innerTimeMod = createTimeModification(actual: 5, normal: 4)
        let noteId2 = UUID()
        parser.processTupletElement(innerStart, noteId: noteId2, timeModification: innerTimeMod)

        XCTAssertEqual(parser.activeCount, 2)

        // Add notes to both
        let noteId3 = UUID()
        parser.addNoteToActiveTuplets(noteId: noteId3)

        // Stop inner tuplet
        let innerStop = createElement(name: "tuplet", attributes: ["type": "stop", "number": "2"])
        let noteId4 = UUID()
        parser.processTupletElement(innerStop, noteId: noteId4, timeModification: nil)

        XCTAssertEqual(parser.activeCount, 1)

        // Stop outer tuplet
        let outerStop = createElement(name: "tuplet", attributes: ["type": "stop", "number": "1"])
        let noteId5 = UUID()
        parser.processTupletElement(outerStop, noteId: noteId5, timeModification: nil)

        XCTAssertFalse(parser.hasActiveTuplets)

        let tuplets = parser.harvestCompletedTuplets()
        XCTAssertEqual(tuplets.count, 2)

        // Check that we got both tuplets with correct values
        let numbers = Set(tuplets.map { $0.number })
        XCTAssertTrue(numbers.contains(1))
        XCTAssertTrue(numbers.contains(2))
    }

    func testTupletWithBracket() {
        let startElement = createElement(name: "tuplet", attributes: [
            "type": "start",
            "bracket": "yes"
        ])
        let timeMod = createTimeModification(actual: 3, normal: 2)

        parser.processTupletElement(startElement, noteId: UUID(), timeModification: timeMod)

        let stopElement = createElement(name: "tuplet", attributes: ["type": "stop"])
        parser.processTupletElement(stopElement, noteId: UUID(), timeModification: nil)

        let tuplets = parser.harvestCompletedTuplets()
        XCTAssertEqual(tuplets[0].showBracket, true)
    }

    func testTupletWithShowNumber() {
        let startElement = createElement(name: "tuplet", attributes: [
            "type": "start",
            "show-number": "both"
        ])
        let timeMod = createTimeModification(actual: 3, normal: 2)

        parser.processTupletElement(startElement, noteId: UUID(), timeModification: timeMod)

        let stopElement = createElement(name: "tuplet", attributes: ["type": "stop"])
        parser.processTupletElement(stopElement, noteId: UUID(), timeModification: nil)

        let tuplets = parser.harvestCompletedTuplets()
        XCTAssertEqual(tuplets[0].showNumber, TupletDisplay.both)
    }

    func testTupletWithPlacement() {
        let startElement = createElement(name: "tuplet", attributes: [
            "type": "start",
            "placement": "above"
        ])
        let timeMod = createTimeModification(actual: 3, normal: 2)

        parser.processTupletElement(startElement, noteId: UUID(), timeModification: timeMod)

        let stopElement = createElement(name: "tuplet", attributes: ["type": "stop"])
        parser.processTupletElement(stopElement, noteId: UUID(), timeModification: nil)

        let tuplets = parser.harvestCompletedTuplets()
        XCTAssertEqual(tuplets[0].placement, Placement.above)
    }

    func testForceCompleteAll() {
        let startElement = createElement(name: "tuplet", attributes: ["type": "start"])
        let timeMod = createTimeModification(actual: 3, normal: 2)

        parser.processTupletElement(startElement, noteId: UUID(), timeModification: timeMod)
        parser.addNoteToActiveTuplets(noteId: UUID())

        XCTAssertTrue(parser.hasActiveTuplets)

        parser.forceCompleteAll()

        XCTAssertFalse(parser.hasActiveTuplets)

        let tuplets = parser.harvestCompletedTuplets()
        XCTAssertEqual(tuplets.count, 1)
    }

    func testHarvestClearsTuplets() {
        let startElement = createElement(name: "tuplet", attributes: ["type": "start"])
        let timeMod = createTimeModification(actual: 3, normal: 2)

        parser.processTupletElement(startElement, noteId: UUID(), timeModification: timeMod)

        let stopElement = createElement(name: "tuplet", attributes: ["type": "stop"])
        parser.processTupletElement(stopElement, noteId: UUID(), timeModification: nil)

        let tuplets1 = parser.harvestCompletedTuplets()
        XCTAssertEqual(tuplets1.count, 1)

        let tuplets2 = parser.harvestCompletedTuplets()
        XCTAssertTrue(tuplets2.isEmpty)
    }

    func testStopWithoutStart() {
        let stopElement = createElement(name: "tuplet", attributes: ["type": "stop"])
        parser.processTupletElement(stopElement, noteId: UUID(), timeModification: nil)

        XCTAssertFalse(parser.hasActiveTuplets)
        let tuplets = parser.harvestCompletedTuplets()
        XCTAssertTrue(tuplets.isEmpty)
    }

    // MARK: - Time Modification Extraction Tests

    func testExtractTimeModification() {
        let noteElement = createElement(name: "note")
        let timeMod = createTimeModification(actual: 3, normal: 2)
        noteElement.addChild(timeMod)

        let result = TupletParser.extractTimeModification(from: noteElement)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.actual, 3)
        XCTAssertEqual(result?.normal, 2)
    }

    func testExtractTimeModificationMissing() {
        let noteElement = createElement(name: "note")

        let result = TupletParser.extractTimeModification(from: noteElement)
        XCTAssertNil(result)
    }

    func testHasTimeModification() {
        let noteElement = createElement(name: "note")
        XCTAssertFalse(TupletParser.hasTimeModification(noteElement))

        let timeMod = createTimeModification(actual: 3, normal: 2)
        noteElement.addChild(timeMod)
        XCTAssertTrue(TupletParser.hasTimeModification(noteElement))
    }

    // MARK: - Tuplet Validation Tests

    func testTupletIsComplete() {
        let startElement = createElement(name: "tuplet", attributes: ["type": "start"])
        let timeMod = createTimeModification(actual: 3, normal: 2)

        parser.processTupletElement(startElement, noteId: UUID(), timeModification: timeMod)
        parser.addNoteToActiveTuplets(noteId: UUID())

        let stopElement = createElement(name: "tuplet", attributes: ["type": "stop"])
        parser.processTupletElement(stopElement, noteId: UUID(), timeModification: nil)

        let tuplets = parser.harvestCompletedTuplets()
        XCTAssertTrue(tuplets[0].isComplete)
    }

    func testTupletIsValidRatio() {
        let startElement = createElement(name: "tuplet", attributes: ["type": "start"])
        let timeMod = createTimeModification(actual: 3, normal: 2)

        parser.processTupletElement(startElement, noteId: UUID(), timeModification: timeMod)

        let stopElement = createElement(name: "tuplet", attributes: ["type": "stop"])
        parser.processTupletElement(stopElement, noteId: UUID(), timeModification: nil)

        let tuplets = parser.harvestCompletedTuplets()
        XCTAssertTrue(tuplets[0].isValidRatio)
    }

    // MARK: - Tuplet Array Extension Tests

    func testGroupedByNumber() {
        // Create two tuplets with different numbers
        let startElement1 = createElement(name: "tuplet", attributes: ["type": "start", "number": "1"])
        let timeMod1 = createTimeModification(actual: 3, normal: 2)
        parser.processTupletElement(startElement1, noteId: UUID(), timeModification: timeMod1)

        let stopElement1 = createElement(name: "tuplet", attributes: ["type": "stop", "number": "1"])
        parser.processTupletElement(stopElement1, noteId: UUID(), timeModification: nil)

        let startElement2 = createElement(name: "tuplet", attributes: ["type": "start", "number": "2"])
        let timeMod2 = createTimeModification(actual: 5, normal: 4)
        parser.processTupletElement(startElement2, noteId: UUID(), timeModification: timeMod2)

        let stopElement2 = createElement(name: "tuplet", attributes: ["type": "stop", "number": "2"])
        parser.processTupletElement(stopElement2, noteId: UUID(), timeModification: nil)

        let tuplets = parser.harvestCompletedTuplets()
        let grouped = tuplets.groupedByNumber()

        XCTAssertEqual(grouped.count, 2)
        XCTAssertEqual(grouped[1]?.count, 1)
        XCTAssertEqual(grouped[2]?.count, 1)
    }

    func testOutermostTuplets() {
        // Create tuplets at different levels
        let startElement1 = createElement(name: "tuplet", attributes: ["type": "start", "number": "1"])
        let timeMod = createTimeModification(actual: 3, normal: 2)
        parser.processTupletElement(startElement1, noteId: UUID(), timeModification: timeMod)

        let startElement2 = createElement(name: "tuplet", attributes: ["type": "start", "number": "2"])
        parser.processTupletElement(startElement2, noteId: UUID(), timeModification: timeMod)

        let stopElement2 = createElement(name: "tuplet", attributes: ["type": "stop", "number": "2"])
        parser.processTupletElement(stopElement2, noteId: UUID(), timeModification: nil)

        let stopElement1 = createElement(name: "tuplet", attributes: ["type": "stop", "number": "1"])
        parser.processTupletElement(stopElement1, noteId: UUID(), timeModification: nil)

        let tuplets = parser.harvestCompletedTuplets()
        let outermost = tuplets.outermostTuplets

        XCTAssertEqual(outermost.count, 1)
        XCTAssertEqual(outermost[0].number, 1)
    }

    func testContainingNoteId() {
        let noteId1 = UUID()
        let noteId2 = UUID()

        let startElement = createElement(name: "tuplet", attributes: ["type": "start"])
        let timeMod = createTimeModification(actual: 3, normal: 2)
        parser.processTupletElement(startElement, noteId: noteId1, timeModification: timeMod)

        let stopElement = createElement(name: "tuplet", attributes: ["type": "stop"])
        parser.processTupletElement(stopElement, noteId: noteId2, timeModification: nil)

        let tuplets = parser.harvestCompletedTuplets()
        let containing = tuplets.containing(noteId: noteId1)

        XCTAssertEqual(containing.count, 1)
    }
}

// MARK: - BeamGrouper Tests

final class BeamGrouperTests: XCTestCase {

    private var grouper: BeamGrouper!

    override func setUp() {
        super.setUp()
        grouper = BeamGrouper()
    }

    func testInitialState() {
        XCTAssertTrue(grouper.completedGroups.isEmpty)
        XCTAssertTrue(grouper.warnings.isEmpty)
    }

    func testReset() {
        let beams = [BeamValue(number: 1, value: .begin)]
        grouper.process(beams: beams, noteIndex: 0, measureIndex: 0, voice: 1, staff: 1)
        grouper.finalize()

        XCTAssertFalse(grouper.completedGroups.isEmpty)

        grouper.reset()

        XCTAssertTrue(grouper.completedGroups.isEmpty)
        XCTAssertTrue(grouper.warnings.isEmpty)
    }

    func testSimpleBeamGroup() {
        grouper.process(beams: [BeamValue(number: 1, value: .begin)], noteIndex: 0, measureIndex: 0, voice: 1, staff: 1)
        grouper.process(beams: [BeamValue(number: 1, value: .continue)], noteIndex: 1, measureIndex: 0, voice: 1, staff: 1)
        grouper.process(beams: [BeamValue(number: 1, value: .end)], noteIndex: 2, measureIndex: 0, voice: 1, staff: 1)

        XCTAssertEqual(grouper.completedGroups.count, 1)

        let group = grouper.completedGroups[0]
        XCTAssertEqual(group.level, 1)
        XCTAssertEqual(group.noteCount, 3)
        XCTAssertEqual(group.startNoteIndex, 0)
        XCTAssertEqual(group.endNoteIndex, 2)
    }

    func testTwoNoteBeam() {
        grouper.process(beams: [BeamValue(number: 1, value: .begin)], noteIndex: 0, measureIndex: 0, voice: 1, staff: 1)
        grouper.process(beams: [BeamValue(number: 1, value: .end)], noteIndex: 1, measureIndex: 0, voice: 1, staff: 1)

        XCTAssertEqual(grouper.completedGroups.count, 1)
        XCTAssertEqual(grouper.completedGroups[0].noteCount, 2)
    }

    func testMultipleLevelBeams() {
        // Sixteenth note beam: level 1 and level 2
        grouper.process(beams: [
            BeamValue(number: 1, value: .begin),
            BeamValue(number: 2, value: .begin)
        ], noteIndex: 0, measureIndex: 0, voice: 1, staff: 1)

        grouper.process(beams: [
            BeamValue(number: 1, value: .continue),
            BeamValue(number: 2, value: .continue)
        ], noteIndex: 1, measureIndex: 0, voice: 1, staff: 1)

        grouper.process(beams: [
            BeamValue(number: 1, value: .end),
            BeamValue(number: 2, value: .end)
        ], noteIndex: 2, measureIndex: 0, voice: 1, staff: 1)

        XCTAssertEqual(grouper.completedGroups.count, 2)

        let levels = Set(grouper.completedGroups.map { $0.level })
        XCTAssertTrue(levels.contains(1))
        XCTAssertTrue(levels.contains(2))
    }

    func testForwardHook() {
        // Start a level 1 beam with a forward hook on level 2
        grouper.process(beams: [
            BeamValue(number: 1, value: .begin),
            BeamValue(number: 2, value: .forwardHook)
        ], noteIndex: 0, measureIndex: 0, voice: 1, staff: 1)

        grouper.process(beams: [
            BeamValue(number: 1, value: .end)
        ], noteIndex: 1, measureIndex: 0, voice: 1, staff: 1)

        XCTAssertEqual(grouper.completedGroups.count, 1)
        // Hook should be attached to the level 1 group
        XCTAssertTrue(grouper.completedGroups[0].notes.contains { $0.hook == .forwardHook })
    }

    func testBackwardHook() {
        grouper.process(beams: [
            BeamValue(number: 1, value: .begin),
            BeamValue(number: 2, value: .backwardHook)
        ], noteIndex: 0, measureIndex: 0, voice: 1, staff: 1)

        grouper.process(beams: [
            BeamValue(number: 1, value: .end)
        ], noteIndex: 1, measureIndex: 0, voice: 1, staff: 1)

        XCTAssertEqual(grouper.completedGroups.count, 1)
        XCTAssertTrue(grouper.completedGroups[0].notes.contains { $0.hook == .backwardHook })
    }

    func testEmptyBeamsIgnored() {
        grouper.process(beams: [], noteIndex: 0, measureIndex: 0, voice: 1, staff: 1)
        grouper.finalize()

        XCTAssertTrue(grouper.completedGroups.isEmpty)
    }

    func testContinueWithoutBeginWarning() {
        grouper.process(beams: [BeamValue(number: 1, value: .continue)], noteIndex: 0, measureIndex: 0, voice: 1, staff: 1)

        XCTAssertEqual(grouper.warnings.count, 1)
        XCTAssertTrue(grouper.warnings[0].contains("continue without begin"))
    }

    func testEndWithoutBeginWarning() {
        grouper.process(beams: [BeamValue(number: 1, value: .end)], noteIndex: 0, measureIndex: 0, voice: 1, staff: 1)

        XCTAssertEqual(grouper.warnings.count, 1)
        XCTAssertTrue(grouper.warnings[0].contains("end without begin"))
    }

    func testOrphanedBeamWarning() {
        grouper.process(beams: [BeamValue(number: 1, value: .begin)], noteIndex: 0, measureIndex: 0, voice: 1, staff: 1)
        grouper.finalize()

        XCTAssertEqual(grouper.warnings.count, 1)
        XCTAssertTrue(grouper.warnings[0].contains("Orphaned"))
        // Should still complete the partial group
        XCTAssertEqual(grouper.completedGroups.count, 1)
    }

    func testVoiceAndStaffTracking() {
        grouper.process(beams: [BeamValue(number: 1, value: .begin)], noteIndex: 0, measureIndex: 0, voice: 2, staff: 2)
        grouper.process(beams: [BeamValue(number: 1, value: .end)], noteIndex: 1, measureIndex: 0, voice: 2, staff: 2)

        XCTAssertEqual(grouper.completedGroups[0].voice, 2)
        XCTAssertEqual(grouper.completedGroups[0].staff, 2)
    }
}

// MARK: - SlurTracker Tests

final class SlurTrackerTests: XCTestCase {

    private var tracker: SlurTracker!

    override func setUp() {
        super.setUp()
        tracker = SlurTracker()
    }

    func testInitialState() {
        XCTAssertTrue(tracker.completedSlurs.isEmpty)
        XCTAssertTrue(tracker.warnings.isEmpty)
    }

    func testReset() {
        let slurs = [SlurNotation(type: .start, number: 1, placement: nil)]
        tracker.process(slurs: slurs, noteIndex: 0, measureIndex: 0, voice: 1, staff: 1)
        tracker.finalize()

        XCTAssertFalse(tracker.warnings.isEmpty)

        tracker.reset()

        XCTAssertTrue(tracker.completedSlurs.isEmpty)
        XCTAssertTrue(tracker.warnings.isEmpty)
    }

    func testSimpleSlur() {
        tracker.process(slurs: [SlurNotation(type: .start, number: 1, placement: nil)],
                       noteIndex: 0, measureIndex: 0, voice: 1, staff: 1)
        tracker.process(slurs: [SlurNotation(type: .stop, number: 1, placement: nil)],
                       noteIndex: 3, measureIndex: 0, voice: 1, staff: 1)

        XCTAssertEqual(tracker.completedSlurs.count, 1)

        let slur = tracker.completedSlurs[0]
        XCTAssertEqual(slur.number, 1)
        XCTAssertEqual(slur.startNoteIndex, 0)
        XCTAssertEqual(slur.stopNoteIndex, 3)
        XCTAssertEqual(slur.startMeasureIndex, 0)
        XCTAssertEqual(slur.stopMeasureIndex, 0)
    }

    func testCrossMeasureSlur() {
        tracker.process(slurs: [SlurNotation(type: .start, number: 1, placement: nil)],
                       noteIndex: 5, measureIndex: 2, voice: 1, staff: 1)
        tracker.process(slurs: [SlurNotation(type: .stop, number: 1, placement: nil)],
                       noteIndex: 2, measureIndex: 4, voice: 1, staff: 1)

        XCTAssertEqual(tracker.completedSlurs.count, 1)

        let slur = tracker.completedSlurs[0]
        XCTAssertEqual(slur.startMeasureIndex, 2)
        XCTAssertEqual(slur.stopMeasureIndex, 4)
    }

    func testSlurWithPlacement() {
        tracker.process(slurs: [SlurNotation(type: .start, number: 1, placement: .above)],
                       noteIndex: 0, measureIndex: 0, voice: 1, staff: 1)
        tracker.process(slurs: [SlurNotation(type: .stop, number: 1, placement: nil)],
                       noteIndex: 1, measureIndex: 0, voice: 1, staff: 1)

        XCTAssertEqual(tracker.completedSlurs[0].placement, Placement.above)
    }

    func testNestedSlurs() {
        // Outer slur number 1
        tracker.process(slurs: [SlurNotation(type: .start, number: 1, placement: nil)],
                       noteIndex: 0, measureIndex: 0, voice: 1, staff: 1)

        // Inner slur number 2
        tracker.process(slurs: [SlurNotation(type: .start, number: 2, placement: nil)],
                       noteIndex: 1, measureIndex: 0, voice: 1, staff: 1)

        tracker.process(slurs: [SlurNotation(type: .stop, number: 2, placement: nil)],
                       noteIndex: 2, measureIndex: 0, voice: 1, staff: 1)

        tracker.process(slurs: [SlurNotation(type: .stop, number: 1, placement: nil)],
                       noteIndex: 3, measureIndex: 0, voice: 1, staff: 1)

        XCTAssertEqual(tracker.completedSlurs.count, 2)

        let numbers = Set(tracker.completedSlurs.map { $0.number })
        XCTAssertTrue(numbers.contains(1))
        XCTAssertTrue(numbers.contains(2))
    }

    func testStopWithoutStartWarning() {
        tracker.process(slurs: [SlurNotation(type: .stop, number: 1, placement: nil)],
                       noteIndex: 0, measureIndex: 0, voice: 1, staff: 1)

        XCTAssertEqual(tracker.warnings.count, 1)
        XCTAssertTrue(tracker.warnings[0].contains("without matching start"))
    }

    func testOrphanedSlurWarning() {
        tracker.process(slurs: [SlurNotation(type: .start, number: 1, placement: nil)],
                       noteIndex: 0, measureIndex: 0, voice: 1, staff: 1)
        tracker.finalize()

        XCTAssertEqual(tracker.warnings.count, 1)
        XCTAssertTrue(tracker.warnings[0].contains("Orphaned"))
    }

    func testContinueType() {
        // Continue should just extend the slur
        tracker.process(slurs: [SlurNotation(type: .start, number: 1, placement: nil)],
                       noteIndex: 0, measureIndex: 0, voice: 1, staff: 1)
        tracker.process(slurs: [SlurNotation(type: .continue, number: 1, placement: nil)],
                       noteIndex: 1, measureIndex: 0, voice: 1, staff: 1)
        tracker.process(slurs: [SlurNotation(type: .stop, number: 1, placement: nil)],
                       noteIndex: 2, measureIndex: 0, voice: 1, staff: 1)

        XCTAssertEqual(tracker.completedSlurs.count, 1)
    }
}

// MARK: - TieTracker Tests

final class TieTrackerTests: XCTestCase {

    private var tracker: TieTracker!

    override func setUp() {
        super.setUp()
        tracker = TieTracker()
    }

    private func createNote(pitch: Pitch, ties: [Tie], voice: Int = 1, staff: Int = 1) -> Note {
        Note(
            noteType: .pitched(pitch),
            type: .quarter,
            voice: voice,
            staff: staff,
            ties: ties
        )
    }

    func testInitialState() {
        XCTAssertTrue(tracker.completedTies.isEmpty)
        XCTAssertTrue(tracker.warnings.isEmpty)
    }

    func testReset() {
        let pitch = Pitch(step: .c, octave: 4)
        let note = createNote(pitch: pitch, ties: [Tie(type: .start)])
        tracker.process(note: note, noteIndex: 0, measureIndex: 0)
        tracker.finalize()

        XCTAssertFalse(tracker.warnings.isEmpty)

        tracker.reset()

        XCTAssertTrue(tracker.completedTies.isEmpty)
        XCTAssertTrue(tracker.warnings.isEmpty)
    }

    func testSimpleTie() {
        let pitch = Pitch(step: .c, octave: 4)

        let startNote = createNote(pitch: pitch, ties: [Tie(type: .start)])
        tracker.process(note: startNote, noteIndex: 0, measureIndex: 0)

        let stopNote = createNote(pitch: pitch, ties: [Tie(type: .stop)])
        tracker.process(note: stopNote, noteIndex: 1, measureIndex: 0)

        XCTAssertEqual(tracker.completedTies.count, 1)

        let tie = tracker.completedTies[0]
        XCTAssertEqual(tie.startNoteIndex, 0)
        XCTAssertEqual(tie.stopNoteIndex, 1)
        XCTAssertEqual(tie.pitch, pitch)
    }

    func testCrossMeasureTie() {
        let pitch = Pitch(step: .g, octave: 5)

        let startNote = createNote(pitch: pitch, ties: [Tie(type: .start)])
        tracker.process(note: startNote, noteIndex: 3, measureIndex: 1)

        let stopNote = createNote(pitch: pitch, ties: [Tie(type: .stop)])
        tracker.process(note: stopNote, noteIndex: 0, measureIndex: 2)

        XCTAssertEqual(tracker.completedTies.count, 1)
        XCTAssertEqual(tracker.completedTies[0].startMeasureIndex, 1)
        XCTAssertEqual(tracker.completedTies[0].stopMeasureIndex, 2)
    }

    func testContinueTie() {
        let pitch = Pitch(step: .d, octave: 4)

        let startNote = createNote(pitch: pitch, ties: [Tie(type: .start)])
        tracker.process(note: startNote, noteIndex: 0, measureIndex: 0)

        let continueNote = createNote(pitch: pitch, ties: [Tie(type: .continue)])
        tracker.process(note: continueNote, noteIndex: 1, measureIndex: 1)

        let stopNote = createNote(pitch: pitch, ties: [Tie(type: .stop)])
        tracker.process(note: stopNote, noteIndex: 2, measureIndex: 2)

        // Continue creates two ties: start->continue and continue->stop
        XCTAssertEqual(tracker.completedTies.count, 2)
    }

    func testLetRing() {
        let pitch = Pitch(step: .e, octave: 3)

        let letRingNote = createNote(pitch: pitch, ties: [Tie(type: .letRing)])
        tracker.process(note: letRingNote, noteIndex: 0, measureIndex: 0)

        // Let ring just starts, might not have a stop
        tracker.finalize()

        // Will generate orphaned warning since there's no stop
        XCTAssertEqual(tracker.warnings.count, 1)
    }

    func testDifferentPitchesNotMatched() {
        let pitchC = Pitch(step: .c, octave: 4)
        let pitchD = Pitch(step: .d, octave: 4)

        let startNote = createNote(pitch: pitchC, ties: [Tie(type: .start)])
        tracker.process(note: startNote, noteIndex: 0, measureIndex: 0)

        let stopNote = createNote(pitch: pitchD, ties: [Tie(type: .stop)])
        tracker.process(note: stopNote, noteIndex: 1, measureIndex: 0)

        // Should have warning because pitches don't match
        XCTAssertEqual(tracker.warnings.count, 1)
        XCTAssertTrue(tracker.warnings[0].contains("without matching start"))
    }

    func testStopWithoutStartWarning() {
        let pitch = Pitch(step: .c, octave: 4)
        let note = createNote(pitch: pitch, ties: [Tie(type: .stop)])
        tracker.process(note: note, noteIndex: 0, measureIndex: 0)

        XCTAssertEqual(tracker.warnings.count, 1)
        XCTAssertTrue(tracker.warnings[0].contains("without matching start"))
    }

    func testOrphanedTieWarning() {
        let pitch = Pitch(step: .c, octave: 4)
        let note = createNote(pitch: pitch, ties: [Tie(type: .start)])
        tracker.process(note: note, noteIndex: 0, measureIndex: 0)

        tracker.finalize()

        XCTAssertEqual(tracker.warnings.count, 1)
        XCTAssertTrue(tracker.warnings[0].contains("Orphaned"))
    }

    func testMultipleTiesInChord() {
        let pitchC = Pitch(step: .c, octave: 4)
        let pitchE = Pitch(step: .e, octave: 4)
        let pitchG = Pitch(step: .g, octave: 4)

        // Start all three
        let startNoteC = createNote(pitch: pitchC, ties: [Tie(type: .start)])
        let startNoteE = createNote(pitch: pitchE, ties: [Tie(type: .start)])
        let startNoteG = createNote(pitch: pitchG, ties: [Tie(type: .start)])

        tracker.process(note: startNoteC, noteIndex: 0, measureIndex: 0)
        tracker.process(note: startNoteE, noteIndex: 1, measureIndex: 0)
        tracker.process(note: startNoteG, noteIndex: 2, measureIndex: 0)

        // Stop all three
        let stopNoteC = createNote(pitch: pitchC, ties: [Tie(type: .stop)])
        let stopNoteE = createNote(pitch: pitchE, ties: [Tie(type: .stop)])
        let stopNoteG = createNote(pitch: pitchG, ties: [Tie(type: .stop)])

        tracker.process(note: stopNoteC, noteIndex: 3, measureIndex: 1)
        tracker.process(note: stopNoteE, noteIndex: 4, measureIndex: 1)
        tracker.process(note: stopNoteG, noteIndex: 5, measureIndex: 1)

        XCTAssertEqual(tracker.completedTies.count, 3)

        let pitches = Set(tracker.completedTies.map { $0.pitch })
        XCTAssertTrue(pitches.contains(pitchC))
        XCTAssertTrue(pitches.contains(pitchE))
        XCTAssertTrue(pitches.contains(pitchG))
    }
}
