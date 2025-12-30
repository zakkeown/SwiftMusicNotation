import XCTest
@testable import MusicXMLImport
@testable import MusicXMLExport
@testable import MusicNotationCore

final class PercussionImportTests: XCTestCase {

    // MARK: - Helper Methods

    private func loadTestResource(_ name: String, extension ext: String = "musicxml") throws -> Data {
        let bundle = Bundle.module
        guard let url = bundle.url(forResource: name, withExtension: ext, subdirectory: "Resources") else {
            throw TestError.resourceNotFound(name)
        }
        return try Data(contentsOf: url)
    }

    private enum TestError: Error {
        case resourceNotFound(String)
    }

    // MARK: - Drum Kit Import Tests

    func testImportDrumKit() throws {
        let data = try loadTestResource("drum_kit")
        let importer = MusicXMLImporter()
        let score = try importer.importScore(from: data)

        // Verify basic structure
        XCTAssertEqual(score.metadata.workTitle, "Drum Kit Test")
        XCTAssertEqual(score.parts.count, 1)

        let part = score.parts[0]
        XCTAssertEqual(part.name, "Drums")
        XCTAssertEqual(part.abbreviation, "Dr.")
        XCTAssertEqual(part.measures.count, 2)
    }

    func testDrumKitInstrumentsParsed() throws {
        let data = try loadTestResource("drum_kit")
        let importer = MusicXMLImporter()
        let score = try importer.importScore(from: data)

        let part = score.parts[0]

        // Should have 5 instruments
        XCTAssertEqual(part.instruments.count, 5)

        // Verify instrument names
        let instrumentNames = part.instruments.map { $0.name }
        XCTAssertTrue(instrumentNames.contains("Bass Drum"))
        XCTAssertTrue(instrumentNames.contains("Snare Drum"))
        XCTAssertTrue(instrumentNames.contains("Closed Hi-Hat"))
        XCTAssertTrue(instrumentNames.contains("Open Hi-Hat"))
        XCTAssertTrue(instrumentNames.contains("Crash Cymbal"))
    }

    func testDrumKitMidiInstrumentsParsed() throws {
        let data = try loadTestResource("drum_kit")
        let importer = MusicXMLImporter()
        let score = try importer.importScore(from: data)

        let part = score.parts[0]

        // Should have 5 MIDI instruments
        XCTAssertEqual(part.midiInstruments.count, 5)

        // All should be on MIDI channel 10
        for midiInstrument in part.midiInstruments {
            XCTAssertEqual(midiInstrument.midiChannel, 10)
        }
    }

    func testPercussionClefParsed() throws {
        let data = try loadTestResource("drum_kit")
        let importer = MusicXMLImporter()
        let score = try importer.importScore(from: data)

        let part = score.parts[0]
        let measure1 = part.measures[0]

        // Find the clef in attributes
        var foundPercussionClef = false
        for element in measure1.elements {
            if case .attributes(let attrs) = element {
                for clef in attrs.clefs {
                    if clef.sign == .percussion {
                        foundPercussionClef = true
                    }
                }
            }
        }

        XCTAssertTrue(foundPercussionClef, "Should find percussion clef")
    }

    func testUnpitchedNotesParsed() throws {
        let data = try loadTestResource("drum_kit")
        let importer = MusicXMLImporter()
        let score = try importer.importScore(from: data)

        let part = score.parts[0]
        let measure1 = part.measures[0]
        let notes = measure1.notes

        // Should have 8 notes (4 beats x 2 notes per beat)
        XCTAssertEqual(notes.count, 8)

        // First note should be crash cymbal (A5)
        let firstNote = notes[0]
        XCTAssertNotNil(firstNote.unpitched, "First note should be unpitched")
        XCTAssertEqual(firstNote.unpitched?.displayStep, .a)
        XCTAssertEqual(firstNote.unpitched?.displayOctave, 5)
        XCTAssertEqual(firstNote.unpitched?.instrumentId, "P1-I49")

        // Second note should be bass drum (F4)
        let secondNote = notes[1]
        XCTAssertNotNil(secondNote.unpitched, "Second note should be unpitched")
        XCTAssertTrue(secondNote.isChordTone, "Should be a chord tone")
        XCTAssertEqual(secondNote.unpitched?.displayStep, .f)
        XCTAssertEqual(secondNote.unpitched?.displayOctave, 4)
        XCTAssertEqual(secondNote.unpitched?.instrumentId, "P1-I36")
    }

    func testPercussionDirectionBeaterParsed() throws {
        let data = try loadTestResource("drum_kit")
        let importer = MusicXMLImporter()
        let score = try importer.importScore(from: data)

        let part = score.parts[0]
        let measure1 = part.measures[0]

        // Find beater direction
        var foundBeater = false
        for element in measure1.elements {
            if case .direction(let direction) = element {
                for dirType in direction.types {
                    if case .percussion(let perc) = dirType {
                        if case .beater(let beaterType) = perc.type {
                            XCTAssertEqual(beaterType, .drumStick)
                            foundBeater = true
                        }
                    }
                }
            }
        }

        XCTAssertTrue(foundBeater, "Should find beater direction")
    }

    func testPercussionDirectionMembraneParsed() throws {
        let data = try loadTestResource("drum_kit")
        let importer = MusicXMLImporter()
        let score = try importer.importScore(from: data)

        let part = score.parts[0]
        let measure2 = part.measures[1]

        // Find membrane direction
        var foundMembrane = false
        for element in measure2.elements {
            if case .direction(let direction) = element {
                for dirType in direction.types {
                    if case .percussion(let perc) = dirType {
                        if case .membrane(let membraneType) = perc.type {
                            XCTAssertEqual(membraneType, .snareDrum)
                            foundMembrane = true
                        }
                    }
                }
            }
        }

        XCTAssertTrue(foundMembrane, "Should find membrane direction")
    }

    func testPercussionDirectionStickParsed() throws {
        let data = try loadTestResource("drum_kit")
        let importer = MusicXMLImporter()
        let score = try importer.importScore(from: data)

        let part = score.parts[0]
        let measure2 = part.measures[1]

        // Find stick direction
        var foundStick = false
        for element in measure2.elements {
            if case .direction(let direction) = element {
                for dirType in direction.types {
                    if case .percussion(let perc) = dirType {
                        if case .stick(let stickSpec) = perc.type {
                            XCTAssertEqual(stickSpec.type, .bassDrum)
                            XCTAssertEqual(stickSpec.material, .hard)
                            foundStick = true
                        }
                    }
                }
            }
        }

        XCTAssertTrue(foundStick, "Should find stick direction")
    }

    func testPartIsPercussion() throws {
        let data = try loadTestResource("drum_kit")
        let importer = MusicXMLImporter()
        let score = try importer.importScore(from: data)

        let part = score.parts[0]

        // Part should be recognized as percussion
        XCTAssertTrue(part.isPercussion, "Drum part should be recognized as percussion")
    }

    func testEffectivePercussionMap() throws {
        let data = try loadTestResource("drum_kit")
        let importer = MusicXMLImporter()
        let score = try importer.importScore(from: data)

        let part = score.parts[0]

        // Without explicit map, should use standard drum kit
        XCTAssertNotNil(part.effectivePercussionMap, "Should have effective percussion map")

        // Check that the standard map works for display positions
        let map = part.effectivePercussionMap!

        // Snare at C5
        let snareInstrument = map.instrument(at: .c, octave: 5)
        XCTAssertNotNil(snareInstrument, "Should find snare at C5")
        XCTAssertEqual(snareInstrument, .snareDrum)

        // Bass drum at F4
        let kickInstrument = map.instrument(at: .f, octave: 4)
        XCTAssertNotNil(kickInstrument, "Should find bass drum at F4")
        XCTAssertEqual(kickInstrument, .bassDrum)

        // Hi-hat at G5
        let hihatInstrument = map.instrument(at: .g, octave: 5)
        XCTAssertNotNil(hihatInstrument, "Should find hi-hat at G5")
        XCTAssertEqual(hihatInstrument, .hiHatClosed)
    }

    // MARK: - Round-Trip Tests

    func testRoundTripDrumKit() throws {
        // Import
        let originalData = try loadTestResource("drum_kit")
        let importer = MusicXMLImporter()
        let score = try importer.importScore(from: originalData)

        // Export
        let exporter = MusicXMLExporter()
        let exportedData = try exporter.export(score)

        // Re-import
        let reimportedScore = try importer.importScore(from: exportedData)

        // Compare
        XCTAssertEqual(score.parts.count, reimportedScore.parts.count)
        XCTAssertEqual(score.parts[0].measures.count, reimportedScore.parts[0].measures.count)

        // Compare unpitched notes
        let originalNotes = score.parts[0].measures[0].notes
        let reimportedNotes = reimportedScore.parts[0].measures[0].notes

        XCTAssertEqual(originalNotes.count, reimportedNotes.count)

        for (original, reimported) in zip(originalNotes, reimportedNotes) {
            XCTAssertEqual(original.unpitched?.displayStep, reimported.unpitched?.displayStep)
            XCTAssertEqual(original.unpitched?.displayOctave, reimported.unpitched?.displayOctave)
            // Note: instrumentId may not survive round-trip unless explicitly exported
        }
    }
}
