# Understanding the Score Hierarchy

Navigate the tree structure of musical scores.

@Metadata {
    @PageKind(article)
}

## Overview

A musical score is organized as a tree of nested containers. Understanding this hierarchy is essential for navigating and manipulating scores programmatically.

## The Hierarchy

```
Score
├── metadata: ScoreMetadata
│   ├── workTitle: "Symphony No. 5"
│   ├── movementTitle: "Allegro con brio"
│   └── creators: [Creator]
│
├── defaults: ScoreDefaults
│   ├── scaling: Scaling
│   └── pageSettings: PageSettings
│
├── credits: [Credit]
│   └── creditWords: [CreditWords]
│
└── parts: [Part]
    ├── id: "P1"
    ├── name: "Violin I"
    ├── staffCount: 1
    ├── instruments: [Instrument]
    │
    └── measures: [Measure]
        ├── number: "1"
        ├── attributes: MeasureAttributes?
        │   ├── clefs: [Clef]
        │   ├── key: KeySignature?
        │   └── time: TimeSignature?
        │
        └── elements: [MeasureElement]
            ├── .note(Note)
            ├── .direction(Direction)
            ├── .attributes(MeasureAttributes)
            ├── .harmony(Harmony)
            └── .barline(Barline)
```

## Navigating the Score

### Accessing Parts

Parts are the top-level containers for individual instruments or voices:

```swift
// By index
let firstPart = score.parts[0]

// By ID (MusicXML part ID)
if let violin = score.part(withID: "P1") {
    print(violin.name)  // "Violin I"
}

// Iterate all parts
for part in score.parts {
    print("\(part.name): \(part.measures.count) measures")
}
```

### Accessing Measures

Measures (bars) contain the actual musical content:

```swift
// By index
let measure = part.measures[0]

// By measure number (string for flexibility)
if let pickup = part.measure(number: "0") {
    print("Has anacrusis")
}

// Measure properties
print("Measure \(measure.number)")
print("Implicit: \(measure.implicit)")  // Pickup measure?
```

### Accessing Elements

Measure elements are accessed through pattern matching:

```swift
for element in measure.elements {
    switch element {
    case .note(let note):
        if let pitch = note.pitch {
            print("Note: \(pitch)")
        } else if note.isRest {
            print("Rest")
        }

    case .direction(let direction):
        switch direction.type {
        case .dynamics(let dyn):
            print("Dynamic: \(dyn)")
        case .metronome(let tempo):
            print("Tempo: \(tempo.perMinute) BPM")
        default:
            break
        }

    case .attributes(let attrs):
        if let clef = attrs.clefs.first {
            print("Clef: \(clef.sign)")
        }

    case .harmony(let chord):
        print("Chord: \(chord.root.step)\(chord.kind)")

    default:
        break
    }
}
```

### Filtering by Voice

In polyphonic music, elements belong to different voices:

```swift
// Get soprano line (voice 1)
let soprano = measure.elements(forVoice: 1)

// Get alto line (voice 2)
let alto = measure.elements(forVoice: 2)
```

### Filtering by Staff

For multi-staff parts like piano:

```swift
// Treble staff (staff 1)
let treble = measure.elements(forStaff: 1)

// Bass staff (staff 2)
let bass = measure.elements(forStaff: 2)
```

### Getting All Notes

The `notes` property provides quick access to all notes in a measure:

```swift
let allNotes = measure.notes  // [Note]

for note in allNotes {
    if let pitch = note.pitch {
        print("\(pitch.step)\(pitch.octave)")
    }
}
```

## Multi-Staff Parts

Some instruments use multiple staves (piano, organ, harp):

```swift
let piano = Part(
    id: "P1",
    name: "Piano",
    staffCount: 2  // Two staves
)

// Notes specify their staff
let rightHand = Note(
    noteType: .pitched(Pitch(step: .c, octave: 5)),
    durationDivisions: 1,
    type: .quarter,
    staff: 1  // Treble staff
)

let leftHand = Note(
    noteType: .pitched(Pitch(step: .c, octave: 3)),
    durationDivisions: 1,
    type: .quarter,
    staff: 2  // Bass staff
)
```

## Score Metadata

Access bibliographic information:

```swift
let metadata = score.metadata

// Work info
print(metadata.workTitle ?? "Untitled")
print(metadata.workNumber ?? "")  // e.g., "Op. 67"

// Movement info
print(metadata.movementTitle ?? "")
print(metadata.movementNumber ?? "")

// Creators
for creator in metadata.creators {
    print("\(creator.type ?? "creator"): \(creator.name)")
}

// Rights/copyright
for right in metadata.rights {
    print(right)
}
```

## Score Defaults

Access layout and scaling information:

```swift
if let defaults = score.defaults {
    // Scaling
    if let scaling = defaults.scaling {
        let pointsPerTenth = scaling.toPoints(1)
        print("1 tenth = \(pointsPerTenth) points")
    }

    // Page settings
    if let page = defaults.pageSettings {
        print("Page: \(page.pageWidth ?? 0) x \(page.pageHeight ?? 0) tenths")
    }

    // Concert vs. transposed
    print("Concert score: \(defaults.concertScore)")
}
```

## Credits

Credits appear on the rendered score (title, composer, copyright):

```swift
for credit in score.credits {
    print("Page \(credit.page ?? 1): \(credit.creditType ?? "text")")
    for words in credit.creditWords {
        print("  \(words.text)")
    }
}
```

## See Also

- ``Score``
- ``Part``
- ``Measure``
- ``MeasureElement``
