# Architecture Overview

Understand how SwiftMusicNotation's modules work together.

@Metadata {
    @PageKind(article)
}

## Overview

SwiftMusicNotation follows a modular architecture with clear separation of concerns. Each module has a specific responsibility and well-defined dependencies.

## Module Dependency Graph

```
SMuFLKit (no dependencies)
    │
    ▼
MusicNotationCore
    │
    ├──────────────────┬──────────────────┬──────────────┐
    ▼                  ▼                  ▼              ▼
MusicXMLImport    MusicXMLExport    MusicNotationLayout  MusicNotationPlayback
                                          │
                                          ▼
                                   MusicNotationRenderer
                                          │
                                          ▼
                                   SwiftMusicNotation (umbrella)
```

### Module Responsibilities

| Module | Responsibility |
|--------|----------------|
| **SMuFLKit** | Load SMuFL fonts, provide glyph names and metadata |
| **MusicNotationCore** | Define domain models for music notation |
| **MusicXMLImport** | Parse MusicXML files into Score objects |
| **MusicXMLExport** | Serialize Score objects to MusicXML |
| **MusicNotationLayout** | Compute positions for all elements |
| **MusicNotationRenderer** | Draw notation and provide views |
| **MusicNotationPlayback** | Convert scores to MIDI and synthesize audio |
| **SwiftMusicNotation** | Re-export all modules for convenience |

## Design Principles

### Separation of Concerns

Each module handles one aspect of the problem:

- **Data representation** is separate from **file I/O**
- **Layout computation** is separate from **rendering**
- **Playback** is independent of **visual display**

This allows you to use only the parts you need. For example, a command-line tool might use only `MusicXMLImport` and `MusicNotationCore` without any rendering.

### Protocol-Oriented Design

Key protocols enable extensibility:

- **`GlyphRepresentable`**: Types that map to SMuFL glyphs
- **`ScoreViewProtocol`**: Platform-agnostic view interface
- **`ScoreSelectionDelegate`**: Handle selection events

### Value Types for Primitives

Musical primitives are value types for thread safety and simplicity:

```swift
// Value types - can be freely copied
let pitch = Pitch(step: .c, octave: 4)
let duration = Duration(base: .quarter, dots: 1)
let accidental = Accidental.sharp
```

### Reference Types for Containers

Container types are reference types for identity and performance:

```swift
// Reference types - shared identity
let score = Score(...)
let part = Part(...)
let measure = Measure(...)
```

### Sendable Conformance

Most types conform to `Sendable` for safe concurrent use:

```swift
// Safe to pass across actor boundaries
let score: Score  // Sendable
let config: LayoutConfiguration  // Sendable
```

## Extension Points

### Custom Rendering

Implement custom rendering by working with `EngravedScore`:

```swift
let engravedScore = layoutEngine.layout(score: score, context: context)

for page in engravedScore.pages {
    for system in page.systems {
        // Custom drawing logic
    }
}
```

### Custom Layout

Modify layout behavior through configuration:

```swift
var config = LayoutConfiguration()
config.spacingConfig.minimumNoteSpace = 15
config.verticalConfig.staffDistance = 80

let engine = LayoutEngine(config: config)
```

### Custom Playback

Access the sequencer for custom MIDI handling:

```swift
let sequencer = ScoreSequencer()
let events = sequencer.sequence(score)

// Process MIDI events yourself
for event in events {
    // Custom handling
}
```

## See Also

- <doc:DataFlow>
- <doc:ModuleDesign>
- <doc:SMuFLIntegration>
