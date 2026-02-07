#if os(iOS) || os(visionOS)
import UIKit
import CoreGraphics
import MusicNotationCore
import MusicNotationLayout
import SMuFLKit

// MARK: - iOS Score View

/// iOS UIView implementation for rendering music notation.
public final class ScoreView: UIScrollView, ScoreViewProtocol, UIScrollViewDelegate {
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
    public var zoomLevel: CGFloat {
        get { self.zoomScale }
        set {
            let clampedZoom = max(minimumZoomLevel, min(maximumZoomLevel, newValue))
            self.zoomScale = clampedZoom
            selectionDelegate?.scoreView(self, didChangeZoomLevel: clampedZoom)
        }
    }

    /// Minimum allowed zoom level.
    public var minimumZoomLevel: CGFloat {
        get { minimumZoomScale }
        set { minimumZoomScale = newValue }
    }

    /// Maximum allowed zoom level.
    public var maximumZoomLevel: CGFloat {
        get { maximumZoomScale }
        set { maximumZoomScale = newValue }
    }

    /// Current scroll offset.
    public var scrollOffset: CGPoint {
        get { contentOffset }
        set { contentOffset = newValue }
    }

    /// The delegate for selection events.
    public weak var selectionDelegate: ScoreSelectionDelegate?

    /// Currently selected elements.
    public var selectedElements: [SelectableElement] = [] {
        didSet {
            selectionDelegate?.scoreView(self, didChangeSelection: selectedElements)
            contentView.setNeedsDisplay()
        }
    }

    /// Whether selection is enabled.
    public var selectionEnabled: Bool = true

    /// Background color of the view.
    public var backgroundColorCG: CGColor = UIColor.systemBackground.cgColor {
        didSet {
            backgroundColor = UIColor(cgColor: backgroundColorCG)
            setNeedsFullRedraw()
        }
    }

    // ScoreViewProtocol conformance
    public var scoreBackgroundColor: CGColor {
        get { backgroundColorCG }
        set { backgroundColorCG = newValue }
    }

    /// Default color for notation elements.
    public var foregroundColor: CGColor = UIColor.label.cgColor {
        didSet {
            setNeedsFullRedraw()
        }
    }

    /// Color for selected elements.
    public var selectionColor: CGColor = UIColor.systemBlue.cgColor

    /// View configuration.
    public var configuration: ScoreViewConfiguration = ScoreViewConfiguration() {
        didSet {
            applyConfiguration()
        }
    }

    /// Render state.
    private let renderState = ScoreRenderState()

    /// Hit tester for selection.
    private var hitTester: HitTester?

    /// The content view that does actual drawing.
    private let contentView: ScoreContentView

    // MARK: - Initialization

    public override init(frame: CGRect) {
        contentView = ScoreContentView(frame: frame)
        super.init(frame: frame)
        commonInit()
    }

    public required init?(coder: NSCoder) {
        contentView = ScoreContentView(frame: .zero)
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        // Configure scroll view
        delegate = self
        minimumZoomScale = 0.25
        maximumZoomScale = 4.0
        bouncesZoom = true
        showsHorizontalScrollIndicator = true
        showsVerticalScrollIndicator = true

        // Add content view
        contentView.scoreView = self
        addSubview(contentView)

        // Apply initial configuration
        applyConfiguration()

        // Setup gestures
        setupGestures()
    }

    private func applyConfiguration() {
        isScrollEnabled = configuration.enableScrollGestures
        pinchGestureRecognizer?.isEnabled = configuration.enableZoomGestures
    }

    private func setupGestures() {
        // Tap gesture for selection
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.numberOfTapsRequired = 1
        addGestureRecognizer(tapGesture)

        // Double tap gesture
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)

        // Make single tap wait for double tap to fail
        tapGesture.require(toFail: doubleTapGesture)
    }

    // MARK: - ScoreViewProtocol Methods

    /// Sets the score and triggers layout.
    public func setScore(_ score: Score, layoutContext: LayoutContext) {
        self.score = score

        // Layout the score using the real layout engine
        let layoutEngine = MusicNotationLayout.LayoutEngine()
        self.engravedScore = layoutEngine.layout(score: score, context: layoutContext)

        // Initialize hit tester
        if let engraved = engravedScore {
            hitTester = HitTester(engravedScore: engraved)
        }
    }

    /// Zooms to fit the entire score in the visible area.
    public func zoomToFit() {
        guard let engraved = engravedScore, !engraved.pages.isEmpty else { return }

        let totalBounds = engraved.totalBounds
        guard totalBounds.width > 0, totalBounds.height > 0 else { return }

        let visibleSize = bounds.size
        let margin = configuration.contentMargin * 2

        let scaleX = (visibleSize.width - margin) / totalBounds.width
        let scaleY = (visibleSize.height - margin) / totalBounds.height

        setZoomScale(min(scaleX, scaleY), animated: true)
        setContentOffset(.zero, animated: true)
    }

    /// Zooms to fit the specified page.
    public func zoomToPage(_ pageIndex: Int) {
        guard let engraved = engravedScore,
              pageIndex >= 0, pageIndex < engraved.pages.count else { return }

        let page = engraved.pages[pageIndex]
        let visibleSize = bounds.size
        let margin = configuration.contentMargin * 2

        let scaleX = (visibleSize.width - margin) / page.frame.width
        let scaleY = (visibleSize.height - margin) / page.frame.height

        let targetZoom = min(scaleX, scaleY)
        setZoomScale(targetZoom, animated: true)

        // Scroll to page
        let offset = CGPoint(x: 0, y: page.frame.origin.y * targetZoom)
        setContentOffset(offset, animated: true)
    }

    /// Scrolls to make the specified measure visible.
    public func scrollToMeasure(_ measureNumber: Int, in partIndex: Int) {
        guard let engraved = engravedScore else { return }

        // Find the measure in the engraved score
        for page in engraved.pages {
            for system in page.systems {
                for measure in system.measures where measure.measureNumber == measureNumber {
                    let measureRect = CGRect(
                        x: (measure.frame.origin.x + system.frame.origin.x + page.frame.origin.x) * zoomScale,
                        y: (measure.frame.origin.y + system.frame.origin.y + page.frame.origin.y) * zoomScale,
                        width: measure.frame.width * zoomScale,
                        height: measure.frame.height * zoomScale
                    )
                    scrollRectToVisible(measureRect, animated: true)
                    return
                }
            }
        }
    }

    /// Scrolls to make the specified element visible.
    public func scrollToElement(_ element: SelectableElement) {
        let viewRect = CGRect(
            x: element.bounds.origin.x * zoomScale,
            y: element.bounds.origin.y * zoomScale,
            width: element.bounds.width * zoomScale,
            height: element.bounds.height * zoomScale
        )
        scrollRectToVisible(viewRect, animated: true)
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
        contentView.setNeedsDisplay()
    }

    /// Forces a redraw of the specified region.
    public func setNeedsRedraw(in rect: CGRect) {
        renderState.dirtyTracker.markDirty(rect)
        contentView.setNeedsDisplay(rect)
    }

    // MARK: - Font Loading

    /// Loads a SMuFL font for rendering.
    public func loadFont(_ font: LoadedSMuFLFont) {
        renderState.initializeRenderers(with: font)
        contentView.renderState = renderState
        setNeedsFullRedraw()
    }

    // MARK: - Content Size

    private func updateContentSize() {
        guard let engraved = engravedScore else {
            contentSize = .zero
            contentView.frame = bounds
            return
        }

        let totalBounds = engraved.totalBounds
        let size = CGSize(
            width: totalBounds.width + configuration.contentMargin * 2,
            height: totalBounds.height + configuration.contentMargin * 2
        )

        contentView.frame = CGRect(origin: .zero, size: size)
        contentSize = size
    }

    // MARK: - UIScrollViewDelegate

    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        contentView
    }

    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        selectionDelegate?.scoreView(self, didChangeZoomLevel: zoomScale)
    }

    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        selectionDelegate?.scoreView(self, didScrollTo: contentOffset)
    }

    // MARK: - Gesture Handlers

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard selectionEnabled, configuration.enableSelection else { return }

        let location = gesture.location(in: contentView)
        let scoreLocation = CGPoint(x: location.x, y: location.y)

        if let hitTester = hitTester,
           let element = hitTester.hitTest(at: scoreLocation) {
            select(element, addToSelection: false)
            selectionDelegate?.scoreView(self, didTapElement: element)
        } else {
            clearSelection()
            selectionDelegate?.scoreViewDidTapEmptySpace(self)
        }
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: contentView)
        let scoreLocation = CGPoint(x: location.x, y: location.y)

        if let hitTester = hitTester,
           let element = hitTester.hitTest(at: scoreLocation) {
            selectionDelegate?.scoreView(self, didDoubleTapElement: element)
        } else {
            // Double tap on empty space = zoom to fit
            if zoomScale > minimumZoomScale + 0.1 {
                setZoomScale(minimumZoomScale, animated: true)
            } else {
                // Zoom to tapped point
                let zoomRect = zoomRectForScale(maximumZoomScale * 0.5, center: location)
                zoom(to: zoomRect, animated: true)
            }
        }
    }

    private func zoomRectForScale(_ scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        zoomRect.size.width = bounds.width / scale
        zoomRect.size.height = bounds.height / scale
        zoomRect.origin.x = center.x - (zoomRect.width / 2.0)
        zoomRect.origin.y = center.y - (zoomRect.height / 2.0)
        return zoomRect
    }
}

// MARK: - Score Content View

/// Internal view that handles the actual drawing.
private class ScoreContentView: UIView {
    weak var scoreView: ScoreView?
    var renderState: ScoreRenderState?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        contentMode = .redraw
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        backgroundColor = .white
        contentMode = .redraw
    }

    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext(),
              let scoreView = scoreView else { return }

        // Draw score
        drawScore(in: context, scoreView: scoreView)

        // Draw selection highlights
        drawSelectionHighlights(in: context, scoreView: scoreView)
    }

    private func drawScore(in context: CGContext, scoreView: ScoreView) {
        guard let engraved = scoreView.engravedScore else { return }

        // Use MusicRenderer for full notation rendering
        let renderer = MusicRenderer()
        renderer.font = renderState?.font

        for pageIndex in 0..<engraved.pages.count {
            renderer.render(score: engraved, pageIndex: pageIndex, in: context)
        }
    }

    private func drawSelectionHighlights(in context: CGContext, scoreView: ScoreView) {
        guard !scoreView.selectedElements.isEmpty else { return }

        context.setFillColor(scoreView.selectionColor.copy(alpha: 0.3) ?? scoreView.selectionColor)
        context.setStrokeColor(scoreView.selectionColor)
        context.setLineWidth(1.0)

        for element in scoreView.selectedElements {
            let highlightRect = element.bounds.insetBy(dx: -2, dy: -2)
            context.fill(highlightRect)
            context.stroke(highlightRect)
        }
    }
}

#endif
