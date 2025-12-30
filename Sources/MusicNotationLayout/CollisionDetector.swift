import Foundation
import CoreGraphics
import MusicNotationCore

// MARK: - Collision Detector

/// Detects and resolves collisions between music notation elements.
public final class CollisionDetector {
    /// Configuration for collision detection.
    public var config: CollisionConfiguration

    public init(config: CollisionConfiguration = CollisionConfiguration()) {
        self.config = config
    }

    // MARK: - Basic Collision Detection

    /// Checks if two bounding boxes intersect.
    public func intersects(_ a: CGRect, _ b: CGRect) -> Bool {
        a.intersects(b)
    }

    /// Checks if two bounding boxes intersect with padding.
    public func intersects(_ a: CGRect, _ b: CGRect, padding: CGFloat) -> Bool {
        let expandedA = a.insetBy(dx: -padding, dy: -padding)
        return expandedA.intersects(b)
    }

    /// Calculates the overlap between two rectangles.
    public func overlap(_ a: CGRect, _ b: CGRect) -> CGRect? {
        guard a.intersects(b) else { return nil }
        return a.intersection(b)
    }

    /// Calculates the minimum displacement to resolve a collision.
    public func minimumDisplacement(from a: CGRect, avoiding b: CGRect) -> CGVector? {
        guard a.intersects(b) else { return nil }

        let intersection = a.intersection(b)

        // Find the smallest displacement direction
        let leftDisplacement = -(intersection.minX - a.minX + intersection.width)
        let rightDisplacement = b.maxX - a.minX + config.minimumHorizontalGap
        let upDisplacement = -(intersection.minY - a.minY + intersection.height)
        let downDisplacement = b.maxY - a.minY + config.minimumVerticalGap

        // Choose the smallest absolute displacement
        let horizontalDisplacement = abs(leftDisplacement) < abs(rightDisplacement) ? leftDisplacement : rightDisplacement
        let verticalDisplacement = abs(upDisplacement) < abs(downDisplacement) ? upDisplacement : downDisplacement

        if abs(horizontalDisplacement) < abs(verticalDisplacement) {
            return CGVector(dx: horizontalDisplacement, dy: 0)
        } else {
            return CGVector(dx: 0, dy: verticalDisplacement)
        }
    }

    // MARK: - Accidental Collision Detection

    /// Resolves collisions between accidentals in a chord or column.
    /// Returns adjusted X offsets for each accidental.
    public func resolveAccidentalCollisions(
        accidentals: [AccidentalBounds],
        noteheadWidth: CGFloat
    ) -> [CGFloat] {
        guard !accidentals.isEmpty else { return [] }

        // Sort by pitch (highest first for typical stacking)
        let sorted = accidentals.enumerated().sorted { $0.element.staffPosition > $1.element.staffPosition }

        var offsets: [CGFloat] = Array(repeating: 0, count: accidentals.count)
        var placedBounds: [(index: Int, bounds: CGRect)] = []

        for (originalIndex, accidental) in sorted {
            var currentOffset: CGFloat = -noteheadWidth - config.accidentalNoteheadGap - accidental.bounds.width
            var placed = false

            while !placed {
                let testBounds = accidental.bounds.offsetBy(dx: currentOffset, dy: 0)

                // Check against all placed accidentals
                var collision = false
                for placed in placedBounds {
                    if intersects(testBounds, placed.bounds, padding: config.accidentalAccidentalGap) {
                        collision = true
                        break
                    }
                }

                if !collision {
                    offsets[originalIndex] = currentOffset
                    placedBounds.append((originalIndex, testBounds))
                    placed = true
                } else {
                    // Move further left
                    currentOffset -= config.accidentalColumnWidth
                }

                // Safety limit
                if currentOffset < -noteheadWidth * 10 {
                    offsets[originalIndex] = currentOffset
                    placed = true
                }
            }
        }

        return offsets
    }

    // MARK: - Stem Collision Detection

    /// Checks if a stem collides with any beams or other elements.
    public func checkStemCollision(
        stemLine: CGRect,
        obstacles: [CGRect]
    ) -> Bool {
        for obstacle in obstacles {
            if intersects(stemLine, obstacle, padding: config.stemClearance) {
                return true
            }
        }
        return false
    }

    /// Calculates stem length adjustment to avoid collision.
    public func adjustStemLength(
        stemStart: CGPoint,
        stemEnd: CGPoint,
        direction: StemDirection,
        obstacles: [CGRect]
    ) -> CGFloat {
        let stemRect = CGRect(
            x: stemStart.x - config.stemWidth / 2,
            y: min(stemStart.y, stemEnd.y),
            width: config.stemWidth,
            height: abs(stemEnd.y - stemStart.y)
        )

        var maxExtension: CGFloat = 0

        for obstacle in obstacles {
            if intersects(stemRect, obstacle, padding: config.stemClearance) {
                let extension_: CGFloat
                if direction == .up {
                    extension_ = stemRect.minY - obstacle.minY + config.stemClearance
                } else {
                    extension_ = obstacle.maxY - stemRect.maxY + config.stemClearance
                }
                maxExtension = max(maxExtension, extension_)
            }
        }

        return maxExtension
    }

    // MARK: - Beam Collision Detection

    /// Checks if a beam collides with noteheads or other elements.
    public func checkBeamCollision(
        beamBounds: CGRect,
        noteheads: [CGRect]
    ) -> Bool {
        for notehead in noteheads {
            if intersects(beamBounds, notehead, padding: config.beamClearance) {
                return true
            }
        }
        return false
    }

    /// Calculates beam position adjustment to avoid noteheads.
    public func adjustBeamPosition(
        beamBounds: CGRect,
        noteheads: [CGRect],
        stemDirection: StemDirection
    ) -> CGFloat {
        var maxAdjustment: CGFloat = 0

        for notehead in noteheads {
            if intersects(beamBounds, notehead, padding: config.beamClearance) {
                let adjustment: CGFloat
                if stemDirection == .up {
                    adjustment = notehead.minY - beamBounds.maxY - config.beamClearance
                } else {
                    adjustment = notehead.maxY - beamBounds.minY + config.beamClearance
                }
                if abs(adjustment) > abs(maxAdjustment) {
                    maxAdjustment = adjustment
                }
            }
        }

        return maxAdjustment
    }

    // MARK: - Articulation Collision Detection

    /// Resolves articulation stacking above/below notes.
    public func resolveArticulationStack(
        articulations: [ArticulationBounds],
        noteBounds: CGRect,
        placement: Placement
    ) -> [CGFloat] {
        guard !articulations.isEmpty else { return [] }

        var offsets: [CGFloat] = []
        var currentY: CGFloat

        if placement == .above {
            currentY = noteBounds.minY - config.articulationNoteGap
            for articulation in articulations {
                currentY -= articulation.bounds.height
                offsets.append(currentY)
                currentY -= config.articulationStackGap
            }
        } else {
            currentY = noteBounds.maxY + config.articulationNoteGap
            for articulation in articulations {
                offsets.append(currentY)
                currentY += articulation.bounds.height + config.articulationStackGap
            }
        }

        return offsets
    }

    // MARK: - Dynamic/Direction Collision Detection

    /// Finds a non-colliding position for a dynamic marking.
    public func findDynamicPosition(
        dynamicBounds: CGRect,
        staffBounds: CGRect,
        obstacles: [CGRect],
        preferredPlacement: Placement
    ) -> CGPoint {
        var testY: CGFloat

        if preferredPlacement == .below {
            testY = staffBounds.maxY + config.dynamicStaffGap
        } else {
            testY = staffBounds.minY - config.dynamicStaffGap - dynamicBounds.height
        }

        let testX = dynamicBounds.minX

        // Check for collisions and adjust
        var testBounds = CGRect(
            x: testX,
            y: testY,
            width: dynamicBounds.width,
            height: dynamicBounds.height
        )

        var iterations = 0
        let maxIterations = 10
        let adjustmentStep: CGFloat = preferredPlacement == .below ? config.dynamicStaffGap : -config.dynamicStaffGap

        while iterations < maxIterations {
            var collision = false
            for obstacle in obstacles {
                if intersects(testBounds, obstacle, padding: config.minimumVerticalGap) {
                    collision = true
                    break
                }
            }

            if !collision {
                return CGPoint(x: testX, y: testY)
            }

            testY += adjustmentStep
            testBounds = testBounds.offsetBy(dx: 0, dy: adjustmentStep)
            iterations += 1
        }

        return CGPoint(x: testX, y: testY)
    }

    // MARK: - Slur/Tie Collision Detection

    /// Checks if a curve (slur/tie) collides with obstacles.
    public func checkCurveCollision(
        curvePoints: [CGPoint],
        obstacles: [CGRect]
    ) -> [CGRect] {
        var collisions: [CGRect] = []

        // Sample points along the curve
        for obstacle in obstacles {
            for point in curvePoints {
                if obstacle.contains(point) {
                    collisions.append(obstacle)
                    break
                }
            }
        }

        return collisions
    }

    /// Calculates curve control point adjustment to avoid obstacles.
    public func adjustCurveHeight(
        startPoint: CGPoint,
        endPoint: CGPoint,
        controlPoint: CGPoint,
        obstacles: [CGRect],
        direction: CurveDirection
    ) -> CGFloat {
        var maxAdjustment: CGFloat = 0

        // Generate sample points along a quadratic bezier
        let sampleCount = 10
        for i in 0...sampleCount {
            let t = CGFloat(i) / CGFloat(sampleCount)
            let point = quadraticBezierPoint(start: startPoint, control: controlPoint, end: endPoint, t: t)

            for obstacle in obstacles {
                if obstacle.contains(point) {
                    let adjustment: CGFloat
                    if direction == .above {
                        adjustment = obstacle.minY - point.y - config.curveClearance
                    } else {
                        adjustment = obstacle.maxY - point.y + config.curveClearance
                    }
                    if abs(adjustment) > abs(maxAdjustment) {
                        maxAdjustment = adjustment
                    }
                }
            }
        }

        return maxAdjustment
    }

    private func quadraticBezierPoint(start: CGPoint, control: CGPoint, end: CGPoint, t: CGFloat) -> CGPoint {
        let oneMinusT = 1 - t
        let x = oneMinusT * oneMinusT * start.x + 2 * oneMinusT * t * control.x + t * t * end.x
        let y = oneMinusT * oneMinusT * start.y + 2 * oneMinusT * t * control.y + t * t * end.y
        return CGPoint(x: x, y: y)
    }

    // MARK: - Batch Collision Detection

    /// Finds all collisions among a set of bounding boxes.
    public func findAllCollisions(bounds: [CGRect]) -> [(Int, Int)] {
        var collisions: [(Int, Int)] = []

        for i in 0..<bounds.count {
            for j in (i + 1)..<bounds.count {
                if intersects(bounds[i], bounds[j]) {
                    collisions.append((i, j))
                }
            }
        }

        return collisions
    }

    /// Finds all elements that collide with a given bounds.
    public func findCollidingElements(
        target: CGRect,
        candidates: [CGRect]
    ) -> [Int] {
        var colliding: [Int] = []

        for (index, candidate) in candidates.enumerated() {
            if intersects(target, candidate) {
                colliding.append(index)
            }
        }

        return colliding
    }
}

// MARK: - Configuration

/// Configuration for collision detection thresholds.
public struct CollisionConfiguration: Sendable {
    /// Minimum horizontal gap between elements.
    public var minimumHorizontalGap: CGFloat = 0.5

    /// Minimum vertical gap between elements.
    public var minimumVerticalGap: CGFloat = 0.5

    /// Gap between accidental and notehead.
    public var accidentalNoteheadGap: CGFloat = 0.2

    /// Gap between stacked accidentals.
    public var accidentalAccidentalGap: CGFloat = 0.1

    /// Width of accidental column for stacking.
    public var accidentalColumnWidth: CGFloat = 1.0

    /// Stem width for collision detection.
    public var stemWidth: CGFloat = 0.12

    /// Clearance around stems.
    public var stemClearance: CGFloat = 0.25

    /// Clearance around beams.
    public var beamClearance: CGFloat = 0.5

    /// Gap between articulation and note.
    public var articulationNoteGap: CGFloat = 0.5

    /// Gap between stacked articulations.
    public var articulationStackGap: CGFloat = 0.25

    /// Gap between dynamic and staff.
    public var dynamicStaffGap: CGFloat = 1.0

    /// Clearance for curves (slurs/ties).
    public var curveClearance: CGFloat = 0.25

    public init() {}
}

// MARK: - Supporting Types

/// Bounds for an accidental with staff position.
public struct AccidentalBounds: Sendable {
    /// The bounding rectangle.
    public var bounds: CGRect

    /// Staff position (line/space number).
    public var staffPosition: Int

    /// The accidental type.
    public var accidental: Accidental

    public init(bounds: CGRect, staffPosition: Int, accidental: Accidental) {
        self.bounds = bounds
        self.staffPosition = staffPosition
        self.accidental = accidental
    }
}

/// Bounds for an articulation.
public struct ArticulationBounds: Sendable {
    /// The bounding rectangle.
    public var bounds: CGRect

    /// The articulation type.
    public var articulation: Articulation

    /// Priority for stacking (lower = closer to note).
    public var stackPriority: Int

    public init(bounds: CGRect, articulation: Articulation, stackPriority: Int = 0) {
        self.bounds = bounds
        self.articulation = articulation
        self.stackPriority = stackPriority
    }
}

/// Direction for curve placement.
public enum CurveDirection: Sendable {
    case above
    case below
}

// MARK: - CGRect Extensions

extension CGRect {
    /// Returns the center point of the rectangle.
    public var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }

    /// Expands the rectangle by the given amount on all sides.
    public func expanded(by amount: CGFloat) -> CGRect {
        insetBy(dx: -amount, dy: -amount)
    }

    /// Returns the distance to another rectangle (0 if overlapping).
    public func distance(to other: CGRect) -> CGFloat {
        if intersects(other) { return 0 }

        let dx = max(0, max(other.minX - maxX, minX - other.maxX))
        let dy = max(0, max(other.minY - maxY, minY - other.maxY))

        return sqrt(dx * dx + dy * dy)
    }
}

// MARK: - Spatial Index (for large-scale collision detection)

/// Simple spatial hash for efficient collision detection with many elements.
public class SpatialHash {
    private var cells: [Int: [Int]] = [:]
    private let cellSize: CGFloat
    private var bounds: [CGRect] = []

    public init(cellSize: CGFloat = 10.0) {
        self.cellSize = cellSize
    }

    /// Clears the spatial hash.
    public func clear() {
        cells.removeAll()
        bounds.removeAll()
    }

    /// Inserts a bounds into the spatial hash.
    public func insert(_ rect: CGRect) -> Int {
        let index = bounds.count
        bounds.append(rect)

        let minCellX = Int(floor(rect.minX / cellSize))
        let maxCellX = Int(floor(rect.maxX / cellSize))
        let minCellY = Int(floor(rect.minY / cellSize))
        let maxCellY = Int(floor(rect.maxY / cellSize))

        for cellX in minCellX...maxCellX {
            for cellY in minCellY...maxCellY {
                let key = hashKey(cellX, cellY)
                if cells[key] == nil {
                    cells[key] = []
                }
                cells[key]?.append(index)
            }
        }

        return index
    }

    /// Finds potential collisions for a given bounds.
    public func query(_ rect: CGRect) -> [Int] {
        var candidates = Set<Int>()

        let minCellX = Int(floor(rect.minX / cellSize))
        let maxCellX = Int(floor(rect.maxX / cellSize))
        let minCellY = Int(floor(rect.minY / cellSize))
        let maxCellY = Int(floor(rect.maxY / cellSize))

        for cellX in minCellX...maxCellX {
            for cellY in minCellY...maxCellY {
                let key = hashKey(cellX, cellY)
                if let cellContents = cells[key] {
                    for index in cellContents {
                        candidates.insert(index)
                    }
                }
            }
        }

        // Filter to actual intersections
        return candidates.filter { bounds[$0].intersects(rect) }
    }

    private func hashKey(_ x: Int, _ y: Int) -> Int {
        // Simple hash combining x and y
        return x * 73856093 ^ y * 19349663
    }
}
