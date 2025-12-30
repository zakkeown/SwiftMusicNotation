import XCTest
@testable import MusicNotationCore

final class DurationTests: XCTestCase {

    // MARK: - Duration Base Tests

    func testDurationBaseQuarterNoteValue() {
        // Quarter note values relative to whole note
        XCTAssertEqual(DurationBase.whole.quarterNoteValue.doubleValue, 4.0, accuracy: 0.001)
        XCTAssertEqual(DurationBase.half.quarterNoteValue.doubleValue, 2.0, accuracy: 0.001)
        XCTAssertEqual(DurationBase.quarter.quarterNoteValue.doubleValue, 1.0, accuracy: 0.001)
        XCTAssertEqual(DurationBase.eighth.quarterNoteValue.doubleValue, 0.5, accuracy: 0.001)
        XCTAssertEqual(DurationBase.sixteenth.quarterNoteValue.doubleValue, 0.25, accuracy: 0.001)
        XCTAssertEqual(DurationBase.thirtySecond.quarterNoteValue.doubleValue, 0.125, accuracy: 0.001)
    }

    func testDurationBaseLongValues() {
        XCTAssertEqual(DurationBase.breve.quarterNoteValue.doubleValue, 8.0, accuracy: 0.001)
        XCTAssertEqual(DurationBase.longa.quarterNoteValue.doubleValue, 16.0, accuracy: 0.001)
        XCTAssertEqual(DurationBase.maxima.quarterNoteValue.doubleValue, 32.0, accuracy: 0.001)
    }

    func testDurationBaseSmallValues() {
        XCTAssertEqual(DurationBase.sixtyFourth.quarterNoteValue.doubleValue, 0.0625, accuracy: 0.001)
        XCTAssertEqual(DurationBase.oneHundredTwentyEighth.quarterNoteValue.doubleValue, 0.03125, accuracy: 0.001)
        XCTAssertEqual(DurationBase.twoHundredFiftySixth.quarterNoteValue.doubleValue, 0.015625, accuracy: 0.001)
    }

    // MARK: - Duration with Dots Tests

    func testDottedQuarter() {
        let duration = Duration(base: .quarter, dots: 1)
        // Dotted quarter = 1 + 0.5 = 1.5 quarter notes
        XCTAssertEqual(duration.quarterNoteValue.doubleValue, 1.5, accuracy: 0.001)
    }

    func testDoubleDottedHalf() {
        let duration = Duration(base: .half, dots: 2)
        // Double dotted half = 2 + 1 + 0.5 = 3.5 quarter notes
        XCTAssertEqual(duration.quarterNoteValue.doubleValue, 3.5, accuracy: 0.001)
    }

    func testTripleDottedWhole() {
        let duration = Duration(base: .whole, dots: 3)
        // Triple dotted whole = 4 + 2 + 1 + 0.5 = 7.5 quarter notes
        XCTAssertEqual(duration.quarterNoteValue.doubleValue, 7.5, accuracy: 0.001)
    }

    func testDottedEighth() {
        let duration = Duration(base: .eighth, dots: 1)
        // Dotted eighth = 0.5 + 0.25 = 0.75 quarter notes
        XCTAssertEqual(duration.quarterNoteValue.doubleValue, 0.75, accuracy: 0.001)
    }

    // MARK: - Tuplet Tests

    func testTriplet() {
        // Triplet: 3 notes in the time of 2
        let tripletRatio = TupletRatio(actual: 3, normal: 2)
        let duration = Duration(base: .eighth, dots: 0, tupletRatio: tripletRatio)
        // Normal eighth = 0.5, triplet eighth = 0.5 * (2/3) = 0.333...
        XCTAssertEqual(duration.quarterNoteValue.doubleValue, 1.0 / 3.0, accuracy: 0.001)
    }

    func testQuintuplet() {
        // Quintuplet: 5 notes in the time of 4
        let quintupletRatio = TupletRatio(actual: 5, normal: 4)
        let duration = Duration(base: .sixteenth, dots: 0, tupletRatio: quintupletRatio)
        // Normal sixteenth = 0.25, quintuplet = 0.25 * (4/5) = 0.2
        XCTAssertEqual(duration.quarterNoteValue.doubleValue, 0.2, accuracy: 0.001)
    }

    func testDuplet() {
        // Duplet: 2 notes in the time of 3 (in compound time)
        let dupletRatio = TupletRatio(actual: 2, normal: 3)
        let duration = Duration(base: .eighth, dots: 0, tupletRatio: dupletRatio)
        // Normal eighth = 0.5, duplet = 0.5 * (3/2) = 0.75
        XCTAssertEqual(duration.quarterNoteValue.doubleValue, 0.75, accuracy: 0.001)
    }

    func testNestedTuplet() {
        // Complex ratio: 7:4
        let ratio = TupletRatio(actual: 7, normal: 4)
        let duration = Duration(base: .sixteenth, dots: 0, tupletRatio: ratio)
        let expected = 0.25 * (4.0 / 7.0)
        XCTAssertEqual(duration.quarterNoteValue.doubleValue, expected, accuracy: 0.001)
    }

    // MARK: - Comparison Tests

    func testDurationEquality() {
        let d1 = Duration(base: .quarter, dots: 0)
        let d2 = Duration(base: .quarter, dots: 0)
        XCTAssertEqual(d1, d2)
    }

    func testDurationInequality() {
        let quarter = Duration(base: .quarter, dots: 0)
        let dottedQuarter = Duration(base: .quarter, dots: 1)
        XCTAssertNotEqual(quarter, dottedQuarter)
    }

    func testDurationComparison() {
        let eighth = Duration(base: .eighth, dots: 0)
        let quarter = Duration(base: .quarter, dots: 0)
        let half = Duration(base: .half, dots: 0)

        XCTAssertLessThan(eighth, quarter)
        XCTAssertLessThan(quarter, half)
    }

    // MARK: - Division Calculation Tests

    func testDivisionsForQuarterNote() {
        let quarter = Duration(base: .quarter, dots: 0)
        // At 1 division per quarter, a quarter note = 1 division
        XCTAssertEqual(quarter.divisions(perQuarter: 1), 1)
        // At 4 divisions per quarter, a quarter note = 4 divisions
        XCTAssertEqual(quarter.divisions(perQuarter: 4), 4)
    }

    func testDivisionsForHalfNote() {
        let half = Duration(base: .half, dots: 0)
        XCTAssertEqual(half.divisions(perQuarter: 1), 2)
        XCTAssertEqual(half.divisions(perQuarter: 4), 8)
    }

    func testDivisionsForDottedNotes() {
        let dottedQuarter = Duration(base: .quarter, dots: 1)
        // Dotted quarter = 1.5 quarters
        XCTAssertEqual(dottedQuarter.divisions(perQuarter: 2), 3)
        XCTAssertEqual(dottedQuarter.divisions(perQuarter: 4), 6)
    }

    // MARK: - MusicXML Type String Tests

    func testMusicXMLTypeStrings() {
        XCTAssertEqual(DurationBase.whole.musicXMLTypeName, "whole")
        XCTAssertEqual(DurationBase.half.musicXMLTypeName, "half")
        XCTAssertEqual(DurationBase.quarter.musicXMLTypeName, "quarter")
        XCTAssertEqual(DurationBase.eighth.musicXMLTypeName, "eighth")
        XCTAssertEqual(DurationBase.sixteenth.musicXMLTypeName, "16th")
        XCTAssertEqual(DurationBase.thirtySecond.musicXMLTypeName, "32nd")
        XCTAssertEqual(DurationBase.sixtyFourth.musicXMLTypeName, "64th")
    }

    func testDurationBaseFromMusicXML() {
        XCTAssertEqual(DurationBase(musicXMLTypeName: "whole"), .whole)
        XCTAssertEqual(DurationBase(musicXMLTypeName: "half"), .half)
        XCTAssertEqual(DurationBase(musicXMLTypeName: "quarter"), .quarter)
        XCTAssertEqual(DurationBase(musicXMLTypeName: "eighth"), .eighth)
        XCTAssertEqual(DurationBase(musicXMLTypeName: "16th"), .sixteenth)
        XCTAssertEqual(DurationBase(musicXMLTypeName: "32nd"), .thirtySecond)
        XCTAssertNil(DurationBase(musicXMLTypeName: "invalid"))
    }

    // MARK: - Codable Tests

    func testDurationCodable() throws {
        let duration = Duration(base: .quarter, dots: 2, tupletRatio: TupletRatio(actual: 3, normal: 2))
        let encoder = JSONEncoder()
        let data = try encoder.encode(duration)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Duration.self, from: data)
        XCTAssertEqual(duration.base, decoded.base)
        XCTAssertEqual(duration.dots, decoded.dots)
        XCTAssertEqual(duration.tupletRatio?.actual, decoded.tupletRatio?.actual)
        XCTAssertEqual(duration.tupletRatio?.normal, decoded.tupletRatio?.normal)
    }

    func testDurationBaseCodable() throws {
        for base in DurationBase.allCases {
            let encoder = JSONEncoder()
            let data = try encoder.encode(base)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(DurationBase.self, from: data)
            XCTAssertEqual(base, decoded)
        }
    }
}
