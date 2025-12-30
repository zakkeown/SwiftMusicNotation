# MIDI Integration

Work with MIDI events for playback, export, and external MIDI integration.

@Metadata {
    @PageKind(article)
}

## Overview

The playback module converts musical scores into timed MIDI events for audio synthesis. Understanding this conversion process enables custom playback scenarios, MIDI export, and integration with external MIDI systems.

## Score to MIDI Conversion

The ``ScoreSequencer`` converts a ``Score`` into a sequence of timed MIDI events:

```swift
let sequencer = ScoreSequencer()
let midiSequence = sequencer.createSequence(from: score)

// Access individual events
for event in midiSequence.events {
    switch event.type {
    case .noteOn(let channel, let pitch, let velocity):
        print("Note On: ch=\(channel) pitch=\(pitch) vel=\(velocity) at \(event.time)")

    case .noteOff(let channel, let pitch):
        print("Note Off: ch=\(channel) pitch=\(pitch) at \(event.time)")

    case .controlChange(let channel, let controller, let value):
        print("CC: ch=\(channel) cc=\(controller) val=\(value)")

    case .programChange(let channel, let program):
        print("Program: ch=\(channel) prog=\(program)")

    case .tempo(let bpm):
        print("Tempo: \(bpm) BPM")
    }
}
```

## Timing Calculation

MIDI timing is calculated from score divisions:

```swift
// Score uses divisions (e.g., 24 divisions per quarter note)
// MIDI uses ticks (typically 480 or 960 per quarter note)

let midiTicksPerQuarter = 480
let scoreDivisions = 24

// Convert score position to MIDI ticks
let midiTicks = (scorePosition * midiTicksPerQuarter) / scoreDivisions
```

The sequencer handles this conversion automatically based on score attributes.

## Velocity and Dynamics

Dynamic markings are converted to MIDI velocities:

| Dynamic | Typical Velocity |
|---------|-----------------|
| ppp | 16 |
| pp | 33 |
| p | 49 |
| mp | 64 |
| mf | 80 |
| f | 96 |
| ff | 112 |
| fff | 127 |

Customize the mapping:

```swift
var config = PlaybackConfiguration()
config.velocityMapping = [
    .ppp: 20,
    .pp: 40,
    .p: 55,
    .mp: 70,
    .mf: 85,
    .f: 100,
    .ff: 115,
    .fff: 127
]
```

### Crescendo and Diminuendo

Wedges (hairpins) interpolate velocity over their duration:

```swift
// The sequencer calculates intermediate velocities
// For a crescendo from p to f over 4 beats:
// Beat 1: velocity 49
// Beat 2: velocity 64
// Beat 3: velocity 80
// Beat 4: velocity 96
```

## Instrument Mapping

The ``InstrumentMapper`` assigns MIDI programs to parts:

```swift
let mapper = InstrumentMapper()

// Get MIDI program for a part
let midiProgram = mapper.midiProgram(for: part)

// Or set custom mappings
mapper.setProgram(41, for: "Violin")  // Violin = program 41
mapper.setProgram(43, for: "Cello")   // Cello = program 43
```

### General MIDI Programs

Common instrument programs:

| Program | Instrument |
|---------|-----------|
| 0 | Acoustic Grand Piano |
| 24 | Acoustic Guitar |
| 40 | Violin |
| 42 | Cello |
| 56 | Trumpet |
| 73 | Flute |

## Custom MIDI Event Handling

Subscribe to MIDI events during playback:

```swift
let engine = PlaybackEngine()

// Subscribe to note events
engine.onNoteEvent = { event in
    switch event {
    case .noteOn(let pitch, let velocity, let noteId):
        highlightNote(noteId)
    case .noteOff(let pitch, let noteId):
        unhighlightNote(noteId)
    }
}

// Subscribe to position changes
engine.onPositionChanged = { position in
    updateCursor(to: position)
}
```

## MIDI Export

Export a score as a Standard MIDI File:

```swift
let exporter = MIDIExporter()

// Export as Type 1 MIDI (multi-track)
let midiData = try exporter.export(score: score, format: .type1)
try midiData.write(to: outputURL)

// Or Type 0 (single track, merged)
let midiType0 = try exporter.export(score: score, format: .type0)
```

## External MIDI Output

Send MIDI to external devices or software:

```swift
let midiOutput = MIDIOutput()

// List available destinations
for destination in midiOutput.availableDestinations {
    print("\(destination.name)")
}

// Connect to a destination
try midiOutput.connect(to: destinationName)

// Send events
midiOutput.send(.noteOn(channel: 0, pitch: 60, velocity: 100))
midiOutput.send(.noteOff(channel: 0, pitch: 60))
```

## MIDI Input (Receive)

Receive MIDI from external controllers:

```swift
let midiInput = MIDIInput()

midiInput.onEventReceived = { event in
    switch event {
    case .noteOn(let channel, let pitch, let velocity):
        // Handle incoming note
        handleNoteInput(pitch: pitch, velocity: velocity)
    default:
        break
    }
}

try midiInput.start()
```

## Timing and Synchronization

### MIDI Clock

For external synchronization:

```swift
let engine = PlaybackEngine()

// Send MIDI clock
engine.sendMIDIClock = true
engine.midiClockOutput = midiOutput

// Or receive MIDI clock
engine.syncToMIDIClock = true
engine.midiClockInput = midiInput
```

### Latency Compensation

Adjust for audio output latency:

```swift
engine.outputLatency = 0.010  // 10ms latency compensation
```

## See Also

- ``ScoreSequencer``
- ``MIDISynthesizer``
- ``InstrumentMapper``
- ``PlaybackEngine``
- <doc:PlaybackEngine>
