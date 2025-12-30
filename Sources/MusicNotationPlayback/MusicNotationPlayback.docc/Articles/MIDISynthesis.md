# MIDI Synthesis

Understand MIDI audio synthesis using AVFoundation.

@Metadata {
    @PageKind(article)
}

## Overview

``MIDISynthesizer`` provides real-time audio synthesis of MIDI events using AVFoundation's `AVAudioUnitSampler`. It handles note playback, instrument selection, and audio effects. While ``PlaybackEngine`` manages this internally, understanding the synthesizer helps with advanced customization.

## Architecture

The audio signal flow:

```
Score → ScoreSequencer → MIDISynthesizer → Audio Output
            │                    │
            │                    ├── AVAudioUnitSampler
            │                    ├── AVAudioMixerNode
            │                    └── AVAudioEngine
            │
            └── MIDI Events (noteOn, noteOff, programChange, etc.)
```

## MIDI Events

### Note Events

The synthesizer plays notes via MIDI note-on and note-off messages:

```swift
// Play a note
synthesizer.noteOn(note: 60, velocity: 100, channel: 0)  // Middle C

// Stop a note
synthesizer.noteOff(note: 60, channel: 0)
```

MIDI note numbers map to pitches:
- 60 = Middle C (C4)
- 69 = A4 (440 Hz)
- Range: 0-127

Velocity controls loudness (0-127).

### Program Changes

Select different instruments (sounds) per channel:

```swift
// Set channel 0 to Acoustic Grand Piano (program 0)
synthesizer.programChange(program: 0, channel: 0)

// Set channel 1 to Strings (program 48)
synthesizer.programChange(program: 48, channel: 1)
```

### General MIDI Instruments

Standard General MIDI programs:

| Range | Category |
|-------|----------|
| 0-7 | Piano |
| 8-15 | Chromatic Percussion |
| 16-23 | Organ |
| 24-31 | Guitar |
| 32-39 | Bass |
| 40-47 | Strings |
| 48-55 | Ensemble |
| 56-63 | Brass |
| 64-71 | Reed |
| 72-79 | Pipe |
| 80-87 | Synth Lead |
| 88-95 | Synth Pad |
| 96-103 | Synth Effects |
| 104-111 | Ethnic |
| 112-119 | Percussive |
| 120-127 | Sound Effects |

### Control Changes

Modify sound parameters in real-time:

```swift
// Volume (CC 7)
synthesizer.controlChange(controller: 7, value: 100, channel: 0)

// Pan (CC 10): 0=left, 64=center, 127=right
synthesizer.controlChange(controller: 10, value: 64, channel: 0)

// Sustain pedal (CC 64): 0=off, 127=on
synthesizer.controlChange(controller: 64, value: 127, channel: 0)

// Expression (CC 11)
synthesizer.controlChange(controller: 11, value: 100, channel: 0)

// Modulation wheel (CC 1)
synthesizer.controlChange(controller: 1, value: 64, channel: 0)
```

### Common Controllers

```swift
extension MIDISynthesizer {
    enum Controller: UInt8 {
        case modulation = 1
        case volume = 7
        case pan = 10
        case expression = 11
        case sustain = 64
        case sostenuto = 66
        case soft = 67
        case reverb = 91
        case chorus = 93
        case allSoundOff = 120
        case allNotesOff = 123
    }
}
```

## Channel Management

MIDI provides 16 channels (0-15):

```swift
// Assign parts to channels
for (index, part) in score.parts.enumerated() {
    let channel = UInt8(index % 16)

    // Set instrument for this part
    if let midiProgram = part.midiInstruments.first?.program {
        synthesizer.programChange(program: UInt8(midiProgram), channel: channel)
    }
}
```

Channel 9 (index 9) is traditionally reserved for drums in General MIDI.

## Volume and Mixing

### Per-Channel Volume

```swift
// Set volume for channel (0.0 to 1.0)
synthesizer.setVolume(0.8, forChannel: 0)

// Mute a channel
synthesizer.setMuted(true, forChannel: 1)

// Pan a channel
synthesizer.setPan(-0.5, forChannel: 0)  // Slight left
synthesizer.setPan(0.5, forChannel: 1)   // Slight right
```

### Master Volume

```swift
synthesizer.setMasterVolume(0.7)  // 70% overall
```

### Effects

```swift
// Reverb send (0.0 to 1.0)
synthesizer.setReverbSend(0.3, forChannel: 0)

// Chorus send (0.0 to 1.0)
synthesizer.setChorusSend(0.2, forChannel: 0)
```

## Sound Banks

### Default Sound Bank

The synthesizer automatically loads the system's General MIDI sound bank:
- macOS: `/Library/Audio/Sounds/Banks/gs_instruments.dls`
- iOS: Built-in sounds

### Custom SoundFonts

Load custom SoundFont files for different sounds:

```swift
let soundFontURL = Bundle.main.url(forResource: "MySoundFont", withExtension: "sf2")!
try synthesizer.loadSoundFont(at: soundFontURL)
```

SoundFont formats supported:
- `.sf2` (SoundFont 2)
- `.dls` (Downloadable Sounds)

## Pitch Bend

Apply pitch bending (vibrato, glissando):

```swift
// Center position (no bend)
synthesizer.pitchBend(value: 8192, channel: 0)

// Bend up
synthesizer.pitchBend(value: 12288, channel: 0)

// Bend down
synthesizer.pitchBend(value: 4096, channel: 0)
```

Pitch bend range: 0-16383 (8192 = center, no bend)

## All Notes Off

Stop all sounding notes immediately:

```swift
synthesizer.allNotesOff()
```

This sends both "All Notes Off" (CC 123) and "All Sound Off" (CC 120) to all channels.

## Audio Engine Lifecycle

```swift
// Start the audio engine
try synthesizer.start()

// Check if running
if synthesizer.isRunning {
    // Process MIDI events
}

// Stop the engine
synthesizer.stop()

// Get current time (for synchronization)
let time = synthesizer.currentTime
```

## Performance Considerations

1. **Pre-load sounds** before playback starts
2. **Limit polyphony** - too many simultaneous notes can cause audio glitches
3. **Use appropriate buffer sizes** - AVAudioEngine manages this automatically
4. **Handle audio interruptions** on iOS (phone calls, etc.)

## See Also

- ``MIDISynthesizer``
- ``MIDISynthesizer/Controller``
- ``MIDISynthesizer/InstrumentFamily``
- ``PlaybackEngine``
- <doc:PlaybackEngine>
- <doc:CursorTracking>
