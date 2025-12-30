# Configuring Layout

Customize spacing, dimensions, and layout behavior.

@Metadata {
    @PageKind(article)
}

## Overview

The layout engine provides extensive configuration options through ``LayoutConfiguration``, ``LayoutContext``, and related types. This article covers how to customize layout behavior for different use cases.

## Layout Context

``LayoutContext`` defines the target page and display settings:

### Page Size

```swift
// US Letter (8.5" x 11" at 72 DPI)
let letter = LayoutContext.letterSize(staffHeight: 40)

// A4 (210mm x 297mm at 72 DPI)
let a4 = LayoutContext.a4Size(staffHeight: 40)

// Custom size
let custom = LayoutContext(
    pageSize: CGSize(width: 1000, height: 1400),
    margins: EdgeInsets(all: 50),
    staffHeight: 40
)
```

### Margins

Control the printable area:

```swift
// Uniform margins
let margins = EdgeInsets(all: 72)  // 1 inch all around

// Different margins for binding
let bookMargins = EdgeInsets(
    top: 72,
    left: 100,     // Extra for binding
    bottom: 72,
    right: 72
)

let context = LayoutContext(
    pageSize: CGSize(width: 612, height: 792),
    margins: bookMargins,
    staffHeight: 40
)
```

### Staff Height

The staff height determines the overall scale of the notation:

```swift
// Smaller for dense scores
let condensed = LayoutContext.letterSize(staffHeight: 30)

// Standard size
let standard = LayoutContext.letterSize(staffHeight: 40)

// Large print for accessibility
let large = LayoutContext.letterSize(staffHeight: 50)
```

Relationship to other measurements:
- **Staff height** = distance from bottom to top staff line = 4 staff spaces
- **Staff space** = distance between adjacent lines = staffHeight / 4
- **Font size** = staffHeight (SMuFL fonts are designed at 1 em = 4 staff spaces)

## Layout Configuration

``LayoutConfiguration`` controls the engine's behavior:

### First Page Offset

Leave space for title and credits:

```swift
var config = LayoutConfiguration()

// More space for title page
config.firstPageTopOffset = 100

// Minimal offset (title at very top)
config.firstPageTopOffset = 30
```

### Fixed Element Widths

Space allocated for front-of-system elements:

```swift
var config = LayoutConfiguration()

// Clef width (G clef needs more than percussion clef)
config.clefWidth = 25

// Key signature width (depends on max accidentals)
config.keySignatureWidth = 40  // Room for 7 sharps/flats

// Time signature width
config.timeSignatureWidth = 25
```

## Horizontal Spacing Configuration

``SpacingConfiguration`` controls note spacing:

```swift
var spacingConfig = SpacingConfiguration()

// Minimum space between any two notes
spacingConfig.minimumNoteSpace = 10

// Base width for a quarter note
spacingConfig.quarterNoteSpacing = 35

// Logarithmic spacing factor (how much longer notes get more space)
spacingConfig.spacingFactor = 1.5

// Apply to layout configuration
var layoutConfig = LayoutConfiguration()
layoutConfig.spacingConfig = spacingConfig
```

### Spacing Philosophy

Music notation uses proportional spacing where longer notes get more horizontal space, but not linearly. The relationship is typically logarithmic:

| Duration | Relative Width |
|----------|---------------|
| Whole note | 4x quarter |
| Half note | 2x quarter |
| Quarter note | 1x (base) |
| Eighth note | 0.7x quarter |
| Sixteenth note | 0.5x quarter |

Adjust `spacingFactor` to control this curve:
- Lower values (1.0-1.2): More even spacing
- Higher values (1.5-2.0): More proportional spacing

## Vertical Spacing Configuration

``VerticalSpacingConfiguration`` controls vertical distances:

```swift
var verticalConfig = VerticalSpacingConfiguration()

// Distance between staves of the same part (e.g., piano)
verticalConfig.staffDistance = 60

// Distance between systems
verticalConfig.systemDistance = 80

// Padding above and below systems
verticalConfig.systemTopPadding = 20
verticalConfig.systemBottomPadding = 20
```

### Multi-Staff Parts

For instruments like piano with multiple staves:

```swift
// Closer spacing for piano grand staff
verticalConfig.staffDistance = 50

// More space between different parts
verticalConfig.systemDistance = 100
```

### Dense vs. Spacious

```swift
// Dense layout for page economy
var denseConfig = VerticalSpacingConfiguration()
denseConfig.staffDistance = 40
denseConfig.systemDistance = 60
denseConfig.systemTopPadding = 10
denseConfig.systemBottomPadding = 10

// Spacious layout for readability
var spaciousConfig = VerticalSpacingConfiguration()
spaciousConfig.staffDistance = 80
spaciousConfig.systemDistance = 100
spaciousConfig.systemTopPadding = 30
spaciousConfig.systemBottomPadding = 30
```

## Configuration Presets

Create reusable configurations:

```swift
extension LayoutConfiguration {
    /// Compact layout for many pages
    static let compact: LayoutConfiguration = {
        var config = LayoutConfiguration()
        config.firstPageTopOffset = 40
        config.spacingConfig.minimumNoteSpace = 8
        config.spacingConfig.quarterNoteSpacing = 30
        config.verticalConfig.staffDistance = 45
        config.verticalConfig.systemDistance = 60
        return config
    }()

    /// Spacious layout for readability
    static let spacious: LayoutConfiguration = {
        var config = LayoutConfiguration()
        config.firstPageTopOffset = 100
        config.spacingConfig.minimumNoteSpace = 12
        config.spacingConfig.quarterNoteSpacing = 45
        config.verticalConfig.staffDistance = 70
        config.verticalConfig.systemDistance = 90
        return config
    }()

    /// Large print for accessibility
    static let largePrint: LayoutConfiguration = {
        var config = LayoutConfiguration()
        config.firstPageTopOffset = 120
        config.clefWidth = 35
        config.keySignatureWidth = 50
        config.timeSignatureWidth = 35
        config.spacingConfig.quarterNoteSpacing = 50
        return config
    }()
}

// Usage
let engine = LayoutEngine(config: .compact)
let context = LayoutContext.letterSize(staffHeight: 35)
```

## Dynamic Configuration

Adjust configuration based on score characteristics:

```swift
func configurationForScore(_ score: Score) -> LayoutConfiguration {
    var config = LayoutConfiguration()

    // Adjust for key signature complexity
    let maxAccidentals = score.parts.flatMap { part in
        part.measures.compactMap { $0.attributes?.keySignatures.first?.fifths }
    }.map { abs($0) }.max() ?? 0

    config.keySignatureWidth = CGFloat(20 + maxAccidentals * 10)

    // Adjust for number of parts
    if score.parts.count > 4 {
        config.verticalConfig.staffDistance = 50
        config.verticalConfig.systemDistance = 70
    }

    // Adjust for average note density
    let noteDensity = calculateNoteDensity(score)
    if noteDensity > 10 {  // Many notes per measure
        config.spacingConfig.minimumNoteSpace = 6
    }

    return config
}
```

## See Also

- ``LayoutConfiguration``
- ``SpacingConfiguration``
- ``VerticalSpacingConfiguration``
- ``LayoutContext``
- <doc:LayoutEngine>
- <doc:UnitsAndScaling>
