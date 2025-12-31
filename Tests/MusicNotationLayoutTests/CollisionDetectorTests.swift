import XCTest
import CoreGraphics
@testable import MusicNotationLayout
@testable import MusicNotationCore

final class CollisionDetectorTests: XCTestCase {

    private var detector: CollisionDetector!

    override func setUp() {
        super.setUp()
        detector = CollisionDetector()
    }

    // MARK: - Basic Intersection Tests

    func testIntersectsTrue() {
        let a = CGRect(x: 0, y: 0, width: 10, height: 10)
        let b = CGRect(x: 5, y: 5, width: 10, height: 10)

        XCTAssertTrue(detector.intersects(a, b))
    }

    func testIntersectsFalse() {
        let a = CGRect(x: 0, y: 0, width: 10, height: 10)
        let b = CGRect(x: 20, y: 20, width: 10, height: 10)

        XCTAssertFalse(detector.intersects(a, b))
    }

    func testIntersectsEdgeTouching() {
        let a = CGRect(x: 0, y: 0, width: 10, height: 10)
        let b = CGRect(x: 10, y: 0, width: 10, height: 10)

        // Edge touching is NOT intersection in CGRect
        XCTAssertFalse(detector.intersects(a, b))
    }

    func testIntersectsWithPaddingTrue() {
        let a = CGRect(x: 0, y: 0, width: 10, height: 10)
        let b = CGRect(x: 12, y: 0, width: 10, height: 10)

        // Without padding, no intersection
        XCTAssertFalse(detector.intersects(a, b))
        // With padding of 3, they should intersect
        XCTAssertTrue(detector.intersects(a, b, padding: 3))
    }

    func testIntersectsWithPaddingFalse() {
        let a = CGRect(x: 0, y: 0, width: 10, height: 10)
        let b = CGRect(x: 20, y: 0, width: 10, height: 10)

        XCTAssertFalse(detector.intersects(a, b, padding: 2))
    }

    // MARK: - Overlap Tests

    func testOverlapReturnsIntersection() {
        let a = CGRect(x: 0, y: 0, width: 10, height: 10)
        let b = CGRect(x: 5, y: 5, width: 10, height: 10)

        let overlap = detector.overlap(a, b)
        XCTAssertNotNil(overlap)
        XCTAssertEqual(overlap?.origin.x, 5)
        XCTAssertEqual(overlap?.origin.y, 5)
        XCTAssertEqual(overlap?.width, 5)
        XCTAssertEqual(overlap?.height, 5)
    }

    func testOverlapReturnsNilForNonIntersecting() {
        let a = CGRect(x: 0, y: 0, width: 10, height: 10)
        let b = CGRect(x: 20, y: 20, width: 10, height: 10)

        XCTAssertNil(detector.overlap(a, b))
    }

    // MARK: - Minimum Displacement Tests

    func testMinimumDisplacementReturnsNilForNonIntersecting() {
        let a = CGRect(x: 0, y: 0, width: 10, height: 10)
        let b = CGRect(x: 20, y: 20, width: 10, height: 10)

        XCTAssertNil(detector.minimumDisplacement(from: a, avoiding: b))
    }

    func testMinimumDisplacementReturnsVector() {
        let a = CGRect(x: 5, y: 5, width: 10, height: 10)
        let b = CGRect(x: 0, y: 0, width: 10, height: 10)

        let displacement = detector.minimumDisplacement(from: a, avoiding: b)
        XCTAssertNotNil(displacement)
        // Should be the minimum displacement needed
    }

    // MARK: - Accidental Collision Resolution Tests

    func testResolveAccidentalCollisionsEmpty() {
        let offsets = detector.resolveAccidentalCollisions(accidentals: [], noteheadWidth: 1.0)
        XCTAssertTrue(offsets.isEmpty)
    }

    func testResolveAccidentalCollisionsSingle() {
        let accidentals = [
            AccidentalBounds(
                bounds: CGRect(x: 0, y: 0, width: 1, height: 2),
                staffPosition: 0,
                accidental: .sharp
            )
        ]

        let offsets = detector.resolveAccidentalCollisions(accidentals: accidentals, noteheadWidth: 1.0)
        XCTAssertEqual(offsets.count, 1)
        XCTAssertTrue(offsets[0] < 0) // Should be to the left of notehead
    }

    func testResolveAccidentalCollisionsMultiple() {
        let accidentals = [
            AccidentalBounds(
                bounds: CGRect(x: 0, y: 0, width: 1, height: 2),
                staffPosition: 0,
                accidental: .sharp
            ),
            AccidentalBounds(
                bounds: CGRect(x: 0, y: 1, width: 1, height: 2),
                staffPosition: 1,
                accidental: .flat
            )
        ]

        let offsets = detector.resolveAccidentalCollisions(accidentals: accidentals, noteheadWidth: 1.0)
        XCTAssertEqual(offsets.count, 2)
        // Both should be negative (left of notehead)
        XCTAssertTrue(offsets.allSatisfy { $0 < 0 })
    }

    // MARK: - Stem Collision Tests

    func testCheckStemCollisionTrue() {
        let stemLine = CGRect(x: 5, y: 0, width: 0.1, height: 10)
        let obstacles = [CGRect(x: 4, y: 5, width: 3, height: 2)]

        XCTAssertTrue(detector.checkStemCollision(stemLine: stemLine, obstacles: obstacles))
    }

    func testCheckStemCollisionFalse() {
        let stemLine = CGRect(x: 5, y: 0, width: 0.1, height: 10)
        let obstacles = [CGRect(x: 20, y: 5, width: 3, height: 2)]

        XCTAssertFalse(detector.checkStemCollision(stemLine: stemLine, obstacles: obstacles))
    }

    func testCheckStemCollisionEmptyObstacles() {
        let stemLine = CGRect(x: 5, y: 0, width: 0.1, height: 10)
        XCTAssertFalse(detector.checkStemCollision(stemLine: stemLine, obstacles: []))
    }

    func testAdjustStemLengthNoCollision() {
        let stemStart = CGPoint(x: 5, y: 10)
        let stemEnd = CGPoint(x: 5, y: 0)
        let obstacles: [CGRect] = []

        let adjustment = detector.adjustStemLength(
            stemStart: stemStart,
            stemEnd: stemEnd,
            direction: .up,
            obstacles: obstacles
        )
        XCTAssertEqual(adjustment, 0)
    }

    // MARK: - Beam Collision Tests

    func testCheckBeamCollisionTrue() {
        let beamBounds = CGRect(x: 0, y: 5, width: 20, height: 2)
        let noteheads = [CGRect(x: 5, y: 4, width: 2, height: 3)]

        XCTAssertTrue(detector.checkBeamCollision(beamBounds: beamBounds, noteheads: noteheads))
    }

    func testCheckBeamCollisionFalse() {
        let beamBounds = CGRect(x: 0, y: 5, width: 20, height: 2)
        let noteheads = [CGRect(x: 5, y: 20, width: 2, height: 2)]

        XCTAssertFalse(detector.checkBeamCollision(beamBounds: beamBounds, noteheads: noteheads))
    }

    func testAdjustBeamPositionNoCollision() {
        let beamBounds = CGRect(x: 0, y: 0, width: 20, height: 2)
        let noteheads: [CGRect] = []

        let adjustment = detector.adjustBeamPosition(
            beamBounds: beamBounds,
            noteheads: noteheads,
            stemDirection: .up
        )
        XCTAssertEqual(adjustment, 0)
    }

    func testAdjustBeamPositionWithCollision() {
        let beamBounds = CGRect(x: 0, y: 5, width: 20, height: 2)
        let noteheads = [CGRect(x: 5, y: 4, width: 2, height: 3)]

        let adjustment = detector.adjustBeamPosition(
            beamBounds: beamBounds,
            noteheads: noteheads,
            stemDirection: .up
        )
        // Should suggest moving the beam
        XCTAssertNotEqual(adjustment, 0)
    }

    // MARK: - Articulation Stack Tests

    func testResolveArticulationStackEmpty() {
        let offsets = detector.resolveArticulationStack(
            articulations: [],
            noteBounds: CGRect(x: 0, y: 0, width: 2, height: 2),
            placement: .above
        )
        XCTAssertTrue(offsets.isEmpty)
    }

    func testResolveArticulationStackAbove() {
        let articulations = [
            ArticulationBounds(bounds: CGRect(x: 0, y: 0, width: 1, height: 1), articulation: .accent),
            ArticulationBounds(bounds: CGRect(x: 0, y: 0, width: 1, height: 1), articulation: .staccato)
        ]
        let noteBounds = CGRect(x: 0, y: 10, width: 2, height: 2)

        let offsets = detector.resolveArticulationStack(
            articulations: articulations,
            noteBounds: noteBounds,
            placement: .above
        )

        XCTAssertEqual(offsets.count, 2)
        // Above means Y should decrease (move up)
        XCTAssertTrue(offsets[0] < noteBounds.minY)
        XCTAssertTrue(offsets[1] < offsets[0])
    }

    func testResolveArticulationStackBelow() {
        let articulations = [
            ArticulationBounds(bounds: CGRect(x: 0, y: 0, width: 1, height: 1), articulation: .accent),
            ArticulationBounds(bounds: CGRect(x: 0, y: 0, width: 1, height: 1), articulation: .staccato)
        ]
        let noteBounds = CGRect(x: 0, y: 10, width: 2, height: 2)

        let offsets = detector.resolveArticulationStack(
            articulations: articulations,
            noteBounds: noteBounds,
            placement: .below
        )

        XCTAssertEqual(offsets.count, 2)
        // Below means Y should increase (move down)
        XCTAssertTrue(offsets[0] > noteBounds.maxY)
        XCTAssertTrue(offsets[1] > offsets[0])
    }

    // MARK: - Dynamic Position Tests

    func testFindDynamicPositionNoObstacles() {
        let dynamicBounds = CGRect(x: 10, y: 0, width: 5, height: 3)
        let staffBounds = CGRect(x: 0, y: 0, width: 100, height: 20)

        let position = detector.findDynamicPosition(
            dynamicBounds: dynamicBounds,
            staffBounds: staffBounds,
            obstacles: [],
            preferredPlacement: .below
        )

        // Should be below the staff
        XCTAssertTrue(position.y > staffBounds.maxY)
    }

    func testFindDynamicPositionAbove() {
        let dynamicBounds = CGRect(x: 10, y: 0, width: 5, height: 3)
        let staffBounds = CGRect(x: 0, y: 10, width: 100, height: 20)

        let position = detector.findDynamicPosition(
            dynamicBounds: dynamicBounds,
            staffBounds: staffBounds,
            obstacles: [],
            preferredPlacement: .above
        )

        // Should be above the staff
        XCTAssertTrue(position.y < staffBounds.minY)
    }

    // MARK: - Curve Collision Tests

    func testCheckCurveCollisionNoObstacles() {
        let curvePoints = [CGPoint(x: 0, y: 0), CGPoint(x: 5, y: 5), CGPoint(x: 10, y: 0)]
        let collisions = detector.checkCurveCollision(curvePoints: curvePoints, obstacles: [])

        XCTAssertTrue(collisions.isEmpty)
    }

    func testCheckCurveCollisionWithObstacle() {
        let curvePoints = [CGPoint(x: 0, y: 0), CGPoint(x: 5, y: 5), CGPoint(x: 10, y: 0)]
        let obstacles = [CGRect(x: 4, y: 4, width: 3, height: 3)]

        let collisions = detector.checkCurveCollision(curvePoints: curvePoints, obstacles: obstacles)

        XCTAssertEqual(collisions.count, 1)
    }

    func testAdjustCurveHeightNoCollision() {
        let startPoint = CGPoint(x: 0, y: 10)
        let endPoint = CGPoint(x: 20, y: 10)
        let controlPoint = CGPoint(x: 10, y: 5)

        let adjustment = detector.adjustCurveHeight(
            startPoint: startPoint,
            endPoint: endPoint,
            controlPoint: controlPoint,
            obstacles: [],
            direction: .above
        )

        XCTAssertEqual(adjustment, 0)
    }

    // MARK: - Batch Collision Detection Tests

    func testFindAllCollisionsEmpty() {
        let collisions = detector.findAllCollisions(bounds: [])
        XCTAssertTrue(collisions.isEmpty)
    }

    func testFindAllCollisionsSingle() {
        let bounds = [CGRect(x: 0, y: 0, width: 10, height: 10)]
        let collisions = detector.findAllCollisions(bounds: bounds)
        XCTAssertTrue(collisions.isEmpty)
    }

    func testFindAllCollisionsMultiple() {
        let bounds = [
            CGRect(x: 0, y: 0, width: 10, height: 10),
            CGRect(x: 5, y: 5, width: 10, height: 10),
            CGRect(x: 20, y: 20, width: 10, height: 10)
        ]

        let collisions = detector.findAllCollisions(bounds: bounds)

        // Only first two should collide
        XCTAssertEqual(collisions.count, 1)
        XCTAssertEqual(collisions[0].0, 0)
        XCTAssertEqual(collisions[0].1, 1)
    }

    func testFindCollidingElementsNone() {
        let target = CGRect(x: 0, y: 0, width: 10, height: 10)
        let candidates = [
            CGRect(x: 20, y: 0, width: 10, height: 10),
            CGRect(x: 40, y: 0, width: 10, height: 10)
        ]

        let colliding = detector.findCollidingElements(target: target, candidates: candidates)
        XCTAssertTrue(colliding.isEmpty)
    }

    func testFindCollidingElementsSome() {
        let target = CGRect(x: 5, y: 5, width: 10, height: 10)
        let candidates = [
            CGRect(x: 0, y: 0, width: 10, height: 10),  // Collides
            CGRect(x: 40, y: 0, width: 10, height: 10), // No collision
            CGRect(x: 10, y: 10, width: 10, height: 10) // Collides
        ]

        let colliding = detector.findCollidingElements(target: target, candidates: candidates)

        XCTAssertEqual(colliding.count, 2)
        XCTAssertTrue(colliding.contains(0))
        XCTAssertTrue(colliding.contains(2))
    }
}

// MARK: - CollisionConfiguration Tests

final class CollisionConfigurationTests: XCTestCase {

    func testDefaultConfiguration() {
        let config = CollisionConfiguration()

        XCTAssertEqual(config.minimumHorizontalGap, 0.5)
        XCTAssertEqual(config.minimumVerticalGap, 0.5)
        XCTAssertEqual(config.accidentalNoteheadGap, 0.2)
        XCTAssertEqual(config.stemWidth, 0.12)
        XCTAssertEqual(config.beamClearance, 0.5)
    }

    func testCustomConfiguration() {
        var config = CollisionConfiguration()
        config.minimumHorizontalGap = 1.0
        config.beamClearance = 2.0

        XCTAssertEqual(config.minimumHorizontalGap, 1.0)
        XCTAssertEqual(config.beamClearance, 2.0)
    }
}

// MARK: - SpatialHash Tests

final class SpatialHashTests: XCTestCase {

    private var spatialHash: SpatialHash!

    override func setUp() {
        super.setUp()
        spatialHash = SpatialHash(cellSize: 10.0)
    }

    func testInsertAndQuery() {
        let rect1 = CGRect(x: 0, y: 0, width: 5, height: 5)
        let rect2 = CGRect(x: 3, y: 3, width: 5, height: 5)
        let rect3 = CGRect(x: 50, y: 50, width: 5, height: 5)

        _ = spatialHash.insert(rect1)
        _ = spatialHash.insert(rect2)
        _ = spatialHash.insert(rect3)

        // Query for rect1's area
        let results = spatialHash.query(rect1)

        // Should find rect1 and rect2 (they overlap)
        XCTAssertTrue(results.contains(0))
        XCTAssertTrue(results.contains(1))
        XCTAssertFalse(results.contains(2)) // rect3 is far away
    }

    func testClear() {
        let rect = CGRect(x: 0, y: 0, width: 5, height: 5)
        _ = spatialHash.insert(rect)

        var results = spatialHash.query(rect)
        XCTAssertEqual(results.count, 1)

        spatialHash.clear()

        results = spatialHash.query(rect)
        XCTAssertTrue(results.isEmpty)
    }

    func testQueryEmptyHash() {
        let rect = CGRect(x: 0, y: 0, width: 5, height: 5)
        let results = spatialHash.query(rect)
        XCTAssertTrue(results.isEmpty)
    }

    func testLargeRectSpansMultipleCells() {
        let largeRect = CGRect(x: 0, y: 0, width: 25, height: 25)
        _ = spatialHash.insert(largeRect)

        // Query from various cells
        let query1 = spatialHash.query(CGRect(x: 5, y: 5, width: 1, height: 1))
        let query2 = spatialHash.query(CGRect(x: 20, y: 20, width: 1, height: 1))

        XCTAssertTrue(query1.contains(0))
        XCTAssertTrue(query2.contains(0))
    }
}

// MARK: - CGRect Extension Tests

final class CGRectExtensionTests: XCTestCase {

    func testCenter() {
        let rect = CGRect(x: 10, y: 20, width: 30, height: 40)
        let center = rect.center

        XCTAssertEqual(center.x, 25)
        XCTAssertEqual(center.y, 40)
    }

    func testExpanded() {
        let rect = CGRect(x: 10, y: 10, width: 20, height: 20)
        let expanded = rect.expanded(by: 5)

        XCTAssertEqual(expanded.origin.x, 5)
        XCTAssertEqual(expanded.origin.y, 5)
        XCTAssertEqual(expanded.width, 30)
        XCTAssertEqual(expanded.height, 30)
    }

    func testDistanceOverlapping() {
        let rect1 = CGRect(x: 0, y: 0, width: 10, height: 10)
        let rect2 = CGRect(x: 5, y: 5, width: 10, height: 10)

        XCTAssertEqual(rect1.distance(to: rect2), 0)
    }

    func testDistanceSeparated() {
        let rect1 = CGRect(x: 0, y: 0, width: 10, height: 10)
        let rect2 = CGRect(x: 20, y: 0, width: 10, height: 10)

        // Distance should be 10 (horizontal gap)
        XCTAssertEqual(rect1.distance(to: rect2), 10)
    }

    func testDistanceDiagonal() {
        let rect1 = CGRect(x: 0, y: 0, width: 10, height: 10)
        let rect2 = CGRect(x: 13, y: 14, width: 10, height: 10)

        // Distance is sqrt(3^2 + 4^2) = 5
        XCTAssertEqual(rect1.distance(to: rect2), 5)
    }
}
