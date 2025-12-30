# Playback Engine

Coordinate MIDI playback of music notation scores.

@Metadata {
    @PageKind(article)
}

## Overview

``PlaybackEngine`` is the main entry point for adding audio playback to music notation applications. It converts scores to timed MIDI events and synthesizes audio using AVFoundation's built-in MIDI synthesizer.

## Basic Usage

Load a score and control playback:

```swift
import MusicNotationPlayback

let engine = PlaybackEngine()

// Load a score
try await engine.load(score)

// Control playback
try engine.play()    // Start or resume
engine.pause()       // Pause at current position
engine.stop()        // Stop and reset to beginning
```

## SwiftUI Integration

``PlaybackEngine`` is an `ObservableObject` with `@Published` properties:

```swift
struct PlaybackControls: View {
    @StateObject private var engine = PlaybackEngine()
    @State private var score: Score?

    var body: some View {
        VStack {
            // Position display
            Text("Measure \(engine.currentPosition.measure)")
                .font(.headline)

            // Transport controls
            HStack {
                Button(action: { try? engine.previousMeasure() }) {
                    Image(systemName: "backward.fill")
                }

                Button(action: togglePlayback) {
                    Image(systemName: engine.state == .playing ? "pause.fill" : "play.fill")
                }

                Button(action: { try? engine.nextMeasure() }) {
                    Image(systemName: "forward.fill")
                }

                Button(action: { engine.stop() }) {
                    Image(systemName: "stop.fill")
                }
            }

            // Tempo slider
            Slider(value: $engine.tempo, in: 40...240)
            Text("\(Int(engine.tempo)) BPM")
        }
        .task {
            if let score = score {
                try? await engine.load(score)
            }
        }
    }

    func togglePlayback() {
        if engine.state == .playing {
            engine.pause()
        } else {
            try? engine.play()
        }
    }
}
```

## Playback Events with Combine

Subscribe to detailed playback events:

```swift
import Combine

var cancellables = Set<AnyCancellable>()

engine.events
    .receive(on: DispatchQueue.main)
    .sink { event in
        switch event {
        case .started:
            updatePlayButton(isPlaying: true)

        case .paused:
            updatePlayButton(isPlaying: false)

        case .stopped:
            resetCursor()
            updatePlayButton(isPlaying: false)

        case .positionChanged(let measure, let beat):
            updateCursor(measure: measure, beat: beat)

        case .tempoChanged(let bpm):
            updateTempoDisplay(bpm)

        case .error(let error):
            showError(error)
        }
    }
    .store(in: &cancellables)
```

### Event Types

| Event | When Triggered |
|-------|----------------|
| `.started` | Playback begins or resumes |
| `.paused` | Playback paused |
| `.stopped` | Playback stopped and reset |
| `.positionChanged(measure, beat)` | Playback position updates |
| `.tempoChanged(bpm)` | Tempo changes |
| `.error(error)` | An error occurred |

## Position Navigation

### Seek to Position

```swift
// Seek to measure 5, beat 1
try engine.seek(to: 5, beat: 1.0)

// Seek to measure 10, beat 3
try engine.seek(to: 10, beat: 3.0)
```

### Navigate by Measure

```swift
// Move to next measure
try engine.nextMeasure()

// Move to previous measure
try engine.previousMeasure()
```

### Reading Position

```swift
let position = engine.currentPosition

print("Measure: \(position.measure)")
print("Beat: \(position.beat)")
print("Time: \(position.timeInSeconds) seconds")
```

## Tempo Control

### Setting Tempo

```swift
// Set tempo in BPM
engine.tempo = 120.0  // Default

// Slower for practice
engine.tempo = 60.0

// Up to tempo
engine.tempo = 144.0
```

### Tempo Changes During Playback

Tempo changes take effect immediately:

```swift
// Gradual tempo change
func accelerate() {
    Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { timer in
        if engine.tempo < 180 {
            engine.tempo += 2
        } else {
            timer.invalidate()
        }
    }
}
```

## Volume Control

### Master Volume

```swift
// Set master volume (0.0 to 1.0)
engine.masterVolume = 0.8  // 80%

// Mute all
engine.masterVolume = 0.0

// Full volume
engine.masterVolume = 1.0
```

### Per-Part Volume

```swift
// Adjust individual parts
engine.setVolume(0.5, forPart: "P1")  // 50% volume
engine.setVolume(1.0, forPart: "P2")  // Full volume

// Mute/unmute parts
engine.setMuted(true, forPart: "P3")   // Mute
engine.setMuted(false, forPart: "P3")  // Unmute
```

### Practice Mode

Create a practice mode that highlights one part:

```swift
func isolatePart(_ partId: String) {
    for part in score.parts {
        if part.id == partId {
            engine.setVolume(1.0, forPart: part.id)
        } else {
            engine.setVolume(0.2, forPart: part.id)  // Background level
        }
    }
}
```

## Playback State

The engine has three states:

```swift
switch engine.state {
case .stopped:
    // Not playing, position at beginning
    break
case .playing:
    // Audio is playing
    break
case .paused:
    // Paused at current position
    break
}
```

### State-Aware UI

```swift
var playButtonTitle: String {
    switch engine.state {
    case .stopped: return "Play"
    case .playing: return "Pause"
    case .paused: return "Resume"
    }
}
```

## Error Handling

Handle playback errors appropriately:

```swift
do {
    try engine.play()
} catch let error as PlaybackEngine.PlaybackError {
    switch error {
    case .noScoreLoaded:
        showAlert("Please load a score first")

    case .audioEngineError(let message):
        showAlert("Audio error: \(message)")

    case .soundBankNotFound:
        showAlert("Sound bank not available")

    case .invalidPosition:
        showAlert("Invalid playback position")

    case .sequencingError(let message):
        showAlert("Sequencing error: \(message)")
    }
}
```

## Thread Safety

``PlaybackEngine`` is marked `@MainActor`. All calls must be made from the main thread:

```swift
// Correct: called from main actor
await MainActor.run {
    try? engine.play()
}

// Or use Task { @MainActor in ... }
Task { @MainActor in
    try await engine.load(score)
    try engine.play()
}
```

The `load(_:)` method is `async` to handle sound bank loading on a background thread.

## See Also

- ``PlaybackEngine``
- ``PlaybackEngine/State``
- ``PlaybackEngine/PlaybackEvent``
- ``PlaybackEngine/PlaybackError``
- ``PlaybackPosition``
- <doc:MIDISynthesis>
- <doc:CursorTracking>
