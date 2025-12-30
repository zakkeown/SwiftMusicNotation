# Importing Files

Load MusicXML files from URLs, data, and compressed archives.

@Metadata {
    @PageKind(article)
}

## Overview

``MusicXMLImporter`` provides a simple API for loading MusicXML files in any format. The importer automatically detects whether files are compressed `.mxl` archives or uncompressed XML, and handles both partwise and timewise MusicXML structures transparently.

## Importing from a URL

The most common way to import is from a file URL:

```swift
import MusicXMLImport

let importer = MusicXMLImporter()

do {
    let score = try importer.importScore(from: fileURL)
    print("Imported '\(score.metadata.workTitle ?? "Untitled")'")
    print("Parts: \(score.parts.count)")
    print("Measures: \(score.measureCount)")
} catch {
    print("Import failed: \(error)")
}
```

The importer accepts any of these file extensions:
- `.musicxml` - Standard MusicXML files
- `.mxl` - Compressed MusicXML archives
- `.xml` - Legacy XML files

## Importing from Data

When you have MusicXML content in memory (e.g., downloaded from a server), import directly from `Data`:

```swift
// Download from a server
let (data, _) = try await URLSession.shared.data(from: serverURL)

let importer = MusicXMLImporter()
let score = try importer.importScore(from: data)
```

This works with both compressed and uncompressed content.

## Supported Formats

MusicXML files come in three formats, all handled automatically:

### Partwise Format

The most common format, where the document is organized by parts:

```xml
<score-partwise version="4.0">
  <part id="P1">
    <measure number="1">...</measure>
    <measure number="2">...</measure>
  </part>
  <part id="P2">
    <measure number="1">...</measure>
    <measure number="2">...</measure>
  </part>
</score-partwise>
```

### Timewise Format

An alternative organization by measures:

```xml
<score-timewise version="4.0">
  <measure number="1">
    <part id="P1">...</part>
    <part id="P2">...</part>
  </measure>
  <measure number="2">
    <part id="P1">...</part>
    <part id="P2">...</part>
  </measure>
</score-timewise>
```

### Compressed Format (.mxl)

A ZIP archive containing:
- `META-INF/container.xml` - Points to the main MusicXML file
- The main MusicXML document (usually partwise)
- Optional media files (images, audio)

The importer extracts and parses compressed archives automatically:

```swift
// Works the same for .mxl files
let score = try importer.importScore(from: mxlFileURL)
```

## Format Detection

The ``FormatDetector`` identifies file formats automatically:

```swift
let detector = FormatDetector()

// Detect from URL (uses extension and content)
let format = try detector.detectFormat(at: fileURL)

// Detect from Data (examines content)
let format = detector.detectFormat(from: data)

switch format {
case .partwise:
    print("Uncompressed partwise MusicXML")
case .timewise:
    print("Uncompressed timewise MusicXML")
case .compressed:
    print("Compressed .mxl archive")
case .unknown:
    print("Unrecognized format")
}
```

## Version Support

MusicXMLImport supports MusicXML versions 1.0 through 4.0. By default, version checking is lenient:

```swift
// Default: accepts any version
let importer = MusicXMLImporter()
let score = try importer.importScore(from: url)
```

For strict version enforcement:

```swift
var options = ImportOptions.default
options.strictVersionCheck = true

let importer = MusicXMLImporter(options: options)

do {
    let score = try importer.importScore(from: url)
} catch MusicXMLError.unsupportedVersion(let version) {
    print("Unsupported MusicXML version: \(version)")
}
```

## Import Options

Configure import behavior with ``ImportOptions``:

```swift
var options = ImportOptions.default

// Reject unsupported MusicXML versions
options.strictVersionCheck = true

// Preserve original XML context for better round-trip export
options.preserveOriginalContext = true

let importer = MusicXMLImporter(options: options)
```

### Available Options

| Option | Default | Description |
|--------|---------|-------------|
| `strictVersionCheck` | `false` | Reject unsupported MusicXML versions |
| `preserveOriginalContext` | `false` | Store extra context for round-trip export |

## Working with the Score

After import, you get a fully populated `Score` object:

```swift
let score = try importer.importScore(from: url)

// Access metadata
let title = score.metadata.workTitle
let composer = score.metadata.creators.first { $0.type == "composer" }?.name

// Iterate parts
for part in score.parts {
    print("\(part.name): \(part.measures.count) measures")

    // Iterate measures
    for measure in part.measures {
        for element in measure.elements {
            switch element {
            case .note(let note):
                // Process notes
                break
            case .attributes(let attrs):
                // Process clefs, key/time signatures
                break
            case .direction(let direction):
                // Process dynamics, tempo marks
                break
            default:
                break
            }
        }
    }
}
```

## Thread Safety

``MusicXMLImporter`` is not thread-safe. For concurrent imports, use separate instances:

```swift
// Safe: separate importers for concurrent use
await withTaskGroup(of: Score?.self) { group in
    for url in fileURLs {
        group.addTask {
            let importer = MusicXMLImporter()  // New instance per task
            return try? importer.importScore(from: url)
        }
    }
}
```

## See Also

- ``MusicXMLImporter``
- ``ImportOptions``
- ``MusicXMLFormat``
- <doc:HandlingWarnings>
- <doc:SupportedFeatures>
