# SwiftMusicNotation

A Swift library for professional music notation rendering using SMuFL-compliant fonts.

## Features

- **MusicXML Import/Export** - Full support for MusicXML 4.0, including compressed `.mxl` files
- **SMuFL Fonts** - Bravura and other SMuFL-compliant music fonts with complete glyph support
- **Professional Layout** - Automatic spacing, system breaks, and page layout
- **Multi-Platform** - Native support for macOS 13+, iOS 16+, and visionOS
- **MIDI Playback** - Built-in audio synthesis with tempo and position tracking
- **SwiftUI & UIKit** - Cross-platform views with zoom, pan, and selection

## Quick Start

```swift
import SwiftMusicNotation

// Load a MusicXML file
let importer = MusicXMLImporter()
let score = try importer.importScore(from: musicXMLURL)

// Display in SwiftUI
ScoreViewRepresentable(
    score: $score,
    layoutContext: LayoutContext.letterSize(staffHeight: 40)
)
```

## Installation

### Swift Package Manager

Add SwiftMusicNotation to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/zakkeown/SwiftMusicNotation.git", from: "1.0.0")
]
```

Or add it in Xcode via **File > Add Package Dependencies**.

## Modules

SwiftMusicNotation is organized into focused modules:

| Module | Description |
|--------|-------------|
| **SwiftMusicNotation** | Umbrella module - import this for full library access |
| **MusicNotationCore** | Domain models (Score, Part, Measure, Note, Pitch, etc.) |
| **SMuFLKit** | SMuFL font loading and glyph management |
| **MusicXMLImport** | Parse MusicXML files into Score objects |
| **MusicXMLExport** | Generate MusicXML from Score objects |
| **MusicNotationLayout** | Compute positions for all notation elements |
| **MusicNotationRenderer** | Core Graphics rendering and platform views |
| **MusicNotationPlayback** | MIDI playback with AVFoundation |

Import the umbrella module for most projects:

```swift
import SwiftMusicNotation
```

Or import individual modules for more control:

```swift
import MusicNotationCore
import MusicXMLImport
```

## Requirements

- Swift 5.9+
- macOS 13+ / iOS 16+
- Xcode 15+

## Usage Examples

### Loading and Displaying a Score

```swift
import SwiftUI
import SwiftMusicNotation

struct ScoreView: View {
    @State private var score: Score?
    let layoutContext = LayoutContext.letterSize(staffHeight: 40)

    var body: some View {
        ScoreViewRepresentable(
            score: $score,
            layoutContext: layoutContext
        )
        .task {
            let importer = MusicXMLImporter()
            score = try? importer.importScore(from: url)
        }
    }
}
```

### Adding Playback

```swift
let engine = PlaybackEngine()
try await engine.load(score)

engine.events.sink { event in
    switch event {
    case .positionChanged(let measure, let beat):
        // Update UI with current position
    case .started, .paused, .stopped:
        // Update playback state
    default:
        break
    }
}

try engine.play()
```

### Exporting to MusicXML

```swift
let exporter = MusicXMLExporter()
let xmlString = try exporter.exportToString(score)

// Or write directly to file
try exporter.export(score, to: outputURL)
```

### Accessing Score Data

```swift
// Navigate the score hierarchy
for part in score.parts {
    print("Part: \(part.name)")

    for measure in part.measures {
        for note in measure.notes {
            if let pitch = note.pitch {
                print("  \(pitch.step)\(pitch.octave)")
            }
        }
    }
}
```

## Architecture

SwiftMusicNotation follows a pipeline architecture:

```
MusicXML → MusicXMLImporter → Score → LayoutEngine → EngravedScore → MusicRenderer → CGContext
```

1. **Import**: Parse MusicXML into domain models
2. **Layout**: Compute positions and page breaks
3. **Render**: Draw to Core Graphics context or display in views

## Documentation

Full documentation is available via DocC:

- **Online**: [SwiftMusicNotation Documentation](https://zakkeown.github.io/SwiftMusicNotation/documentation/swiftmusicnotation/)
- **Xcode**: **Product > Build Documentation**
- **Command Line**:
  ```bash
  swift package generate-documentation
  swift package --disable-sandbox preview-documentation
  ```

### Tutorials

Interactive tutorials are included:
- **Displaying Your First Score** - Load and render MusicXML
- **Customizing Appearance** - Fonts, colors, and layout
- **Adding Playback** - MIDI synthesis and position tracking
- **Exporting Scores** - MusicXML, PDF, and image export

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Contributing

Contributions are welcome! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

### Quick Links

- [Report a Bug](https://github.com/zakkeown/SwiftMusicNotation/issues)
- [Request a Feature](https://github.com/zakkeown/SwiftMusicNotation/issues)
- [View Documentation](https://zakkeown.github.io/SwiftMusicNotation/)
