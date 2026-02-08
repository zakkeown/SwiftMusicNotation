import XCTest
@testable import MusicXMLExport
@testable import MusicNotationCore

final class MusicXMLExportDirectionsTests: XCTestCase {

    // MARK: - Helper

    private func makeScore(withDirection direction: Direction) -> Score {
        let measure = Measure(
            number: "1",
            elements: [.direction(direction)],
            attributes: MeasureAttributes(divisions: 1)
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        return Score(parts: [part])
    }

    // MARK: - Wedge Tests

    func testExportCrescendoWedge() throws {
        let direction = Direction(
            placement: .below,
            staff: 1,
            types: [.wedge(Wedge(type: .crescendo))]
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(makeScore(withDirection: direction))

        XCTAssertTrue(xml.contains("<wedge"), "Should contain wedge element")
        XCTAssertTrue(xml.contains("type=\"crescendo\""), "Should have crescendo type")
    }

    func testExportDiminuendoWedge() throws {
        let direction = Direction(
            placement: .below,
            staff: 1,
            types: [.wedge(Wedge(type: .diminuendo))]
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(makeScore(withDirection: direction))

        XCTAssertTrue(xml.contains("type=\"diminuendo\""), "Should have diminuendo type")
    }

    func testExportWedgeStop() throws {
        let direction = Direction(
            staff: 1,
            types: [.wedge(Wedge(type: .stop))]
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(makeScore(withDirection: direction))

        XCTAssertTrue(xml.contains("type=\"stop\""), "Should have stop type")
    }

    func testExportWedgeNiente() throws {
        let direction = Direction(
            placement: .below,
            staff: 1,
            types: [.wedge(Wedge(type: .crescendo, niente: true))]
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(makeScore(withDirection: direction))

        XCTAssertTrue(xml.contains("niente=\"yes\""), "Should have niente=yes")
    }

    // MARK: - Metronome Tests

    func testExportMetronome() throws {
        let direction = Direction(
            placement: .above,
            staff: 1,
            types: [.metronome(Metronome(beatUnit: .quarter, perMinute: "120"))]
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(makeScore(withDirection: direction))

        XCTAssertTrue(xml.contains("<metronome>"), "Should contain metronome element")
        XCTAssertTrue(xml.contains("<beat-unit>quarter</beat-unit>"), "Should contain beat-unit quarter")
        XCTAssertTrue(xml.contains("<per-minute>120</per-minute>"), "Should contain per-minute 120")
    }

    func testExportDottedMetronome() throws {
        let direction = Direction(
            placement: .above,
            staff: 1,
            types: [.metronome(Metronome(beatUnit: .quarter, beatUnitDots: 1, perMinute: "80"))]
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(makeScore(withDirection: direction))

        XCTAssertTrue(xml.contains("<beat-unit-dot"), "Should contain beat-unit-dot element")
    }

    // MARK: - Rehearsal Tests

    func testExportRehearsalMark() throws {
        let direction = Direction(
            placement: .above,
            staff: 1,
            types: [.rehearsal(Rehearsal(text: "A", enclosure: .rectangle))]
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(makeScore(withDirection: direction))

        XCTAssertTrue(xml.contains("<rehearsal"), "Should contain rehearsal element")
        XCTAssertTrue(xml.contains("enclosure=\"rectangle\""), "Should have rectangle enclosure")
        XCTAssertTrue(xml.contains(">A</rehearsal>"), "Should contain rehearsal text A")
    }

    // MARK: - Words Tests

    func testExportWords() throws {
        let direction = Direction(
            placement: .below,
            staff: 1,
            types: [.words(Words(text: "dolce"))]
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(makeScore(withDirection: direction))

        XCTAssertTrue(xml.contains("<words>dolce</words>"), "Should contain words element with dolce")
    }

    // MARK: - Segno and Coda Tests

    func testExportSegno() throws {
        let direction = Direction(
            placement: .above,
            staff: 1,
            types: [.segno(Segno())]
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(makeScore(withDirection: direction))

        XCTAssertTrue(xml.contains("<segno"), "Should contain segno element")
    }

    func testExportCoda() throws {
        let direction = Direction(
            placement: .above,
            staff: 1,
            types: [.coda(Coda())]
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(makeScore(withDirection: direction))

        XCTAssertTrue(xml.contains("<coda"), "Should contain coda element")
    }

    // MARK: - Dashes Tests

    func testExportDashes() throws {
        let direction = Direction(
            staff: 1,
            types: [.dashes(Dashes(type: .start))]
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(makeScore(withDirection: direction))

        XCTAssertTrue(xml.contains("<dashes"), "Should contain dashes element")
        XCTAssertTrue(xml.contains("type=\"start\""), "Should have start type")
    }

    // MARK: - Bracket Tests

    func testExportBracket() throws {
        let direction = Direction(
            staff: 1,
            types: [.bracket(DirectionBracket(type: .start, lineEnd: .down))]
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(makeScore(withDirection: direction))

        XCTAssertTrue(xml.contains("<bracket"), "Should contain bracket element")
        XCTAssertTrue(xml.contains("type=\"start\""), "Should have start type")
        XCTAssertTrue(xml.contains("line-end=\"down\""), "Should have line-end=down")
    }

    // MARK: - Pedal Tests

    func testExportPedalStart() throws {
        let direction = Direction(
            placement: .below,
            staff: 1,
            types: [.pedal(Pedal(type: .start))]
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(makeScore(withDirection: direction))

        XCTAssertTrue(xml.contains("<pedal"), "Should contain pedal element")
        XCTAssertTrue(xml.contains("type=\"start\""), "Should have start type")
    }

    func testExportPedalStop() throws {
        let direction = Direction(
            placement: .below,
            staff: 1,
            types: [.pedal(Pedal(type: .stop))]
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(makeScore(withDirection: direction))

        XCTAssertTrue(xml.contains("type=\"stop\""), "Should have stop type")
    }

    // MARK: - Octave Shift Tests

    func testExportOctaveShiftUp() throws {
        let direction = Direction(
            placement: .above,
            staff: 1,
            types: [.octaveShift(OctaveShift(type: .up, size: 8))]
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(makeScore(withDirection: direction))

        XCTAssertTrue(xml.contains("<octave-shift"), "Should contain octave-shift element")
        XCTAssertTrue(xml.contains("type=\"up\""), "Should have up type")
        XCTAssertTrue(xml.contains("size=\"8\""), "Should have size=8")
    }

    func testExportOctaveShiftDown() throws {
        let direction = Direction(
            placement: .below,
            staff: 1,
            types: [.octaveShift(OctaveShift(type: .down, size: 8))]
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(makeScore(withDirection: direction))

        XCTAssertTrue(xml.contains("type=\"down\""), "Should have down type")
    }

    // MARK: - Direction Attributes Tests

    func testExportDirectionPlacement() throws {
        let direction = Direction(
            placement: .above,
            staff: 1,
            types: [.words(Words(text: "test"))]
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(makeScore(withDirection: direction))

        XCTAssertTrue(xml.contains("<direction placement=\"above\">"), "Should have direction with above placement")
    }

    func testExportDirectionWithOffset() throws {
        let direction = Direction(
            staff: 1,
            types: [.words(Words(text: "test"))],
            offset: 2
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(makeScore(withDirection: direction))

        XCTAssertTrue(xml.contains("<offset>2</offset>"), "Should contain offset element with value 2")
    }

    func testExportDirectionWithSound() throws {
        let direction = Direction(
            staff: 1,
            types: [.words(Words(text: "Allegro"))],
            sound: Sound(tempo: 120)
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(makeScore(withDirection: direction))

        XCTAssertTrue(xml.contains("<sound"), "Should contain sound element")
        XCTAssertTrue(xml.contains("tempo=\"120"), "Should have tempo=120")
    }

    // MARK: - Dynamics Multiple Values Tests

    func testExportDynamicsMultipleValues() throws {
        let direction = Direction(
            placement: .below,
            staff: 1,
            types: [.dynamics(DynamicsDirection(values: [.sfz]))]
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(makeScore(withDirection: direction))

        XCTAssertTrue(xml.contains("<dynamics>"), "Should contain dynamics wrapper")
        XCTAssertTrue(xml.contains("<sfz"), "Should contain sfz element")
    }
}
