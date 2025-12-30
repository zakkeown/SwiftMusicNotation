import XCTest
@testable import MusicNotationLayout
@testable import MusicNotationCore

final class LayoutTests: XCTestCase {

    // MARK: - Units Tests

    func testStaffSpacesCreation() {
        let oneSpace = StaffSpaces(1.0)
        XCTAssertEqual(oneSpace.value, 1.0)

        let zero = StaffSpaces.zero
        XCTAssertEqual(zero.value, 0.0)

        let one = StaffSpaces.one
        XCTAssertEqual(one.value, 1.0)
    }

    func testStaffSpacesToPoints() {
        let oneSpace = StaffSpaces(1.0)
        // At 32 point staff height (4 spaces), 1 space = 8 points
        let points = oneSpace.toPoints(staffHeight: 32)
        XCTAssertEqual(points, 8.0, accuracy: 0.001)
    }

    func testStaffSpacesFromPoints() {
        let staffSpaces = StaffSpaces.fromPoints(8.0, staffHeight: 32)
        XCTAssertEqual(staffSpaces.value, 1.0, accuracy: 0.001)
    }

    func testStaffSpacesArithmetic() {
        let a = StaffSpaces(2.0)
        let b = StaffSpaces(3.0)

        XCTAssertEqual((a + b).value, 5.0)
        XCTAssertEqual((b - a).value, 1.0)
        XCTAssertEqual((a * 2).value, 4.0)
        XCTAssertEqual((b / 3).value, 1.0)
        XCTAssertEqual((-a).value, -2.0)
    }

    func testStaffSpacesComparison() {
        let a = StaffSpaces(1.0)
        let b = StaffSpaces(2.0)

        XCTAssertTrue(a < b)
        XCTAssertFalse(b < a)
        XCTAssertTrue(a <= a)
    }

    func testTenthsConversion() {
        let tenths = Tenths(40.0) // One staff space in MusicXML
        let staffSpaces = tenths.toStaffSpaces()
        XCTAssertEqual(staffSpaces.value, 1.0, accuracy: 0.001)
    }

    func testTenthsFromStaffSpaces() {
        let staffSpaces = StaffSpaces(2.0)
        let tenths = Tenths.fromStaffSpaces(staffSpaces)
        XCTAssertEqual(tenths.value, 80.0, accuracy: 0.001)
    }

    func testTenthsArithmetic() {
        let a = Tenths(40.0)
        let b = Tenths(20.0)

        XCTAssertEqual((a + b).value, 60.0)
        XCTAssertEqual((a - b).value, 20.0)
        XCTAssertEqual((a * 2).value, 80.0)
        XCTAssertEqual((a / 2).value, 20.0)
    }

    // MARK: - Position Types Tests

    func testStaffPosition() {
        let pos = StaffPosition(x: StaffSpaces(1.0), y: StaffSpaces(2.0))
        XCTAssertEqual(pos.x.value, 1.0)
        XCTAssertEqual(pos.y.value, 2.0)

        let zero = StaffPosition.zero
        XCTAssertEqual(zero.x.value, 0.0)
        XCTAssertEqual(zero.y.value, 0.0)
    }

    func testStaffPositionToPoint() {
        let pos = StaffPosition(x: StaffSpaces(1.0), y: StaffSpaces(2.0))
        let point = pos.toPoint(staffHeight: 32)
        XCTAssertEqual(point.x, 8.0, accuracy: 0.001)
        XCTAssertEqual(point.y, 16.0, accuracy: 0.001)
    }

    func testStaffSize() {
        let size = StaffSize(width: StaffSpaces(4.0), height: StaffSpaces(2.0))
        XCTAssertEqual(size.width.value, 4.0)
        XCTAssertEqual(size.height.value, 2.0)
    }

    func testStaffRect() {
        let rect = StaffRect(
            x: StaffSpaces(1.0),
            y: StaffSpaces(2.0),
            width: StaffSpaces(3.0),
            height: StaffSpaces(4.0)
        )

        XCTAssertEqual(rect.minX.value, 1.0)
        XCTAssertEqual(rect.maxX.value, 4.0)
        XCTAssertEqual(rect.minY.value, 2.0)
        XCTAssertEqual(rect.maxY.value, 6.0)
        XCTAssertEqual(rect.midX.value, 2.5)
        XCTAssertEqual(rect.midY.value, 4.0)
    }

    func testStaffRectIntersection() {
        let rect1 = StaffRect(x: StaffSpaces(0), y: StaffSpaces(0), width: StaffSpaces(2), height: StaffSpaces(2))
        let rect2 = StaffRect(x: StaffSpaces(1), y: StaffSpaces(1), width: StaffSpaces(2), height: StaffSpaces(2))
        let rect3 = StaffRect(x: StaffSpaces(5), y: StaffSpaces(5), width: StaffSpaces(2), height: StaffSpaces(2))

        XCTAssertTrue(rect1.intersects(rect2))
        XCTAssertFalse(rect1.intersects(rect3))
    }

    func testStaffRectUnion() {
        let rect1 = StaffRect(x: StaffSpaces(0), y: StaffSpaces(0), width: StaffSpaces(2), height: StaffSpaces(2))
        let rect2 = StaffRect(x: StaffSpaces(3), y: StaffSpaces(3), width: StaffSpaces(2), height: StaffSpaces(2))

        let union = rect1.union(rect2)

        XCTAssertEqual(union.minX.value, 0.0)
        XCTAssertEqual(union.minY.value, 0.0)
        XCTAssertEqual(union.maxX.value, 5.0)
        XCTAssertEqual(union.maxY.value, 5.0)
    }

    // MARK: - Scaling Context Tests

    func testScalingContext() {
        let context = ScalingContext(
            millimetersPerStaffSpace: 7.2143,
            tenthsPerStaffSpace: 40,
            staffHeightPoints: 32
        )

        XCTAssertEqual(context.pointsPerStaffSpace, 8.0, accuracy: 0.001)
    }

    func testScalingContextConversions() {
        let context = ScalingContext(staffHeightPoints: 32)

        let tenths = Tenths(40)
        let points = context.tenthsToPoints(tenths)
        XCTAssertEqual(points, 8.0, accuracy: 0.1)

        let staffSpaces = StaffSpaces(2.0)
        let ssPoints = context.staffSpacesToPoints(staffSpaces)
        XCTAssertEqual(ssPoints, 16.0, accuracy: 0.001)
    }

    // MARK: - Horizontal Spacing Tests

    func testHorizontalSpacingEngine() {
        let engine = HorizontalSpacingEngine()

        // Test ideal width calculation
        let quarterWidth = engine.computeIdealWidth(duration: 1, divisions: 1)
        XCTAssertGreaterThan(quarterWidth, 0)

        let halfWidth = engine.computeIdealWidth(duration: 2, divisions: 1)
        XCTAssertGreaterThan(halfWidth, quarterWidth)

        let wholeWidth = engine.computeIdealWidth(duration: 4, divisions: 1)
        XCTAssertGreaterThan(wholeWidth, halfWidth)
    }

    func testSpacingComputation() {
        let engine = HorizontalSpacingEngine()

        let elements = [
            SpacingElement(position: 0, type: .note),
            SpacingElement(position: 1, type: .note),
            SpacingElement(position: 2, type: .note),
            SpacingElement(position: 3, type: .note)
        ]

        let result = engine.computeSpacing(elements: elements, divisions: 1, measureDuration: 4)

        XCTAssertEqual(result.columns.count, 4)
        XCTAssertGreaterThan(result.totalWidth, 0)

        // Each column should be at increasing x positions
        for i in 1..<result.columns.count {
            XCTAssertGreaterThan(result.columns[i].x, result.columns[i-1].x)
        }
    }

    func testSpacingJustification() {
        let engine = HorizontalSpacingEngine()

        let elements = [
            SpacingElement(position: 0, type: .note),
            SpacingElement(position: 1, type: .note)
        ]

        let result = engine.computeSpacing(elements: elements, divisions: 1, measureDuration: 2)
        let targetWidth: CGFloat = 200

        let justified = engine.justify(result: result, targetWidth: targetWidth)

        XCTAssertEqual(justified.totalWidth, targetWidth)
    }

    func testSpacingConfiguration() {
        var config = SpacingConfiguration()
        config.quarterNoteSpacing = 40.0
        config.minimumNoteSpacing = 15.0

        let engine = HorizontalSpacingEngine(config: config)

        let width = engine.computeIdealWidth(duration: 1, divisions: 1)
        XCTAssertGreaterThanOrEqual(width, config.minimumNoteSpacing)
    }

    // MARK: - System Spacing Tests

    func testSystemBreaks() {
        let engine = SystemSpacingEngine()

        let measureWidths: [CGFloat] = [100, 100, 100, 100, 100]
        let systemWidth: CGFloat = 250

        let breaks = engine.computeSystemBreaks(measureWidths: measureWidths, systemWidth: systemWidth)

        // Should have breaks to fit measures
        XCTAssertGreaterThan(breaks.count, 0)

        // Verify all measures are accounted for
        let totalMeasures = breaks.reduce(0) { $0 + $1.measureCount }
        XCTAssertEqual(totalMeasures, measureWidths.count)
    }

    func testSystemJustification() {
        let engine = SystemSpacingEngine()

        let spacings = [
            MeasureSpacing(measureIndex: 0, naturalWidth: 100),
            MeasureSpacing(measureIndex: 1, naturalWidth: 100)
        ]

        let justified = engine.justifySystem(measureSpacings: spacings, systemWidth: 300)

        // Total width should equal system width
        let totalWidth = justified.reduce(CGFloat(0)) { $0 + $1.width }
        XCTAssertEqual(totalWidth, 300, accuracy: 0.001)
    }

    // MARK: - Spacing Result Tests

    func testSpacingResultXPosition() {
        let columns = [
            SpacingColumn(position: 0, x: 0),
            SpacingColumn(position: 4, x: 100),
            SpacingColumn(position: 8, x: 200)
        ]

        let result = SpacingResult(columns: columns, totalWidth: 250, measureDuration: 8)

        // Exact position lookup
        XCTAssertEqual(result.xPosition(for: 0), 0)
        XCTAssertEqual(result.xPosition(for: 4), 100)
        XCTAssertEqual(result.xPosition(for: 8), 200)
        XCTAssertNil(result.xPosition(for: 2))

        // Interpolated position
        let interpolated = result.interpolatedX(for: 2)
        XCTAssertEqual(interpolated, 50, accuracy: 0.001)
    }

    // MARK: - System Break Tests

    func testSystemBreakProperties() {
        let breakPoint = SystemBreak(startMeasure: 0, endMeasure: 3, naturalWidth: 400)

        XCTAssertEqual(breakPoint.measureCount, 4)
        XCTAssertEqual(breakPoint.startMeasure, 0)
        XCTAssertEqual(breakPoint.endMeasure, 3)
    }
}
