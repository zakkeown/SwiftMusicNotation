# ``MusicNotationLayout``

Compute positions for music notation elements.

## Overview

MusicNotationLayout provides `LayoutEngine` for computing the precise positions of all notation elements. It handles horizontal spacing, vertical staff placement, system breaks, and page breaks.

### Basic Layout

```swift
let layoutEngine = LayoutEngine()

// Create layout context
let context = LayoutContext.letterSize(staffHeight: 40)

// Compute layout
let engravedScore = layoutEngine.layout(score: score, context: context)
```

### Layout Context

Configure page size, margins, and staff height:

```swift
// Preset sizes
let letter = LayoutContext.letterSize(staffHeight: 40)
let a4 = LayoutContext.a4Size(staffHeight: 40)

// Custom configuration
let custom = LayoutContext(
    pageSize: CGSize(width: 800, height: 1000),
    margins: EdgeInsets(top: 72, left: 72, bottom: 72, right: 72),
    staffHeight: 35,
    fontName: "Bravura"
)
```

### Layout Configuration

Fine-tune layout behavior:

```swift
var config = LayoutConfiguration()

// Spacing configuration
config.spacingConfig = SpacingConfiguration()

// Vertical spacing
config.verticalConfig = VerticalSpacingConfiguration()

// Title area offset
config.firstPageTopOffset = 80

// Fixed element widths
config.clefWidth = 25
config.keySignatureWidth = 35
config.timeSignatureWidth = 25

let layoutEngine = LayoutEngine(config: config)
```

### Engraved Score

The layout engine produces an `EngravedScore` with computed positions:

```swift
let engravedScore = layoutEngine.layout(score: score, context: context)

// Access pages
for page in engravedScore.pages {
    print("Page \(page.pageNumber): \(page.systems.count) systems")

    // Access systems
    for system in page.systems {
        print("  Measures \(system.measureRange)")

        // Access staves
        for staff in system.staves {
            print("    Staff \(staff.staffNumber) at y=\(staff.centerLineY)")
        }
    }
}
```

### Units and Scaling

The layout uses a consistent coordinate system:

```swift
// ScalingContext converts between units
let scaling = engravedScore.scaling

// Staff spaces (1 space = distance between staff lines)
let oneSpace = StaffSpaces(1.0)
let inPoints = scaling.toPoints(oneSpace)

// Tenths (MusicXML's unit, 1/10 of interline space)
let tenTenths = Tenths(10.0)
let tenthsInPoints = scaling.toPoints(tenTenths)
```

## Topics

### Layout Engine

- ``LayoutEngine``
- ``LayoutConfiguration``
- ``LayoutContext``

### Algorithms

- <doc:SpacingAlgorithm>
- <doc:BreakingAlgorithm>
- <doc:CollisionDetection>

### Advanced Topics

- <doc:OrchestralScores>

### Spacing

- ``HorizontalSpacingEngine``
- ``SpacingConfiguration``
- ``SpacingResult``

### Breaking

- ``BreakingEngine``
- ``BreakingConfiguration``
- ``SystemBreak``
- ``PageBreakInfo``

### Collision Detection

- ``CollisionDetector``
- ``CollisionConfiguration``
- ``SpatialHash``

### Engraved Types

- ``EngravedScore``
- ``EngravedPage``
- ``EngravedSystem``
- ``EngravedMeasure``
- ``EngravedStaff``
- ``EngravedElement``

### Configuration

- ``VerticalSpacingConfiguration``
- ``EdgeInsets``

### Units

- ``ScalingContext``
- ``StaffSpaces``
- ``Tenths``
