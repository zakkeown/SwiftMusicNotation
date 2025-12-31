import XCTest
import CoreGraphics
@testable import MusicNotationRenderer
@testable import MusicNotationLayout
@testable import MusicNotationCore
@testable import SMuFLKit

final class RendererTests: XCTestCase {

    // MARK: - BeamRenderer Tests

    func testBeamRendererInitialization() {
        let renderer = BeamRenderer()
        XCTAssertNotNil(renderer.config)
        XCTAssertGreaterThan(renderer.config.beamThickness, 0)
        XCTAssertGreaterThan(renderer.config.beamSpacing, 0)
    }

    func testBeamRendererCustomConfig() {
        var config = BeamRenderConfiguration()
        config.beamThickness = 6.0
        config.beamSpacing = 3.0
        config.maxBeamSlope = 0.3

        let renderer = BeamRenderer(config: config)
        XCTAssertEqual(renderer.config.beamThickness, 6.0)
        XCTAssertEqual(renderer.config.beamSpacing, 3.0)
        XCTAssertEqual(renderer.config.maxBeamSlope, 0.3)
    }

    func testCalculateBeamEndpoints() {
        let renderer = BeamRenderer()

        let stemEnds = [
            CGPoint(x: 100, y: 50),
            CGPoint(x: 150, y: 55),
            CGPoint(x: 200, y: 48)
        ]

        let result = renderer.calculateBeamEndpoints(stemEnds: stemEnds, stemDirection: .up)
        XCTAssertNotNil(result)

        if let result = result {
            XCTAssertEqual(result.start.x, 100)
            XCTAssertEqual(result.end.x, 200)
        }
    }

    func testCalculateBeamEndpointsEmptyArray() {
        let renderer = BeamRenderer()
        let result = renderer.calculateBeamEndpoints(stemEnds: [], stemDirection: .up)
        XCTAssertNil(result)
    }

    func testCalculateBeamEndpointsSingleNote() {
        let renderer = BeamRenderer()
        let result = renderer.calculateBeamEndpoints(stemEnds: [CGPoint(x: 100, y: 50)], stemDirection: .up)
        XCTAssertNil(result)
    }

    func testBeamSlopeClamping() {
        var config = BeamRenderConfiguration()
        config.maxBeamSlope = 0.2

        let renderer = BeamRenderer(config: config)

        // Create stem ends with a steep slope
        let stemEnds = [
            CGPoint(x: 100, y: 50),
            CGPoint(x: 200, y: 100)  // 50 point rise over 100 points = 0.5 slope
        ]

        let result = renderer.calculateBeamEndpoints(stemEnds: stemEnds, stemDirection: .up)
        XCTAssertNotNil(result)

        if let result = result {
            // Slope should be clamped to maxBeamSlope
            XCTAssertLessThanOrEqual(abs(result.slope), config.maxBeamSlope)
        }
    }

    // MARK: - BeamGroupBuilder Tests

    func testBeamGroupBuilderBasic() {
        var builder = BeamGroupBuilder(stemDirection: .up)
        builder.addNote(stemEnd: CGPoint(x: 100, y: 50), beamCount: 1)
        builder.addNote(stemEnd: CGPoint(x: 150, y: 55), beamCount: 1)
        builder.addNote(stemEnd: CGPoint(x: 200, y: 48), beamCount: 1)

        let config = BeamRenderConfiguration()
        let result = builder.build(config: config)

        XCTAssertNotNil(result)
        if let info = result {
            XCTAssertEqual(info.primaryBeamStart.x, 100)
            XCTAssertEqual(info.primaryBeamEnd.x, 200)
            XCTAssertEqual(info.stemDirection, .up)
        }
    }

    func testBeamGroupBuilderSingleNote() {
        var builder = BeamGroupBuilder(stemDirection: .down)
        builder.addNote(stemEnd: CGPoint(x: 100, y: 50), beamCount: 1)

        let config = BeamRenderConfiguration()
        let result = builder.build(config: config)

        // Should return nil for single note
        XCTAssertNil(result)
    }

    func testBeamGroupBuilderWithSecondaryBeams() {
        var builder = BeamGroupBuilder(stemDirection: .up)
        builder.addNote(stemEnd: CGPoint(x: 100, y: 50), beamCount: 2)  // 16th note
        builder.addNote(stemEnd: CGPoint(x: 150, y: 55), beamCount: 2)  // 16th note
        builder.addNote(stemEnd: CGPoint(x: 200, y: 48), beamCount: 1)  // 8th note

        let config = BeamRenderConfiguration()
        let result = builder.build(config: config)

        XCTAssertNotNil(result)
        if let info = result {
            // Should have secondary beams for the 16th notes
            XCTAssertFalse(info.secondaryBeams.isEmpty)
        }
    }

    // MARK: - TextRenderer Tests

    func testTextRendererInitialization() {
        let renderer = TextRenderer()
        XCTAssertNotNil(renderer.config)
        XCTAssertFalse(renderer.config.defaultFontName.isEmpty)
    }

    func testTextRendererCustomConfig() {
        var config = TextRenderConfiguration()
        config.lyricFontSize = 14
        config.dynamicFontSize = 16

        let renderer = TextRenderer(config: config)
        XCTAssertEqual(renderer.config.lyricFontSize, 14)
        XCTAssertEqual(renderer.config.dynamicFontSize, 16)
    }

    func testTextMeasurement() {
        let renderer = TextRenderer()
        let bounds = renderer.measureText("Hello", fontSize: 12)

        XCTAssertGreaterThan(bounds.width, 0)
    }

    func testTextMeasurementEmptyString() {
        let renderer = TextRenderer()
        let bounds = renderer.measureText("", fontSize: 12)

        // Empty string should have zero or minimal width
        XCTAssertLessThanOrEqual(bounds.width, 1)
    }

    // MARK: - LayerManager Tests

    func testLayerManagerInitialization() {
        let manager = LayerManager()
        XCTAssertNotNil(manager)
        XCTAssertTrue(manager.activeLayers.isEmpty)
    }

    func testLayerElement() {
        let element = LayerElement(
            id: "test-element",
            bounds: CGRect(x: 100, y: 50, width: 10, height: 20)
        )

        XCTAssertEqual(element.id, "test-element")
        XCTAssertEqual(element.bounds.origin.x, 100)
        XCTAssertEqual(element.bounds.width, 10)
    }

    func testCullingVisibleElements() {
        let viewport = CGRect(x: 0, y: 0, width: 500, height: 500)

        let insideElement = LayerElement(
            id: "inside",
            bounds: CGRect(x: 100, y: 100, width: 10, height: 10)
        )

        let outsideElement = LayerElement(
            id: "outside",
            bounds: CGRect(x: 1000, y: 1000, width: 10, height: 10)
        )

        let elements = [insideElement, outsideElement]
        let visible = CullingHelper.cull(elements, to: viewport)

        XCTAssertEqual(visible.count, 1)
        XCTAssertEqual(visible.first?.bounds.origin.x, 100)
    }

    func testCullingPartiallyVisibleElements() {
        let viewport = CGRect(x: 0, y: 0, width: 500, height: 500)

        // Element that overlaps the viewport edge
        let partialElement = LayerElement(
            id: "partial",
            bounds: CGRect(x: 495, y: 100, width: 20, height: 20)
        )

        let elements = [partialElement]
        let visible = CullingHelper.cull(elements, to: viewport)

        // Partially visible elements should be included
        XCTAssertEqual(visible.count, 1)
    }

    func testExpandedViewport() {
        let viewport = CGRect(x: 100, y: 100, width: 200, height: 200)
        let expanded = CullingHelper.expandedViewport(viewport, margin: 50)

        XCTAssertEqual(expanded.origin.x, 50)
        XCTAssertEqual(expanded.origin.y, 50)
        XCTAssertEqual(expanded.width, 300)
        XCTAssertEqual(expanded.height, 300)
    }

    // MARK: - DirtyRegion Tests

    func testDirtyRegionTracking() {
        let tracker = DirtyRegionTracker()

        // Start fresh - clear the initial full redraw state
        tracker.clearDirty()

        tracker.markDirty(CGRect(x: 0, y: 0, width: 100, height: 100))
        tracker.markDirty(CGRect(x: 50, y: 50, width: 100, height: 100))

        let region = tracker.dirtyRegion()

        // Should combine both rects
        XCTAssertNotNil(region)
        if let region = region {
            XCTAssertEqual(region.origin.x, 0)
            XCTAssertEqual(region.origin.y, 0)
            XCTAssertEqual(region.maxX, 150)
            XCTAssertEqual(region.maxY, 150)
        }
    }

    func testDirtyRegionClear() {
        let tracker = DirtyRegionTracker()

        tracker.clearDirty()
        tracker.markDirty(CGRect(x: 0, y: 0, width: 100, height: 100))
        tracker.clearDirty()

        let region = tracker.dirtyRegion()
        XCTAssertEqual(region, CGRect.zero)
    }

    func testFullRedraw() {
        let tracker = DirtyRegionTracker()

        tracker.markFullRedraw()

        // When full redraw is needed, dirtyRegion returns nil
        let region = tracker.dirtyRegion()
        XCTAssertNil(region)
    }

    func testNeedsRedraw() {
        let tracker = DirtyRegionTracker()

        // Initially needs full redraw
        XCTAssertTrue(tracker.needsRedraw)

        tracker.clearDirty()
        XCTAssertFalse(tracker.needsRedraw)

        tracker.markDirty(CGRect(x: 0, y: 0, width: 10, height: 10))
        XCTAssertTrue(tracker.needsRedraw)
    }

    // MARK: - MusicRenderer Tests

    func testMusicRendererInitialization() {
        let renderer = MusicRenderer()
        XCTAssertNotNil(renderer.config)
    }

    func testMusicRendererCustomConfig() {
        var config = RenderConfiguration()
        config.staffLineThickness = 2.0
        config.stemThickness = 1.5

        let renderer = MusicRenderer(config: config)
        XCTAssertEqual(renderer.config.staffLineThickness, 2.0)
        XCTAssertEqual(renderer.config.stemThickness, 1.5)
    }

    // MARK: - StaffRenderer Tests

    func testStaffRendererInitialization() {
        let renderer = StaffRenderer()
        XCTAssertNotNil(renderer.config)
    }

    func testStaffRendererCustomConfig() {
        var config = StaffRenderConfiguration()
        config.staffLineThickness = 1.5
        config.ledgerLineThickness = 0.2

        let renderer = StaffRenderer(config: config)
        XCTAssertEqual(renderer.config.staffLineThickness, 1.5)
        XCTAssertEqual(renderer.config.ledgerLineThickness, 0.2)
    }

    // MARK: - RenderLayer Tests

    func testRenderLayerOrdering() {
        XCTAssertLessThan(RenderLayer.background, RenderLayer.staffLines)
        XCTAssertLessThan(RenderLayer.staffLines, RenderLayer.noteheads)
        XCTAssertLessThan(RenderLayer.noteheads, RenderLayer.beams)
        XCTAssertLessThan(RenderLayer.beams, RenderLayer.dynamics)
        XCTAssertLessThan(RenderLayer.dynamics, RenderLayer.selection)
    }

    func testLayerConfiguration() {
        var config = LayerConfiguration()
        XCTAssertTrue(config.enableLayeredRendering)
        XCTAssertTrue(config.enableCulling)
        XCTAssertFalse(config.debugShowLayers)

        config.disabledLayers.insert(.debug)
        XCTAssertFalse(config.shouldRender(layer: .debug))
        XCTAssertTrue(config.shouldRender(layer: .noteheads))
    }
}

// MARK: - Render Info Tests

final class RenderInfoTests: XCTestCase {

    func testBeamGroupRenderInfo() {
        let info = BeamGroupRenderInfo(
            primaryBeamStart: CGPoint(x: 100, y: 50),
            primaryBeamEnd: CGPoint(x: 200, y: 45),
            beamThickness: 5.0,
            stemDirection: .up,
            secondaryBeams: [],
            slope: -0.05
        )

        XCTAssertEqual(info.primaryBeamStart.x, 100)
        XCTAssertEqual(info.primaryBeamEnd.x, 200)
        XCTAssertEqual(info.beamThickness, 5.0)
        XCTAssertEqual(info.stemDirection, .up)
        XCTAssertEqual(info.slope, -0.05)
        XCTAssertTrue(info.secondaryBeams.isEmpty)
    }

    func testBeamSegment() {
        let segment = BeamSegment(
            start: CGPoint(x: 100, y: 50),
            end: CGPoint(x: 150, y: 48),
            level: 2
        )

        XCTAssertEqual(segment.start.x, 100)
        XCTAssertEqual(segment.end.x, 150)
        XCTAssertEqual(segment.level, 2)
    }

    func testLyricRenderInfo() {
        let info = LyricRenderInfo(
            text: "la",
            position: CGPoint(x: 100, y: 200),
            verse: 1,
            connector: nil
        )

        XCTAssertEqual(info.text, "la")
        XCTAssertEqual(info.position.x, 100)
        XCTAssertEqual(info.verse, 1)
        XCTAssertNil(info.connector)
    }

    func testLyricConnector() {
        let connector = LyricConnector(
            type: .hyphen,
            startX: 100,
            endX: 150,
            y: 200
        )

        XCTAssertEqual(connector.type, .hyphen)
        XCTAssertEqual(connector.startX, 100)
        XCTAssertEqual(connector.endX, 150)
    }

    func testTempoRenderInfo() {
        let metronome = MetronomeInfo(
            beatUnitGlyph: .noteheadBlack,
            dots: 0,
            bpm: 120
        )

        let info = TempoRenderInfo(
            position: CGPoint(x: 50, y: 20),
            text: "Allegro",
            metronome: metronome
        )

        XCTAssertEqual(info.text, "Allegro")
        XCTAssertEqual(info.metronome?.bpm, 120)
    }

    func testDirectionTextRenderInfo() {
        let info = DirectionTextRenderInfo(
            text: "cresc.",
            position: CGPoint(x: 100, y: 150),
            alignment: .left,
            isItalic: true,
            isBold: false
        )

        XCTAssertEqual(info.text, "cresc.")
        XCTAssertEqual(info.alignment, .left)
        XCTAssertTrue(info.isItalic)
        XCTAssertFalse(info.isBold)
    }

    func testRehearsalMarkRenderInfo() {
        let info = RehearsalMarkRenderInfo(
            text: "A",
            position: CGPoint(x: 50, y: 30),
            enclosure: .rectangle
        )

        XCTAssertEqual(info.text, "A")
        XCTAssertEqual(info.enclosure, .rectangle)
    }

    func testCreditRenderInfo() {
        let info = CreditRenderInfo(
            text: "Johann Sebastian Bach",
            position: CGPoint(x: 300, y: 50),
            fontSize: 14,
            alignment: .center,
            isItalic: false,
            isBold: true
        )

        XCTAssertEqual(info.text, "Johann Sebastian Bach")
        XCTAssertEqual(info.fontSize, 14)
        XCTAssertEqual(info.alignment, .center)
        XCTAssertTrue(info.isBold)
    }
}

// MARK: - Configuration Tests

final class ConfigurationTests: XCTestCase {

    func testBeamRenderConfiguration() {
        var config = BeamRenderConfiguration()
        config.beamThickness = 4.0
        config.beamSpacing = 2.5
        config.maxBeamSlope = 0.25

        XCTAssertEqual(config.beamThickness, 4.0)
        XCTAssertEqual(config.beamSpacing, 2.5)
        XCTAssertEqual(config.maxBeamSlope, 0.25)
    }

    func testTextRenderConfiguration() {
        var config = TextRenderConfiguration()
        config.defaultFontName = "Georgia"
        config.lyricFontSize = 11
        config.rehearsalPadding = 4.0

        XCTAssertEqual(config.defaultFontName, "Georgia")
        XCTAssertEqual(config.lyricFontSize, 11)
        XCTAssertEqual(config.rehearsalPadding, 4.0)
    }

    func testRenderConfiguration() {
        var config = RenderConfiguration()
        config.staffLineThickness = 1.2
        config.stemThickness = 1.1

        XCTAssertEqual(config.staffLineThickness, 1.2)
        XCTAssertEqual(config.stemThickness, 1.1)
    }

    func testStaffRenderConfiguration() {
        var config = StaffRenderConfiguration()
        config.staffLineThickness = 0.15
        config.ledgerLineThickness = 0.18

        XCTAssertEqual(config.staffLineThickness, 0.15)
        XCTAssertEqual(config.ledgerLineThickness, 0.18)
    }
}

// MARK: - Enclosure Type Tests

final class EnclosureTypeTests: XCTestCase {

    func testEnclosureTypeValues() {
        XCTAssertEqual(EnclosureType.rectangle.rawValue, "rectangle")
        XCTAssertEqual(EnclosureType.square.rawValue, "square")
        XCTAssertEqual(EnclosureType.circle.rawValue, "circle")
        XCTAssertEqual(EnclosureType.oval.rawValue, "oval")
        XCTAssertEqual(EnclosureType.diamond.rawValue, "diamond")
        XCTAssertEqual(EnclosureType.triangle.rawValue, "triangle")
        XCTAssertEqual(EnclosureType.none.rawValue, "none")
    }
}

// MARK: - Text Alignment Tests

final class TextAlignmentTests: XCTestCase {

    func testTextAlignmentValues() {
        XCTAssertEqual(TextAlignment.left.rawValue, "left")
        XCTAssertEqual(TextAlignment.center.rawValue, "center")
        XCTAssertEqual(TextAlignment.right.rawValue, "right")
    }
}

// MARK: - Lyric Connector Type Tests

final class LyricConnectorTypeTests: XCTestCase {

    func testLyricConnectorTypeValues() {
        XCTAssertEqual(LyricConnectorType.hyphen.rawValue, "hyphen")
        XCTAssertEqual(LyricConnectorType.extender.rawValue, "extender")
        XCTAssertEqual(LyricConnectorType.elision.rawValue, "elision")
    }
}

// MARK: - Render Pass Tests

final class RenderPassTests: XCTestCase {

    func testRenderPassInitialization() {
        let pass = RenderPass(
            name: "test",
            layers: [.noteheads, .stems],
            usesBlending: true
        )

        XCTAssertEqual(pass.name, "test")
        XCTAssertTrue(pass.layers.contains(.noteheads))
        XCTAssertTrue(pass.layers.contains(.stems))
        XCTAssertTrue(pass.usesBlending)
    }

    func testStandardRenderPasses() {
        let passes = RenderPass.standardPasses
        XCTAssertFalse(passes.isEmpty)

        // Should have background, structure, notes, etc.
        let passNames = passes.map { $0.name }
        XCTAssertTrue(passNames.contains("background"))
        XCTAssertTrue(passNames.contains("notes"))
    }
}
