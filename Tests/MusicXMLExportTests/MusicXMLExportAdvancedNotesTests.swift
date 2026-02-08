import XCTest
@testable import MusicXMLExport
@testable import MusicNotationCore

final class MusicXMLExportAdvancedNotesTests: XCTestCase {

    // MARK: - Grace Note Tests

    func testExportGraceNoteSlashed() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .d, octave: 5)),
            durationDivisions: 0,
            type: .eighth,
            voice: 1,
            staff: 1,
            grace: GraceNote(slash: true)
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

        XCTAssertTrue(xml.contains("<grace"), "Should contain grace element")
        XCTAssertTrue(xml.contains("slash=\"yes\""), "Should have slash=yes")
        // Grace notes should not have <duration>
        // The <duration> for the grace note (durationDivisions=0) should export as <duration>0</duration>
        // but actually the exporter skips duration for grace notes
        XCTAssertFalse(xml.contains("<duration>0</duration>") && xml.contains("<grace"),
            "Grace note behavior check")
    }

    func testExportGraceNoteUnslashed() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 5)),
            durationDivisions: 0,
            type: .sixteenth,
            voice: 1,
            staff: 1,
            grace: GraceNote(slash: false)
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

        XCTAssertTrue(xml.contains("<grace"), "Should contain grace element")
        XCTAssertFalse(xml.contains("slash=\"yes\""), "Should not have slash=yes for unslashed grace")
    }

    func testExportGraceNoteNoDuration() throws {
        let graceNote = Note(
            noteType: .pitched(Pitch(step: .e, octave: 4)),
            durationDivisions: 0,
            type: .eighth,
            voice: 1,
            staff: 1,
            grace: GraceNote(slash: true)
        )

        let regularNote = Note(
            noteType: .pitched(Pitch(step: .f, octave: 4)),
            durationDivisions: 4,
            type: .quarter,
            voice: 1,
            staff: 1
        )

        let measure = Measure(
            number: "1",
            elements: [.note(graceNote), .note(regularNote)],
            attributes: MeasureAttributes(divisions: 4)
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        // Count <duration> elements - should only be from the regular note
        let durationCount = xml.components(separatedBy: "<duration>").count - 1
        XCTAssertEqual(durationCount, 1, "Should only have 1 duration element (from the regular note, not the grace note)")
    }

    // MARK: - Cue Note Tests

    func testExportCueNote() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 5)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            cue: true
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

        XCTAssertTrue(xml.contains("<cue"), "Should contain cue element")
    }

    // MARK: - Beam Tests

    func testExportBeamBeginEnd() throws {
        let note1 = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 1,
            type: .eighth,
            voice: 1,
            staff: 1,
            beams: [BeamValue(number: 1, value: .begin)]
        )

        let note2 = Note(
            noteType: .pitched(Pitch(step: .d, octave: 4)),
            durationDivisions: 1,
            type: .eighth,
            voice: 1,
            staff: 1,
            beams: [BeamValue(number: 1, value: .end)]
        )

        let measure = Measure(
            number: "1",
            elements: [.note(note1), .note(note2)],
            attributes: MeasureAttributes(divisions: 2)
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<beam number=\"1\">begin</beam>"), "Should have beam begin")
        XCTAssertTrue(xml.contains("<beam number=\"1\">end</beam>"), "Should have beam end")
    }

    func testExportBeamMultipleLevels() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 1,
            type: .sixteenth,
            voice: 1,
            staff: 1,
            beams: [
                BeamValue(number: 1, value: .begin),
                BeamValue(number: 2, value: .begin),
            ]
        )

        let measure = Measure(
            number: "1",
            elements: [.note(note)],
            attributes: MeasureAttributes(divisions: 4)
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<beam number=\"1\">begin</beam>"), "Should have beam level 1")
        XCTAssertTrue(xml.contains("<beam number=\"2\">begin</beam>"), "Should have beam level 2")
    }

    func testExportBeamHooks() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 1,
            type: .sixteenth,
            voice: 1,
            staff: 1,
            beams: [
                BeamValue(number: 1, value: .continue),
                BeamValue(number: 2, value: .forwardHook),
            ]
        )

        let measure = Measure(
            number: "1",
            elements: [.note(note)],
            attributes: MeasureAttributes(divisions: 4)
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<beam number=\"2\">forward hook</beam>"), "Should have forward hook")
    }

    // MARK: - Stem Direction Tests

    func testExportStemDirection() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            stemDirection: .up
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

        XCTAssertTrue(xml.contains("<stem>up</stem>"), "Should contain stem up")
    }

    func testExportStemDown() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .a, octave: 5)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            stemDirection: .down
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

        XCTAssertTrue(xml.contains("<stem>down</stem>"), "Should contain stem down")
    }

    // MARK: - Notehead Tests

    func testExportNoteheadDiamond() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            notehead: NoteheadInfo(type: .diamond)
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

        XCTAssertTrue(xml.contains("<notehead"), "Should contain notehead element")
        XCTAssertTrue(xml.contains("diamond</notehead>"), "Should have diamond type")
    }

    func testExportNoteheadFilled() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            notehead: NoteheadInfo(type: .diamond, filled: true)
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

        XCTAssertTrue(xml.contains("filled=\"yes\""), "Should have filled=yes")
    }

    func testExportNoteheadParentheses() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            notehead: NoteheadInfo(type: .diamond, parentheses: true)
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

        XCTAssertTrue(xml.contains("parentheses=\"yes\""), "Should have parentheses=yes")
    }

    // MARK: - Measure Rest Tests

    func testExportMeasureRest() throws {
        let rest = Note(
            noteType: .rest(RestInfo(measureRest: true)),
            durationDivisions: 4,
            type: .whole,
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

        XCTAssertTrue(xml.contains("measure=\"yes\""), "Should have measure=yes on rest")
    }

    // MARK: - Multiple Dots Tests

    func testExportMultipleDots() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 7,
            type: .half,
            dots: 2,
            voice: 1,
            staff: 1
        )

        let measure = Measure(
            number: "1",
            elements: [.note(note)],
            attributes: MeasureAttributes(divisions: 2)
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        let dotCount = xml.components(separatedBy: "<dot").count - 1
        XCTAssertEqual(dotCount, 2, "Should have exactly 2 dot elements")
    }

    // MARK: - Tie Sound Element Tests

    func testExportTieSoundElement() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            ties: [Tie(type: .start)]
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

        XCTAssertTrue(xml.contains("<tie type=\"start\""), "Should contain tie element with start type")
        // The tied notation should also appear since ties array is non-empty
        XCTAssertTrue(xml.contains("<tied"), "Should also export tied notation when ties exist")
    }

    // MARK: - Accidental Parentheses Tests

    func testExportAccidentalParentheses() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .f, alter: 0, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            accidental: AccidentalMark(accidental: .natural, parentheses: true)
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

        XCTAssertTrue(xml.contains("parentheses=\"yes\""), "Should have parentheses=yes on accidental")
        XCTAssertTrue(xml.contains("natural</accidental>"), "Should have natural accidental")
    }
}
