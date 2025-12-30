# Horizontal Spacing Algorithm

Understand how note spacing is computed for professional music engraving.

@Metadata {
    @PageKind(article)
}

## Overview

MusicNotationLayout uses a logarithmic duration-based spacing algorithm that follows traditional music engraving principles. This approach produces visually balanced notation where note spacing relates to duration in a way that's natural to read.

## The Logarithmic Model

The core principle: doubling a note's duration increases its horizontal space by a fixed amount, rather than doubling the space. This creates the characteristic look of professionally engraved music.

### Why Logarithmic?

Linear spacing (where a half note gets twice the space of a quarter note) creates unnaturally wide measures for longer notes and cramped measures for short notes. Logarithmic spacing compresses this relationship:

| Duration | Linear Spacing | Logarithmic Spacing |
|----------|---------------|---------------------|
| Whole note | 120 pts | 60 pts |
| Half note | 60 pts | 50 pts |
| Quarter note | 30 pts | 40 pts |
| Eighth note | 15 pts | 30 pts |
| Sixteenth note | 7.5 pts | 20 pts |

### The Formula

The ``HorizontalSpacingEngine`` computes ideal width using:

```
width = quarterNoteSpacing * (1 + spacingFactor * log₂(durationInQuarterNotes))
```

Where:
- `quarterNoteSpacing`: Base width for a quarter note (default: 30 points)
- `spacingFactor`: Controls the logarithmic curve steepness (default: 0.7)
- `durationInQuarterNotes`: Duration expressed as quarter note multiples

## Column-Based Spacing

The algorithm organizes musical events into columns by their time position:

1. **Group by position**: Notes, rests, and other elements at the same beat are grouped into columns
2. **Calculate minimum widths**: Each column needs enough space for its widest element (including accidentals, dots)
3. **Apply ideal widths**: Duration to the next column determines the ideal width
4. **Constrain to minimums**: Final width is the maximum of ideal width and minimum width

## Configuration

Customize spacing through ``SpacingConfiguration``:

```swift
var config = SpacingConfiguration()

// Tighter spacing for dense passages
config.quarterNoteSpacing = 25.0
config.spacingFactor = 0.5
config.minimumNoteSpacing = 10.0

// More generous spacing for teaching materials
config.quarterNoteSpacing = 40.0
config.spacingFactor = 0.8
config.minimumNoteSpacing = 15.0

let engine = HorizontalSpacingEngine(config: config)
```

### Key Parameters

| Parameter | Purpose | Default |
|-----------|---------|---------|
| `quarterNoteSpacing` | Base width for quarter notes | 30.0 |
| `spacingFactor` | Logarithmic curve steepness | 0.7 |
| `minimumNoteSpacing` | Smallest allowed gap | 12.0 |
| `accidentalWidth` | Space reserved for accidentals | 8.0 |
| `dotSpacing` | Space before each dot | 3.0 |

## Justification

After computing natural spacing, the engine can justify content to fill a target width:

```swift
let naturalResult = engine.computeSpacing(elements: elements, divisions: 24, measureDuration: 96)
let justifiedResult = engine.justify(result: naturalResult, targetWidth: 300)
```

Justification distributes extra space proportionally based on each column's original width, maintaining the visual relationships established by the logarithmic algorithm.

## See Also

- ``HorizontalSpacingEngine``
- ``SpacingConfiguration``
- <doc:BreakingAlgorithm>
