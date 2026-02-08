import XCTest
@testable import MusicXMLExport
@testable import MusicNotationCore

final class MusicXMLExportNotationsTests: XCTestCase {

    // MARK: - Slur Tests

    func testExportSlurStart() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            notations: [.slur(SlurNotation(type: .start, number: 1))]
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

        XCTAssertTrue(xml.contains("<slur"), "Should contain slur element")
        XCTAssertTrue(xml.contains("type=\"start\""), "Should have start type")
        XCTAssertTrue(xml.contains("number=\"1\""), "Should have number 1")
    }

    func testExportSlurStop() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .d, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            notations: [.slur(SlurNotation(type: .stop, number: 1))]
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

        XCTAssertTrue(xml.contains("<slur"), "Should contain slur element")
        XCTAssertTrue(xml.contains("type=\"stop\""), "Should have stop type")
    }

    func testExportSlurWithPlacement() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .e, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            notations: [.slur(SlurNotation(type: .start, number: 1, placement: .above))]
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

        XCTAssertTrue(xml.contains("placement=\"above\""), "Should have above placement")
    }

    // MARK: - Tied Notation Tests

    func testExportTiedNotation() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            ties: [Tie(type: .start)],
            notations: [.tied(TiedNotation(type: .start))]
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

        // Both <tie> (sound) and <tied> (notation) should be present
        XCTAssertTrue(xml.contains("<tie type=\"start\""), "Should contain tie element")
        XCTAssertTrue(xml.contains("<tied"), "Should contain tied notation")
    }

    // MARK: - Tuplet Tests

    func testExportTupletNotation() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 1,
            type: .eighth,
            voice: 1,
            staff: 1,
            notations: [.tuplet(TupletNotation(type: .start, number: 1))],
            timeModification: TupletRatio(actual: 3, normal: 2)
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

        XCTAssertTrue(xml.contains("<tuplet"), "Should contain tuplet element")
        XCTAssertTrue(xml.contains("type=\"start\""), "Should have start type")
        XCTAssertTrue(xml.contains("<actual-notes>3</actual-notes>"), "Should have actual-notes 3")
        XCTAssertTrue(xml.contains("<normal-notes>2</normal-notes>"), "Should have normal-notes 2")
    }

    func testExportTupletBracket() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 1,
            type: .eighth,
            voice: 1,
            staff: 1,
            notations: [.tuplet(TupletNotation(type: .start, number: 1, bracket: true, showNumber: .both))],
            timeModification: TupletRatio(actual: 3, normal: 2)
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

        XCTAssertTrue(xml.contains("bracket=\"yes\""), "Should have bracket=yes")
        XCTAssertTrue(xml.contains("show-number=\"both\""), "Should have show-number=both")
    }

    // MARK: - Articulation Tests

    func testExportArticulations() throws {
        let testCases: [(Articulation, String)] = [
            (.staccato, "staccato"),
            (.accent, "accent"),
            (.tenuto, "tenuto"),
            (.strongAccent, "strong-accent"),
        ]

        for (articulation, expectedName) in testCases {
            let note = Note(
                noteType: .pitched(Pitch(step: .c, octave: 4)),
                durationDivisions: 1,
                type: .quarter,
                voice: 1,
                staff: 1,
                notations: [.articulations([ArticulationMark(articulation: articulation)])]
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

            XCTAssertTrue(xml.contains("<articulations>"), "Should contain articulations wrapper for \(expectedName)")
            XCTAssertTrue(xml.contains("<\(expectedName)"), "Should contain \(expectedName) element")
        }
    }

    func testExportArticulationPlacement() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            notations: [.articulations([ArticulationMark(articulation: .staccato, placement: .below)])]
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

        XCTAssertTrue(xml.contains("placement=\"below\""), "Should have below placement on articulation")
    }

    func testExportMultipleArticulations() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            notations: [.articulations([
                ArticulationMark(articulation: .staccato),
                ArticulationMark(articulation: .accent),
            ])]
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

        XCTAssertTrue(xml.contains("<staccato"), "Should contain staccato")
        XCTAssertTrue(xml.contains("<accent"), "Should contain accent")
    }

    // MARK: - Ornament Tests

    func testExportOrnamentTrill() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            notations: [.ornaments([Ornament(type: .trill)])]
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

        XCTAssertTrue(xml.contains("<ornaments>"), "Should contain ornaments wrapper")
        XCTAssertTrue(xml.contains("<trill-mark"), "Should contain trill-mark element")
    }

    func testExportOrnamentMordent() throws {
        let testCases: [(OrnamentType, String)] = [
            (.mordent, "mordent"),
            (.invertedMordent, "inverted-mordent"),
        ]

        for (ornamentType, expectedName) in testCases {
            let note = Note(
                noteType: .pitched(Pitch(step: .d, octave: 4)),
                durationDivisions: 1,
                type: .quarter,
                voice: 1,
                staff: 1,
                notations: [.ornaments([Ornament(type: ornamentType)])]
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

            XCTAssertTrue(xml.contains("<\(expectedName)"), "Should contain \(expectedName) element")
        }
    }

    // MARK: - Technical Tests

    func testExportTechnicalFingering() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            notations: [.technical([TechnicalMark(type: .fingering, text: "3")])]
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

        XCTAssertTrue(xml.contains("<technical>"), "Should contain technical wrapper")
        XCTAssertTrue(xml.contains("<fingering"), "Should contain fingering element")
    }

    func testExportTechnicalHarmonic() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .e, octave: 5)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            notations: [.technical([TechnicalMark(type: .harmonic)])]
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

        XCTAssertTrue(xml.contains("<harmonic"), "Should contain harmonic element")
    }

    // MARK: - Fermata Tests

    func testExportFermata() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            notations: [.fermata(Fermata(shape: .normal, type: .upright))]
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

        XCTAssertTrue(xml.contains("<fermata"), "Should contain fermata element")
        XCTAssertTrue(xml.contains("type=\"upright\""), "Should have upright type")
        XCTAssertTrue(xml.contains("normal</fermata>"), "Should have normal shape")
    }

    func testExportFermataInverted() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            notations: [.fermata(Fermata(shape: .normal, type: .inverted))]
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

        XCTAssertTrue(xml.contains("type=\"inverted\""), "Should have inverted type")
    }

    // MARK: - Arpeggiate Tests

    func testExportArpeggiate() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            notations: [.arpeggiate(Arpeggiate(direction: .up))]
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

        XCTAssertTrue(xml.contains("<arpeggiate"), "Should contain arpeggiate element")
        XCTAssertTrue(xml.contains("direction=\"up\""), "Should have up direction")
    }

    // MARK: - Glissando Tests

    func testExportGlissando() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            notations: [.glissando(Glissando(type: .start, text: "gliss."))]
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

        XCTAssertTrue(xml.contains("<glissando"), "Should contain glissando element")
        XCTAssertTrue(xml.contains("type=\"start\""), "Should have start type")
        XCTAssertTrue(xml.contains("gliss."), "Should contain gliss. text")
    }

    // MARK: - Slide Tests

    func testExportSlide() throws {
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1,
            notations: [.slide(Slide(type: .start))]
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

        XCTAssertTrue(xml.contains("<slide"), "Should contain slide element")
        XCTAssertTrue(xml.contains("type=\"start\""), "Should have start type")
    }
}
