import XCTest
@testable import MusicXMLExport
@testable import MusicNotationCore

final class MusicXMLExportMultiVoiceTests: XCTestCase {

    // MARK: - Backup Tests

    func testExportBackup() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 4,
            type: .quarter,
            voice: 1,
            staff: 1
        )

        let measure = Measure(
            number: "1",
            elements: [
                .note(note),
                .backup(Backup(duration: 4)),
            ],
            attributes: MeasureAttributes(divisions: 4)
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<backup>"), "Should contain backup element")
        XCTAssertTrue(xml.contains("<duration>4</duration>"), "Should have duration 4")
    }

    // MARK: - Forward Tests

    func testExportForward() throws {
        let measure = Measure(
            number: "1",
            elements: [
                .forward(Forward(duration: 2, voice: 2, staff: 1)),
            ],
            attributes: MeasureAttributes(divisions: 4)
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<forward>"), "Should contain forward element")
        XCTAssertTrue(xml.contains("<duration>2</duration>"), "Should have duration 2")
        XCTAssertTrue(xml.contains("<voice>2</voice>"), "Should have voice 2")
        XCTAssertTrue(xml.contains("<staff>1</staff>"), "Should have staff 1")
    }

    // MARK: - Two Voices Tests

    func testExportTwoVoices() throws {
        let voice1Note = Note(
            noteType: .pitched(Pitch(step: .e, octave: 5)),
            durationDivisions: 4,
            type: .quarter,
            voice: 1,
            staff: 1
        )

        let voice2Note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 4,
            type: .quarter,
            voice: 2,
            staff: 1
        )

        let measure = Measure(
            number: "1",
            elements: [
                .note(voice1Note),
                .backup(Backup(duration: 4)),
                .note(voice2Note),
            ],
            attributes: MeasureAttributes(divisions: 4)
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<voice>1</voice>"), "Should have voice 1")
        XCTAssertTrue(xml.contains("<voice>2</voice>"), "Should have voice 2")
        XCTAssertTrue(xml.contains("<backup>"), "Should have backup between voices")
    }

    // MARK: - Multi-Staff Tests

    func testExportMultiStaffPart() throws {
        let trebleNote = Note(
            noteType: .pitched(Pitch(step: .c, octave: 5)),
            durationDivisions: 4,
            type: .quarter,
            voice: 1,
            staff: 1
        )

        let bassNote = Note(
            noteType: .pitched(Pitch(step: .c, octave: 3)),
            durationDivisions: 4,
            type: .quarter,
            voice: 2,
            staff: 2
        )

        let measure = Measure(
            number: "1",
            elements: [
                .note(trebleNote),
                .backup(Backup(duration: 4)),
                .note(bassNote),
            ],
            attributes: MeasureAttributes(
                divisions: 4,
                staves: 2,
                clefs: [
                    Clef(sign: .g, line: 2, staffNumber: 1),
                    Clef(sign: .f, line: 4, staffNumber: 2),
                ]
            )
        )
        let part = Part(id: "P1", name: "Piano", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<staves>2</staves>"), "Should have 2 staves")
        XCTAssertTrue(xml.contains("<staff>1</staff>"), "Should have staff 1")
        XCTAssertTrue(xml.contains("<staff>2</staff>"), "Should have staff 2")
    }

    func testExportClefPerStaff() throws {
        let measure = Measure(
            number: "1",
            attributes: MeasureAttributes(
                staves: 2,
                clefs: [
                    Clef(sign: .g, line: 2, staffNumber: 1),
                    Clef(sign: .f, line: 4, staffNumber: 2),
                ]
            )
        )
        let part = Part(id: "P1", name: "Piano", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<clef number=\"1\">"), "Should have clef number 1")
        XCTAssertTrue(xml.contains("<clef number=\"2\">"), "Should have clef number 2")
    }

    // MARK: - Transpose Tests

    func testExportTranspose() throws {
        let measure = Measure(
            number: "1",
            attributes: MeasureAttributes(
                transposes: [Transpose(diatonic: -1, chromatic: -2)]
            )
        )
        let part = Part(id: "P1", name: "Clarinet", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<transpose>"), "Should contain transpose element")
        XCTAssertTrue(xml.contains("<diatonic>-1</diatonic>"), "Should have diatonic -1")
        XCTAssertTrue(xml.contains("<chromatic>-2</chromatic>"), "Should have chromatic -2")
    }

    func testExportTransposeOctaveChange() throws {
        let measure = Measure(
            number: "1",
            attributes: MeasureAttributes(
                transposes: [Transpose(diatonic: 0, chromatic: 0, octaveChange: -1)]
            )
        )
        let part = Part(id: "P1", name: "Bass", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<octave-change>-1</octave-change>"), "Should have octave-change -1")
    }

    // MARK: - Sound Tests

    func testExportSoundTempo() throws {
        let measure = Measure(
            number: "1",
            elements: [.sound(Sound(tempo: 120))],
            attributes: MeasureAttributes(divisions: 1)
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<sound"), "Should contain sound element")
        XCTAssertTrue(xml.contains("tempo=\"120"), "Should have tempo=120")
    }

    func testExportSoundDynamics() throws {
        let measure = Measure(
            number: "1",
            elements: [.sound(Sound(dynamics: 80))],
            attributes: MeasureAttributes(divisions: 1)
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("dynamics=\"80"), "Should have dynamics=80")
    }

    func testExportSoundDacapo() throws {
        let measure = Measure(
            number: "1",
            elements: [.sound(Sound(dacapo: true))],
            attributes: MeasureAttributes(divisions: 1)
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("dacapo=\"yes\""), "Should have dacapo=yes")
    }

    func testExportSoundSegno() throws {
        let measure = Measure(
            number: "1",
            elements: [.sound(Sound(segno: "S1"))],
            attributes: MeasureAttributes(divisions: 1)
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("segno=\"S1\""), "Should have segno=S1")
    }

    func testExportSoundFine() throws {
        let measure = Measure(
            number: "1",
            elements: [.sound(Sound(fine: true))],
            attributes: MeasureAttributes(divisions: 1)
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("fine=\"yes\""), "Should have fine=yes")
    }

    // MARK: - Print Attributes Tests

    func testExportPrintNewSystem() throws {
        let measure = Measure(
            number: "2",
            attributes: MeasureAttributes(divisions: 1),
            printAttributes: PrintAttributes(newSystem: true)
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("new-system=\"yes\""), "Should have new-system=yes")
    }

    func testExportPrintNewPage() throws {
        let measure = Measure(
            number: "2",
            attributes: MeasureAttributes(divisions: 1),
            printAttributes: PrintAttributes(newPage: true)
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("new-page=\"yes\""), "Should have new-page=yes")
    }
}
