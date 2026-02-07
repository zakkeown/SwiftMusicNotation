import XCTest
import CoreGraphics
import CoreText
@testable import MusicNotationRenderer
@testable import MusicNotationLayout
@testable import MusicNotationCore
@testable import SMuFLKit

/// End-to-end diagnostic tests for the rendering pipeline.
/// Tests each stage: Score → Layout → EngravedScore → Renderer → Pixels.
final class RenderPipelineDiagnosticTests: XCTestCase {

    // MARK: - Helpers

    private func loadFont() throws -> LoadedSMuFLFont {
        try SMuFLFontManager.shared.loadBundledFont()
    }

    private func makeBitmapContext(width: Int = 800, height: Int = 600) -> CGContext? {
        CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: width * 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )
    }

    private func countNonWhitePixels(in context: CGContext) -> Int {
        guard let data = context.data else { return 0 }
        let pixelData = data.assumingMemoryBound(to: UInt8.self)
        let total = context.width * context.height
        var count = 0
        for i in stride(from: 0, to: total * 4, by: 4) {
            if pixelData[i] < 250 || pixelData[i + 1] < 250 || pixelData[i + 2] < 250 {
                count += 1
            }
        }
        return count
    }

    // MARK: - Step 1: Layout engine produces elements

    func testLayoutEngineProducesElements() throws {
        let score = makeSimpleScore()
        let engine = LayoutEngine()
        let context = LayoutContext.letterSize(staffHeight: 40)
        let engraved = engine.layout(score: score, context: context)

        XCTAssertFalse(engraved.pages.isEmpty, "Should have at least one page")

        let page = engraved.pages[0]
        XCTAssertFalse(page.systems.isEmpty, "Page should have at least one system")
        print("Page 0: \(page.systems.count) systems, \(page.credits.count) credits")
        print("Page frame: \(page.frame)")

        let system = page.systems[0]
        XCTAssertFalse(system.measures.isEmpty, "System should have measures")
        XCTAssertFalse(system.staves.isEmpty, "System should have staves")
        print("System 0: \(system.measures.count) measures, \(system.staves.count) staves")
        print("System frame: \(system.frame)")

        var totalElements = 0
        for measure in system.measures {
            for (staffNum, elements) in measure.elementsByStaff {
                print("  Measure \(measure.measureNumber), staff \(staffNum): \(elements.count) elements")
                for element in elements {
                    print("    \(element)")
                    totalElements += 1
                }
            }
        }

        XCTAssertGreaterThan(totalElements, 0, "Should have some engraved elements (clefs, notes, etc.)")
    }

    // MARK: - Step 2: MusicRenderer.render() with font = nil draws structural elements only

    func testRendererWithNilFontDrawsStructuralElements() throws {
        let score = makeSimpleScore()
        let engine = LayoutEngine()
        let layoutContext = LayoutContext.letterSize(staffHeight: 40)
        let engraved = engine.layout(score: score, context: layoutContext)

        guard let context = makeBitmapContext() else {
            XCTFail("Cannot create bitmap context")
            return
        }

        // Fill white
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 800, height: 600))

        // Render with NO font
        let renderer = MusicRenderer()
        renderer.font = nil
        renderer.render(score: engraved, pageIndex: 0, in: context)

        let pixels = countNonWhitePixels(in: context)
        print("Renderer with nil font: \(pixels) non-white pixels")
        // Should still draw staff lines and barlines
        XCTAssertGreaterThan(pixels, 0, "Even without font, staff lines should be drawn")
    }

    // MARK: - Step 3: MusicRenderer.render() with font draws glyphs too

    func testRendererWithFontDrawsMorePixels() throws {
        let font = try loadFont()
        let score = makeSimpleScore()
        let engine = LayoutEngine()
        let layoutContext = LayoutContext.letterSize(staffHeight: 40)
        let engraved = engine.layout(score: score, context: layoutContext)

        // Render WITHOUT font
        guard let ctxNoFont = makeBitmapContext() else { XCTFail(""); return }
        ctxNoFont.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        ctxNoFont.fill(CGRect(x: 0, y: 0, width: 800, height: 600))
        let rendererNoFont = MusicRenderer()
        rendererNoFont.font = nil
        rendererNoFont.render(score: engraved, pageIndex: 0, in: ctxNoFont)
        let pixelsNoFont = countNonWhitePixels(in: ctxNoFont)

        // Render WITH font
        guard let ctxWithFont = makeBitmapContext() else { XCTFail(""); return }
        ctxWithFont.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        ctxWithFont.fill(CGRect(x: 0, y: 0, width: 800, height: 600))
        let rendererWithFont = MusicRenderer()
        rendererWithFont.font = font
        rendererWithFont.render(score: engraved, pageIndex: 0, in: ctxWithFont)
        let pixelsWithFont = countNonWhitePixels(in: ctxWithFont)

        print("Pixels without font: \(pixelsNoFont)")
        print("Pixels with font: \(pixelsWithFont)")
        print("Difference: \(pixelsWithFont - pixelsNoFont)")

        XCTAssertGreaterThan(pixelsWithFont, pixelsNoFont,
                             "Rendering with font should produce MORE pixels than without (glyphs should add pixels)")
    }

    // MARK: - Step 4: Verify drum score specifically

    func testDrumScoreLayout() throws {
        let score = makeDrumScore()
        let engine = LayoutEngine()
        let layoutContext = LayoutContext.letterSize(staffHeight: 40)
        let engraved = engine.layout(score: score, context: layoutContext)

        XCTAssertFalse(engraved.pages.isEmpty, "Drum score should produce pages")

        let page = engraved.pages[0]
        print("Drum score - Page 0: systems=\(page.systems.count)")

        for (sysIdx, system) in page.systems.enumerated() {
            print("  System \(sysIdx): measures=\(system.measures.count), staves=\(system.staves.count)")
            for measure in system.measures {
                let totalElements = measure.elementsByStaff.values.reduce(0) { $0 + $1.count }
                print("    Measure \(measure.measureNumber): \(totalElements) total elements")
                for (staffNum, elements) in measure.elementsByStaff.sorted(by: { $0.key < $1.key }) {
                    for element in elements {
                        switch element {
                        case .clef(let c):
                            print("      staff \(staffNum): CLEF \(c.glyph.rawValue) at \(c.position)")
                        case .timeSignature(let ts):
                            print("      staff \(staffNum): TIME SIG at \(ts.position), topGlyphs=\(ts.topGlyphs.count)")
                        case .note(let n):
                            print("      staff \(staffNum): NOTE \(n.noteheadGlyph.rawValue) at \(n.position)")
                        case .rest(let r):
                            print("      staff \(staffNum): REST \(r.glyph.rawValue) at \(r.position)")
                        case .chord(let ch):
                            print("      staff \(staffNum): CHORD with \(ch.notes.count) notes")
                        case .barline(let b):
                            print("      staff \(staffNum): BARLINE at x=\(b.frame.origin.x)")
                        case .direction(let d):
                            print("      staff \(staffNum): DIRECTION at \(d.position)")
                        default:
                            print("      staff \(staffNum): OTHER \(element)")
                        }
                    }
                }
            }
        }
    }

    func testDrumScoreRendersGlyphs() throws {
        let font = try loadFont()
        let score = makeDrumScore()
        let engine = LayoutEngine()
        let layoutContext = LayoutContext.letterSize(staffHeight: 40)
        let engraved = engine.layout(score: score, context: layoutContext)

        guard let context = makeBitmapContext() else { XCTFail(""); return }
        context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: 800, height: 600))

        let renderer = MusicRenderer()
        renderer.font = font
        renderer.render(score: engraved, pageIndex: 0, in: context)

        let pixels = countNonWhitePixels(in: context)
        print("Drum score render: \(pixels) non-white pixels")
        XCTAssertGreaterThan(pixels, 100, "Drum score should render substantial content")
    }

    // MARK: - Step 5: Two-measure drum score layout diagnostic

    func testTwoMeasureDrumScorePositions() throws {
        let score = makeTwoMeasureDrumScore()
        let engine = LayoutEngine()
        let layoutContext = LayoutContext.letterSize(staffHeight: 40)
        let engraved = engine.layout(score: score, context: layoutContext)

        let page = engraved.pages[0]
        let system = page.systems[0]

        print("=== TWO-MEASURE DRUM SCORE DIAGNOSTIC ===")
        print("System frame: \(system.frame)")
        print("System measures: \(system.measures.count)")
        print("System staves: \(system.staves.count)")

        for staff in system.staves {
            print("  Staff \(staff.staffNumber): frame=\(staff.frame), centerLineY=\(staff.centerLineY), staffHeight=\(staff.staffHeight)")
        }

        for measure in system.measures {
            print("\n--- Measure \(measure.measureNumber) ---")
            print("  frame: \(measure.frame)")
            print("  leftBarlineX: \(measure.leftBarlineX)")
            print("  rightBarlineX: \(measure.rightBarlineX)")

            for (staffNum, elements) in measure.elementsByStaff.sorted(by: { $0.key < $1.key }) {
                print("  Staff \(staffNum): \(elements.count) elements")
                for element in elements {
                    switch element {
                    case .clef(let c):
                        print("    CLEF \(c.glyph.rawValue) at \(c.position)")
                    case .timeSignature(let ts):
                        print("    TIME_SIG at \(ts.position)")
                        for (g, p) in ts.topGlyphs { print("      top: \(g.rawValue) at \(p)") }
                        for (g, p) in ts.bottomGlyphs { print("      bot: \(g.rawValue) at \(p)") }
                    case .note(let n):
                        let stemInfo: String
                        if let s = n.stem {
                            stemInfo = "stem(\(s.direction)==\(s.direction == .up ? "up" : "dn") \(s.start)->\(s.end))"
                        } else {
                            stemInfo = "no stem"
                        }
                        print("    NOTE \(n.noteheadGlyph.rawValue) at \(n.position) staffPos=\(n.staffPosition) \(stemInfo)")
                    case .rest(let r):
                        print("    REST \(r.glyph.rawValue) at \(r.position)")
                    default:
                        print("    OTHER \(element)")
                    }
                }
            }
        }

        // Verify: measure 1 should have clef + time sig + notes
        let m1Elements = system.measures[0].elementsByStaff[1] ?? []
        let m1Clefs = m1Elements.filter { if case .clef = $0 { return true }; return false }
        let m1TimeSigs = m1Elements.filter { if case .timeSignature = $0 { return true }; return false }
        let m1Notes = m1Elements.filter { if case .note = $0 { return true }; return false }

        XCTAssertEqual(m1Clefs.count, 1, "Measure 1 should have 1 clef")
        XCTAssertEqual(m1TimeSigs.count, 1, "Measure 1 should have 1 time signature")
        XCTAssertGreaterThan(m1Notes.count, 0, "Measure 1 should have notes")

        // Verify: measure 2 should have notes but NO clef/time sig
        let m2Elements = system.measures[1].elementsByStaff[1] ?? []
        let m2Clefs = m2Elements.filter { if case .clef = $0 { return true }; return false }
        let m2TimeSigs = m2Elements.filter { if case .timeSignature = $0 { return true }; return false }
        let m2Notes = m2Elements.filter { if case .note = $0 { return true }; return false }

        XCTAssertEqual(m2Clefs.count, 0, "Measure 2 should have NO clef")
        XCTAssertEqual(m2TimeSigs.count, 0, "Measure 2 should have NO time signature")
        XCTAssertGreaterThan(m2Notes.count, 0, "Measure 2 should have notes")

        // Verify: all measure 1 notes are within measure 1's frame
        let m1Frame = system.measures[0].frame
        for element in m1Elements {
            let bbox = element.boundingBox
            let noteCenter: CGPoint
            switch element {
            case .note(let n): noteCenter = n.position
            case .clef(let c): noteCenter = c.position
            case .timeSignature(let ts): noteCenter = ts.position
            default: continue
            }
            XCTAssertGreaterThanOrEqual(noteCenter.x, 0,
                "M1 element at \(noteCenter) should have x >= 0")
            XCTAssertLessThanOrEqual(noteCenter.x, m1Frame.width,
                "M1 element at \(noteCenter) should have x <= measure width \(m1Frame.width)")
        }

        // Verify: all measure 2 notes are within measure 2's frame
        let m2Frame = system.measures[1].frame
        for element in m2Elements {
            let noteCenter: CGPoint
            switch element {
            case .note(let n): noteCenter = n.position
            case .clef(let c): noteCenter = c.position
            case .timeSignature(let ts): noteCenter = ts.position
            default: continue
            }
            XCTAssertGreaterThanOrEqual(noteCenter.x, 0,
                "M2 element at \(noteCenter) should have x >= 0")
            XCTAssertLessThanOrEqual(noteCenter.x, m2Frame.width,
                "M2 element at \(noteCenter) should have x <= measure width \(m2Frame.width)")
        }

        print("\n=== SUMMARY ===")
        print("M1: \(m1Clefs.count) clef, \(m1TimeSigs.count) timeSig, \(m1Notes.count) notes in frame \(m1Frame)")
        print("M2: \(m2Clefs.count) clef, \(m2TimeSigs.count) timeSig, \(m2Notes.count) notes in frame \(m2Frame)")
    }

    // MARK: - Step 6: Bitmap rendering check for both measures

    func testBitmapRenderBothMeasures() throws {
        let score = makeTwoMeasureDrumScore()
        let font = try loadFont()
        let engine = LayoutEngine()
        let layoutContext = LayoutContext.letterSize(staffHeight: 40)
        let engraved = engine.layout(score: score, context: layoutContext)

        let width = 800
        let height = 400
        guard let ctx = makeBitmapContext(width: width, height: height) else {
            XCTFail("Cannot create bitmap context")
            return
        }

        // Fill with white
        ctx.setFillColor(CGColor(gray: 1, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Flip context to simulate NSView isFlipped = true (top-left origin)
        ctx.translateBy(x: 0, y: CGFloat(height))
        ctx.scaleBy(x: 1, y: -1)

        // Render using MusicRenderer (same code path as ScoreView)
        let renderer = MusicRenderer()
        renderer.font = font
        renderer.render(score: engraved, pageIndex: 0, in: ctx)

        // Read pixel data
        guard let data = ctx.data else {
            XCTFail("Cannot access bitmap data")
            return
        }
        let pixelData = data.assumingMemoryBound(to: UInt8.self)

        // System origin x=72, M1 width=174 (72..246), M2 starts at 246 width=104 (246..350)
        // But elements also extend above/below the staff (y-wise). We check all Y rows.
        let m1XRange = 72..<246
        let m2XRange = 246..<350

        // Count non-white pixels in each measure's X range
        var m1Pixels = 0
        var m2Pixels = 0
        var m1GlyphRegionPixels = 0  // x in 72..170 (clef + time sig + first notes area, excludes barline overlap with m2)

        for y in 0..<height {
            for x in 0..<width {
                let i = (y * width + x) * 4
                let r = pixelData[i]
                let g = pixelData[i + 1]
                let b = pixelData[i + 2]
                if r < 250 || g < 250 || b < 250 {
                    if m1XRange.contains(x) {
                        m1Pixels += 1
                        if x < 170 {
                            m1GlyphRegionPixels += 1
                        }
                    } else if m2XRange.contains(x) {
                        m2Pixels += 1
                    }
                }
            }
        }

        print("=== BITMAP RENDERING DIAGNOSTIC ===")
        print("Measure 1 region (x:\(m1XRange)): \(m1Pixels) non-white pixels")
        print("  M1 glyph area (x:72..<170): \(m1GlyphRegionPixels) non-white pixels")
        print("Measure 2 region (x:\(m2XRange)): \(m2Pixels) non-white pixels")

        // Both measures should have substantial pixel content
        XCTAssertGreaterThan(m1Pixels, 100, "Measure 1 should have substantial pixel content")
        XCTAssertGreaterThan(m2Pixels, 100, "Measure 2 should have substantial pixel content")

        // The glyph area of measure 1 (clef + time sig + notes) should have pixels
        // This is the region where the user reported missing glyphs
        XCTAssertGreaterThan(m1GlyphRegionPixels, 50,
            "Measure 1 glyph area (clef/timesig/notes) should have pixels")

        // Save bitmap as PNG for visual inspection
        if let image = ctx.makeImage() {
            let desktopURL = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Desktop")
                .appendingPathComponent("drum_score_render.png")
            if let dest = CGImageDestinationCreateWithURL(desktopURL as CFURL, "public.png" as CFString, 1, nil) {
                CGImageDestinationAddImage(dest, image, nil)
                CGImageDestinationFinalize(dest)
                print("Saved render to: \(desktopURL.path)")
            }
        }
    }

    // MARK: - Step 7: Single glyph position verification

    /// Draws a glyph at a known position and a crosshair at the same position,
    /// then compares their pixel bounding boxes to verify glyph placement.
    func testGlyphPositionAccuracy() throws {
        let font = try loadFont()
        let sizedFont = font.font(forStaffHeight: 40)

        let width = 200
        let height = 200
        guard let ctx = makeBitmapContext(width: width, height: height) else {
            XCTFail("Cannot create bitmap context")
            return
        }

        // Fill white
        ctx.setFillColor(CGColor(gray: 1, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Flip to simulate isFlipped=true
        ctx.translateBy(x: 0, y: CGFloat(height))
        ctx.scaleBy(x: 1, y: -1)

        let targetPos = CGPoint(x: 100, y: 100)

        // 1. Draw the glyph using the EXACT same pattern as renderGlyph
        guard var glyph = font.glyph(for: .noteheadBlack) else {
            XCTFail("Cannot get notehead glyph")
            return
        }

        ctx.saveGState()
        ctx.setFillColor(CGColor(gray: 0, alpha: 1))
        ctx.translateBy(x: targetPos.x, y: targetPos.y)
        ctx.scaleBy(x: 1, y: -1)
        var glyphPosition = CGPoint.zero
        CTFontDrawGlyphs(sizedFont, &glyph, &glyphPosition, 1, ctx)
        ctx.restoreGState()

        // 2. Draw a RED crosshair at the same position using PLAIN CG drawing
        //    (same drawing approach as renderStem — no scaleBy involved)
        ctx.saveGState()
        ctx.setStrokeColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        ctx.setLineWidth(2)
        // Horizontal line through target
        ctx.move(to: CGPoint(x: targetPos.x - 15, y: targetPos.y))
        ctx.addLine(to: CGPoint(x: targetPos.x + 15, y: targetPos.y))
        // Vertical line through target
        ctx.move(to: CGPoint(x: targetPos.x, y: targetPos.y - 15))
        ctx.addLine(to: CGPoint(x: targetPos.x, y: targetPos.y + 15))
        ctx.strokePath()
        ctx.restoreGState()

        // 3. Analyze pixel positions
        guard let data = ctx.data else {
            XCTFail("Cannot access bitmap data")
            return
        }
        let pixelData = data.assumingMemoryBound(to: UInt8.self)

        // Find bounding box of BLACK pixels (glyph) and RED pixels (crosshair)
        var glyphMinX = width, glyphMaxX = 0, glyphMinY = height, glyphMaxY = 0
        var crossMinX = width, crossMaxX = 0, crossMinY = height, crossMaxY = 0

        for y in 0..<height {
            for x in 0..<width {
                let i = (y * width + x) * 4
                let r = pixelData[i]
                let g = pixelData[i + 1]
                let b = pixelData[i + 2]

                // Black pixel (glyph): R<50, G<50, B<50
                if r < 50 && g < 50 && b < 50 {
                    glyphMinX = min(glyphMinX, x)
                    glyphMaxX = max(glyphMaxX, x)
                    glyphMinY = min(glyphMinY, y)
                    glyphMaxY = max(glyphMaxY, y)
                }

                // Red pixel (crosshair): R>200, G<50, B<50
                if r > 200 && g < 50 && b < 50 {
                    crossMinX = min(crossMinX, x)
                    crossMaxX = max(crossMaxX, x)
                    crossMinY = min(crossMinY, y)
                    crossMaxY = max(crossMaxY, y)
                }
            }
        }

        let glyphCenterX = (glyphMinX + glyphMaxX) / 2
        let glyphCenterY = (glyphMinY + glyphMaxY) / 2
        let crossCenterX = (crossMinX + crossMaxX) / 2
        let crossCenterY = (crossMinY + crossMaxY) / 2

        print("=== SINGLE GLYPH POSITION TEST ===")
        print("Target position: \(targetPos)")
        print("Glyph (black) pixel bbox: x=\(glyphMinX)..\(glyphMaxX), y=\(glyphMinY)..\(glyphMaxY)")
        print("Glyph center: (\(glyphCenterX), \(glyphCenterY))")
        print("Crosshair (red) pixel bbox: x=\(crossMinX)..\(crossMaxX), y=\(crossMinY)..\(crossMaxY)")
        print("Crosshair center: (\(crossCenterX), \(crossCenterY))")
        print("Offset glyph-vs-crosshair: dx=\(glyphCenterX - crossCenterX), dy=\(glyphCenterY - crossCenterY)")
        print("Offset glyph-left-vs-target: \(glyphMinX - Int(targetPos.x))")

        // The crosshair center should be at (100, 100)
        XCTAssertEqual(crossCenterX, Int(targetPos.x), accuracy: 2,
            "Crosshair X center should be at target X")
        XCTAssertEqual(crossCenterY, Int(targetPos.y), accuracy: 2,
            "Crosshair Y center should be at target Y")

        // The glyph left edge should be near the target X (SMuFL origin is at left edge)
        XCTAssertEqual(glyphMinX, Int(targetPos.x), accuracy: 5,
            "Glyph left edge should be near target X (within 5px)")

        // Save for visual inspection
        if let image = ctx.makeImage() {
            let url = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Desktop")
                .appendingPathComponent("glyph_position_test.png")
            if let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) {
                CGImageDestinationAddImage(dest, image, nil)
                CGImageDestinationFinalize(dest)
                print("Saved to: \(url.path)")
            }
        }
    }

    /// Tests if rendering ALL elements at their layout positions produces
    /// correctly positioned output — verifies stem vs glyph alignment.
    func testStemVsGlyphAlignment() throws {
        let font = try loadFont()
        let sizedFont = font.font(forStaffHeight: 40)

        let width = 300
        let height = 200
        guard let ctx = makeBitmapContext(width: width, height: height) else {
            XCTFail("Cannot create bitmap context"); return
        }

        // Fill white, flip
        ctx.setFillColor(CGColor(gray: 1, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))
        ctx.translateBy(x: 0, y: CGFloat(height))
        ctx.scaleBy(x: 1, y: -1)

        // Simulate a note at position (50, 100) with stem up
        let noteX: CGFloat = 50
        let noteY: CGFloat = 100
        let noteheadWidth: CGFloat = 11.8 // 1.18 * staffSpace(10)
        let stemX: CGFloat = noteX + noteheadWidth
        let stemTopY: CGFloat = noteY - 35 // 3.5 staff spaces up

        // Draw notehead glyph (same as renderGlyph)
        guard var glyph = font.glyph(for: .noteheadBlack) else {
            XCTFail("Cannot get glyph"); return
        }
        ctx.saveGState()
        ctx.setFillColor(CGColor(gray: 0, alpha: 1))
        ctx.translateBy(x: noteX, y: noteY)
        ctx.scaleBy(x: 1, y: -1)
        var glyphPos = CGPoint.zero
        CTFontDrawGlyphs(sizedFont, &glyph, &glyphPos, 1, ctx)
        ctx.restoreGState()

        // Draw stem (same as renderStem)
        ctx.saveGState()
        ctx.setStrokeColor(CGColor(gray: 0, alpha: 1))
        ctx.setLineWidth(0.8)
        ctx.move(to: CGPoint(x: stemX, y: noteY))
        ctx.addLine(to: CGPoint(x: stemX, y: stemTopY))
        ctx.strokePath()
        ctx.restoreGState()

        // Draw RED reference markers at key positions
        ctx.saveGState()
        ctx.setStrokeColor(CGColor(red: 1, green: 0, blue: 0, alpha: 1))
        ctx.setLineWidth(1)
        // Mark noteX
        ctx.move(to: CGPoint(x: noteX, y: noteY - 3))
        ctx.addLine(to: CGPoint(x: noteX, y: noteY + 3))
        // Mark noteX + noteheadWidth
        ctx.move(to: CGPoint(x: noteX + noteheadWidth, y: noteY - 3))
        ctx.addLine(to: CGPoint(x: noteX + noteheadWidth, y: noteY + 3))
        ctx.strokePath()
        ctx.restoreGState()

        // Second note at (150, 100) for comparison
        let noteX2: CGFloat = 150
        guard var glyph2 = font.glyph(for: .noteheadBlack) else { return }

        ctx.saveGState()
        ctx.setFillColor(CGColor(gray: 0, alpha: 1))
        ctx.translateBy(x: noteX2, y: noteY)
        ctx.scaleBy(x: 1, y: -1)
        var glyphPos2 = CGPoint.zero
        CTFontDrawGlyphs(sizedFont, &glyph2, &glyphPos2, 1, ctx)
        ctx.restoreGState()

        // Stem for second note
        let stemX2 = noteX2 + noteheadWidth
        ctx.saveGState()
        ctx.setStrokeColor(CGColor(gray: 0, alpha: 1))
        ctx.setLineWidth(0.8)
        ctx.move(to: CGPoint(x: stemX2, y: noteY))
        ctx.addLine(to: CGPoint(x: stemX2, y: stemTopY))
        ctx.strokePath()
        ctx.restoreGState()

        // Analyze: find pixel bounds for each note
        guard let data = ctx.data else { return }
        let pixelData = data.assumingMemoryBound(to: UInt8.self)

        // Count black pixels in columns around each note to verify alignment
        print("=== STEM VS GLYPH ALIGNMENT ===")
        print("Note 1 at x=\(noteX), stem at x=\(stemX)")
        print("Note 2 at x=\(noteX2), stem at x=\(stemX2)")

        // Find leftmost black pixel in each note region
        var note1LeftmostX = width
        var note2LeftmostX = width
        let yRange = 90..<110 // Around noteY=100

        for y in yRange {
            for x in 0..<width {
                let i = (y * width + x) * 4
                let r = pixelData[i]; let g = pixelData[i+1]; let b = pixelData[i+2]
                if r < 50 && g < 50 && b < 50 {
                    if x < 120 { note1LeftmostX = min(note1LeftmostX, x) }
                    else if x > 120 { note2LeftmostX = min(note2LeftmostX, x) }
                }
            }
        }

        print("Note 1 leftmost black pixel (near y=100): x=\(note1LeftmostX) (expected ~\(Int(noteX)))")
        print("Note 2 leftmost black pixel (near y=100): x=\(note2LeftmostX) (expected ~\(Int(noteX2)))")
        print("Note 1 offset from expected: \(note1LeftmostX - Int(noteX))px")
        print("Note 2 offset from expected: \(note2LeftmostX - Int(noteX2))px")

        // Glyph left edge should be within a few pixels of noteX
        XCTAssertEqual(note1LeftmostX, Int(noteX), accuracy: 3,
            "Note 1 glyph left edge should align with noteX")
        XCTAssertEqual(note2LeftmostX, Int(noteX2), accuracy: 3,
            "Note 2 glyph left edge should align with noteX2")

        // Save
        if let image = ctx.makeImage() {
            let url = FileManager.default.homeDirectoryForCurrentUser
                .appendingPathComponent("Desktop")
                .appendingPathComponent("stem_glyph_alignment.png")
            if let dest = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) {
                CGImageDestinationAddImage(dest, image, nil)
                CGImageDestinationFinalize(dest)
                print("Saved to: \(url.path)")
            }
        }
    }

    // MARK: - Step 8: Pixel-column analysis for precise position mapping

    func testPixelColumnAnalysis() throws {
        let score = makeTwoMeasureDrumScore()
        let font = try loadFont()
        let engine = LayoutEngine()
        let layoutContext = LayoutContext.letterSize(staffHeight: 40)
        let engraved = engine.layout(score: score, context: layoutContext)

        let width = 600
        let height = 300
        guard let ctx = makeBitmapContext(width: width, height: height) else {
            XCTFail("Cannot create bitmap context")
            return
        }

        // Fill white
        ctx.setFillColor(CGColor(gray: 1, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: width, height: height))

        // Flip to simulate isFlipped=true NSView
        ctx.translateBy(x: 0, y: CGFloat(height))
        ctx.scaleBy(x: 1, y: -1)

        let renderer = MusicRenderer()
        renderer.font = font
        renderer.render(score: engraved, pageIndex: 0, in: ctx)

        guard let data = ctx.data else {
            XCTFail("Cannot access bitmap data")
            return
        }
        let pixelData = data.assumingMemoryBound(to: UInt8.self)

        // Count non-white pixels per X column
        var columnCounts: [Int] = Array(repeating: 0, count: width)
        for y in 0..<height {
            for x in 0..<width {
                let i = (y * width + x) * 4
                let r = pixelData[i]
                let g = pixelData[i + 1]
                let b = pixelData[i + 2]
                if r < 250 || g < 250 || b < 250 {
                    columnCounts[x] += 1
                }
            }
        }

        // Find X ranges with significant pixel content (>3 pixels in column)
        print("=== PIXEL COLUMN ANALYSIS ===")
        print("Expected layout:")
        let system = engraved.pages[0].systems[0]
        let sysX = Int(system.frame.origin.x)
        let m1W = Int(system.measures[0].frame.width)
        let m2X = Int(system.measures[1].frame.origin.x)
        let m2W = Int(system.measures[1].frame.width)
        print("  System origin x=\(sysX)")
        print("  M1: x=\(sysX)...\(sysX + m1W) (width \(m1W))")
        print("  M2: x=\(sysX + m2X)...\(sysX + m2X + m2W) (width \(m2W))")

        // Print column counts in ranges
        print("\nPixel density by x-region:")
        let ranges: [(String, Range<Int>)] = [
            ("Left margin (0..72)", 0..<72),
            ("M1 clef area (72..92)", 72..<92),
            ("M1 timeSig area (92..142)", 92..<142),
            ("M1 notes area (142..246)", 142..<246),
            ("M2 notes area (246..350)", 246..<350),
            ("Empty staff (350..540)", 350..<min(540, width)),
            ("Right margin (540+)", min(540, width)..<width),
        ]

        for (label, range) in ranges {
            let total = range.reduce(0) { $0 + columnCounts[$1] }
            let maxCol = range.max(by: { columnCounts[$0] < columnCounts[$1] }) ?? range.lowerBound
            print("  \(label): \(total) pixels, peak=\(columnCounts[maxCol]) at x=\(maxCol)")
        }

        // Print a visual ASCII density map (one char per 5 columns)
        print("\nASCII pixel density (each char = 5 columns, '.' = 0, '#' = high):")
        var ascii = ""
        for x in stride(from: 0, to: min(600, width), by: 5) {
            let sum = (x..<min(x+5, width)).reduce(0) { $0 + columnCounts[$1] }
            if sum == 0 {
                ascii += "."
            } else if sum < 10 {
                ascii += "'"
            } else if sum < 50 {
                ascii += ":"
            } else if sum < 100 {
                ascii += "+"
            } else {
                ascii += "#"
            }
        }
        print("  |\(ascii)|")
        print("  0    50   100  150  200  250  300  350  400  450  500  550")

        // Now render WITHOUT flip to compare positions
        guard let ctx2 = makeBitmapContext(width: width, height: height) else { return }
        ctx2.setFillColor(CGColor(gray: 1, alpha: 1))
        ctx2.fill(CGRect(x: 0, y: 0, width: width, height: height))
        // NO FLIP - standard bottom-left origin
        let renderer2 = MusicRenderer()
        renderer2.font = font
        renderer2.render(score: engraved, pageIndex: 0, in: ctx2)

        guard let data2 = ctx2.data else { return }
        let pixelData2 = data2.assumingMemoryBound(to: UInt8.self)
        var columnCounts2: [Int] = Array(repeating: 0, count: width)
        for y in 0..<height {
            for x in 0..<width {
                let i = (y * width + x) * 4
                let r = pixelData2[i]
                let g = pixelData2[i + 1]
                let b = pixelData2[i + 2]
                if r < 250 || g < 250 || b < 250 {
                    columnCounts2[x] += 1
                }
            }
        }

        print("\nNon-flipped comparison:")
        for (label, range) in ranges {
            let total = range.reduce(0) { $0 + columnCounts2[$1] }
            print("  \(label): \(total) pixels")
        }

        var ascii2 = ""
        for x in stride(from: 0, to: min(600, width), by: 5) {
            let sum = (x..<min(x+5, width)).reduce(0) { $0 + columnCounts2[$1] }
            if sum == 0 {
                ascii2 += "."
            } else if sum < 10 {
                ascii2 += "'"
            } else if sum < 50 {
                ascii2 += ":"
            } else if sum < 100 {
                ascii2 += "+"
            } else {
                ascii2 += "#"
            }
        }
        print("  |\(ascii2)|")
    }

    // MARK: - Test Score Builders

    private func makeSimpleScore() -> Score {
        let attributes = MeasureAttributes(
            divisions: 1,
            timeSignatures: [.fourFour],
            clefs: [.treble]
        )
        let note = Note(
            noteType: .pitched(Pitch(step: .c, octave: 4)),
            durationDivisions: 4,
            type: .whole,
            voice: 1,
            staff: 1
        )
        let measure = Measure(
            number: "1",
            elements: [.note(note)],
            attributes: attributes
        )
        let part = Part(id: "P1", name: "Piano", measures: [measure])
        return Score(parts: [part])
    }

    /// Builds a 2-measure drum score matching the Drumux app pattern.
    private func makeTwoMeasureDrumScore() -> Score {
        let div = 2
        let attributes = MeasureAttributes(
            divisions: div,
            timeSignatures: [.fourFour],
            clefs: [.percussion]
        )

        func drumMeasureElements() -> [MeasureElement] {
            var elements: [MeasureElement] = []

            // Voice 1: 8 hi-hat eighths (with snare chord tones at beats 2, 4)
            for i in 0..<8 {
                let isSnarePos = (i == 2 || i == 6) // beats 2 and 4
                if isSnarePos {
                    // Snare first
                    elements.append(.note(Note(
                        noteType: .unpitched(UnpitchedNote(displayStep: .c, displayOctave: 5)),
                        durationDivisions: 1, type: .eighth, voice: 1, staff: 1,
                        stemDirection: .up,
                        beams: [BeamValue(number: 1, value: i % 2 == 0 ? .begin : .end)]
                    )))
                    // Hi-hat chord tone
                    elements.append(.note(Note(
                        noteType: .unpitched(UnpitchedNote(displayStep: .g, displayOctave: 5)),
                        durationDivisions: 1, type: .eighth, voice: 1, staff: 1,
                        isChordTone: true, stemDirection: .up,
                        notehead: NoteheadInfo(type: .x),
                        beams: [BeamValue(number: 1, value: i % 2 == 0 ? .begin : .end)]
                    )))
                } else {
                    elements.append(.note(Note(
                        noteType: .unpitched(UnpitchedNote(displayStep: .g, displayOctave: 5)),
                        durationDivisions: 1, type: .eighth, voice: 1, staff: 1,
                        stemDirection: .up,
                        notehead: NoteheadInfo(type: .x),
                        beams: [BeamValue(number: 1, value: i % 2 == 0 ? .begin : .end)]
                    )))
                }
            }

            // Voice 2: Kick on beats 1, 3
            elements.append(.backup(Backup(duration: 8)))
            elements.append(.note(Note(
                noteType: .unpitched(UnpitchedNote(displayStep: .f, displayOctave: 4)),
                durationDivisions: 1, type: .eighth, voice: 2, staff: 1,
                stemDirection: .down
            )))
            elements.append(.note(Note(
                noteType: .rest(RestInfo()), durationDivisions: 3, type: .quarter,
                voice: 2, staff: 1
            )))
            elements.append(.note(Note(
                noteType: .unpitched(UnpitchedNote(displayStep: .f, displayOctave: 4)),
                durationDivisions: 1, type: .eighth, voice: 2, staff: 1,
                stemDirection: .down
            )))
            elements.append(.note(Note(
                noteType: .rest(RestInfo()), durationDivisions: 3, type: .quarter,
                voice: 2, staff: 1
            )))

            return elements
        }

        let measure1 = Measure(number: "1", elements: drumMeasureElements(), attributes: attributes)
        // Measure 2: NO attributes — should inherit divisions=2
        let measure2 = Measure(number: "2", elements: drumMeasureElements())

        let part = Part(id: "P1", name: "Drums", measures: [measure1, measure2], percussionMap: .standardDrumKit)
        return Score(metadata: ScoreMetadata(movementTitle: "Test"), parts: [part])
    }

    private func makeDrumScore() -> Score {
        let div = 2
        let attributes = MeasureAttributes(
            divisions: div,
            timeSignatures: [.fourFour],
            clefs: [.percussion]
        )

        var elements: [MeasureElement] = []

        // Voice 1: Hi-hat eighth notes
        for i in 0..<4 {
            elements.append(.note(Note(
                noteType: .unpitched(UnpitchedNote(displayStep: .g, displayOctave: 5)),
                durationDivisions: 1,
                type: .eighth,
                voice: 1,
                staff: 1,
                stemDirection: .up,
                notehead: NoteheadInfo(type: .x),
                beams: [BeamValue(number: 1, value: i % 2 == 0 ? .begin : .end)]
            )))
        }

        // Voice 2: Kick on beat 1
        elements.append(.backup(Backup(duration: 4)))
        elements.append(.note(Note(
            noteType: .unpitched(UnpitchedNote(displayStep: .f, displayOctave: 4)),
            durationDivisions: 2,
            type: .quarter,
            voice: 2,
            staff: 1,
            stemDirection: .down
        )))
        elements.append(.note(Note(
            noteType: .rest(RestInfo()),
            durationDivisions: 2,
            type: .quarter,
            voice: 2,
            staff: 1
        )))

        let measure = Measure(number: "1", elements: elements, attributes: attributes)
        let part = Part(id: "P1", name: "Drums", measures: [measure], percussionMap: .standardDrumKit)
        return Score(metadata: ScoreMetadata(movementTitle: "Test"), parts: [part])
    }
}
