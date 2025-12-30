# ``MusicXMLImport``

Parse MusicXML files into Score objects.

## Overview

MusicXMLImport provides `MusicXMLImporter` for loading MusicXML files. It supports both uncompressed `.musicxml` files and compressed `.mxl` archives.

### Basic Import

```swift
let importer = MusicXMLImporter()

// Import from URL
let score = try importer.importScore(from: musicXMLURL)

// Import from Data
let score = try importer.importScore(from: musicXMLData)
```

### Import Options

Configure import behavior with `ImportOptions`:

```swift
var options = ImportOptions.default

// Strict version checking (reject unsupported versions)
options.strictVersionCheck = true

// Preserve original context for round-trip export
options.preserveOriginalContext = true

let importer = MusicXMLImporter(options: options)
```

### Handling Warnings

The importer collects non-fatal warnings during parsing:

```swift
let importer = MusicXMLImporter()
let score = try importer.importScore(from: url)

// Check for warnings
for warning in importer.warnings {
    print("Warning: \(warning)")
}
```

### Error Handling

Handle specific import errors:

```swift
do {
    let score = try importer.importScore(from: url)
} catch let error as MusicXMLError {
    switch error {
    case .invalidFileFormat(let message):
        print("Invalid format: \(message)")
    case .unsupportedVersion(let version):
        print("Unsupported version: \(version)")
    case .invalidXMLStructure(let message):
        print("Invalid XML: \(message)")
    case .parsingError(let message):
        print("Parsing error: \(message)")
    }
}
```

### Supported Features

MusicXMLImport supports:

- **Score Structure**: Partwise and timewise formats
- **Notes**: Pitched, unpitched, and rest notes with full duration support
- **Attributes**: Clefs, key signatures, time signatures, divisions
- **Notations**: Ties, slurs, beams, tuplets, articulations, dynamics
- **Directions**: Dynamics, wedges, tempo markings, rehearsal marks
- **Barlines**: All bar styles, repeats, endings
- **Percussion**: Unpitched notes with instrument mapping
- **Metadata**: Work/movement titles, creators, credits

### Format Detection

The importer automatically detects the file format:

```swift
// Handles all formats automatically
let score = try importer.importScore(from: url)

// Works with:
// - .musicxml (partwise or timewise)
// - .mxl (compressed archive)
// - .xml (legacy extension)
```

## Topics

### Import

- ``MusicXMLImporter``
- ``ImportOptions``

### Understanding Import

- <doc:ImportInternals>
- <doc:SupportedFeatures>
- <doc:HandlingWarnings>

### Element Mapping

- ``NoteMapper``
- ``AttributesMapper``
- ``DirectionMapper``

### Spanner Resolution

- ``BeamGrouper``
- ``SlurTracker``
- ``TieTracker``
- ``TupletParser``

### Errors

- ``MusicXMLError``
- ``MusicXMLWarning``
