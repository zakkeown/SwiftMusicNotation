# Rendering to Context

Draw music notation directly to Core Graphics contexts.

@Metadata {
    @PageKind(article)
}

## Overview

``MusicRenderer`` provides low-level rendering of engraved scores to Core Graphics contexts. This is useful for PDF generation, custom view implementations, image export, and other scenarios where you need direct control over the rendering output.

## Basic Rendering

Render a score page to any `CGContext`:

```swift
import MusicNotationRenderer
import MusicNotationLayout

// Compute the layout
let layoutEngine = LayoutEngine()
let layoutContext = LayoutContext.letterSize(staffHeight: 40)
let engravedScore = layoutEngine.layout(score: score, context: layoutContext)

// Set up the renderer
let renderer = MusicRenderer()
renderer.font = try SMuFLFontManager.shared.loadFont(named: "Bravura")

// Render page 0
renderer.render(score: engravedScore, pageIndex: 0, in: cgContext)
```

## Configuring Appearance

Use ``RenderConfiguration`` to customize colors and line thicknesses:

```swift
var config = RenderConfiguration()

// Colors
config.backgroundColor = CGColor(gray: 1, alpha: 1)  // White
config.staffLineColor = CGColor(gray: 0, alpha: 1)   // Black
config.barlineColor = CGColor(gray: 0, alpha: 1)     // Black
config.noteColor = CGColor(gray: 0, alpha: 1)        // Black

// Line thicknesses (in points)
config.staffLineThickness = 0.8
config.thinBarlineThickness = 0.8
config.thickBarlineThickness = 3.0
config.stemThickness = 0.8
config.bracketThickness = 2.0

let renderer = MusicRenderer(config: config)
```

### Dark Mode Support

Create a configuration for dark mode interfaces:

```swift
var darkConfig = RenderConfiguration()
darkConfig.backgroundColor = CGColor(gray: 0.1, alpha: 1)
darkConfig.staffLineColor = CGColor(gray: 0.9, alpha: 1)
darkConfig.barlineColor = CGColor(gray: 0.9, alpha: 1)
darkConfig.noteColor = CGColor(gray: 0.95, alpha: 1)
```

### Transparent Background

For compositing over other content:

```swift
var config = RenderConfiguration()
config.backgroundColor = nil  // Transparent
```

## PDF Generation

Create multi-page PDFs:

```swift
func exportToPDF(engravedScore: EngravedScore, to url: URL) throws {
    let pageSize = engravedScore.pages.first?.frame.size ?? CGSize(width: 612, height: 792)

    var mediaBox = CGRect(origin: .zero, size: pageSize)

    guard let pdfContext = CGContext(url as CFURL, mediaBox: &mediaBox, nil) else {
        throw ExportError.contextCreationFailed
    }

    let renderer = MusicRenderer()
    renderer.font = SMuFLFontManager.shared.currentFont

    for pageIndex in 0..<engravedScore.pages.count {
        pdfContext.beginPage(mediaBox: &mediaBox)

        // Flip coordinate system for PDF
        pdfContext.translateBy(x: 0, y: pageSize.height)
        pdfContext.scaleBy(x: 1, y: -1)

        renderer.render(score: engravedScore, pageIndex: pageIndex, in: pdfContext)

        pdfContext.endPage()
    }

    pdfContext.closePDF()
}
```

## Image Export

Render to a bitmap image:

```swift
func renderToImage(engravedScore: EngravedScore, pageIndex: Int, scale: CGFloat = 2.0) -> CGImage? {
    let page = engravedScore.pages[pageIndex]
    let size = page.frame.size

    let width = Int(size.width * scale)
    let height = Int(size.height * scale)

    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
          let context = CGContext(
              data: nil,
              width: width,
              height: height,
              bitsPerComponent: 8,
              bytesPerRow: 0,
              space: colorSpace,
              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
          ) else {
        return nil
    }

    // Scale for retina
    context.scaleBy(x: scale, y: scale)

    // Flip for correct orientation
    context.translateBy(x: 0, y: size.height)
    context.scaleBy(x: 1, y: -1)

    let renderer = MusicRenderer()
    renderer.font = SMuFLFontManager.shared.currentFont
    renderer.render(score: engravedScore, pageIndex: pageIndex, in: context)

    return context.makeImage()
}
```

## Render Context

For advanced rendering scenarios, create a ``RenderContext`` directly:

```swift
let renderContext = RenderContext(
    font: loadedFont,
    scaling: engravedScore.scaling,
    config: RenderConfiguration(),
    visibleRect: viewBounds  // For visibility culling
)

// Access scaling information
let staffSpace = renderContext.staffSpace  // Points per staff space
```

### Visibility Culling

The `visibleRect` enables optimization by skipping off-screen elements:

```swift
// Only render visible portions
let renderContext = RenderContext(
    font: font,
    scaling: scaling,
    config: config,
    visibleRect: scrollView.visibleRect
)

// Elements outside visibleRect may be skipped
renderer.renderPage(page, in: context, renderContext: renderContext)
```

## Font Requirements

Rendering requires a loaded SMuFL font:

```swift
// Load the font
let font = try SMuFLFontManager.shared.loadFont(named: "Bravura")

// Assign to renderer
renderer.font = font

// Or use the current font
renderer.font = SMuFLFontManager.shared.currentFont
```

If no font is set, glyph rendering is skipped but structural elements (staff lines, barlines) are still drawn.

## Custom View Integration

Integrate rendering with custom NSView or UIView subclasses:

```swift
#if os(macOS)
class CustomScoreView: NSView {
    var engravedScore: EngravedScore?
    var renderer = MusicRenderer()

    override func draw(_ dirtyRect: NSRect) {
        guard let context = NSGraphicsContext.current?.cgContext,
              let score = engravedScore else { return }

        renderer.render(score: score, pageIndex: 0, in: context)
    }
}
#endif
```

## Thread Safety

``MusicRenderer`` is not thread-safe. For concurrent rendering:

```swift
// Safe: separate renderers per thread
DispatchQueue.concurrentPerform(iterations: pageCount) { pageIndex in
    let renderer = MusicRenderer()  // New instance
    renderer.font = loadedFont
    renderer.render(score: engravedScore, pageIndex: pageIndex, in: contexts[pageIndex])
}
```

## See Also

- ``MusicRenderer``
- ``RenderConfiguration``
- ``RenderContext``
- ``EngravedScore``
- <doc:PlatformViews>
