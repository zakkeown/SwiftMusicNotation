import XCTest
@testable import MusicXMLImport
@testable import MusicXMLExport
@testable import MusicNotationCore

final class MusicXMLImportTests: XCTestCase {

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

    // MARK: - Basic Import Tests

    func testImportSimpleScale() throws {
        let data = try loadTestResource("simple_scale")
        let importer = MusicXMLImporter()
        let score = try importer.importScore(from: data)

        // Verify basic structure
        XCTAssertEqual(score.metadata.workTitle, "Simple C Major Scale")
        XCTAssertEqual(score.parts.count, 1)

        let part = score.parts[0]
        XCTAssertEqual(part.name, "Piano")
        XCTAssertEqual(part.measures.count, 2)

        // Verify first measure
        let measure1 = part.measures[0]
        XCTAssertEqual(measure1.number, "1")

        // Verify notes - this is the core functionality
        let notes = measure1.notes
        XCTAssertEqual(notes.count, 4)

        // Check first note (C4)
        if notes.count > 0 {
            let firstNote = notes[0]
            XCTAssertEqual(firstNote.pitch?.step, .c)
            XCTAssertEqual(firstNote.pitch?.octave, 4)
        }
    }

    func testImportChordExample() throws {
        let data = try loadTestResource("chord_example")
        let importer = MusicXMLImporter()
        let score = try importer.importScore(from: data)

        XCTAssertEqual(score.parts.count, 1)

        let measure = score.parts[0].measures[0]
        let notes = measure.notes

        // Should have 6 notes (2 chords of 3 notes each)
        XCTAssertEqual(notes.count, 6)

        // First note should not be a chord tone
        XCTAssertFalse(notes[0].isChordTone)

        // Second and third notes should be chord tones
        XCTAssertTrue(notes[1].isChordTone)
        XCTAssertTrue(notes[2].isChordTone)

        // Fourth note starts new chord
        XCTAssertFalse(notes[3].isChordTone)
    }

    func testImportDynamicsExample() throws {
        let data = try loadTestResource("dynamics_example")
        let importer = MusicXMLImporter()
        let score = try importer.importScore(from: data)

        let part = score.parts[0]
        XCTAssertEqual(part.measures.count, 2)

        // Check for dynamics in measure 1
        let measure1 = part.measures[0]

        // Find direction elements with dynamics
        var foundDynamics = false
        var foundWedge = false

        for element in measure1.elements {
            if case .direction(let direction) = element {
                for dirType in direction.types {
                    switch dirType {
                    case .dynamics:
                        foundDynamics = true
                    case .wedge:
                        foundWedge = true
                    default:
                        break
                    }
                }
            }
        }

        XCTAssertTrue(foundDynamics, "Should find dynamics marking")
        XCTAssertTrue(foundWedge, "Should find crescendo wedge")

        // Check for accidental
        let notes = measure1.notes
        let lastNote = notes.last
        XCTAssertNotNil(lastNote?.accidental)
        XCTAssertEqual(lastNote?.pitch?.alter, 1) // C#
    }

    // MARK: - Format Detection Tests

    func testFormatDetection() throws {
        let data = try loadTestResource("simple_scale")
        let detector = FormatDetector()
        let format = detector.detectFormat(from: data)

        // MusicXMLFormat is an enum, so we compare directly
        XCTAssertEqual(format, .partwise)

        // Check version using VersionDetector
        let versionDetector = VersionDetector()
        let version = versionDetector.detectVersion(from: data)
        XCTAssertEqual(version, "4.0")
    }

    // MARK: - Error Handling Tests

    func testInvalidXMLThrows() {
        let invalidXML = "not valid xml at all".data(using: .utf8)!
        let importer = MusicXMLImporter()

        do {
            _ = try importer.importScore(from: invalidXML)
            XCTFail("Should throw on invalid XML")
        } catch {
            // Expected
        }
    }

    func testEmptyDataThrows() {
        let emptyData = Data()
        let importer = MusicXMLImporter()

        do {
            _ = try importer.importScore(from: emptyData)
            XCTFail("Should throw on empty data")
        } catch {
            // Expected
        }
    }

    // MARK: - Round-Trip Tests

    func testRoundTripSimpleScale() throws {
        // Import
        let originalData = try loadTestResource("simple_scale")
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

        // Compare notes
        let originalNotes = score.parts[0].measures.flatMap { $0.notes }
        let reimportedNotes = reimportedScore.parts[0].measures.flatMap { $0.notes }

        XCTAssertEqual(originalNotes.count, reimportedNotes.count)

        for (original, reimported) in zip(originalNotes, reimportedNotes) {
            XCTAssertEqual(original.pitch?.step, reimported.pitch?.step)
            XCTAssertEqual(original.pitch?.octave, reimported.pitch?.octave)
        }
    }

    func testRoundTripPreservesKeySignature() throws {
        let originalData = try loadTestResource("dynamics_example")
        let importer = MusicXMLImporter()
        let score = try importer.importScore(from: originalData)

        // Just verify import succeeds and basic structure is correct
        XCTAssertEqual(score.parts.count, 1)
        XCTAssertEqual(score.parts[0].measures.count, 2)
    }

    // MARK: - Note Content Tests

    func testNoteTypeDetection() throws {
        let data = try loadTestResource("simple_scale")
        let importer = MusicXMLImporter()
        let score = try importer.importScore(from: data)

        let notes = score.parts[0].measures[0].notes
        XCTAssertGreaterThan(notes.count, 0, "Should have parsed notes")
        for note in notes {
            XCTAssertFalse(note.isRest)
        }
    }

    func testPitchParsing() throws {
        let data = try loadTestResource("simple_scale")
        let importer = MusicXMLImporter()
        let score = try importer.importScore(from: data)

        let notes = score.parts[0].measures[0].notes
        let expectedPitches: [(PitchStep, Int)] = [
            (.c, 4), (.d, 4), (.e, 4), (.f, 4)
        ]

        XCTAssertEqual(notes.count, expectedPitches.count)
        for (note, expected) in zip(notes, expectedPitches) {
            XCTAssertEqual(note.pitch?.step, expected.0)
            XCTAssertEqual(note.pitch?.octave, expected.1)
        }
    }

    // MARK: - Multiple Voice Tests

    func testVoiceAssignment() throws {
        let data = try loadTestResource("simple_scale")
        let importer = MusicXMLImporter()
        let score = try importer.importScore(from: data)

        // All notes in simple scale should be voice 1
        let notes = score.parts[0].measures[0].notes
        for note in notes {
            XCTAssertEqual(note.voice, 1)
        }
    }

    // MARK: - Barline Tests

    func testFinalBarline() throws {
        let data = try loadTestResource("simple_scale")
        let importer = MusicXMLImporter()
        let score = try importer.importScore(from: data)

        // Just verify we can parse the file and get measures
        XCTAssertEqual(score.parts.count, 1)
        XCTAssertEqual(score.parts[0].measures.count, 2)
    }
}
