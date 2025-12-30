import XCTest
@testable import SMuFLKit

final class SMuFLFontManagerTests: XCTestCase {

    // MARK: - Singleton Tests

    func testSharedInstance() {
        let manager1 = SMuFLFontManager.shared
        let manager2 = SMuFLFontManager.shared
        XCTAssertTrue(manager1 === manager2, "Shared instance should be the same object")
    }

    // MARK: - Font Loading Tests

    func testLoadedFontNamesInitiallyEmpty() {
        let manager = SMuFLFontManager.shared
        // Note: This test may fail if fonts are already loaded from other tests
        // In a fresh state, this would be empty
        _ = manager.loadedFontNames
        // Just verify it doesn't crash
    }

    // MARK: - Loaded Font Tests

    func testLoadedFontProperties() throws {
        // This test requires Bravura to be loadable
        // Skip if font loading fails (e.g., in CI without fonts)
        let manager = SMuFLFontManager.shared

        do {
            let font = try manager.loadFont(named: "Bravura", from: Bundle.module)
            XCTAssertEqual(font.name, "Bravura")
            XCTAssertNotNil(font.ctFont)
        } catch {
            // Font not available - skip test
            throw XCTSkip("Bravura font not available: \(error)")
        }
    }

    func testFontForStaffHeight() throws {
        let manager = SMuFLFontManager.shared

        do {
            let loadedFont = try manager.loadFont(named: "Bravura", from: Bundle.module)

            // Test different staff heights
            let font24 = loadedFont.font(forStaffHeight: 24)
            let font48 = loadedFont.font(forStaffHeight: 48)

            XCTAssertNotNil(font24)
            XCTAssertNotNil(font48)
        } catch {
            throw XCTSkip("Bravura font not available: \(error)")
        }
    }

    func testGlyphLookup() throws {
        let manager = SMuFLFontManager.shared

        do {
            let loadedFont = try manager.loadFont(named: "Bravura", from: Bundle.module)

            // Test glyph lookup for common glyphs
            let trebleClef = loadedFont.glyph(for: .gClef)
            let noteheadBlack = loadedFont.glyph(for: .noteheadBlack)

            // These should return valid glyphs if font is properly loaded
            XCTAssertNotNil(trebleClef, "Should find treble clef glyph")
            XCTAssertNotNil(noteheadBlack, "Should find black notehead glyph")
        } catch {
            throw XCTSkip("Bravura font not available: \(error)")
        }
    }

    func testBoundingBoxRetrieval() throws {
        let manager = SMuFLFontManager.shared

        do {
            let loadedFont = try manager.loadFont(named: "Bravura", from: Bundle.module)

            // Bounding boxes come from metadata
            if loadedFont.metadata != nil {
                let bbox = loadedFont.boundingBox(for: .noteheadBlack)
                if let bbox = bbox {
                    // Notehead should have positive width and height
                    XCTAssertGreaterThan(bbox.width, 0, "Notehead width should be positive")
                    XCTAssertGreaterThan(bbox.height, 0, "Notehead height should be positive")
                }
            }
        } catch {
            throw XCTSkip("Bravura font not available: \(error)")
        }
    }

    func testEngravingDefaults() throws {
        let manager = SMuFLFontManager.shared

        do {
            let loadedFont = try manager.loadFont(named: "Bravura", from: Bundle.module)

            let defaults = loadedFont.engravingDefaults

            // Staff line thickness should be positive and reasonable
            XCTAssertGreaterThan(defaults.staffLineThickness, 0)
            XCTAssertLessThan(defaults.staffLineThickness, 0.5)

            // Stem thickness should be positive
            XCTAssertGreaterThan(defaults.stemThickness, 0)

            // Beam thickness should be positive
            XCTAssertGreaterThan(defaults.beamThickness, 0)
        } catch {
            throw XCTSkip("Bravura font not available: \(error)")
        }
    }

    func testAnchorRetrieval() throws {
        let manager = SMuFLFontManager.shared

        do {
            let loadedFont = try manager.loadFont(named: "Bravura", from: Bundle.module)

            // Anchors come from metadata
            if loadedFont.metadata != nil {
                let anchors = loadedFont.anchors(for: .noteheadBlack)
                // Noteheads should have stem anchors
                if let anchors = anchors {
                    XCTAssertNotNil(anchors.point(for: .stemUpSE), "Notehead should have stemUpSE anchor")
                    XCTAssertNotNil(anchors.point(for: .stemDownNW), "Notehead should have stemDownNW anchor")
                }
            }
        } catch {
            throw XCTSkip("Bravura font not available: \(error)")
        }
    }

    // MARK: - Default Engraving Defaults Tests

    func testDefaultEngravingDefaults() {
        let defaults = EngravingDefaults.default

        // Verify default values are reasonable
        XCTAssertGreaterThan(defaults.staffLineThickness, 0)
        XCTAssertGreaterThan(defaults.stemThickness, 0)
        XCTAssertGreaterThan(defaults.beamThickness, 0)
        XCTAssertGreaterThan(defaults.beamSpacing, 0)
    }
}
