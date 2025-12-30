import Foundation
import CoreGraphics
import MusicNotationLayout

// MARK: - Hit Tester

/// Provides hit testing for selectable elements in an engraved score.
///
/// `HitTester` enables interactive selection of music notation elements by determining
/// which elements are under a given point or within a selection rectangle. It uses a
/// spatial index for efficient lookups in large scores.
///
/// ## Basic Usage
///
/// ```swift
/// let hitTester = HitTester(engravedScore: engravedScore)
///
/// // Single-point hit test (e.g., tap or click)
/// if let element = hitTester.hitTest(at: tapLocation) {
///     print("Tapped on \(element.elementType)")
/// }
///
/// // Rectangle hit test (e.g., marquee selection)
/// let selection = hitTester.hitTest(in: selectionRect)
/// print("Selected \(selection.count) elements")
/// ```
///
/// ## Configuration
///
/// Use `HitTestConfiguration` to customize hit testing behavior:
///
/// ```swift
/// var config = HitTestConfiguration()
/// config.hitTolerance = 8.0  // Larger touch target
/// config.selectStaves = true  // Allow staff selection
/// config.selectableTypes = [.note, .rest, .chord]  // Limit selectable types
///
/// let hitTester = HitTester(engravedScore: score, config: config)
/// ```
///
/// ## Element Priority
///
/// When multiple elements overlap, the hit tester returns the topmost element
/// based on layer priority. Notes and chords have highest priority, followed by
/// rests, dynamics, directions, and finally structural elements like barlines.
///
/// ## Performance
///
/// The hit tester builds a spatial index for O(1) lookups. Call `invalidateIndex()`
/// after modifying the score to rebuild the index on the next hit test.
///
/// - SeeAlso: ``SelectableElement`` for the returned element type
/// - SeeAlso: ``HitTestConfiguration`` for customization options
public final class HitTester {
    /// The engraved score to test against.
    public var engravedScore: EngravedScore

    /// Hit test configuration.
    public var config: HitTestConfiguration

    /// Cached spatial index for faster lookups.
    private var spatialIndex: SpatialIndex?

    /// Whether the spatial index needs rebuilding.
    private var indexNeedsRebuild: Bool = true

    public init(engravedScore: EngravedScore, config: HitTestConfiguration = HitTestConfiguration()) {
        self.engravedScore = engravedScore
        self.config = config
    }

    // MARK: - Hit Testing

    /// Performs a hit test at the specified point.
    /// - Parameter point: The point in score coordinates.
    /// - Returns: The topmost selectable element at the point, or nil if none.
    public func hitTest(at point: CGPoint) -> SelectableElement? {
        // Build spatial index if needed
        if indexNeedsRebuild {
            rebuildSpatialIndex()
        }

        // Use spatial index for fast lookup
        if let spatialIndex = spatialIndex {
            let candidates = spatialIndex.query(point: point, tolerance: config.hitTolerance)
            return selectTopElement(from: candidates, at: point)
        }

        // Fallback to linear search
        return linearHitTest(at: point)
    }

    /// Performs a hit test within a rectangle.
    /// - Parameter rect: The rectangle in score coordinates.
    /// - Returns: All selectable elements that intersect the rectangle.
    public func hitTest(in rect: CGRect) -> [SelectableElement] {
        if indexNeedsRebuild {
            rebuildSpatialIndex()
        }

        if let spatialIndex = spatialIndex {
            return spatialIndex.query(rect: rect)
        }

        return linearHitTest(in: rect)
    }

    /// Invalidates the spatial index, forcing rebuild on next hit test.
    public func invalidateIndex() {
        indexNeedsRebuild = true
    }

    // MARK: - Element Selection Priority

    /// Selects the topmost element from candidates at a point.
    private func selectTopElement(from candidates: [SelectableElement], at point: CGPoint) -> SelectableElement? {
        guard !candidates.isEmpty else { return nil }

        // Sort by layer priority (higher = on top)
        let sorted = candidates.sorted { element1, element2 in
            let priority1 = layerPriority(for: element1.elementType)
            let priority2 = layerPriority(for: element2.elementType)
            return priority1 > priority2
        }

        // Return the topmost element that contains the point within tolerance
        for element in sorted {
            let expandedBounds = element.bounds.insetBy(dx: -config.hitTolerance, dy: -config.hitTolerance)
            if expandedBounds.contains(point) {
                return element
            }
        }

        return sorted.first
    }

    /// Returns the layer priority for an element type.
    /// Higher values are "on top" and get selected first.
    private func layerPriority(for elementType: SelectableElementType) -> Int {
        switch elementType {
        case .note, .chord:
            return 100
        case .rest:
            return 90
        case .articulation:
            return 85
        case .dynamic:
            return 80
        case .lyric:
            return 75
        case .direction:
            return 70
        case .slur, .tie:
            return 60
        case .beam:
            return 50
        case .clef, .keySignature, .timeSignature:
            return 40
        case .barline:
            return 30
        case .measure:
            return 20
        case .staff:
            return 10
        case .part:
            return 5
        }
    }

    // MARK: - Linear Search (Fallback)

    private func linearHitTest(at point: CGPoint) -> SelectableElement? {
        var candidates: [SelectableElement] = []

        for page in engravedScore.pages {
            // Check if point is within page
            guard page.frame.contains(point) else { continue }
            let pagePoint = CGPoint(x: point.x - page.frame.origin.x, y: point.y - page.frame.origin.y)

            for system in page.systems {
                // Check if point is within system
                guard system.frame.contains(pagePoint) else { continue }
                let systemPoint = CGPoint(x: pagePoint.x - system.frame.origin.x, y: pagePoint.y - system.frame.origin.y)

                // Check measures
                for measure in system.measures {
                    let measureRect = measure.frame.insetBy(dx: -config.hitTolerance, dy: -config.hitTolerance)
                    if measureRect.contains(systemPoint) {
                        let measureAbsBounds = absoluteBounds(measure.frame, system: system, page: page)
                        let measureElement = SelectableElement(
                            id: "measure-\(measure.measureNumber)",
                            elementType: .measure,
                            bounds: measureAbsBounds,
                            measureNumber: measure.measureNumber
                        )
                        candidates.append(measureElement)

                        // Check elements within measure
                        for (staffIndex, elements) in measure.elementsByStaff {
                            for element in elements {
                                let elementBounds = element.boundingBox.insetBy(dx: -config.hitTolerance, dy: -config.hitTolerance)
                                if elementBounds.contains(systemPoint) {
                                    let absElement = selectableElement(from: element, staffIndex: staffIndex, measure: measure, system: system, page: page)
                                    candidates.append(absElement)
                                }
                            }
                        }
                    }
                }

                // Check staves
                for staff in system.staves {
                    let staffRect = staff.frame.insetBy(dx: -config.hitTolerance, dy: -config.hitTolerance)
                    if staffRect.contains(systemPoint) && config.selectStaves {
                        let staffAbsBounds = absoluteBounds(staff.frame, system: system, page: page)
                        let staffElement = SelectableElement(
                            id: "staff-\(staff.partIndex)-\(staff.staffNumber)",
                            elementType: .staff,
                            bounds: staffAbsBounds,
                            partIndex: staff.partIndex,
                            staff: staff.staffNumber
                        )
                        candidates.append(staffElement)
                    }
                }
            }
        }

        return selectTopElement(from: candidates, at: point)
    }

    private func linearHitTest(in rect: CGRect) -> [SelectableElement] {
        var results: [SelectableElement] = []

        for page in engravedScore.pages {
            guard page.frame.intersects(rect) else { continue }

            for system in page.systems {
                let systemAbsFrame = CGRect(
                    origin: CGPoint(x: system.frame.origin.x + page.frame.origin.x, y: system.frame.origin.y + page.frame.origin.y),
                    size: system.frame.size
                )
                guard systemAbsFrame.intersects(rect) else { continue }

                for measure in system.measures {
                    let measureAbsBounds = absoluteBounds(measure.frame, system: system, page: page)
                    if measureAbsBounds.intersects(rect) {
                        let element = SelectableElement(
                            id: "measure-\(measure.measureNumber)",
                            elementType: .measure,
                            bounds: measureAbsBounds,
                            measureNumber: measure.measureNumber
                        )
                        results.append(element)

                        for (staffIndex, elements) in measure.elementsByStaff {
                            for engravedElement in elements {
                                let absElement = selectableElement(from: engravedElement, staffIndex: staffIndex, measure: measure, system: system, page: page)
                                if absElement.bounds.intersects(rect) {
                                    results.append(absElement)
                                }
                            }
                        }
                    }
                }
            }
        }

        return results
    }

    // MARK: - Spatial Index

    private func rebuildSpatialIndex() {
        var allElements: [SelectableElement] = []

        for page in engravedScore.pages {
            for system in page.systems {
                // Add measures
                for measure in system.measures {
                    let measureAbsBounds = absoluteBounds(measure.frame, system: system, page: page)
                    let measureElement = SelectableElement(
                        id: "measure-\(measure.measureNumber)",
                        elementType: .measure,
                        bounds: measureAbsBounds,
                        measureNumber: measure.measureNumber
                    )
                    allElements.append(measureElement)

                    // Add elements within measure
                    for (staffIndex, elements) in measure.elementsByStaff {
                        for element in elements {
                            let selectableEl = selectableElement(from: element, staffIndex: staffIndex, measure: measure, system: system, page: page)
                            allElements.append(selectableEl)
                        }
                    }
                }

                // Add staves if selectable
                if config.selectStaves {
                    for staff in system.staves {
                        let staffAbsBounds = absoluteBounds(staff.frame, system: system, page: page)
                        let staffElement = SelectableElement(
                            id: "staff-\(staff.partIndex)-\(staff.staffNumber)",
                            elementType: .staff,
                            bounds: staffAbsBounds,
                            partIndex: staff.partIndex,
                            staff: staff.staffNumber
                        )
                        allElements.append(staffElement)
                    }
                }
            }
        }

        spatialIndex = SpatialIndex(elements: allElements)
        indexNeedsRebuild = false
    }

    // MARK: - Helpers

    private func absoluteBounds(_ rect: CGRect, system: EngravedSystem, page: EngravedPage) -> CGRect {
        CGRect(
            x: rect.origin.x + system.frame.origin.x + page.frame.origin.x,
            y: rect.origin.y + system.frame.origin.y + page.frame.origin.y,
            width: rect.width,
            height: rect.height
        )
    }

    private func selectableElement(from element: EngravedElement, staffIndex: Int, measure: EngravedMeasure, system: EngravedSystem, page: EngravedPage) -> SelectableElement {
        let absoluteElementBounds = CGRect(
            x: element.boundingBox.origin.x + system.frame.origin.x + page.frame.origin.x,
            y: element.boundingBox.origin.y + system.frame.origin.y + page.frame.origin.y,
            width: element.boundingBox.width,
            height: element.boundingBox.height
        )

        let (elementType, elementId) = mapElementType(element)

        return SelectableElement(
            id: elementId,
            elementType: elementType,
            bounds: absoluteElementBounds,
            measureNumber: measure.measureNumber,
            staff: staffIndex
        )
    }

    private func mapElementType(_ element: EngravedElement) -> (SelectableElementType, String) {
        switch element {
        case .note(let n):
            return (.note, "note-\(n.noteId)")
        case .rest:
            return (.rest, "rest-\(UUID().uuidString)")
        case .chord:
            return (.chord, "chord-\(UUID().uuidString)")
        case .clef:
            return (.clef, "clef-\(UUID().uuidString)")
        case .keySignature:
            return (.keySignature, "keysig-\(UUID().uuidString)")
        case .timeSignature:
            return (.timeSignature, "timesig-\(UUID().uuidString)")
        case .barline:
            return (.barline, "barline-\(UUID().uuidString)")
        case .direction:
            return (.direction, "direction-\(UUID().uuidString)")
        }
    }
}

// MARK: - Hit Test Configuration

/// Configuration for hit testing behavior.
public struct HitTestConfiguration: Sendable {
    /// Tolerance in points for hit detection.
    public var hitTolerance: CGFloat = 4.0

    /// Whether to allow selecting measures.
    public var selectMeasures: Bool = true

    /// Whether to allow selecting staves.
    public var selectStaves: Bool = false

    /// Element types that can be selected.
    public var selectableTypes: Set<SelectableElementType> = Set(SelectableElementType.allCases)

    public init() {}
}

// MARK: - Spatial Index

/// Simple grid-based spatial index for fast hit testing.
private final class SpatialIndex {
    private let cellSize: CGFloat = 100
    private var grid: [GridCell: [SelectableElement]] = [:]
    private var bounds: CGRect = .zero

    struct GridCell: Hashable {
        let x: Int
        let y: Int
    }

    init(elements: [SelectableElement]) {
        for element in elements {
            insert(element)
            bounds = bounds.union(element.bounds)
        }
    }

    private func insert(_ element: SelectableElement) {
        let cells = cellsForRect(element.bounds)
        for cell in cells {
            if grid[cell] == nil {
                grid[cell] = []
            }
            grid[cell]?.append(element)
        }
    }

    func query(point: CGPoint, tolerance: CGFloat) -> [SelectableElement] {
        let queryRect = CGRect(
            x: point.x - tolerance,
            y: point.y - tolerance,
            width: tolerance * 2,
            height: tolerance * 2
        )
        return query(rect: queryRect)
    }

    func query(rect: CGRect) -> [SelectableElement] {
        var results: Set<String> = []
        var elements: [SelectableElement] = []

        let cells = cellsForRect(rect)
        for cell in cells {
            if let cellElements = grid[cell] {
                for element in cellElements where !results.contains(element.id) {
                    if element.bounds.intersects(rect) {
                        results.insert(element.id)
                        elements.append(element)
                    }
                }
            }
        }

        return elements
    }

    private func cellsForRect(_ rect: CGRect) -> [GridCell] {
        let minX = Int(floor(rect.minX / cellSize))
        let maxX = Int(ceil(rect.maxX / cellSize))
        let minY = Int(floor(rect.minY / cellSize))
        let maxY = Int(ceil(rect.maxY / cellSize))

        var cells: [GridCell] = []
        for x in minX...maxX {
            for y in minY...maxY {
                cells.append(GridCell(x: x, y: y))
            }
        }
        return cells
    }
}
