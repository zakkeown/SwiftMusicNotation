# Selection and Interaction

Enable users to select and interact with notation elements.

@Metadata {
    @PageKind(article)
}

## Overview

MusicNotationRenderer provides a complete system for detecting user interactions with notation elements. The ``HitTester`` performs efficient hit detection using spatial indexing, while ``SelectableElement`` provides a uniform representation of selected items that works across all element types.

## Selectable Elements

``SelectableElement`` represents any element the user can interact with:

```swift
public struct SelectableElement {
    /// Unique identifier for this element.
    public let id: String

    /// The type of element (note, rest, measure, etc.).
    public let elementType: SelectableElementType

    /// Bounding box in score coordinates.
    public let bounds: CGRect

    /// Optional: measure number if applicable.
    public let measureNumber: Int?

    /// Optional: part index if applicable.
    public let partIndex: Int?

    /// Optional: staff number if applicable.
    public let staff: Int?
}
```

### Element Types

The ``SelectableElementType`` enum covers all selectable elements:

```swift
public enum SelectableElementType: CaseIterable {
    case note
    case chord
    case rest
    case clef
    case keySignature
    case timeSignature
    case barline
    case beam
    case slur
    case tie
    case articulation
    case dynamic
    case direction
    case lyric
    case measure
    case staff
    case part
}
```

## Hit Testing

``HitTester`` performs efficient hit detection:

```swift
// Create a hit tester for an engraved score
let hitTester = HitTester(engravedScore: engravedScore)

// Test a single point
if let element = hitTester.hitTest(at: tapLocation) {
    print("Hit: \(element.elementType)")
}

// Test a rectangle (for marquee selection)
let elementsInRect = hitTester.hitTest(in: selectionRect)
print("Selected \(elementsInRect.count) elements")
```

### Hit Test Configuration

Configure hit testing behavior:

```swift
var config = HitTestConfiguration()

// Tolerance in points for hit detection
config.hitTolerance = 4.0

// Enable/disable measure selection
config.selectMeasures = true

// Enable/disable staff selection
config.selectStaves = false

// Limit selectable element types
config.selectableTypes = [.note, .rest, .chord]

let hitTester = HitTester(engravedScore: score, config: config)
```

### Element Priority

When multiple elements overlap, higher-priority elements are selected first:

| Priority | Element Types |
|----------|---------------|
| Highest | Notes, Chords |
| High | Rests, Articulations |
| Medium | Dynamics, Lyrics, Directions |
| Low | Slurs, Ties, Beams |
| Lower | Clefs, Key/Time Signatures |
| Lowest | Barlines, Measures, Staves |

## Selection in SwiftUI

Use bindings to track selection:

```swift
struct SelectableScoreView: View {
    @State private var score: Score?
    @State private var selectedElements: [SelectableElement] = []

    var body: some View {
        VStack {
            // Selection info
            SelectionInfoView(elements: selectedElements)

            ScoreViewRepresentable(
                score: $score,
                selectedElements: $selectedElements,
                layoutContext: LayoutContext.letterSize(),
                onSelectionChanged: { elements in
                    handleSelectionChange(elements)
                }
            )
        }
    }

    func handleSelectionChange(_ elements: [SelectableElement]) {
        // Group by type
        let notes = elements.filter { $0.elementType == .note }
        let measures = elements.filter { $0.elementType == .measure }

        print("Selected \(notes.count) notes in \(measures.count) measures")
    }
}
```

### Selection Info View

Display information about selected elements:

```swift
struct SelectionInfoView: View {
    let elements: [SelectableElement]

    var body: some View {
        HStack {
            if elements.isEmpty {
                Text("No selection")
                    .foregroundColor(.secondary)
            } else if elements.count == 1 {
                let element = elements[0]
                Text("\(element.elementType)")
                if let measure = element.measureNumber {
                    Text("Measure \(measure)")
                }
            } else {
                Text("\(elements.count) elements selected")
            }
            Spacer()
        }
        .padding(.horizontal)
    }
}
```

## Selection Delegate

For UIKit/AppKit, implement ``ScoreSelectionDelegate``:

```swift
class ScoreController: ScoreSelectionDelegate {
    func scoreView(_ scoreView: ScoreViewProtocol, didChangeSelection selection: [SelectableElement]) {
        // Update UI based on selection
        updateInspector(with: selection)
    }

    func scoreView(_ scoreView: ScoreViewProtocol, didTapElement element: SelectableElement) {
        // Handle single tap
        switch element.elementType {
        case .note, .chord:
            playElement(element)
        case .measure:
            selectMeasure(element.measureNumber!)
        default:
            break
        }
    }

    func scoreView(_ scoreView: ScoreViewProtocol, didDoubleTapElement element: SelectableElement) {
        // Handle double tap - typically opens editor
        openEditor(for: element)
    }

    func scoreViewDidTapEmptySpace(_ scoreView: ScoreViewProtocol) {
        // Clear selection when tapping empty space
        scoreView.selectedElements = []
    }

    func scoreView(_ scoreView: ScoreViewProtocol, didChangeZoomLevel zoomLevel: CGFloat) {
        // Update zoom indicator
        updateZoomDisplay(zoomLevel)
    }

    func scoreView(_ scoreView: ScoreViewProtocol, didScrollTo offset: CGPoint) {
        // Track scroll position for restore
        saveScrollPosition(offset)
    }
}
```

## Programmatic Selection

Select elements programmatically:

```swift
// Select all notes in a measure
func selectMeasure(_ measureNumber: Int) {
    let hitTester = HitTester(engravedScore: engravedScore)

    // Find the measure bounds
    for page in engravedScore.pages {
        for system in page.systems {
            for measure in system.measures where measure.measureNumber == measureNumber {
                let elements = hitTester.hitTest(in: measure.frame)
                selectedElements = elements.filter { $0.elementType == .note }
                return
            }
        }
    }
}

// Clear selection
func clearSelection() {
    selectedElements = []
}

// Add to selection
func addToSelection(_ element: SelectableElement) {
    if !selectedElements.contains(where: { $0.id == element.id }) {
        selectedElements.append(element)
    }
}

// Toggle selection
func toggleSelection(_ element: SelectableElement) {
    if let index = selectedElements.firstIndex(where: { $0.id == element.id }) {
        selectedElements.remove(at: index)
    } else {
        selectedElements.append(element)
    }
}
```

## Spatial Index Performance

The ``HitTester`` uses a grid-based spatial index for efficient queries:

```swift
// Initial hit test builds the index
let element = hitTester.hitTest(at: point)  // O(1) average

// Subsequent queries use the cached index
let elements = hitTester.hitTest(in: rect)  // O(k) where k = results

// Invalidate when score changes
hitTester.invalidateIndex()
```

For very large scores, the spatial index significantly improves hit testing performance compared to linear search.

## Best Practices

1. **Update selection immediately** to provide responsive feedback
2. **Clear selection** when tapping empty space
3. **Provide visual feedback** for selected elements
4. **Support multi-selection** for editing operations
5. **Invalidate hit tester** when the score changes

## See Also

- ``SelectableElement``
- ``SelectableElementType``
- ``HitTester``
- ``HitTestConfiguration``
- ``ScoreSelectionDelegate``
- <doc:PlatformViews>
