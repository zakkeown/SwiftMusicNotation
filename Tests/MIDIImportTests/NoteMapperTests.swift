import XCTest
import MusicNotationCore
@testable import MIDIImport

final class NoteMapperTests: XCTestCase {

    let defaultOptions = MIDIImportOptions()

    private func makeQuantizer(tpq: Int = 480) -> TickQuantizer {
        TickQuantizer(ticksPerQuarter: tpq)
    }

    private func makeMapper(tpq: Int = 480) -> NoteMapper {
        NoteMapper(quantizer: makeQuantizer(tpq: tpq), options: defaultOptions)
    }

    // MARK: - Note-On/Off Pairing

    func testBasicPairing() {
        let mapper = makeMapper()
        let events: [MIDITrackEvent] = [
            MIDITrackEvent(absoluteTick: 0, event: .noteOn(channel: 0, note: 60, velocity: 100)),
            MIDITrackEvent(absoluteTick: 480, event: .noteOff(channel: 0, note: 60, velocity: 0)),
        ]

        let spans = mapper.pairNotes(events: events)
        XCTAssertEqual(spans.count, 1)
        XCTAssertEqual(spans[0].startTick, 0)
        XCTAssertEqual(spans[0].endTick, 480)
        XCTAssertEqual(spans[0].noteNumber, 60)
        XCTAssertEqual(spans[0].velocity, 100)
    }

    func testMultipleNotes() {
        let mapper = makeMapper()
        let events: [MIDITrackEvent] = [
            MIDITrackEvent(absoluteTick: 0, event: .noteOn(channel: 0, note: 60, velocity: 100)),
            MIDITrackEvent(absoluteTick: 480, event: .noteOff(channel: 0, note: 60, velocity: 0)),
            MIDITrackEvent(absoluteTick: 480, event: .noteOn(channel: 0, note: 62, velocity: 90)),
            MIDITrackEvent(absoluteTick: 960, event: .noteOff(channel: 0, note: 62, velocity: 0)),
        ]

        let spans = mapper.pairNotes(events: events)
        XCTAssertEqual(spans.count, 2)
        XCTAssertEqual(spans[0].noteNumber, 60)
        XCTAssertEqual(spans[1].noteNumber, 62)
    }

    func testSimultaneousNotes() {
        let mapper = makeMapper()
        // Two notes starting at the same time (chord)
        let events: [MIDITrackEvent] = [
            MIDITrackEvent(absoluteTick: 0, event: .noteOn(channel: 0, note: 60, velocity: 100)),
            MIDITrackEvent(absoluteTick: 0, event: .noteOn(channel: 0, note: 64, velocity: 100)),
            MIDITrackEvent(absoluteTick: 480, event: .noteOff(channel: 0, note: 60, velocity: 0)),
            MIDITrackEvent(absoluteTick: 480, event: .noteOff(channel: 0, note: 64, velocity: 0)),
        ]

        let spans = mapper.pairNotes(events: events)
        XCTAssertEqual(spans.count, 2)
    }

    func testIgnoresNonNoteEvents() {
        let mapper = makeMapper()
        let events: [MIDITrackEvent] = [
            MIDITrackEvent(absoluteTick: 0, event: .programChange(channel: 0, program: 0)),
            MIDITrackEvent(absoluteTick: 0, event: .noteOn(channel: 0, note: 60, velocity: 100)),
            MIDITrackEvent(absoluteTick: 0, event: .controlChange(channel: 0, controller: 7, value: 100)),
            MIDITrackEvent(absoluteTick: 480, event: .noteOff(channel: 0, note: 60, velocity: 0)),
        ]

        let spans = mapper.pairNotes(events: events)
        XCTAssertEqual(spans.count, 1)
    }

    // MARK: - Pitched Note Building

    func testBuildPitchedNote() {
        let mapper = makeMapper()
        let spans = [
            NoteMapper.NoteSpan(startTick: 0, endTick: 480, noteNumber: 60, velocity: 100, channel: 0),
        ]

        let notes = mapper.buildPitchedNotes(spans: spans, divisions: 480)
        XCTAssertEqual(notes.count, 1)

        let note = notes[0].note
        XCTAssertFalse(note.isRest)
        XCTAssertFalse(note.isChordTone)
        if case .pitched(let pitch) = note.noteType {
            XCTAssertEqual(pitch.step, .c)
            XCTAssertEqual(pitch.octave, 4) // Middle C
        } else {
            XCTFail("Expected pitched note")
        }
        XCTAssertEqual(note.type, .quarter) // 480 ticks at 480 tpq
    }

    func testChordDetection() {
        let mapper = makeMapper()
        let spans = [
            NoteMapper.NoteSpan(startTick: 0, endTick: 480, noteNumber: 60, velocity: 100, channel: 0),
            NoteMapper.NoteSpan(startTick: 0, endTick: 480, noteNumber: 64, velocity: 100, channel: 0),
        ]

        let notes = mapper.buildPitchedNotes(spans: spans, divisions: 480)
        XCTAssertEqual(notes.count, 2)
        XCTAssertFalse(notes[0].note.isChordTone)
        XCTAssertTrue(notes[1].note.isChordTone)
    }

    func testGhostNoteDetection() {
        let mapper = makeMapper() // threshold = 40
        let spans = [
            NoteMapper.NoteSpan(startTick: 0, endTick: 480, noteNumber: 60, velocity: 30, channel: 0),
        ]

        let notes = mapper.buildPitchedNotes(spans: spans, divisions: 480)
        XCTAssertEqual(notes.count, 1)
        XCTAssertNotNil(notes[0].note.notehead)
        XCTAssertEqual(notes[0].note.notehead?.parentheses, true)
    }

    // MARK: - Percussion Note Building

    func testPercussionNoteBuild() {
        let mapper = makeMapper()
        let percMap = PercussionMap.standardDrumKit

        let spans = [
            // Bass drum (MIDI 36)
            NoteMapper.NoteSpan(startTick: 0, endTick: 480, noteNumber: 36, velocity: 100, channel: 9),
        ]

        let notes = mapper.buildPercussionNotes(spans: spans, percussionMap: percMap, divisions: 480)
        XCTAssertEqual(notes.count, 1)

        let note = notes[0].note
        if case .unpitched(let unpitched) = note.noteType {
            XCTAssertEqual(unpitched.displayStep, .f)
            XCTAssertEqual(unpitched.displayOctave, 4)
            XCTAssertEqual(unpitched.percussionInstrument, .bassDrum)
        } else {
            XCTFail("Expected unpitched note")
        }
    }

    func testPercussionVoiceSeparation() {
        let mapper = makeMapper()
        let percMap = PercussionMap.standardDrumKit

        let spans = [
            // Hi-hat (MIDI 42) — stems up → voice 1
            NoteMapper.NoteSpan(startTick: 0, endTick: 480, noteNumber: 42, velocity: 100, channel: 9),
            // Bass drum (MIDI 36) — stems down → voice 2
            NoteMapper.NoteSpan(startTick: 0, endTick: 480, noteNumber: 36, velocity: 100, channel: 9),
        ]

        let notes = mapper.buildPercussionNotes(spans: spans, percussionMap: percMap, divisions: 480)
        XCTAssertEqual(notes.count, 2)

        let voice1Notes = notes.filter { $0.note.voice == 1 }
        let voice2Notes = notes.filter { $0.note.voice == 2 }

        XCTAssertEqual(voice1Notes.count, 1)
        XCTAssertEqual(voice2Notes.count, 1)

        // Hi-hat should be in voice 1
        if case .unpitched(let unpitched) = voice1Notes[0].note.noteType {
            XCTAssertEqual(unpitched.percussionInstrument, .hiHatClosed)
        }
        // Bass drum should be in voice 2
        if case .unpitched(let unpitched) = voice2Notes[0].note.noteType {
            XCTAssertEqual(unpitched.percussionInstrument, .bassDrum)
        }
    }

    func testPercussionNoteheadStyles() {
        let mapper = makeMapper()
        let percMap = PercussionMap.standardDrumKit

        // Test that hi-hat gets X notehead
        let spans = [
            NoteMapper.NoteSpan(startTick: 0, endTick: 480, noteNumber: 42, velocity: 100, channel: 9),
        ]

        let notes = mapper.buildPercussionNotes(spans: spans, percussionMap: percMap, divisions: 480)
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes[0].note.notehead?.type, .x)
    }

    func testPercussionGhostNote() {
        let mapper = makeMapper()
        let percMap = PercussionMap.standardDrumKit

        let spans = [
            // Snare ghost note (velocity < 40)
            NoteMapper.NoteSpan(startTick: 0, endTick: 480, noteNumber: 38, velocity: 20, channel: 9),
        ]

        let notes = mapper.buildPercussionNotes(spans: spans, percussionMap: percMap, divisions: 480)
        XCTAssertEqual(notes.count, 1)
        XCTAssertEqual(notes[0].note.notehead?.parentheses, true)
    }
}
