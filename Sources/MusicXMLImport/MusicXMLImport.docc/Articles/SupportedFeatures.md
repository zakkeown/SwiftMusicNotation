# Supported Features

Understand which MusicXML elements are supported by the importer.

@Metadata {
    @PageKind(article)
}

## Overview

MusicXMLImport supports a comprehensive subset of the MusicXML 4.0 specification, covering the elements most commonly used in music notation. This article details which features are fully supported, partially supported, or not yet implemented.

## Score Structure

### Fully Supported

| Element | Description |
|---------|-------------|
| `<score-partwise>` | Standard part-organized format |
| `<score-timewise>` | Measure-organized format |
| `<part-list>` | Part definitions and groupings |
| `<part>` | Individual instrument parts |
| `<measure>` | Measure containers |

### Part Information

```swift
// Parsed from <score-part>
let part = score.parts[0]
part.id              // From id attribute
part.name            // From <part-name>
part.abbreviation    // From <part-abbreviation>
part.staffCount      // From <staves> in attributes
part.instruments     // From <score-instrument>
part.midiInstruments // From <midi-instrument>
```

## Notes and Rests

### Fully Supported

| Element | Notes |
|---------|-------|
| `<note>` | Pitched notes, rests, unpitched |
| `<pitch>` | Step, alter, octave |
| `<duration>` | Actual duration in divisions |
| `<type>` | Notated duration (quarter, eighth, etc.) |
| `<dot>` | Augmentation dots (multiple supported) |
| `<rest>` | Including measure rests |
| `<chord>` | Notes sounding together |
| `<voice>` | Voice assignment |
| `<staff>` | Staff assignment |
| `<stem>` | Up/down/none/double |
| `<grace>` | Grace notes (slashed/unslashed) |
| `<cue>` | Cue-sized notes |

### Note Types

```swift
// Duration types parsed from <type>
case maxima, long, breve
case whole, half, quarter
case eighth, sixteenth
case thirtySecond, sixtyFourth
case oneHundredTwentyEighth, twoHundredFiftySixth
```

### Accidentals

```swift
// Accidentals parsed from <accidental>
case sharp, flat, natural
case doubleSharp, doubleFlat
case quarterFlat, quarterSharp
case threeQuartersFlat, threeQuartersSharp
// Plus parenthetical and cautionary variants
```

### Noteheads

```swift
// Notehead types from <notehead>
case normal, diamond, triangle
case slash, cross, circleX
case square
// With filled/open variants
```

## Attributes

### Clefs

```swift
// Supported clef types
ClefSign.g      // Treble (G clef)
ClefSign.f      // Bass (F clef)
ClefSign.c      // Alto/Tenor (C clef)
ClefSign.percussion
ClefSign.tab

// With octave changes (8va, 8vb, 15ma, 15mb)
```

### Key Signatures

```swift
// Traditional key signatures (fifths-based)
let keySignature = KeySignature(fifths: -3, mode: .minor)  // C minor

// Parsed from <key>:
// - <fifths>: -7 to +7
// - <mode>: major, minor, dorian, etc.
```

### Time Signatures

```swift
// Standard time signatures
TimeSignature(beats: 4, beatType: 4)      // 4/4
TimeSignature(beats: 6, beatType: 8)      // 6/8

// Special symbols
TimeSignatureSymbol.common     // C
TimeSignatureSymbol.cut        // Cut time

// Compound time signatures
// 3+2/8 supported via multiple beat values
```

### Other Attributes

| Element | Description |
|---------|-------------|
| `<divisions>` | Divisions per quarter note |
| `<staves>` | Number of staves in part |
| `<transpose>` | Transposition information |
| `<measure-style>` | Multiple rest, slash notation |

## Notations

### Ties and Slurs

```swift
// Ties connect same pitches
case .tie(Tie)
// - type: start/stop
// - orientation: over/under

// Slurs connect different pitches
case .slur(Slur)
// - type: start/stop/continue
// - number: for nested slurs
// - placement: above/below
```

### Beams

```swift
// Beam information
Beam(number: 1, type: .begin)
Beam(number: 2, type: .continue)
// Types: begin, continue, end, forwardHook, backwardHook
```

### Tuplets

```swift
// Tuplet notation
Tuplet(
    type: .start,
    number: 1,
    actualNotes: 3,
    normalNotes: 2,
    bracket: true
)
```

### Articulations

```swift
// Supported articulations
case accent, strongAccent
case staccato, staccatissimo
case tenuto
case detachedLegato
case marcato
case spiccato
case scoop, plop, doit, falloff
case breathMark, caesura
```

### Ornaments

```swift
// Supported ornaments
case trill
case turn, invertedTurn, delayedTurn
case mordent, invertedMordent
case tremoloSingle(bars: Int)
case tremoloDouble(bars: Int)
```

### Dynamics

```swift
// Dynamic markings
DynamicValue.ppp, .pp, .p
DynamicValue.mp, .mf
DynamicValue.f, .ff, .fff
DynamicValue.sfz, .sfp, .fp
// etc.
```

### Other Notations

| Element | Description |
|---------|-------------|
| `<fermata>` | Hold markings |
| `<arpeggiate>` | Rolled chords |
| `<glissando>` | Glissando lines |
| `<slide>` | Portamento |
| `<technical>` | Fingerings, strings, frets |

## Directions

### Supported Direction Types

| Element | Swift Type |
|---------|------------|
| `<dynamics>` | `DynamicsDirection` |
| `<wedge>` | `Wedge` (crescendo/diminuendo) |
| `<metronome>` | `Metronome` |
| `<words>` | `Words` |
| `<rehearsal>` | `Rehearsal` |
| `<segno>` | `Segno` |
| `<coda>` | `Coda` |
| `<octave-shift>` | `OctaveShift` |
| `<pedal>` | `Pedal` |
| `<percussion>` | `PercussionDirection` |

### Direction Properties

```swift
let direction = Direction(
    placement: .above,
    directive: true,
    voice: 1,
    staff: 1,
    types: [.dynamics(...)],
    offset: 0
)
```

## Barlines

### Bar Styles

```swift
BarStyle.regular
BarStyle.dotted
BarStyle.dashed
BarStyle.heavy
BarStyle.lightLight
BarStyle.lightHeavy
BarStyle.heavyLight
BarStyle.heavyHeavy
BarStyle.none
```

### Repeats and Endings

```swift
// Repeat barlines
RepeatDirection.forward
RepeatDirection.backward

// Volta brackets (endings)
Ending(number: "1", type: .start, text: "1.")
Ending(number: "2", type: .start, text: "2.")
```

## Percussion

### Unpitched Notes

```swift
// Unpitched percussion notes
Note(
    pitch: nil,
    unpitched: Unpitched(displayStep: .e, displayOctave: 4),
    instrument: "P1-I1"
)
```

### Percussion Directions

```swift
// Percussion-specific directions
PercussionDirectionType.timpani(TimpaniTuning)
PercussionDirectionType.beater(BeaterType)
PercussionDirectionType.stick(StickSpecification)
PercussionDirectionType.membrane(MembraneType)
PercussionDirectionType.metal(MetalType)
```

## Metadata

### Score Information

```swift
score.metadata.workTitle        // From <work-title>
score.metadata.workNumber       // From <work-number>
score.metadata.movementTitle    // From <movement-title>
score.metadata.movementNumber   // From <movement-number>
score.metadata.creators         // From <creator type="composer">
score.metadata.rights           // From <rights>
score.metadata.encoding         // Software, date, encoder
```

### Credits

```swift
// Page credits
score.credits[0].page           // Page number
score.credits[0].creditType     // "title", "subtitle", "composer"
score.credits[0].creditWords    // Text and positioning
```

### Layout Defaults

```swift
score.defaults?.scaling         // Millimeters per tenths
score.defaults?.pageSettings    // Page dimensions, margins
```

## Print Controls

| Element | Description |
|---------|-------------|
| `new-system` | Force system break |
| `new-page` | Force page break |
| `blank-page` | Insert blank page |
| `page-number` | Page number text |
| `staff-spacing` | Staff distance override |

## Forward and Backup

```swift
// Move forward in time (for voice independence)
Forward(duration: 24, voice: 2, staff: 1)

// Move backward in time
Backup(duration: 48)
```

## Not Yet Supported

The following elements are recognized but not fully parsed:

| Element | Status |
|---------|--------|
| `<harmony>` | Chord symbols - planned |
| `<figured-bass>` | Figured bass notation |
| `<lyric>` | Lyrics - partial support |
| `<sound>` | Playback instructions |
| `<listen>` | Accessibility |
| `<frame>` | Guitar frames |

## Version Compatibility

MusicXMLImport supports:

| Version | Support Level |
|---------|---------------|
| MusicXML 1.0 | Full |
| MusicXML 2.0 | Full |
| MusicXML 3.0 | Full |
| MusicXML 3.1 | Full |
| MusicXML 4.0 | Full |

Files with newer versions are parsed with best-effort compatibility.

## See Also

- ``MusicXMLImporter``
- ``Score``
- ``Note``
- ``Direction``
- <doc:ImportingFiles>
- <doc:HandlingWarnings>
