# Duration and Rhythm

Understand the rhythmic value system for notes and rests.

@Metadata {
    @PageKind(article)
}

## Overview

SwiftMusicNotation uses a precise system for representing rhythmic durations. This article explains how durations work, including base values, dots, and tuplets.

## Duration Components

A complete ``Duration`` has three components:

1. **Base value** (``DurationBase``): The fundamental note type
2. **Dots**: Augmentation dots that extend the duration
3. **Tuplet ratio** (``TupletRatio``): Optional modification for irregular groupings

```swift
// Simple quarter note
let quarter = Duration(base: .quarter)

// Dotted half note
let dottedHalf = Duration(base: .half, dots: 1)

// Triplet eighth note
let tripletEighth = Duration(base: .eighth, tupletRatio: .triplet)
```

## Base Values

``DurationBase`` defines the fundamental note values:

| Value | Name | Beats (in 4/4) |
|-------|------|----------------|
| `.whole` | Whole note | 4 |
| `.half` | Half note | 2 |
| `.quarter` | Quarter note | 1 |
| `.eighth` | Eighth note | 1/2 |
| `.sixteenth` | Sixteenth note | 1/4 |
| `.thirtySecond` | 32nd note | 1/8 |
| `.sixtyFourth` | 64th note | 1/16 |

### Extended Values

For early music and special notation:

| Value | Name | Beats (in 4/4) |
|-------|------|----------------|
| `.breve` | Double whole | 8 |
| `.longa` | Longa | 16 |
| `.maxima` | Maxima | 32 |

### Very Short Values

For complex modern music:

| Value | Name |
|-------|------|
| `.oneHundredTwentyEighth` | 128th note |
| `.twoHundredFiftySixth` | 256th note |

## Fractional Values

Durations can be expressed as fractions using ``Rational``:

```swift
// As a fraction of a whole note
Duration.quarter.wholeNoteValue      // 1/4
Duration.eighth.wholeNoteValue       // 1/8
Duration.dottedHalf.wholeNoteValue   // 3/4

// As a fraction of a quarter note
Duration.quarter.quarterNoteValue    // 1/1
Duration.eighth.quarterNoteValue     // 1/2
Duration.half.quarterNoteValue       // 2/1
```

## Augmentation Dots

Each dot adds half of the previous value:

```swift
// One dot: 1 + 1/2 = 3/2 of the base
let dottedQuarter = Duration(base: .quarter, dots: 1)
dottedQuarter.quarterNoteValue  // 3/2 (1.5 beats)

// Two dots: 1 + 1/2 + 1/4 = 7/4 of the base
let doubleDottedQuarter = Duration(base: .quarter, dots: 2)
doubleDottedQuarter.quarterNoteValue  // 7/4 (1.75 beats)

// Three dots: 1 + 1/2 + 1/4 + 1/8 = 15/8 of the base
let tripleDottedQuarter = Duration(base: .quarter, dots: 3)
tripleDottedQuarter.quarterNoteValue  // 15/8 (1.875 beats)
```

### Common Dotted Values

```swift
Duration.dottedWhole      // 6 beats
Duration.dottedHalf       // 3 beats
Duration.dottedQuarter    // 1.5 beats
Duration.dottedEighth     // 0.75 beats
Duration.dottedSixteenth  // 0.375 beats
```

## Tuplets

Tuplets modify durations for irregular rhythmic groupings.

### Common Tuplet Ratios

```swift
TupletRatio.triplet     // 3:2 (3 notes in the time of 2)
TupletRatio.duplet      // 2:3 (2 notes in the time of 3)
TupletRatio.quintuplet  // 5:4 (5 notes in the time of 4)
TupletRatio.sextuplet   // 6:4 (6 notes in the time of 4)
TupletRatio.septuplet   // 7:4 (7 notes in the time of 4)
```

### Triplets

The most common tuplet—3 notes in the time of 2:

```swift
// Triplet eighth notes
let tripletEighth = Duration(base: .eighth, tupletRatio: .triplet)

// Each triplet eighth = 2/3 of a regular eighth
tripletEighth.quarterNoteValue  // 1/3 (three fit in one beat)
```

### Duplets

Used in compound meter—2 notes in the time of 3:

```swift
// Duplet eighths in 6/8
let dupletEighth = Duration(base: .eighth, tupletRatio: .duplet)

// Each duplet eighth = 3/2 of a regular eighth
dupletEighth.quarterNoteValue  // 3/4
```

### Custom Tuplets

Create any ratio:

```swift
// 5 notes in the time of 4
let quintuplet = TupletRatio(actual: 5, normal: 4)

// 7 notes in the time of 6
let septupletSix = TupletRatio(actual: 7, normal: 6)

// With specific note types
let customTuplet = TupletRatio(
    actual: 5,
    normal: 3,
    actualType: .sixteenth,
    normalType: .eighth
)
```

### Nested Tuplets

Tuplets can nest (though uncommon):

```swift
// A triplet within a triplet
// First, create the outer triplet ratio
let outerRatio = TupletRatio.triplet

// Then apply another triplet to that
// Result: 1/9 of the original duration
```

## MusicXML Divisions

MusicXML uses "divisions" to represent timing. The divisions value indicates how many units equal one quarter note.

```swift
// Convert duration to divisions
let divisions = 2  // 2 divisions per quarter
let quarterDivs = Duration.quarter.divisions(perQuarter: divisions)  // 2
let eighthDivs = Duration.eighth.divisions(perQuarter: divisions)    // 1
let halfDivs = Duration.half.divisions(perQuarter: divisions)        // 4

// Convert divisions back to duration
let duration = Duration.from(
    divisions: 3,
    perQuarter: 2,
    type: .quarter,
    dots: 1
)
```

## Beams and Flags

The number of beams/flags depends on the duration:

```swift
DurationBase.quarter.beamCount       // 0 (no beams)
DurationBase.eighth.beamCount        // 1
DurationBase.sixteenth.beamCount     // 2
DurationBase.thirtySecond.beamCount  // 3
DurationBase.sixtyFourth.beamCount   // 4
```

## Duration Comparison

Durations are comparable by their actual length:

```swift
Duration.quarter < Duration.half           // true
Duration.dottedQuarter > Duration.quarter  // true

// With tuplets
let triplet = Duration(base: .quarter, tupletRatio: .triplet)
triplet < Duration.quarter  // true (triplet is shorter)
```

## Practical Examples

### Calculating Measure Duration

```swift
// In 4/4 time, a measure should total 4 quarter notes
let measureDuration = Rational(4, 1)

// Check if notes fill the measure
var total = Rational(0, 1)
for note in measure.notes {
    if let duration = note.duration {
        total = total + duration.quarterNoteValue
    }
}

if total == measureDuration {
    print("Measure is complete")
} else if total < measureDuration {
    print("Measure is short by \(measureDuration - total) beats")
} else {
    print("Measure overflows by \(total - measureDuration) beats")
}
```

### Converting Tempo to Note Duration

```swift
// At 120 BPM, quarter note = 0.5 seconds
let bpm = 120.0
let quarterNoteDuration = 60.0 / bpm  // 0.5 seconds

// An eighth note at 120 BPM
let eighthDuration = quarterNoteDuration * Duration.eighth.quarterNoteValue.doubleValue
// 0.25 seconds
```

## See Also

- ``Duration``
- ``DurationBase``
- ``TupletRatio``
- ``Rational``
