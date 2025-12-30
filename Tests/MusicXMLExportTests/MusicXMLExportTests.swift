import XCTest
@testable import MusicXMLExport
@testable import MusicNotationCore

final class MusicXMLExportTests: XCTestCase {

    // MARK: - Basic Export Tests

    func testExportEmptyScore() throws {
        let score = Score(
            metadata: ScoreMetadata(workTitle: "Test Score"),
            parts: []
        )

        let exporter = MusicXMLExporter()
        let data = try exporter.export(score)

        XCTAssertFalse(data.isEmpty)

        let xml = try exporter.exportToString(score)
        XCTAssertTrue(xml.contains("score-partwise"))
        XCTAssertTrue(xml.contains("Test Score"))
    }

    func testExportScoreWithSinglePart() throws {
        let measure = Measure(
            number: "1",
            elements: [],
            attributes: MeasureAttributes(
                divisions: 1,
                keySignatures: [KeySignature(fifths: 0)],
                timeSignatures: [TimeSignature(beats: "4", beatType: "4")],
                clefs: [Clef.treble]
            )
        )

        let part = Part(
            id: "P1",
            name: "Piano",
            measures: [measure]
        )

        let score = Score(
            metadata: ScoreMetadata(workTitle: "Single Part Test"),
            parts: [part]
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<part-list>"))
        XCTAssertTrue(xml.contains("<score-part id=\"P1\">"))
        XCTAssertTrue(xml.contains("<part-name>Piano</part-name>"))
        XCTAssertTrue(xml.contains("<part id=\"P1\">"))
        XCTAssertTrue(xml.contains("<measure number=\"1\">"))
    }

    func testExportNotes() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, alter: 0, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            dots: 0,
            voice: 1,
            staff: 1
        )

        let measure = Measure(
            number: "1",
            elements: [.note(note)],
            attributes: MeasureAttributes(divisions: 1)
        )

        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<note>"))
        XCTAssertTrue(xml.contains("<pitch>"))
        XCTAssertTrue(xml.contains("<step>C</step>"))
        XCTAssertTrue(xml.contains("<octave>4</octave>"))
        XCTAssertTrue(xml.contains("<duration>1</duration>"))
        XCTAssertTrue(xml.contains("<type>quarter</type>"))
    }

    func testExportRest() throws {
        let rest = Note(
            noteType: .rest(RestInfo(measureRest: false)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1
        )

        let measure = Measure(
            number: "1",
            elements: [.note(rest)],
            attributes: MeasureAttributes(divisions: 1)
        )

        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<rest/>") || xml.contains("<rest></rest>") || xml.contains("<rest "))
        XCTAssertFalse(xml.contains("<pitch>"))
    }

    func testExportChord() throws {
        let note1 = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 2,
            type: .half,
            voice: 1,
            staff: 1,
            isChordTone: false
        )

        let note2 = Note(
            noteType: .pitched(Pitch(step: .e, octave: 4)),
            durationDivisions: 2,
            type: .half,
            voice: 1,
            staff: 1,
            isChordTone: true
        )

        let note3 = Note(
            noteType: .pitched(Pitch(step: .g, octave: 4)),
            durationDivisions: 2,
            type: .half,
            voice: 1,
            staff: 1,
            isChordTone: true
        )

        let measure = Measure(
            number: "1",
            elements: [.note(note1), .note(note2), .note(note3)],
            attributes: MeasureAttributes(divisions: 2)
        )

        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        // Should have <chord/> elements for chord tones
        let chordCount = xml.components(separatedBy: "<chord").count - 1
        XCTAssertEqual(chordCount, 2, "Should have 2 chord elements")
    }

    // MARK: - Key Signature Export Tests

    func testExportKeySignatures() throws {
        let keySigs: [(Int, String)] = [
            (0, "0"),   // C major
            (1, "1"),   // G major
            (-1, "-1"), // F major
            (2, "2"),   // D major
            (-2, "-2")  // Bb major
        ]

        for (fifths, expected) in keySigs {
            let measure = Measure(
                number: "1",
                attributes: MeasureAttributes(
                    keySignatures: [KeySignature(fifths: fifths)]
                )
            )
            let part = Part(id: "P1", name: "Test", measures: [measure])
            let score = Score(parts: [part])

            let exporter = MusicXMLExporter()
            let xml = try exporter.exportToString(score)

            XCTAssertTrue(xml.contains("<fifths>\(expected)</fifths>"),
                "Should export fifths=\(expected) for key signature \(fifths)")
        }
    }

    // MARK: - Time Signature Export Tests

    func testExportTimeSignatures() throws {
        let timeSigs: [(String, String)] = [
            ("4", "4"),
            ("3", "4"),
            ("6", "8"),
            ("2", "2"),
            ("5", "4")
        ]

        for (beats, beatType) in timeSigs {
            let measure = Measure(
                number: "1",
                attributes: MeasureAttributes(
                    timeSignatures: [TimeSignature(beats: beats, beatType: beatType)]
                )
            )
            let part = Part(id: "P1", name: "Test", measures: [measure])
            let score = Score(parts: [part])

            let exporter = MusicXMLExporter()
            let xml = try exporter.exportToString(score)

            XCTAssertTrue(xml.contains("<beats>\(beats)</beats>"))
            XCTAssertTrue(xml.contains("<beat-type>\(beatType)</beat-type>"))
        }
    }

    func testExportCommonTime() throws {
        let measure = Measure(
            number: "1",
            attributes: MeasureAttributes(
                timeSignatures: [TimeSignature(beats: "4", beatType: "4", symbol: .common)]
            )
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("symbol=\"common\""))
    }

    // MARK: - Clef Export Tests

    func testExportClefs() throws {
        let clefs: [(Clef, String, Int)] = [
            (.treble, "G", 2),
            (.bass, "F", 4),
            (.alto, "C", 3),
            (.tenor, "C", 4)
        ]

        for (clef, sign, line) in clefs {
            let measure = Measure(
                number: "1",
                attributes: MeasureAttributes(clefs: [clef])
            )
            let part = Part(id: "P1", name: "Test", measures: [measure])
            let score = Score(parts: [part])

            let exporter = MusicXMLExporter()
            let xml = try exporter.exportToString(score)

            XCTAssertTrue(xml.contains("<sign>\(sign)</sign>"))
            XCTAssertTrue(xml.contains("<line>\(line)</line>"))
        }
    }

    // MARK: - Accidental Export Tests

    func testExportAccidentals() throws {
        let noteWithAccidental = Note(
            noteType: .pitched(Pitch(step: .f, alter: 1, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            accidental: AccidentalMark(accidental: .sharp)
        )

        let measure = Measure(
            number: "1",
            elements: [.note(noteWithAccidental)],
            attributes: MeasureAttributes(divisions: 1)
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<alter>1</alter>"))
        XCTAssertTrue(xml.contains("<accidental>sharp</accidental>"))
    }

    // MARK: - Dotted Note Export Tests

    func testExportDottedNotes() throws {
        let dottedQuarter = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 3, // With divisions=2, this is 1.5 quarters
            type: .quarter,
            dots: 1,
            voice: 1,
            staff: 1
        )

        let measure = Measure(
            number: "1",
            elements: [.note(dottedQuarter)],
            attributes: MeasureAttributes(divisions: 2)
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<dot/>") || xml.contains("<dot></dot>"))
    }

    // MARK: - Barline Export Tests

    func testExportBarlines() throws {
        let measure = Measure(
            number: "1",
            rightBarline: Barline(location: .right, barStyle: .lightHeavy)
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<barline"))
        XCTAssertTrue(xml.contains("<bar-style>light-heavy</bar-style>"))
    }

    func testExportRepeatBarline() throws {
        let measure = Measure(
            number: "1",
            leftBarline: Barline(
                location: .left,
                barStyle: .heavyLight,
                repeatDirection: .forward
            )
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<repeat direction=\"forward\""))
    }

    // MARK: - Dynamics Export Tests

    func testExportDynamics() throws {
        let dynamicsDirection = Direction(
            placement: .below,
            staff: 1,
            types: [.dynamics(DynamicsDirection(values: [.f]))]
        )

        let measure = Measure(
            number: "1",
            elements: [.direction(dynamicsDirection)],
            attributes: MeasureAttributes(divisions: 1)
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<direction"))
        XCTAssertTrue(xml.contains("<dynamics>"))
        XCTAssertTrue(xml.contains("<f/>") || xml.contains("<f></f>"))
    }

    // MARK: - XML Structure Tests

    func testXMLDeclaration() throws {
        let score = Score(parts: [])
        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.hasPrefix("<?xml version=\"1.0\" encoding=\"UTF-8\"?>"))
    }

    func testDoctype() throws {
        let score = Score(parts: [])
        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<!DOCTYPE score-partwise"))
    }

    func testRootElement() throws {
        let score = Score(parts: [])
        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<score-partwise"))
        XCTAssertTrue(xml.contains("</score-partwise>"))
    }

    // MARK: - Metadata Export Tests

    func testExportWorkTitle() throws {
        let score = Score(
            metadata: ScoreMetadata(workTitle: "Symphony No. 5"),
            parts: []
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<work-title>Symphony No. 5</work-title>"))
    }

    func testExportComposer() throws {
        let score = Score(
            metadata: ScoreMetadata(workTitle: "Test", creators: [Creator(type: "composer", name: "Beethoven")]),
            parts: []
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<creator type=\"composer\">Beethoven</creator>"))
    }
}
