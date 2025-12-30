# Quick Start

Display a music score in your app in just a few lines of code.

@Metadata {
    @PageKind(article)
}

## Overview

This guide walks you through the basic workflow: loading a MusicXML file, computing its layout, and displaying it in a SwiftUI view.

## The Basic Workflow

SwiftMusicNotation follows a pipeline architecture:

```
MusicXML File → Import → Score → Layout → Render
```

1. **Import**: Parse MusicXML into a `Score` object
2. **Layout**: Compute positions with `LayoutEngine`
3. **Render**: Display using `ScoreViewRepresentable`

## Step 1: Import a MusicXML File

Use `MusicXMLImporter` to parse MusicXML files:

```swift
import SwiftMusicNotation

let importer = MusicXMLImporter()

// From a URL
let score = try importer.importScore(from: musicXMLURL)

// Or from Data
let score = try importer.importScore(from: musicXMLData)
```

The importer handles both `.musicxml` files and compressed `.mxl` archives automatically.

## Step 2: Configure Layout

Create a `LayoutContext` with page size and staff height:

```swift
// US Letter size with 40-point staff height
let context = LayoutContext.letterSize(staffHeight: 40)

// Or A4 paper
let context = LayoutContext.a4Size(staffHeight: 40)

// Or custom size
let context = LayoutContext(
    pageSize: CGSize(width: 800, height: 600),
    margins: EdgeInsets(all: 50),
    staffHeight: 35
)
```

## Step 3: Display in SwiftUI

Use `ScoreViewRepresentable` to display the score:

```swift
import SwiftUI
import SwiftMusicNotation

struct ContentView: View {
    @State private var score: Score?

    let layoutContext = LayoutContext.letterSize(staffHeight: 40)

    var body: some View {
        VStack {
            if score != nil {
                ScoreViewRepresentable(
                    score: $score,
                    layoutContext: layoutContext
                )
            } else {
                Text("No score loaded")
            }

            Button("Load Score") {
                loadScore()
            }
        }
    }

    private func loadScore() {
        guard let url = Bundle.main.url(
            forResource: "example",
            withExtension: "musicxml"
        ) else { return }

        do {
            let importer = MusicXMLImporter()
            score = try importer.importScore(from: url)
        } catch {
            print("Failed to load score: \(error)")
        }
    }
}
```

## Adding Zoom and Selection

Enable zoom and element selection with bindings:

```swift
struct ScoreDisplayView: View {
    @State private var score: Score?
    @State private var zoomLevel: CGFloat = 1.0
    @State private var selectedElements: [SelectableElement] = []

    let layoutContext = LayoutContext.letterSize(staffHeight: 40)

    var body: some View {
        VStack {
            ScoreViewRepresentable(
                score: $score,
                zoomLevel: $zoomLevel,
                selectedElements: $selectedElements,
                layoutContext: layoutContext,
                onElementTapped: { element in
                    print("Tapped: \(element.elementType)")
                }
            )

            HStack {
                Button("Zoom Out") { zoomLevel = max(0.5, zoomLevel - 0.1) }
                Text("\(Int(zoomLevel * 100))%")
                Button("Zoom In") { zoomLevel = min(2.0, zoomLevel + 0.1) }
            }
        }
    }
}
```

## Adding Playback

Use `PlaybackEngine` for MIDI playback:

```swift
import Combine

class PlaybackController: ObservableObject {
    private let engine = PlaybackEngine()
    private var cancellables = Set<AnyCancellable>()

    @Published var isPlaying = false
    @Published var currentMeasure = 1

    init() {
        engine.events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .started:
                    self?.isPlaying = true
                case .stopped, .paused:
                    self?.isPlaying = false
                case .positionChanged(let measure, _):
                    self?.currentMeasure = measure
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    func load(_ score: Score) async throws {
        try await engine.load(score)
    }

    func togglePlayback() throws {
        if isPlaying {
            engine.pause()
        } else {
            try engine.play()
        }
    }
}
```

## Complete Example

Here's a complete view combining display and playback:

```swift
struct MusicPlayerView: View {
    @State private var score: Score?
    @State private var zoomLevel: CGFloat = 1.0
    @StateObject private var playback = PlaybackController()

    let layoutContext = LayoutContext.letterSize(staffHeight: 40)

    var body: some View {
        VStack {
            if score != nil {
                ScoreViewRepresentable(
                    score: $score,
                    zoomLevel: $zoomLevel,
                    layoutContext: layoutContext
                )
            }

            HStack {
                Button(playback.isPlaying ? "Pause" : "Play") {
                    try? playback.togglePlayback()
                }

                Text("Measure \(playback.currentMeasure)")
            }
            .padding()
        }
        .task {
            await loadAndPrepare()
        }
    }

    private func loadAndPrepare() async {
        guard let url = Bundle.main.url(
            forResource: "example",
            withExtension: "musicxml"
        ) else { return }

        do {
            let importer = MusicXMLImporter()
            let loadedScore = try importer.importScore(from: url)
            score = loadedScore
            try await playback.load(loadedScore)
        } catch {
            print("Error: \(error)")
        }
    }
}
```

## Next Steps

- Learn about the <doc:ArchitectureOverview> and data flow
- Explore the score model hierarchy for accessing notation data
- Customize layout with `LayoutConfiguration`
- Adjust visual appearance with `RenderConfiguration`
