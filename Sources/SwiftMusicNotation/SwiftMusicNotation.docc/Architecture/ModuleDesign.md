# Module Design

A deep dive into each module's responsibilities, key types, and extension points.

@Metadata {
    @PageKind(article)
}

## Overview

SwiftMusicNotation consists of eight focused modules. This article describes each module's purpose, its key types, and how to extend or customize its behavior.

## SMuFLKit

**Purpose**: Load SMuFL-compliant fonts and provide glyph metadata for music notation rendering.

SMuFLKit is the foundation layer with no dependencies on other modules. It handles everything related to the SMuFL (Standard Music Font Layout) specification.

### Key Types

| Type | Description |
|------|-------------|
| `SMuFLFontManager` | Singleton that loads and caches fonts |
| `LoadedSMuFLFont` | A loaded font with its metadata |
| `SMuFLGlyphName` | Enum of all standard SMuFL glyph names |
| `SMuFLFontMetadata` | Bounding boxes and anchors for glyphs |
| `EngravingDefaults` | Staff line widths, stem lengths, etc. |

### Architecture

```
SMuFLFontManager (singleton)
    │
    ├── loadFont(named:from:) → LoadedSMuFLFont
    │   ├── CTFont (Core Text font)
    │   ├── SMuFLFontMetadata
    │   │   ├── glyphBoundingBoxes
    │   │   └── glyphAnchors
    │   └── EngravingDefaults
    │
    └── Font cache (thread-safe)
```

### Extension Points

- **Custom Fonts**: Load any SMuFL-compliant font by providing a URL to the font file and metadata JSON
- **Glyph Lookup**: Access glyph code points via `LoadedSMuFLFont.codePoint(for:)`

### See Also

- <doc:SMuFLIntegration>

---

## MusicNotationCore

**Purpose**: Define domain models that represent music notation semantically.

This module provides the data structures that represent musical scores, completely independent of how they're displayed or played.

### Key Types

**Score Hierarchy**:

| Type | Description |
|------|-------------|
| `Score` | Root container with metadata, parts, and credits |
| `Part` | A single instrument or voice with measures |
| `Measure` | A bar containing notes, rests, and other elements |
| `MeasureElement` | Protocol for all elements in a measure |

**Primitives**:

| Type | Description |
|------|-------------|
| `Pitch` | Step (A-G), octave, and optional alteration |
| `Duration` | Base rhythmic value with dots and tuplet info |
| `Accidental` | Sharp, flat, natural, double-sharp, etc. |
| `Rational` | Exact fractional values for timing |

**Elements**:

| Type | Description |
|------|-------------|
| `Note` | A pitched or unpitched note with duration |
| `Chord` | Multiple simultaneous notes |
| `Rest` | A rhythmic rest |

**Spanners** (multi-element relationships):

| Type | Description |
|------|-------------|
| `Tie` | Connects notes of the same pitch |
| `Slur` | Phrasing arc across notes |
| `Beam` | Groups notes together visually |
| `Tuplet` | Non-standard rhythmic groupings |

**Attributes**:

| Type | Description |
|------|-------------|
| `MeasureAttributes` | Clef, key, time signature changes |
| `Clef` | G, F, C, percussion clefs |
| `KeySignature` | Key definition (fifths or explicit) |
| `TimeSignature` | Beats and beat type |

**Notations**:

| Type | Description |
|------|-------------|
| `Dynamic` | pp, p, mp, mf, f, ff, etc. |
| `Articulation` | Staccato, accent, tenuto, etc. |
| `Direction` | Tempo, rehearsal marks, text |

### Architecture

```
Score
├── metadata: ScoreMetadata
├── defaults: ScoreDefaults
├── credits: [Credit]
└── parts: [Part]
    ├── id, name
    ├── instruments: [Instrument]
    └── measures: [Measure]
        ├── number
        ├── attributes: MeasureAttributes?
        └── elements: [MeasureElement]
            ├── Note (with Pitch, Duration, notations)
            ├── Rest
            ├── Chord
            ├── Direction
            └── Barline
```

### Extension Points

- **GlyphRepresentable Protocol**: Types that map to SMuFL glyphs implement this protocol
- **Custom Elements**: Implement `MeasureElement` to add new element types

---

## MusicXMLImport

**Purpose**: Parse MusicXML files into `Score` objects.

Handles both partwise and timewise MusicXML formats, as well as compressed `.mxl` archives.

### Key Types

| Type | Description |
|------|-------------|
| `MusicXMLImporter` | Main entry point for importing |
| `MusicXMLImportError` | Detailed error information |
| `MusicXMLWarning` | Non-fatal import issues |
| `ImportOptions` | Configuration for import behavior |

**Internal Components**:

| Type | Description |
|------|-------------|
| `FormatDetector` | Identifies MusicXML variants |
| `MXLContainerReader` | Extracts XML from compressed archives |
| `NoteMapper` | Converts XML note elements |
| `AttributesMapper` | Converts clef/key/time changes |
| `DirectionMapper` | Converts dynamics, tempo, text |

**Trackers** (cross-element relationships):

| Type | Description |
|------|-------------|
| `TieTracker` | Links tied notes together |
| `SlurTracker` | Connects slur start/stop pairs |
| `BeamGrouper` | Groups beamed notes |
| `TupletParser` | Parses tuplet groupings |

### Architecture

```
MusicXMLImporter
├── importScore(from: URL) → Score
├── importScore(from: Data) → Score
│
├── FormatDetector
│   └── detect compressed vs. plain XML
│
├── MXLContainerReader
│   └── extract XML from .mxl ZIP archives
│
├── XMLParserContext
│   ├── NoteMapper
│   ├── AttributesMapper
│   ├── DirectionMapper
│   │
│   └── Cross-Element Trackers
│       ├── TieTracker
│       ├── SlurTracker
│       ├── BeamGrouper
│       └── TupletParser
│
└── OriginalXMLContext (for round-trip preservation)
```

### Extension Points

- **Import Options**: Configure how unknown elements are handled
- **Warning Collection**: Access non-fatal warnings after import

---

## MusicXMLExport

**Purpose**: Serialize `Score` objects back to MusicXML format.

Generates well-formed MusicXML that can be opened in other notation software.

### Key Types

| Type | Description |
|------|-------------|
| `MusicXMLExporter` | Main entry point for exporting |
| `ExportConfiguration` | Options for output format |
| `XMLBuilder` | Constructs XML element tree |

### Architecture

```
MusicXMLExporter
├── export(_:to:) → writes to URL
├── export(_:) → returns Data
│
├── ExportConfiguration
│   ├── version (4.0, 3.1, etc.)
│   ├── format (partwise vs. timewise)
│   └── indentation options
│
└── XMLBuilder
    └── Constructs XML from Score
```

### Extension Points

- **Export Configuration**: Control MusicXML version and formatting
- **Round-Trip Preservation**: Original XML context is preserved when possible

---

## MusicNotationLayout

**Purpose**: Compute precise positions for all notation elements.

Transforms a semantic `Score` into an `EngravedScore` with exact coordinates for rendering.

### Key Types

**Engine**:

| Type | Description |
|------|-------------|
| `LayoutEngine` | Orchestrates the layout pipeline |
| `LayoutContext` | Page size, margins, staff height |
| `LayoutConfiguration` | Detailed spacing parameters |

**Output Models**:

| Type | Description |
|------|-------------|
| `EngravedScore` | Complete laid-out score |
| `EngravedPage` | A single page with systems |
| `EngravedSystem` | A line of music with staves |
| `EngravedStaff` | A five-line staff |
| `EngravedMeasure` | A measure with positioned elements |
| `EngravedElement` | Any positioned notation element |

**Internal Engines**:

| Type | Description |
|------|-------------|
| `HorizontalSpacing` | Note-to-note horizontal spacing |
| `VerticalSpacing` | Staff and system vertical layout |
| `BreakingEngine` | System and page break decisions |
| `CollisionDetector` | Prevents overlapping elements |
| `OrchestralLayout` | Handles large ensemble scores |

**Units**:

| Type | Description |
|------|-------------|
| `StaffSpaces` | Unit relative to staff line distance |
| `Tenths` | MusicXML's tenths-of-a-staff-space |
| `ScalingContext` | Converts between unit systems |

### Architecture

```
LayoutEngine
├── layout(score:context:) → EngravedScore
│
├── Phase 1: Horizontal Spacing
│   ├── Calculate ideal note spacing
│   ├── Apply minimum distances
│   └── Stretch/compress to fit
│
├── Phase 2: System Breaking
│   ├── Determine measures per system
│   └── Balance systems across pages
│
├── Phase 3: Page Breaking
│   ├── Determine systems per page
│   └── Distribute vertical space
│
├── Phase 4: Vertical Layout
│   ├── Position staves
│   ├── Handle cross-staff notation
│   └── Place dynamics and text
│
└── Phase 5: Element Positioning
    ├── Position notes, rests, chords
    ├── Calculate beam angles
    └── Route slurs and ties
```

### Extension Points

- **LayoutConfiguration**: Customize spacing, distances, and break behavior
- **Custom Page Sizes**: Create contexts for any page dimensions
- **EngravedScore Traversal**: Walk the output tree for custom rendering

---

## MusicNotationRenderer

**Purpose**: Draw notation using Core Graphics and provide platform views.

Renders `EngravedScore` output to screen or export formats.

### Key Types

**Rendering**:

| Type | Description |
|------|-------------|
| `MusicRenderer` | Main rendering coordinator |
| `RenderContext` | Current drawing state and config |
| `RenderConfiguration` | Colors, fonts, appearance |

**Element Renderers**:

| Type | Description |
|------|-------------|
| `GlyphRenderer` | Draws SMuFL glyphs |
| `StaffRenderer` | Draws staff lines |
| `NoteRenderer` | Draws notes with stems and flags |
| `BeamRenderer` | Draws beams between notes |
| `CurveRenderer` | Draws slurs and ties |
| `TextRenderer` | Draws titles, lyrics, dynamics |

**Platform Views**:

| Type | Description |
|------|-------------|
| `ScoreViewRepresentable` | SwiftUI wrapper |
| `ScoreView` (iOS) | UIView subclass |
| `ScoreView` (macOS) | NSView subclass |
| `ScoreViewProtocol` | Common view interface |

**Interaction**:

| Type | Description |
|------|-------------|
| `HitTester` | Finds elements at touch/click points |
| `SelectableElement` | An element that can be selected |
| `ScoreSelectionDelegate` | Receives selection events |

**Export**:

| Type | Description |
|------|-------------|
| `ExportEngine` | Renders to PDF, PNG, JPEG, SVG |
| `ExportConfiguration` | Scale, format options |

### Architecture

```
MusicRenderer
├── render(score:pageIndex:in:) → draws to CGContext
│
├── Layered Rendering
│   ├── StaffRenderer (staff lines, clefs)
│   ├── NoteRenderer (noteheads, stems, flags)
│   ├── BeamRenderer (beam lines)
│   ├── CurveRenderer (slurs, ties)
│   ├── GlyphRenderer (SMuFL symbols)
│   └── TextRenderer (titles, lyrics)
│
├── Platform Views
│   ├── ScoreView+iOS (UIView)
│   ├── ScoreView+macOS (NSView)
│   └── ScoreViewRepresentable (SwiftUI)
│
└── Export
    └── ExportEngine → PDF/PNG/JPEG/SVG
```

### Extension Points

- **RenderConfiguration**: Customize colors and line widths
- **Custom Views**: Implement `ScoreViewProtocol` for custom platforms
- **Selection Handling**: Implement `ScoreSelectionDelegate` for custom behavior
- **Export Formats**: Access `EngravedScore` for custom export

---

## MusicNotationPlayback

**Purpose**: Convert scores to MIDI and synthesize audio via AVFoundation.

Provides real-time playback with position tracking for visual synchronization.

### Key Types

| Type | Description |
|------|-------------|
| `PlaybackEngine` | Main playback coordinator |
| `PlaybackPosition` | Current playback location |
| `PlaybackEvent` | Position changes, state changes |

**Internal Components**:

| Type | Description |
|------|-------------|
| `ScoreSequencer` | Converts score to timed MIDI events |
| `MIDISynthesizer` | AVAudioEngine-based synthesis |
| `DynamicsInterpreter` | Maps dynamics to MIDI velocity |
| `InstrumentMapper` | Maps instruments to General MIDI |
| `PlaybackCursor` | Tracks current position |

### Architecture

```
PlaybackEngine
├── load(_:) async throws → prepares score
├── play() throws
├── pause()
├── stop()
├── seek(to:)
│
├── ScoreSequencer
│   ├── Walks score structure
│   ├── Calculates absolute times
│   └── Generates MIDI events
│
├── DynamicsInterpreter
│   ├── Tracks dynamic markings
│   └── Outputs velocity values
│
├── InstrumentMapper
│   ├── Maps part instruments
│   └── Selects GM patches
│
├── MIDISynthesizer
│   ├── AVAudioEngine
│   ├── AVAudioUnitSampler
│   └── Built-in General MIDI sounds
│
├── PlaybackCursor
│   ├── Tracks current time
│   └── Maps to measure/beat
│
└── events: AnyPublisher<PlaybackEvent, Never>
    └── Combine publisher for UI updates
```

### Extension Points

- **Tempo Control**: Adjust playback speed
- **Position Tracking**: Subscribe to position events for cursor display
- **Custom Instruments**: Future support for custom SoundFont files

---

## SwiftMusicNotation (Umbrella)

**Purpose**: Convenient re-export of all modules.

Import this single module to access the entire library.

```swift
import SwiftMusicNotation

// All types from all modules are now available
let importer = MusicXMLImporter()
let layoutEngine = LayoutEngine()
let playbackEngine = PlaybackEngine()
```

### When to Use Individual Modules

Import individual modules when you need:

- **Smaller binary size**: Only link what you use
- **Clearer dependencies**: Explicit about what features you need
- **Faster compilation**: Less code to process

```swift
// Just for importing MusicXML
import MusicNotationCore
import MusicXMLImport

// Just for layout without rendering
import MusicNotationCore
import MusicNotationLayout
```

## See Also

- <doc:ArchitectureOverview>
- <doc:DataFlow>
- <doc:SMuFLIntegration>
