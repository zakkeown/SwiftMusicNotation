# Export Configuration

Customize MusicXML output format and options.

@Metadata {
    @PageKind(article)
}

## Overview

``ExportConfiguration`` controls how ``MusicXMLExporter`` generates MusicXML output. You can configure the MusicXML version, character encoding, DOCTYPE inclusion, and software signature.

## Default Configuration

The default configuration produces standard MusicXML 4.0 output:

```swift
let exporter = MusicXMLExporter()  // Uses default configuration

// Equivalent to:
let config = ExportConfiguration()
let exporter = MusicXMLExporter(config: config)
```

Default settings:
- MusicXML version: 4.0
- Encoding: UTF-8
- DOCTYPE: Included
- Software signature: Added

## MusicXML Version

Control the declared MusicXML version:

```swift
var config = ExportConfiguration()

// Latest version (default)
config.musicXMLVersion = "4.0"

// For broader compatibility with older software
config.musicXMLVersion = "3.1"

// Legacy compatibility
config.musicXMLVersion = "3.0"
```

The version affects:
- The `version` attribute on the root element
- The DOCTYPE declaration (if enabled)

```xml
<!-- With version "4.0" -->
<score-partwise version="4.0">

<!-- With version "3.1" -->
<score-partwise version="3.1">
```

### Version Compatibility

| Version | Support Level | Notes |
|---------|---------------|-------|
| 4.0 | Full | Default, latest features |
| 3.1 | Full | Excellent compatibility |
| 3.0 | Full | Wide legacy support |
| 2.0 | Partial | Older elements may differ |

## Character Encoding

Configure the output encoding:

```swift
var config = ExportConfiguration()

// UTF-8 (default, recommended)
config.encoding = .utf8

// Other encodings for specific requirements
config.encoding = .utf16
config.encoding = .isoLatin1
```

The encoding is declared in the XML declaration:

```xml
<?xml version="1.0" encoding="UTF-8"?>
```

UTF-8 is strongly recommended for maximum compatibility and international character support.

## DOCTYPE Declaration

Control whether to include the DOCTYPE:

```swift
var config = ExportConfiguration()

// Include DOCTYPE (default)
config.includeDoctype = true

// Skip DOCTYPE for smaller output
config.includeDoctype = false
```

With DOCTYPE enabled:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE score-partwise PUBLIC "-//Recordare//DTD MusicXML 4.0 Partwise//EN"
    "http://www.musicxml.org/dtds/partwise.dtd">
<score-partwise version="4.0">
```

Without DOCTYPE:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<score-partwise version="4.0">
```

Most MusicXML parsers don't require the DOCTYPE, but including it improves compliance and validation.

## Software Signature

Control whether to add a SwiftMusicNotation signature:

```swift
var config = ExportConfiguration()

// Add signature (default)
config.addEncodingSignature = true

// Don't add signature
config.addEncodingSignature = false
```

With signature enabled, the output includes:

```xml
<identification>
    <encoding>
        <software>SwiftMusicNotation</software>
        <encoding-date>2025-01-15</encoding-date>
        <!-- Original encoding info preserved -->
    </encoding>
</identification>
```

This helps track the source of exported files and is useful for debugging interoperability issues.

## Configuration Presets

Create reusable configurations for common scenarios:

```swift
extension ExportConfiguration {
    /// Minimal output for debugging
    static let minimal: ExportConfiguration = {
        var config = ExportConfiguration()
        config.includeDoctype = false
        config.addEncodingSignature = false
        return config
    }()

    /// Maximum compatibility with older software
    static let legacy: ExportConfiguration = {
        var config = ExportConfiguration()
        config.musicXMLVersion = "3.0"
        config.encoding = .utf8
        config.includeDoctype = true
        config.addEncodingSignature = true
        return config
    }()

    /// Standard production output
    static let standard: ExportConfiguration = {
        var config = ExportConfiguration()
        config.musicXMLVersion = "4.0"
        config.includeDoctype = true
        config.addEncodingSignature = true
        return config
    }()
}

// Usage
let debugExporter = MusicXMLExporter(config: .minimal)
let legacyExporter = MusicXMLExporter(config: .legacy)
let productionExporter = MusicXMLExporter(config: .standard)
```

## Modifying Configuration

You can modify the configuration on an existing exporter:

```swift
let exporter = MusicXMLExporter()

// Check current settings
print("Version: \(exporter.config.musicXMLVersion)")

// Modify settings
exporter.config.musicXMLVersion = "3.1"
exporter.config.includeDoctype = false

// Export with new settings
try exporter.export(score, to: outputURL)
```

## Configuration Impact

### File Size

Configuration affects output file size:

| Setting | Impact |
|---------|--------|
| `includeDoctype = false` | ~200 bytes smaller |
| `addEncodingSignature = false` | ~100 bytes smaller |
| Lower version | Minimal impact |

For typical scores, these differences are negligible.

### Compatibility

For maximum compatibility with other software:

```swift
var config = ExportConfiguration()
config.musicXMLVersion = "3.1"       // Not all apps support 4.0
config.encoding = .utf8              // Most universal
config.includeDoctype = true         // Expected by validators
config.addEncodingSignature = true   // Helps debugging

let exporter = MusicXMLExporter(config: config)
```

### Round-Trip Quality

For re-exporting imported files:

```swift
// Import with context preservation
var importOptions = ImportOptions.default
importOptions.preserveOriginalContext = true

let importer = MusicXMLImporter(options: importOptions)
let score = try importer.importScore(from: inputURL)

// Export matching original version if possible
var config = ExportConfiguration()
if let originalVersion = score.metadata.encoding?.musicXMLVersion {
    config.musicXMLVersion = originalVersion
}

let exporter = MusicXMLExporter(config: config)
try exporter.export(score, to: outputURL)
```

## See Also

- ``ExportConfiguration``
- ``MusicXMLExporter``
- <doc:ExportingScores>
