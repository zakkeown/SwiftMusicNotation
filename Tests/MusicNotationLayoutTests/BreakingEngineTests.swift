import XCTest
import CoreGraphics
@testable import MusicNotationLayout

final class BreakingEngineTests: XCTestCase {

    // MARK: - System Breaking Tests

    func testComputeSystemBreaksEmpty() {
        let engine = BreakingEngine()

        let breaks = engine.computeSystemBreaks(measureWidths: [], systemWidth: 500)

        XCTAssertTrue(breaks.isEmpty)
    }

    func testComputeSystemBreaksSingleMeasure() {
        let engine = BreakingEngine()

        let breaks = engine.computeSystemBreaks(measureWidths: [200], systemWidth: 500)

        XCTAssertEqual(breaks.count, 1)
        XCTAssertEqual(breaks[0].startMeasure, 0)
        XCTAssertEqual(breaks[0].endMeasure, 0)
        XCTAssertEqual(breaks[0].measureCount, 1)
    }

    func testComputeSystemBreaksMultipleMeasuresFitOnOneLine() {
        let engine = BreakingEngine()

        let breaks = engine.computeSystemBreaks(
            measureWidths: [100, 100, 100],
            systemWidth: 500
        )

        XCTAssertEqual(breaks.count, 1)
        XCTAssertEqual(breaks[0].startMeasure, 0)
        XCTAssertEqual(breaks[0].endMeasure, 2)
        XCTAssertEqual(breaks[0].measureCount, 3)
    }

    func testComputeSystemBreaksRequiresMultipleSystems() {
        let engine = BreakingEngine()

        // 5 measures of 150 each = 750, system width is 400
        let breaks = engine.computeSystemBreaks(
            measureWidths: [150, 150, 150, 150, 150],
            systemWidth: 400
        )

        XCTAssertGreaterThan(breaks.count, 1)

        // Verify all measures are accounted for
        let totalMeasures = breaks.reduce(0) { $0 + $1.measureCount }
        XCTAssertEqual(totalMeasures, 5)
    }

    func testComputeSystemBreaksWithBreakHints() {
        var engine = BreakingEngine()
        engine.config.preferredBreakBonus = 100

        let hints = [BreakHint(measureIndex: 2, type: .preferred)]

        let breaks = engine.computeSystemBreaks(
            measureWidths: [100, 100, 100, 100],
            systemWidth: 450,
            breakHints: hints
        )

        // The algorithm should favor breaking at measure 2
        XCTAssertGreaterThanOrEqual(breaks.count, 1)
    }

    // MARK: - Greedy System Breaking Tests

    func testComputeSystemBreaksGreedyEmpty() {
        let engine = BreakingEngine()

        let breaks = engine.computeSystemBreaksGreedy(measureWidths: [], systemWidth: 500)

        XCTAssertTrue(breaks.isEmpty)
    }

    func testComputeSystemBreaksGreedySingleMeasure() {
        let engine = BreakingEngine()

        let breaks = engine.computeSystemBreaksGreedy(measureWidths: [200], systemWidth: 500)

        XCTAssertEqual(breaks.count, 1)
        XCTAssertEqual(breaks[0].startMeasure, 0)
        XCTAssertEqual(breaks[0].endMeasure, 0)
    }

    func testComputeSystemBreaksGreedyMultipleSystems() {
        let engine = BreakingEngine()

        let breaks = engine.computeSystemBreaksGreedy(
            measureWidths: [200, 200, 200, 200],
            systemWidth: 450
        )

        XCTAssertEqual(breaks.count, 2)

        let totalMeasures = breaks.reduce(0) { $0 + $1.measureCount }
        XCTAssertEqual(totalMeasures, 4)
    }

    // MARK: - Page Breaking Tests

    func testComputePageBreaksEmpty() {
        let engine = BreakingEngine()

        let breaks = engine.computePageBreaks(
            systemHeights: [],
            pageHeight: 800,
            systemGap: 50
        )

        XCTAssertTrue(breaks.isEmpty)
    }

    func testComputePageBreaksSingleSystem() {
        let engine = BreakingEngine()

        let breaks = engine.computePageBreaks(
            systemHeights: [200],
            pageHeight: 800,
            systemGap: 50
        )

        XCTAssertEqual(breaks.count, 1)
        XCTAssertEqual(breaks[0].startSystem, 0)
        XCTAssertEqual(breaks[0].endSystem, 0)
        XCTAssertEqual(breaks[0].systemCount, 1)
    }

    func testComputePageBreaksMultipleSystemsFitOnOnePage() {
        let engine = BreakingEngine()

        let breaks = engine.computePageBreaks(
            systemHeights: [150, 150, 150],
            pageHeight: 800,
            systemGap: 50
        )

        XCTAssertEqual(breaks.count, 1)
        XCTAssertEqual(breaks[0].startSystem, 0)
        XCTAssertEqual(breaks[0].endSystem, 2)
        XCTAssertEqual(breaks[0].systemCount, 3)
    }

    func testComputePageBreaksRequiresMultiplePages() {
        let engine = BreakingEngine()

        // 5 systems of 200 each with 50 gap = too much for 800 page height
        let breaks = engine.computePageBreaks(
            systemHeights: [200, 200, 200, 200, 200],
            pageHeight: 600,
            systemGap: 50
        )

        XCTAssertGreaterThan(breaks.count, 1)

        let totalSystems = breaks.reduce(0) { $0 + $1.systemCount }
        XCTAssertEqual(totalSystems, 5)
    }

    // MARK: - Greedy Page Breaking Tests

    func testComputePageBreaksGreedyEmpty() {
        let engine = BreakingEngine()

        let breaks = engine.computePageBreaksGreedy(
            systemHeights: [],
            pageHeight: 800,
            systemGap: 50
        )

        XCTAssertTrue(breaks.isEmpty)
    }

    func testComputePageBreaksGreedySinglePage() {
        let engine = BreakingEngine()

        let breaks = engine.computePageBreaksGreedy(
            systemHeights: [200, 200],
            pageHeight: 800,
            systemGap: 50
        )

        XCTAssertEqual(breaks.count, 1)
    }

    func testComputePageBreaksGreedyMultiplePages() {
        let engine = BreakingEngine()

        let breaks = engine.computePageBreaksGreedy(
            systemHeights: [300, 300, 300],
            pageHeight: 500,
            systemGap: 50
        )

        XCTAssertGreaterThan(breaks.count, 1)
    }

    // MARK: - Justification Tests

    func testJustifySystemStretch() {
        let engine = BreakingEngine()

        let result = engine.justifySystem(
            measureWidths: [100, 100],
            systemWidth: 300
        )

        XCTAssertTrue(result.isStretched)
        XCTAssertFalse(result.isCompressed)
        XCTAssertEqual(result.adjustedWidths.reduce(0, +), 300, accuracy: 0.01)
    }

    func testJustifySystemCompress() {
        let engine = BreakingEngine()

        let result = engine.justifySystem(
            measureWidths: [200, 200],
            systemWidth: 300,
            allowCompression: true
        )

        XCTAssertFalse(result.isStretched)
        XCTAssertTrue(result.isCompressed)
        XCTAssertEqual(result.adjustedWidths.reduce(0, +), 300, accuracy: 0.01)
    }

    func testJustifySystemNoCompression() {
        let engine = BreakingEngine()

        let originalWidths: [CGFloat] = [200, 200]
        let result = engine.justifySystem(
            measureWidths: originalWidths,
            systemWidth: 300,
            allowCompression: false
        )

        // Should return original widths
        XCTAssertEqual(result.adjustedWidths, originalWidths)
    }

    func testJustifySystemProportional() {
        let engine = BreakingEngine()

        let result = engine.justifySystem(
            measureWidths: [100, 200], // 2:1 ratio
            systemWidth: 450
        )

        // Extra 150 should be distributed proportionally
        // 100 gets 50, 200 gets 100
        XCTAssertEqual(result.adjustedWidths[0], 150, accuracy: 0.01)
        XCTAssertEqual(result.adjustedWidths[1], 300, accuracy: 0.01)
    }

    // MARK: - First System Adjustment Tests

    func testAdjustForFirstSystemNoChange() {
        let engine = BreakingEngine()

        let breaks = [SystemBreak(startMeasure: 0, endMeasure: 2, naturalWidth: 300)]
        let measureWidths: [CGFloat] = [100, 100, 100]

        let adjusted = engine.adjustForFirstSystem(
            breaks: breaks,
            firstSystemExtraWidth: 50,
            measureWidths: measureWidths,
            systemWidth: 400
        )

        // 300 + 50 = 350, still fits in 400
        XCTAssertEqual(adjusted.count, 1)
    }

    func testAdjustForFirstSystemNeedsAdjustment() {
        let engine = BreakingEngine()

        let breaks = [SystemBreak(startMeasure: 0, endMeasure: 3, naturalWidth: 380)]
        let measureWidths: [CGFloat] = [100, 100, 100, 80]

        let adjusted = engine.adjustForFirstSystem(
            breaks: breaks,
            firstSystemExtraWidth: 50,
            measureWidths: measureWidths,
            systemWidth: 400
        )

        // 380 + 50 = 430 > 400, needs adjustment
        XCTAssertGreaterThanOrEqual(adjusted.count, 1)
    }

    // MARK: - Configuration Tests

    func testBreakingConfigurationDefaults() {
        let config = BreakingConfiguration()

        XCTAssertEqual(config.stretchPenalty, 100)
        XCTAssertEqual(config.compressPenalty, 200)
        XCTAssertEqual(config.minimumMeasureGap, 2.0)
        XCTAssertEqual(config.minimumMeasuresPerSystem, 1)
        XCTAssertEqual(config.maximumMeasuresPerSystem, 8)
        XCTAssertEqual(config.minimumPageFill, 0.5)
    }

    // MARK: - Break Hint Tests

    func testBreakHintTypes() {
        let preferred = BreakHint(measureIndex: 0, type: .preferred)
        XCTAssertEqual(preferred.type, .preferred)

        let required = BreakHint(measureIndex: 1, type: .required)
        XCTAssertEqual(required.type, .required)

        let forbidden = BreakHint(measureIndex: 2, type: .forbidden)
        XCTAssertEqual(forbidden.type, .forbidden)
    }

    // MARK: - PageBreakInfo Tests

    func testPageBreakInfoSystemCount() {
        let info = PageBreakInfo(startSystem: 2, endSystem: 5, contentHeight: 500)

        XCTAssertEqual(info.systemCount, 4)
    }

    // MARK: - JustificationResult Tests

    func testJustificationResultProperties() {
        let stretched = JustificationResult(adjustedWidths: [150, 150], stretchRatio: 1.5)
        XCTAssertTrue(stretched.isStretched)
        XCTAssertFalse(stretched.isCompressed)

        let compressed = JustificationResult(adjustedWidths: [75, 75], stretchRatio: 0.75)
        XCTAssertFalse(compressed.isStretched)
        XCTAssertTrue(compressed.isCompressed)

        let unchanged = JustificationResult(adjustedWidths: [100, 100], stretchRatio: 1.0)
        XCTAssertFalse(unchanged.isStretched)
        XCTAssertFalse(unchanged.isCompressed)
    }
}
