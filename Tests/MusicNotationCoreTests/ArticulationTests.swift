import XCTest
@testable import MusicNotationCore
@testable import SMuFLKit

final class ArticulationTests: XCTestCase {

    // MARK: - Glyph Mapping Tests

    func testGlyphAbove() {
        XCTAssertEqual(Articulation.accent.glyphAbove, .articAccentAbove)
        XCTAssertEqual(Articulation.strongAccent.glyphAbove, .articMarcatoAbove)
        XCTAssertEqual(Articulation.staccato.glyphAbove, .articStaccatoAbove)
        XCTAssertEqual(Articulation.tenuto.glyphAbove, .articTenutoAbove)
        XCTAssertEqual(Articulation.detachedLegato.glyphAbove, .articTenutoStaccatoAbove)
        XCTAssertEqual(Articulation.staccatissimo.glyphAbove, .articStaccatissimoAbove)
        XCTAssertEqual(Articulation.stress.glyphAbove, .articStressAbove)
        XCTAssertEqual(Articulation.unstress.glyphAbove, .articUnstressAbove)
        XCTAssertEqual(Articulation.breathMark.glyphAbove, .breathMarkComma)
        XCTAssertEqual(Articulation.caesura.glyphAbove, .caesura)
        XCTAssertEqual(Articulation.upBow.glyphAbove, .stringsUpBow)
        XCTAssertEqual(Articulation.downBow.glyphAbove, .stringsDownBow)
        XCTAssertEqual(Articulation.harmonic.glyphAbove, .stringsHarmonic)
        XCTAssertEqual(Articulation.thumbPosition.glyphAbove, .stringsThumbPosition)
        XCTAssertEqual(Articulation.snapPizzicato.glyphAbove, .stringsSnapPizzicatoAbove)
        XCTAssertEqual(Articulation.softAccent.glyphAbove, .articSoftAccentAbove)
    }

    func testGlyphBelow() {
        XCTAssertEqual(Articulation.accent.glyphBelow, .articAccentBelow)
        XCTAssertEqual(Articulation.strongAccent.glyphBelow, .articMarcatoBelow)
        XCTAssertEqual(Articulation.staccato.glyphBelow, .articStaccatoBelow)
        XCTAssertEqual(Articulation.tenuto.glyphBelow, .articTenutoBelow)
        XCTAssertEqual(Articulation.detachedLegato.glyphBelow, .articTenutoStaccatoBelow)
        XCTAssertEqual(Articulation.staccatissimo.glyphBelow, .articStaccatissimoBelow)
        XCTAssertEqual(Articulation.stress.glyphBelow, .articStressBelow)
        XCTAssertEqual(Articulation.unstress.glyphBelow, .articUnstressBelow)
        XCTAssertEqual(Articulation.softAccent.glyphBelow, .articSoftAccentBelow)
        XCTAssertEqual(Articulation.snapPizzicato.glyphBelow, .stringsSnapPizzicatoBelow)
    }

    func testGlyphForPlacement() {
        XCTAssertEqual(Articulation.accent.glyph(for: .above), .articAccentAbove)
        XCTAssertEqual(Articulation.accent.glyph(for: .below), .articAccentBelow)
        XCTAssertEqual(Articulation.staccato.glyph(for: .above), .articStaccatoAbove)
        XCTAssertEqual(Articulation.staccato.glyph(for: .below), .articStaccatoBelow)
    }

    func testGlyphNil() {
        // Some articulations don't have explicit glyphs
        XCTAssertNil(Articulation.scoop.glyphAbove)
        XCTAssertNil(Articulation.plop.glyphAbove)
        XCTAssertNil(Articulation.doit.glyphAbove)
        XCTAssertNil(Articulation.falloff.glyphAbove)
    }

    // MARK: - Default Placement Tests

    func testDefaultPlacement() {
        XCTAssertEqual(Articulation.staccato.defaultPlacement, .above)
        XCTAssertEqual(Articulation.tenuto.defaultPlacement, .above)
        XCTAssertEqual(Articulation.accent.defaultPlacement, .above)
        XCTAssertEqual(Articulation.strongAccent.defaultPlacement, .above)
        XCTAssertEqual(Articulation.breathMark.defaultPlacement, .above)
        XCTAssertEqual(Articulation.upBow.defaultPlacement, .above)
        XCTAssertEqual(Articulation.downBow.defaultPlacement, .above)
    }

    // MARK: - Category Tests

    func testArticulationCategories() {
        XCTAssertEqual(Articulation.accent.category, .accent)
        XCTAssertEqual(Articulation.strongAccent.category, .accent)
        XCTAssertEqual(Articulation.stress.category, .accent)
        XCTAssertEqual(Articulation.softAccent.category, .accent)

        XCTAssertEqual(Articulation.staccato.category, .staccato)
        XCTAssertEqual(Articulation.staccatissimo.category, .staccato)
        XCTAssertEqual(Articulation.spiccato.category, .staccato)

        XCTAssertEqual(Articulation.tenuto.category, .tenuto)
        XCTAssertEqual(Articulation.detachedLegato.category, .tenuto)

        XCTAssertEqual(Articulation.breathMark.category, .breath)
        XCTAssertEqual(Articulation.caesura.category, .breath)

        XCTAssertEqual(Articulation.upBow.category, .bowing)
        XCTAssertEqual(Articulation.downBow.category, .bowing)

        XCTAssertEqual(Articulation.harmonic.category, .string)
        XCTAssertEqual(Articulation.openString.category, .string)
        XCTAssertEqual(Articulation.snapPizzicato.category, .string)

        XCTAssertEqual(Articulation.scoop.category, .jazz)
        XCTAssertEqual(Articulation.plop.category, .jazz)
        XCTAssertEqual(Articulation.doit.category, .jazz)
        XCTAssertEqual(Articulation.falloff.category, .jazz)
    }

    // MARK: - MusicXML Mapping Tests

    func testMusicXMLInitialization() {
        XCTAssertEqual(Articulation(musicXMLName: "accent"), .accent)
        XCTAssertEqual(Articulation(musicXMLName: "strong-accent"), .strongAccent)
        XCTAssertEqual(Articulation(musicXMLName: "staccato"), .staccato)
        XCTAssertEqual(Articulation(musicXMLName: "tenuto"), .tenuto)
        XCTAssertEqual(Articulation(musicXMLName: "detached-legato"), .detachedLegato)
        XCTAssertEqual(Articulation(musicXMLName: "staccatissimo"), .staccatissimo)
        XCTAssertEqual(Articulation(musicXMLName: "spiccato"), .spiccato)
        XCTAssertEqual(Articulation(musicXMLName: "stress"), .stress)
        XCTAssertEqual(Articulation(musicXMLName: "unstress"), .unstress)
        XCTAssertEqual(Articulation(musicXMLName: "breath-mark"), .breathMark)
        XCTAssertEqual(Articulation(musicXMLName: "caesura"), .caesura)
        XCTAssertEqual(Articulation(musicXMLName: "up-bow"), .upBow)
        XCTAssertEqual(Articulation(musicXMLName: "down-bow"), .downBow)
        XCTAssertEqual(Articulation(musicXMLName: "harmonic"), .harmonic)
        XCTAssertEqual(Articulation(musicXMLName: "open-string"), .openString)
        XCTAssertEqual(Articulation(musicXMLName: "thumb-position"), .thumbPosition)
        XCTAssertEqual(Articulation(musicXMLName: "snap-pizzicato"), .snapPizzicato)
        XCTAssertEqual(Articulation(musicXMLName: "scoop"), .scoop)
        XCTAssertEqual(Articulation(musicXMLName: "plop"), .plop)
        XCTAssertEqual(Articulation(musicXMLName: "doit"), .doit)
        XCTAssertEqual(Articulation(musicXMLName: "falloff"), .falloff)

        XCTAssertNil(Articulation(musicXMLName: "unknown"))
    }

    func testMusicXMLName() {
        XCTAssertEqual(Articulation.accent.musicXMLName, "accent")
        XCTAssertEqual(Articulation.strongAccent.musicXMLName, "strong-accent")
        XCTAssertEqual(Articulation.staccato.musicXMLName, "staccato")
        XCTAssertEqual(Articulation.tenuto.musicXMLName, "tenuto")
        XCTAssertEqual(Articulation.detachedLegato.musicXMLName, "detached-legato")
        XCTAssertEqual(Articulation.staccatissimo.musicXMLName, "staccatissimo")
        XCTAssertEqual(Articulation.breathMark.musicXMLName, "breath-mark")
        XCTAssertEqual(Articulation.upBow.musicXMLName, "up-bow")
        XCTAssertEqual(Articulation.downBow.musicXMLName, "down-bow")
        XCTAssertEqual(Articulation.snapPizzicato.musicXMLName, "snap-pizzicato")
    }

    func testMusicXMLRoundTrip() {
        for articulation in Articulation.allCases {
            let name = articulation.musicXMLName
            let parsed = Articulation(musicXMLName: name)
            XCTAssertEqual(parsed, articulation, "Round-trip failed for \(articulation)")
        }
    }

    // MARK: - ArticulationDisplay Tests

    func testArticulationDisplayInitialization() {
        let display = ArticulationDisplay(articulation: .staccato, placement: .below)

        XCTAssertEqual(display.articulation, .staccato)
        XCTAssertEqual(display.placement, .below)
        XCTAssertFalse(display.editorial)
    }

    func testArticulationDisplayEffectivePlacement() {
        let displayWithPlacement = ArticulationDisplay(articulation: .accent, placement: .below)
        XCTAssertEqual(displayWithPlacement.effectivePlacement, .below)

        let displayWithoutPlacement = ArticulationDisplay(articulation: .accent, placement: nil)
        XCTAssertEqual(displayWithoutPlacement.effectivePlacement, .above) // default
    }

    func testArticulationDisplayGlyph() {
        let aboveDisplay = ArticulationDisplay(articulation: .accent, placement: .above)
        XCTAssertEqual(aboveDisplay.glyph, .articAccentAbove)

        let belowDisplay = ArticulationDisplay(articulation: .accent, placement: .below)
        XCTAssertEqual(belowDisplay.glyph, .articAccentBelow)
    }

    func testArticulationDisplayEditorial() {
        let editorial = ArticulationDisplay(articulation: .staccato, editorial: true)
        XCTAssertTrue(editorial.editorial)
    }

    // MARK: - CaseIterable Tests

    func testAllCases() {
        // Verify all cases are accounted for
        XCTAssertGreaterThan(Articulation.allCases.count, 20)

        // Verify each case has a MusicXML name
        for articulation in Articulation.allCases {
            XCTAssertFalse(articulation.musicXMLName.isEmpty)
        }
    }

    // MARK: - ArticulationCategory Tests

    func testArticulationCategoryRawValues() {
        XCTAssertEqual(ArticulationCategory.accent.rawValue, "accent")
        XCTAssertEqual(ArticulationCategory.staccato.rawValue, "staccato")
        XCTAssertEqual(ArticulationCategory.tenuto.rawValue, "tenuto")
        XCTAssertEqual(ArticulationCategory.breath.rawValue, "breath")
        XCTAssertEqual(ArticulationCategory.bowing.rawValue, "bowing")
        XCTAssertEqual(ArticulationCategory.string.rawValue, "string")
        XCTAssertEqual(ArticulationCategory.jazz.rawValue, "jazz")
        XCTAssertEqual(ArticulationCategory.other.rawValue, "other")
    }
}
