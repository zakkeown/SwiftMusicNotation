import XCTest
@testable import MusicNotationCore

final class ChordTests: XCTestCase {

    // MARK: - Initialization Tests

    func testChordInitializationWithNotes() {
        let note1 = Note(noteType: .pitched(Pitch(step: .c, octave: 4)), durationDivisions: 1)
        let note2 = Note(noteType: .pitched(Pitch(step: .e, octave: 4)), durationDivisions: 1)
        let note3 = Note(noteType: .pitched(Pitch(step: .g, octave: 4)), durationDivisions: 1)

        let chord = Chord(notes: [note3, note1, note2]) // Intentionally out of order

        XCTAssertEqual(chord.noteCount, 3)
        // Notes should be sorted by pitch
        XCTAssertEqual(chord.notes[0].pitch?.step, .c)
        XCTAssertEqual(chord.notes[1].pitch?.step, .e)
        XCTAssertEqual(chord.notes[2].pitch?.step, .g)
    }

    func testChordInitializationFromSingleNote() {
        let note = Note(noteType: .pitched(Pitch(step: .d, octave: 4)), durationDivisions: 2, voice: 2, staff: 1)
        let chord = Chord(note: note)

        XCTAssertEqual(chord.noteCount, 1)
        XCTAssertEqual(chord.voice, 2)
        XCTAssertEqual(chord.staff, 1)
        XCTAssertTrue(chord.isSingleNote)
    }

    // MARK: - Pitch Access Tests

    func testLowestAndHighestNote() {
        let low = Note(noteType: .pitched(Pitch(step: .c, octave: 3)), durationDivisions: 1)
        let mid = Note(noteType: .pitched(Pitch(step: .g, octave: 4)), durationDivisions: 1)
        let high = Note(noteType: .pitched(Pitch(step: .e, octave: 5)), durationDivisions: 1)

        let chord = Chord(notes: [mid, high, low])

        XCTAssertEqual(chord.lowestNote?.pitch?.step, .c)
        XCTAssertEqual(chord.lowestNote?.pitch?.octave, 3)
        XCTAssertEqual(chord.highestNote?.pitch?.step, .e)
        XCTAssertEqual(chord.highestNote?.pitch?.octave, 5)
    }

    func testLowestAndHighestPitch() {
        let low = Note(noteType: .pitched(Pitch(step: .a, octave: 3)), durationDivisions: 1)
        let high = Note(noteType: .pitched(Pitch(step: .b, octave: 4)), durationDivisions: 1)

        let chord = Chord(notes: [low, high])

        XCTAssertEqual(chord.lowestPitch?.step, .a)
        XCTAssertEqual(chord.highestPitch?.step, .b)
    }

    func testPitches() {
        let note1 = Note(noteType: .pitched(Pitch(step: .c, octave: 4)), durationDivisions: 1)
        let note2 = Note(noteType: .pitched(Pitch(step: .e, octave: 4)), durationDivisions: 1)
        let note3 = Note(noteType: .pitched(Pitch(step: .g, octave: 4)), durationDivisions: 1)

        let chord = Chord(notes: [note1, note2, note3])

        let pitches = chord.pitches
        XCTAssertEqual(pitches.count, 3)
        XCTAssertEqual(pitches[0].step, .c)
        XCTAssertEqual(pitches[1].step, .e)
        XCTAssertEqual(pitches[2].step, .g)
    }

    func testSpan() {
        // C4 (MIDI 60) to G4 (MIDI 67) = 7 semitones
        let low = Note(noteType: .pitched(Pitch(step: .c, octave: 4)), durationDivisions: 1)
        let high = Note(noteType: .pitched(Pitch(step: .g, octave: 4)), durationDivisions: 1)

        let chord = Chord(notes: [low, high])

        XCTAssertEqual(chord.span, 7)
    }

    // MARK: - Note Management Tests

    func testAddNote() {
        let note1 = Note(noteType: .pitched(Pitch(step: .c, octave: 4)), durationDivisions: 1)
        let note2 = Note(noteType: .pitched(Pitch(step: .g, octave: 4)), durationDivisions: 1)

        var chord = Chord(notes: [note1])
        XCTAssertEqual(chord.noteCount, 1)

        // Add a note that should be sorted after
        chord.addNote(note2)
        XCTAssertEqual(chord.noteCount, 2)
        XCTAssertEqual(chord.notes[0].pitch?.step, .c)
        XCTAssertEqual(chord.notes[1].pitch?.step, .g)

        // Add a note in the middle
        let note3 = Note(noteType: .pitched(Pitch(step: .e, octave: 4)), durationDivisions: 1)
        chord.addNote(note3)
        XCTAssertEqual(chord.noteCount, 3)
        XCTAssertEqual(chord.notes[1].pitch?.step, .e)
    }

    func testRemoveNote() {
        let note1 = Note(noteType: .pitched(Pitch(step: .c, octave: 4)), durationDivisions: 1)
        let note2 = Note(noteType: .pitched(Pitch(step: .e, octave: 4)), durationDivisions: 1)
        let note3 = Note(noteType: .pitched(Pitch(step: .g, octave: 4)), durationDivisions: 1)

        var chord = Chord(notes: [note1, note2, note3])
        XCTAssertEqual(chord.noteCount, 3)

        let removed = chord.removeNote(withId: note2.id)
        XCTAssertNotNil(removed)
        XCTAssertEqual(removed?.pitch?.step, .e)
        XCTAssertEqual(chord.noteCount, 2)
    }

    func testRemoveNonExistentNote() {
        let note1 = Note(noteType: .pitched(Pitch(step: .c, octave: 4)), durationDivisions: 1)
        var chord = Chord(notes: [note1])

        let removed = chord.removeNote(withId: UUID())
        XCTAssertNil(removed)
        XCTAssertEqual(chord.noteCount, 1)
    }

    func testNoteAtPitch() {
        let pitch1 = Pitch(step: .c, octave: 4)
        let pitch2 = Pitch(step: .e, octave: 4)
        let note1 = Note(noteType: .pitched(pitch1), durationDivisions: 1)
        let note2 = Note(noteType: .pitched(pitch2), durationDivisions: 1)

        let chord = Chord(notes: [note1, note2])

        XCTAssertNotNil(chord.note(at: pitch1))
        XCTAssertNotNil(chord.note(at: pitch2))
        XCTAssertNil(chord.note(at: Pitch(step: .g, octave: 4)))
    }

    // MARK: - Stem Calculations Tests

    func testOptimalStemDirectionAboveMiddle() {
        // Notes above middle line (B4) should have stem down
        let high1 = Note(noteType: .pitched(Pitch(step: .c, octave: 5)), durationDivisions: 1)
        let high2 = Note(noteType: .pitched(Pitch(step: .e, octave: 5)), durationDivisions: 1)

        let chord = Chord(notes: [high1, high2])

        XCTAssertEqual(chord.optimalStemDirection(), .down)
    }

    func testOptimalStemDirectionBelowMiddle() {
        // Notes below middle line (B4) should have stem up
        let low1 = Note(noteType: .pitched(Pitch(step: .c, octave: 4)), durationDivisions: 1)
        let low2 = Note(noteType: .pitched(Pitch(step: .e, octave: 4)), durationDivisions: 1)

        let chord = Chord(notes: [low1, low2])

        XCTAssertEqual(chord.optimalStemDirection(), .up)
    }

    func testOptimalStemDirectionEmpty() {
        let chord = Chord(notes: [], voice: 1, staff: 1)
        XCTAssertEqual(chord.optimalStemDirection(), .up)
    }

    func testSecondsRequiringOffset() {
        // C4 and D4 are a second apart (2 semitones)
        let note1 = Note(noteType: .pitched(Pitch(step: .c, octave: 4)), durationDivisions: 1)
        let note2 = Note(noteType: .pitched(Pitch(step: .d, octave: 4)), durationDivisions: 1)
        let note3 = Note(noteType: .pitched(Pitch(step: .g, octave: 4)), durationDivisions: 1)

        let chord = Chord(notes: [note1, note2, note3])

        let seconds = chord.secondsRequiringOffset
        XCTAssertEqual(seconds.count, 1)
        XCTAssertEqual(seconds[0].0, 0)
        XCTAssertEqual(seconds[0].1, 1)
    }

    func testContainsSeconds() {
        // No seconds
        let note1 = Note(noteType: .pitched(Pitch(step: .c, octave: 4)), durationDivisions: 1)
        let note2 = Note(noteType: .pitched(Pitch(step: .e, octave: 4)), durationDivisions: 1)
        let chord1 = Chord(notes: [note1, note2])
        XCTAssertFalse(chord1.containsSeconds)

        // With seconds
        let note3 = Note(noteType: .pitched(Pitch(step: .c, octave: 4)), durationDivisions: 1)
        let note4 = Note(noteType: .pitched(Pitch(step: .d, octave: 4)), durationDivisions: 1)
        let chord2 = Chord(notes: [note3, note4])
        XCTAssertTrue(chord2.containsSeconds)
    }

    // MARK: - Chord Properties Tests

    func testIsSingleNote() {
        let note = Note(noteType: .pitched(Pitch(step: .c, octave: 4)), durationDivisions: 1)
        let singleChord = Chord(notes: [note])
        XCTAssertTrue(singleChord.isSingleNote)

        let note2 = Note(noteType: .pitched(Pitch(step: .e, octave: 4)), durationDivisions: 1)
        let multiChord = Chord(notes: [note, note2])
        XCTAssertFalse(multiChord.isSingleNote)
    }

    func testDurationProperties() {
        let note1 = Note(noteType: .pitched(Pitch(step: .c, octave: 4)), durationDivisions: 4, type: .quarter, dots: 1)
        let note2 = Note(noteType: .pitched(Pitch(step: .e, octave: 4)), durationDivisions: 4, type: .quarter, dots: 1)

        let chord = Chord(notes: [note1, note2])

        XCTAssertEqual(chord.durationDivisions, 4)
        XCTAssertEqual(chord.type, .quarter)
        XCTAssertEqual(chord.dots, 1)
    }

    // MARK: - Interval Analysis Tests

    func testIntervals() {
        // C4 to E4 = 4 semitones, E4 to G4 = 3 semitones
        let note1 = Note(noteType: .pitched(Pitch(step: .c, octave: 4)), durationDivisions: 1)
        let note2 = Note(noteType: .pitched(Pitch(step: .e, octave: 4)), durationDivisions: 1)
        let note3 = Note(noteType: .pitched(Pitch(step: .g, octave: 4)), durationDivisions: 1)

        let chord = Chord(notes: [note1, note2, note3])

        let intervals = chord.intervals
        XCTAssertEqual(intervals.count, 2)
        XCTAssertEqual(intervals[0], 4) // C to E
        XCTAssertEqual(intervals[1], 3) // E to G
    }

    func testIsClosePosition() {
        // C4 to G4 = 7 semitones (close position, <= 12)
        let note1 = Note(noteType: .pitched(Pitch(step: .c, octave: 4)), durationDivisions: 1)
        let note2 = Note(noteType: .pitched(Pitch(step: .g, octave: 4)), durationDivisions: 1)

        let closeChord = Chord(notes: [note1, note2])
        XCTAssertTrue(closeChord.isClosePosition)
        XCTAssertFalse(closeChord.isOpenPosition)
    }

    func testIsOpenPosition() {
        // C4 to E5 = 16 semitones (open position, > 12)
        let note1 = Note(noteType: .pitched(Pitch(step: .c, octave: 4)), durationDivisions: 1)
        let note2 = Note(noteType: .pitched(Pitch(step: .e, octave: 5)), durationDivisions: 1)

        let openChord = Chord(notes: [note1, note2])
        XCTAssertTrue(openChord.isOpenPosition)
        XCTAssertFalse(openChord.isClosePosition)
    }

    // MARK: - Factory Methods Tests

    func testFromPitches() {
        let pitches = [
            Pitch(step: .c, octave: 4),
            Pitch(step: .e, octave: 4),
            Pitch(step: .g, octave: 4)
        ]

        let chord = Chord.fromPitches(pitches, durationDivisions: 4, type: .quarter)

        XCTAssertEqual(chord.noteCount, 3)
        XCTAssertEqual(chord.durationDivisions, 4)
        XCTAssertEqual(chord.type, .quarter)

        // First note should not be a chord tone, rest should be
        XCTAssertFalse(chord.notes[0].isChordTone)
        XCTAssertTrue(chord.notes[1].isChordTone)
        XCTAssertTrue(chord.notes[2].isChordTone)
    }

    func testMajorTriad() {
        let root = Pitch(step: .c, octave: 4)
        let chord = Chord.majorTriad(root: root, durationDivisions: 4, type: .quarter)

        XCTAssertEqual(chord.noteCount, 3)

        let intervals = chord.intervals
        XCTAssertEqual(intervals[0], 4) // Major third
        XCTAssertEqual(intervals[1], 3) // Minor third (to make perfect fifth)
    }

    func testMinorTriad() {
        let root = Pitch(step: .c, octave: 4)
        let chord = Chord.minorTriad(root: root, durationDivisions: 4, type: .quarter)

        XCTAssertEqual(chord.noteCount, 3)

        let intervals = chord.intervals
        XCTAssertEqual(intervals[0], 3) // Minor third
        XCTAssertEqual(intervals[1], 4) // Major third (to make perfect fifth)
    }

    // MARK: - Pitch Transposition Helper Tests

    func testPitchTransposed() {
        let pitch = Pitch(step: .c, octave: 4) // MIDI 60
        let transposed = pitch.transposed(by: 7) // Perfect fifth up

        XCTAssertEqual(transposed.midiNoteNumber, 67) // G4
    }

    func testPitchTransposedNegative() {
        let pitch = Pitch(step: .c, octave: 5) // MIDI 72
        let transposed = pitch.transposed(by: -12) // Octave down

        XCTAssertEqual(transposed.midiNoteNumber, 60) // C4
    }
}
