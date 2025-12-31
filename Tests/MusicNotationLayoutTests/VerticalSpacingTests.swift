import XCTest
import CoreGraphics
@testable import MusicNotationLayout

final class VerticalSpacingTests: XCTestCase {

    // MARK: - Staff Position Tests

    func testComputeStaffPositionsSinglePart() {
        let engine = VerticalSpacingEngine()
        let parts = [PartStaffInfo(staffCount: 1)]

        let positions = engine.computeStaffPositions(parts: parts, staffHeight: 40)

        XCTAssertEqual(positions.count, 1)
        XCTAssertEqual(positions[0].partIndex, 0)
        XCTAssertEqual(positions[0].staffNumber, 1)
        XCTAssertEqual(positions[0].topY, 0)
        XCTAssertEqual(positions[0].bottomY, 40)
        XCTAssertEqual(positions[0].centerLineY, 20)
        XCTAssertEqual(positions[0].height, 40)
    }

    func testComputeStaffPositionsPianoGrandStaff() {
        let engine = VerticalSpacingEngine()
        let parts = [PartStaffInfo(staffCount: 2)]

        let positions = engine.computeStaffPositions(parts: parts, staffHeight: 40)

        XCTAssertEqual(positions.count, 2)

        // First staff
        XCTAssertEqual(positions[0].partIndex, 0)
        XCTAssertEqual(positions[0].staffNumber, 1)
        XCTAssertEqual(positions[0].topY, 0)

        // Second staff (should be offset by staff height + distance)
        XCTAssertEqual(positions[1].partIndex, 0)
        XCTAssertEqual(positions[1].staffNumber, 2)
        XCTAssertGreaterThan(positions[1].topY, positions[0].bottomY)
    }

    func testComputeStaffPositionsMultipleParts() {
        let engine = VerticalSpacingEngine()
        let parts = [
            PartStaffInfo(staffCount: 1),
            PartStaffInfo(staffCount: 1),
            PartStaffInfo(staffCount: 1)
        ]

        let positions = engine.computeStaffPositions(parts: parts, staffHeight: 40)

        XCTAssertEqual(positions.count, 3)

        // Each part should have its own staff
        for (index, position) in positions.enumerated() {
            XCTAssertEqual(position.partIndex, index)
            XCTAssertEqual(position.staffNumber, 1)
        }

        // Parts should be spaced by partDistance
        XCTAssertGreaterThan(positions[1].topY, positions[0].bottomY)
        XCTAssertGreaterThan(positions[2].topY, positions[1].bottomY)
    }

    func testComputeStaffPositionsWithStartY() {
        let engine = VerticalSpacingEngine()
        let parts = [PartStaffInfo(staffCount: 1)]

        let positions = engine.computeStaffPositions(parts: parts, staffHeight: 40, startY: 100)

        XCTAssertEqual(positions[0].topY, 100)
        XCTAssertEqual(positions[0].bottomY, 140)
    }

    func testComputeStaffPositionsWithCustomStaffDistance() {
        let engine = VerticalSpacingEngine()
        let customDistance: CGFloat = 100

        let parts = [PartStaffInfo(staffCount: 2, staffDistance: customDistance)]

        let positions = engine.computeStaffPositions(parts: parts, staffHeight: 40)

        let distanceBetweenStaves = positions[1].topY - positions[0].bottomY
        XCTAssertEqual(distanceBetweenStaves, customDistance)
    }

    // MARK: - System Position Tests

    func testComputeSystemPositionsSingle() {
        let engine = VerticalSpacingEngine()

        let positions = engine.computeSystemPositions(
            systemCount: 1,
            pageHeight: 800,
            topMargin: 50,
            bottomMargin: 50,
            systemHeights: [200]
        )

        XCTAssertEqual(positions.count, 1)
        XCTAssertEqual(positions[0].systemIndex, 0)
        XCTAssertEqual(positions[0].topY, 50)
        XCTAssertEqual(positions[0].height, 200)
    }

    func testComputeSystemPositionsMultiple() {
        let engine = VerticalSpacingEngine()

        let positions = engine.computeSystemPositions(
            systemCount: 3,
            pageHeight: 800,
            topMargin: 50,
            bottomMargin: 50,
            systemHeights: [150, 150, 150]
        )

        XCTAssertEqual(positions.count, 3)

        // Systems should be ordered
        for (index, position) in positions.enumerated() {
            XCTAssertEqual(position.systemIndex, index)
        }

        // Systems should not overlap
        XCTAssertLessThanOrEqual(positions[0].bottomY, positions[1].topY)
        XCTAssertLessThanOrEqual(positions[1].bottomY, positions[2].topY)
    }

    func testComputeSystemPositionsEmpty() {
        let engine = VerticalSpacingEngine()

        let positions = engine.computeSystemPositions(
            systemCount: 0,
            pageHeight: 800,
            topMargin: 50,
            bottomMargin: 50,
            systemHeights: []
        )

        XCTAssertTrue(positions.isEmpty)
    }

    // MARK: - System Height Tests

    func testComputeSystemHeightBasic() {
        let engine = VerticalSpacingEngine()

        let staffPositions = [
            StaffPositionInfo(partIndex: 0, staffNumber: 1, topY: 0, bottomY: 40, centerLineY: 20)
        ]

        let height = engine.computeSystemHeight(
            staffPositions: staffPositions,
            elementBounds: [],
            staffHeight: 40
        )

        // Should be at least staff height + padding
        XCTAssertGreaterThanOrEqual(height, 40)
    }

    func testComputeSystemHeightWithElements() {
        let engine = VerticalSpacingEngine()

        let staffPositions = [
            StaffPositionInfo(partIndex: 0, staffNumber: 1, topY: 0, bottomY: 40, centerLineY: 20)
        ]

        // Element extends above and below staff
        let elementBounds = [CGRect(x: 0, y: -20, width: 100, height: 100)]

        let height = engine.computeSystemHeight(
            staffPositions: staffPositions,
            elementBounds: elementBounds,
            staffHeight: 40
        )

        // Should accommodate elements that extend beyond staves
        XCTAssertGreaterThan(height, 40)
    }

    // MARK: - Collision Resolution Tests

    func testResolveCollisionsSingleStaff() {
        let engine = VerticalSpacingEngine()

        var positions = [
            StaffPositionInfo(partIndex: 0, staffNumber: 1, topY: 0, bottomY: 40, centerLineY: 20)
        ]

        // Should not crash with single staff
        engine.resolveCollisions(
            staffPositions: &positions,
            upperBounds: [:],
            lowerBounds: [:],
            staffHeight: 40
        )

        XCTAssertEqual(positions.count, 1)
    }

    func testResolveCollisionsNoOverlap() {
        let engine = VerticalSpacingEngine()

        var positions = [
            StaffPositionInfo(partIndex: 0, staffNumber: 1, topY: 0, bottomY: 40, centerLineY: 20),
            StaffPositionInfo(partIndex: 1, staffNumber: 1, topY: 100, bottomY: 140, centerLineY: 120)
        ]

        let originalSecondY = positions[1].topY

        engine.resolveCollisions(
            staffPositions: &positions,
            upperBounds: [:],
            lowerBounds: [:],
            staffHeight: 40
        )

        // No collision, positions should be unchanged
        XCTAssertEqual(positions[1].topY, originalSecondY)
    }

    func testResolveCollisionsWithOverlap() {
        var engine = VerticalSpacingEngine()
        engine.config.minimumStaffClearance = 10

        var positions = [
            StaffPositionInfo(partIndex: 0, staffNumber: 1, topY: 0, bottomY: 40, centerLineY: 20),
            StaffPositionInfo(partIndex: 1, staffNumber: 1, topY: 50, bottomY: 90, centerLineY: 70)
        ]

        // Elements extend beyond staves, causing collision
        let lowerBounds: [Int: CGFloat] = [0: 60] // First staff content extends to 60
        let upperBounds: [Int: CGFloat] = [1: 45] // Second staff content starts at 45

        engine.resolveCollisions(
            staffPositions: &positions,
            upperBounds: upperBounds,
            lowerBounds: lowerBounds,
            staffHeight: 40
        )

        // Second staff should be pushed down
        XCTAssertGreaterThan(positions[1].topY, 50)
    }

    // MARK: - Configuration Tests

    func testVerticalSpacingConfigurationDefaults() {
        let config = VerticalSpacingConfiguration()

        XCTAssertEqual(config.staffDistance, 60.0)
        XCTAssertEqual(config.partDistance, 80.0)
        XCTAssertEqual(config.systemDistance, 80.0)
        XCTAssertEqual(config.topSystemDistance, 100.0)
        XCTAssertEqual(config.systemTopPadding, 20.0)
        XCTAssertEqual(config.systemBottomPadding, 20.0)
        XCTAssertEqual(config.minimumStaffClearance, 10.0)
    }

    func testVerticalSpacingEngineCustomConfig() {
        var config = VerticalSpacingConfiguration()
        config.staffDistance = 100
        config.partDistance = 120

        let engine = VerticalSpacingEngine(config: config)

        XCTAssertEqual(engine.config.staffDistance, 100)
        XCTAssertEqual(engine.config.partDistance, 120)
    }

    // MARK: - Page Layout Engine Tests

    func testPageLayoutEngineComputePageBreaks() {
        let engine = PageLayoutEngine()

        let breaks = engine.computePageBreaks(
            systemHeights: [200, 200, 200],
            pageHeight: 800,
            topMargin: 50,
            bottomMargin: 50
        )

        XCTAssertFalse(breaks.isEmpty)

        // Verify all systems are accounted for
        let totalSystems = breaks.reduce(0) { $0 + $1.systemCount }
        XCTAssertEqual(totalSystems, 3)
    }

    func testPageLayoutEngineWithFirstPageMargin() {
        let engine = PageLayoutEngine()

        let breaks = engine.computePageBreaks(
            systemHeights: [200, 200, 200, 200, 200],
            pageHeight: 600,
            topMargin: 50,
            bottomMargin: 50,
            firstPageTopMargin: 150 // Extra space for title
        )

        XCTAssertGreaterThan(breaks.count, 1) // Should need multiple pages
    }

    // MARK: - PageBreak Tests

    func testPageBreakSystemCount() {
        let pageBreak = PageBreak(startSystem: 0, endSystem: 3, totalHeight: 500)

        XCTAssertEqual(pageBreak.systemCount, 4)
    }

    // MARK: - PartStaffInfo Tests

    func testPartStaffInfoSingleStaff() {
        let info = PartStaffInfo(staffCount: 1)

        XCTAssertEqual(info.staffCount, 1)
        XCTAssertNil(info.staffDistance)
    }

    func testPartStaffInfoGrandStaff() {
        let info = PartStaffInfo(staffCount: 2, staffDistance: 70)

        XCTAssertEqual(info.staffCount, 2)
        XCTAssertEqual(info.staffDistance, 70)
    }

    // MARK: - StaffPositionInfo Tests

    func testStaffPositionInfoHeight() {
        let info = StaffPositionInfo(partIndex: 0, staffNumber: 1, topY: 100, bottomY: 140, centerLineY: 120)

        XCTAssertEqual(info.height, 40)
    }

    // MARK: - SystemPositionInfo Tests

    func testSystemPositionInfo() {
        let info = SystemPositionInfo(systemIndex: 0, topY: 50, bottomY: 250, height: 200)

        XCTAssertEqual(info.systemIndex, 0)
        XCTAssertEqual(info.topY, 50)
        XCTAssertEqual(info.bottomY, 250)
        XCTAssertEqual(info.height, 200)
    }
}
