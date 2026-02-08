import XCTest
@testable import MusicXMLExport
@testable import MusicNotationCore

final class MusicXMLExportMetadataTests: XCTestCase {

    // MARK: - Work/Movement Tests

    func testExportWorkNumber() throws {
        let score = Score(
            metadata: ScoreMetadata(workTitle: "Symphony", workNumber: "Op. 67"),
            parts: []
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<work-number>Op. 67</work-number>"), "Should contain work-number")
    }

    func testExportMovementInfo() throws {
        let score = Score(
            metadata: ScoreMetadata(movementTitle: "Allegro con brio", movementNumber: "1"),
            parts: []
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<movement-title>Allegro con brio</movement-title>"), "Should contain movement-title")
        XCTAssertTrue(xml.contains("<movement-number>1</movement-number>"), "Should contain movement-number")
    }

    // MARK: - Creator Tests

    func testExportMultipleCreators() throws {
        let score = Score(
            metadata: ScoreMetadata(
                workTitle: "Test",
                creators: [
                    Creator(type: "composer", name: "Mozart"),
                    Creator(type: "lyricist", name: "Da Ponte"),
                ]
            ),
            parts: []
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<creator type=\"composer\">Mozart</creator>"), "Should have composer creator")
        XCTAssertTrue(xml.contains("<creator type=\"lyricist\">Da Ponte</creator>"), "Should have lyricist creator")
    }

    // MARK: - Rights Tests

    func testExportRights() throws {
        let score = Score(
            metadata: ScoreMetadata(workTitle: "Test", rights: ["Copyright 2024 Test Publisher"]),
            parts: []
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<rights>Copyright 2024 Test Publisher</rights>"), "Should contain rights element")
    }

    // MARK: - Source Tests

    func testExportSource() throws {
        let score = Score(
            metadata: ScoreMetadata(workTitle: "Test", source: "Manuscript"),
            parts: []
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<source>Manuscript</source>"), "Should contain source element")
    }

    // MARK: - Scaling Tests

    func testExportScaling() throws {
        let score = Score(
            parts: [],
            defaults: ScoreDefaults(
                scaling: Scaling(millimeters: 7.05, tenths: 40)
            )
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<scaling>"), "Should contain scaling element")
        XCTAssertTrue(xml.contains("<millimeters>7.05</millimeters>"), "Should contain millimeters")
        XCTAssertTrue(xml.contains("<tenths>40"), "Should contain tenths")
    }

    // MARK: - Page Layout Tests

    func testExportPageLayout() throws {
        let score = Score(
            parts: [],
            defaults: ScoreDefaults(
                pageSettings: PageSettings(pageHeight: 1683, pageWidth: 1190)
            )
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<page-layout>"), "Should contain page-layout element")
        XCTAssertTrue(xml.contains("<page-height>1683"), "Should contain page-height")
        XCTAssertTrue(xml.contains("<page-width>1190"), "Should contain page-width")
    }

    // MARK: - System Layout Tests

    func testExportSystemLayout() throws {
        let score = Score(
            parts: [],
            defaults: ScoreDefaults(
                systemLayout: SystemLayout(systemDistance: 120)
            )
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<system-layout>"), "Should contain system-layout element")
        XCTAssertTrue(xml.contains("<system-distance>120"), "Should contain system-distance")
    }

    // MARK: - Credit Tests

    func testExportCredits() throws {
        let score = Score(
            parts: [],
            credits: [
                Credit(page: 1, creditWords: [CreditWords(text: "Title")])
            ]
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<credit"), "Should contain credit element")
        XCTAssertTrue(xml.contains("page=\"1\""), "Should have page=1")
        XCTAssertTrue(xml.contains("<credit-words"), "Should contain credit-words")
        XCTAssertTrue(xml.contains(">Title</credit-words>"), "Should have Title text")
    }

    func testExportCreditPositioning() throws {
        let score = Score(
            parts: [],
            credits: [
                Credit(page: 1, creditWords: [
                    CreditWords(text: "Title", defaultX: 595, defaultY: 1600)
                ])
            ]
        )

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("default-x=\"595"), "Should have default-x=595")
        XCTAssertTrue(xml.contains("default-y=\"1600"), "Should have default-y=1600")
    }

    // MARK: - Unpitched Note Tests

    func testExportUnpitchedNote() throws {
        let note = Note(
            noteType: .unpitched(UnpitchedNote(displayStep: .c, displayOctave: 5)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1
        )

        let measure = Measure(
            number: "1",
            elements: [.note(note)],
            attributes: MeasureAttributes(divisions: 1)
        )
        let part = Part(id: "P1", name: "Percussion", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<unpitched>"), "Should contain unpitched element")
        XCTAssertTrue(xml.contains("<display-step>C</display-step>"), "Should have display-step C")
        XCTAssertTrue(xml.contains("<display-octave>5</display-octave>"), "Should have display-octave 5")
    }

    func testExportUnpitchedWithInstrument() throws {
        let note = Note(
            noteType: .unpitched(UnpitchedNote(
                displayStep: .c,
                displayOctave: 5,
                instrumentId: "P1-I36",
                percussionInstrument: nil,
                noteheadOverride: nil
            )),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1
        )

        let measure = Measure(
            number: "1",
            elements: [.note(note)],
            attributes: MeasureAttributes(divisions: 1)
        )
        let part = Part(id: "P1", name: "Drums", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<instrument id=\"P1-I36\""), "Should have instrument element with id")
    }

    // MARK: - Config Tests

    func testExportConfigNoDoctype() throws {
        let score = Score(parts: [])

        var config = ExportConfiguration()
        config.includeDoctype = false
        let exporter = MusicXMLExporter(config: config)
        let xml = try exporter.exportToString(score)

        XCTAssertFalse(xml.contains("<!DOCTYPE"), "Should not contain DOCTYPE")
    }

    func testExportConfigNoSignature() throws {
        let score = Score(parts: [])

        var config = ExportConfiguration()
        config.addEncodingSignature = false
        let exporter = MusicXMLExporter(config: config)
        let xml = try exporter.exportToString(score)

        XCTAssertFalse(xml.contains("SwiftMusicNotation"), "Should not contain SwiftMusicNotation signature")
    }

    // MARK: - Barline Endings Tests

    func testExportBarlineEndings() throws {
        let measure = Measure(
            number: "1",
            rightBarline: Barline(
                location: .right,
                barStyle: .lightHeavy,
                ending: Ending(number: "1", type: .start)
            )
        )
        let part = Part(id: "P1", name: "Test", measures: [measure])
        let score = Score(parts: [part])

        let exporter = MusicXMLExporter()
        let xml = try exporter.exportToString(score)

        XCTAssertTrue(xml.contains("<ending"), "Should contain ending element")
        XCTAssertTrue(xml.contains("number=\"1\""), "Should have number=1")
        XCTAssertTrue(xml.contains("type=\"start\""), "Should have type=start")
    }
}
