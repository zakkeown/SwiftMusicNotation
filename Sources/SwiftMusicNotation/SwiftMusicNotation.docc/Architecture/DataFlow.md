# Data Flow

Follow how data moves through SwiftMusicNotation from file to screen.

@Metadata {
    @PageKind(article)
}

## Overview

SwiftMusicNotation processes music notation through a pipeline with distinct stages. Understanding this flow helps you work effectively with the library.

## The Pipeline

```
┌─────────────┐    ┌──────────────────┐    ┌───────────┐
│  MusicXML   │───▶│ MusicXMLImporter │───▶│   Score   │
│    File     │    │                  │    │           │
└─────────────┘    └──────────────────┘    └─────┬─────┘
                                                 │
                   ┌─────────────────────────────┼─────────────────────────────┐
                   │                             │                             │
                   ▼                             ▼                             ▼
           ┌──────────────┐              ┌──────────────┐              ┌──────────────┐
           │ LayoutEngine │              │PlaybackEngine│              │MusicXMLExport│
           │              │              │              │              │              │
           └──────┬───────┘              └──────────────┘              └──────────────┘
                  │
                  ▼
           ┌──────────────┐
           │ EngravedScore│
           │              │
           └──────┬───────┘
                  │
                  ▼
           ┌──────────────┐
           │MusicRenderer │───▶ CGContext / Screen
           │              │
           └──────────────┘
```

## Stage 1: Import

**Input**: MusicXML file (`.musicxml`, `.mxl`, or `.xml`)
**Output**: `Score` object

```swift
let importer = MusicXMLImporter()
let score = try importer.importScore(from: url)
```

The importer:
1. Detects file format (partwise, timewise, compressed)
2. Extracts XML from compressed archives if needed
3. Parses XML into domain model objects
4. Handles cross-element relationships (ties, slurs, beams)
5. Collects warnings for non-fatal issues

### Score Structure

The `Score` contains:

```
Score
├── metadata: ScoreMetadata
│   ├── workTitle, movementTitle
│   ├── creators (composer, arranger, etc.)
│   └── encoding info
├── defaults: ScoreDefaults
│   ├── scaling (tenths to millimeters)
│   └── page settings
├── credits: [Credit]
│   └── title, copyright text
└── parts: [Part]
    ├── id, name
    ├── instruments
    └── measures: [Measure]
        ├── number, attributes
        └── elements: [MeasureElement]
```

## Stage 2: Layout

**Input**: `Score` + `LayoutContext`
**Output**: `EngravedScore`

```swift
let engine = LayoutEngine()
let context = LayoutContext.letterSize(staffHeight: 40)
let engravedScore = engine.layout(score: score, context: context)
```

The layout engine:
1. Computes horizontal spacing for each measure
2. Determines system breaks (which measures fit on each line)
3. Computes page breaks
4. Positions staves vertically
5. Places all notation elements

### Engraved Structure

```
EngravedScore
├── score: Score (reference to source)
├── scaling: ScalingContext
└── pages: [EngravedPage]
    ├── pageNumber
    ├── frame: CGRect
    ├── credits: [EngravedCredit]
    └── systems: [EngravedSystem]
        ├── frame: CGRect
        ├── measureRange
        ├── staves: [EngravedStaff]
        │   ├── partIndex, staffNumber
        │   ├── frame, centerLineY
        │   └── staffHeight
        └── measures: [EngravedMeasure]
            ├── measureNumber
            ├── frame
            └── elementsByStaff
```

## Stage 3: Render

**Input**: `EngravedScore`
**Output**: Pixels on screen (via `CGContext`)

```swift
// Via SwiftUI
ScoreViewRepresentable(score: $score, layoutContext: context)

// Or direct rendering
let renderer = MusicRenderer()
renderer.render(score: engravedScore, pageIndex: 0, in: cgContext)
```

The renderer:
1. Draws staff lines
2. Renders clefs, key signatures, time signatures
3. Draws noteheads, stems, beams
4. Renders accidentals, articulations, dynamics
5. Draws barlines
6. Renders text (titles, credits, lyrics)

## Parallel Path: Playback

Playback runs independently from the visual pipeline:

**Input**: `Score`
**Output**: Audio via AVFoundation

```swift
let engine = PlaybackEngine()
try await engine.load(score)
try engine.play()
```

The playback engine:
1. Sequences the score into timed MIDI events
2. Interprets dynamics as velocity
3. Maps instruments to General MIDI
4. Synthesizes audio with AVAudioEngine
5. Tracks position for cursor display

## Parallel Path: Export

Export also works directly from the Score:

**Input**: `Score`
**Output**: MusicXML file

```swift
let exporter = MusicXMLExporter()
try exporter.export(score, to: outputURL)
```

## Connecting Playback to Display

Synchronize playback position with the visual display:

```swift
engine.events.sink { event in
    switch event {
    case .positionChanged(let measure, let beat):
        // Scroll to current measure
        scoreView.scrollToMeasure(measure, in: 0)

        // Or highlight current beat
        highlightPosition(measure: measure, beat: beat)

    default:
        break
    }
}
```

## See Also

- <doc:ArchitectureOverview>
- <doc:QuickStart>
