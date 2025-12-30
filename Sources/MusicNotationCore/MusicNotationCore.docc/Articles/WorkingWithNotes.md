# Working with Notes

Create, inspect, and manipulate notes, rests, and chords.

@Metadata {
    @PageKind(article)
}

## Overview

Notes are the fundamental elements of music notation. The ``Note`` type represents pitched notes, unpitched (percussion) notes, and rests—all in a unified structure.

## Note Types

Every note has a `noteType` that defines its content:

```swift
// Pitched note (most common)
let c4 = Note(
    noteType: .pitched(Pitch(step: .c, octave: 4)),
    durationDivisions: 1,
    type: .quarter
)

// Rest
let quarterRest = Note(
    noteType: .rest(RestInfo()),
    durationDivisions: 1,
    type: .quarter
)

// Unpitched (percussion)
let snare = Note(
    noteType: .unpitched(UnpitchedNote(
        displayStep: .c,
        displayOctave: 5
    )),
    durationDivisions: 1,
    type: .quarter
)
```

## Checking Note Content

Use convenience properties to check what kind of note you have:

```swift
if let pitch = note.pitch {
    // It's a pitched note
    print("\(pitch.step)\(pitch.octave)")
} else if note.isRest {
    // It's a rest
    print("Rest")
} else if let unpitched = note.unpitched {
    // It's a percussion note
    print("Display position: \(unpitched.displayStep)\(unpitched.displayOctave)")
}
```

## Creating Pitched Notes

### Basic Notes

```swift
// Middle C, quarter note
let middleC = Note(
    noteType: .pitched(Pitch(step: .c, octave: 4)),
    durationDivisions: 1,
    type: .quarter
)

// F#5, eighth note with stem down
let fSharp = Note(
    noteType: .pitched(Pitch(step: .f, alter: 1, octave: 5)),
    durationDivisions: 1,
    type: .eighth,
    stemDirection: .down
)
```

### Dotted Notes

```swift
// Dotted half note
let dottedHalf = Note(
    noteType: .pitched(Pitch(step: .g, octave: 4)),
    durationDivisions: 3,  // 3 quarters
    type: .half,
    dots: 1
)

// Double-dotted quarter
let doubleDotted = Note(
    noteType: .pitched(Pitch(step: .a, octave: 4)),
    durationDivisions: 7,  // 7 eighths
    type: .quarter,
    dots: 2
)
```

### Notes with Accidentals

```swift
// Show a sharp (even if already in key)
let cautionarySharp = Note(
    noteType: .pitched(Pitch(step: .f, alter: 1, octave: 4)),
    durationDivisions: 1,
    type: .quarter,
    accidental: AccidentalMark(
        accidental: .sharp,
        cautionary: true
    )
)

// Editorial natural in parentheses
let editorial = Note(
    noteType: .pitched(Pitch(step: .b, octave: 4)),
    durationDivisions: 1,
    type: .quarter,
    accidental: AccidentalMark(
        accidental: .natural,
        parentheses: true,
        editorial: true
    )
)
```

## Chords

Chord tones share the same rhythmic position. The first note establishes the position; subsequent notes are marked as chord tones:

```swift
// C major chord
let cNote = Note(
    noteType: .pitched(Pitch(step: .c, octave: 4)),
    durationDivisions: 1,
    type: .quarter
)

let eNote = Note(
    noteType: .pitched(Pitch(step: .e, octave: 4)),
    durationDivisions: 1,
    type: .quarter,
    isChordTone: true  // Same position as C
)

let gNote = Note(
    noteType: .pitched(Pitch(step: .g, octave: 4)),
    durationDivisions: 1,
    type: .quarter,
    isChordTone: true  // Same position as C
)

// Add to measure in order
measure.elements.append(.note(cNote))
measure.elements.append(.note(eNote))
measure.elements.append(.note(gNote))
```

## Grace Notes

Grace notes precede the main note and have no rhythmic duration:

```swift
// Acciaccatura (slashed grace note)
let acciaccatura = Note(
    noteType: .pitched(Pitch(step: .d, octave: 5)),
    durationDivisions: 0,  // No duration
    type: .eighth,
    grace: GraceNote(slash: true)
)

// Appoggiatura (unslashed grace note)
let appoggiatura = Note(
    noteType: .pitched(Pitch(step: .e, octave: 5)),
    durationDivisions: 0,
    type: .eighth,
    grace: GraceNote(slash: false)
)

// Check if it's a grace note
if note.isGraceNote {
    print("Grace note")
}
```

## Rests

### Simple Rests

```swift
let quarterRest = Note(
    noteType: .rest(RestInfo()),
    durationDivisions: 1,
    type: .quarter
)
```

### Measure Rests

Whole measure rests are positioned at the center of the measure:

```swift
let measureRest = Note(
    noteType: .rest(RestInfo(measureRest: true)),
    durationDivisions: 4,  // Full 4/4 measure
    type: .whole
)
```

### Positioned Rests

Rests can be positioned on specific staff lines:

```swift
let positionedRest = Note(
    noteType: .rest(RestInfo(
        displayStep: .b,
        displayOctave: 4
    )),
    durationDivisions: 1,
    type: .quarter
)
```

## Voice and Staff Assignment

### Multiple Voices

In polyphonic music, notes belong to different voices:

```swift
// Voice 1 (soprano)
let soprano = Note(
    noteType: .pitched(Pitch(step: .e, octave: 5)),
    durationDivisions: 2,
    type: .half,
    voice: 1,
    stemDirection: .up
)

// Voice 2 (alto)
let alto = Note(
    noteType: .pitched(Pitch(step: .c, octave: 5)),
    durationDivisions: 2,
    type: .half,
    voice: 2,
    stemDirection: .down
)
```

### Multiple Staves

For instruments like piano, notes specify their staff:

```swift
// Right hand (staff 1)
let rightHand = Note(
    noteType: .pitched(Pitch(step: .g, octave: 5)),
    durationDivisions: 1,
    type: .quarter,
    staff: 1
)

// Left hand (staff 2)
let leftHand = Note(
    noteType: .pitched(Pitch(step: .c, octave: 3)),
    durationDivisions: 1,
    type: .quarter,
    staff: 2
)
```

## Notations

Notes can have various notations attached:

```swift
var note = Note(
    noteType: .pitched(Pitch(step: .c, octave: 4)),
    durationDivisions: 1,
    type: .quarter,
    notations: [
        // Staccato
        .articulations([
            ArticulationMark(type: "staccato", placement: .above)
        ]),
        // Slur start
        .slur(SlurNotation(type: .start, number: 1)),
        // Fermata
        .fermata(Fermata(shape: .normal, type: .upright))
    ]
)
```

### Articulations

```swift
// Common articulations
let staccato = ArticulationMark(type: "staccato", placement: .above)
let accent = ArticulationMark(type: "accent", placement: .above)
let tenuto = ArticulationMark(type: "tenuto", placement: .below)
```

### Ties

Ties connect notes of the same pitch:

```swift
// First note: tie start
let tiedNote1 = Note(
    noteType: .pitched(Pitch(step: .c, octave: 4)),
    durationDivisions: 2,
    type: .half,
    ties: [Tie(type: .start)],
    notations: [.tied(TiedNotation(type: .start))]
)

// Second note: tie stop
let tiedNote2 = Note(
    noteType: .pitched(Pitch(step: .c, octave: 4)),
    durationDivisions: 2,
    type: .half,
    ties: [Tie(type: .stop)],
    notations: [.tied(TiedNotation(type: .stop))]
)
```

## Beams

Beaming information is stored per note:

```swift
// First eighth note: beam begins
let first = Note(
    noteType: .pitched(Pitch(step: .c, octave: 4)),
    durationDivisions: 1,
    type: .eighth,
    beams: [BeamValue(number: 1, value: .begin)]
)

// Middle eighth note: beam continues
let middle = Note(
    noteType: .pitched(Pitch(step: .d, octave: 4)),
    durationDivisions: 1,
    type: .eighth,
    beams: [BeamValue(number: 1, value: .continue)]
)

// Last eighth note: beam ends
let last = Note(
    noteType: .pitched(Pitch(step: .e, octave: 4)),
    durationDivisions: 1,
    type: .eighth,
    beams: [BeamValue(number: 1, value: .end)]
)
```

## Lyrics

Attach lyrics to notes:

```swift
let note = Note(
    noteType: .pitched(Pitch(step: .c, octave: 4)),
    durationDivisions: 1,
    type: .quarter,
    lyrics: [
        Lyric(
            number: "1",
            text: "Hel",
            syllabic: .begin  // First syllable of "Hello"
        ),
        Lyric(
            number: "2",
            text: "World",
            syllabic: .single  // Single-syllable word
        )
    ]
)
```

## See Also

- ``Note``
- ``Pitch``
- ``Duration``
- ``Notation``
