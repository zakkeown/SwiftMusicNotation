# ``SwiftMusicNotation``

A Swift library for professional music notation rendering using SMuFL-compliant fonts.

@Metadata {
    @DisplayName("SwiftMusicNotation")
}

## Overview

SwiftMusicNotation provides a complete solution for working with music notation in Swift applications. Import MusicXML files, compute professional-quality layouts, render notation with Core Graphics, and add MIDI playback.

The library is organized into focused modules that can be used together or independently:

- **MusicNotationCore**: Domain models for representing musical scores
- **SMuFLKit**: SMuFL font loading and glyph management
- **MusicXMLImport**: Parse MusicXML files into Score objects
- **MusicXMLExport**: Generate MusicXML from Score objects
- **MusicNotationLayout**: Compute positions for notation elements
- **MusicNotationRenderer**: Render scores with Core Graphics
- **MusicNotationPlayback**: MIDI playback with AVFoundation

### Quick Example

```swift
import SwiftMusicNotation

// Load a MusicXML file
let importer = MusicXMLImporter()
let score = try importer.importScore(from: musicXMLURL)

// Compute layout
let layoutEngine = LayoutEngine()
let context = LayoutContext.letterSize(staffHeight: 40)
let engravedScore = layoutEngine.layout(score: score, context: context)

// Display in SwiftUI
ScoreViewRepresentable(
    score: $score,
    layoutContext: context
)
```

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Installation>
- <doc:QuickStart>

### Guides

- <doc:ErrorHandling>

### Architecture

- <doc:ArchitectureOverview>
- <doc:DataFlow>
- <doc:ModuleDesign>
- <doc:SMuFLIntegration>

### Key Entry Points

Use `MusicXMLImporter` to load MusicXML files, `LayoutEngine` with `LayoutContext` to compute layout, and `ScoreViewRepresentable` to display scores in SwiftUI.
