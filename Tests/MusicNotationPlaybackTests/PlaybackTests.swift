import XCTest
@testable import MusicNotationPlayback
@testable import MusicNotationCore

final class PlaybackTests: XCTestCase {

    // MARK: - Dynamics Interpreter Tests

    func testDynamicVelocities() {
        let interpreter = DynamicsInterpreter()

        // Test standard dynamics
        let ppp = interpreter.velocityFor(dynamic: .ppp)
        let pp = interpreter.velocityFor(dynamic: .pp)
        let p = interpreter.velocityFor(dynamic: .p)
        let mp = interpreter.velocityFor(dynamic: .mp)
        let mf = interpreter.velocityFor(dynamic: .mf)
        let f = interpreter.velocityFor(dynamic: .f)
        let ff = interpreter.velocityFor(dynamic: .ff)
        let fff = interpreter.velocityFor(dynamic: .fff)

        // Dynamics should be in order
        XCTAssertLessThan(ppp, pp)
        XCTAssertLessThan(pp, p)
        XCTAssertLessThan(p, mp)
        XCTAssertLessThan(mp, mf)
        XCTAssertLessThan(mf, f)
        XCTAssertLessThan(f, ff)
        XCTAssertLessThan(ff, fff)
    }

    func testVelocityRange() {
        let interpreter = DynamicsInterpreter()

        // All velocities should be in valid MIDI range (1-127)
        for dynamic in [DynamicValue.ppp, .pp, .p, .mp, .mf, .f, .ff, .fff] {
            let velocity = interpreter.velocityFor(dynamic: dynamic)
            XCTAssertGreaterThanOrEqual(velocity, 1)
            XCTAssertLessThanOrEqual(velocity, 127)
        }
    }

    func testAccentedDynamics() {
        let interpreter = DynamicsInterpreter()

        let sf = interpreter.velocityFor(dynamic: .sf)
        let sfz = interpreter.velocityFor(dynamic: .sfz)
        let f = interpreter.velocityFor(dynamic: .f)

        // Accented dynamics should be louder than normal forte
        XCTAssertGreaterThanOrEqual(sf, f)
        XCTAssertGreaterThanOrEqual(sfz, f)
    }

    func testVelocityInterpolation() {
        let interpreter = DynamicsInterpreter()

        let start: UInt8 = 50
        let end: UInt8 = 100

        // At 0%, should be start
        let at0 = interpreter.interpolateVelocity(from: start, to: end, progress: 0.0)
        XCTAssertEqual(at0, start)

        // At 100%, should be end
        let at100 = interpreter.interpolateVelocity(from: start, to: end, progress: 1.0)
        XCTAssertEqual(at100, end)

        // At 50%, should be roughly in the middle
        let at50 = interpreter.interpolateVelocity(from: start, to: end, progress: 0.5)
        XCTAssertGreaterThan(at50, start)
        XCTAssertLessThan(at50, end)
    }

    func testArticulationVelocityAdjustment() {
        let interpreter = DynamicsInterpreter()
        let baseVelocity: UInt8 = 80

        // Accent should increase velocity
        let accentNotation = Notation.articulations([ArticulationMark(type: "accent")])
        let accentVelocity = interpreter.adjustVelocityForArticulations(baseVelocity, notations: [accentNotation])
        XCTAssertGreaterThan(accentVelocity, baseVelocity)

        // Staccato might slightly decrease velocity
        let staccatoNotation = Notation.articulations([ArticulationMark(type: "staccato")])
        let staccatoVelocity = interpreter.adjustVelocityForArticulations(baseVelocity, notations: [staccatoNotation])
        XCTAssertLessThanOrEqual(staccatoVelocity, baseVelocity)
    }

    // MARK: - Instrument Mapper Tests

    func testCommonInstrumentMapping() {
        let mapper = InstrumentMapper()

        // Test common instruments map to correct General MIDI programs
        let piano = Part(id: "P1", name: "Piano", measures: [])
        XCTAssertEqual(mapper.midiProgram(for: piano), GeneralMIDI.acousticGrandPiano.rawValue)

        let violin = Part(id: "P2", name: "Violin", measures: [])
        XCTAssertEqual(mapper.midiProgram(for: violin), GeneralMIDI.violin.rawValue)

        let flute = Part(id: "P3", name: "Flute", measures: [])
        XCTAssertEqual(mapper.midiProgram(for: flute), GeneralMIDI.flute.rawValue)

        let trumpet = Part(id: "P4", name: "Trumpet", measures: [])
        XCTAssertEqual(mapper.midiProgram(for: trumpet), GeneralMIDI.trumpet.rawValue)
    }

    func testInstrumentAbbreviations() {
        let mapper = InstrumentMapper()

        let vln = Part(id: "P1", name: "Vln.", abbreviation: "Vln.", measures: [])
        XCTAssertEqual(mapper.midiProgram(for: vln), GeneralMIDI.violin.rawValue)

        let vc = Part(id: "P2", name: "Vc.", abbreviation: "Vc.", measures: [])
        XCTAssertEqual(mapper.midiProgram(for: vc), GeneralMIDI.cello.rawValue)
    }

    func testPercussionChannel() {
        let mapper = InstrumentMapper()

        let drums = Part(id: "P1", name: "Drums", measures: [])
        let channel = mapper.midiChannel(for: drums, partIndex: 0)
        XCTAssertEqual(channel, 9) // Percussion is always channel 10 (index 9)
    }

    func testTransposingInstruments() {
        let mapper = InstrumentMapper()

        // Bb Clarinet sounds a major 2nd lower
        let clarinet = Part(id: "P1", name: "Bb Clarinet", measures: [])
        XCTAssertEqual(mapper.transposition(for: clarinet), -2)

        // French Horn in F sounds a perfect 5th lower
        let horn = Part(id: "P2", name: "French Horn", measures: [])
        XCTAssertEqual(mapper.transposition(for: horn), -7)

        // Piccolo sounds an octave higher
        let piccolo = Part(id: "P3", name: "Piccolo", measures: [])
        XCTAssertEqual(mapper.transposition(for: piccolo), 12)
    }

    // MARK: - Score Sequencer Tests

    func testSequencerCreation() {
        let score = createSimpleScore()
        let sequencer = ScoreSequencer(score: score)

        XCTAssertNotNil(sequencer)
        XCTAssertEqual(sequencer.tempo, 120.0) // Default tempo
    }

    func testBuildSequence() throws {
        let score = createSimpleScore()
        let sequencer = ScoreSequencer(score: score)

        try sequencer.buildSequence()
        XCTAssertFalse(sequencer.isComplete)
    }

    func testTempoChange() {
        let sequencer = ScoreSequencer(score: createSimpleScore())
        sequencer.tempo = 60.0
        XCTAssertEqual(sequencer.tempo, 60.0)

        sequencer.tempo = 180.0
        XCTAssertEqual(sequencer.tempo, 180.0)
    }

    func testTimeCalculation() throws {
        let score = createSimpleScore()
        let sequencer = ScoreSequencer(score: score)
        sequencer.tempo = 120.0 // 2 beats per second

        try sequencer.buildSequence()

        // Measure 1, beat 1 should be at time 0
        let time1 = sequencer.timeForPosition(measure: 1, beat: 1.0)
        XCTAssertEqual(time1, 0.0, accuracy: 0.001)

        // Measure 1, beat 2 at 120 bpm should be at 0.5 seconds
        let time2 = sequencer.timeForPosition(measure: 1, beat: 2.0)
        XCTAssertEqual(time2, 0.5, accuracy: 0.001)
    }

    func testSequencerReset() throws {
        let score = createSimpleScore()
        let sequencer = ScoreSequencer(score: score)

        try sequencer.buildSequence()
        sequencer.seek(to: 5.0)
        sequencer.reset()

        // After reset, should be at beginning
        XCTAssertFalse(sequencer.isComplete)
    }

    // MARK: - Playback Cursor Tests

    func testCursorInitialPosition() {
        let score = createSimpleScore()
        let cursor = PlaybackCursor(score: score)

        XCTAssertEqual(cursor.currentPosition.measure, 1)
        XCTAssertEqual(cursor.currentPosition.beat, 1.0)
    }

    func testCursorSeek() {
        let score = createSimpleScore()
        let cursor = PlaybackCursor(score: score)

        cursor.seek(to: 2, beat: 3.0)
        XCTAssertEqual(cursor.currentPosition.measure, 2)
        XCTAssertEqual(cursor.currentPosition.beat, 3.0, accuracy: 0.001)
    }

    func testCursorReset() {
        let score = createSimpleScore()
        let cursor = PlaybackCursor(score: score)

        cursor.seek(to: 2, beat: 3.0)
        cursor.reset()

        XCTAssertEqual(cursor.currentPosition.measure, 1)
        XCTAssertEqual(cursor.currentPosition.beat, 1.0, accuracy: 0.001)
    }

    func testTotalDuration() {
        let score = createSimpleScore()
        let cursor = PlaybackCursor(score: score)
        cursor.tempo = 120.0

        let duration = cursor.totalDuration()
        // 2 measures of 4/4 at 120 bpm = 4 seconds
        XCTAssertEqual(duration, 4.0, accuracy: 0.1)
    }

    func testPositionAtTime() {
        let score = createSimpleScore()
        let cursor = PlaybackCursor(score: score)
        cursor.tempo = 120.0

        // At time 0, should be measure 1, beat 1
        let pos0 = cursor.positionAt(time: 0.0)
        XCTAssertEqual(pos0.measure, 1)
        XCTAssertEqual(pos0.beat, 1.0, accuracy: 0.1)

        // At time 2 seconds (120 bpm, 4 beats), should be measure 2
        let pos2 = cursor.positionAt(time: 2.0)
        XCTAssertEqual(pos2.measure, 2)
    }

    // MARK: - Playback Position Tests

    func testPlaybackPositionEquality() {
        let pos1 = PlaybackPosition(measure: 1, beat: 1.0, timeInSeconds: 0.0)
        let pos2 = PlaybackPosition(measure: 1, beat: 1.0, timeInSeconds: 0.0)
        let pos3 = PlaybackPosition(measure: 2, beat: 1.0, timeInSeconds: 2.0)

        XCTAssertEqual(pos1, pos2)
        XCTAssertNotEqual(pos1, pos3)
    }

    func testPlaybackPositionZero() {
        let zero = PlaybackPosition.zero
        XCTAssertEqual(zero.measure, 1)
        XCTAssertEqual(zero.beat, 1.0)
        XCTAssertEqual(zero.timeInSeconds, 0.0)
    }

    // MARK: - General MIDI Tests

    func testGeneralMIDIProgramNumbers() {
        // Verify some common General MIDI program numbers
        XCTAssertEqual(GeneralMIDI.acousticGrandPiano.rawValue, 0)
        XCTAssertEqual(GeneralMIDI.violin.rawValue, 40)
        XCTAssertEqual(GeneralMIDI.trumpet.rawValue, 56)
        XCTAssertEqual(GeneralMIDI.flute.rawValue, 73)
        XCTAssertEqual(GeneralMIDI.acousticBass.rawValue, 32)
    }

    func testGeneralMIDIPercussion() {
        // Verify some General MIDI percussion note numbers
        XCTAssertEqual(GeneralMIDIPercussion.bassDrum1.rawValue, 36)
        XCTAssertEqual(GeneralMIDIPercussion.acousticSnare.rawValue, 38)
        XCTAssertEqual(GeneralMIDIPercussion.closedHiHat.rawValue, 42)
        XCTAssertEqual(GeneralMIDIPercussion.crashCymbal1.rawValue, 49)
    }

    // MARK: - Wedge Interpreter Tests

    func testWedgeInterpreterCrescendo() {
        let interpreter = WedgeInterpreter()
        let crescendo = interpreter.createCrescendo(
            startTime: 0.0,
            endTime: 2.0,
            startDynamic: .p
        )

        XCTAssertTrue(crescendo.isCrescendo)
        XCTAssertEqual(crescendo.startTime, 0.0)
        XCTAssertEqual(crescendo.endTime, 2.0)
        XCTAssertLessThan(crescendo.startVelocity, crescendo.endVelocity)
    }

    func testWedgeInterpreterDiminuendo() {
        let interpreter = WedgeInterpreter()
        let diminuendo = interpreter.createDiminuendo(
            startTime: 0.0,
            endTime: 2.0,
            startDynamic: .f
        )

        XCTAssertFalse(diminuendo.isCrescendo)
        XCTAssertGreaterThan(diminuendo.startVelocity, diminuendo.endVelocity)
    }

    func testActiveWedgeVelocity() {
        let interpreter = WedgeInterpreter()
        let dynamicsInterpreter = DynamicsInterpreter()

        let wedge = interpreter.createCrescendo(
            startTime: 0.0,
            endTime: 4.0,
            startDynamic: .p,
            endDynamic: .f
        )

        // At start
        let vel0 = wedge.velocityAt(time: 0.0, interpreter: dynamicsInterpreter)
        XCTAssertEqual(vel0, wedge.startVelocity)

        // At end
        let velEnd = wedge.velocityAt(time: 4.0, interpreter: dynamicsInterpreter)
        XCTAssertEqual(velEnd, wedge.endVelocity)

        // At middle
        let velMid = wedge.velocityAt(time: 2.0, interpreter: dynamicsInterpreter)
        XCTAssertNotNil(velMid)
        if let mid = velMid {
            XCTAssertGreaterThan(mid, wedge.startVelocity)
            XCTAssertLessThan(mid, wedge.endVelocity)
        }

        // Outside range
        XCTAssertNil(wedge.velocityAt(time: -1.0, interpreter: dynamicsInterpreter))
        XCTAssertNil(wedge.velocityAt(time: 5.0, interpreter: dynamicsInterpreter))
    }

    // MARK: - Helper Methods

    private func createSimpleScore() -> Score {
        let note1 = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1
        )

        let note2 = Note(
            noteType: .pitched(Pitch(step: .d, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1
        )

        let note3 = Note(
            noteType: .pitched(Pitch(step: .e, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1
        )

        let note4 = Note(
            noteType: .pitched(Pitch(step: .f, octave: 4)),
            durationDivisions: 1,
            type: .quarter,
            voice: 1,
            staff: 1
        )

        let measure1 = Measure(
            number: "1",
            elements: [.note(note1), .note(note2), .note(note3), .note(note4)],
            attributes: MeasureAttributes(
                divisions: 1,
                timeSignatures: [TimeSignature(beats: "4", beatType: "4")]
            )
        )

        let measure2 = Measure(
            number: "2",
            elements: [.note(note1), .note(note2), .note(note3), .note(note4)]
        )

        let part = Part(
            id: "P1",
            name: "Piano",
            measures: [measure1, measure2]
        )

        return Score(parts: [part])
    }
}
