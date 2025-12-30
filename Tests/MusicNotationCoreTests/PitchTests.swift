import XCTest
@testable import MusicNotationCore

final class PitchTests: XCTestCase {

    // MARK: - Initialization Tests

    func testBasicPitchCreation() {
        let pitch = Pitch(step: .c, alter: 0, octave: 4)
        XCTAssertEqual(pitch.step, .c)
        XCTAssertEqual(pitch.alter, 0)
        XCTAssertEqual(pitch.octave, 4)
    }

    func testPitchWithAlteration() {
        let cSharp = Pitch(step: .c, alter: 1, octave: 4)
        XCTAssertEqual(cSharp.alter, 1)

        let bFlat = Pitch(step: .b, alter: -1, octave: 3)
        XCTAssertEqual(bFlat.alter, -1)

        let fDoubleSharp = Pitch(step: .f, alter: 2, octave: 5)
        XCTAssertEqual(fDoubleSharp.alter, 2)
    }

    func testMicrotoneAlterations() {
        let quarterSharp = Pitch(step: .a, alter: 0.5, octave: 4)
        XCTAssertEqual(quarterSharp.alter, 0.5)

        let quarterFlat = Pitch(step: .e, alter: -0.5, octave: 4)
        XCTAssertEqual(quarterFlat.alter, -0.5)
    }

    // MARK: - MIDI Note Number Tests

    func testMiddleCMidiNumber() {
        let middleC = Pitch(step: .c, alter: 0, octave: 4)
        XCTAssertEqual(middleC.midiNoteNumber, 60)
    }

    func testConcertAMidiNumber() {
        let concertA = Pitch(step: .a, alter: 0, octave: 4)
        XCTAssertEqual(concertA.midiNoteNumber, 69)
    }

    func testMidiNoteNumberWithAlterations() {
        let cSharp4 = Pitch(step: .c, alter: 1, octave: 4)
        XCTAssertEqual(cSharp4.midiNoteNumber, 61)

        let bFlat3 = Pitch(step: .b, alter: -1, octave: 3)
        XCTAssertEqual(bFlat3.midiNoteNumber, 58)

        let fDoubleSharp5 = Pitch(step: .f, alter: 2, octave: 5)
        XCTAssertEqual(fDoubleSharp5.midiNoteNumber, 79) // F5=77 + 2 = 79
    }

    func testMidiNoteNumberRange() {
        // Lowest note on piano (A0)
        let a0 = Pitch(step: .a, alter: 0, octave: 0)
        XCTAssertEqual(a0.midiNoteNumber, 21)

        // Highest note on piano (C8)
        let c8 = Pitch(step: .c, alter: 0, octave: 8)
        XCTAssertEqual(c8.midiNoteNumber, 108)
    }

    func testMidiNoteNumberFromMidi() {
        // Test round-trip: MIDI -> Pitch -> MIDI
        for midiNote in 21...108 {
            let pitch = Pitch(midiNoteNumber: midiNote)
            XCTAssertEqual(pitch.midiNoteNumber, midiNote, "MIDI note \(midiNote) failed round-trip")
        }
    }

    // MARK: - Frequency Tests

    func testConcertAFrequency() {
        let concertA = Pitch(step: .a, alter: 0, octave: 4)
        XCTAssertEqual(concertA.frequency, 440.0, accuracy: 0.01)
    }

    func testMiddleCFrequency() {
        let middleC = Pitch(step: .c, alter: 0, octave: 4)
        XCTAssertEqual(middleC.frequency, 261.63, accuracy: 0.01)
    }

    func testOctaveDoubling() {
        let a4 = Pitch(step: .a, alter: 0, octave: 4)
        let a5 = Pitch(step: .a, alter: 0, octave: 5)
        XCTAssertEqual(a5.frequency, a4.frequency * 2, accuracy: 0.01)
    }

    // MARK: - Enharmonic Tests

    func testEnharmonicEquivalence() {
        let cSharp = Pitch(step: .c, alter: 1, octave: 4)
        let dFlat = Pitch(step: .d, alter: -1, octave: 4)
        XCTAssertTrue(cSharp.isEnharmonic(with: dFlat))
    }

    func testEnharmonicConversion() {
        let cSharp = Pitch(step: .c, alter: 1, octave: 4)
        let asD = cSharp.enharmonic(withStep: .d)
        XCTAssertEqual(asD.step, .d)
        XCTAssertEqual(asD.alter, -1)
        XCTAssertTrue(cSharp.isEnharmonic(with: asD))
    }

    func testDoubleSharpEnharmonic() {
        let fDoubleSharp = Pitch(step: .f, alter: 2, octave: 4)
        let gNatural = Pitch(step: .g, alter: 0, octave: 4)
        XCTAssertTrue(fDoubleSharp.isEnharmonic(with: gNatural))
    }

    // MARK: - Comparison Tests

    func testPitchOrdering() {
        let c4 = Pitch(step: .c, alter: 0, octave: 4)
        let d4 = Pitch(step: .d, alter: 0, octave: 4)
        let c5 = Pitch(step: .c, alter: 0, octave: 5)

        XCTAssertLessThan(c4, d4)
        XCTAssertLessThan(d4, c5)
        XCTAssertLessThan(c4, c5)
    }

    func testSemitonesInterval() {
        let c4 = Pitch(step: .c, alter: 0, octave: 4)
        let g4 = Pitch(step: .g, alter: 0, octave: 4)
        XCTAssertEqual(c4.semitones(to: g4), 7) // Perfect fifth

        let c5 = Pitch(step: .c, alter: 0, octave: 5)
        XCTAssertEqual(c4.semitones(to: c5), 12) // Octave
    }

    // MARK: - Pitch Class Tests

    func testDiatonicPitchClass() {
        XCTAssertEqual(Pitch(step: .c, octave: 4).diatonicPitchClass, 0)
        XCTAssertEqual(Pitch(step: .d, octave: 4).diatonicPitchClass, 1)
        XCTAssertEqual(Pitch(step: .e, octave: 4).diatonicPitchClass, 2)
        XCTAssertEqual(Pitch(step: .f, octave: 4).diatonicPitchClass, 3)
        XCTAssertEqual(Pitch(step: .g, octave: 4).diatonicPitchClass, 4)
        XCTAssertEqual(Pitch(step: .a, octave: 4).diatonicPitchClass, 5)
        XCTAssertEqual(Pitch(step: .b, octave: 4).diatonicPitchClass, 6)
    }

    func testChromaticPitchClass() {
        XCTAssertEqual(Pitch(step: .c, octave: 4).chromaticPitchClass, 0)
        XCTAssertEqual(Pitch(step: .c, alter: 1, octave: 4).chromaticPitchClass, 1)
        XCTAssertEqual(Pitch(step: .d, octave: 4).chromaticPitchClass, 2)
        XCTAssertEqual(Pitch(step: .b, octave: 4).chromaticPitchClass, 11)
    }

    // MARK: - Description Tests

    func testPitchDescription() {
        XCTAssertEqual(Pitch(step: .c, octave: 4).description, "C4")
        XCTAssertEqual(Pitch(step: .c, alter: 1, octave: 4).description, "C♯4")
        XCTAssertEqual(Pitch(step: .b, alter: -1, octave: 3).description, "B♭3")
        XCTAssertEqual(Pitch(step: .f, alter: 2, octave: 5).description, "F𝄪5")
        XCTAssertEqual(Pitch(step: .g, alter: -2, octave: 2).description, "G𝄫2")
    }

    // MARK: - Static Properties Tests

    func testStaticMiddleC() {
        XCTAssertEqual(Pitch.middleC, Pitch(step: .c, octave: 4))
        XCTAssertEqual(Pitch.middleC.midiNoteNumber, 60)
    }

    func testStaticConcertA() {
        XCTAssertEqual(Pitch.concertA, Pitch(step: .a, octave: 4))
        XCTAssertEqual(Pitch.concertA.midiNoteNumber, 69)
    }

    // MARK: - PitchStep Tests

    func testPitchStepChromaticOffset() {
        XCTAssertEqual(PitchStep.c.chromaticOffset, 0)
        XCTAssertEqual(PitchStep.d.chromaticOffset, 2)
        XCTAssertEqual(PitchStep.e.chromaticOffset, 4)
        XCTAssertEqual(PitchStep.f.chromaticOffset, 5)
        XCTAssertEqual(PitchStep.g.chromaticOffset, 7)
        XCTAssertEqual(PitchStep.a.chromaticOffset, 9)
        XCTAssertEqual(PitchStep.b.chromaticOffset, 11)
    }

    func testPitchStepAddingDiatonicSteps() {
        XCTAssertEqual(PitchStep.c.adding(diatonicSteps: 2), .e)
        XCTAssertEqual(PitchStep.g.adding(diatonicSteps: 3), .c)
        XCTAssertEqual(PitchStep.b.adding(diatonicSteps: 1), .c)
    }

    // MARK: - Codable Tests

    func testPitchCodable() throws {
        let pitch = Pitch(step: .f, alter: 1, octave: 5)
        let encoder = JSONEncoder()
        let data = try encoder.encode(pitch)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Pitch.self, from: data)
        XCTAssertEqual(pitch, decoded)
    }
}
