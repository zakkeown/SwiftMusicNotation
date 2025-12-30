# SMuFL Integration

Understanding how SwiftMusicNotation uses the Standard Music Font Layout specification.

@Metadata {
    @PageKind(article)
}

## Overview

SMuFL (Standard Music Font Layout) is a specification for music notation fonts. SwiftMusicNotation uses SMuFL-compliant fonts for all musical symbols, ensuring professional-quality rendering and compatibility with the broader music notation ecosystem.

## What is SMuFL?

SMuFL is a W3C community specification that standardizes:

- **Glyph Names**: Canonical names for every musical symbol (e.g., `noteheadBlack`, `gClef`)
- **Code Points**: Unicode Private Use Area assignments (U+E000 onwards)
- **Metrics**: Precise bounding boxes and anchor points for each glyph
- **Engraving Defaults**: Recommended thicknesses for stems, beams, slurs, etc.

### Why SMuFL Matters

Before SMuFL, every notation font used different encodings and metrics. This made font switching difficult and required per-font rendering logic. SMuFL solves this by providing:

1. **Interoperability**: Any SMuFL font works with any SMuFL-aware application
2. **Precise Metrics**: Glyph metadata enables exact positioning without trial-and-error
3. **Comprehensive Coverage**: Over 2,600 glyphs covering Western notation and beyond
4. **Active Development**: Maintained by the W3C Music Notation Community Group

### Reference Fonts

The SMuFL specification includes reference fonts:

- **Bravura**: The primary reference font, included with MuseScore and many applications
- **Petaluma**: A hand-engraved style font
- **Leland**: Used by MuseScore 4
- **Sebastian**: Used by StaffPad

SwiftMusicNotation works with any SMuFL-compliant font.

## SMuFLKit Module

The `SMuFLKit` module handles all SMuFL-related functionality:

```swift
import SMuFLKit

// Load a font
let font = try SMuFLFontManager.shared.loadFont(
    named: "Bravura",
    from: fontBundle
)

// Access glyph code points
let codePoint = font.codePoint(for: .noteheadBlack)  // U+E0A4

// Get glyph bounding box
if let bbox = font.metadata.boundingBox(for: .noteheadBlack) {
    print("Width: \(bbox.width) staff spaces")
}

// Get anchor points
if let anchors = font.metadata.anchors(for: .noteheadBlack) {
    if let stemUp = anchors.point(for: .stemUpSE) {
        print("Stem attachment: \(stemUp)")
    }
}
```

## Glyph Names

`SMuFLGlyphName` is an enum containing all standard glyph names organized by category:

### Common Categories

```swift
// Clefs (U+E050–U+E07F)
SMuFLGlyphName.gClef           // Treble clef
SMuFLGlyphName.fClef           // Bass clef
SMuFLGlyphName.cClef           // Alto/tenor clef

// Noteheads (U+E0A0–U+E0FF)
SMuFLGlyphName.noteheadWhole   // Whole note
SMuFLGlyphName.noteheadHalf    // Half note
SMuFLGlyphName.noteheadBlack   // Quarter note and smaller

// Flags (U+E240–U+E25F)
SMuFLGlyphName.flag8thUp       // Eighth note flag (stem up)
SMuFLGlyphName.flag8thDown     // Eighth note flag (stem down)

// Rests (U+E4E0–U+E4FF)
SMuFLGlyphName.restWhole       // Whole rest
SMuFLGlyphName.restQuarter     // Quarter rest

// Accidentals (U+E260–U+E26F)
SMuFLGlyphName.accidentalSharp
SMuFLGlyphName.accidentalFlat
SMuFLGlyphName.accidentalNatural

// Dynamics (U+E520–U+E54F)
SMuFLGlyphName.dynamicPiano    // p
SMuFLGlyphName.dynamicForte    // f
SMuFLGlyphName.dynamicMezzo    // m

// Time Signatures (U+E080–U+E09F)
SMuFLGlyphName.timeSig0 ... timeSig9
SMuFLGlyphName.timeSigCommon   // C (common time)
SMuFLGlyphName.timeSigCutCommon // Cut time
```

### Full Coverage

The enum includes glyphs for:

| Category | Examples |
|----------|----------|
| Barlines & Repeats | Final barline, repeat signs, segno, coda |
| Clefs | G, F, C clefs with octave variants |
| Time Signatures | Digits, common/cut symbols |
| Noteheads | Standard, X, diamond, slash, plus |
| Stems & Flags | Up/down flags for all durations |
| Rests | Whole through 256th |
| Accidentals | Standard plus microtonal |
| Articulations | Staccato, accent, tenuto, fermata |
| Dynamics | All standard dynamics and hairpins |
| Ornaments | Trills, turns, mordents |
| Percussion | All standard notehead shapes |
| Beams & Tuplets | Beam fragments, tuplet brackets |
| Lyrics | Elision connectors |
| And many more... | Medieval, avant-garde, figured bass |

## Glyph Metadata

SMuFL fonts include JSON metadata files that provide precise measurements for each glyph.

### Bounding Boxes

Every glyph has a bounding box measured in **staff spaces** (the distance between two staff lines):

```swift
public struct GlyphBoundingBox {
    // Bottom-left corner
    let southWestX: StaffSpaces
    let southWestY: StaffSpaces

    // Top-right corner
    let northEastX: StaffSpaces
    let northEastY: StaffSpaces

    var width: StaffSpaces { northEastX - southWestX }
    var height: StaffSpaces { northEastY - southWestY }
}
```

Bounding boxes follow mathematical coordinates where Y increases upward (opposite of Core Graphics).

### Anchor Points

Anchors define precise attachment points for combining glyphs:

```swift
public enum AnchorType {
    // Stem attachment for noteheads
    case stemUpSE      // Stem up, attach at south-east
    case stemDownNW    // Stem down, attach at north-west

    // Cut-out regions for accidental kerning
    case cutOutNE, cutOutSE, cutOutSW, cutOutNW

    // Other positioning
    case opticalCenter // For dynamic alignment
    case noteheadOrigin // Left edge of notehead
}
```

Example: Attaching a stem to a notehead:

```swift
// Get notehead anchors
let anchors = font.metadata.anchors(for: .noteheadBlack)

// For an upward stem, attach at bottom-right of notehead
if let stemAttach = anchors?.point(for: .stemUpSE) {
    let stemX = noteheadX + stemAttach.x * staffSpaceInPoints
    let stemY = noteheadY - stemAttach.y * staffSpaceInPoints  // Flip Y
}
```

## Engraving Defaults

Fonts provide recommended measurements for drawn elements:

```swift
public struct EngravingDefaults {
    // Line thicknesses (in staff spaces)
    var staffLineThickness: StaffSpaces      // ~0.13
    var stemThickness: StaffSpaces           // ~0.12
    var beamThickness: StaffSpaces           // ~0.5
    var beamSpacing: StaffSpaces             // ~0.25
    var legerLineThickness: StaffSpaces      // ~0.16
    var legerLineExtension: StaffSpaces      // ~0.4

    // Slurs and ties
    var slurEndpointThickness: StaffSpaces   // ~0.1
    var slurMidpointThickness: StaffSpaces   // ~0.22
    var tieEndpointThickness: StaffSpaces    // ~0.1
    var tieMidpointThickness: StaffSpaces    // ~0.22

    // Barlines
    var thinBarlineThickness: StaffSpaces    // ~0.16
    var thickBarlineThickness: StaffSpaces   // ~0.5
    var barlineSeparation: StaffSpaces       // ~0.4

    // And many more...
}
```

The renderer uses these values to ensure visual consistency with the font's design:

```swift
let defaults = font.engravingDefaults

// Draw staff lines with correct thickness
context.setLineWidth(defaults.staffLineThickness * staffSpaceInPoints)

// Draw beams with correct thickness
let beamHeight = defaults.beamThickness * staffSpaceInPoints
```

## GlyphRepresentable Protocol

Domain types implement `GlyphRepresentable` to map to SMuFL glyphs:

```swift
public protocol GlyphRepresentable {
    var glyph: SMuFLGlyphName? { get }
}

// Clefs
extension Clef: GlyphRepresentable {
    public var glyph: SMuFLGlyphName? {
        switch sign {
        case .g: return .gClef
        case .f: return .fClef
        case .c: return .cClef
        case .percussion: return .unpitchedPercussionClef1
        // ...
        }
    }
}

// Accidentals
extension Accidental: GlyphRepresentable {
    public var glyph: SMuFLGlyphName? {
        switch self {
        case .sharp: return .accidentalSharp
        case .flat: return .accidentalFlat
        case .natural: return .accidentalNatural
        // ...
        }
    }
}
```

### Placement-Dependent Glyphs

Some symbols have different glyphs for above/below placement:

```swift
public protocol PlacementGlyphRepresentable: GlyphRepresentable {
    var glyphAbove: SMuFLGlyphName? { get }
    var glyphBelow: SMuFLGlyphName? { get }
    func glyph(for placement: Placement) -> SMuFLGlyphName?
}

// Articulations have above/below variants
extension Articulation: PlacementGlyphRepresentable {
    var glyphAbove: SMuFLGlyphName? {
        switch self {
        case .staccato: return .articStaccatoAbove
        case .accent: return .articAccentAbove
        // ...
        }
    }

    var glyphBelow: SMuFLGlyphName? {
        switch self {
        case .staccato: return .articStaccatoBelow
        case .accent: return .articAccentBelow
        // ...
        }
    }
}
```

### Composite Glyphs

Dynamics like "mf" are composed of multiple glyphs:

```swift
public protocol CompositeGlyphRepresentable: GlyphRepresentable {
    var componentGlyphs: [SMuFLGlyphName] { get }
}

extension Dynamic: CompositeGlyphRepresentable {
    var componentGlyphs: [SMuFLGlyphName] {
        switch self {
        case .mf: return [.dynamicMezzo, .dynamicForte]
        case .mp: return [.dynamicMezzo, .dynamicPiano]
        case .fff: return [.dynamicForte, .dynamicForte, .dynamicForte]
        // ...
        }
    }
}
```

## Loading Custom Fonts

Load any SMuFL-compliant font:

```swift
// From a bundle (app or framework)
let font = try SMuFLFontManager.shared.loadFont(
    named: "Bravura",
    from: Bundle.main
)

// From specific file URLs
let font = try SMuFLFontManager.shared.loadFont(
    name: "MyCustomFont",
    fontURL: fontFileURL,
    metadataURL: metadataJSONURL
)
```

### Required Files

A SMuFL font bundle needs:

1. **Font file**: `.ttf` or `.otf` with glyphs at SMuFL code points
2. **Metadata JSON**: `[fontname]_metadata.json` with bounding boxes and anchors

Optional:

3. **Classes JSON**: Glyph categories for selection
4. **Ranges JSON**: Code point ranges for validation

## Coordinate Conversion

SMuFL uses staff spaces with Y-up coordinates. Convert to Core Graphics (Y-down):

```swift
// Convert staff spaces to points
let points = staffSpaces * staffSpaceInPoints

// Flip Y coordinate
let cgY = -smuflY * staffSpaceInPoints

// Full conversion for a glyph position
func cgPoint(from smuflPoint: CGPoint, staffSpaceInPoints: CGFloat) -> CGPoint {
    CGPoint(
        x: smuflPoint.x * staffSpaceInPoints,
        y: -smuflPoint.y * staffSpaceInPoints
    )
}
```

## Best Practices

### 1. Cache Font References

```swift
// Load once and reuse
class MyView {
    private let font: LoadedSMuFLFont

    init() {
        self.font = try! SMuFLFontManager.shared.loadFont(named: "Bravura", from: .main)
    }
}
```

### 2. Use Metadata for Positioning

```swift
// Don't guess positions - use anchor points
let bbox = font.metadata.boundingBox(for: .gClef)
let clefHeight = bbox?.height ?? 4.0  // Fallback if metadata missing
```

### 3. Respect Engraving Defaults

```swift
// Use font-provided thicknesses
let stemWidth = font.engravingDefaults.stemThickness * scale
```

### 4. Handle Missing Glyphs

```swift
// Check for glyph availability
if font.hasGlyph(.noteheadSlashHorizontalEnds) {
    // Use glyph
} else {
    // Use fallback or skip
}
```

## See Also

- <doc:ModuleDesign>
- [SMuFL Specification](https://w3c.github.io/smufl/latest/)
- [Bravura Font](https://github.com/steinbergmedia/bravura)
