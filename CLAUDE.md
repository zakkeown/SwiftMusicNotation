# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

SwiftMusicNotation is a Swift library for music notation rendering using SMuFL-compliant fonts. It provides MusicXML import/export, layout computation, Core Graphics rendering, and MIDI playback capabilities.

## Build Commands

```bash
# Build the package
swift build

# Run all tests
swift test

# Run tests for a specific module
swift test --filter MusicNotationCoreTests
swift test --filter SMuFLKitTests
swift test --filter MusicXMLImportTests
swift test --filter MusicXMLExportTests
swift test --filter MusicNotationLayoutTests
swift test --filter MusicNotationPlaybackTests
swift test --filter MusicXMLValidationTests

# Run a single test
swift test --filter MusicXMLImportTests.testImportSimpleScale
```

## Architecture

The library is organized as a multi-module Swift Package with the following modules:

### Core Modules

- **MusicNotationCore**: Domain models for music notation (Score, Part, Measure, Note, Pitch, Duration, etc.). Depends on SMuFLKit for glyph mappings.

- **SMuFLKit**: SMuFL font integration. Handles font loading via `SMuFLFontManager`, glyph name mappings (`SMuFLGlyphName`), and font metadata (bounding boxes, anchors, engraving defaults). Bundled fonts/metadata are in `Sources/SMuFLKit/Resources/`.

### Import/Export

- **MusicXMLImport**: Parses MusicXML files (both `.musicxml` and compressed `.mxl`). Entry point is `MusicXMLImporter`. Uses `FormatDetector` for format detection, `NoteMapper` and `AttributesMapper` for element mapping, and trackers (`SlurTracker`, `TieTracker`, `BeamGrouper`, `TupletParser`) for cross-element relationships.

- **MusicXMLExport**: Generates MusicXML from `Score` objects. Entry point is `MusicXMLExporter`.

### Layout and Rendering

- **MusicNotationLayout**: Computes positions for all notation elements. `LayoutEngine` is the main entry point, producing `EngravedScore` containing `EngravedPage`, `EngravedSystem`, `EngravedMeasure`, etc. Uses separate engines for horizontal spacing, vertical spacing, page breaks, and system breaks.

- **MusicNotationRenderer**: Core Graphics rendering. `MusicRenderer` renders `EngravedScore` to a `CGContext`. Individual renderers handle specific elements (notes, beams, curves, text). Platform views in `Platform/` provide UIKit (`ScoreView+iOS`), AppKit (`ScoreView+macOS`), and SwiftUI (`ScoreViewRepresentable`) integration.

### Playback

- **MusicNotationPlayback**: MIDI playback via AVFoundation. `PlaybackEngine` coordinates `ScoreSequencer` (converts score to timed events), `MIDISynthesizer` (audio output), and `PlaybackCursor` (position tracking). Async API with Combine publishers for state changes.

### Umbrella Module

- **SwiftMusicNotation**: Re-exports all modules via `@_exported import`. Import this for full library access.

## Key Patterns

### Data Flow
MusicXML -> `MusicXMLImporter` -> `Score` -> `LayoutEngine` -> `EngravedScore` -> `MusicRenderer` -> CGContext

### Score Model Hierarchy
`Score` contains `Part[]`, each Part contains `Measure[]`, each Measure contains `MeasureElement[]` (notes, rests, attributes, directions, barlines).

### SMuFL Font Integration
SMuFL fonts use Unicode PUA (Private Use Area). Load fonts via `SMuFLFontManager.shared.loadFont(named:from:)`. Glyph names are defined in `SMuFLGlyphName` enum. Font metadata provides glyph metrics needed for precise layout.

### Test Resources
Test MusicXML files go in `Tests/MusicXMLImportTests/Resources/` and `Tests/MusicXMLValidationTests/Resources/`. Access via `Bundle.module` in tests.

## Platform Support

- macOS 13+
- iOS 16+
