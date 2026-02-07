import XCTest
import MusicNotationCore
@testable import MIDIImport

/// End-to-end integration tests: .mid binary data → Score with correct parts/measures/notes.
final class MIDIImportTests: XCTestCase {

    // MARK: - Helpers

    private func uint16Bytes(_ value: UInt16) -> [UInt8] {
        [UInt8(value >> 8), UInt8(value & 0xFF)]
    }

    private func uint32Bytes(_ value: UInt32) -> [UInt8] {
        [UInt8((value >> 24) & 0xFF), UInt8((value >> 16) & 0xFF),
         UInt8((value >> 8) & 0xFF), UInt8(value & 0xFF)]
    }

    /// Builds a complete MIDI file from raw track byte arrays.
    private func buildMIDIFile(
        format: UInt16 = 0,
        tpq: UInt16 = 480,
        tracks: [[UInt8]]
    ) -> Data {
        var data = Data()

        // Header
        data.append(contentsOf: [0x4D, 0x54, 0x68, 0x64]) // MThd
        data.append(contentsOf: uint32Bytes(6))
        data.append(contentsOf: uint16Bytes(format))
        data.append(contentsOf: uint16Bytes(UInt16(tracks.count)))
        data.append(contentsOf: uint16Bytes(tpq))

        for track in tracks {
            var trackData = track
            trackData.append(contentsOf: [0x00, 0xFF, 0x2F, 0x00]) // End of track
            data.append(contentsOf: [0x4D, 0x54, 0x72, 0x6B]) // MTrk
            data.append(contentsOf: uint32Bytes(UInt32(trackData.count)))
            data.append(contentsOf: trackData)
        }

        return data
    }

    // MARK: - Basic Import

    func testImportSimplePitchedScore() throws {
        // Format 0, one track with a C4 quarter note
        let trackEvents: [UInt8] = [
            // Tempo: 120 BPM
            0x00, 0xFF, 0x51, 0x03, 0x07, 0xA1, 0x20,
            // Time sig: 4/4
            0x00, 0xFF, 0x58, 0x04, 0x04, 0x02, 0x18, 0x08,
            // Note on C4
            0x00, 0x90, 60, 100,
            // Note off C4 after quarter note
            0x83, 0x60, 0x80, 60, 0,
        ]

        let data = buildMIDIFile(format: 0, tpq: 480, tracks: [trackEvents])
        let importer = MIDIImporter()
        let score = try importer.importScore(from: data)

        XCTAssertFalse(score.parts.isEmpty, "Score should have at least one part")

        let part = score.parts[0]
        XCTAssertFalse(part.isPercussion, "Should not be a percussion part")
        XCTAssertFalse(part.measures.isEmpty, "Part should have at least one measure")

        // Check that the first measure has a note
        let firstMeasure = part.measures[0]
        let notes = firstMeasure.notes
        let pitchedNotes = notes.filter { !$0.isRest }
        XCTAssertGreaterThanOrEqual(pitchedNotes.count, 1, "First measure should have at least one pitched note")

        // Check the note is C4
        if let firstNote = pitchedNotes.first, case .pitched(let pitch) = firstNote.noteType {
            XCTAssertEqual(pitch.step, .c)
            XCTAssertEqual(pitch.octave, 4)
        }
    }

    // MARK: - Percussion Import

    func testImportDrumPattern() throws {
        // Drum pattern on channel 9: kick + hi-hat
        let trackEvents: [UInt8] = [
            // Tempo
            0x00, 0xFF, 0x51, 0x03, 0x07, 0xA1, 0x20,
            // Time sig: 4/4
            0x00, 0xFF, 0x58, 0x04, 0x04, 0x02, 0x18, 0x08,
            // Beat 1: Bass drum (36) + Closed hi-hat (42)
            0x00, 0x99, 36, 100,
            0x00, 0x99, 42, 80,
            // Off after eighth note
            0x81, 0x70, 0x89, 36, 0,   // delta=240
            0x00, 0x89, 42, 0,
            // Beat 1-and: Hi-hat only
            0x00, 0x99, 42, 80,
            0x81, 0x70, 0x89, 42, 0,   // delta=240
        ]

        let data = buildMIDIFile(format: 0, tpq: 480, tracks: [trackEvents])
        let importer = MIDIImporter()
        let score = try importer.importScore(from: data)

        XCTAssertFalse(score.parts.isEmpty)

        // Find the percussion part (channel 9)
        let drumPart = score.parts.first { $0.isPercussion }
        XCTAssertNotNil(drumPart, "Should have a drum part")
        XCTAssertNotNil(drumPart?.percussionMap, "Drum part should have a percussion map")

        if let measures = drumPart?.measures, !measures.isEmpty {
            // First measure should have percussion clef
            let attrs = measures[0].attributes
            XCTAssertNotNil(attrs)
            if let clef = attrs?.clefs.first {
                XCTAssertEqual(clef.sign, .percussion)
            }
        }
    }

    // MARK: - Format 1

    func testImportFormat1() throws {
        // Track 0: tempo/meta track
        let tempoTrack: [UInt8] = [
            0x00, 0xFF, 0x51, 0x03, 0x07, 0xA1, 0x20,  // 120 BPM
            0x00, 0xFF, 0x58, 0x04, 0x04, 0x02, 0x18, 0x08,  // 4/4
        ]

        // Track 1: Piano on channel 0
        let pianoTrack: [UInt8] = [
            0x00, 0xFF, 0x03, 0x05, 0x50, 0x69, 0x61, 0x6E, 0x6F,  // Track name "Piano"
            0x00, 0xC0, 0x00,  // Program change: Acoustic Grand Piano
            0x00, 0x90, 60, 100,
            0x83, 0x60, 0x80, 60, 0,
        ]

        let data = buildMIDIFile(format: 1, tpq: 480, tracks: [tempoTrack, pianoTrack])
        let importer = MIDIImporter()
        let score = try importer.importScore(from: data)

        XCTAssertGreaterThanOrEqual(score.parts.count, 1)

        let part = score.parts[0]
        XCTAssertEqual(part.name, "Piano")
        XCTAssertFalse(part.isPercussion)
    }

    // MARK: - Time Signature

    func testTimeSignatureInAttributes() throws {
        let trackEvents: [UInt8] = [
            // 3/4 time
            0x00, 0xFF, 0x58, 0x04, 0x03, 0x02, 0x18, 0x08,
            // Quarter note
            0x00, 0x90, 60, 100,
            0x83, 0x60, 0x80, 60, 0,
        ]

        let data = buildMIDIFile(format: 0, tpq: 480, tracks: [trackEvents])
        let importer = MIDIImporter()
        let score = try importer.importScore(from: data)

        let attrs = score.parts[0].measures[0].attributes
        XCTAssertNotNil(attrs)
        if let timeSig = attrs?.timeSignatures.first {
            XCTAssertEqual(timeSig.beats, "3")
            XCTAssertEqual(timeSig.beatType, "4")
        }
    }

    // MARK: - Key Signature

    func testKeySignatureInAttributes() throws {
        let trackEvents: [UInt8] = [
            // D major (2 sharps)
            0x00, 0xFF, 0x59, 0x02, 0x02, 0x00,
            // Quarter note
            0x00, 0x90, 60, 100,
            0x83, 0x60, 0x80, 60, 0,
        ]

        let data = buildMIDIFile(format: 0, tpq: 480, tracks: [trackEvents])
        let importer = MIDIImporter()
        let score = try importer.importScore(from: data)

        let attrs = score.parts[0].measures[0].attributes
        XCTAssertNotNil(attrs)
        if let keySig = attrs?.keySignatures.first {
            XCTAssertEqual(keySig.fifths, 2)
            XCTAssertEqual(keySig.mode, .major)
        }
    }

    // MARK: - Options

    func testCustomQuantizationResolution() throws {
        let trackEvents: [UInt8] = [
            0x00, 0x90, 60, 100,
            0x83, 0x60, 0x80, 60, 0,
        ]
        let data = buildMIDIFile(format: 0, tpq: 480, tracks: [trackEvents])

        let importer = MIDIImporter(options: MIDIImportOptions(quantizationResolution: .eighth))
        let score = try importer.importScore(from: data)
        XCTAssertFalse(score.parts.isEmpty)
    }

    func testExtendedDrumKit() throws {
        // China cymbal (MIDI 52) is only in extended kit
        let trackEvents: [UInt8] = [
            0x00, 0x99, 52, 100,            // China cymbal on ch9
            0x83, 0x60, 0x89, 52, 0,
        ]
        let data = buildMIDIFile(format: 0, tpq: 480, tracks: [trackEvents])

        let importer = MIDIImporter(options: MIDIImportOptions(useExtendedDrumKit: true))
        let score = try importer.importScore(from: data)

        let drumPart = score.parts.first { $0.isPercussion }
        XCTAssertNotNil(drumPart)
    }

    // MARK: - Error Handling

    func testEmptyDataThrows() {
        let importer = MIDIImporter()
        XCTAssertThrowsError(try importer.importScore(from: Data()))
    }

    func testInvalidDataThrows() {
        let importer = MIDIImporter()
        XCTAssertThrowsError(try importer.importScore(from: Data([0x00, 0x01, 0x02, 0x03])))
    }

    // MARK: - Multi-Part

    func testMultiplePartsFromChannels() throws {
        // One track with notes on channel 0 and channel 9
        let trackEvents: [UInt8] = [
            // Piano note on ch 0
            0x00, 0x90, 60, 100,
            0x83, 0x60, 0x80, 60, 0,
            // Drum note on ch 9
            0x00, 0x99, 36, 100,
            0x83, 0x60, 0x89, 36, 0,
        ]

        let data = buildMIDIFile(format: 0, tpq: 480, tracks: [trackEvents])
        let importer = MIDIImporter()
        let score = try importer.importScore(from: data)

        XCTAssertEqual(score.parts.count, 2, "Should have two parts: pitched and percussion")

        let percParts = score.parts.filter { $0.isPercussion }
        let pitchedParts = score.parts.filter { !$0.isPercussion }

        XCTAssertEqual(percParts.count, 1, "Should have one percussion part")
        XCTAssertEqual(pitchedParts.count, 1, "Should have one pitched part")
    }

    // MARK: - Divisions

    func testDivisionsSetCorrectly() throws {
        let trackEvents: [UInt8] = [
            0x00, 0x90, 60, 100,
            0x83, 0x60, 0x80, 60, 0,
        ]
        let data = buildMIDIFile(format: 0, tpq: 480, tracks: [trackEvents])

        let importer = MIDIImporter()
        let score = try importer.importScore(from: data)

        let attrs = score.parts[0].measures[0].attributes
        XCTAssertEqual(attrs?.divisions, 480)
    }
}
