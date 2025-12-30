# Font Metadata

Use font metadata for precise glyph positioning and layout.

@Metadata {
    @PageKind(article)
}

## Overview

SMuFL fonts include JSON metadata files that provide essential information for accurate music notation rendering. This metadata includes glyph bounding boxes, anchor points for combining glyphs, advance widths for spacing, and engraving defaults for layout parameters.

## What Metadata Provides

SMuFL metadata is loaded automatically when you load a font with ``SMuFLFontManager``. It includes:

| Category | Purpose |
|----------|---------|
| Bounding boxes | Visual extent of each glyph for collision detection |
| Anchors | Attachment points for stems, articulations, etc. |
| Advance widths | Horizontal spacing between glyphs |
| Engraving defaults | Recommended line thicknesses and spacing |
| Optional glyphs | Font-specific extended glyph sets |
| Stylistic sets | Alternate glyph appearances |

## Accessing Metadata

Metadata is available through the ``LoadedSMuFLFont`` instance:

```swift
let font = try SMuFLFontManager.shared.loadFont(named: "Bravura")

// Check if metadata was loaded
if let metadata = font.metadata {
    print("Font version: \(metadata.fontVersion ?? "unknown")")
}

// Access individual metadata items
let bbox = font.boundingBox(for: .noteheadBlack)
let anchors = font.anchors(for: .noteheadBlack)
let width = font.advanceWidth(for: .noteheadBlack)
```

## Bounding Boxes

Bounding boxes define the visual extent of a glyph in staff spaces. They're essential for collision detection and layout calculations.

```swift
if let bbox = font.boundingBox(for: .noteheadBlack) {
    // Coordinates are in staff spaces
    // Origin (0,0) is at the glyph's registration point
    // Y increases upward (mathematical coordinates)

    let leftEdge = bbox.southWestX    // Left boundary
    let bottomEdge = bbox.southWestY  // Bottom boundary
    let rightEdge = bbox.northEastX   // Right boundary
    let topEdge = bbox.northEastY     // Top boundary

    // Computed properties
    let glyphWidth = bbox.width       // rightEdge - leftEdge
    let glyphHeight = bbox.height     // topEdge - bottomEdge
}
```

### Converting to Core Graphics Coordinates

SMuFL uses mathematical coordinates (Y up), but Core Graphics uses screen coordinates (Y down). ``GlyphBoundingBox`` provides a conversion method:

```swift
let staffSpaceInPoints: CGFloat = 10.0  // 1 staff space = 10 points

if let bbox = font.boundingBox(for: .gClef) {
    // Convert to CGRect with Y-flip for Core Graphics
    let cgRect = bbox.cgRect(staffSpaceInPoints: staffSpaceInPoints)

    // Use for hit testing, collision detection, etc.
    if cgRect.contains(touchPoint) {
        // Glyph was tapped
    }
}
```

## Anchor Points

Anchors define precise attachment points for combining glyphs. They're critical for proper stem placement, articulation positioning, and other composite symbols.

### Common Anchor Types

```swift
// Stem attachment for noteheads
AnchorType.stemUpSE    // Bottom-right for upward stems
AnchorType.stemDownNW  // Top-left for downward stems

// Cut-out regions for accidental kerning
AnchorType.cutOutNE
AnchorType.cutOutSE
AnchorType.cutOutSW
AnchorType.cutOutNW

// Grace note slash attachment
AnchorType.graceNoteSlashSW
AnchorType.graceNoteSlashNE

// Special positioning
AnchorType.opticalCenter   // Visual center for dynamics
AnchorType.noteheadOrigin  // Left edge of asymmetric noteheads
```

### Using Anchors

```swift
if let anchors = font.anchors(for: .noteheadBlack) {
    // Get stem attachment point for stem-up note
    if let stemPoint = anchors.point(for: .stemUpSE) {
        // stemPoint.x, stemPoint.y are in staff spaces
        let stemX = noteX + stemPoint.x * staffSpaceInPoints
        let stemY = noteY + stemPoint.y * staffSpaceInPoints
    }

    // Check which anchors are available
    let available = anchors.availableAnchors
    print("Available anchors: \(available)")
}
```

### Stem Positioning Example

```swift
func calculateStemPosition(
    noteheadPosition: CGPoint,
    stemDirection: StemDirection,
    font: LoadedSMuFLFont,
    staffSpaceInPoints: CGFloat
) -> CGPoint? {

    guard let anchors = font.anchors(for: .noteheadBlack) else {
        return nil
    }

    let anchorType: AnchorType = stemDirection == .up ? .stemUpSE : .stemDownNW

    guard let anchor = anchors.staffSpacePoint(for: anchorType) else {
        return nil
    }

    return CGPoint(
        x: noteheadPosition.x + anchor.x * staffSpaceInPoints,
        y: noteheadPosition.y - anchor.y * staffSpaceInPoints  // Y-flip
    )
}
```

## Advance Widths

Advance widths specify how much horizontal space a glyph occupies, used for spacing calculations:

```swift
if let advance = font.advanceWidth(for: .accidentalSharp) {
    // advance is in staff spaces
    let advancePoints = advance * staffSpaceInPoints

    // Position the next element after this advance
    let nextX = accidentalX + advancePoints
}
```

## Engraving Defaults

Engraving defaults provide font-specific recommendations for line thicknesses, spacing, and other layout parameters:

```swift
let defaults = font.engravingDefaults

// Line thicknesses (in staff spaces)
let staffLineThickness = defaults.staffLineThickness     // ~0.13
let stemThickness = defaults.stemThickness               // ~0.12
let beamThickness = defaults.beamThickness               // ~0.5
let beamSpacing = defaults.beamSpacing                   // ~0.25

// Leger lines
let legerThickness = defaults.legerLineThickness         // ~0.16
let legerExtension = defaults.legerLineExtension         // ~0.4

// Slurs and ties
let slurEndpoint = defaults.slurEndpointThickness        // ~0.1
let slurMidpoint = defaults.slurMidpointThickness        // ~0.22

// Barlines
let thinBarline = defaults.thinBarlineThickness          // ~0.16
let thickBarline = defaults.thickBarlineThickness        // ~0.5

// Other elements
let hairpinThickness = defaults.hairpinThickness         // ~0.16
let tupletBracket = defaults.tupletBracketThickness      // ~0.16
```

### Using Engraving Defaults

```swift
func drawStaffLines(
    in context: CGContext,
    at origin: CGPoint,
    width: CGFloat,
    font: LoadedSMuFLFont,
    staffSpaceInPoints: CGFloat
) {
    let thickness = font.engravingDefaults.staffLineThickness * staffSpaceInPoints

    context.setLineWidth(thickness)
    context.setStrokeColor(CGColor(gray: 0, alpha: 1))

    for line in 0..<5 {
        let y = origin.y + CGFloat(line) * staffSpaceInPoints
        context.move(to: CGPoint(x: origin.x, y: y))
        context.addLine(to: CGPoint(x: origin.x + width, y: y))
    }

    context.strokePath()
}
```

## Staff Spaces Unit System

All SMuFL metadata uses staff spaces as the unit of measurement:

- **1 staff space** = distance between two adjacent staff lines
- **4 staff spaces** = height of a 5-line staff
- **1 em** (font size) = 4 staff spaces in SMuFL fonts

To convert staff spaces to points:

```swift
let staffHeight: CGFloat = 40  // points
let staffSpaceInPoints = staffHeight / 4  // 10 points per staff space

// Convert a value from staff spaces to points
func toPoints(_ staffSpaces: StaffSpaces) -> CGFloat {
    return staffSpaces * staffSpaceInPoints
}

// Example: beam thickness
let beamThicknessPoints = toPoints(font.engravingDefaults.beamThickness)
// ~0.5 * 10 = 5 points
```

## Optional Glyphs

Some fonts include optional glyphs beyond the required SMuFL set:

```swift
if let optionals = font.metadata?.optionalGlyphs {
    for (name, glyph) in optionals {
        print("Optional glyph: \(name)")
        print("  Code point: \(glyph.codepoint)")
        print("  Classes: \(glyph.classes ?? [])")
    }
}
```

## Stylistic Sets

Fonts may provide stylistic sets for alternate glyph appearances:

```swift
if let sets = font.metadata?.sets {
    for (setName, set) in sets {
        print("Stylistic set: \(setName)")
        print("  Description: \(set.description ?? "none")")
        print("  Glyphs: \(set.glyphs.count)")
    }
}
```

## Handling Missing Metadata

Not all fonts provide complete metadata. Always handle optional values:

```swift
func getStemAttachment(
    for notehead: SMuFLGlyphName,
    direction: StemDirection,
    font: LoadedSMuFLFont
) -> CGPoint {

    // Try to get anchor from metadata
    if let anchors = font.anchors(for: notehead) {
        let anchorType: AnchorType = direction == .up ? .stemUpSE : .stemDownNW
        if let point = anchors.point(for: anchorType) {
            return point
        }
    }

    // Fall back to bounding box
    if let bbox = font.boundingBox(for: notehead) {
        switch direction {
        case .up:
            return CGPoint(x: bbox.northEastX, y: 0)
        case .down:
            return CGPoint(x: bbox.southWestX, y: 0)
        }
    }

    // Ultimate fallback: assume standard notehead dimensions
    return direction == .up
        ? CGPoint(x: 1.18, y: 0)
        : CGPoint(x: 0, y: 0)
}
```

## See Also

- ``GlyphBoundingBox``
- ``GlyphAnchors``
- ``AnchorType``
- ``EngravingDefaults``
- ``SMuFLFontMetadata``
- <doc:LoadingFonts>
- <doc:GlyphMapping>
