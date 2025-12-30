# Exporting Scores

Serialize Score objects to MusicXML files for sharing and interoperability.

@Metadata {
    @PageKind(article)
}

## Overview

``MusicXMLExporter`` converts `Score` objects back to MusicXML format, enabling you to save user-created or modified scores to files, share them with other applications, or upload them to servers.

## Basic Export

Export a score to a file URL:

```swift
import MusicXMLExport

let exporter = MusicXMLExporter()

// Export to a file
let outputURL = documentsDirectory.appendingPathComponent("score.musicxml")
try exporter.export(score, to: outputURL)
```

## Export Formats

### To File

The most common export writes directly to a file URL:

```swift
let outputURL = FileManager.default.urls(
    for: .documentDirectory,
    in: .userDomainMask
).first!.appendingPathComponent("my-score.musicxml")

try exporter.export(score, to: outputURL)
```

### To String

Get the MusicXML as a string for inspection or further processing:

```swift
let xmlString = try exporter.exportToString(score)

// Inspect the output
print("Generated \(xmlString.count) characters of XML")

// Or process further
let processedXML = customTransform(xmlString)
```

### To Data

Export as `Data` for network uploads or custom storage:

```swift
let xmlData = try exporter.export(score)

// Upload to a server
try await URLSession.shared.upload(for: request, from: xmlData)

// Or store in a database
try database.storeScore(xmlData, forId: scoreId)
```

### Compressed (.mxl)

Export as a compressed MXL archive for smaller file sizes:

```swift
let mxlURL = outputDirectory.appendingPathComponent("score.mxl")
try exporter.exportCompressed(score, to: mxlURL)
```

> Note: Full MXL compression is planned for a future version. Currently this writes uncompressed MusicXML.

## Output Format

The exporter generates partwise MusicXML (the most common format) with the following structure:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 4.0 Partwise//EN"
    "http://www.musicxml.org/dtds/partwise.dtd">
<score-partwise version="4.0">
    <work>
        <work-title>My Score</work-title>
    </work>
    <identification>
        <creator type="composer">J. S. Bach</creator>
        <encoding>
            <software>SwiftMusicNotation</software>
            <encoding-date>2025-01-15</encoding-date>
        </encoding>
    </identification>
    <defaults>...</defaults>
    <credit>...</credit>
    <part-list>...</part-list>
    <part id="P1">
        <measure number="1">...</measure>
        ...
    </part>
</score-partwise>
```

## Export Workflow

A typical export workflow:

```swift
import MusicXMLExport

func saveScore(_ score: Score, to url: URL) throws {
    // Configure the exporter
    var config = ExportConfiguration()
    config.musicXMLVersion = "4.0"
    config.includeDoctype = true
    config.addEncodingSignature = true

    let exporter = MusicXMLExporter(config: config)

    // Export
    try exporter.export(score, to: url)

    print("Saved to \(url.lastPathComponent)")
}

// Use it
let outputURL = getOutputURL()
try saveScore(myScore, to: outputURL)
```

## Round-Trip Fidelity

For best fidelity when re-exporting imported files, enable context preservation during import:

```swift
import MusicXMLImport
import MusicXMLExport

// Import with context preservation
var importOptions = ImportOptions.default
importOptions.preserveOriginalContext = true

let importer = MusicXMLImporter(options: importOptions)
let score = try importer.importScore(from: inputURL)

// Modify the score as needed
// ...

// Re-export preserves original structure
let exporter = MusicXMLExporter()
try exporter.export(score, to: outputURL)
```

This preserves:
- Element ordering from the original file
- Optional attributes and formatting hints
- Layout and appearance settings

## Supported Elements

The exporter outputs all elements from ``MusicNotationCore``:

| Category | Elements |
|----------|----------|
| Score structure | Parts, measures, voices, staves |
| Notes | Pitched, unpitched, rests, chords, grace notes |
| Attributes | Clefs, keys, time signatures, transposes |
| Notations | Ties, slurs, tuplets, articulations, dynamics |
| Directions | Dynamics, wedges, tempos, rehearsal marks |
| Barlines | All styles, repeats, endings |
| Metadata | Work info, creators, credits, encoding |
| Layout | Page settings, system/staff layout |

## Error Handling

Handle export errors appropriately:

```swift
do {
    try exporter.export(score, to: outputURL)
} catch let error as MusicXMLExportError {
    switch error {
    case .encodingError:
        // Use UTF-8 to avoid this
        print("Character encoding failed")

    case .fileWriteError(let url):
        // Permission or disk space issue
        print("Cannot write to \(url.path)")

    case .invalidScore(let reason):
        // Score has invalid data
        print("Score problem: \(reason)")
    }
} catch {
    // File system errors
    print("Write failed: \(error)")
}
```

## Thread Safety

``MusicXMLExporter`` is not thread-safe. For concurrent exports, create separate instances:

```swift
// Safe: separate exporters for concurrent use
await withTaskGroup(of: Void.self) { group in
    for (score, url) in scoresToExport {
        group.addTask {
            let exporter = MusicXMLExporter()  // New instance per task
            try? exporter.export(score, to: url)
        }
    }
}
```

## See Also

- ``MusicXMLExporter``
- ``ExportConfiguration``
- ``MusicXMLExportError``
- <doc:ExportConfiguration>
