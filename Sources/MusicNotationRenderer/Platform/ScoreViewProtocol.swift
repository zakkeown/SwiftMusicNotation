import Foundation
import CoreGraphics
import MusicNotationCore
import MusicNotationLayout
import SMuFLKit

// MARK: - Score View Protocol

/// Protocol defining the interface for platform-native score rendering views.
///
/// `ScoreViewProtocol` abstracts the common functionality of score display views
/// across different platforms (macOS, iOS, visionOS). Platform-specific implementations
/// (`ScoreView` on each platform) conform to this protocol.
///
/// ## For App Developers
///
/// Most SwiftUI applications should use `ScoreViewRepresentable` instead of
/// working with this protocol directly. Use `ScoreViewProtocol` when:
/// - Building UIKit or AppKit apps without SwiftUI
/// - Creating custom view subclasses
/// - Implementing platform-specific features
///
/// ## For Custom Implementations
///
/// If implementing a custom score view, conform to this protocol to ensure
/// compatibility with the library's interaction and selection systems.
///
/// - SeeAlso: `ScoreViewRepresentable` for SwiftUI integration
/// - SeeAlso: `ScoreSelectionDelegate` for handling user interactions
public protocol ScoreViewProtocol: AnyObject {
    /// The source score to display.
    ///
    /// Setting this triggers layout computation and re-rendering.
    var score: Score? { get set }

    /// The computed layout (engraved representation) for rendering.
    ///
    /// This is populated automatically when you call `setScore(_:layoutContext:)`.
    /// Access this for hit testing or coordinate conversions.
    var engravedScore: EngravedScore? { get set }

    /// The current zoom level where 1.0 represents 100% (actual size).
    ///
    /// Values less than 1.0 zoom out, values greater than 1.0 zoom in.
    /// The view clamps values to the range `minimumZoomLevel...maximumZoomLevel`.
    var zoomLevel: CGFloat { get set }

    /// The minimum allowed zoom level.
    ///
    /// Default is typically 0.25 (25%). Set this to prevent users from
    /// zooming out too far.
    var minimumZoomLevel: CGFloat { get set }

    /// The maximum allowed zoom level.
    ///
    /// Default is typically 4.0 (400%). Set this to prevent excessive
    /// zooming that might cause performance issues.
    var maximumZoomLevel: CGFloat { get set }

    /// The current scroll offset in points.
    ///
    /// This represents the top-left corner of the visible viewport
    /// in score coordinates.
    var scrollOffset: CGPoint { get set }

    /// The delegate receiving selection and interaction events.
    ///
    /// Set this to receive callbacks when the user selects elements,
    /// taps, or scrolls.
    var selectionDelegate: ScoreSelectionDelegate? { get set }

    /// The currently selected notation elements.
    ///
    /// Set this to programmatically select elements. The view will
    /// highlight selected elements and notify the delegate of changes.
    var selectedElements: [SelectableElement] { get set }

    /// Whether user selection is enabled.
    ///
    /// When `false`, taps on elements don't select them.
    /// Useful for read-only display or playback modes.
    var selectionEnabled: Bool { get set }

    /// The background color of the score view.
    ///
    /// This fills the area around the score pages.
    var scoreBackgroundColor: CGColor { get set }

    /// The default color for notation elements.
    ///
    /// Used for notes, rests, staff lines, and other elements
    /// when not overridden by selection or custom styling.
    var foregroundColor: CGColor { get set }

    /// The highlight color for selected elements.
    ///
    /// Selected elements are drawn with this color instead of
    /// the foreground color.
    var selectionColor: CGColor { get set }

    // MARK: - Methods

    /// Loads a score and computes its layout for display.
    ///
    /// This is the primary method for displaying a score. It computes
    /// the layout using the provided context and triggers rendering.
    ///
    /// - Parameters:
    ///   - score: The score to display.
    ///   - layoutContext: The layout configuration (page size, margins, etc.).
    func setScore(_ score: Score, layoutContext: LayoutContext)

    /// Adjusts zoom to fit the entire score in the visible area.
    ///
    /// Call this after loading a score to show the full first page.
    func zoomToFit()

    /// Adjusts zoom to fit a specific page in the visible area.
    ///
    /// - Parameter pageIndex: The zero-based index of the page to fit.
    func zoomToPage(_ pageIndex: Int)

    /// Scrolls to make a specific measure visible.
    ///
    /// - Parameters:
    ///   - measureNumber: The measure number (1-based) to scroll to.
    ///   - partIndex: The part index containing the measure.
    func scrollToMeasure(_ measureNumber: Int, in partIndex: Int)

    /// Scrolls to make a specific element visible.
    ///
    /// - Parameter element: The element to scroll into view.
    func scrollToElement(_ element: SelectableElement)

    /// Deselects all currently selected elements.
    func clearSelection()

    /// Selects or adds to selection the specified element.
    ///
    /// - Parameters:
    ///   - element: The element to select.
    ///   - addToSelection: If `true`, adds to existing selection.
    ///     If `false`, replaces the current selection.
    func select(_ element: SelectableElement, addToSelection: Bool)

    /// Marks the entire view as needing redraw.
    ///
    /// Call this when configuration changes require a full re-render.
    func setNeedsFullRedraw()

    /// Marks a specific region as needing redraw.
    ///
    /// - Parameter rect: The region in view coordinates to redraw.
    func setNeedsRedraw(in rect: CGRect)
}

// MARK: - Score Selection Delegate

/// Delegate protocol for receiving score view interaction events.
///
/// Implement this protocol to respond to user interactions with the score view,
/// including element selection, taps, zoom changes, and scrolling.
///
/// ## Usage
///
/// ```swift
/// class MyViewController: UIViewController, ScoreSelectionDelegate {
///     func scoreView(_ scoreView: ScoreViewProtocol,
///                    didChangeSelection selection: [SelectableElement]) {
///         // Update inspector panel with selected elements
///         updateInspector(with: selection)
///     }
///
///     func scoreView(_ scoreView: ScoreViewProtocol,
///                    didTapElement element: SelectableElement) {
///         // Play the tapped note
///         if element.elementType == .note {
///             playNote(element)
///         }
///     }
/// }
/// ```
///
/// All methods have default empty implementations, so you only need to
/// implement the events you're interested in.
///
/// - SeeAlso: `ScoreViewProtocol` for the view interface
/// - SeeAlso: `SelectableElement` for element data
public protocol ScoreSelectionDelegate: AnyObject {
    /// Called when the selection changes.
    ///
    /// This is called whenever elements are selected or deselected, whether
    /// by user interaction (tap, click) or programmatically via `select(_:addToSelection:)`.
    ///
    /// - Parameters:
    ///   - scoreView: The score view that changed.
    ///   - selection: The new selection (may be empty if selection was cleared).
    func scoreView(_ scoreView: ScoreViewProtocol, didChangeSelection selection: [SelectableElement])

    /// Called when an element is tapped or clicked.
    ///
    /// Use this for immediate feedback like playing a note sound.
    ///
    /// - Parameters:
    ///   - scoreView: The score view where the tap occurred.
    ///   - element: The element that was tapped.
    func scoreView(_ scoreView: ScoreViewProtocol, didTapElement element: SelectableElement)

    /// Called when an element is double-tapped or double-clicked.
    ///
    /// Use this for editing actions like opening a note properties dialog.
    ///
    /// - Parameters:
    ///   - scoreView: The score view where the double-tap occurred.
    ///   - element: The element that was double-tapped.
    func scoreView(_ scoreView: ScoreViewProtocol, didDoubleTapElement element: SelectableElement)

    /// Called when empty space is tapped (no element under cursor).
    ///
    /// Use this to clear selection or dismiss modal editors.
    ///
    /// - Parameter scoreView: The score view where the tap occurred.
    func scoreViewDidTapEmptySpace(_ scoreView: ScoreViewProtocol)

    /// Called when the zoom level changes.
    ///
    /// This is called during pinch-to-zoom gestures, scroll wheel zoom,
    /// or programmatic zoom changes.
    ///
    /// - Parameters:
    ///   - scoreView: The score view that zoomed.
    ///   - zoomLevel: The new zoom level (1.0 = 100%).
    func scoreView(_ scoreView: ScoreViewProtocol, didChangeZoomLevel zoomLevel: CGFloat)

    /// Called when the scroll position changes.
    ///
    /// Use this to update navigation indicators or load content lazily.
    ///
    /// - Parameters:
    ///   - scoreView: The score view that scrolled.
    ///   - offset: The new scroll offset in points.
    func scoreView(_ scoreView: ScoreViewProtocol, didScrollTo offset: CGPoint)
}

// MARK: - Default Delegate Implementations

public extension ScoreSelectionDelegate {
    func scoreView(_ scoreView: ScoreViewProtocol, didChangeSelection selection: [SelectableElement]) {}
    func scoreView(_ scoreView: ScoreViewProtocol, didTapElement element: SelectableElement) {}
    func scoreView(_ scoreView: ScoreViewProtocol, didDoubleTapElement element: SelectableElement) {}
    func scoreViewDidTapEmptySpace(_ scoreView: ScoreViewProtocol) {}
    func scoreView(_ scoreView: ScoreViewProtocol, didChangeZoomLevel zoomLevel: CGFloat) {}
    func scoreView(_ scoreView: ScoreViewProtocol, didScrollTo offset: CGPoint) {}
}

// MARK: - Selectable Element

/// Represents a notation element that can be selected in the score view.
///
/// `SelectableElement` provides metadata about selectable elements, including
/// their type, position, and location within the score hierarchy. Use this
/// information to identify what the user selected and respond appropriately.
///
/// ## Element Information
///
/// Each element includes:
/// - `id`: Unique identifier for the element instance
/// - `elementType`: The kind of element (note, rest, clef, etc.)
/// - `bounds`: Bounding rectangle in score coordinates
/// - Location context (part, measure, voice, staff)
///
/// ## Example Usage
///
/// ```swift
/// func handleSelection(_ element: SelectableElement) {
///     switch element.elementType {
///     case .note:
///         print("Note in measure \(element.measureNumber ?? 0)")
///     case .measure:
///         selectEntireMeasure(element.measureNumber)
///     default:
///         break
///     }
/// }
/// ```
///
/// - SeeAlso: `SelectableElementType` for the list of element types
/// - SeeAlso: `ScoreSelectionDelegate` for receiving selection events
public struct SelectableElement: Identifiable, Equatable, Sendable {
    /// Unique identifier for this element instance.
    ///
    /// Use this to track specific elements across selection changes or
    /// to maintain element-specific state in your application.
    public let id: String

    /// The type of notation element.
    ///
    /// Use this to determine how to handle the selected element.
    public let elementType: SelectableElementType

    /// The bounding rectangle of the element in score coordinates.
    ///
    /// This represents the visual extent of the element. Use for:
    /// - Determining element size
    /// - Hit testing custom interactions
    /// - Drawing custom selection indicators
    public let bounds: CGRect

    /// The index of the part containing this element, if applicable.
    ///
    /// For elements like notes and measures, this identifies which
    /// instrument part the element belongs to.
    public let partIndex: Int?

    /// The measure number (1-based) containing this element, if applicable.
    ///
    /// Use this to navigate to or highlight the containing measure.
    public let measureNumber: Int?

    /// The voice number within the staff, if applicable.
    ///
    /// Voices allow multiple independent rhythmic lines on the same staff.
    /// Voice 1 is typically the primary voice.
    public let voice: Int?

    /// The staff number within the part (1-based), if applicable.
    ///
    /// For piano or other multi-staff instruments, this distinguishes
    /// between the upper (1) and lower (2) staves.
    public let staff: Int?

    /// Creates a new selectable element.
    ///
    /// - Parameters:
    ///   - id: Unique identifier for this element.
    ///   - elementType: The type of notation element.
    ///   - bounds: The bounding rectangle in score coordinates.
    ///   - partIndex: The part index, if applicable.
    ///   - measureNumber: The measure number (1-based), if applicable.
    ///   - voice: The voice number, if applicable.
    ///   - staff: The staff number within the part, if applicable.
    public init(
        id: String,
        elementType: SelectableElementType,
        bounds: CGRect,
        partIndex: Int? = nil,
        measureNumber: Int? = nil,
        voice: Int? = nil,
        staff: Int? = nil
    ) {
        self.id = id
        self.elementType = elementType
        self.bounds = bounds
        self.partIndex = partIndex
        self.measureNumber = measureNumber
        self.voice = voice
        self.staff = staff
    }

    public static func == (lhs: SelectableElement, rhs: SelectableElement) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - Selectable Element Type

/// Enumeration of notation element types that can be selected.
///
/// Use this to determine how to respond to user interactions with
/// different types of notation elements.
///
/// ## Categories
///
/// **Rhythmic Elements**: `.note`, `.rest`, `.chord`
/// - Individual pitched or unpitched events
///
/// **Connectors**: `.beam`, `.tie`, `.slur`
/// - Elements that connect other elements
///
/// **Expressions**: `.dynamic`, `.articulation`, `.direction`
/// - Performance instructions and markings
///
/// **Structural**: `.clef`, `.keySignature`, `.timeSignature`, `.barline`
/// - Elements defining musical structure
///
/// **Text**: `.lyric`, `.direction`
/// - Text-based elements
///
/// **Containers**: `.measure`, `.staff`, `.part`
/// - Selection of entire regions
public enum SelectableElementType: String, Sendable, CaseIterable {
    /// A single note with pitch and duration.
    case note
    /// A rest (silence) with duration.
    case rest
    /// Multiple notes played simultaneously.
    case chord
    /// A beam connecting note stems.
    case beam
    /// A tie connecting notes of the same pitch.
    case tie
    /// A slur indicating legato phrasing.
    case slur
    /// A dynamic marking (pp, mf, ff, etc.).
    case dynamic
    /// An articulation mark (staccato, accent, etc.).
    case articulation
    /// A clef symbol (treble, bass, etc.).
    case clef
    /// A key signature (sharps or flats).
    case keySignature
    /// A time signature (4/4, 3/4, etc.).
    case timeSignature
    /// A barline (single, double, repeat, etc.).
    case barline
    /// A direction marking (tempo, expression text).
    case direction
    /// A lyric syllable under a note.
    case lyric
    /// An entire measure (bar).
    case measure
    /// A complete staff.
    case staff
    /// An entire part (instrument).
    case part
}

// MARK: - Score View Configuration

/// Configuration options for score view behavior and appearance.
///
/// Use `ScoreViewConfiguration` to customize how the score view responds to
/// user interactions and displays content. This affects gestures, selection,
/// and visual presentation.
///
/// ## Example
///
/// ```swift
/// var config = ScoreViewConfiguration()
/// config.enableMultipleSelection = false  // Single selection only
/// config.showPageShadow = true            // Visual separation between pages
/// config.animationDuration = 0.3          // Smooth animations
/// ```
///
/// - Note: Not all configuration options are used by all view implementations.
///   Check platform-specific documentation for supported features.
public struct ScoreViewConfiguration: Sendable {
    /// Whether pinch-to-zoom (iOS) and scroll wheel zoom (macOS) are enabled.
    ///
    /// Default: `true`
    public var enableZoomGestures: Bool = true

    /// Whether pan (iOS) and scroll (macOS) gestures are enabled.
    ///
    /// Default: `true`
    public var enableScrollGestures: Bool = true

    /// Whether tapping/clicking elements selects them.
    ///
    /// Set to `false` for read-only display or during playback.
    ///
    /// Default: `true`
    public var enableSelection: Bool = true

    /// Whether multiple elements can be selected simultaneously.
    ///
    /// On macOS, hold Command to add to selection.
    /// On iOS, tap additional elements after initial selection.
    ///
    /// Default: `true`
    public var enableMultipleSelection: Bool = true

    /// Whether to draw visual indicators for page margins.
    ///
    /// Useful for layout debugging or print preview.
    ///
    /// Default: `false`
    public var showPageMargins: Bool = false

    /// Whether to draw a drop shadow under score pages.
    ///
    /// Provides visual separation when displaying multiple pages
    /// or against a colored background.
    ///
    /// Default: `true`
    public var showPageShadow: Bool = true

    /// Padding around the score content in points.
    ///
    /// This space appears between the score pages and the view edges.
    ///
    /// Default: 20 points
    public var contentMargin: CGFloat = 20

    /// Duration for animated zoom and scroll transitions.
    ///
    /// Set to 0 for immediate transitions.
    ///
    /// Default: 0.25 seconds
    public var animationDuration: TimeInterval = 0.25

    /// Zoom increment for keyboard shortcuts and zoom buttons.
    ///
    /// The zoom level changes by this amount (as a multiplier) when
    /// using zoom in/out commands.
    ///
    /// Default: 0.25 (25%)
    public var zoomStep: CGFloat = 0.25

    /// Whether to snap zoom to standard levels after gesture ends.
    ///
    /// When `true`, zoom snaps to 50%, 75%, 100%, 125%, 150%, or 200%
    /// after the user finishes a zoom gesture.
    ///
    /// Default: `false`
    public var snapZoomToStandardLevels: Bool = false

    /// Creates a default configuration.
    public init() {}
}

// MARK: - Score Render State

/// Manages the rendering state and cached renderers for a score view.
///
/// `ScoreRenderState` holds references to specialized renderers for different
/// notation elements (glyphs, notes, beams, etc.) and tracks rendering state
/// like the current viewport and dirty regions.
///
/// ## Usage
///
/// This class is typically used internally by `ScoreView` implementations.
/// You may need to interact with it when implementing custom views or
/// performance optimizations.
///
/// ```swift
/// let renderState = ScoreRenderState()
/// renderState.initializeRenderers(with: loadedFont)
///
/// // After rendering, clear caches if memory is low
/// renderState.clearCaches()
/// ```
///
/// ## Thread Safety
///
/// `ScoreRenderState` is not thread-safe. Access should be confined to
/// the main thread or synchronized externally.
public final class ScoreRenderState {
    /// The loaded SMuFL font used for rendering musical glyphs.
    public var font: LoadedSMuFLFont?

    /// Renderer for SMuFL glyphs (notes, clefs, accidentals, etc.).
    public var glyphRenderer: GlyphRenderer?

    /// Renderer for staff lines.
    public var staffRenderer: StaffRenderer?

    /// Renderer for notes and their components (stems, flags, dots).
    public var noteRenderer: NoteRenderer?

    /// Renderer for beams connecting note groups.
    public var beamRenderer: BeamRenderer?

    /// Renderer for curved elements (slurs, ties).
    public var curveRenderer: CurveRenderer?

    /// Renderer for text elements (lyrics, directions).
    public var textRenderer: TextRenderer?

    /// Manages rendering layers for proper draw order.
    public var layerManager: LayerManager = LayerManager()

    /// Tracks regions that need redrawing.
    public var dirtyTracker: DirtyRegionTracker = DirtyRegionTracker()

    /// The currently visible viewport in score coordinates.
    ///
    /// Used for culling elements outside the visible area.
    public var viewport: CGRect = .zero

    /// The staff height in points.
    ///
    /// This value is used by renderers to scale notation elements.
    public var staffHeight: CGFloat = 40

    /// Creates an empty render state.
    ///
    /// Call `initializeRenderers(with:)` to set up the specialized renderers.
    public init() {}

    /// Initializes all specialized renderers with the given font.
    ///
    /// This must be called before rendering any notation. The font provides
    /// the glyph data needed for drawing musical symbols.
    ///
    /// - Parameter font: The loaded SMuFL font to use for rendering.
    public func initializeRenderers(with font: LoadedSMuFLFont) {
        self.font = font
        self.glyphRenderer = GlyphRenderer(font: font)

        if let glyphRenderer = self.glyphRenderer {
            self.noteRenderer = NoteRenderer(glyphRenderer: glyphRenderer)
        }

        self.staffRenderer = StaffRenderer()
        self.beamRenderer = BeamRenderer()
        self.curveRenderer = CurveRenderer()
        self.textRenderer = TextRenderer()
    }

    /// Clears all cached rendering data.
    ///
    /// Call this when:
    /// - Receiving a memory warning
    /// - Changing fonts
    /// - Disposing of the view
    public func clearCaches() {
        glyphRenderer?.clearCache()
        textRenderer?.clearFontCache()
        layerManager.clear()
    }
}

// MARK: - Zoom Level Presets

/// Standard zoom level presets for score viewing.
///
/// `ZoomPreset` provides common zoom levels that can be used for zoom menus,
/// keyboard shortcuts, or snapping zoom levels to standard values.
///
/// ## Usage
///
/// Build a zoom menu:
///
/// ```swift
/// Menu("Zoom") {
///     ForEach(ZoomPreset.allCases, id: \.rawValue) { preset in
///         Button(preset.displayName) {
///             zoomLevel = preset.rawValue
///         }
///     }
/// }
/// ```
///
/// Navigate between zoom levels:
///
/// ```swift
/// func zoomIn() {
///     let current = ZoomPreset.nearest(to: zoomLevel)
///     if let next = current.nextHigher {
///         zoomLevel = next.rawValue
///     }
/// }
/// ```
public enum ZoomPreset: CGFloat, CaseIterable, Sendable {
    /// 25% zoom (very zoomed out).
    case percent25 = 0.25
    /// 50% zoom.
    case percent50 = 0.50
    /// 75% zoom.
    case percent75 = 0.75
    /// 100% zoom (actual size).
    case percent100 = 1.0
    /// 125% zoom.
    case percent125 = 1.25
    /// 150% zoom.
    case percent150 = 1.5
    /// 200% zoom.
    case percent200 = 2.0
    /// 300% zoom.
    case percent300 = 3.0
    /// 400% zoom (very zoomed in).
    case percent400 = 4.0

    /// Human-readable display name (e.g., "100%").
    public var displayName: String {
        "\(Int(rawValue * 100))%"
    }

    /// Finds the preset closest to a given zoom level.
    ///
    /// - Parameter level: The zoom level to match.
    /// - Returns: The nearest preset. Returns `.percent100` if no presets exist.
    ///
    /// ```swift
    /// ZoomPreset.nearest(to: 0.85)  // Returns .percent75 or .percent100
    /// ```
    public static func nearest(to level: CGFloat) -> ZoomPreset {
        allCases.min(by: { abs($0.rawValue - level) < abs($1.rawValue - level) }) ?? .percent100
    }

    /// The next larger zoom preset, if one exists.
    ///
    /// Returns `nil` if this is already the maximum preset.
    public var nextHigher: ZoomPreset? {
        let sorted = ZoomPreset.allCases.sorted { $0.rawValue < $1.rawValue }
        guard let index = sorted.firstIndex(of: self), index < sorted.count - 1 else { return nil }
        return sorted[index + 1]
    }

    /// The next smaller zoom preset, if one exists.
    ///
    /// Returns `nil` if this is already the minimum preset.
    public var nextLower: ZoomPreset? {
        let sorted = ZoomPreset.allCases.sorted { $0.rawValue < $1.rawValue }
        guard let index = sorted.firstIndex(of: self), index > 0 else { return nil }
        return sorted[index - 1]
    }
}

// MARK: - EngravedScore Extensions

public extension EngravedScore {
    /// Total bounds encompassing all pages.
    var totalBounds: CGRect {
        guard !pages.isEmpty else { return .zero }
        var bounds = pages[0].frame
        for page in pages.dropFirst() {
            bounds = bounds.union(page.frame)
        }
        return bounds
    }
}
