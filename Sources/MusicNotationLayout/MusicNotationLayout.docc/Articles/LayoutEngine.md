# Layout Engine

Transform scores into positioned elements ready for rendering.

@Metadata {
    @PageKind(article)
}

## Overview

``LayoutEngine`` is the core of the layout system, transforming a `Score` into an ``EngravedScore`` with computed positions for every notation element. This article explains the layout pipeline, how to configure the engine, and how to work with the results.

## The Layout Pipeline

The layout engine processes scores through a multi-stage pipeline:

```
Score → LayoutEngine.layout() → EngravedScore

┌─────────────────────────────────────────────────────────┐
│ 1. Horizontal Spacing                                   │
│    Compute widths based on duration and element types   │
├─────────────────────────────────────────────────────────┤
│ 2. System Breaks                                        │
│    Determine which measures fit on each line            │
├─────────────────────────────────────────────────────────┤
│ 3. Vertical Spacing                                     │
│    Position staves within each system                   │
├─────────────────────────────────────────────────────────┤
│ 4. Page Breaks                                          │
│    Distribute systems across pages                      │
├─────────────────────────────────────────────────────────┤
│ 5. Element Positioning                                  │
│    Compute final coordinates for all elements           │
└─────────────────────────────────────────────────────────┘
```

## Basic Usage

```swift
import MusicNotationLayout

// Create the layout engine
let layoutEngine = LayoutEngine()

// Define the layout context (page size, margins, staff height)
let context = LayoutContext.letterSize(staffHeight: 40)

// Compute the layout
let engravedScore = layoutEngine.layout(score: score, context: context)

// The result is ready for rendering
for page in engravedScore.pages {
    print("Page \(page.pageNumber): \(page.systems.count) systems")
}
```

## Layout Context

The ``LayoutContext`` defines the target page and display settings:

```swift
// US Letter (8.5" x 11") with 1-inch margins
let letter = LayoutContext.letterSize(staffHeight: 40)

// A4 paper (210mm x 297mm)
let a4 = LayoutContext.a4Size(staffHeight: 40)

// Custom configuration
let custom = LayoutContext(
    pageSize: CGSize(width: 800, height: 1200),
    margins: EdgeInsets(top: 50, left: 60, bottom: 50, right: 60),
    staffHeight: 35,
    fontName: "Bravura"
)
```

### Staff Height

The `staffHeight` parameter controls the size of the notation:

| Staff Height | Use Case |
|--------------|----------|
| 25-30 points | Pocket scores, dense orchestral parts |
| 35-40 points | Standard sheet music (default) |
| 45-50 points | Large print, educational music |
| 60+ points | Projected display, accessibility |

## Engraved Score Structure

The output is an ``EngravedScore`` containing a hierarchy of positioned elements:

```swift
let engraved = layoutEngine.layout(score: score, context: context)

// Access pages
for page in engraved.pages {
    // Page frame in points
    let pageFrame = page.frame

    // Credits (title, composer) on first page
    for credit in page.credits {
        print("\(credit.text) at \(credit.position)")
    }

    // Systems (lines of music)
    for system in page.systems {
        // System frame relative to page
        let systemFrame = system.frame

        // Measure range on this system
        let measures = system.measureRange  // e.g., 1...4

        // Staves within the system
        for staff in system.staves {
            print("Staff \(staff.staffNumber) at y=\(staff.centerLineY)")
        }

        // Individual measures
        for measure in system.measures {
            print("Measure \(measure.measureNumber): \(measure.frame)")
        }
    }
}
```

## Configuring the Engine

Use ``LayoutConfiguration`` to customize layout behavior:

```swift
var config = LayoutConfiguration()

// First page spacing for title
config.firstPageTopOffset = 100  // Extra space for title area

// Element widths
config.clefWidth = 25            // Space for clef symbols
config.keySignatureWidth = 35    // Space for key signature
config.timeSignatureWidth = 25   // Space for time signature

// Create engine with custom config
let engine = LayoutEngine(config: config)
```

### Spacing Configuration

Fine-tune horizontal spacing:

```swift
config.spacingConfig.minimumNoteSpace = 10
config.spacingConfig.quarterNoteSpacing = 40
config.spacingConfig.spacingFactor = 1.2
```

### Vertical Spacing Configuration

Adjust vertical distances:

```swift
config.verticalConfig.staffDistance = 60       // Between staves in a part
config.verticalConfig.systemDistance = 80      // Between systems
config.verticalConfig.systemTopPadding = 20
config.verticalConfig.systemBottomPadding = 20
```

## Working with Scaling

The ``ScalingContext`` converts between coordinate systems:

```swift
let scaling = engravedScore.scaling

// Staff space to points
let staffSpace = StaffSpaces(1.0)
let points = scaling.staffSpacesToPoints(staffSpace)

// Tenths (MusicXML units) to points
let tenths = Tenths(40)  // 40 tenths = 1 staff space
let tenthsInPoints = scaling.tenthsToPoints(tenths)

// Points per staff space
let pointsPerSpace = scaling.pointsPerStaffSpace
```

## Multi-Part Scores

For scores with multiple parts, the engine positions staves appropriately:

```swift
// Access part-specific staves in a system
for system in page.systems {
    for staff in system.staves {
        print("Part \(staff.partIndex), Staff \(staff.staffNumber)")
        print("  Top: \(staff.frame.minY), Bottom: \(staff.frame.maxY)")
    }
}
```

## Thread Safety

``LayoutEngine`` is not thread-safe. For concurrent layout:

```swift
// Safe: separate engines per task
await withTaskGroup(of: EngravedScore.self) { group in
    for score in scores {
        group.addTask {
            let engine = LayoutEngine()  // New instance
            let context = LayoutContext.letterSize(staffHeight: 40)
            return engine.layout(score: score, context: context)
        }
    }
}
```

## See Also

- ``LayoutEngine``
- ``LayoutContext``
- ``LayoutConfiguration``
- ``EngravedScore``
- <doc:ConfiguringLayout>
- <doc:UnitsAndScaling>
