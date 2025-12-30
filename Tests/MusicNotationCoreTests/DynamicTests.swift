import XCTest
@testable import MusicNotationCore
@testable import SMuFLKit

final class DynamicTests: XCTestCase {

    // MARK: - Glyph Mapping Tests

    func testGlyphMapping() {
        XCTAssertEqual(Dynamic.pppppp.glyph, .dynamicPPPPPP)
        XCTAssertEqual(Dynamic.ppppp.glyph, .dynamicPPPPP)
        XCTAssertEqual(Dynamic.pppp.glyph, .dynamicPPPP)
        XCTAssertEqual(Dynamic.ppp.glyph, .dynamicPPP)
        XCTAssertEqual(Dynamic.pp.glyph, .dynamicPP)
        XCTAssertEqual(Dynamic.p.glyph, .dynamicPiano)
        XCTAssertEqual(Dynamic.mp.glyph, .dynamicMP)
        XCTAssertEqual(Dynamic.mf.glyph, .dynamicMF)
        XCTAssertEqual(Dynamic.f.glyph, .dynamicForte)
        XCTAssertEqual(Dynamic.ff.glyph, .dynamicFF)
        XCTAssertEqual(Dynamic.fff.glyph, .dynamicFFF)
        XCTAssertEqual(Dynamic.ffff.glyph, .dynamicFFFF)
        XCTAssertEqual(Dynamic.fffff.glyph, .dynamicFFFFF)
        XCTAssertEqual(Dynamic.ffffff.glyph, .dynamicFFFFFF)
        XCTAssertEqual(Dynamic.sf.glyph, .dynamicSforzando1)
        XCTAssertEqual(Dynamic.sfp.glyph, .dynamicSforzandoPiano)
        XCTAssertEqual(Dynamic.fp.glyph, .dynamicFortePiano)
        XCTAssertEqual(Dynamic.sfz.glyph, .dynamicSforzato)
        XCTAssertEqual(Dynamic.fz.glyph, .dynamicForzando)
        XCTAssertEqual(Dynamic.n.glyph, .dynamicNiente)
    }

    func testGlyphNil() {
        // sffz uses component glyphs, no combined glyph
        XCTAssertNil(Dynamic.sffz.glyph)
    }

    // MARK: - Component Glyphs Tests

    func testComponentGlyphs() {
        XCTAssertEqual(Dynamic.p.componentGlyphs, [.dynamicPiano])
        XCTAssertEqual(Dynamic.pp.componentGlyphs, [.dynamicPiano, .dynamicPiano])
        XCTAssertEqual(Dynamic.ppp.componentGlyphs, [.dynamicPiano, .dynamicPiano, .dynamicPiano])

        XCTAssertEqual(Dynamic.f.componentGlyphs, [.dynamicForte])
        XCTAssertEqual(Dynamic.ff.componentGlyphs, [.dynamicForte, .dynamicForte])
        XCTAssertEqual(Dynamic.fff.componentGlyphs, [.dynamicForte, .dynamicForte, .dynamicForte])

        XCTAssertEqual(Dynamic.mp.componentGlyphs, [.dynamicMezzo, .dynamicPiano])
        XCTAssertEqual(Dynamic.mf.componentGlyphs, [.dynamicMezzo, .dynamicForte])

        XCTAssertEqual(Dynamic.sfz.componentGlyphs, [.dynamicSforzando, .dynamicForte, .dynamicZ])
        XCTAssertEqual(Dynamic.sffz.componentGlyphs, [.dynamicSforzando, .dynamicForte, .dynamicForte, .dynamicZ])
    }

    // MARK: - MIDI Velocity Tests

    func testMidiVelocityOrder() {
        // Verify dynamics are ordered from quietest to loudest
        XCTAssertLessThan(Dynamic.pppppp.midiVelocity, Dynamic.ppppp.midiVelocity)
        XCTAssertLessThan(Dynamic.ppppp.midiVelocity, Dynamic.pppp.midiVelocity)
        XCTAssertLessThan(Dynamic.pppp.midiVelocity, Dynamic.ppp.midiVelocity)
        XCTAssertLessThan(Dynamic.ppp.midiVelocity, Dynamic.pp.midiVelocity)
        XCTAssertLessThan(Dynamic.pp.midiVelocity, Dynamic.p.midiVelocity)
        XCTAssertLessThan(Dynamic.p.midiVelocity, Dynamic.mp.midiVelocity)
        XCTAssertLessThan(Dynamic.mp.midiVelocity, Dynamic.mf.midiVelocity)
        XCTAssertLessThan(Dynamic.mf.midiVelocity, Dynamic.f.midiVelocity)
        XCTAssertLessThan(Dynamic.f.midiVelocity, Dynamic.ff.midiVelocity)
        XCTAssertLessThan(Dynamic.ff.midiVelocity, Dynamic.fff.midiVelocity)
        XCTAssertLessThan(Dynamic.fff.midiVelocity, Dynamic.ffff.midiVelocity)
        XCTAssertLessThan(Dynamic.ffff.midiVelocity, Dynamic.fffff.midiVelocity)
        XCTAssertLessThan(Dynamic.fffff.midiVelocity, Dynamic.ffffff.midiVelocity)
    }

    func testMidiVelocityRange() {
        for dynamic in Dynamic.allCases {
            XCTAssertGreaterThanOrEqual(dynamic.midiVelocity, 0)
            XCTAssertLessThanOrEqual(dynamic.midiVelocity, 127)
        }
    }

    func testSpecificMidiVelocities() {
        XCTAssertEqual(Dynamic.n.midiVelocity, 0) // niente = silence
        XCTAssertEqual(Dynamic.ffffff.midiVelocity, 127) // max
        XCTAssertEqual(Dynamic.mp.midiVelocity, 64) // mezzo piano = medium
    }

    // MARK: - Dynamic Properties Tests

    func testIsAccentDynamic() {
        XCTAssertTrue(Dynamic.sf.isAccentDynamic)
        XCTAssertTrue(Dynamic.sfp.isAccentDynamic)
        XCTAssertTrue(Dynamic.sfpp.isAccentDynamic)
        XCTAssertTrue(Dynamic.fp.isAccentDynamic)
        XCTAssertTrue(Dynamic.rf.isAccentDynamic)
        XCTAssertTrue(Dynamic.rfz.isAccentDynamic)
        XCTAssertTrue(Dynamic.sfz.isAccentDynamic)
        XCTAssertTrue(Dynamic.sffz.isAccentDynamic)
        XCTAssertTrue(Dynamic.fz.isAccentDynamic)
        XCTAssertTrue(Dynamic.sfzp.isAccentDynamic)

        XCTAssertFalse(Dynamic.p.isAccentDynamic)
        XCTAssertFalse(Dynamic.f.isAccentDynamic)
        XCTAssertFalse(Dynamic.mf.isAccentDynamic)
        XCTAssertFalse(Dynamic.mp.isAccentDynamic)
    }

    func testIsGraduatedDynamic() {
        XCTAssertTrue(Dynamic.pppppp.isGraduatedDynamic)
        XCTAssertTrue(Dynamic.ppppp.isGraduatedDynamic)
        XCTAssertTrue(Dynamic.pppp.isGraduatedDynamic)
        XCTAssertTrue(Dynamic.ppp.isGraduatedDynamic)
        XCTAssertTrue(Dynamic.pp.isGraduatedDynamic)
        XCTAssertTrue(Dynamic.p.isGraduatedDynamic)
        XCTAssertTrue(Dynamic.mp.isGraduatedDynamic)
        XCTAssertTrue(Dynamic.mf.isGraduatedDynamic)
        XCTAssertTrue(Dynamic.f.isGraduatedDynamic)
        XCTAssertTrue(Dynamic.ff.isGraduatedDynamic)
        XCTAssertTrue(Dynamic.fff.isGraduatedDynamic)
        XCTAssertTrue(Dynamic.ffff.isGraduatedDynamic)
        XCTAssertTrue(Dynamic.fffff.isGraduatedDynamic)
        XCTAssertTrue(Dynamic.ffffff.isGraduatedDynamic)

        XCTAssertFalse(Dynamic.sf.isGraduatedDynamic)
        XCTAssertFalse(Dynamic.sfz.isGraduatedDynamic)
        XCTAssertFalse(Dynamic.fp.isGraduatedDynamic)
        XCTAssertFalse(Dynamic.n.isGraduatedDynamic)
    }

    func testRelativeLoudness() {
        XCTAssertEqual(Dynamic.n.relativeLoudness, 0.0, accuracy: 0.01)
        XCTAssertEqual(Dynamic.ffffff.relativeLoudness, 1.0, accuracy: 0.01)

        // Mid-range dynamics should be somewhere in between
        XCTAssertGreaterThan(Dynamic.mf.relativeLoudness, 0.5)
        XCTAssertLessThan(Dynamic.mp.relativeLoudness, 0.6)
    }

    // MARK: - MusicXML Mapping Tests

    func testMusicXMLInitialization() {
        XCTAssertEqual(Dynamic(musicXMLName: "pppppp"), .pppppp)
        XCTAssertEqual(Dynamic(musicXMLName: "ppppp"), .ppppp)
        XCTAssertEqual(Dynamic(musicXMLName: "pppp"), .pppp)
        XCTAssertEqual(Dynamic(musicXMLName: "ppp"), .ppp)
        XCTAssertEqual(Dynamic(musicXMLName: "pp"), .pp)
        XCTAssertEqual(Dynamic(musicXMLName: "p"), .p)
        XCTAssertEqual(Dynamic(musicXMLName: "mp"), .mp)
        XCTAssertEqual(Dynamic(musicXMLName: "mf"), .mf)
        XCTAssertEqual(Dynamic(musicXMLName: "f"), .f)
        XCTAssertEqual(Dynamic(musicXMLName: "ff"), .ff)
        XCTAssertEqual(Dynamic(musicXMLName: "fff"), .fff)
        XCTAssertEqual(Dynamic(musicXMLName: "ffff"), .ffff)
        XCTAssertEqual(Dynamic(musicXMLName: "fffff"), .fffff)
        XCTAssertEqual(Dynamic(musicXMLName: "ffffff"), .ffffff)
        XCTAssertEqual(Dynamic(musicXMLName: "sf"), .sf)
        XCTAssertEqual(Dynamic(musicXMLName: "sfp"), .sfp)
        XCTAssertEqual(Dynamic(musicXMLName: "sfpp"), .sfpp)
        XCTAssertEqual(Dynamic(musicXMLName: "fp"), .fp)
        XCTAssertEqual(Dynamic(musicXMLName: "rf"), .rf)
        XCTAssertEqual(Dynamic(musicXMLName: "rfz"), .rfz)
        XCTAssertEqual(Dynamic(musicXMLName: "sfz"), .sfz)
        XCTAssertEqual(Dynamic(musicXMLName: "sffz"), .sffz)
        XCTAssertEqual(Dynamic(musicXMLName: "fz"), .fz)
        XCTAssertEqual(Dynamic(musicXMLName: "n"), .n)
        XCTAssertEqual(Dynamic(musicXMLName: "pf"), .pf)
        XCTAssertEqual(Dynamic(musicXMLName: "sfzp"), .sfzp)

        XCTAssertNil(Dynamic(musicXMLName: "unknown"))
    }

    func testMusicXMLCaseInsensitive() {
        XCTAssertEqual(Dynamic(musicXMLName: "PP"), .pp)
        XCTAssertEqual(Dynamic(musicXMLName: "FF"), .ff)
        XCTAssertEqual(Dynamic(musicXMLName: "Mf"), .mf)
        XCTAssertEqual(Dynamic(musicXMLName: "SFZ"), .sfz)
    }

    func testMusicXMLName() {
        XCTAssertEqual(Dynamic.p.musicXMLName, "p")
        XCTAssertEqual(Dynamic.pp.musicXMLName, "pp")
        XCTAssertEqual(Dynamic.f.musicXMLName, "f")
        XCTAssertEqual(Dynamic.ff.musicXMLName, "ff")
        XCTAssertEqual(Dynamic.sfz.musicXMLName, "sfz")
    }

    func testMusicXMLRoundTrip() {
        for dynamic in Dynamic.allCases {
            let name = dynamic.musicXMLName
            let parsed = Dynamic(musicXMLName: name)
            XCTAssertEqual(parsed, dynamic, "Round-trip failed for \(dynamic)")
        }
    }

    // MARK: - Comparable Tests

    func testDynamicComparison() {
        XCTAssertLessThan(Dynamic.p, Dynamic.f)
        XCTAssertLessThan(Dynamic.pp, Dynamic.p)
        XCTAssertLessThan(Dynamic.mp, Dynamic.mf)
        XCTAssertLessThan(Dynamic.ff, Dynamic.fff)
        XCTAssertLessThan(Dynamic.n, Dynamic.pppppp)
    }

    func testDynamicSorting() {
        let unsorted: [Dynamic] = [.f, .p, .ff, .mp, .mf, .pp]
        let sorted = unsorted.sorted()

        XCTAssertEqual(sorted, [.pp, .p, .mp, .mf, .f, .ff])
    }

    // MARK: - DynamicDisplay Tests

    func testDynamicDisplayInitialization() {
        let display = DynamicDisplay(dynamic: .mf, placement: .above)

        XCTAssertEqual(display.dynamic, .mf)
        XCTAssertEqual(display.placement, .above)
        XCTAssertFalse(display.editorial)
    }

    func testDynamicDisplayEffectivePlacement() {
        let displayWithPlacement = DynamicDisplay(dynamic: .f, placement: .above)
        XCTAssertEqual(displayWithPlacement.effectivePlacement, .above)

        let displayWithoutPlacement = DynamicDisplay(dynamic: .f, placement: nil)
        XCTAssertEqual(displayWithoutPlacement.effectivePlacement, .below) // default for dynamics
    }

    func testDynamicDisplayOffsets() {
        let display = DynamicDisplay(dynamic: .p, defaultX: 10.5, defaultY: -15.0)

        XCTAssertEqual(display.defaultX, 10.5)
        XCTAssertEqual(display.defaultY, -15.0)
    }

    func testDynamicDisplayEditorial() {
        let editorial = DynamicDisplay(dynamic: .pp, editorial: true)
        XCTAssertTrue(editorial.editorial)
    }

    // MARK: - CaseIterable Tests

    func testAllCases() {
        // Verify all cases are accounted for
        XCTAssertGreaterThan(Dynamic.allCases.count, 20)

        // Verify each case has velocity in valid range
        for dynamic in Dynamic.allCases {
            XCTAssertGreaterThanOrEqual(dynamic.midiVelocity, 0)
            XCTAssertLessThanOrEqual(dynamic.midiVelocity, 127)
        }
    }
}
