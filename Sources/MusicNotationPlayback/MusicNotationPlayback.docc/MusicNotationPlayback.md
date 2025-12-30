# ``MusicNotationPlayback``

MIDI playback for music scores using AVFoundation.

## Overview

MusicNotationPlayback provides `PlaybackEngine` for audio playback of scores. It converts notation to MIDI events and synthesizes audio using AVFoundation.

### Basic Playback

```swift
let engine = PlaybackEngine()

// Load a score
try await engine.load(score)

// Control playback
try engine.play()
engine.pause()
engine.stop()
```

### Playback Events

Subscribe to playback events with Combine:

```swift
import Combine

var cancellables = Set<AnyCancellable>()

engine.events
    .receive(on: DispatchQueue.main)
    .sink { event in
        switch event {
        case .started:
            print("Playback started")

        case .paused:
            print("Playback paused")

        case .stopped:
            print("Playback stopped")

        case .positionChanged(let measure, let beat):
            print("Position: measure \(measure), beat \(beat)")

        case .tempoChanged(let bpm):
            print("Tempo: \(bpm) BPM")

        case .error(let error):
            print("Error: \(error)")
        }
    }
    .store(in: &cancellables)
```

### Position Control

Navigate within the score:

```swift
// Seek to a specific position
engine.seek(to: 5, beat: 1.0)  // Measure 5, beat 1

// Navigate by measure
engine.nextMeasure()
engine.previousMeasure()

// Get current position
let position = engine.currentPosition
print("Measure \(position.measure), beat \(position.beat)")
```

### Tempo Control

Adjust playback tempo:

```swift
// Get/set tempo in BPM
engine.tempo = 120

// Tempo is published for UI binding
@Published var tempo: Double
```

### Volume and Muting

Control individual part volumes:

```swift
// Master volume (0.0 to 1.0)
engine.masterVolume = 0.8

// Per-part volume
engine.setVolume(0.5, forPart: 0)  // 50% volume for first part

// Mute/unmute parts
engine.setMuted(true, forPart: 1)  // Mute second part
```

### Playback State

Monitor playback state:

```swift
// Published properties for SwiftUI binding
@Published var state: State  // .stopped, .playing, .paused
@Published var isLoaded: Bool
@Published var currentPosition: PlaybackPosition
```

### Error Handling

Handle playback errors:

```swift
do {
    try engine.play()
} catch let error as PlaybackEngine.PlaybackError {
    switch error {
    case .noScoreLoaded:
        print("No score loaded")
    case .audioEngineError(let message):
        print("Audio error: \(message)")
    case .soundBankNotFound:
        print("Sound bank not found")
    case .invalidPosition:
        print("Invalid seek position")
    case .sequencingError(let message):
        print("Sequencing error: \(message)")
    }
}
```

### SwiftUI Integration

Example playback controller for SwiftUI:

```swift
@MainActor
class PlaybackController: ObservableObject {
    private let engine = PlaybackEngine()
    private var cancellables = Set<AnyCancellable>()

    @Published var isPlaying = false
    @Published var currentMeasure = 1
    @Published var tempo: Double = 120

    init() {
        engine.events
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleEvent(event)
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

    private func handleEvent(_ event: PlaybackEngine.PlaybackEvent) {
        switch event {
        case .started:
            isPlaying = true
        case .stopped, .paused:
            isPlaying = false
        case .positionChanged(let measure, _):
            currentMeasure = measure
        case .tempoChanged(let bpm):
            tempo = bpm
        default:
            break
        }
    }
}
```

## Topics

### Playback Engine

- ``PlaybackEngine``
- ``PlaybackEngine/State``
- ``PlaybackEngine/PlaybackEvent``
- ``PlaybackEngine/PlaybackError``

### Articles

- <doc:PlaybackEngine>
- <doc:MIDIIntegration>
- <doc:CursorTracking>

### Position

- ``PlaybackPosition``
- ``PlaybackCursor``

### Sequencing

- ``ScoreSequencer``
- ``InstrumentMapper``
- ``DynamicsInterpreter``

### Synthesis

- ``MIDISynthesizer``
