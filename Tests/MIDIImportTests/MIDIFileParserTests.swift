import XCTest
@testable import MIDIImport

final class MIDIFileParserTests: XCTestCase {

    let parser = MIDIFileParser()

    // MARK: - Helper: Build Minimal MIDI Data

    /// Builds a minimal Format 0 MIDI file with one track containing the given events.
    private func buildMIDIData(
        format: UInt16 = 0,
        trackCount: UInt16 = 1,
        tpq: UInt16 = 480,
        trackEvents: [UInt8] = []
    ) -> Data {
        var data = Data()

        // Header: MThd
        data.append(contentsOf: [0x4D, 0x54, 0x68, 0x64]) // "MThd"
        data.append(contentsOf: uint32Bytes(6))             // chunk size
        data.append(contentsOf: uint16Bytes(format))        // format
        data.append(contentsOf: uint16Bytes(trackCount))    // track count
        data.append(contentsOf: uint16Bytes(tpq))           // ticks per quarter

        // Track: MTrk
        data.append(contentsOf: [0x4D, 0x54, 0x72, 0x6B]) // "MTrk"
        let trackData = trackEvents + [0x00, 0xFF, 0x2F, 0x00] // + end-of-track
        data.append(contentsOf: uint32Bytes(UInt32(trackData.count)))
        data.append(contentsOf: trackData)

        return data
    }

    private func uint16Bytes(_ value: UInt16) -> [UInt8] {
        [UInt8(value >> 8), UInt8(value & 0xFF)]
    }

    private func uint32Bytes(_ value: UInt32) -> [UInt8] {
        [UInt8((value >> 24) & 0xFF), UInt8((value >> 16) & 0xFF),
         UInt8((value >> 8) & 0xFF), UInt8(value & 0xFF)]
    }

    // MARK: - Header Tests

    func testParseValidHeader() throws {
        let data = buildMIDIData(format: 0, trackCount: 1, tpq: 480)
        let file = try parser.parse(data)

        XCTAssertEqual(file.format, 0)
        XCTAssertEqual(file.trackCount, 1)
        if case .ticksPerQuarter(let tpq) = file.timeDivision {
            XCTAssertEqual(tpq, 480)
        } else {
            XCTFail("Expected ticksPerQuarter time division")
        }
    }

    func testParseFormat1Header() throws {
        // Build a format 1 file with 2 tracks
        var data = Data()
        data.append(contentsOf: [0x4D, 0x54, 0x68, 0x64]) // MThd
        data.append(contentsOf: uint32Bytes(6))
        data.append(contentsOf: uint16Bytes(1))   // format 1
        data.append(contentsOf: uint16Bytes(2))   // 2 tracks
        data.append(contentsOf: uint16Bytes(960)) // tpq 960

        // Track 1 (tempo track)
        let track1Events: [UInt8] = [0x00, 0xFF, 0x2F, 0x00]
        data.append(contentsOf: [0x4D, 0x54, 0x72, 0x6B])
        data.append(contentsOf: uint32Bytes(UInt32(track1Events.count)))
        data.append(contentsOf: track1Events)

        // Track 2
        let track2Events: [UInt8] = [0x00, 0xFF, 0x2F, 0x00]
        data.append(contentsOf: [0x4D, 0x54, 0x72, 0x6B])
        data.append(contentsOf: uint32Bytes(UInt32(track2Events.count)))
        data.append(contentsOf: track2Events)

        let file = try parser.parse(data)
        XCTAssertEqual(file.format, 1)
        XCTAssertEqual(file.trackCount, 2)
        XCTAssertEqual(file.tracks.count, 2)
        if case .ticksPerQuarter(let tpq) = file.timeDivision {
            XCTAssertEqual(tpq, 960)
        } else {
            XCTFail("Expected ticksPerQuarter")
        }
    }

    func testInvalidHeaderThrows() {
        // 14+ bytes but wrong magic bytes (not "MThd")
        let data = Data([
            0x00, 0x01, 0x02, 0x03, 0x00, 0x00, 0x00, 0x06,
            0x00, 0x00, 0x00, 0x01, 0x01, 0xE0
        ])
        XCTAssertThrowsError(try parser.parse(data)) { error in
            if case MIDIError.invalidHeader = error {} else {
                XCTFail("Expected invalidHeader, got \(error)")
            }
        }
    }

    func testUnsupportedFormatThrows() {
        // Format 2
        var data = Data()
        data.append(contentsOf: [0x4D, 0x54, 0x68, 0x64])
        data.append(contentsOf: uint32Bytes(6))
        data.append(contentsOf: uint16Bytes(2))   // format 2
        data.append(contentsOf: uint16Bytes(1))
        data.append(contentsOf: uint16Bytes(480))
        // Empty track
        data.append(contentsOf: [0x4D, 0x54, 0x72, 0x6B])
        data.append(contentsOf: uint32Bytes(4))
        data.append(contentsOf: [0x00, 0xFF, 0x2F, 0x00])

        XCTAssertThrowsError(try parser.parse(data)) { error in
            if case MIDIError.unsupportedFormat(2) = error {} else {
                XCTFail("Expected unsupportedFormat(2), got \(error)")
            }
        }
    }

    func testEmptyDataThrows() {
        XCTAssertThrowsError(try parser.parse(Data())) { error in
            if case MIDIError.unexpectedEOF = error {} else {
                XCTFail("Expected unexpectedEOF, got \(error)")
            }
        }
    }

    // MARK: - Event Tests

    func testParseNoteOnOff() throws {
        // Delta=0, Note On ch0, C4 (60), vel 100
        // Delta=480 (variable length: 0x83, 0x60), Note Off ch0, C4, vel 0
        let events: [UInt8] = [
            0x00, 0x90, 60, 100,          // delta=0, note on ch0, C4, vel=100
            0x83, 0x60, 0x80, 60, 0,      // delta=480, note off ch0, C4, vel=0
        ]
        let data = buildMIDIData(tpq: 480, trackEvents: events)
        let file = try parser.parse(data)

        XCTAssertEqual(file.tracks.count, 1)
        let trackEvents = file.tracks[0].events

        // First event: note on at tick 0
        if case .noteOn(let ch, let note, let vel) = trackEvents[0].event {
            XCTAssertEqual(ch, 0)
            XCTAssertEqual(note, 60)
            XCTAssertEqual(vel, 100)
            XCTAssertEqual(trackEvents[0].absoluteTick, 0)
        } else {
            XCTFail("Expected noteOn, got \(trackEvents[0].event)")
        }

        // Second event: note off at tick 480
        if case .noteOff(let ch, let note, _) = trackEvents[1].event {
            XCTAssertEqual(ch, 0)
            XCTAssertEqual(note, 60)
            XCTAssertEqual(trackEvents[1].absoluteTick, 480)
        } else {
            XCTFail("Expected noteOff, got \(trackEvents[1].event)")
        }
    }

    func testNoteOnVelocityZeroIsNoteOff() throws {
        let events: [UInt8] = [
            0x00, 0x90, 60, 100,   // note on
            0x83, 0x60, 0x90, 60, 0, // note on with vel=0 → note off
        ]
        let data = buildMIDIData(tpq: 480, trackEvents: events)
        let file = try parser.parse(data)

        if case .noteOff = file.tracks[0].events[1].event {} else {
            XCTFail("Note On with velocity 0 should be parsed as Note Off")
        }
    }

    func testRunningStatus() throws {
        // Note On ch0 (0x90), then running status for the next note on
        let events: [UInt8] = [
            0x00, 0x90, 60, 100,   // note on ch0, C4, vel 100
            0x00, 62, 80,          // running status: note on ch0, D4, vel 80
            0x83, 0x60, 60, 0,     // running status: note on ch0, C4, vel 0 (= note off)
            0x00, 62, 0,           // running status: note on ch0, D4, vel 0 (= note off)
        ]
        let data = buildMIDIData(tpq: 480, trackEvents: events)
        let file = try parser.parse(data)

        let trackEvents = file.tracks[0].events

        // Should have 4 channel events + end of track
        XCTAssertGreaterThanOrEqual(trackEvents.count, 4)

        if case .noteOn(_, let note, _) = trackEvents[0].event {
            XCTAssertEqual(note, 60)
        } else {
            XCTFail("Expected noteOn")
        }

        if case .noteOn(_, let note, _) = trackEvents[1].event {
            XCTAssertEqual(note, 62)
        } else {
            XCTFail("Expected noteOn via running status")
        }

        if case .noteOff(_, let note, _) = trackEvents[2].event {
            XCTAssertEqual(note, 60)
        } else {
            XCTFail("Expected noteOff via running status")
        }
    }

    func testParseTempo() throws {
        // Tempo: 120 BPM = 500000 µs/qn = 0x07A120
        let events: [UInt8] = [
            0x00, 0xFF, 0x51, 0x03, 0x07, 0xA1, 0x20,  // tempo meta event
        ]
        let data = buildMIDIData(tpq: 480, trackEvents: events)
        let file = try parser.parse(data)

        if case .tempo(let usPerQN) = file.tracks[0].events[0].event {
            XCTAssertEqual(usPerQN, 500_000)
        } else {
            XCTFail("Expected tempo event")
        }
    }

    func testParseTimeSignature() throws {
        // Time sig: 3/4, 24 clocks/click, 8 32nd-notes/quarter
        let events: [UInt8] = [
            0x00, 0xFF, 0x58, 0x04, 0x03, 0x02, 0x18, 0x08,
        ]
        let data = buildMIDIData(tpq: 480, trackEvents: events)
        let file = try parser.parse(data)

        if case .timeSignature(let num, let denom, _, _) = file.tracks[0].events[0].event {
            XCTAssertEqual(num, 3)
            XCTAssertEqual(denom, 4) // 2^2 = 4
        } else {
            XCTFail("Expected time signature event")
        }
    }

    func testParseKeySignature() throws {
        // Key sig: 2 sharps, major (D major)
        let events: [UInt8] = [
            0x00, 0xFF, 0x59, 0x02, 0x02, 0x00,
        ]
        let data = buildMIDIData(tpq: 480, trackEvents: events)
        let file = try parser.parse(data)

        if case .keySignature(let sf, let isMinor) = file.tracks[0].events[0].event {
            XCTAssertEqual(sf, 2)
            XCTAssertFalse(isMinor)
        } else {
            XCTFail("Expected key signature event")
        }
    }

    func testParseTrackName() throws {
        let name = "Piano"
        let nameBytes = Array(name.utf8)
        var events: [UInt8] = [0x00, 0xFF, 0x03]
        events.append(UInt8(nameBytes.count))
        events.append(contentsOf: nameBytes)

        let data = buildMIDIData(tpq: 480, trackEvents: events)
        let file = try parser.parse(data)

        if case .trackName(let parsedName) = file.tracks[0].events[0].event {
            XCTAssertEqual(parsedName, "Piano")
        } else {
            XCTFail("Expected track name event")
        }
    }

    func testParseProgramChange() throws {
        let events: [UInt8] = [
            0x00, 0xC0, 0x00,  // Program change ch0, program 0 (Acoustic Grand Piano)
        ]
        let data = buildMIDIData(tpq: 480, trackEvents: events)
        let file = try parser.parse(data)

        if case .programChange(let ch, let prog) = file.tracks[0].events[0].event {
            XCTAssertEqual(ch, 0)
            XCTAssertEqual(prog, 0)
        } else {
            XCTFail("Expected program change event")
        }
    }

    func testVariableLengthQuantity() throws {
        // Delta time of 128 (0x80) encoded as VLQ: 0x81, 0x00
        let events: [UInt8] = [
            0x00, 0x90, 60, 100,       // delta=0, note on
            0x81, 0x00, 0x80, 60, 0,   // delta=128, note off
        ]
        let data = buildMIDIData(tpq: 480, trackEvents: events)
        let file = try parser.parse(data)

        XCTAssertEqual(file.tracks[0].events[1].absoluteTick, 128)
    }

    func testAbsoluteTickAccumulation() throws {
        let events: [UInt8] = [
            0x00, 0x90, 60, 100,           // delta=0, note on at tick 0
            0x83, 0x60, 0x80, 60, 0,       // delta=480, note off at tick 480
            0x00, 0x90, 64, 100,           // delta=0, note on at tick 480
            0x83, 0x60, 0x80, 64, 0,       // delta=480, note off at tick 960
        ]
        let data = buildMIDIData(tpq: 480, trackEvents: events)
        let file = try parser.parse(data)

        let events2 = file.tracks[0].events
        XCTAssertEqual(events2[0].absoluteTick, 0)
        XCTAssertEqual(events2[1].absoluteTick, 480)
        XCTAssertEqual(events2[2].absoluteTick, 480)
        XCTAssertEqual(events2[3].absoluteTick, 960)
    }

    func testPercussionChannel() throws {
        // Channel 9 (0-indexed) = percussion
        let events: [UInt8] = [
            0x00, 0x99, 36, 100,           // Note on ch9, bass drum (36), vel 100
            0x83, 0x60, 0x89, 36, 0,       // Note off ch9, bass drum
        ]
        let data = buildMIDIData(tpq: 480, trackEvents: events)
        let file = try parser.parse(data)

        if case .noteOn(let ch, let note, _) = file.tracks[0].events[0].event {
            XCTAssertEqual(ch, 9)
            XCTAssertEqual(note, 36)
        } else {
            XCTFail("Expected noteOn on channel 9")
        }
    }
}
