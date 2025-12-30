# Loading Fonts

Load and manage SMuFL-compliant music notation fonts.

@Metadata {
    @PageKind(article)
}

## Overview

SMuFLKit provides a centralized system for loading and managing SMuFL fonts through ``SMuFLFontManager``. This article covers how to load fonts from your app bundle, switch between fonts, and access font instances for rendering.

## What is SMuFL?

SMuFL (Standard Music Font Layout) is a specification that ensures music notation fonts are interchangeable. It defines:

- **Standardized glyph names**: Every musical symbol has a canonical name
- **Unicode code points**: Glyphs use Private Use Area (U+E000–U+F8FF)
- **Metadata format**: JSON files describe glyph metrics and positioning
- **Engraving defaults**: Recommended values for line thicknesses and spacing

Popular SMuFL fonts include Bravura (bundled with SwiftMusicNotation), Petaluma, Leland, Finale Maestro, and Sebastian.

## Loading the Bundled Font

SMuFLKit includes the Bravura font and its metadata. Load it using the shared manager:

```swift
import SMuFLKit

do {
    let font = try SMuFLFontManager.shared.loadFont(named: "Bravura")
    print("Loaded \(font.name)")
} catch {
    print("Failed to load font: \(error)")
}
```

The font is automatically registered with Core Text and becomes the `currentFont`.

## Loading Custom Fonts

To use a different SMuFL font, add these files to your app bundle:

1. **Font file**: `FontName.otf` or `FontName.ttf`
2. **Metadata file**: `fontname_metadata.json` (lowercase)

Then load the font by name:

```swift
do {
    let font = try SMuFLFontManager.shared.loadFont(
        named: "Petaluma",
        from: Bundle.main
    )
    print("Loaded custom font: \(font.name)")
} catch let error as SMuFLFontError {
    switch error {
    case .fontFileNotFound(let name):
        print("Font file not found: \(name).otf or .ttf")
    case .metadataFileNotFound(let name):
        print("Metadata not found (optional): \(name)_metadata.json")
    case .fontRegistrationFailed(let name, let underlying):
        print("Core Text failed to register \(name): \(underlying?.localizedDescription ?? "")")
    default:
        print("Font error: \(error)")
    }
}
```

## Switching Between Fonts

Load multiple fonts and switch between them without reloading:

```swift
// Load fonts at app startup
try SMuFLFontManager.shared.loadFont(named: "Bravura")
try SMuFLFontManager.shared.loadFont(named: "Petaluma")
try SMuFLFontManager.shared.loadFont(named: "Leland")

// Check what's loaded
let available = SMuFLFontManager.shared.loadedFontNames
print("Available fonts: \(available)")

// Switch to a different font
try SMuFLFontManager.shared.setCurrentFont(named: "Petaluma")

// Access the current font
if let font = SMuFLFontManager.shared.currentFont {
    print("Now using: \(font.name)")
}
```

## Creating Sized Font Instances

SMuFL fonts are designed so that 1 em (font size) equals 4 staff spaces. To create a `CTFont` for a specific staff height:

```swift
let font = SMuFLFontManager.shared.currentFont!

// Create a font for a 40-point staff height
let ctFont = font.font(forStaffHeight: 40)

// The font size equals the staff height
let fontSize = CTFontGetSize(ctFont)  // 40.0

// Use with Core Text for drawing
var glyph = font.glyph(for: .noteheadBlack)!
var position = CGPoint(x: 100, y: 200)
CTFontDrawGlyphs(ctFont, &glyph, &position, 1, context)
```

## Font Caching

Loaded fonts are cached by the manager. Subsequent calls to `loadFont(named:)` return the cached instance:

```swift
// First call: loads from disk and registers with Core Text
let font1 = try SMuFLFontManager.shared.loadFont(named: "Bravura")

// Second call: returns cached instance (instant)
let font2 = try SMuFLFontManager.shared.loadFont(named: "Bravura")

// Same instance
assert(font1 === font2)
```

## Thread Safety

``SMuFLFontManager`` is thread-safe. Font loading operations are serialized internally using a lock:

```swift
// Safe to call from any thread
Task.detached {
    let font = try SMuFLFontManager.shared.loadFont(named: "Bravura")
}
```

However, ``LoadedSMuFLFont`` instances and `CTFont` rendering should typically happen on the main thread or a dedicated rendering thread.

## Error Handling

Handle font loading errors to provide fallback behavior:

```swift
func loadPreferredFont(name: String) -> LoadedSMuFLFont? {
    do {
        return try SMuFLFontManager.shared.loadFont(named: name)
    } catch SMuFLFontError.fontFileNotFound {
        // Try bundled Bravura as fallback
        return try? SMuFLFontManager.shared.loadFont(named: "Bravura")
    } catch {
        print("Font loading failed: \(error)")
        return nil
    }
}
```

## See Also

- ``SMuFLFontManager``
- ``LoadedSMuFLFont``
- ``SMuFLFontError``
- <doc:GlyphMapping>
- <doc:FontMetadata>
