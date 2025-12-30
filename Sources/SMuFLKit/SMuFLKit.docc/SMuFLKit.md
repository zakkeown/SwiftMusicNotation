# ``SMuFLKit``

SMuFL font loading and glyph management for music notation.

## Overview

SMuFLKit handles loading and working with SMuFL (Standard Music Font Layout) compliant fonts. SMuFL is a specification for music fonts that assigns consistent Unicode code points to musical symbols.

### Loading Fonts

Use `SMuFLFontManager` to load and manage fonts:

```swift
let fontManager = SMuFLFontManager.shared

// Load the bundled Bravura font
let font = try fontManager.loadFont(named: "Bravura")

// Set as current font for rendering
fontManager.setCurrentFont(named: "Bravura")

// Access the current font
if let currentFont = fontManager.currentFont {
    let scaledFont = currentFont.font(forStaffHeight: 40)
}
```

### Bundled Fonts

SMuFLKit includes the Bravura font and its metadata. Bravura is a comprehensive SMuFL font suitable for professional music engraving.

### Glyph Names

SMuFL defines standard names for musical symbols. Use `SMuFLGlyphName` to reference glyphs:

```swift
// Common glyphs
let trebleClef = SMuFLGlyphName.gClef
let quarterNote = SMuFLGlyphName.noteheadBlack
let sharp = SMuFLGlyphName.accidentalSharp

// Get glyph from loaded font
let glyph = font.glyph(for: trebleClef)
```

### Font Metadata

Loaded fonts provide metadata for precise positioning:

```swift
let font: LoadedSMuFLFont = ...

// Get bounding box for a glyph
let bbox = font.boundingBox(for: .gClef)

// Get anchor points
let anchors = font.anchors(for: .noteheadBlack)

// Get advance width
let advance = font.advanceWidth(for: .flag8thUp)
```

### GlyphRepresentable Protocol

Core types conform to `GlyphRepresentable` for automatic glyph mapping:

```swift
// Clef provides its glyph name
let clef = Clef(sign: .g, line: 2)
let glyphName = clef.glyphName  // .gClef

// Time signature numerals
let timeSignature = TimeSignature(beats: "4", beatType: "4")
// Maps to timeSig4 glyphs
```

## Topics

### Font Management

- ``SMuFLFontManager``
- ``LoadedSMuFLFont``
- ``SMuFLFontError``

### Glyph Names

- ``SMuFLGlyphName``

### Font Metadata

- ``SMuFLFontMetadata``
- ``EngravingDefaults``
- ``GlyphMetadata``

### Protocols

- ``GlyphRepresentable``
- ``PlacementGlyphRepresentable``
- ``CompositeGlyphRepresentable``
