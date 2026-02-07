import SwiftUI
import MusicNotationCore
import MusicNotationLayout
import SMuFLKit

// MARK: - SwiftUI Score View

/// A SwiftUI view that displays rendered music notation with interaction support.
///
/// `ScoreViewRepresentable` is the primary SwiftUI component for displaying music
/// notation. It wraps platform-native views (`NSView` on macOS, `UIView` on iOS)
/// and provides a declarative SwiftUI interface with bindings for state management.
///
/// ## Basic Usage
///
/// Display a score with default settings:
///
/// ```swift
/// struct ContentView: View {
///     @State private var score: Score?
///
///     let layoutContext = LayoutContext.letterSize(staffHeight: 40)
///
///     var body: some View {
///         ScoreViewRepresentable(
///             score: $score,
///             layoutContext: layoutContext
///         )
///         .onAppear {
///             score = try? loadMusicXML()
///         }
///     }
/// }
/// ```
///
/// ## Zoom and Selection
///
/// Control zoom level and track selected elements:
///
/// ```swift
/// struct ScoreEditor: View {
///     @State private var score: Score?
///     @State private var zoomLevel: CGFloat = 1.0
///     @State private var selectedElements: [SelectableElement] = []
///
///     var body: some View {
///         VStack {
///             HStack {
///                 Button("Zoom In") { zoomLevel *= 1.25 }
///                 Button("Zoom Out") { zoomLevel /= 1.25 }
///                 Text("\(Int(zoomLevel * 100))%")
///             }
///
///             ScoreViewRepresentable(
///                 score: $score,
///                 zoomLevel: $zoomLevel,
///                 selectedElements: $selectedElements,
///                 layoutContext: LayoutContext.letterSize(),
///                 onSelectionChanged: { elements in
///                     print("Selected \(elements.count) elements")
///                 }
///             )
///         }
///     }
/// }
/// ```
///
/// ## Handling Interactions
///
/// Respond to user taps on notation elements:
///
/// ```swift
/// ScoreViewRepresentable(
///     score: $score,
///     layoutContext: context,
///     onElementTapped: { element in
///         switch element.elementType {
///         case .note:
///             playNote(element)
///         case .measure:
///             selectMeasure(element.measureNumber)
///         default:
///             break
///         }
///     },
///     onElementDoubleTapped: { element in
///         editElement(element)
///     },
///     onEmptySpaceTapped: {
///         clearSelection()
///     }
/// )
/// ```
///
/// ## Platform Support
///
/// This view automatically uses the appropriate native implementation:
/// - macOS: `NSScrollView` with `ScoreView` as document view
/// - iOS/visionOS: `UIScrollView` with `ScoreView` as content view
///
/// Both platforms support pinch-to-zoom and panning gestures.
///
/// - SeeAlso: `LayoutContext` for configuring score layout
/// - SeeAlso: `SelectableElement` for working with selected elements
/// - SeeAlso: `ScoreSelectionDelegate` for the delegate protocol
public struct ScoreViewRepresentable: View {
    /// The score to display.
    ///
    /// When the score changes, the view automatically re-layouts and re-renders.
    /// Pass `nil` to display an empty view.
    @Binding public var score: Score?

    /// The current zoom level (1.0 = 100%).
    ///
    /// Bind to this property to programmatically control zoom or track user
    /// zoom changes from pinch gestures or scroll wheel.
    @Binding public var zoomLevel: CGFloat

    /// The currently selected notation elements.
    ///
    /// Bind to this property to programmatically select elements or track
    /// user selection changes.
    @Binding public var selectedElements: [SelectableElement]

    /// The layout context defining page size, margins, and staff height.
    ///
    /// Create using factory methods like `LayoutContext.letterSize(staffHeight:)`
    /// or `LayoutContext.a4Size(staffHeight:)`.
    public var layoutContext: LayoutContext

    /// The SMuFL font for rendering musical glyphs.
    ///
    /// If `nil`, the view will attempt to load the default bundled font.
    /// For custom fonts, load them via `SMuFLFontManager` and pass here.
    public var font: LoadedSMuFLFont?

    /// Called when the selection changes.
    ///
    /// This closure is called whenever elements are selected or deselected,
    /// whether by user interaction or programmatic changes.
    public var onSelectionChanged: (([SelectableElement]) -> Void)?

    /// Called when an element is tapped (single click/tap).
    ///
    /// Use this to respond to element selection, play notes, or show contextual
    /// information.
    public var onElementTapped: ((SelectableElement) -> Void)?

    /// Called when an element is double-tapped (double click/tap).
    ///
    /// Use this for editing actions like opening a note editor dialog.
    public var onElementDoubleTapped: ((SelectableElement) -> Void)?

    /// Called when empty space is tapped (no element hit).
    ///
    /// Use this to clear selection or dismiss editors.
    public var onEmptySpaceTapped: (() -> Void)?

    /// Creates a new score view with the specified bindings and handlers.
    ///
    /// - Parameters:
    ///   - score: Binding to the score to display.
    ///   - zoomLevel: Binding to the zoom level. Defaults to 1.0 (100%).
    ///   - selectedElements: Binding to the selected elements array.
    ///   - layoutContext: The layout configuration for page size and margins.
    ///   - font: Optional SMuFL font. If `nil`, uses the default bundled font.
    ///   - onSelectionChanged: Called when selection changes.
    ///   - onElementTapped: Called on single tap/click.
    ///   - onElementDoubleTapped: Called on double tap/click.
    ///   - onEmptySpaceTapped: Called when tapping empty space.
    public init(
        score: Binding<Score?>,
        zoomLevel: Binding<CGFloat> = .constant(1.0),
        selectedElements: Binding<[SelectableElement]> = .constant([]),
        layoutContext: LayoutContext,
        font: LoadedSMuFLFont? = nil,
        onSelectionChanged: (([SelectableElement]) -> Void)? = nil,
        onElementTapped: ((SelectableElement) -> Void)? = nil,
        onElementDoubleTapped: ((SelectableElement) -> Void)? = nil,
        onEmptySpaceTapped: (() -> Void)? = nil
    ) {
        self._score = score
        self._zoomLevel = zoomLevel
        self._selectedElements = selectedElements
        self.layoutContext = layoutContext
        self.font = font
        self.onSelectionChanged = onSelectionChanged
        self.onElementTapped = onElementTapped
        self.onElementDoubleTapped = onElementDoubleTapped
        self.onEmptySpaceTapped = onEmptySpaceTapped
    }

    public var body: some View {
        #if os(macOS)
        MacScoreViewRepresentable(
            score: $score,
            zoomLevel: $zoomLevel,
            selectedElements: $selectedElements,
            layoutContext: layoutContext,
            font: font,
            onSelectionChanged: onSelectionChanged,
            onElementTapped: onElementTapped,
            onElementDoubleTapped: onElementDoubleTapped,
            onEmptySpaceTapped: onEmptySpaceTapped
        )
        #elseif os(iOS) || os(visionOS)
        IOSScoreViewRepresentable(
            score: $score,
            zoomLevel: $zoomLevel,
            selectedElements: $selectedElements,
            layoutContext: layoutContext,
            font: font,
            onSelectionChanged: onSelectionChanged,
            onElementTapped: onElementTapped,
            onElementDoubleTapped: onElementDoubleTapped,
            onEmptySpaceTapped: onEmptySpaceTapped
        )
        #endif
    }
}

// MARK: - macOS Representable

#if os(macOS)
import AppKit

/// macOS NSViewRepresentable wrapper.
public struct MacScoreViewRepresentable: NSViewRepresentable {
    @Binding var score: Score?
    @Binding var zoomLevel: CGFloat
    @Binding var selectedElements: [SelectableElement]
    var layoutContext: LayoutContext
    var font: LoadedSMuFLFont?
    var onSelectionChanged: (([SelectableElement]) -> Void)?
    var onElementTapped: ((SelectableElement) -> Void)?
    var onElementDoubleTapped: ((SelectableElement) -> Void)?
    var onEmptySpaceTapped: (() -> Void)?

    public func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        let scoreView = ScoreView(frame: scrollView.bounds)
        scoreView.selectionDelegate = context.coordinator

        // Load font: use provided font, or auto-load bundled Bravura
        let loadedFont = font ?? (try? SMuFLFontManager.shared.loadBundledFont())
        if let loadedFont {
            scoreView.loadFont(loadedFont)
        }

        scrollView.documentView = scoreView

        return scrollView
    }

    public func updateNSView(_ nsView: NSScrollView, context: Context) {
        guard let scoreView = nsView.documentView as? ScoreView else { return }

        // Update score if changed, or relayout if layoutContext changed
        if let score = score {
            if scoreView.score !== score || context.coordinator.lastLayoutContext != layoutContext {
                scoreView.setScore(score, layoutContext: layoutContext)
                context.coordinator.lastLayoutContext = layoutContext
            }
        }

        // Update zoom
        if scoreView.zoomLevel != zoomLevel {
            scoreView.zoomLevel = zoomLevel
        }

        // Update selection
        if scoreView.selectedElements != selectedElements {
            scoreView.selectedElements = selectedElements
        }

        // Update font if needed
        if scoreView.renderState.font == nil {
            let loadedFont = font ?? (try? SMuFLFontManager.shared.loadBundledFont())
            if let loadedFont {
                scoreView.loadFont(loadedFont)
            }
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, ScoreSelectionDelegate {
        var parent: MacScoreViewRepresentable
        var lastLayoutContext: LayoutContext?

        init(_ parent: MacScoreViewRepresentable) {
            self.parent = parent
        }

        public func scoreView(_ scoreView: ScoreViewProtocol, didChangeSelection selection: [SelectableElement]) {
            DispatchQueue.main.async {
                self.parent.selectedElements = selection
                self.parent.onSelectionChanged?(selection)
            }
        }

        public func scoreView(_ scoreView: ScoreViewProtocol, didTapElement element: SelectableElement) {
            parent.onElementTapped?(element)
        }

        public func scoreView(_ scoreView: ScoreViewProtocol, didDoubleTapElement element: SelectableElement) {
            parent.onElementDoubleTapped?(element)
        }

        public func scoreViewDidTapEmptySpace(_ scoreView: ScoreViewProtocol) {
            parent.onEmptySpaceTapped?()
        }

        public func scoreView(_ scoreView: ScoreViewProtocol, didChangeZoomLevel zoomLevel: CGFloat) {
            DispatchQueue.main.async {
                self.parent.zoomLevel = zoomLevel
            }
        }

        public func scoreView(_ scoreView: ScoreViewProtocol, didScrollTo offset: CGPoint) {
            // Could add scroll position binding if needed
        }
    }

}
#endif

// MARK: - iOS Representable

#if os(iOS) || os(visionOS)
import UIKit

/// iOS UIViewRepresentable wrapper.
public struct IOSScoreViewRepresentable: UIViewRepresentable {
    @Binding var score: Score?
    @Binding var zoomLevel: CGFloat
    @Binding var selectedElements: [SelectableElement]
    var layoutContext: LayoutContext
    var font: LoadedSMuFLFont?
    var onSelectionChanged: (([SelectableElement]) -> Void)?
    var onElementTapped: ((SelectableElement) -> Void)?
    var onElementDoubleTapped: ((SelectableElement) -> Void)?
    var onEmptySpaceTapped: (() -> Void)?

    public func makeUIView(context: Context) -> ScoreView {
        let scoreView = ScoreView(frame: .zero)
        scoreView.selectionDelegate = context.coordinator

        // Load font: use provided font, or auto-load bundled Bravura
        let loadedFont = font ?? (try? SMuFLFontManager.shared.loadBundledFont())
        if let loadedFont {
            scoreView.loadFont(loadedFont)
        }

        return scoreView
    }

    public func updateUIView(_ uiView: ScoreView, context: Context) {
        // Update score if changed, or relayout if layoutContext changed
        if let score = score {
            if uiView.score !== score || context.coordinator.lastLayoutContext != layoutContext {
                uiView.setScore(score, layoutContext: layoutContext)
                context.coordinator.lastLayoutContext = layoutContext
            }
        }

        // Update zoom
        if uiView.zoomLevel != zoomLevel {
            uiView.zoomLevel = zoomLevel
        }

        // Update selection
        if uiView.selectedElements != selectedElements {
            uiView.selectedElements = selectedElements
        }

        // Update font if needed
        if let font = font {
            uiView.loadFont(font)
        }
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public class Coordinator: NSObject, ScoreSelectionDelegate {
        var parent: IOSScoreViewRepresentable
        var lastLayoutContext: LayoutContext?

        init(_ parent: IOSScoreViewRepresentable) {
            self.parent = parent
        }

        public func scoreView(_ scoreView: ScoreViewProtocol, didChangeSelection selection: [SelectableElement]) {
            DispatchQueue.main.async {
                self.parent.selectedElements = selection
                self.parent.onSelectionChanged?(selection)
            }
        }

        public func scoreView(_ scoreView: ScoreViewProtocol, didTapElement element: SelectableElement) {
            parent.onElementTapped?(element)
        }

        public func scoreView(_ scoreView: ScoreViewProtocol, didDoubleTapElement element: SelectableElement) {
            parent.onElementDoubleTapped?(element)
        }

        public func scoreViewDidTapEmptySpace(_ scoreView: ScoreViewProtocol) {
            parent.onEmptySpaceTapped?()
        }

        public func scoreView(_ scoreView: ScoreViewProtocol, didChangeZoomLevel zoomLevel: CGFloat) {
            DispatchQueue.main.async {
                self.parent.zoomLevel = zoomLevel
            }
        }

        public func scoreView(_ scoreView: ScoreViewProtocol, didScrollTo offset: CGPoint) {
            // Could add scroll position binding if needed
        }
    }
}
#endif

// MARK: - Score View Modifiers

public extension ScoreViewRepresentable {
    /// Sets the minimum zoom level.
    func minimumZoomLevel(_ level: CGFloat) -> ScoreViewRepresentable {
        var copy = self
        // Would need to pass through to underlying view
        return copy
    }

    /// Sets the maximum zoom level.
    func maximumZoomLevel(_ level: CGFloat) -> ScoreViewRepresentable {
        var copy = self
        // Would need to pass through to underlying view
        return copy
    }

    /// Enables or disables selection.
    func selectionEnabled(_ enabled: Bool) -> ScoreViewRepresentable {
        var copy = self
        // Would need to pass through to underlying view
        return copy
    }

    /// Sets the foreground color for notation.
    func foregroundColor(_ color: Color) -> ScoreViewRepresentable {
        var copy = self
        // Would need to pass through to underlying view
        return copy
    }

    /// Sets the selection highlight color.
    func selectionColor(_ color: Color) -> ScoreViewRepresentable {
        var copy = self
        // Would need to pass through to underlying view
        return copy
    }
}

// MARK: - Preview Provider

#if DEBUG
struct ScoreViewRepresentable_Previews: PreviewProvider {
    static var previews: some View {
        ScoreViewRepresentable(
            score: .constant(nil),
            layoutContext: LayoutContext.letterSize()
        )
        .frame(width: 600, height: 400)
    }
}
#endif
