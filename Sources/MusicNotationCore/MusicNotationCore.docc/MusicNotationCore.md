# ``MusicNotationCore``

Domain models for representing music notation.

## Overview

MusicNotationCore provides the fundamental types for representing musical scores. These models form the foundation that all other modules build upon.

### Score Hierarchy

A score follows a hierarchical structure:

```
Score
├── metadata (title, composer, etc.)
├── defaults (page settings, scaling)
├── credits (title text, copyright)
└── parts[]
    ├── name, abbreviation
    ├── instruments
    └── measures[]
        ├── number, attributes
        └── elements[]
            ├── notes (pitched, rest, unpitched)
            ├── directions (dynamics, tempo)
            ├── attributes (clef, key, time)
            └── barlines
```

### Working with Scores

Access parts and measures by index or ID:

```swift
let score: Score = ...

// Access parts
let piano = score.parts[0]
let violin = score.part(withID: "P2")

// Access measures
let firstMeasure = piano.measures[0]
let measure42 = piano.measure(number: "42")

// Get notes from a measure
let notes = firstMeasure.notes
```

### Pitch and Duration

The library provides rich types for musical primitives:

```swift
// Pitch with step, octave, and alteration
let middleC = Pitch(step: .c, octave: 4)
let fSharp = Pitch(step: .f, octave: 4, alter: 1.0)

// Convert to MIDI
let midiNote = middleC.midiNoteNumber  // 60

// Duration types
let quarter = DurationBase.quarter
let dottedHalf = Duration(base: .half, dots: 1)
```

## Topics

### Score Structure

- ``Score``
- ``Part``
- ``Measure``
- ``MeasureElement``

### Notes and Pitches

- ``Note``
- ``Pitch``
- ``PitchStep``
- ``Duration``
- ``DurationBase``
- ``Accidental``

### Measure Attributes

- ``MeasureAttributes``
- ``Clef``
- ``KeySignature``
- ``TimeSignature``

### Notations

- ``Notation``
- ``ArticulationMark``
- ``DynamicMark``
- ``Ornament``
- ``TechnicalMark``

### Spanners

- ``Tie``
- ``SlurNotation``
- ``TupletNotation``
- ``BeamValue``

### Directions

- ``Direction``
- ``DirectionType``
- ``DynamicsDirection``
- ``Wedge``
- ``Metronome``

### Barlines

- ``Barline``
- ``BarStyle``
- ``RepeatDirection``
- ``Ending``

### Metadata

- ``ScoreMetadata``
- ``ScoreDefaults``
- ``Credit``
- ``Creator``

### Percussion

- ``PercussionMap``
- ``PercussionInstrument``
- ``UnpitchedNote``

### Articles

- <doc:ScoreHierarchy>
- <doc:WorkingWithNotes>
- <doc:DurationAndRhythm>
