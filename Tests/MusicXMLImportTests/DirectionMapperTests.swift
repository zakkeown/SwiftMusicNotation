import XCTest
@testable import MusicXMLImport
@testable import MusicNotationCore

// Use typealias to resolve ambiguity with Foundation's XMLElement
typealias MusicXMLElement = MusicXMLImport.XMLElement

final class DirectionMapperTests: XCTestCase {

    private var mapper: DirectionMapper!
    private var context: XMLParserContext!

    override func setUp() {
        super.setUp()
        mapper = DirectionMapper()
        context = XMLParserContext()
    }

    // MARK: - Helper Methods

    private func createElement(name: String, attributes: [String: String] = [:], text: String? = nil) -> MusicXMLElement {
        let element = MusicXMLElement(name: name)
        for (key, value) in attributes {
            element.setAttribute(value, forKey: key)
        }
        if let text = text {
            element.textContent = text
        }
        return element
    }

    private func createDirection(placement: String? = nil, directive: Bool = false, children: [MusicXMLElement] = []) -> MusicXMLElement {
        var attrs: [String: String] = [:]
        if let placement = placement {
            attrs["placement"] = placement
        }
        if directive {
            attrs["directive"] = "yes"
        }
        let direction = createElement(name: "direction", attributes: attrs)
        for child in children {
            direction.addChild(child)
        }
        return direction
    }

    private func createDirectionType(children: [MusicXMLElement] = []) -> MusicXMLElement {
        let dirType = createElement(name: "direction-type")
        for child in children {
            dirType.addChild(child)
        }
        return dirType
    }

    // MARK: - Basic Direction Tests

    func testMapEmptyDirection() throws {
        let directionElement = createDirection()
        let direction = try mapper.mapDirection(from: directionElement, context: context)

        XCTAssertNil(direction.placement)
        XCTAssertFalse(direction.directive)
        XCTAssertEqual(direction.staff, 1)
        XCTAssertNil(direction.voice)
        XCTAssertTrue(direction.types.isEmpty)
        XCTAssertNil(direction.offset)
        XCTAssertNil(direction.sound)
    }

    func testMapDirectionWithPlacementAbove() throws {
        let directionElement = createDirection(placement: "above")
        let direction = try mapper.mapDirection(from: directionElement, context: context)

        XCTAssertEqual(direction.placement, .above)
    }

    func testMapDirectionWithPlacementBelow() throws {
        let directionElement = createDirection(placement: "below")
        let direction = try mapper.mapDirection(from: directionElement, context: context)

        XCTAssertEqual(direction.placement, .below)
    }

    func testMapDirectionWithDirective() throws {
        let directionElement = createDirection(directive: true)
        let direction = try mapper.mapDirection(from: directionElement, context: context)

        XCTAssertTrue(direction.directive)
    }

    func testMapDirectionWithStaff() throws {
        let directionElement = createDirection()
        let staffElement = createElement(name: "staff", text: "2")
        directionElement.addChild(staffElement)

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        XCTAssertEqual(direction.staff, 2)
    }

    func testMapDirectionWithVoice() throws {
        let directionElement = createDirection()
        let voiceElement = createElement(name: "voice", text: "3")
        directionElement.addChild(voiceElement)

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        XCTAssertEqual(direction.voice, 3)
    }

    func testMapDirectionWithOffset() throws {
        let directionElement = createDirection()
        let offsetElement = createElement(name: "offset", text: "10")
        directionElement.addChild(offsetElement)

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        XCTAssertEqual(direction.offset, 10)
    }

    // MARK: - Dynamics Tests

    func testMapDynamicsPiano() throws {
        let dynamicsElement = createElement(name: "dynamics")
        let pElement = createElement(name: "p")
        dynamicsElement.addChild(pElement)

        let dirType = createDirectionType(children: [dynamicsElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        XCTAssertEqual(direction.types.count, 1)
        if case .dynamics(let dyn) = direction.types[0] {
            XCTAssertEqual(dyn.values.count, 1)
            XCTAssertEqual(dyn.values[0], .p)
        } else {
            XCTFail("Expected dynamics direction type")
        }
    }

    func testMapDynamicsForte() throws {
        let dynamicsElement = createElement(name: "dynamics")
        let fElement = createElement(name: "f")
        dynamicsElement.addChild(fElement)

        let dirType = createDirectionType(children: [dynamicsElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        XCTAssertEqual(direction.types.count, 1)
        if case .dynamics(let dyn) = direction.types[0] {
            XCTAssertEqual(dyn.values[0], .f)
        } else {
            XCTFail("Expected dynamics direction type")
        }
    }

    func testMapDynamicsMezzoForte() throws {
        let dynamicsElement = createElement(name: "dynamics")
        let mfElement = createElement(name: "mf")
        dynamicsElement.addChild(mfElement)

        let dirType = createDirectionType(children: [dynamicsElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .dynamics(let dyn) = direction.types[0] {
            XCTAssertEqual(dyn.values[0], .mf)
        } else {
            XCTFail("Expected dynamics direction type")
        }
    }

    func testMapDynamicsSforzando() throws {
        let dynamicsElement = createElement(name: "dynamics")
        let sfzElement = createElement(name: "sfz")
        dynamicsElement.addChild(sfzElement)

        let dirType = createDirectionType(children: [dynamicsElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .dynamics(let dyn) = direction.types[0] {
            XCTAssertEqual(dyn.values[0], .sfz)
        } else {
            XCTFail("Expected dynamics direction type")
        }
    }

    func testMapDynamicsMultiple() throws {
        let dynamicsElement = createElement(name: "dynamics")
        let sfElement = createElement(name: "sf")
        let pElement = createElement(name: "p")
        dynamicsElement.addChild(sfElement)
        dynamicsElement.addChild(pElement)

        let dirType = createDirectionType(children: [dynamicsElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .dynamics(let dyn) = direction.types[0] {
            XCTAssertEqual(dyn.values.count, 2)
        } else {
            XCTFail("Expected dynamics direction type")
        }
    }

    func testMapAllDynamicTypes() throws {
        let allDynamics = ["p", "pp", "ppp", "pppp", "ppppp", "pppppp",
                          "f", "ff", "fff", "ffff", "fffff", "ffffff",
                          "mp", "mf", "sf", "sfp", "sfpp", "fp",
                          "rf", "rfz", "sfz", "sffz", "fz", "n", "pf", "sfzp"]

        for dynStr in allDynamics {
            let dynamicsElement = createElement(name: "dynamics")
            let dynElement = createElement(name: dynStr)
            dynamicsElement.addChild(dynElement)

            let dirType = createDirectionType(children: [dynamicsElement])
            let directionElement = createDirection(children: [dirType])

            let direction = try mapper.mapDirection(from: directionElement, context: context)

            if case .dynamics(let dyn) = direction.types[0] {
                XCTAssertFalse(dyn.values.isEmpty, "Should parse dynamic: \(dynStr)")
            } else {
                XCTFail("Expected dynamics for: \(dynStr)")
            }
        }
    }

    // MARK: - Wedge Tests

    func testMapWedgeCrescendo() throws {
        let wedgeElement = createElement(name: "wedge", attributes: ["type": "crescendo"])
        let dirType = createDirectionType(children: [wedgeElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .wedge(let wedge) = direction.types[0] {
            XCTAssertEqual(wedge.type, .crescendo)
            XCTAssertEqual(wedge.number, 1)
            XCTAssertNil(wedge.spread)
            XCTAssertFalse(wedge.niente)
        } else {
            XCTFail("Expected wedge direction type")
        }
    }

    func testMapWedgeDiminuendo() throws {
        let wedgeElement = createElement(name: "wedge", attributes: ["type": "diminuendo"])
        let dirType = createDirectionType(children: [wedgeElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .wedge(let wedge) = direction.types[0] {
            XCTAssertEqual(wedge.type, .diminuendo)
        } else {
            XCTFail("Expected wedge direction type")
        }
    }

    func testMapWedgeStop() throws {
        let wedgeElement = createElement(name: "wedge", attributes: ["type": "stop"])
        let dirType = createDirectionType(children: [wedgeElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .wedge(let wedge) = direction.types[0] {
            XCTAssertEqual(wedge.type, .stop)
        } else {
            XCTFail("Expected wedge direction type")
        }
    }

    func testMapWedgeWithNumber() throws {
        let wedgeElement = createElement(name: "wedge", attributes: ["type": "crescendo", "number": "2"])
        let dirType = createDirectionType(children: [wedgeElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .wedge(let wedge) = direction.types[0] {
            XCTAssertEqual(wedge.number, 2)
        } else {
            XCTFail("Expected wedge direction type")
        }
    }

    func testMapWedgeWithSpread() throws {
        let wedgeElement = createElement(name: "wedge", attributes: ["type": "crescendo", "spread": "15.5"])
        let dirType = createDirectionType(children: [wedgeElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .wedge(let wedge) = direction.types[0] {
            XCTAssertEqual(wedge.spread, 15.5)
        } else {
            XCTFail("Expected wedge direction type")
        }
    }

    func testMapWedgeWithNiente() throws {
        let wedgeElement = createElement(name: "wedge", attributes: ["type": "diminuendo", "niente": "yes"])
        let dirType = createDirectionType(children: [wedgeElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .wedge(let wedge) = direction.types[0] {
            XCTAssertTrue(wedge.niente)
        } else {
            XCTFail("Expected wedge direction type")
        }
    }

    // MARK: - Words Tests

    func testMapWordsSimple() throws {
        let wordsElement = createElement(name: "words", text: "dolce")
        let dirType = createDirectionType(children: [wordsElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .words(let words) = direction.types[0] {
            XCTAssertEqual(words.text, "dolce")
            XCTAssertNil(words.font)
            XCTAssertNil(words.justify)
        } else {
            XCTFail("Expected words direction type")
        }
    }

    func testMapWordsWithFont() throws {
        let wordsElement = createElement(name: "words", attributes: [
            "font-family": "Times New Roman",
            "font-size": "12.5",
            "font-style": "italic",
            "font-weight": "bold"
        ], text: "espressivo")
        let dirType = createDirectionType(children: [wordsElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .words(let words) = direction.types[0] {
            XCTAssertEqual(words.text, "espressivo")
            XCTAssertNotNil(words.font)
            XCTAssertEqual(words.font?.fontFamily, ["Times New Roman"])
            XCTAssertEqual(words.font?.fontSize, 12.5)
            XCTAssertEqual(words.font?.fontStyle, .italic)
            XCTAssertEqual(words.font?.fontWeight, .bold)
        } else {
            XCTFail("Expected words direction type")
        }
    }

    func testMapWordsWithJustify() throws {
        let wordsElement = createElement(name: "words", attributes: ["justify": "center"], text: "rit.")
        let dirType = createDirectionType(children: [wordsElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .words(let words) = direction.types[0] {
            XCTAssertEqual(words.justify, .center)
        } else {
            XCTFail("Expected words direction type")
        }
    }

    // MARK: - Rehearsal Tests

    func testMapRehearsalSimple() throws {
        let rehearsalElement = createElement(name: "rehearsal", text: "A")
        let dirType = createDirectionType(children: [rehearsalElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .rehearsal(let rehearsal) = direction.types[0] {
            XCTAssertEqual(rehearsal.text, "A")
            XCTAssertEqual(rehearsal.enclosure, .rectangle) // Default
        } else {
            XCTFail("Expected rehearsal direction type")
        }
    }

    func testMapRehearsalWithCircle() throws {
        let rehearsalElement = createElement(name: "rehearsal", attributes: ["enclosure": "circle"], text: "1")
        let dirType = createDirectionType(children: [rehearsalElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .rehearsal(let rehearsal) = direction.types[0] {
            XCTAssertEqual(rehearsal.text, "1")
            XCTAssertEqual(rehearsal.enclosure, .circle)
        } else {
            XCTFail("Expected rehearsal direction type")
        }
    }

    func testMapRehearsalWithSquare() throws {
        let rehearsalElement = createElement(name: "rehearsal", attributes: ["enclosure": "square"], text: "B")
        let dirType = createDirectionType(children: [rehearsalElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .rehearsal(let rehearsal) = direction.types[0] {
            XCTAssertEqual(rehearsal.enclosure, .square)
        } else {
            XCTFail("Expected rehearsal direction type")
        }
    }

    // MARK: - Metronome Tests

    func testMapMetronomeSimple() throws {
        let metronomeElement = createElement(name: "metronome")
        let beatUnit = createElement(name: "beat-unit", text: "quarter")
        let perMinute = createElement(name: "per-minute", text: "120")
        metronomeElement.addChild(beatUnit)
        metronomeElement.addChild(perMinute)

        let dirType = createDirectionType(children: [metronomeElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .metronome(let metronome) = direction.types[0] {
            XCTAssertEqual(metronome.beatUnit, .quarter)
            XCTAssertEqual(metronome.perMinute, "120")
            XCTAssertEqual(metronome.beatUnitDots, 0)
            XCTAssertNil(metronome.beatUnit2)
            XCTAssertFalse(metronome.parentheses)
        } else {
            XCTFail("Expected metronome direction type")
        }
    }

    func testMapMetronomeWithDot() throws {
        let metronomeElement = createElement(name: "metronome")
        let beatUnit = createElement(name: "beat-unit", text: "quarter")
        let beatUnitDot = createElement(name: "beat-unit-dot")
        let perMinute = createElement(name: "per-minute", text: "88")
        metronomeElement.addChild(beatUnit)
        metronomeElement.addChild(beatUnitDot)
        metronomeElement.addChild(perMinute)

        let dirType = createDirectionType(children: [metronomeElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .metronome(let metronome) = direction.types[0] {
            XCTAssertEqual(metronome.beatUnitDots, 1)
        } else {
            XCTFail("Expected metronome direction type")
        }
    }

    func testMapMetronomeEquivalent() throws {
        let metronomeElement = createElement(name: "metronome")
        let beatUnit1 = createElement(name: "beat-unit", text: "quarter")
        let beatUnit2 = createElement(name: "beat-unit", text: "half")
        metronomeElement.addChild(beatUnit1)
        metronomeElement.addChild(beatUnit2)

        let dirType = createDirectionType(children: [metronomeElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .metronome(let metronome) = direction.types[0] {
            XCTAssertEqual(metronome.beatUnit, .quarter)
            XCTAssertEqual(metronome.beatUnit2, .half)
            XCTAssertNil(metronome.perMinute)
        } else {
            XCTFail("Expected metronome direction type")
        }
    }

    func testMapMetronomeWithParentheses() throws {
        let metronomeElement = createElement(name: "metronome", attributes: ["parentheses": "yes"])
        let beatUnit = createElement(name: "beat-unit", text: "eighth")
        let perMinute = createElement(name: "per-minute", text: "144")
        metronomeElement.addChild(beatUnit)
        metronomeElement.addChild(perMinute)

        let dirType = createDirectionType(children: [metronomeElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .metronome(let metronome) = direction.types[0] {
            XCTAssertTrue(metronome.parentheses)
        } else {
            XCTFail("Expected metronome direction type")
        }
    }

    func testMapMetronomeWithNoBeatUnit() throws {
        let metronomeElement = createElement(name: "metronome")
        let perMinute = createElement(name: "per-minute", text: "120")
        metronomeElement.addChild(perMinute)

        let dirType = createDirectionType(children: [metronomeElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        // Should not add metronome type if beat-unit is missing
        XCTAssertTrue(direction.types.isEmpty)
    }

    // MARK: - Pedal Tests

    func testMapPedalStart() throws {
        let pedalElement = createElement(name: "pedal", attributes: ["type": "start"])
        let dirType = createDirectionType(children: [pedalElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .pedal(let pedal) = direction.types[0] {
            XCTAssertEqual(pedal.type, .start)
        } else {
            XCTFail("Expected pedal direction type")
        }
    }

    func testMapPedalStop() throws {
        let pedalElement = createElement(name: "pedal", attributes: ["type": "stop"])
        let dirType = createDirectionType(children: [pedalElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .pedal(let pedal) = direction.types[0] {
            XCTAssertEqual(pedal.type, .stop)
        } else {
            XCTFail("Expected pedal direction type")
        }
    }

    func testMapPedalWithLine() throws {
        let pedalElement = createElement(name: "pedal", attributes: ["type": "start", "line": "yes"])
        let dirType = createDirectionType(children: [pedalElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .pedal(let pedal) = direction.types[0] {
            XCTAssertEqual(pedal.line, true)
        } else {
            XCTFail("Expected pedal direction type")
        }
    }

    func testMapPedalWithSign() throws {
        let pedalElement = createElement(name: "pedal", attributes: ["type": "start", "sign": "yes"])
        let dirType = createDirectionType(children: [pedalElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .pedal(let pedal) = direction.types[0] {
            XCTAssertEqual(pedal.sign, true)
        } else {
            XCTFail("Expected pedal direction type")
        }
    }

    // MARK: - Octave Shift Tests

    func testMapOctaveShiftUp() throws {
        let octaveShiftElement = createElement(name: "octave-shift", attributes: ["type": "up", "size": "8"])
        let dirType = createDirectionType(children: [octaveShiftElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .octaveShift(let octaveShift) = direction.types[0] {
            XCTAssertEqual(octaveShift.type, .up)
            XCTAssertEqual(octaveShift.size, 8)
        } else {
            XCTFail("Expected octaveShift direction type")
        }
    }

    func testMapOctaveShiftDown() throws {
        let octaveShiftElement = createElement(name: "octave-shift", attributes: ["type": "down", "size": "15"])
        let dirType = createDirectionType(children: [octaveShiftElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .octaveShift(let octaveShift) = direction.types[0] {
            XCTAssertEqual(octaveShift.type, .down)
            XCTAssertEqual(octaveShift.size, 15)
        } else {
            XCTFail("Expected octaveShift direction type")
        }
    }

    func testMapOctaveShiftStop() throws {
        let octaveShiftElement = createElement(name: "octave-shift", attributes: ["type": "stop"])
        let dirType = createDirectionType(children: [octaveShiftElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .octaveShift(let octaveShift) = direction.types[0] {
            XCTAssertEqual(octaveShift.type, .stop)
        } else {
            XCTFail("Expected octaveShift direction type")
        }
    }

    // MARK: - Segno and Coda Tests

    func testMapSegno() throws {
        let segnoElement = createElement(name: "segno")
        let dirType = createDirectionType(children: [segnoElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .segno(let segno) = direction.types[0] {
            XCTAssertNil(segno.id)
        } else {
            XCTFail("Expected segno direction type")
        }
    }

    func testMapSegnoWithId() throws {
        let segnoElement = createElement(name: "segno", attributes: ["id": "segno1"])
        let dirType = createDirectionType(children: [segnoElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .segno(let segno) = direction.types[0] {
            XCTAssertEqual(segno.id, "segno1")
        } else {
            XCTFail("Expected segno direction type")
        }
    }

    func testMapCoda() throws {
        let codaElement = createElement(name: "coda")
        let dirType = createDirectionType(children: [codaElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .coda(let coda) = direction.types[0] {
            XCTAssertNil(coda.id)
        } else {
            XCTFail("Expected coda direction type")
        }
    }

    func testMapCodaWithId() throws {
        let codaElement = createElement(name: "coda", attributes: ["id": "coda1"])
        let dirType = createDirectionType(children: [codaElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .coda(let coda) = direction.types[0] {
            XCTAssertEqual(coda.id, "coda1")
        } else {
            XCTFail("Expected coda direction type")
        }
    }

    // MARK: - Dashes Tests

    func testMapDashesStart() throws {
        let dashesElement = createElement(name: "dashes", attributes: ["type": "start"])
        let dirType = createDirectionType(children: [dashesElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .dashes(let dashes) = direction.types[0] {
            XCTAssertEqual(dashes.type, .start)
            XCTAssertEqual(dashes.number, 1)
        } else {
            XCTFail("Expected dashes direction type")
        }
    }

    func testMapDashesStop() throws {
        let dashesElement = createElement(name: "dashes", attributes: ["type": "stop", "number": "2"])
        let dirType = createDirectionType(children: [dashesElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .dashes(let dashes) = direction.types[0] {
            XCTAssertEqual(dashes.type, StartStopContinue.stop)
            XCTAssertEqual(dashes.number, 2)
        } else {
            XCTFail("Expected dashes direction type")
        }
    }

    // MARK: - Bracket Tests

    func testMapBracketStart() throws {
        let bracketElement = createElement(name: "bracket", attributes: ["type": "start", "line-end": "down"])
        let dirType = createDirectionType(children: [bracketElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .bracket(let bracket) = direction.types[0] {
            XCTAssertEqual(bracket.type, StartStopContinue.start)
            XCTAssertEqual(bracket.lineEnd, LineEnd.down)
        } else {
            XCTFail("Expected bracket direction type")
        }
    }

    func testMapBracketStop() throws {
        let bracketElement = createElement(name: "bracket", attributes: ["type": "stop", "number": "1"])
        let dirType = createDirectionType(children: [bracketElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .bracket(let bracket) = direction.types[0] {
            XCTAssertEqual(bracket.type, StartStopContinue.stop)
            XCTAssertEqual(bracket.number, 1)
        } else {
            XCTFail("Expected bracket direction type")
        }
    }

    // MARK: - Sound Tests

    func testMapSoundWithTempo() throws {
        let soundElement = createElement(name: "sound", attributes: ["tempo": "120"])
        let directionElement = createDirection()
        directionElement.addChild(soundElement)

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        XCTAssertNotNil(direction.sound)
        XCTAssertEqual(direction.sound?.tempo, 120)
    }

    func testMapSoundWithDynamics() throws {
        let soundElement = createElement(name: "sound", attributes: ["dynamics": "80"])
        let directionElement = createDirection()
        directionElement.addChild(soundElement)

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        XCTAssertNotNil(direction.sound)
        XCTAssertEqual(direction.sound?.dynamics, 80)
    }

    func testMapSoundWithDaCapo() throws {
        let soundElement = createElement(name: "sound", attributes: ["dacapo": "yes"])
        let directionElement = createDirection()
        directionElement.addChild(soundElement)

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        XCTAssertNotNil(direction.sound)
        XCTAssertTrue(direction.sound?.dacapo ?? false)
    }

    func testMapSoundWithSegno() throws {
        let soundElement = createElement(name: "sound", attributes: ["segno": "segno1"])
        let directionElement = createDirection()
        directionElement.addChild(soundElement)

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        XCTAssertNotNil(direction.sound)
        XCTAssertEqual(direction.sound?.segno, "segno1")
    }

    func testMapSoundWithDalSegno() throws {
        let soundElement = createElement(name: "sound", attributes: ["dalsegno": "segno1"])
        let directionElement = createDirection()
        directionElement.addChild(soundElement)

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        XCTAssertNotNil(direction.sound)
        XCTAssertEqual(direction.sound?.dalsegno, "segno1")
    }

    func testMapSoundWithCoda() throws {
        let soundElement = createElement(name: "sound", attributes: ["coda": "coda1", "tocoda": "coda2"])
        let directionElement = createDirection()
        directionElement.addChild(soundElement)

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        XCTAssertNotNil(direction.sound)
        XCTAssertEqual(direction.sound?.coda, "coda1")
        XCTAssertEqual(direction.sound?.tocoda, "coda2")
    }

    func testMapSoundWithFine() throws {
        let soundElement = createElement(name: "sound", attributes: ["fine": "yes"])
        let directionElement = createDirection()
        directionElement.addChild(soundElement)

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        XCTAssertNotNil(direction.sound)
        XCTAssertTrue(direction.sound?.fine ?? false)
    }

    func testMapSoundWithForwardRepeat() throws {
        let soundElement = createElement(name: "sound", attributes: ["forward-repeat": "yes"])
        let directionElement = createDirection()
        directionElement.addChild(soundElement)

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        XCTAssertNotNil(direction.sound)
        XCTAssertTrue(direction.sound?.forwardRepeat ?? false)
    }

    // MARK: - Multiple Direction Types

    func testMapMultipleDirectionTypes() throws {
        let dynamicsElement = createElement(name: "dynamics")
        let pElement = createElement(name: "p")
        dynamicsElement.addChild(pElement)

        let wordsElement = createElement(name: "words", text: "dolce")

        let dirType1 = createDirectionType(children: [dynamicsElement])
        let dirType2 = createDirectionType(children: [wordsElement])
        let directionElement = createDirection(children: [dirType1, dirType2])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        XCTAssertEqual(direction.types.count, 2)
    }

    func testMapMultipleDirectionTypesInSameBlock() throws {
        let dynamicsElement = createElement(name: "dynamics")
        let pElement = createElement(name: "p")
        dynamicsElement.addChild(pElement)

        let wordsElement = createElement(name: "words", text: "dolce")

        let dirType = createDirectionType(children: [dynamicsElement, wordsElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        XCTAssertEqual(direction.types.count, 2)
    }

    // MARK: - Other Direction Tests

    func testMapOtherDirection() throws {
        let otherElement = createElement(name: "other-direction", text: "custom marking")
        let dirType = createDirectionType(children: [otherElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .otherDirection(let other) = direction.types[0] {
            XCTAssertEqual(other.text, "custom marking")
        } else {
            XCTFail("Expected otherDirection type")
        }
    }

    // MARK: - Accordion Registration Tests

    func testMapAccordionRegistration() throws {
        let accordionElement = createElement(name: "accordion-registration")
        let highElement = createElement(name: "accordion-high")
        let middleElement = createElement(name: "accordion-middle", text: "2")
        let lowElement = createElement(name: "accordion-low")
        accordionElement.addChild(highElement)
        accordionElement.addChild(middleElement)
        accordionElement.addChild(lowElement)

        let dirType = createDirectionType(children: [accordionElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .accordionRegistration(let accordion) = direction.types[0] {
            XCTAssertEqual(accordion.accordionHigh, true)
            XCTAssertEqual(accordion.accordionMiddle, 2)
            XCTAssertEqual(accordion.accordionLow, true)
        } else {
            XCTFail("Expected accordionRegistration type")
        }
    }

    // MARK: - Principal Voice Tests

    func testMapPrincipalVoiceStart() throws {
        let principalElement = createElement(name: "principal-voice", attributes: ["type": "start", "symbol": "Hauptstimme"])
        let dirType = createDirectionType(children: [principalElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .principalVoice(let pv) = direction.types[0] {
            XCTAssertEqual(pv.type, StartStop.start)
            XCTAssertEqual(pv.symbol, PrincipalVoiceSymbol.hauptstimme)
        } else {
            XCTFail("Expected principalVoice type")
        }
    }

    func testMapPrincipalVoiceStop() throws {
        let principalElement = createElement(name: "principal-voice", attributes: ["type": "stop"])
        let dirType = createDirectionType(children: [principalElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .principalVoice(let pv) = direction.types[0] {
            XCTAssertEqual(pv.type, StartStop.stop)
        } else {
            XCTFail("Expected principalVoice type")
        }
    }

    // MARK: - Harp Pedals Tests

    func testMapHarpPedals() throws {
        let harpPedalsElement = createElement(name: "harp-pedals")

        let tuning1 = createElement(name: "pedal-tuning")
        let step1 = createElement(name: "pedal-step", text: "C")
        let alter1 = createElement(name: "pedal-alter", text: "0")
        tuning1.addChild(step1)
        tuning1.addChild(alter1)

        let tuning2 = createElement(name: "pedal-tuning")
        let step2 = createElement(name: "pedal-step", text: "D")
        let alter2 = createElement(name: "pedal-alter", text: "-1")
        tuning2.addChild(step2)
        tuning2.addChild(alter2)

        harpPedalsElement.addChild(tuning1)
        harpPedalsElement.addChild(tuning2)

        let dirType = createDirectionType(children: [harpPedalsElement])
        let directionElement = createDirection(children: [dirType])

        let direction = try mapper.mapDirection(from: directionElement, context: context)

        if case .harpPedals(let harpPedals) = direction.types[0] {
            XCTAssertEqual(harpPedals.pedalTuning.count, 2)
            XCTAssertEqual(harpPedals.pedalTuning[0].pedalStep, PitchStep.c)
            XCTAssertEqual(harpPedals.pedalTuning[0].pedalAlter, 0)
            XCTAssertEqual(harpPedals.pedalTuning[1].pedalStep, PitchStep.d)
            XCTAssertEqual(harpPedals.pedalTuning[1].pedalAlter, -1)
        } else {
            XCTFail("Expected harpPedals type")
        }
    }
}
