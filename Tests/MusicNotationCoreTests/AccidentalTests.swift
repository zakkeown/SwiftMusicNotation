import XCTest
@testable import MusicNotationCore

final class AccidentalTests: XCTestCase {

    // MARK: - Semitone Alteration Tests

    func testNaturalAlteration() {
        XCTAssertEqual(Accidental.natural.semitoneAlteration, 0)
    }

    func testSharpAlterations() {
        XCTAssertEqual(Accidental.sharp.semitoneAlteration, 1)
        XCTAssertEqual(Accidental.doubleSharp.semitoneAlteration, 2)
        XCTAssertEqual(Accidental.tripleSharp.semitoneAlteration, 3)
    }

    func testFlatAlterations() {
        XCTAssertEqual(Accidental.flat.semitoneAlteration, -1)
        XCTAssertEqual(Accidental.doubleFlat.semitoneAlteration, -2)
        XCTAssertEqual(Accidental.tripleFlat.semitoneAlteration, -3)
    }

    func testQuarterToneAlterations() {
        XCTAssertEqual(Accidental.quarterToneSharp.semitoneAlteration, 0.5, accuracy: 0.01)
        XCTAssertEqual(Accidental.quarterToneFlat.semitoneAlteration, -0.5, accuracy: 0.01)
        XCTAssertEqual(Accidental.threeQuarterToneSharp.semitoneAlteration, 1.5, accuracy: 0.01)
        XCTAssertEqual(Accidental.threeQuarterToneFlat.semitoneAlteration, -1.5, accuracy: 0.01)
    }

    func testCombinationAccidentals() {
        XCTAssertEqual(Accidental.naturalSharp.semitoneAlteration, 1)
        XCTAssertEqual(Accidental.naturalFlat.semitoneAlteration, -1)
    }

    func testPersianAccidentals() {
        XCTAssertEqual(Accidental.sori.semitoneAlteration, 0.5, accuracy: 0.01)
        XCTAssertEqual(Accidental.koron.semitoneAlteration, -0.5, accuracy: 0.01)
    }

    // MARK: - MusicXML Mapping Tests

    func testMusicXMLNames() {
        XCTAssertEqual(Accidental.natural.musicXMLName, "natural")
        XCTAssertEqual(Accidental.sharp.musicXMLName, "sharp")
        XCTAssertEqual(Accidental.flat.musicXMLName, "flat")
        XCTAssertEqual(Accidental.doubleSharp.musicXMLName, "double-sharp")
        XCTAssertEqual(Accidental.doubleFlat.musicXMLName, "flat-flat")
    }

    func testFromMusicXML() {
        XCTAssertEqual(Accidental(musicXMLName: "natural"), .natural)
        XCTAssertEqual(Accidental(musicXMLName: "sharp"), .sharp)
        XCTAssertEqual(Accidental(musicXMLName: "flat"), .flat)
        XCTAssertEqual(Accidental(musicXMLName: "double-sharp"), .doubleSharp)
        XCTAssertEqual(Accidental(musicXMLName: "flat-flat"), .doubleFlat)
        XCTAssertEqual(Accidental(musicXMLName: "sharp-sharp"), .doubleSharp)
        XCTAssertNil(Accidental(musicXMLName: "invalid"))
    }

    func testMicrotoneXMLNames() {
        XCTAssertEqual(Accidental(musicXMLName: "quarter-sharp"), .quarterToneSharp)
        XCTAssertEqual(Accidental(musicXMLName: "quarter-flat"), .quarterToneFlat)
        XCTAssertEqual(Accidental(musicXMLName: "three-quarters-sharp"), .threeQuarterToneSharp)
        XCTAssertEqual(Accidental(musicXMLName: "three-quarters-flat"), .threeQuarterToneFlat)
    }

    // MARK: - From Alteration Tests

    func testFromAlteration() {
        XCTAssertEqual(Accidental(fromAlteration: 0), .natural)
        XCTAssertEqual(Accidental(fromAlteration: 1), .sharp)
        XCTAssertEqual(Accidental(fromAlteration: -1), .flat)
        XCTAssertEqual(Accidental(fromAlteration: 2), .doubleSharp)
        XCTAssertEqual(Accidental(fromAlteration: -2), .doubleFlat)
    }

    func testFromQuarterToneAlteration() {
        XCTAssertEqual(Accidental(fromAlteration: 0.5), .quarterToneSharp)
        XCTAssertEqual(Accidental(fromAlteration: -0.5), .quarterToneFlat)
        XCTAssertEqual(Accidental(fromAlteration: 1.5), .threeQuarterToneSharp)
        XCTAssertEqual(Accidental(fromAlteration: -1.5), .threeQuarterToneFlat)
    }

    func testFromUnknownAlteration() {
        XCTAssertNil(Accidental(fromAlteration: 0.25))
        XCTAssertNil(Accidental(fromAlteration: 4))
    }

    // MARK: - Boolean Properties Tests

    func testIsSharpening() {
        XCTAssertTrue(Accidental.sharp.isSharpening)
        XCTAssertTrue(Accidental.doubleSharp.isSharpening)
        XCTAssertTrue(Accidental.quarterToneSharp.isSharpening)
        XCTAssertFalse(Accidental.natural.isSharpening)
        XCTAssertFalse(Accidental.flat.isSharpening)
    }

    func testIsFlattening() {
        XCTAssertTrue(Accidental.flat.isFlattening)
        XCTAssertTrue(Accidental.doubleFlat.isFlattening)
        XCTAssertTrue(Accidental.quarterToneFlat.isFlattening)
        XCTAssertFalse(Accidental.natural.isFlattening)
        XCTAssertFalse(Accidental.sharp.isFlattening)
    }

    func testIsMicrotonal() {
        XCTAssertTrue(Accidental.quarterToneSharp.isMicrotonal)
        XCTAssertTrue(Accidental.quarterToneFlat.isMicrotonal)
        XCTAssertTrue(Accidental.threeQuarterToneSharp.isMicrotonal)
        XCTAssertTrue(Accidental.sori.isMicrotonal)
        XCTAssertTrue(Accidental.koron.isMicrotonal)

        XCTAssertFalse(Accidental.natural.isMicrotonal)
        XCTAssertFalse(Accidental.sharp.isMicrotonal)
        XCTAssertFalse(Accidental.flat.isMicrotonal)
        XCTAssertFalse(Accidental.doubleSharp.isMicrotonal)
    }

    // MARK: - Comparison Tests

    func testAccidentalOrdering() {
        let accidentals: [Accidental] = [
            .doubleFlat,
            .flat,
            .natural,
            .sharp,
            .doubleSharp
        ]

        for i in 0..<accidentals.count - 1 {
            XCTAssertLessThan(
                accidentals[i].semitoneAlteration,
                accidentals[i + 1].semitoneAlteration,
                "\(accidentals[i]) should be less than \(accidentals[i + 1])"
            )
        }
    }

    // MARK: - Pitch Integration Tests

    func testAccidentalWithPitch() {
        let cNatural = Pitch(step: .c, alter: Accidental.natural.semitoneAlteration, octave: 4)
        XCTAssertEqual(cNatural.midiNoteNumber, 60)

        let cSharp = Pitch(step: .c, alter: Accidental.sharp.semitoneAlteration, octave: 4)
        XCTAssertEqual(cSharp.midiNoteNumber, 61)

        let cFlat = Pitch(step: .c, alter: Accidental.flat.semitoneAlteration, octave: 4)
        XCTAssertEqual(cFlat.midiNoteNumber, 59)

        let cDoubleSharp = Pitch(step: .c, alter: Accidental.doubleSharp.semitoneAlteration, octave: 4)
        XCTAssertEqual(cDoubleSharp.midiNoteNumber, 62)
    }

    // MARK: - Codable Tests

    func testAccidentalCodable() throws {
        for accidental in [Accidental.natural, .sharp, .flat, .doubleSharp, .doubleFlat, .quarterToneSharp] {
            let encoder = JSONEncoder()
            let data = try encoder.encode(accidental)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(Accidental.self, from: data)
            XCTAssertEqual(accidental, decoded)
        }
    }

    // MARK: - All Cases Tests

    func testAllCasesHaveMusicXMLName() {
        for accidental in Accidental.allCases {
            XCTAssertFalse(accidental.musicXMLName.isEmpty, "Accidental \(accidental) should have a MusicXML name")
        }
    }

    func testAllCasesHaveSemitoneAlteration() {
        for accidental in Accidental.allCases {
            let alter = accidental.semitoneAlteration
            XCTAssertGreaterThanOrEqual(alter, -3.0)
            XCTAssertLessThanOrEqual(alter, 3.0)
        }
    }

    // MARK: - Description Tests

    func testDescription() {
        XCTAssertEqual(Accidental.natural.description, "♮")
        XCTAssertEqual(Accidental.sharp.description, "♯")
        XCTAssertEqual(Accidental.flat.description, "♭")
        XCTAssertEqual(Accidental.doubleSharp.description, "𝄪")
        XCTAssertEqual(Accidental.doubleFlat.description, "𝄫")
    }
}
