#if os(macOS)
import AppKit
import CoreGraphics
import MusicNotationCore
import MusicNotationLayout
import SMuFLKit

// MARK: - macOS Score View

/// macOS NSView implementation for rendering music notation.
public final class ScoreView: NSView, ScoreViewProtocol {
    // MARK: - Properties

    /// The score to display.
    public var score: Score? {
        didSet {
            setNeedsFullRedraw()
        }
    }

    /// The engraved layout for rendering.
    public var engravedScore: EngravedScore? {
        didSet {
            updateContentSize()
            setNeedsFullRedraw()
        }
    }

    /// Current zoom level (1.0 = 100%).
    public var zoomLevel: CGFloat = 1.0 {
        didSet {
            zoomLevel = max(minimumZoomLevel, min(maximumZoomLevel, zoomLevel))
            updateContentSize()
            selectionDelegate?.scoreView(self, didChangeZoomLevel: zoomLevel)
            setNeedsFullRedraw()
        }
    }

    /// Minimum allowed zoom level.
    public var minimumZoomLevel: CGFloat = 0.25

    /// Maximum allowed zoom level.
    public var maximumZoomLevel: CGFloat = 4.0

    /// Current scroll offset.
    public var scrollOffset: CGPoint = .zero {
        didSet {
            selectionDelegate?.scoreView(self, didScrollTo: scrollOffset)
            setNeedsFullRedraw()
        }
    }

    /// The delegate for selection events.
    public weak var selectionDelegate: ScoreSelectionDelegate?

    /// Currently selected elements.
    public var selectedElements: [SelectableElement] = [] {
        didSet {
            selectionDelegate?.scoreView(self, didChangeSelection: selectedElements)
            setNeedsFullRedraw()
        }
    }

    /// Whether selection is enabled.
    public var selectionEnabled: Bool = true

    /// Background color of the view.
    public var scoreBackgroundColor: CGColor = NSColor.windowBackgroundColor.cgColor {
        didSet {
            setNeedsFullRedraw()
        }
    }

    /// Default color for notation elements.
    public var foregroundColor: CGColor = NSColor.textColor.cgColor {
        didSet {
            setNeedsFullRedraw()
        }
    }

    /// Color for selected elements.
    public var selectionColor: CGColor = NSColor.selectedContentBackgroundColor.cgColor

    /// View configuration.
    public var configuration: ScoreViewConfiguration = ScoreViewConfiguration()

    /// Render state.
    public let renderState = ScoreRenderState()

    /// Hit tester for selection.
    private var hitTester: HitTester?

    /// Content size (score size * zoom).
    private var contentSize: CGSize = .zero

    // MARK: - Initialization

    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        wantsLayer = true
        layer?.backgroundColor = scoreBackgroundColor
    }

    // MARK: - ScoreViewProtocol Methods

    /// Sets the score and triggers layout.
    public func setScore(_ score: Score, layoutContext: LayoutContext) {
        self.score = score
        // Note: Layout would be performed by the layout engine
        // For now, this is a stub - actual layout integration needed
    }

    /// Zooms to fit the entire score in the visible area.
    public func zoomToFit() {
        guard let engraved = engravedScore, !engraved.pages.isEmpty else { return }

        let totalBounds = engraved.totalBounds
        guard totalBounds.width > 0, totalBounds.height > 0 else { return }

        let visibleSize = enclosingScrollView?.contentSize ?? bounds.size
        let margin = configuration.contentMargin * 2

        let scaleX = (visibleSize.width - margin) / totalBounds.width
        let scaleY = (visibleSize.height - margin) / totalBounds.height

        zoomLevel = min(scaleX, scaleY)
        scrollOffset = .zero
    }

    /// Zooms to fit the specified page.
    public func zoomToPage(_ pageIndex: Int) {
        guard let engraved = engravedScore,
              pageIndex >= 0, pageIndex < engraved.pages.count else { return }

        let page = engraved.pages[pageIndex]
        let visibleSize = enclosingScrollView?.contentSize ?? bounds.size
        let margin = configuration.contentMargin * 2

        let scaleX = (visibleSize.width - margin) / page.frame.width
        let scaleY = (visibleSize.height - margin) / page.frame.height

        zoomLevel = min(scaleX, scaleY)
        scrollOffset = CGPoint(x: 0, y: page.frame.origin.y * zoomLevel)
    }

    /// Scrolls to make the specified measure visible.
    public func scrollToMeasure(_ measureNumber: Int, in partIndex: Int) {
        guard let engraved = engravedScore else { return }

        // Find the measure in the engraved score
        for page in engraved.pages {
            for system in page.systems {
                for measure in system.measures where measure.measureNumber == measureNumber {
                    let measureRect = CGRect(
                        x: measure.frame.origin.x + system.frame.origin.x + page.frame.origin.x,
                        y: measure.frame.origin.y + system.frame.origin.y + page.frame.origin.y,
                        width: measure.frame.width,
                        height: measure.frame.height
                    )
                    scrollToVisible(measureRect, animated: true)
                    return
                }
            }
        }
    }

    /// Scrolls to make the specified element visible.
    public func scrollToElement(_ element: SelectableElement) {
        scrollToVisible(element.bounds, animated: true)
    }

    /// Clears the current selection.
    public func clearSelection() {
        selectedElements = []
    }

    /// Selects the specified element.
    public func select(_ element: SelectableElement, addToSelection: Bool) {
        if addToSelection && configuration.enableMultipleSelection {
            if !selectedElements.contains(element) {
                selectedElements.append(element)
            }
        } else {
            selectedElements = [element]
        }
    }

    /// Forces a redraw of the entire view.
    public func setNeedsFullRedraw() {
        renderState.dirtyTracker.markFullRedraw()
        needsDisplay = true
    }

    /// Forces a redraw of the specified region.
    public func setNeedsRedraw(in rect: CGRect) {
        renderState.dirtyTracker.markDirty(rect)
        setNeedsDisplay(rect)
    }

    // MARK: - Font Loading

    /// Loads a SMuFL font for rendering.
    public func loadFont(_ font: LoadedSMuFLFont) {
        renderState.initializeRenderers(with: font)
        setNeedsFullRedraw()
    }

    // MARK: - Drawing

    public override var isFlipped: Bool {
        true // Use top-left origin like iOS
    }

    public override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext else { return }

        // Fill background
        context.setFillColor(scoreBackgroundColor)
        context.fill(dirtyRect)

        // Draw score
        drawScore(in: context, dirtyRect: dirtyRect)

        // Draw selection highlights
        drawSelectionHighlights(in: context)
    }

    private func drawScore(in context: CGContext, dirtyRect: CGRect) {
        guard let engraved = engravedScore else { return }

        context.saveGState()

        // Apply zoom transform
        context.scaleBy(x: zoomLevel, y: zoomLevel)

        // Apply scroll offset
        context.translateBy(x: -scrollOffset.x / zoomLevel, y: -scrollOffset.y / zoomLevel)

        // Calculate visible rect in score coordinates
        let visibleRect = CGRect(
            x: scrollOffset.x / zoomLevel,
            y: scrollOffset.y / zoomLevel,
            width: dirtyRect.width / zoomLevel,
            height: dirtyRect.height / zoomLevel
        )

        renderState.viewport = visibleRect

        // Draw each page
        for page in engraved.pages {
            // Check if page is visible
            guard page.frame.intersects(visibleRect) else { continue }

            context.saveGState()
            context.translateBy(x: page.frame.origin.x, y: page.frame.origin.y)

            // Draw page background (white)
            if configuration.showPageShadow {
                context.setShadow(offset: CGSize(width: 2, height: 2), blur: 5, color: NSColor.black.withAlphaComponent(0.3).cgColor)
            }

            context.setFillColor(NSColor.white.cgColor)
            context.fill(CGRect(origin: .zero, size: page.frame.size))
            context.setShadow(offset: .zero, blur: 0)

            // Draw systems
            for system in page.systems {
                drawSystem(system, in: context)
            }

            context.restoreGState()
        }

        context.restoreGState()
    }

    private func drawSystem(_ system: EngravedSystem, in context: CGContext) {
        context.saveGState()
        context.translateBy(x: system.frame.origin.x, y: system.frame.origin.y)

        // Draw staff lines for each staff
        for staff in system.staves {
            drawStaff(staff, in: context)
        }

        context.restoreGState()
    }

    private func drawStaff(_ staff: EngravedStaff, in context: CGContext) {
        guard let staffRenderer = renderState.staffRenderer else { return }

        context.saveGState()
        context.translateBy(x: staff.frame.origin.x, y: staff.frame.origin.y)

        // Draw staff lines
        let staffSpacing = staff.staffHeight / 4
        staffRenderer.renderStaffLines(
            at: .zero,
            width: staff.frame.width,
            lineCount: staff.lineCount,
            staffSpacing: staffSpacing,
            color: foregroundColor,
            in: context
        )

        context.restoreGState()
    }

    private func drawSelectionHighlights(in context: CGContext) {
        guard !selectedElements.isEmpty else { return }

        context.saveGState()
        context.scaleBy(x: zoomLevel, y: zoomLevel)
        context.translateBy(x: -scrollOffset.x / zoomLevel, y: -scrollOffset.y / zoomLevel)

        context.setFillColor(selectionColor.copy(alpha: 0.3) ?? selectionColor)
        context.setStrokeColor(selectionColor)
        context.setLineWidth(1.0 / zoomLevel)

        for element in selectedElements {
            let highlightRect = element.bounds.insetBy(dx: -2, dy: -2)
            context.fill(highlightRect)
            context.stroke(highlightRect)
        }

        context.restoreGState()
    }

    // MARK: - Content Size

    private func updateContentSize() {
        guard let engraved = engravedScore else {
            contentSize = .zero
            return
        }

        let totalBounds = engraved.totalBounds
        contentSize = CGSize(
            width: totalBounds.width * zoomLevel + configuration.contentMargin * 2,
            height: totalBounds.height * zoomLevel + configuration.contentMargin * 2
        )

        enclosingScrollView?.documentView?.frame.size = contentSize
    }

    // MARK: - Mouse Events

    public override func mouseDown(with event: NSEvent) {
        guard selectionEnabled, configuration.enableSelection else {
            super.mouseDown(with: event)
            return
        }

        let location = convert(event.locationInWindow, from: nil)
        let scoreLocation = viewToScoreCoordinate(location)

        if let hitTester = hitTester,
           let element = hitTester.hitTest(at: scoreLocation) {
            let addToSelection = event.modifierFlags.contains(.shift) || event.modifierFlags.contains(.command)
            select(element, addToSelection: addToSelection)
            selectionDelegate?.scoreView(self, didTapElement: element)
        } else {
            if !event.modifierFlags.contains(.shift) && !event.modifierFlags.contains(.command) {
                clearSelection()
            }
            selectionDelegate?.scoreViewDidTapEmptySpace(self)
        }
    }

    public override func mouseUp(with event: NSEvent) {
        if event.clickCount == 2 {
            let location = convert(event.locationInWindow, from: nil)
            let scoreLocation = viewToScoreCoordinate(location)

            if let hitTester = hitTester,
               let element = hitTester.hitTest(at: scoreLocation) {
                selectionDelegate?.scoreView(self, didDoubleTapElement: element)
            }
        }
    }

    // MARK: - Scroll Wheel

    public override func scrollWheel(with event: NSEvent) {
        if event.modifierFlags.contains(.option) && configuration.enableZoomGestures {
            let zoomDelta = event.scrollingDeltaY * 0.01
            let newZoom = zoomLevel + zoomDelta
            zoomLevel = max(minimumZoomLevel, min(maximumZoomLevel, newZoom))
        } else if configuration.enableScrollGestures {
            super.scrollWheel(with: event)
        }
    }

    // MARK: - Magnification (Trackpad Pinch)

    public override func magnify(with event: NSEvent) {
        guard configuration.enableZoomGestures else { return }

        let newZoom = zoomLevel * (1 + event.magnification)
        zoomLevel = max(minimumZoomLevel, min(maximumZoomLevel, newZoom))
    }

    // MARK: - Keyboard

    public override var acceptsFirstResponder: Bool {
        true
    }

    public override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 24: // + key (zoom in)
            if event.modifierFlags.contains(.command) {
                zoomLevel = min(maximumZoomLevel, zoomLevel + configuration.zoomStep)
            }
        case 27: // - key (zoom out)
            if event.modifierFlags.contains(.command) {
                zoomLevel = max(minimumZoomLevel, zoomLevel - configuration.zoomStep)
            }
        case 29: // 0 key (reset zoom)
            if event.modifierFlags.contains(.command) {
                zoomLevel = 1.0
            }
        default:
            super.keyDown(with: event)
        }
    }

    // MARK: - Coordinate Conversion

    /// Converts a view coordinate to score coordinate.
    public func viewToScoreCoordinate(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: (point.x + scrollOffset.x) / zoomLevel,
            y: (point.y + scrollOffset.y) / zoomLevel
        )
    }

    /// Converts a score coordinate to view coordinate.
    public func scoreToViewCoordinate(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: point.x * zoomLevel - scrollOffset.x,
            y: point.y * zoomLevel - scrollOffset.y
        )
    }

    // MARK: - Scroll Helpers

    private func scrollToVisible(_ rect: CGRect, animated: Bool) {
        let viewRect = CGRect(
            x: rect.origin.x * zoomLevel,
            y: rect.origin.y * zoomLevel,
            width: rect.width * zoomLevel,
            height: rect.height * zoomLevel
        )

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = configuration.animationDuration
                self.enclosingScrollView?.contentView.animator().bounds.origin = viewRect.origin
            }
        } else {
            enclosingScrollView?.contentView.scroll(to: viewRect.origin)
        }
    }
}
#endif
