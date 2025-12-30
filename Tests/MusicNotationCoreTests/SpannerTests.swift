import XCTest
@testable import MusicNotationCore

final class SpannerTests: XCTestCase {

    // MARK: - Tuplet Tests

    func testTupletInitialization() {
        let tuplet = Tuplet(actualNotes: 3, normalNotes: 2)

        XCTAssertEqual(tuplet.actualNotes, 3)
        XCTAssertEqual(tuplet.normalNotes, 2)
        XCTAssertEqual(tuplet.number, 1)
        XCTAssertTrue(tuplet.noteIds.isEmpty)
    }

    func testTupletRatioString() {
        let triplet = Tuplet(actualNotes: 3, normalNotes: 2)
        XCTAssertEqual(triplet.ratioString, "3:2")

        let quintuplet = Tuplet(actualNotes: 5, normalNotes: 4)
        XCTAssertEqual(quintuplet.ratioString, "5:4")
    }

    func testTupletDurationMultiplier() {
        let triplet = Tuplet(actualNotes: 3, normalNotes: 2)
        XCTAssertEqual(triplet.durationMultiplier, 2.0 / 3.0, accuracy: 0.0001)

        let duplet = Tuplet(actualNotes: 2, normalNotes: 3)
        XCTAssertEqual(duplet.durationMultiplier, 3.0 / 2.0, accuracy: 0.0001)
    }

    func testTupletIsTriplet() {
        let triplet = Tuplet(actualNotes: 3, normalNotes: 2)
        XCTAssertTrue(triplet.isTriplet)
        XCTAssertFalse(triplet.isDuplet)

        let duplet = Tuplet(actualNotes: 2, normalNotes: 3)
        XCTAssertFalse(duplet.isTriplet)
        XCTAssertTrue(duplet.isDuplet)
    }

    func testTupletNoteCount() {
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()
        let tuplet = Tuplet(actualNotes: 3, normalNotes: 2, noteIds: [id1, id2, id3])

        XCTAssertEqual(tuplet.noteCount, 3)
    }

    func testTupletFactoryMethods() {
        let triplet = Tuplet.triplet()
        XCTAssertEqual(triplet.actualNotes, 3)
        XCTAssertEqual(triplet.normalNotes, 2)

        let duplet = Tuplet.duplet()
        XCTAssertEqual(duplet.actualNotes, 2)
        XCTAssertEqual(duplet.normalNotes, 3)

        let quintuplet = Tuplet.quintuplet()
        XCTAssertEqual(quintuplet.actualNotes, 5)
        XCTAssertEqual(quintuplet.normalNotes, 4)

        let sextuplet = Tuplet.sextuplet()
        XCTAssertEqual(sextuplet.actualNotes, 6)
        XCTAssertEqual(sextuplet.normalNotes, 4)

        let septuplet = Tuplet.septuplet()
        XCTAssertEqual(septuplet.actualNotes, 7)
        XCTAssertEqual(septuplet.normalNotes, 4)
    }

    func testTupletNumberGlyph() {
        let tuplet2 = Tuplet(actualNotes: 2, normalNotes: 3)
        XCTAssertEqual(tuplet2.numberGlyph, .tuplet2)

        let tuplet3 = Tuplet(actualNotes: 3, normalNotes: 2)
        XCTAssertEqual(tuplet3.numberGlyph, .tuplet3)

        let tuplet4 = Tuplet(actualNotes: 4, normalNotes: 3)
        XCTAssertEqual(tuplet4.numberGlyph, .tuplet4)

        let tuplet5 = Tuplet(actualNotes: 5, normalNotes: 4)
        XCTAssertEqual(tuplet5.numberGlyph, .tuplet5)

        let tuplet6 = Tuplet(actualNotes: 6, normalNotes: 4)
        XCTAssertEqual(tuplet6.numberGlyph, .tuplet6)

        let tuplet7 = Tuplet(actualNotes: 7, normalNotes: 4)
        XCTAssertEqual(tuplet7.numberGlyph, .tuplet7)

        let tuplet8 = Tuplet(actualNotes: 8, normalNotes: 6)
        XCTAssertEqual(tuplet8.numberGlyph, .tuplet8)

        let tuplet9 = Tuplet(actualNotes: 9, normalNotes: 8)
        XCTAssertEqual(tuplet9.numberGlyph, .tuplet9)

        let tuplet10 = Tuplet(actualNotes: 10, normalNotes: 8)
        XCTAssertNil(tuplet10.numberGlyph)
    }

    func testTupletColonGlyph() {
        let tuplet = Tuplet.triplet()
        XCTAssertEqual(tuplet.colonGlyph, .tupletColon)
    }

    // MARK: - TupletStart Tests

    func testTupletStartAddNote() {
        var start = TupletStart(number: 1, actualNotes: 3, normalNotes: 2)
        XCTAssertTrue(start.noteIds.isEmpty)

        let id1 = UUID()
        let id2 = UUID()
        start.addNote(id: id1)
        start.addNote(id: id2)

        XCTAssertEqual(start.noteIds.count, 2)
        XCTAssertEqual(start.noteIds[0], id1)
        XCTAssertEqual(start.noteIds[1], id2)
    }

    func testTupletStartToTuplet() {
        var start = TupletStart(
            number: 1,
            actualNotes: 3,
            normalNotes: 2,
            showNumber: .both,
            showType: .actual
        )
        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()
        start.addNote(id: id1)
        start.addNote(id: id2)
        start.addNote(id: id3)

        let tuplet = start.toTuplet()

        XCTAssertEqual(tuplet.actualNotes, 3)
        XCTAssertEqual(tuplet.normalNotes, 2)
        XCTAssertEqual(tuplet.noteIds.count, 3)
        XCTAssertEqual(tuplet.showNumber, .both)
        XCTAssertEqual(tuplet.showType, .actual)
    }

    // MARK: - NestedTuplet Tests

    func testNestedTupletTotalMultiplier() {
        let outer = Tuplet.triplet() // 2/3
        let inner = Tuplet.triplet() // 2/3

        let nested = NestedTuplet(outer: outer, inner: [inner])

        // (2/3) * (2/3) = 4/9
        XCTAssertEqual(nested.totalMultiplier, 4.0 / 9.0, accuracy: 0.0001)
    }

    func testNestedTupletNoInner() {
        let outer = Tuplet.triplet()
        let nested = NestedTuplet(outer: outer, inner: [])

        XCTAssertEqual(nested.totalMultiplier, 2.0 / 3.0, accuracy: 0.0001)
    }

    // MARK: - Beam Tests

    func testBeamInitialization() {
        let beam = Beam(level: 1)

        XCTAssertEqual(beam.level, 1)
        XCTAssertTrue(beam.noteIds.isEmpty)
        XCTAssertFalse(beam.hasForwardHook)
        XCTAssertFalse(beam.hasBackwardHook)
        XCTAssertNil(beam.fan)
    }

    func testBeamNoteCount() {
        let id1 = UUID()
        let id2 = UUID()
        let beam = Beam(level: 1, noteIds: [id1, id2])

        XCTAssertEqual(beam.noteCount, 2)
    }

    func testBeamIsValid() {
        let id1 = UUID()
        let id2 = UUID()

        let validBeam = Beam(level: 1, noteIds: [id1, id2])
        XCTAssertTrue(validBeam.isValid)

        let invalidBeam = Beam(level: 1, noteIds: [id1])
        XCTAssertFalse(invalidBeam.isValid)

        let emptyBeam = Beam(level: 1, noteIds: [])
        XCTAssertFalse(emptyBeam.isValid)
    }

    func testBeamTremoloGlyph() {
        let beam1 = Beam(level: 1)
        XCTAssertEqual(beam1.tremoloGlyph, .tremolo1)

        let beam2 = Beam(level: 2)
        XCTAssertEqual(beam2.tremoloGlyph, .tremolo2)

        let beam3 = Beam(level: 3)
        XCTAssertEqual(beam3.tremoloGlyph, .tremolo3)

        let beam4 = Beam(level: 4)
        XCTAssertEqual(beam4.tremoloGlyph, .tremolo4)

        let beam5 = Beam(level: 5)
        XCTAssertEqual(beam5.tremoloGlyph, .tremolo5)

        let beam6 = Beam(level: 6)
        XCTAssertNil(beam6.tremoloGlyph)
    }

    func testBeamFan() {
        let accelBeam = Beam(level: 1, fan: .accelerando)
        XCTAssertEqual(accelBeam.fan, .accelerando)

        let ritBeam = Beam(level: 1, fan: .ritardando)
        XCTAssertEqual(ritBeam.fan, .ritardando)
    }

    // MARK: - BeamGroup Tests

    func testBeamGroupInitialization() {
        let group = BeamGroup(voice: 1, staff: 1)

        XCTAssertEqual(group.voice, 1)
        XCTAssertEqual(group.staff, 1)
        XCTAssertTrue(group.noteIds.isEmpty)
        XCTAssertTrue(group.beamsByLevel.isEmpty)
    }

    func testBeamGroupMaxLevel() {
        let beam1 = Beam(level: 1)
        let beam2 = Beam(level: 2)

        let group = BeamGroup(beamsByLevel: [1: beam1, 2: beam2])

        XCTAssertEqual(group.maxLevel, 2)
    }

    func testBeamGroupMaxLevelEmpty() {
        let group = BeamGroup()
        XCTAssertEqual(group.maxLevel, 1)
    }

    func testBeamGroupPrimaryBeam() {
        let beam1 = Beam(level: 1)
        let beam2 = Beam(level: 2)

        let group = BeamGroup(beamsByLevel: [1: beam1, 2: beam2])

        XCTAssertNotNil(group.primaryBeam)
        XCTAssertEqual(group.primaryBeam?.level, 1)
    }

    func testBeamGroupLevels() {
        let beam1 = Beam(level: 1)
        let beam2 = Beam(level: 2)
        let beam3 = Beam(level: 3)

        let group = BeamGroup(beamsByLevel: [1: beam1, 3: beam3, 2: beam2])

        XCTAssertEqual(group.levels, [1, 2, 3])
    }

    func testBeamGroupFastestNoteValue() {
        let beam1 = Beam(level: 1)
        let group1 = BeamGroup(beamsByLevel: [1: beam1])
        XCTAssertEqual(group1.fastestNoteValue, .eighth)

        let beam2 = Beam(level: 2)
        let group2 = BeamGroup(beamsByLevel: [1: beam1, 2: beam2])
        XCTAssertEqual(group2.fastestNoteValue, .sixteenth)

        let beam3 = Beam(level: 3)
        let group3 = BeamGroup(beamsByLevel: [1: beam1, 2: beam2, 3: beam3])
        XCTAssertEqual(group3.fastestNoteValue, .thirtySecond)
    }

    func testBeamGroupBeamCount() {
        XCTAssertEqual(BeamGroup.beamCount(for: .eighth), 1)
        XCTAssertEqual(BeamGroup.beamCount(for: .sixteenth), 2)
        XCTAssertEqual(BeamGroup.beamCount(for: .thirtySecond), 3)
        XCTAssertEqual(BeamGroup.beamCount(for: .sixtyFourth), 4)
        XCTAssertEqual(BeamGroup.beamCount(for: .oneHundredTwentyEighth), 5)
        XCTAssertEqual(BeamGroup.beamCount(for: .twoHundredFiftySixth), 6)
        XCTAssertEqual(BeamGroup.beamCount(for: .quarter), 0)
        XCTAssertEqual(BeamGroup.beamCount(for: .half), 0)
        XCTAssertEqual(BeamGroup.beamCount(for: .whole), 0)
    }

    // MARK: - Tie Tests

    func testTieConnectionInitialization() {
        let startId = UUID()
        let endId = UUID()
        let pitch = Pitch(step: .c, octave: 4)

        let tie = TieConnection(startNoteId: startId, endNoteId: endId, pitch: pitch)

        XCTAssertEqual(tie.startNoteId, startId)
        XCTAssertEqual(tie.endNoteId, endId)
        XCTAssertEqual(tie.pitch.step, .c)
        XCTAssertEqual(tie.pitch.octave, 4)
    }

    func testTieChainInitialization() {
        let pitch = Pitch(step: .d, octave: 5)
        let chain = TieChain(pitch: pitch)

        XCTAssertEqual(chain.pitch.step, .d)
        XCTAssertEqual(chain.pitch.octave, 5)
        XCTAssertTrue(chain.noteIds.isEmpty)
        XCTAssertTrue(chain.ties.isEmpty)
    }

    func testTieChainAddNote() {
        let pitch = Pitch(step: .e, octave: 4)
        var chain = TieChain(pitch: pitch)

        let id1 = UUID()
        let id2 = UUID()
        let id3 = UUID()

        chain.addNote(id: id1)
        XCTAssertEqual(chain.noteCount, 1)
        XCTAssertEqual(chain.tieCount, 0)

        chain.addNote(id: id2)
        XCTAssertEqual(chain.noteCount, 2)
        XCTAssertEqual(chain.tieCount, 1)

        chain.addNote(id: id3)
        XCTAssertEqual(chain.noteCount, 3)
        XCTAssertEqual(chain.tieCount, 2)

        XCTAssertEqual(chain.firstNoteId, id1)
        XCTAssertEqual(chain.lastNoteId, id3)
    }

    func testTieTrackingKey() {
        let pitch = Pitch(step: .f, octave: 4)
        let key = TieTrackingKey(pitch: pitch, voice: 1, staff: 1)

        XCTAssertEqual(key.pitch.step, .f)
        XCTAssertEqual(key.voice, 1)
        XCTAssertEqual(key.staff, 1)
    }

    func testPendingTieTrackingKey() {
        let noteId = UUID()
        let pitch = Pitch(step: .g, octave: 3)
        let pending = PendingTie(
            noteId: noteId,
            measureIndex: 0,
            noteIndex: 1,
            pitch: pitch,
            voice: 2,
            staff: 1
        )

        let key = pending.trackingKey
        XCTAssertEqual(key.pitch.step, .g)
        XCTAssertEqual(key.voice, 2)
        XCTAssertEqual(key.staff, 1)
    }

    func testCompletedTieToTieConnection() {
        let startId = UUID()
        let endId = UUID()
        let pitch = Pitch(step: .a, octave: 4)

        let completed = CompletedTie(
            startNoteId: startId,
            endNoteId: endId,
            startMeasureIndex: 0,
            startNoteIndex: 2,
            endMeasureIndex: 1,
            endNoteIndex: 0,
            pitch: pitch
        )

        XCTAssertTrue(completed.crossesMeasure)

        let connection = completed.toTieConnection()
        XCTAssertEqual(connection.startNoteId, startId)
        XCTAssertEqual(connection.endNoteId, endId)
        XCTAssertEqual(connection.pitch.step, .a)
    }

    func testCompletedTieSameMeasure() {
        let startId = UUID()
        let endId = UUID()
        let pitch = Pitch(step: .b, octave: 4)

        let completed = CompletedTie(
            startNoteId: startId,
            endNoteId: endId,
            startMeasureIndex: 0,
            startNoteIndex: 0,
            endMeasureIndex: 0,
            endNoteIndex: 1,
            pitch: pitch
        )

        XCTAssertFalse(completed.crossesMeasure)
    }

    func testLetRing() {
        let noteId = UUID()
        let pitch = Pitch(step: .c, octave: 5)
        let letRing = LetRing(noteId: noteId, pitch: pitch)

        XCTAssertEqual(letRing.noteId, noteId)
        XCTAssertEqual(letRing.pitch.step, .c)
        XCTAssertEqual(letRing.pitch.octave, 5)
    }

    // MARK: - Slur Tests

    func testSlurInitialization() {
        let slur = Slur(number: 1)

        XCTAssertEqual(slur.number, 1)
        XCTAssertNil(slur.startNoteId)
        XCTAssertNil(slur.endNoteId)
        XCTAssertEqual(slur.lineType, .solid)
    }

    func testSlurIsComplete() {
        let startId = UUID()
        let endId = UUID()

        let incompleteSlur1 = Slur(number: 1, startNoteId: startId)
        XCTAssertFalse(incompleteSlur1.isComplete)

        let incompleteSlur2 = Slur(number: 1, endNoteId: endId)
        XCTAssertFalse(incompleteSlur2.isComplete)

        let completeSlur = Slur(number: 1, startNoteId: startId, endNoteId: endId)
        XCTAssertTrue(completeSlur.isComplete)
    }

    func testSlurLineTypes() {
        let solidSlur = Slur(number: 1, lineType: .solid)
        XCTAssertEqual(solidSlur.lineType, .solid)

        let dashedSlur = Slur(number: 1, lineType: .dashed)
        XCTAssertEqual(dashedSlur.lineType, .dashed)

        let dottedSlur = Slur(number: 1, lineType: .dotted)
        XCTAssertEqual(dottedSlur.lineType, .dotted)

        let wavySlur = Slur(number: 1, lineType: .wavy)
        XCTAssertEqual(wavySlur.lineType, .wavy)
    }

    func testBezierPoints() {
        let points = BezierPoints(
            bezierX: 10.0,
            bezierY: 20.0,
            bezierX2: 30.0,
            bezierY2: 40.0
        )

        XCTAssertEqual(points.bezierX, 10.0)
        XCTAssertEqual(points.bezierY, 20.0)
        XCTAssertEqual(points.bezierX2, 30.0)
        XCTAssertEqual(points.bezierY2, 40.0)
    }

    func testSlurStart() {
        let noteId = UUID()
        let start = SlurStart(noteId: noteId, measureIndex: 0, noteIndex: 1, placement: .above)

        XCTAssertEqual(start.noteId, noteId)
        XCTAssertEqual(start.measureIndex, 0)
        XCTAssertEqual(start.noteIndex, 1)
        XCTAssertEqual(start.placement, .above)
    }

    func testSlurPairToSlur() {
        let startId = UUID()
        let endId = UUID()

        let pair = SlurPair(
            slurNumber: 1,
            startNoteId: startId,
            endNoteId: endId,
            startMeasureIndex: 0,
            startNoteIndex: 0,
            endMeasureIndex: 1,
            endNoteIndex: 2,
            placement: .below
        )

        let slur = pair.toSlur()

        XCTAssertEqual(slur.number, 1)
        XCTAssertEqual(slur.startNoteId, startId)
        XCTAssertEqual(slur.endNoteId, endId)
        XCTAssertEqual(slur.placement, .below)
    }

    func testCurveOrientation() {
        XCTAssertEqual(CurveOrientation.over.rawValue, "over")
        XCTAssertEqual(CurveOrientation.under.rawValue, "under")
    }

    // MARK: - TupletDisplay Tests

    func testTupletDisplay() {
        XCTAssertEqual(TupletDisplay.actual.rawValue, "actual")
        XCTAssertEqual(TupletDisplay.both.rawValue, "both")
        XCTAssertEqual(TupletDisplay.none.rawValue, "none")
    }
}
