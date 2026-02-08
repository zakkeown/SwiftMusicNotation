import XCTest
@testable import MusicXMLExport
@testable import MusicNotationCore

final class MusicXMLExportLyricsHarmonyTests: XCTestCase {

    // MARK: - Lyric Tests

    func testExportSingleLyric() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            lyrics: [Lyric(text: "la", syllabic: .single)]
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

        XCTAssertTrue(xml.contains("<lyric"), "Should contain lyric element")
        XCTAssertTrue(xml.contains("<syllabic>single</syllabic>"), "Should have syllabic=single")
        XCTAssertTrue(xml.contains("<text>la</text>"), "Should have text=la")
    }

    func testExportLyricBegin() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            lyrics: [Lyric(text: "hel", syllabic: .begin)]
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

        XCTAssertTrue(xml.contains("<syllabic>begin</syllabic>"), "Should have syllabic=begin")
    }

    func testExportLyricMiddle() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .d, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            lyrics: [Lyric(text: "lo", syllabic: .middle)]
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

        XCTAssertTrue(xml.contains("<syllabic>middle</syllabic>"), "Should have syllabic=middle")
    }

    func testExportLyricEnd() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .e, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            lyrics: [Lyric(text: "world", syllabic: .end)]
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

        XCTAssertTrue(xml.contains("<syllabic>end</syllabic>"), "Should have syllabic=end")
    }

    func testExportLyricExtend() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            lyrics: [Lyric(text: "ah", syllabic: .single, extend: true)]
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

        XCTAssertTrue(xml.contains("<extend"), "Should contain extend element")
    }

    func testExportMultipleVerses() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            lyrics: [
                Lyric(number: "1", text: "Joy", syllabic: .single),
                Lyric(number: "2", text: "Peace", syllabic: .single),
            ]
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

        XCTAssertTrue(xml.contains("number=\"1\""), "Should have lyric number 1")
        XCTAssertTrue(xml.contains("number=\"2\""), "Should have lyric number 2")
        XCTAssertTrue(xml.contains("<text>Joy</text>"), "Should contain Joy text")
        XCTAssertTrue(xml.contains("<text>Peace</text>"), "Should contain Peace text")
    }

    // MARK: - Harmony Tests

    func testExportHarmonyBasic() throws {
        let harmony = Harmony(root: HarmonyRoot(step: .c), kind: .major)

        let measure = Measure(
            number: "1",
            elements: [.harmony(harmony)],
            attributes: MeasureAttributes(divisions: 1)
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<harmony>"), "Should contain harmony element")
        XCTAssertTrue(xml.contains("<root>"), "Should contain root element")
        XCTAssertTrue(xml.contains("<root-step>C</root-step>"), "Should have root-step C")
        XCTAssertTrue(xml.contains("<kind>major</kind>"), "Should have kind=major")
    }

    func testExportHarmonyMinor() throws {
        let harmony = Harmony(root: HarmonyRoot(step: .a), kind: .minor)

        let measure = Measure(
            number: "1",
            elements: [.harmony(harmony)],
            attributes: MeasureAttributes(divisions: 1)
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<root-step>A</root-step>"), "Should have root-step A")
        XCTAssertTrue(xml.contains("<kind>minor</kind>"), "Should have kind=minor")
    }

    func testExportHarmonyWithBass() throws {
        let harmony = Harmony(
            root: HarmonyRoot(step: .c),
            kind: .major,
            bass: HarmonyRoot(step: .g)
        )

        let measure = Measure(
            number: "1",
            elements: [.harmony(harmony)],
            attributes: MeasureAttributes(divisions: 1)
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<bass>"), "Should contain bass element")
        XCTAssertTrue(xml.contains("<bass-step>G</bass-step>"), "Should have bass-step G")
    }

    func testExportHarmonyWithAlter() throws {
        let harmony = Harmony(
            root: HarmonyRoot(step: .b, alter: -1),
            kind: .major
        )

        let measure = Measure(
            number: "1",
            elements: [.harmony(harmony)],
            attributes: MeasureAttributes(divisions: 1)
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<root-step>B</root-step>"), "Should have root-step B")
        XCTAssertTrue(xml.contains("<root-alter>-1"), "Should have root-alter -1")
    }

    func testExportHarmonyDegree() throws {
        let harmony = Harmony(
            root: HarmonyRoot(step: .c),
            kind: .major,
            degrees: [ChordDegree(value: 9, alter: 1, type: .add)]
        )

        let measure = Measure(
            number: "1",
            elements: [.harmony(harmony)],
            attributes: MeasureAttributes(divisions: 1)
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<degree>"), "Should contain degree element")
        XCTAssertTrue(xml.contains("<degree-value>9</degree-value>"), "Should have degree-value 9")
        XCTAssertTrue(xml.contains("<degree-alter>1"), "Should have degree-alter 1")
        XCTAssertTrue(xml.contains("<degree-type>add</degree-type>"), "Should have degree-type add")
    }

    func testExportHarmonyDominantSeventh() throws {
        let harmony = Harmony(root: HarmonyRoot(step: .g), kind: .dominant)

        let measure = Measure(
            number: "1",
            elements: [.harmony(harmony)],
            attributes: MeasureAttributes(divisions: 1)
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<kind>dominant</kind>"), "Should have kind=dominant")
    }
}
