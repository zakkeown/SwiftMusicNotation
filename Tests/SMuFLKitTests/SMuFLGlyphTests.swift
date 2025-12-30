import XCTest
@testable import SMuFLKit

final class SMuFLGlyphTests: XCTestCase {

    // MARK: - Code Point Tests

    func testNoteheadCodePoints() {
        // Verify common notehead code points match SMuFL specification
        XCTAssertEqual(SMuFLGlyphName.noteheadWhole.codePoint, 0xE0A2)
        XCTAssertEqual(SMuFLGlyphName.noteheadHalf.codePoint, 0xE0A3)
        XCTAssertEqual(SMuFLGlyphName.noteheadBlack.codePoint, 0xE0A4)
    }

    func testClefCodePoints() {
        XCTAssertEqual(SMuFLGlyphName.gClef.codePoint, 0xE050)
        XCTAssertEqual(SMuFLGlyphName.fClef.codePoint, 0xE062)
        XCTAssertEqual(SMuFLGlyphName.cClef.codePoint, 0xE05C)
    }

    func testAccidentalCodePoints() {
        XCTAssertEqual(SMuFLGlyphName.accidentalFlat.codePoint, 0xE260)
        XCTAssertEqual(SMuFLGlyphName.accidentalNatural.codePoint, 0xE261)
        XCTAssertEqual(SMuFLGlyphName.accidentalSharp.codePoint, 0xE262)
        XCTAssertEqual(SMuFLGlyphName.accidentalDoubleSharp.codePoint, 0xE263)
        XCTAssertEqual(SMuFLGlyphName.accidentalDoubleFlat.codePoint, 0xE264)
    }

    func testRestCodePoints() {
        XCTAssertEqual(SMuFLGlyphName.restWhole.codePoint, 0xE4E3)
        XCTAssertEqual(SMuFLGlyphName.restHalf.codePoint, 0xE4E4)
        XCTAssertEqual(SMuFLGlyphName.restQuarter.codePoint, 0xE4E5)
        XCTAssertEqual(SMuFLGlyphName.rest8th.codePoint, 0xE4E6)
        XCTAssertEqual(SMuFLGlyphName.rest16th.codePoint, 0xE4E7)
    }

    func testFlagCodePoints() {
        XCTAssertEqual(SMuFLGlyphName.flag8thUp.codePoint, 0xE240)
        XCTAssertEqual(SMuFLGlyphName.flag8thDown.codePoint, 0xE241)
        XCTAssertEqual(SMuFLGlyphName.flag16thUp.codePoint, 0xE242)
        XCTAssertEqual(SMuFLGlyphName.flag16thDown.codePoint, 0xE243)
    }

    func testDynamicsCodePoints() {
        XCTAssertEqual(SMuFLGlyphName.dynamicPiano.codePoint, 0xE520)
        XCTAssertEqual(SMuFLGlyphName.dynamicMezzo.codePoint, 0xE521)
        XCTAssertEqual(SMuFLGlyphName.dynamicForte.codePoint, 0xE522)
        XCTAssertEqual(SMuFLGlyphName.dynamicSforzando.codePoint, 0xE524)
    }

    func testTimeSignatureCodePoints() {
        XCTAssertEqual(SMuFLGlyphName.timeSig0.codePoint, 0xE080)
        XCTAssertEqual(SMuFLGlyphName.timeSig1.codePoint, 0xE081)
        XCTAssertEqual(SMuFLGlyphName.timeSig2.codePoint, 0xE082)
        XCTAssertEqual(SMuFLGlyphName.timeSig3.codePoint, 0xE083)
        XCTAssertEqual(SMuFLGlyphName.timeSig4.codePoint, 0xE084)
        XCTAssertEqual(SMuFLGlyphName.timeSigCommon.codePoint, 0xE08A)
        XCTAssertEqual(SMuFLGlyphName.timeSigCutCommon.codePoint, 0xE08B)
    }

    // MARK: - Character Conversion Tests

    func testCharacterConversion() {
        let trebleClef = SMuFLGlyphName.gClef
        let char = trebleClef.character
        XCTAssertNotNil(char)
        XCTAssertEqual(String(char), "\u{E050}")
    }

    func testStringConversion() {
        let quarterNote = SMuFLGlyphName.noteheadBlack
        XCTAssertEqual(quarterNote.string, "\u{E0A4}")
    }

    // MARK: - Glyph Name Tests

    func testGlyphNames() {
        XCTAssertEqual(SMuFLGlyphName.gClef.rawValue, "gClef")
        XCTAssertEqual(SMuFLGlyphName.fClef.rawValue, "fClef")
        XCTAssertEqual(SMuFLGlyphName.noteheadBlack.rawValue, "noteheadBlack")
        XCTAssertEqual(SMuFLGlyphName.accidentalSharp.rawValue, "accidentalSharp")
    }

    // MARK: - Range Tests

    func testGlyphsInValidRange() {
        // All SMuFL glyphs should be in the Private Use Area (U+E000 to U+F8FF)
        // or supplementary PUA (U+F0000 to U+FFFFD)
        let commonGlyphs: [SMuFLGlyphName] = [
            .gClef, .fClef, .cClef,
            .noteheadWhole, .noteheadHalf, .noteheadBlack,
            .accidentalFlat, .accidentalNatural, .accidentalSharp,
            .restWhole, .restQuarter, .rest8th
        ]

        for glyph in commonGlyphs {
            let codePoint = glyph.codePoint
            let inPUA = (0xE000...0xF8FF).contains(codePoint)
            let inSupplementary = (0xF0000...0xFFFFD).contains(codePoint)
            XCTAssertTrue(inPUA || inSupplementary,
                "\(glyph.rawValue) code point 0x\(String(codePoint, radix: 16)) not in PUA")
        }
    }

    // MARK: - Lookup Tests

    func testGlyphFromName() {
        XCTAssertEqual(SMuFLGlyphName(rawValue: "gClef"), .gClef)
        XCTAssertEqual(SMuFLGlyphName(rawValue: "noteheadBlack"), .noteheadBlack)
        XCTAssertNil(SMuFLGlyphName(rawValue: "invalidGlyph"))
    }

    // MARK: - Articulation Glyph Tests

    func testArticulationGlyphs() {
        XCTAssertNotNil(SMuFLGlyphName.articAccentAbove.codePoint)
        XCTAssertNotNil(SMuFLGlyphName.articAccentBelow.codePoint)
        XCTAssertNotNil(SMuFLGlyphName.articStaccatoAbove.codePoint)
        XCTAssertNotNil(SMuFLGlyphName.articStaccatoBelow.codePoint)
        XCTAssertNotNil(SMuFLGlyphName.articTenutoAbove.codePoint)
        XCTAssertNotNil(SMuFLGlyphName.articTenutoBelow.codePoint)
    }

    // MARK: - Ornament Glyph Tests

    func testOrnamentGlyphs() {
        XCTAssertNotNil(SMuFLGlyphName.ornamentTrill.codePoint)
        XCTAssertNotNil(SMuFLGlyphName.ornamentTurn.codePoint)
        XCTAssertNotNil(SMuFLGlyphName.ornamentMordent.codePoint)
    }

    // MARK: - Barline Glyph Tests

    func testBarlineGlyphs() {
        XCTAssertNotNil(SMuFLGlyphName.barlineSingle.codePoint)
        XCTAssertNotNil(SMuFLGlyphName.barlineDouble.codePoint)
        XCTAssertNotNil(SMuFLGlyphName.barlineFinal.codePoint)
    }

    // MARK: - Dot Tests

    func testAugmentationDot() {
        XCTAssertNotNil(SMuFLGlyphName.augmentationDot.codePoint)
    }

    // MARK: - Fermata Tests

    func testFermataGlyphs() {
        XCTAssertNotNil(SMuFLGlyphName.fermataAbove.codePoint)
        XCTAssertNotNil(SMuFLGlyphName.fermataBelow.codePoint)
    }

    // MARK: - Breath Mark Tests

    func testBreathMarkGlyphs() {
        XCTAssertNotNil(SMuFLGlyphName.breathMarkComma.codePoint)
        XCTAssertNotNil(SMuFLGlyphName.breathMarkTick.codePoint)
    }

    // MARK: - Repeat Tests

    func testRepeatGlyphs() {
        XCTAssertNotNil(SMuFLGlyphName.repeatDot.codePoint)
        XCTAssertNotNil(SMuFLGlyphName.segno.codePoint)
        XCTAssertNotNil(SMuFLGlyphName.coda.codePoint)
    }

    // MARK: - Brace/Bracket Tests

    func testBraceGlyphs() {
        XCTAssertNotNil(SMuFLGlyphName.brace.codePoint)
        XCTAssertNotNil(SMuFLGlyphName.bracket.codePoint)
    }
}
