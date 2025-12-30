# Glyph Mapping

Access musical symbols using standardized SMuFL glyph names.

@Metadata {
    @PageKind(article)
}

## Overview

SMuFL (Standard Music Font Layout) defines canonical names for every musical symbol, ensuring fonts are interchangeable. SMuFLKit provides the ``SMuFLGlyphName`` enum that maps these standardized names to their Unicode code points, making it easy to look up and render any musical glyph.

## The SMuFL Code Point System

SMuFL glyphs use Unicode's Private Use Area (PUA), specifically:

| Range | Category |
|-------|----------|
| U+E000–U+E02F | Brackets, braces, system dividers |
| U+E030–U+E04F | Barlines and repeats |
| U+E050–U+E07F | Clefs |
| U+E080–U+E09F | Time signature components |
| U+E0A0–U+E0FF | Noteheads |
| U+E1E7 | Augmentation dot |
| U+E210–U+E21F | Stems |
| U+E220–U+E23F | Tremolos |
| U+E240–U+E25F | Flags |
| U+E260–U+E4FF | Accidentals, articulations, rests |
| U+E520–U+E54F | Dynamics |
| U+E560–U+E59F | Ornaments |
| U+E880–U+E88F | Tuplet numbers |

## Looking Up Glyphs by Name

The ``SMuFLGlyphName`` enum provides type-safe access to all standard SMuFL glyphs:

```swift
import SMuFLKit

let font = SMuFLFontManager.shared.currentFont!

// Look up a glyph by its SMuFL name
if let glyph = font.glyph(for: .noteheadBlack) {
    // glyph is a CGGlyph ready for Core Text rendering
}

// Common noteheads
let wholeNote = font.glyph(for: .noteheadWhole)
let halfNote = font.glyph(for: .noteheadHalf)
let quarterNote = font.glyph(for: .noteheadBlack)

// Clefs
let trebleClef = font.glyph(for: .gClef)
let bassClef = font.glyph(for: .fClef)
let altoClef = font.glyph(for: .cClef)
```

## Looking Up Glyphs by Code Point

When you have a raw Unicode code point, you can look up glyphs directly:

```swift
// Look up by Unicode code point
if let glyph = font.glyph(forCodePoint: 0xE0A4) {
    // 0xE0A4 is noteheadBlack
}

// Useful when parsing external data that uses code points
let codePoint: UInt32 = 0xE050  // G clef
if let treble = font.glyph(forCodePoint: codePoint) {
    // Use the glyph
}
```

## Glyph Categories

### Noteheads

SMuFL provides noteheads for different durations and styles:

```swift
// Standard noteheads
SMuFLGlyphName.noteheadDoubleWhole  // Breve
SMuFLGlyphName.noteheadWhole        // Whole note
SMuFLGlyphName.noteheadHalf         // Half note
SMuFLGlyphName.noteheadBlack        // Quarter, eighth, etc.

// Special noteheads
SMuFLGlyphName.noteheadXBlack       // X-shaped (percussion)
SMuFLGlyphName.noteheadDiamondBlack // Diamond (harmonics)
SMuFLGlyphName.noteheadSlashX       // Slash (rhythmic notation)
```

### Clefs

```swift
// G clefs (treble family)
SMuFLGlyphName.gClef      // Standard treble clef
SMuFLGlyphName.gClef8va   // Treble with 8va
SMuFLGlyphName.gClef8vb   // Treble with 8vb
SMuFLGlyphName.gClef15ma  // Treble with 15ma
SMuFLGlyphName.gClef15mb  // Treble with 15mb

// F clefs (bass family)
SMuFLGlyphName.fClef      // Standard bass clef
SMuFLGlyphName.fClef8va   // Bass with 8va
SMuFLGlyphName.fClef8vb   // Bass with 8vb

// C clefs
SMuFLGlyphName.cClef      // Alto/tenor clef

// Percussion and tablature
SMuFLGlyphName.unpitchedPercussionClef1
SMuFLGlyphName.sixStringTabClef
```

### Time Signatures

Build time signatures from individual digit glyphs:

```swift
// Digits 0-9
let digits: [SMuFLGlyphName] = [
    .timeSig0, .timeSig1, .timeSig2, .timeSig3, .timeSig4,
    .timeSig5, .timeSig6, .timeSig7, .timeSig8, .timeSig9
]

// Special symbols
SMuFLGlyphName.timeSigCommon     // Common time (C)
SMuFLGlyphName.timeSigCutCommon  // Cut time (C with line)
SMuFLGlyphName.timeSigPlus       // For additive meters
```

### Accidentals

```swift
// Standard accidentals
SMuFLGlyphName.accidentalFlat
SMuFLGlyphName.accidentalNatural
SMuFLGlyphName.accidentalSharp
SMuFLGlyphName.accidentalDoubleFlat
SMuFLGlyphName.accidentalDoubleSharp

// Microtonal (Stein-Zimmermann)
SMuFLGlyphName.accidentalQuarterToneSharpStein
SMuFLGlyphName.accidentalQuarterToneFlatStein

// Parentheses for cautionary accidentals
SMuFLGlyphName.accidentalParensLeft
SMuFLGlyphName.accidentalParensRight
```

### Flags

```swift
// Stem-up flags
SMuFLGlyphName.flag8thUp
SMuFLGlyphName.flag16thUp
SMuFLGlyphName.flag32ndUp
SMuFLGlyphName.flag64thUp
SMuFLGlyphName.flag128thUp

// Stem-down flags
SMuFLGlyphName.flag8thDown
SMuFLGlyphName.flag16thDown
SMuFLGlyphName.flag32ndDown
SMuFLGlyphName.flag64thDown
SMuFLGlyphName.flag128thDown
```

### Rests

```swift
SMuFLGlyphName.restDoubleWhole  // Breve rest
SMuFLGlyphName.restWhole        // Whole rest
SMuFLGlyphName.restHalf         // Half rest
SMuFLGlyphName.restQuarter      // Quarter rest
SMuFLGlyphName.rest8th          // Eighth rest
SMuFLGlyphName.rest16th         // Sixteenth rest
SMuFLGlyphName.rest32nd         // Thirty-second rest
SMuFLGlyphName.rest64th         // Sixty-fourth rest

// Multi-bar rest components
SMuFLGlyphName.restHBarLeft
SMuFLGlyphName.restHBarMiddle
SMuFLGlyphName.restHBarRight
```

### Dynamics

```swift
// Individual letters for building dynamics
SMuFLGlyphName.dynamicPiano       // p
SMuFLGlyphName.dynamicMezzo       // m
SMuFLGlyphName.dynamicForte       // f
SMuFLGlyphName.dynamicSforzando   // s
SMuFLGlyphName.dynamicRinforzando // r
SMuFLGlyphName.dynamicZ           // z
SMuFLGlyphName.dynamicNiente      // n

// Pre-combined dynamics
SMuFLGlyphName.dynamicPP          // pp
SMuFLGlyphName.dynamicMP          // mp
SMuFLGlyphName.dynamicMF          // mf
SMuFLGlyphName.dynamicFF          // ff
SMuFLGlyphName.dynamicFortePiano  // fp
SMuFLGlyphName.dynamicSforzato    // sfz

// Hairpins
SMuFLGlyphName.dynamicCrescendoHairpin
SMuFLGlyphName.dynamicDiminuendoHairpin
```

### Articulations

```swift
// Above-note articulations
SMuFLGlyphName.articAccentAbove
SMuFLGlyphName.articStaccatoAbove
SMuFLGlyphName.articTenutoAbove
SMuFLGlyphName.articMarcatoAbove

// Below-note articulations
SMuFLGlyphName.articAccentBelow
SMuFLGlyphName.articStaccatoBelow
SMuFLGlyphName.articTenutoBelow
SMuFLGlyphName.articMarcatoBelow

// Combined articulations
SMuFLGlyphName.articAccentStaccatoAbove
SMuFLGlyphName.articTenutoStaccatoAbove
SMuFLGlyphName.articMarcatoStaccatoAbove
```

### Ornaments

```swift
SMuFLGlyphName.ornamentTrill
SMuFLGlyphName.ornamentTurn
SMuFLGlyphName.ornamentTurnInverted
SMuFLGlyphName.ornamentMordent
SMuFLGlyphName.ornamentMordentInverted
SMuFLGlyphName.ornamentShortTrill
```

### Fermatas and Breath Marks

```swift
// Fermatas
SMuFLGlyphName.fermataAbove
SMuFLGlyphName.fermataBelow
SMuFLGlyphName.fermataShortAbove
SMuFLGlyphName.fermataLongAbove
SMuFLGlyphName.fermataVeryLongAbove

// Breath marks
SMuFLGlyphName.breathMarkComma
SMuFLGlyphName.breathMarkTick
SMuFLGlyphName.caesura
```

## Accessing Code Points

Each ``SMuFLGlyphName`` case knows its Unicode code point:

```swift
let glyphName = SMuFLGlyphName.noteheadBlack
let codePoint = glyphName.codePoint  // 0xE0A4

// Convert to Unicode scalar for string operations
if let scalar = UnicodeScalar(codePoint) {
    let character = Character(scalar)
    let string = String(character)
}
```

## Iterating All Glyphs

``SMuFLGlyphName`` conforms to `CaseIterable`, allowing iteration:

```swift
// Count available glyphs
let totalGlyphs = SMuFLGlyphName.allCases.count

// Find all dynamics
let dynamics = SMuFLGlyphName.allCases.filter {
    $0.rawValue.hasPrefix("dynamic")
}

// Check if a font supports all required glyphs
let requiredGlyphs: [SMuFLGlyphName] = [
    .noteheadBlack, .noteheadHalf, .noteheadWhole,
    .gClef, .fClef,
    .restQuarter, .rest8th
]

let unsupported = requiredGlyphs.filter { font.glyph(for: $0) == nil }
if unsupported.isEmpty {
    print("Font supports all required glyphs")
}
```

## Glyph Caching

``LoadedSMuFLFont`` automatically caches glyph lookups for performance:

```swift
// First lookup: performs Core Text query
let glyph1 = font.glyph(for: .noteheadBlack)

// Subsequent lookups: returns cached value (instant)
let glyph2 = font.glyph(for: .noteheadBlack)
```

This caching is thread-safe and transparent to your code.

## See Also

- ``SMuFLGlyphName``
- ``LoadedSMuFLFont``
- <doc:LoadingFonts>
- <doc:FontMetadata>
