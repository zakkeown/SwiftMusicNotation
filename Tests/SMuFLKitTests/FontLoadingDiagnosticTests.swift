import XCTest
import CoreText
@testable import SMuFLKit

/// Diagnostic tests that verify every step of the font loading and glyph rendering pipeline.
/// These are designed to pinpoint exactly where failures occur.
final class FontLoadingDiagnosticTests: XCTestCase {

    // MARK: - Step 1: Bundle.module contains font resources

    func testBundleModuleContainsFontDirectory() {
        let fontsURL = Bundle.module.url(forResource: "Bravura", withExtension: "otf", subdirectory: "Fonts/Bravura")
        XCTAssertNotNil(fontsURL, "Bundle.module should contain Fonts/Bravura/Bravura.otf")
        if let url = fontsURL {
            XCTAssertTrue(FileManager.default.fileExists(atPath: url.path), "Font file should exist on disk at \(url.path)")
        }
    }

    func testBundleModuleContainsMetadata() {
        let metadataURL = Bundle.module.url(forResource: "bravura_metadata", withExtension: "json", subdirectory: "Fonts/Bravura")
        XCTAssertNotNil(metadataURL, "Bundle.module should contain Fonts/Bravura/bravura_metadata.json")
    }

    func testBundleModuleRootDoesNotContainFont() {
        // This verifies the font is NOT at the root level — it's in a subdirectory
        let rootURL = Bundle.module.url(forResource: "Bravura", withExtension: "otf")
        // This may or may not be nil depending on how SPM copies resources.
        // The important thing is the subdirectory path works (tested above).
        if rootURL == nil {
            // Font is only in subdirectory — loadFont must check subdirectory
            print("Font is NOT at bundle root — subdirectory lookup is required")
        } else {
            print("Font IS at bundle root — either lookup path works")
        }
    }

    // MARK: - Step 2: Font registration with Core Text

    func testCTFontRegistration() throws {
        guard let fontURL = Bundle.module.url(forResource: "Bravura", withExtension: "otf", subdirectory: "Fonts/Bravura")
            ?? Bundle.module.url(forResource: "Bravura", withExtension: "otf") else {
            XCTFail("Cannot find Bravura.otf in bundle")
            return
        }

        // Try to register — may already be registered
        var error: Unmanaged<CFError>?
        let registered = CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error)

        if !registered {
            if let cfError = error?.takeRetainedValue() {
                let nsError = cfError as Error as NSError
                // Code 105 = already registered, which is fine
                XCTAssertEqual(nsError.code, 105, "If registration fails, it should be because font is already registered (code 105), got code \(nsError.code): \(nsError.localizedDescription)")
            } else {
                XCTFail("Font registration failed with no error details")
            }
        }

        // Verify we can create descriptors from the URL
        let descriptors = CTFontManagerCreateFontDescriptorsFromURL(fontURL as CFURL) as? [CTFontDescriptor]
        XCTAssertNotNil(descriptors, "Should be able to create font descriptors from URL")
        XCTAssertFalse(descriptors?.isEmpty ?? true, "Descriptors array should not be empty")
    }

    // MARK: - Step 3: CTFont creation

    func testCTFontCreation() throws {
        guard let fontURL = Bundle.module.url(forResource: "Bravura", withExtension: "otf", subdirectory: "Fonts/Bravura")
            ?? Bundle.module.url(forResource: "Bravura", withExtension: "otf") else {
            throw XCTSkip("Bravura.otf not found")
        }

        // Register (ignore already-registered error)
        CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)

        guard let descriptors = CTFontManagerCreateFontDescriptorsFromURL(fontURL as CFURL) as? [CTFontDescriptor],
              let descriptor = descriptors.first else {
            XCTFail("Cannot create font descriptors")
            return
        }

        let ctFont = CTFontCreateWithFontDescriptor(descriptor, 0, nil)
        let fontName = CTFontCopyPostScriptName(ctFont) as String
        let defaultSize = CTFontGetSize(ctFont)

        print("Created CTFont: name=\(fontName), defaultSize=\(defaultSize)")
        XCTAssertFalse(fontName.isEmpty, "Font should have a PostScript name")

        // Test creating a sized version
        let sizedFont = CTFontCreateCopyWithAttributes(ctFont, 40, nil, nil)
        let sizedFontSize = CTFontGetSize(sizedFont)
        XCTAssertEqual(sizedFontSize, 40, accuracy: 0.1, "Sized font should be 40pt")
    }

    // MARK: - Step 4: SMuFLFontManager.loadBundledFont()

    func testLoadBundledFontSucceeds() throws {
        let font = try SMuFLFontManager.shared.loadBundledFont()
        XCTAssertEqual(font.name, "Bravura")
        XCTAssertNotNil(font.ctFont, "Loaded font should have a CTFont")
        print("loadBundledFont() succeeded: name=\(font.name), ctFontSize=\(CTFontGetSize(font.ctFont))")
    }

    func testLoadBundledFontIdempotent() throws {
        // Should succeed on repeated calls (no "already registered" crash)
        let font1 = try SMuFLFontManager.shared.loadBundledFont()
        let font2 = try SMuFLFontManager.shared.loadBundledFont()
        XCTAssertEqual(font1.name, font2.name)
    }

    // MARK: - Step 5: Glyph lookup by codepoint

    func testGlyphLookupByCorePointWorks() throws {
        let font = try SMuFLFontManager.shared.loadBundledFont()

        // G Clef = U+E050
        let gClef = font.glyph(for: .gClef)
        XCTAssertNotNil(gClef, "gClef (U+E050) glyph lookup should succeed")
        if let g = gClef {
            XCTAssertNotEqual(g, 0, "gClef glyph ID should not be 0")
            print("gClef glyph ID: \(g)")
        }

        // Black notehead = U+E0A4
        let notehead = font.glyph(for: .noteheadBlack)
        XCTAssertNotNil(notehead, "noteheadBlack (U+E0A4) glyph lookup should succeed")
        if let n = notehead {
            XCTAssertNotEqual(n, 0, "noteheadBlack glyph ID should not be 0")
            print("noteheadBlack glyph ID: \(n)")
        }

        // Percussion clef (unpitchedPercussionClef1)
        let percClef = font.glyph(for: .unpitchedPercussionClef1)
        XCTAssertNotNil(percClef, "unpitchedPercussionClef1 glyph lookup should succeed")
        if let p = percClef {
            print("percussionClef glyph ID: \(p)")
        }

        // Time signature digits
        let timeSig4 = font.glyph(for: .timeSig4)
        XCTAssertNotNil(timeSig4, "timeSig4 glyph lookup should succeed")

        // X notehead (for hi-hat)
        let noteheadX = font.glyph(for: .noteheadXBlack)
        XCTAssertNotNil(noteheadX, "noteheadXBlack glyph lookup should succeed")
    }

    func testGlyphLookupVsOldApproach() throws {
        let font = try SMuFLFontManager.shared.loadBundledFont()

        // The OLD broken approach: CTFontGetGlyphWithName
        let glyphNameString = "gClef" as CFString
        let oldGlyph = CTFontGetGlyphWithName(font.ctFont, glyphNameString)

        // The NEW correct approach: font.glyph(for:)
        let newGlyph = font.glyph(for: .gClef)

        print("OLD approach (CTFontGetGlyphWithName 'gClef'): \(oldGlyph)")
        print("NEW approach (font.glyph(for: .gClef)): \(newGlyph ?? 0)")

        // The old approach likely returns 0 (not found by PostScript name)
        // The new approach should return a valid glyph
        XCTAssertNotNil(newGlyph, "New approach should find the glyph")
        if oldGlyph == 0 {
            print("CONFIRMED: CTFontGetGlyphWithName returns 0 for SMuFL glyph names — old approach was broken!")
        }
    }

    // MARK: - Step 6: font(forStaffHeight:) produces correctly sized font

    func testFontForStaffHeight() throws {
        let font = try SMuFLFontManager.shared.loadBundledFont()
        let sizedFont = font.font(forStaffHeight: 40)
        let size = CTFontGetSize(sizedFont)
        XCTAssertEqual(size, 40, accuracy: 0.1, "Font sized for 40pt staff height should be 40pt")

        // Verify glyphs can still be looked up with the sized font
        let glyphName = SMuFLGlyphName.noteheadBlack
        guard let glyph = font.glyph(for: glyphName) else {
            XCTFail("Glyph lookup failed")
            return
        }

        // Get bounding box with the sized font to verify it's reasonable
        var glyphCG = glyph
        var rect = CTFontGetBoundingRectsForGlyphs(sizedFont, .default, &glyphCG, nil, 1)
        print("noteheadBlack bounding box at 40pt: \(rect)")
        XCTAssertGreaterThan(rect.width, 1, "Notehead at 40pt should be wider than 1pt")
        XCTAssertGreaterThan(rect.height, 1, "Notehead at 40pt should be taller than 1pt")

        // Compare with base-size font
        rect = CTFontGetBoundingRectsForGlyphs(font.ctFont, .default, &glyphCG, nil, 1)
        print("noteheadBlack bounding box at base size (\(CTFontGetSize(font.ctFont))pt): \(rect)")
    }

    // MARK: - Step 7: CTFontDrawGlyphs actually draws pixels

    func testCTFontDrawGlyphsProducesPixels() throws {
        let font = try SMuFLFontManager.shared.loadBundledFont()
        let sizedFont = font.font(forStaffHeight: 40)

        guard var glyph = font.glyph(for: .noteheadBlack) else {
            XCTFail("Glyph lookup failed")
            return
        }

        // Create a bitmap context
        let width = 100
        let height = 100
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            XCTFail("Cannot create bitmap context")
            return
        }

        // Fill with white
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Draw the glyph in black at center
        context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
        var position = CGPoint(x: 50, y: 50)
        CTFontDrawGlyphs(sizedFont, &glyph, &position, 1, context)

        // Check if any pixels changed from white
        guard let data = context.data else {
            XCTFail("Cannot access bitmap data")
            return
        }

        let pixelData = data.assumingMemoryBound(to: UInt8.self)
        var nonWhitePixels = 0
        for i in stride(from: 0, to: width * height * 4, by: 4) {
            let r = pixelData[i]
            let g = pixelData[i + 1]
            let b = pixelData[i + 2]
            if r < 250 || g < 250 || b < 250 {
                nonWhitePixels += 1
            }
        }

        print("CTFontDrawGlyphs produced \(nonWhitePixels) non-white pixels out of \(width * height)")
        XCTAssertGreaterThan(nonWhitePixels, 0, "CTFontDrawGlyphs should have drawn SOME pixels")
    }
}
