# Platform Views

Display music notation in iOS, macOS, and SwiftUI applications.

@Metadata {
    @PageKind(article)
}

## Overview

MusicNotationRenderer provides ready-to-use views for displaying music notation on all Apple platforms. For SwiftUI apps, ``ScoreViewRepresentable`` offers the easiest integration with full support for bindings, zoom, and selection. For UIKit and AppKit apps, platform-specific `ScoreView` classes provide native integration.

## SwiftUI Integration

``ScoreViewRepresentable`` is the primary view for SwiftUI apps:

```swift
import SwiftUI
import SwiftMusicNotation

struct ContentView: View {
    @State private var score: Score?

    let layoutContext = LayoutContext.letterSize(staffHeight: 40)

    var body: some View {
        ScoreViewRepresentable(
            score: $score,
            layoutContext: layoutContext
        )
        .onAppear {
            loadScore()
        }
    }

    func loadScore() {
        let importer = MusicXMLImporter()
        score = try? importer.importScore(from: musicXMLURL)
    }
}
```

### Zoom Control

Control and observe zoom level:

```swift
struct ZoomableScoreView: View {
    @State private var score: Score?
    @State private var zoomLevel: CGFloat = 1.0

    var body: some View {
        VStack {
            HStack {
                Button("Zoom Out") { zoomLevel = max(0.25, zoomLevel / 1.25) }
                Text("\(Int(zoomLevel * 100))%")
                    .frame(width: 60)
                Button("Zoom In") { zoomLevel = min(4.0, zoomLevel * 1.25) }
            }
            .padding()

            ScoreViewRepresentable(
                score: $score,
                zoomLevel: $zoomLevel,
                layoutContext: LayoutContext.letterSize()
            )
        }
    }
}
```

### Zoom Presets

Use standard zoom presets:

```swift
let preset = ZoomPreset.oneHundredPercent       // 1.0
let fitWidth = ZoomPreset.fiftyPercent          // 0.5
let detailed = ZoomPreset.twoHundredPercent     // 2.0

// Find nearest preset
let nearest = ZoomPreset.nearest(to: currentZoom)

// Navigate between presets
let nextUp = currentPreset.nextHigher
let nextDown = currentPreset.nextLower
```

### Selection Handling

Track and respond to element selection:

```swift
struct SelectableScoreView: View {
    @State private var score: Score?
    @State private var selectedElements: [SelectableElement] = []

    var body: some View {
        VStack {
            Text("Selected: \(selectedElements.count) elements")

            ScoreViewRepresentable(
                score: $score,
                selectedElements: $selectedElements,
                layoutContext: LayoutContext.letterSize(),
                onSelectionChanged: { elements in
                    print("Selection changed to \(elements.count) elements")
                }
            )
        }
    }
}
```

### Interaction Callbacks

Handle taps and double-taps:

```swift
ScoreViewRepresentable(
    score: $score,
    layoutContext: context,
    onElementTapped: { element in
        switch element.elementType {
        case .note:
            playNote(element)
        case .measure:
            highlightMeasure(element.measureNumber!)
        default:
            break
        }
    },
    onElementDoubleTapped: { element in
        openEditor(for: element)
    },
    onEmptySpaceTapped: {
        clearSelection()
    }
)
```

## macOS (AppKit)

Use `ScoreView` directly in AppKit apps:

```swift
import AppKit
import SwiftMusicNotation

class ScoreViewController: NSViewController, ScoreSelectionDelegate {
    var scoreView: ScoreView!

    override func loadView() {
        // Create scroll view
        let scrollView = NSScrollView(frame: NSRect(x: 0, y: 0, width: 800, height: 600))
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true

        // Create score view
        scoreView = ScoreView(frame: scrollView.bounds)
        scoreView.selectionDelegate = self

        // Load font
        if let font = try? SMuFLFontManager.shared.loadFont(named: "Bravura") {
            scoreView.loadFont(font)
        }

        scrollView.documentView = scoreView
        self.view = scrollView
    }

    func loadScore(_ score: Score) {
        let context = LayoutContext.letterSize(staffHeight: 40)
        scoreView.setScore(score, layoutContext: context)
    }

    // MARK: - ScoreSelectionDelegate

    func scoreView(_ scoreView: ScoreViewProtocol, didChangeSelection selection: [SelectableElement]) {
        print("Selected \(selection.count) elements")
    }

    func scoreView(_ scoreView: ScoreViewProtocol, didTapElement element: SelectableElement) {
        print("Tapped: \(element.elementType)")
    }

    func scoreView(_ scoreView: ScoreViewProtocol, didDoubleTapElement element: SelectableElement) {
        print("Double-tapped: \(element.elementType)")
    }

    func scoreViewDidTapEmptySpace(_ scoreView: ScoreViewProtocol) {
        scoreView.selectedElements = []
    }

    func scoreView(_ scoreView: ScoreViewProtocol, didChangeZoomLevel zoomLevel: CGFloat) {
        print("Zoom: \(Int(zoomLevel * 100))%")
    }

    func scoreView(_ scoreView: ScoreViewProtocol, didScrollTo offset: CGPoint) {
        // Track scroll position
    }
}
```

## iOS (UIKit)

Use `ScoreView` in UIKit apps:

```swift
import UIKit
import SwiftMusicNotation

class ScoreViewController: UIViewController, ScoreSelectionDelegate {
    var scoreView: ScoreView!

    override func viewDidLoad() {
        super.viewDidLoad()

        scoreView = ScoreView(frame: view.bounds)
        scoreView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        scoreView.selectionDelegate = self

        // Load font
        if let font = try? SMuFLFontManager.shared.loadFont(named: "Bravura") {
            scoreView.loadFont(font)
        }

        view.addSubview(scoreView)
    }

    func loadScore(_ score: Score) {
        let context = LayoutContext.letterSize(staffHeight: 40)
        scoreView.setScore(score, layoutContext: context)
    }

    // MARK: - ScoreSelectionDelegate

    func scoreView(_ scoreView: ScoreViewProtocol, didChangeSelection selection: [SelectableElement]) {
        // Handle selection
    }

    func scoreView(_ scoreView: ScoreViewProtocol, didTapElement element: SelectableElement) {
        // Handle tap
    }

    func scoreView(_ scoreView: ScoreViewProtocol, didDoubleTapElement element: SelectableElement) {
        // Handle double-tap
    }

    func scoreViewDidTapEmptySpace(_ scoreView: ScoreViewProtocol) {
        // Handle empty tap
    }

    func scoreView(_ scoreView: ScoreViewProtocol, didChangeZoomLevel zoomLevel: CGFloat) {
        // Handle zoom
    }

    func scoreView(_ scoreView: ScoreViewProtocol, didScrollTo offset: CGPoint) {
        // Handle scroll
    }
}
```

## ScoreView Protocol

All platform views conform to ``ScoreViewProtocol``:

```swift
public protocol ScoreViewProtocol: AnyObject {
    /// The displayed score.
    var score: Score? { get }

    /// Current zoom level (1.0 = 100%).
    var zoomLevel: CGFloat { get set }

    /// Currently selected elements.
    var selectedElements: [SelectableElement] { get set }

    /// Selection delegate for callbacks.
    var selectionDelegate: ScoreSelectionDelegate? { get set }

    /// Set the score and layout context.
    func setScore(_ score: Score, layoutContext: LayoutContext)

    /// Load a SMuFL font for rendering.
    func loadFont(_ font: LoadedSMuFLFont)
}
```

## Platform Differences

| Feature | SwiftUI | macOS (AppKit) | iOS (UIKit) |
|---------|---------|----------------|-------------|
| Scroll | Automatic | NSScrollView | UIScrollView |
| Zoom | Binding | Scroll wheel + pinch | Pinch gesture |
| Selection | Binding | Delegate | Delegate |
| Touch/Click | Callbacks | Delegate | Delegate |

## See Also

- ``ScoreViewRepresentable``
- ``ScoreViewProtocol``
- ``ScoreSelectionDelegate``
- ``ZoomPreset``
- <doc:SelectionAndInteraction>
