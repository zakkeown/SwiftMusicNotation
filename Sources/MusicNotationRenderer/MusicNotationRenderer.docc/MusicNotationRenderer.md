# ``MusicNotationRenderer``

Render music notation with Core Graphics and display in platform views.

## Overview

MusicNotationRenderer provides rendering capabilities for displaying engraved scores. It includes Core Graphics rendering and cross-platform SwiftUI views.

### SwiftUI Integration

Use `ScoreViewRepresentable` for SwiftUI apps:

```swift
import SwiftUI
import SwiftMusicNotation

struct ContentView: View {
    @State private var score: Score?
    @State private var zoomLevel: CGFloat = 1.0
    @State private var selectedElements: [SelectableElement] = []

    let layoutContext = LayoutContext.letterSize(staffHeight: 40)

    var body: some View {
        ScoreViewRepresentable(
            score: $score,
            zoomLevel: $zoomLevel,
            selectedElements: $selectedElements,
            layoutContext: layoutContext,
            onElementTapped: { element in
                print("Tapped: \(element.elementType)")
            }
        )
    }
}
```

### Selection and Interaction

Handle element selection and taps:

```swift
ScoreViewRepresentable(
    score: $score,
    selectedElements: $selectedElements,
    layoutContext: context,
    onSelectionChanged: { elements in
        print("Selected \(elements.count) elements")
    },
    onElementTapped: { element in
        // Single tap
    },
    onElementDoubleTapped: { element in
        // Double tap
    },
    onEmptySpaceTapped: {
        // Clear selection
    }
)
```

### Render Configuration

Customize visual appearance:

```swift
var config = RenderConfiguration()

// Colors
config.backgroundColor = .white
config.staffLineColor = .black
config.noteColor = .black
config.barlineColor = .black

// Line thicknesses
config.staffLineThickness = 1.0
config.thinBarlineThickness = 1.0
config.thickBarlineThickness = 3.0
config.stemThickness = 1.2

let renderer = MusicRenderer(config: config)
```

### Direct Rendering

Render to a Core Graphics context:

```swift
let renderer = MusicRenderer()
let engravedScore = layoutEngine.layout(score: score, context: layoutContext)

// Render a specific page
renderer.render(
    score: engravedScore,
    pageIndex: 0,
    in: cgContext
)
```

### Platform-Specific Views

For more control, use the native views directly:

```swift
// macOS (AppKit)
let scoreView = ScoreView(frame: bounds)
scoreView.setScore(score, layoutContext: context)
scoreView.selectionDelegate = self

// iOS (UIKit)
let scoreView = ScoreView(frame: bounds)
scoreView.setScore(score, layoutContext: context)
```

### Zoom Presets

Use standard zoom levels:

```swift
let preset = ZoomPreset.oneHundredPercent
let nearest = ZoomPreset.nearest(to: currentZoom)
let nextUp = ZoomPreset.fiftyPercent.nextHigher
```

## Topics

### SwiftUI Views

- ``ScoreViewRepresentable``

### Rendering

- ``MusicRenderer``
- ``RenderConfiguration``
- ``RenderContext``

### Component Renderers

- ``NoteRenderer``
- ``BeamRenderer``
- ``CurveRenderer``
- ``StaffRenderer``
- ``GlyphRenderer``
- ``TextRenderer``

### Advanced Rendering

- <doc:CustomRendering>
- <doc:RenderingToContext>

### View Protocol

- ``ScoreViewProtocol``
- ``ScoreSelectionDelegate``
- ``ScoreViewConfiguration``

### Platform Views

- <doc:PlatformViews>

### Selection

- ``SelectableElement``
- ``SelectableElementType``
- <doc:SelectionAndInteraction>

### Zoom

- ``ZoomPreset``
