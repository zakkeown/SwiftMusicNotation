# Error Handling Guide

Handle errors gracefully across all SwiftMusicNotation modules.

@Metadata {
    @PageKind(article)
}

## Overview

SwiftMusicNotation uses Swift's typed error system with detailed context for debugging. Understanding the error types and patterns helps you provide better feedback to users and build more robust applications.

## MusicXML Import Errors

The import module uses ``MusicXMLError`` for fatal issues that prevent successful parsing:

```swift
do {
    let score = try importer.importScore(from: url)
} catch let error as MusicXMLError {
    switch error {
    case .fileNotFound(let url):
        showError("File not found: \(url.lastPathComponent)")

    case .invalidFileFormat(let message):
        showError("Invalid format: \(message)")

    case .unsupportedVersion(let version):
        showError("MusicXML version \(version) is not supported")

    case .xmlParsingFailed(let line, let column, let message):
        showError("XML error at line \(line), column \(column): \(message)")

    case .invalidPitch(let step, let octave):
        showError("Invalid pitch: \(step)\(octave)")

    case .invalidDuration(let value):
        showError("Invalid duration value: \(value)")

    case .missingRequiredElement(let name, let context):
        showError("Missing required element '\(name)' in \(context)")

    case .invalidAttributeValue(let attribute, let value, let element):
        showError("Invalid value '\(value)' for \(attribute) in <\(element)>")

    case .compressionError(let message):
        showError("Failed to decompress MXL file: \(message)")

    case .encodingError(let message):
        showError("Text encoding error: \(message)")
    }
} catch {
    showError("Unexpected error: \(error.localizedDescription)")
}
```

## Import Warnings

Non-fatal issues are collected as warnings rather than throwing errors. This allows import to succeed while informing you of potential problems:

```swift
let importer = MusicXMLImporter()
let score = try importer.importScore(from: url)

// Check for warnings after successful import
if !importer.warnings.isEmpty {
    for warning in importer.warnings {
        switch warning {
        case .orphanedSlur(let number, let measure):
            logger.warning("Orphaned slur \(number) in measure \(measure)")

        case .orphanedTie(let pitch, let measure):
            logger.warning("Orphaned tie on \(pitch) in measure \(measure)")

        case .unsupportedElement(let name, let context):
            logger.warning("Unsupported element <\(name)> in \(context)")

        case .invalidAttributeIgnored(let attribute, let element):
            logger.warning("Ignored invalid \(attribute) in <\(element)>")

        case .durationMismatch(let expected, let actual, let measure):
            logger.warning("Duration mismatch in measure \(measure): expected \(expected), got \(actual)")
        }
    }
}
```

## Playback Errors

The playback module uses ``PlaybackEngine/PlaybackError`` for audio-related issues:

```swift
do {
    try engine.play()
} catch let error as PlaybackEngine.PlaybackError {
    switch error {
    case .noScoreLoaded:
        showError("Please load a score before playing")

    case .audioEngineStartFailed(let message):
        showError("Audio engine failed to start: \(message)")

    case .soundBankNotFound(let name):
        showError("Sound bank '\(name)' not found")

    case .midiSetupFailed(let message):
        showError("MIDI setup failed: \(message)")

    case .invalidTempo(let bpm):
        showError("Invalid tempo: \(bpm) BPM")
    }
}
```

## Layout Errors

Layout typically doesn't throw errors but may produce warnings or fall back to default values:

```swift
let layoutEngine = LayoutEngine()
let result = layoutEngine.layout(score: score, context: context)

// Check for layout warnings
for warning in result.warnings {
    switch warning {
    case .measureOverflow(let measureIndex, let overflow):
        logger.warning("Measure \(measureIndex) overflows by \(overflow) points")

    case .collisionUnresolved(let element1, let element2):
        logger.warning("Unresolved collision between \(element1) and \(element2)")

    case .fontGlyphMissing(let glyphName):
        logger.warning("Missing glyph: \(glyphName)")
    }
}
```

## Error Recovery Patterns

### Graceful Degradation

When possible, continue with partial results rather than failing completely:

```swift
func loadScore(from url: URL) -> Score? {
    do {
        let importer = MusicXMLImporter()
        let score = try importer.importScore(from: url)

        // Log warnings but don't fail
        for warning in importer.warnings {
            logger.warning("\(warning)")
        }

        return score
    } catch {
        // Log error and return nil
        logger.error("Failed to load score: \(error)")
        return nil
    }
}
```

### User Feedback

Provide actionable feedback when errors occur:

```swift
func handleImportError(_ error: MusicXMLError) -> String {
    switch error {
    case .fileNotFound:
        return "The file could not be found. Please check the file path and try again."

    case .invalidFileFormat:
        return "This file is not a valid MusicXML file. Please select a .musicxml or .mxl file."

    case .unsupportedVersion(let version):
        return "This file uses MusicXML version \(version) which is not yet supported. " +
               "Please export using MusicXML 3.1 or earlier."

    case .xmlParsingFailed(let line, _, let message):
        return "The file contains invalid XML at line \(line): \(message). " +
               "Please check the file for corruption."

    default:
        return "An error occurred while loading the file. Please try a different file."
    }
}
```

### Retry with Options

Some errors can be resolved by adjusting import options:

```swift
func importWithFallback(from url: URL) throws -> Score {
    let importer = MusicXMLImporter()

    do {
        // Try strict import first
        var options = ImportOptions.default
        options.strictVersionCheck = true
        return try importer.importScore(from: url, options: options)
    } catch MusicXMLError.unsupportedVersion {
        // Retry with lenient version checking
        var options = ImportOptions.default
        options.strictVersionCheck = false
        return try importer.importScore(from: url, options: options)
    }
}
```

## Debugging Tips

### Enable Verbose Logging

For development, enable detailed logging:

```swift
let importer = MusicXMLImporter()
importer.loggingLevel = .verbose  // Log all parsing steps

let score = try importer.importScore(from: url)
```

### Inspect Warning Details

Warnings often contain context that helps identify the source:

```swift
for warning in importer.warnings {
    print("Warning: \(warning)")
    print("  Measure: \(warning.measureIndex ?? -1)")
    print("  Element: \(warning.elementContext ?? "unknown")")
}
```

## See Also

- ``MusicXMLError``
- ``MusicXMLWarning``
- ``PlaybackEngine/PlaybackError``
