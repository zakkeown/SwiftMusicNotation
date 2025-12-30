# Custom Rendering

Implement custom rendering logic for specialized notation needs.

@Metadata {
    @PageKind(article)
}

## Overview

While ``MusicRenderer`` handles standard notation rendering, you may need custom rendering for specialized requirements like color-coding, highlighting, analysis overlays, or non-standard notation. This guide shows how to work with the rendering components directly.

## Working with EngravedScore

The ``EngravedScore`` from layout contains all positioned elements ready for rendering. You can iterate through its hierarchy for custom processing:

```swift
let engravedScore = layoutEngine.layout(score: score, context: context)

for page in engravedScore.pages {
    for system in page.systems {
        for staff in system.staves {
            // Custom staff rendering
        }

        for measure in system.measures {
            for element in measure.elements {
                // Custom element rendering
            }
        }
    }
}
```

## Using Component Renderers

The rendering module provides specialized renderers for different element types:

### NoteRenderer

Renders noteheads, stems, flags, accidentals, and dots:

```swift
let glyphRenderer = GlyphRenderer(fontManager: fontManager, scaling: scaling)
let noteRenderer = NoteRenderer(glyphRenderer: glyphRenderer)

let noteInfo = NoteRenderInfo(
    position: notePosition,
    staffPosition: 0,
    noteheadGlyph: .noteheadBlack,
    stem: StemRenderInfo(start: stemStart, end: stemEnd, direction: .up, thickness: 1.2),
    dots: [dotPosition]
)

noteRenderer.renderNote(noteInfo, color: CGColor.black, in: context)
```

### BeamRenderer

Renders beams connecting groups of notes:

```swift
let beamRenderer = BeamRenderer()

let beamInfo = BeamGroupRenderInfo(
    primaryBeamStart: firstStemEnd,
    primaryBeamEnd: lastStemEnd,
    beamThickness: 5.0,
    stemDirection: .up,
    secondaryBeams: [] // For 16th notes and smaller
)

beamRenderer.renderBeamGroup(beamInfo, color: CGColor.black, in: context)
```

### CurveRenderer

Renders slurs and ties:

```swift
let curveRenderer = CurveRenderer()

// Render a tie (uniform thickness)
curveRenderer.renderTie(
    from: tieStart,
    to: tieEnd,
    direction: .above,
    color: CGColor.black,
    in: context
)

// Render a slur (variable thickness)
curveRenderer.renderSlur(
    from: slurStart,
    to: slurEnd,
    direction: .above,
    color: CGColor.black,
    in: context
)
```

### StaffRenderer

Renders staff lines, ledger lines, and barlines:

```swift
let staffRenderer = StaffRenderer()

staffRenderer.renderStaffLines(
    at: staffOrigin,
    width: staffWidth,
    lineSpacing: staffSpacing,
    lineThickness: 0.13,
    color: CGColor.black,
    in: context
)
```

### GlyphRenderer

Renders SMuFL glyphs directly:

```swift
let glyphRenderer = GlyphRenderer(fontManager: fontManager, scaling: scaling)

// Render any SMuFL glyph
glyphRenderer.renderGlyph(.gClef, at: clefPosition, color: CGColor.black, in: context)
glyphRenderer.renderGlyph(.dynamicForte, at: dynamicPosition, color: CGColor.black, in: context)
```

## Custom Color-Coding

A common use case is color-coding notes based on analysis or teaching purposes:

```swift
func colorForNote(_ note: Note) -> CGColor {
    switch note.pitch?.step {
    case .c: return CGColor(red: 1, green: 0, blue: 0, alpha: 1)      // Red
    case .d: return CGColor(red: 1, green: 0.5, blue: 0, alpha: 1)    // Orange
    case .e: return CGColor(red: 1, green: 1, blue: 0, alpha: 1)      // Yellow
    case .f: return CGColor(red: 0, green: 0.8, blue: 0, alpha: 1)    // Green
    case .g: return CGColor(red: 0, green: 0.5, blue: 1, alpha: 1)    // Blue
    case .a: return CGColor(red: 0.5, green: 0, blue: 1, alpha: 1)    // Indigo
    case .b: return CGColor(red: 0.8, blue: 0, green: 0.8, alpha: 1)  // Violet
    default: return CGColor.black
    }
}

// In rendering loop:
for element in measure.elements {
    if case .note(let noteInfo) = element.type {
        let color = colorForNote(noteInfo.note)
        noteRenderer.renderNote(noteInfo, color: color, in: context)
    }
}
```

## Rendering Overlays

Add overlays for analysis, selection highlighting, or annotations:

```swift
// Highlight a measure
func highlightMeasure(_ measure: EngravedMeasure, in context: CGContext) {
    context.saveGState()
    context.setFillColor(CGColor(red: 1, green: 1, blue: 0, alpha: 0.2))
    context.fill(measure.bounds)
    context.restoreGState()
}

// Draw selection rectangle
func drawSelection(around element: EngravedElement, in context: CGContext) {
    context.saveGState()
    context.setStrokeColor(CGColor(red: 0, green: 0.5, blue: 1, alpha: 1))
    context.setLineWidth(2)
    context.stroke(element.bounds.insetBy(dx: -2, dy: -2))
    context.restoreGState()
}
```

## Direct Core Graphics

For complete control, use Core Graphics directly with position data from EngravedScore:

```swift
context.saveGState()

// Custom path drawing
let path = CGMutablePath()
path.move(to: startPoint)
path.addCurve(to: endPoint, control1: control1, control2: control2)
context.addPath(path)
context.setStrokeColor(customColor)
context.setLineWidth(2)
context.strokePath()

// Custom text
let attributes: [NSAttributedString.Key: Any] = [
    .font: customFont,
    .foregroundColor: NSColor.black
]
let text = NSAttributedString(string: "Allegro", attributes: attributes)
text.draw(at: textPosition)

context.restoreGState()
```

## Performance Considerations

When implementing custom rendering:

1. **Batch similar operations**: Group glyph rendering by font/color to minimize state changes
2. **Use clipping**: Set clip rects to avoid rendering off-screen content
3. **Cache paths**: Reuse CGPath objects for repeated shapes
4. **Layer rendering**: Use render layers for complex overlays that don't change often

## See Also

- ``MusicRenderer``
- ``NoteRenderer``
- ``BeamRenderer``
- ``CurveRenderer``
- ``StaffRenderer``
- ``GlyphRenderer``
