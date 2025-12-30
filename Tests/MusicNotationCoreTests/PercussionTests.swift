import XCTest
@testable import MusicNotationCore
@testable import SMuFLKit

final class PercussionTests: XCTestCase {

    // MARK: - Percussion Instrument Tests

    func testPercussionInstrumentMIDINotes() {
        // Drum kit
        XCTAssertEqual(PercussionInstrument.bassDrum.midiNote, 36)
        XCTAssertEqual(PercussionInstrument.acousticSnare.midiNote, 38)
        XCTAssertEqual(PercussionInstrument.snareDrum.midiNote, 38)
        XCTAssertEqual(PercussionInstrument.sideStick.midiNote, 37)

        // Hi-hat
        XCTAssertEqual(PercussionInstrument.hiHatClosed.midiNote, 42)
        XCTAssertEqual(PercussionInstrument.hiHatOpen.midiNote, 46)
        XCTAssertEqual(PercussionInstrument.hiHatPedal.midiNote, 44)

        // Cymbals
        XCTAssertEqual(PercussionInstrument.rideCymbal.midiNote, 51)
        XCTAssertEqual(PercussionInstrument.crashCymbal.midiNote, 49)
        XCTAssertEqual(PercussionInstrument.rideBell.midiNote, 53)

        // Toms
        XCTAssertEqual(PercussionInstrument.floorTom.midiNote, 43)
        XCTAssertEqual(PercussionInstrument.lowTom.midiNote, 45)
        XCTAssertEqual(PercussionInstrument.highTom.midiNote, 50)

        // Latin
        XCTAssertEqual(PercussionInstrument.cowbell.midiNote, 56)
        XCTAssertEqual(PercussionInstrument.tambourine.midiNote, 54)
        XCTAssertEqual(PercussionInstrument.claves.midiNote, 75)
    }

    func testPercussionInstrumentDefaultNoteheads() {
        // Cymbals use X noteheads
        XCTAssertEqual(PercussionInstrument.hiHatClosed.defaultNotehead, .x)
        XCTAssertEqual(PercussionInstrument.rideCymbal.defaultNotehead, .x)
        XCTAssertEqual(PercussionInstrument.crashCymbal.defaultNotehead, .x)

        // Open hi-hat uses circle-X
        XCTAssertEqual(PercussionInstrument.hiHatOpen.defaultNotehead, .circleX)

        // Drums use normal noteheads
        XCTAssertEqual(PercussionInstrument.bassDrum.defaultNotehead, .normal)
        XCTAssertEqual(PercussionInstrument.snareDrum.defaultNotehead, .normal)

        // Side stick uses plus
        XCTAssertEqual(PercussionInstrument.sideStick.defaultNotehead, .plus)

        // Cowbell uses diamond
        XCTAssertEqual(PercussionInstrument.cowbell.defaultNotehead, .diamond)

        // Triangle uses triangle
        XCTAssertEqual(PercussionInstrument.triangle.defaultNotehead, .triangle)
    }

    func testPercussionInstrumentDefaultStaffPosition() {
        // Bass drum below staff
        XCTAssertEqual(PercussionInstrument.bassDrum.defaultStaffPosition, -4)

        // Snare in middle
        XCTAssertEqual(PercussionInstrument.snareDrum.defaultStaffPosition, 0)

        // Hi-hat at top
        XCTAssertEqual(PercussionInstrument.hiHatClosed.defaultStaffPosition, 4)
    }

    func testPercussionInstrumentDisplayNames() {
        XCTAssertEqual(PercussionInstrument.bassDrum.displayName, "Bass Drum")
        XCTAssertEqual(PercussionInstrument.acousticSnare.displayName, "Acoustic Snare")
        XCTAssertEqual(PercussionInstrument.hiHatClosed.displayName, "Closed Hi-Hat")
    }

    // MARK: - Percussion Notehead Tests

    func testPercussionNoteheadGlyphs() {
        // Quarter note durations
        XCTAssertEqual(PercussionNotehead.normal.glyph(for: .quarter), .noteheadBlack)
        XCTAssertEqual(PercussionNotehead.x.glyph(for: .quarter), .noteheadXBlack)
        XCTAssertEqual(PercussionNotehead.circleX.glyph(for: .quarter), .noteheadCircleX)
        XCTAssertEqual(PercussionNotehead.diamond.glyph(for: .quarter), .noteheadDiamondBlack)
        XCTAssertEqual(PercussionNotehead.plus.glyph(for: .quarter), .noteheadPlusBlack)

        // Half note durations
        XCTAssertEqual(PercussionNotehead.normal.glyph(for: .half), .noteheadHalf)
        XCTAssertEqual(PercussionNotehead.x.glyph(for: .half), .noteheadXHalf)
        XCTAssertEqual(PercussionNotehead.diamond.glyph(for: .half), .noteheadDiamondHalf)

        // Whole note durations
        XCTAssertEqual(PercussionNotehead.normal.glyph(for: .whole), .noteheadWhole)
        XCTAssertEqual(PercussionNotehead.x.glyph(for: .whole), .noteheadXWhole)
    }

    func testPercussionNoteheadTriangleGlyphs() {
        XCTAssertEqual(PercussionNotehead.triangle.glyph(for: .quarter), .noteheadTriangleUpBlack)
        XCTAssertEqual(PercussionNotehead.triangle.glyph(for: .half), .noteheadTriangleUpHalf)
        XCTAssertEqual(PercussionNotehead.triangle.glyph(for: .whole), .noteheadTriangleUpWhole)

        XCTAssertEqual(PercussionNotehead.triangleDown.glyph(for: .quarter), .noteheadTriangleDownBlack)
        XCTAssertEqual(PercussionNotehead.triangleDown.glyph(for: .half), .noteheadTriangleDownHalf)
    }

    func testPercussionNoteheadSlashGlyphs() {
        XCTAssertEqual(PercussionNotehead.slash.glyph(for: .quarter), .noteheadSlashVerticalEnds)
        XCTAssertEqual(PercussionNotehead.slash.glyph(for: .half), .noteheadSlashWhiteHalf)
        XCTAssertEqual(PercussionNotehead.slash.glyph(for: .whole), .noteheadSlashWhiteWhole)
    }

    func testPercussionNoteheadMusicXMLConversion() {
        XCTAssertEqual(PercussionNotehead(musicXMLValue: "normal"), .normal)
        XCTAssertEqual(PercussionNotehead(musicXMLValue: "x"), .x)
        XCTAssertEqual(PercussionNotehead(musicXMLValue: "circle-x"), .circleX)
        XCTAssertEqual(PercussionNotehead(musicXMLValue: "diamond"), .diamond)
        XCTAssertEqual(PercussionNotehead(musicXMLValue: "triangle"), .triangle)
        XCTAssertEqual(PercussionNotehead(musicXMLValue: "slash"), .slash)
        XCTAssertEqual(PercussionNotehead(musicXMLValue: "cross"), .plus)
        XCTAssertNil(PercussionNotehead(musicXMLValue: "invalid"))

        XCTAssertEqual(PercussionNotehead.normal.musicXMLValue, "normal")
        XCTAssertEqual(PercussionNotehead.x.musicXMLValue, "x")
        XCTAssertEqual(PercussionNotehead.circleX.musicXMLValue, "circle-x")
    }

    func testPercussionNoteheadParenthesesGlyphs() {
        XCTAssertEqual(PercussionNotehead.ghost.leftParenthesisGlyph, .noteheadParenthesisLeft)
        XCTAssertEqual(PercussionNotehead.ghost.rightParenthesisGlyph, .noteheadParenthesisRight)
    }

    // MARK: - Percussion Map Tests

    func testStandardDrumKitMap() {
        let map = PercussionMap.standardDrumKit

        // Check bass drum at F4
        let bassEntry = map.entry(at: .f, octave: 4)
        XCTAssertNotNil(bassEntry)
        XCTAssertEqual(bassEntry?.instrument, .bassDrum)
        XCTAssertEqual(bassEntry?.notehead, .normal)
        XCTAssertEqual(bassEntry?.midiNote, 36)

        // Check snare at C5
        let snareEntry = map.entry(at: .c, octave: 5)
        XCTAssertNotNil(snareEntry)
        XCTAssertEqual(snareEntry?.instrument, .snareDrum)
        XCTAssertEqual(snareEntry?.midiNote, 38)

        // Check hi-hat at G5
        let hihatEntry = map.entry(at: .g, octave: 5)
        XCTAssertNotNil(hihatEntry)
        XCTAssertEqual(hihatEntry?.instrument, .hiHatClosed)
        XCTAssertEqual(hihatEntry?.notehead, .x)
        XCTAssertEqual(hihatEntry?.midiNote, 42)
    }

    func testPercussionMapLookups() {
        let map = PercussionMap.standardDrumKit

        // Test instrument lookup
        XCTAssertEqual(map.instrument(at: .f, octave: 4), .bassDrum)
        XCTAssertEqual(map.instrument(at: .c, octave: 5), .snareDrum)
        XCTAssertNil(map.instrument(at: .a, octave: 3))  // Not in map

        // Test notehead lookup
        XCTAssertEqual(map.notehead(at: .g, octave: 5), .x)  // Hi-hat
        XCTAssertEqual(map.notehead(at: .c, octave: 5), .normal)  // Snare

        // Test MIDI note lookup
        XCTAssertEqual(map.midiNote(at: .f, octave: 4), 36)  // Bass drum
        XCTAssertEqual(map.midiNote(at: .a, octave: 5), 49)  // Crash
    }

    func testPercussionMapFindByInstrument() {
        let map = PercussionMap.standardDrumKit

        let snareEntry = map.entry(for: .snareDrum)
        XCTAssertNotNil(snareEntry)
        XCTAssertEqual(snareEntry?.displayStep, .c)
        XCTAssertEqual(snareEntry?.displayOctave, 5)

        let hihatEntry = map.entry(for: .hiHatClosed)
        XCTAssertNotNil(hihatEntry)
        XCTAssertEqual(hihatEntry?.displayStep, .g)
    }

    func testPercussionMapFindByMIDINote() {
        let map = PercussionMap.standardDrumKit

        let snareEntry = map.entry(forMidiNote: 38)
        XCTAssertNotNil(snareEntry)
        XCTAssertEqual(snareEntry?.instrument, .snareDrum)

        let rideEntry = map.entry(forMidiNote: 51)
        XCTAssertNotNil(rideEntry)
        XCTAssertEqual(rideEntry?.instrument, .rideCymbal)
    }

    func testExtendedDrumKitMap() {
        let map = PercussionMap.extendedDrumKit

        // Should have standard entries
        XCTAssertNotNil(map.entry(at: .f, octave: 4))  // Bass drum

        // Should have extended entries
        XCTAssertNotNil(map.entry(for: .cowbell))
        XCTAssertNotNil(map.entry(for: .tambourine))
    }

    func testLatinPercussionMap() {
        let map = PercussionMap.latinPercussion

        XCTAssertNotNil(map.entry(for: .highBongo))
        XCTAssertNotNil(map.entry(for: .lowBongo))
        XCTAssertNotNil(map.entry(for: .openHighConga))
        XCTAssertNotNil(map.entry(for: .highTimbale))
    }

    // MARK: - Unpitched Note Tests

    func testUnpitchedNoteCreation() {
        let note = UnpitchedNote(displayStep: .c, displayOctave: 5)
        XCTAssertEqual(note.displayStep, .c)
        XCTAssertEqual(note.displayOctave, 5)
        XCTAssertNil(note.instrumentId)
        XCTAssertNil(note.percussionInstrument)
        XCTAssertNil(note.noteheadOverride)
    }

    func testUnpitchedNoteFullCreation() {
        let note = UnpitchedNote(
            displayStep: .g,
            displayOctave: 5,
            instrumentId: "P1-I2",
            percussionInstrument: .hiHatClosed,
            noteheadOverride: .x
        )

        XCTAssertEqual(note.displayStep, .g)
        XCTAssertEqual(note.displayOctave, 5)
        XCTAssertEqual(note.instrumentId, "P1-I2")
        XCTAssertEqual(note.percussionInstrument, .hiHatClosed)
        XCTAssertEqual(note.noteheadOverride, .x)
    }

    func testUnpitchedNoteEffectiveNotehead() {
        // Override takes precedence
        var note = UnpitchedNote(displayStep: .c, displayOctave: 5)
        note.noteheadOverride = .diamond
        XCTAssertEqual(note.effectiveNotehead, .diamond)

        // Instrument default is used when no override
        note.noteheadOverride = nil
        note.percussionInstrument = .hiHatClosed
        XCTAssertEqual(note.effectiveNotehead, .x)

        // Falls back to normal
        note.percussionInstrument = nil
        XCTAssertEqual(note.effectiveNotehead, .normal)
    }

    // MARK: - Percussion Types Tests

    func testBeaterTypes() {
        XCTAssertEqual(BeaterType.drumStick.musicXMLValue, "drum-stick")
        XCTAssertEqual(BeaterType(musicXMLValue: "wire-brush"), .wireBrush)
        XCTAssertEqual(BeaterType(musicXMLValue: "triangle-beater"), .triangleBeater)
    }

    func testStickTypes() {
        XCTAssertEqual(StickType.bassDrum.musicXMLValue, "bass-drum")
        XCTAssertEqual(StickType(musicXMLValue: "timpani"), .timpani)
    }

    func testMembraneTypes() {
        XCTAssertEqual(MembraneType.snareDrum.musicXMLValue, "snare-drum")
        XCTAssertEqual(MembraneType(musicXMLValue: "bass-drum"), .bassDrum)
    }

    func testMetalTypes() {
        XCTAssertEqual(MetalType.cowbell.musicXMLValue, "cowbell")
        XCTAssertEqual(MetalType.hiHat.musicXMLValue, "hi-hat")
        XCTAssertEqual(MetalType(musicXMLValue: "suspended-cymbal"), .suspendedCymbal)
    }

    func testWoodTypes() {
        XCTAssertEqual(WoodType.woodBlock.musicXMLValue, "wood-block")
        XCTAssertEqual(WoodType(musicXMLValue: "claves"), .claves)
    }

    // MARK: - Part Percussion Tests

    func testPartIsPercussion() {
        // Part with percussion map
        let percPart = Part(
            id: "P1",
            name: "Drums",
            percussionMap: .standardDrumKit
        )
        XCTAssertTrue(percPart.isPercussion)

        // Part without percussion map or clef
        let normalPart = Part(id: "P2", name: "Piano")
        XCTAssertFalse(normalPart.isPercussion)
    }

    func testPartEffectivePercussionMap() {
        // Part with explicit map
        let customMap = PercussionMap(entries: [])
        let part1 = Part(id: "P1", name: "Drums", percussionMap: customMap)
        XCTAssertNotNil(part1.effectivePercussionMap)
        XCTAssertEqual(part1.effectivePercussionMap?.entries.count, 0)

        // Part that needs default map
        let part2 = Part(id: "P2", name: "Drums", percussionMap: .standardDrumKit)
        XCTAssertNotNil(part2.effectivePercussionMap)
        XCTAssertGreaterThan(part2.effectivePercussionMap?.entries.count ?? 0, 0)

        // Non-percussion part
        let part3 = Part(id: "P3", name: "Piano")
        XCTAssertNil(part3.effectivePercussionMap)
    }

    // MARK: - Percussion Direction Tests

    func testPercussionDirectionType() {
        let timpaniDir = PercussionDirection(type: .timpani(TimpaniTuning(step: .c, alter: nil, octave: 3)))
        if case .timpani(let tuning) = timpaniDir.type {
            XCTAssertEqual(tuning?.step, .c)
            XCTAssertEqual(tuning?.octave, 3)
        } else {
            XCTFail("Expected timpani type")
        }

        let membraneDir = PercussionDirection(type: .membrane(.snareDrum))
        if case .membrane(let type) = membraneDir.type {
            XCTAssertEqual(type, .snareDrum)
        } else {
            XCTFail("Expected membrane type")
        }

        let beaterDir = PercussionDirection(type: .beater(.wireBrush))
        if case .beater(let type) = beaterDir.type {
            XCTAssertEqual(type, .wireBrush)
        } else {
            XCTFail("Expected beater type")
        }
    }

    func testPercussionDirectionSimpleCreation() {
        let dir = PercussionDirection(value: "custom percussion")
        if case .other(let text) = dir.type {
            XCTAssertEqual(text, "custom percussion")
        } else {
            XCTFail("Expected other type")
        }
    }

    // MARK: - Codable Tests

    func testPercussionInstrumentCodable() throws {
        for instrument in PercussionInstrument.allCases {
            let encoder = JSONEncoder()
            let data = try encoder.encode(instrument)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(PercussionInstrument.self, from: data)
            XCTAssertEqual(instrument, decoded)
        }
    }

    func testPercussionNoteheadCodable() throws {
        for notehead in PercussionNotehead.allCases {
            let encoder = JSONEncoder()
            let data = try encoder.encode(notehead)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(PercussionNotehead.self, from: data)
            XCTAssertEqual(notehead, decoded)
        }
    }

    func testPercussionMapCodable() throws {
        let map = PercussionMap.standardDrumKit
        let encoder = JSONEncoder()
        let data = try encoder.encode(map)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(PercussionMap.self, from: data)

        XCTAssertEqual(map.entries.count, decoded.entries.count)

        // Verify an entry
        let originalSnare = map.entry(for: .snareDrum)
        let decodedSnare = decoded.entry(for: .snareDrum)
        XCTAssertEqual(originalSnare?.displayStep, decodedSnare?.displayStep)
        XCTAssertEqual(originalSnare?.midiNote, decodedSnare?.midiNote)
    }

    func testUnpitchedNoteCodable() throws {
        let note = UnpitchedNote(
            displayStep: .g,
            displayOctave: 5,
            instrumentId: "P1-I2",
            percussionInstrument: .hiHatClosed,
            noteheadOverride: .x
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(note)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(UnpitchedNote.self, from: data)

        XCTAssertEqual(note.displayStep, decoded.displayStep)
        XCTAssertEqual(note.displayOctave, decoded.displayOctave)
        XCTAssertEqual(note.instrumentId, decoded.instrumentId)
        XCTAssertEqual(note.percussionInstrument, decoded.percussionInstrument)
        XCTAssertEqual(note.noteheadOverride, decoded.noteheadOverride)
    }
}
