# ``MusicXMLExport``

Generate MusicXML from Score objects.

## Overview

MusicXMLExport provides `MusicXMLExporter` for serializing Score objects back to MusicXML format.

### Basic Export

```swift
let exporter = MusicXMLExporter()

// Export to string
let xmlString = try exporter.exportToString(score)

// Export to file
try exporter.export(score, to: outputURL)

// Export as compressed .mxl
try exporter.exportCompressed(score, to: outputURL)
```

### Export Configuration

Customize export output with `ExportConfiguration`:

```swift
var config = ExportConfiguration()

// MusicXML version
config.musicXMLVersion = "4.0"

// Character encoding
config.encoding = .utf8

// Include XML doctype
config.includeDoctype = true

// Add encoding signature comment
config.addEncodingSignature = true

let exporter = MusicXMLExporter(config: config)
```

### Round-Trip Preservation

For best round-trip fidelity, enable context preservation during import:

```swift
// Import with preservation
var importOptions = ImportOptions.default
importOptions.preserveOriginalContext = true

let importer = MusicXMLImporter(options: importOptions)
let score = try importer.importScore(from: url)

// Export preserves original structure
let exporter = MusicXMLExporter()
let xml = try exporter.exportToString(score)
```

### Error Handling

Handle export errors:

```swift
do {
    try exporter.export(score, to: url)
} catch let error as MusicXMLExportError {
    switch error {
    case .encodingError(let message):
        print("Encoding error: \(message)")
    case .fileWriteError(let message):
        print("Write error: \(message)")
    case .invalidScore(let message):
        print("Invalid score: \(message)")
    }
}
```

## Topics

### Export

- ``MusicXMLExporter``
- ``ExportConfiguration``

### Errors

- ``MusicXMLExportError``
