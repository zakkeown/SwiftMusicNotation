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
        if let char = char {
            XCTAssertEqual(String(char), "\u{E050}")
        }
    }

    func testStringConversion() {
        let quarterNote = SMuFLGlyphName.noteheadBlack
        XCTAssertNotNil(quarterNote.string)
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

// MARK: - GlyphBoundingBox Tests

final class GlyphBoundingBoxTests: XCTestCase {

    func testInitWithArrays() {
        let box = GlyphBoundingBox(
            bBoxSW: [-0.5, -0.5],
            bBoxNE: [1.5, 0.5]
        )

        XCTAssertEqual(box.southWestX, -0.5)
        XCTAssertEqual(box.southWestY, -0.5)
        XCTAssertEqual(box.northEastX, 1.5)
        XCTAssertEqual(box.northEastY, 0.5)
    }

    func testInitWithExplicitCoordinates() {
        let box = GlyphBoundingBox(
            southWestX: -1.0,
            southWestY: -2.0,
            northEastX: 3.0,
            northEastY: 4.0
        )

        XCTAssertEqual(box.southWestX, -1.0)
        XCTAssertEqual(box.southWestY, -2.0)
        XCTAssertEqual(box.northEastX, 3.0)
        XCTAssertEqual(box.northEastY, 4.0)
    }

    func testWidth() {
        let box = GlyphBoundingBox(
            southWestX: -0.5,
            southWestY: 0,
            northEastX: 1.5,
            northEastY: 1
        )

        XCTAssertEqual(box.width, 2.0)
    }

    func testHeight() {
        let box = GlyphBoundingBox(
            southWestX: 0,
            southWestY: -1.0,
            northEastX: 1,
            northEastY: 2.0
        )

        XCTAssertEqual(box.height, 3.0)
    }

    func testCGRect() {
        let box = GlyphBoundingBox(
            southWestX: 0,
            southWestY: 0,
            northEastX: 2,
            northEastY: 1
        )

        let staffSpaceInPoints: CGFloat = 10.0
        let rect = box.cgRect(staffSpaceInPoints: staffSpaceInPoints)

        XCTAssertEqual(rect.origin.x, 0)
        XCTAssertEqual(rect.origin.y, -10.0) // Y flipped
        XCTAssertEqual(rect.width, 20.0)
        XCTAssertEqual(rect.height, 10.0)
    }

    func testEquality() {
        let box1 = GlyphBoundingBox(bBoxSW: [0, 0], bBoxNE: [1, 1])
        let box2 = GlyphBoundingBox(bBoxSW: [0, 0], bBoxNE: [1, 1])
        let box3 = GlyphBoundingBox(bBoxSW: [0, 0], bBoxNE: [2, 2])

        XCTAssertEqual(box1, box2)
        XCTAssertNotEqual(box1, box3)
    }

    func testHashable() {
        let box1 = GlyphBoundingBox(bBoxSW: [0, 0], bBoxNE: [1, 1])
        let box2 = GlyphBoundingBox(bBoxSW: [0, 0], bBoxNE: [1, 1])

        var set = Set<GlyphBoundingBox>()
        set.insert(box1)
        set.insert(box2)

        XCTAssertEqual(set.count, 1)
    }
}

// MARK: - GlyphAnchors Tests

final class GlyphAnchorsTests: XCTestCase {

    func testPointForType() {
        let anchors = GlyphAnchors(anchors: [
            "stemUpSE": [1.0, 0.5],
            "stemDownNW": [-0.5, 1.0]
        ])

        let stemUpSE = anchors.point(for: .stemUpSE)
        XCTAssertNotNil(stemUpSE)
        XCTAssertEqual(stemUpSE?.x, 1.0)
        XCTAssertEqual(stemUpSE?.y, 0.5)

        let stemDownNW = anchors.point(for: .stemDownNW)
        XCTAssertNotNil(stemDownNW)
        XCTAssertEqual(stemDownNW?.x, -0.5)
        XCTAssertEqual(stemDownNW?.y, 1.0)
    }

    func testPointForMissingType() {
        let anchors = GlyphAnchors(anchors: [:])
        XCTAssertNil(anchors.point(for: .stemUpSE))
    }

    func testStaffSpacePoint() {
        let anchors = GlyphAnchors(anchors: [
            "opticalCenter": [0.5, 0.0]
        ])

        let point = anchors.staffSpacePoint(for: .opticalCenter)
        XCTAssertNotNil(point)
        XCTAssertEqual(point?.x, 0.5)
        XCTAssertEqual(point?.y, 0.0)
    }

    func testStaffSpacePointMissing() {
        let anchors = GlyphAnchors(anchors: [:])
        XCTAssertNil(anchors.staffSpacePoint(for: .cutOutNE))
    }

    func testAvailableAnchors() {
        let anchors = GlyphAnchors(anchors: [
            "stemUpSE": [1.0, 0.5],
            "stemDownNW": [-0.5, 1.0],
            "opticalCenter": [0.5, 0.0]
        ])

        let available = anchors.availableAnchors
        XCTAssertEqual(available.count, 3)
        XCTAssertTrue(available.contains(.stemUpSE))
        XCTAssertTrue(available.contains(.stemDownNW))
        XCTAssertTrue(available.contains(.opticalCenter))
    }

    func testAvailableAnchorsEmpty() {
        let anchors = GlyphAnchors(anchors: [:])
        XCTAssertTrue(anchors.availableAnchors.isEmpty)
    }
}

// MARK: - AnchorType Tests

final class AnchorTypeTests: XCTestCase {

    func testRawValues() {
        XCTAssertEqual(AnchorType.stemUpSE.rawValue, "stemUpSE")
        XCTAssertEqual(AnchorType.stemDownNW.rawValue, "stemDownNW")
        XCTAssertEqual(AnchorType.cutOutNE.rawValue, "cutOutNE")
        XCTAssertEqual(AnchorType.opticalCenter.rawValue, "opticalCenter")
    }

    func testAllCases() {
        // Verify some key anchor types exist
        let allCases = AnchorType.allCases
        XCTAssertTrue(allCases.contains(.stemUpSE))
        XCTAssertTrue(allCases.contains(.stemDownNW))
        XCTAssertTrue(allCases.contains(.stemUpNW))
        XCTAssertTrue(allCases.contains(.stemDownSW))
        XCTAssertTrue(allCases.contains(.cutOutNE))
        XCTAssertTrue(allCases.contains(.cutOutNW))
        XCTAssertTrue(allCases.contains(.cutOutSE))
        XCTAssertTrue(allCases.contains(.cutOutSW))
        XCTAssertTrue(allCases.contains(.opticalCenter))
        XCTAssertTrue(allCases.contains(.noteheadOrigin))
    }
}

// MARK: - GlyphAlternate Tests

final class GlyphAlternateTests: XCTestCase {

    func testInitialization() {
        let alternate = GlyphAlternate(
            codepoint: "U+E0A5",
            name: "noteheadBlackSmall",
            alternateFor: "noteheadBlack"
        )

        XCTAssertEqual(alternate.codepoint, "U+E0A5")
        XCTAssertEqual(alternate.name, "noteheadBlackSmall")
        XCTAssertEqual(alternate.alternateFor, "noteheadBlack")
    }

    func testAlternateForNil() {
        let alternate = GlyphAlternate(
            codepoint: "U+E0A6",
            name: "specialGlyph",
            alternateFor: nil
        )

        XCTAssertNil(alternate.alternateFor)
    }
}

// MARK: - OptionalGlyph Tests

final class OptionalGlyphTests: XCTestCase {

    func testInitialization() {
        let optional = OptionalGlyph(
            codepoint: "U+F000",
            classes: ["noteheads", "recommended"],
            description: "A special notehead for extended techniques"
        )

        XCTAssertEqual(optional.codepoint, "U+F000")
        XCTAssertEqual(optional.classes?.count, 2)
        XCTAssertEqual(optional.description, "A special notehead for extended techniques")
    }

    func testNilClassesAndDescription() {
        let optional = OptionalGlyph(
            codepoint: "U+F001",
            classes: nil,
            description: nil
        )

        XCTAssertNil(optional.classes)
        XCTAssertNil(optional.description)
    }
}

// MARK: - GlyphLigature Tests

final class GlyphLigatureTests: XCTestCase {

    func testInitialization() {
        let ligature = GlyphLigature(
            codepoint: "U+F100",
            componentGlyphs: ["dynamicPiano", "dynamicPiano"],
            description: "Double piano (pp)"
        )

        XCTAssertEqual(ligature.codepoint, "U+F100")
        XCTAssertEqual(ligature.componentGlyphs.count, 2)
        XCTAssertEqual(ligature.description, "Double piano (pp)")
    }

    func testNilDescription() {
        let ligature = GlyphLigature(
            codepoint: "U+F101",
            componentGlyphs: ["dynamicForte", "dynamicForte", "dynamicForte"],
            description: nil
        )

        XCTAssertEqual(ligature.componentGlyphs.count, 3)
        XCTAssertNil(ligature.description)
    }
}
