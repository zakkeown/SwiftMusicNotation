import Foundation
import CoreGraphics

// MARK: - Render Layer

/// Defines the rendering order for music notation elements.
/// Elements are rendered from lowest to highest layer to ensure proper overlap.
public enum RenderLayer: Int, CaseIterable, Comparable, Sendable {
    /// Background fill and page elements.
    case background = 0

    /// Staff lines (drawn early so notes appear on top).
    case staffLines = 10

    /// Ledger lines (drawn with staff lines).
    case ledgerLines = 11

    /// Barlines and system barlines.
    case barlines = 20

    /// Staff grouping symbols (brackets, braces).
    case groupings = 25

    /// Noteheads (main note bodies).
    case noteheads = 30

    /// Accidentals (sharps, flats, naturals).
    case accidentals = 31

    /// Augmentation dots.
    case dots = 32

    /// Stems.
    case stems = 40

    /// Flags (on unbeamed notes).
    case flags = 41

    /// Beams.
    case beams = 50

    /// Ties.
    case ties = 60

    /// Slurs.
    case slurs = 61

    /// Articulations (staccato, accent, etc.).
    case articulations = 70

    /// Dynamics.
    case dynamics = 80

    /// Wedges (crescendo/diminuendo hairpins).
    case wedges = 81

    /// Text directions and words.
    case directions = 90

    /// Tempo markings.
    case tempo = 91

    /// Clefs, key signatures, time signatures.
    case attributes = 100

    /// Rehearsal marks.
    case rehearsalMarks = 110

    /// Lyrics.
    case lyrics = 120

    /// Ornaments (trills, turns, mordents).
    case ornaments = 130

    /// Fermatas.
    case fermatas = 140

    /// Selection highlights and cursors.
    case selection = 200

    /// Debug overlays.
    case debug = 255

    public static func < (lhs: RenderLayer, rhs: RenderLayer) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

// MARK: - Layer Manager

/// Manages rendering elements by layer for proper draw order.
public final class LayerManager {
    /// Elements grouped by layer.
    private var layers: [RenderLayer: [LayerElement]] = [:]

    public init() {}

    /// Adds an element to a layer.
    public func add(_ element: LayerElement, to layer: RenderLayer) {
        if layers[layer] == nil {
            layers[layer] = []
        }
        layers[layer]?.append(element)
    }

    /// Clears all elements.
    public func clear() {
        layers.removeAll()
    }

    /// Renders all layers in order.
    public func render(in context: CGContext, drawBlock: (RenderLayer, [LayerElement], CGContext) -> Void) {
        for layer in RenderLayer.allCases.sorted() {
            if let elements = layers[layer], !elements.isEmpty {
                drawBlock(layer, elements, context)
            }
        }
    }

    /// Gets elements for a specific layer.
    public func elements(for layer: RenderLayer) -> [LayerElement] {
        layers[layer] ?? []
    }

    /// Gets all layers that have elements.
    public var activeLayers: [RenderLayer] {
        layers.keys.sorted()
    }
}

// MARK: - Layer Element

/// An element that can be rendered on a layer.
public struct LayerElement: Sendable {
    /// Unique identifier for the element.
    public var id: String

    /// Bounding box for culling.
    public var bounds: CGRect

    /// The render action closure type.
    public typealias RenderAction = @Sendable (CGContext) -> Void

    /// Render action (called when drawing).
    private var _renderAction: RenderAction?

    public init(id: String, bounds: CGRect, renderAction: RenderAction? = nil) {
        self.id = id
        self.bounds = bounds
        self._renderAction = renderAction
    }

    /// Renders the element.
    public func render(in context: CGContext) {
        _renderAction?(context)
    }
}

// MARK: - Layer Configuration

/// Configuration for layer rendering.
public struct LayerConfiguration: Sendable {
    /// Whether to enable layer-based rendering.
    public var enableLayeredRendering: Bool = true

    /// Whether to skip culled (off-screen) elements.
    public var enableCulling: Bool = true

    /// Debug: highlight layer boundaries.
    public var debugShowLayers: Bool = false

    /// Debug: colors for each layer (for visualization).
    public var debugLayerColors: [RenderLayer: CGColor] = [:]

    /// Layers to skip during rendering.
    public var disabledLayers: Set<RenderLayer> = []

    public init() {}

    /// Checks if a layer should be rendered.
    public func shouldRender(layer: RenderLayer) -> Bool {
        !disabledLayers.contains(layer)
    }
}

// MARK: - Render Pass

/// A render pass for a specific set of layers.
public struct RenderPass: Sendable {
    /// Name of the render pass.
    public var name: String

    /// Layers included in this pass.
    public var layers: Set<RenderLayer>

    /// Whether this pass uses alpha blending.
    public var usesBlending: Bool

    public init(name: String, layers: Set<RenderLayer>, usesBlending: Bool = false) {
        self.name = name
        self.layers = layers
        self.usesBlending = usesBlending
    }

    /// Standard render passes for music notation.
    public static let standardPasses: [RenderPass] = [
        RenderPass(name: "background", layers: [.background, .staffLines, .ledgerLines]),
        RenderPass(name: "structure", layers: [.barlines, .groupings, .attributes]),
        RenderPass(name: "notes", layers: [.noteheads, .accidentals, .dots, .stems, .flags, .beams]),
        RenderPass(name: "spanners", layers: [.ties, .slurs], usesBlending: true),
        RenderPass(name: "markings", layers: [.articulations, .dynamics, .wedges, .directions, .tempo]),
        RenderPass(name: "text", layers: [.rehearsalMarks, .lyrics, .ornaments, .fermatas]),
        RenderPass(name: "overlay", layers: [.selection, .debug])
    ]
}

// MARK: - Dirty Region Tracking

/// Tracks dirty (changed) regions for incremental rendering.
public final class DirtyRegionTracker {
    /// Dirty rectangles that need redrawing.
    private var dirtyRects: [CGRect] = []

    /// Whether the entire view needs redrawing.
    private var fullRedraw: Bool = true

    public init() {}

    /// Marks a region as dirty.
    public func markDirty(_ rect: CGRect) {
        if !fullRedraw {
            dirtyRects.append(rect)
        }
    }

    /// Marks the entire view as dirty.
    public func markFullRedraw() {
        fullRedraw = true
        dirtyRects.removeAll()
    }

    /// Gets the combined dirty region.
    public func dirtyRegion() -> CGRect? {
        if fullRedraw {
            return nil // Indicates full redraw needed
        }
        guard let firstRect = dirtyRects.first else { return CGRect.zero }

        var combined = firstRect
        for rect in dirtyRects.dropFirst() {
            combined = combined.union(rect)
        }
        return combined
    }

    /// Clears dirty tracking after render.
    public func clearDirty() {
        fullRedraw = false
        dirtyRects.removeAll()
    }

    /// Whether any region needs redrawing.
    public var needsRedraw: Bool {
        fullRedraw || !dirtyRects.isEmpty
    }
}

// MARK: - Culling

/// Utilities for visibility culling.
public struct CullingHelper {
    /// Checks if a bounds is visible within a viewport.
    public static func isVisible(_ bounds: CGRect, in viewport: CGRect) -> Bool {
        bounds.intersects(viewport)
    }

    /// Filters elements to only those visible in the viewport.
    public static func cull(_ elements: [LayerElement], to viewport: CGRect) -> [LayerElement] {
        elements.filter { isVisible($0.bounds, in: viewport) }
    }

    /// Expands a viewport by a margin for pre-fetching.
    public static func expandedViewport(_ viewport: CGRect, margin: CGFloat) -> CGRect {
        viewport.insetBy(dx: -margin, dy: -margin)
    }
}
