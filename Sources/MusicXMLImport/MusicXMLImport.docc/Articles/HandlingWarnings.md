# Handling Warnings

Process non-fatal issues encountered during MusicXML import.

@Metadata {
    @PageKind(article)
}

## Overview

MusicXML files in the wild often contain minor issues or non-standard elements. Rather than failing on every issue, ``MusicXMLImporter`` collects non-fatal problems as warnings while continuing to parse the document. After import, you can review these warnings to understand what was skipped or defaulted.

## Accessing Warnings

The ``MusicXMLImporter/warnings`` property contains all warnings from the most recent import:

```swift
let importer = MusicXMLImporter()
let score = try importer.importScore(from: url)

// Check for warnings
if !importer.warnings.isEmpty {
    print("Import completed with \(importer.warnings.count) warnings:")
    for warning in importer.warnings {
        print("  - \(warning)")
    }
}
```

Warnings are cleared at the start of each import, so they only reflect the most recent operation.

## Warning Structure

Each ``MusicXMLWarning`` contains:

```swift
public struct MusicXMLWarning {
    /// Human-readable description of the issue
    public let message: String

    /// Location in the source XML (if available)
    public let location: SourceLocation?

    /// How the importer handled this issue
    public let recoveryAction: MusicXMLRecoveryAction
}
```

### Source Location

When available, the ``SourceLocation`` provides details about where the issue occurred:

```swift
for warning in importer.warnings {
    if let location = warning.location {
        print("Line \(location.line), column \(location.column)")
        if let path = location.elementPath {
            print("  Element: \(path)")  // e.g., "score-partwise/part/measure/note"
        }
    }
    print("  \(warning.message)")
}
```

### Recovery Actions

The ``MusicXMLRecoveryAction`` indicates how the importer handled each warning:

| Action | Description |
|--------|-------------|
| `.skip` | Problematic element was skipped entirely |
| `.useDefault` | A default value was substituted |
| `.abort` | Parsing was aborted (rare, usually throws instead) |

```swift
for warning in importer.warnings {
    switch warning.recoveryAction {
    case .skip:
        print("Skipped: \(warning.message)")
    case .useDefault:
        print("Defaulted: \(warning.message)")
    case .abort:
        print("Aborted: \(warning.message)")
    }
}
```

## Common Warning Types

### Missing Optional Elements

Elements that are optional in MusicXML but useful for rendering:

```swift
// Example warnings:
// "Part 'P1' missing part-name element"
// "Note missing stem direction, defaulting to auto"
// "Measure 5 missing explicit time signature"
```

### Unrecognized Elements

Elements the importer doesn't handle (often notation software extensions):

```swift
// "Unrecognized element 'my-custom-element' in direction-type"
// "Unknown articulation type 'custom-accent'"
```

### Invalid Attribute Values

Values that don't conform to the MusicXML schema:

```swift
// "Invalid octave value '10' for note, using 4"
// "Invalid dynamics value 'fortississimo', skipping"
// "Unrecognized clef sign 'X', defaulting to G"
```

### Orphaned Spanners

Slurs, ties, or other spanning elements without matching start/stop:

```swift
// "Orphaned slur (number=1) without matching stop"
// "Tie start without matching stop in measure 12"
```

## Filtering Warnings

Process warnings by category or severity:

```swift
// Find all skipped elements
let skipped = importer.warnings.filter { $0.recoveryAction == .skip }

// Find warnings about specific elements
let slurWarnings = importer.warnings.filter {
    $0.message.lowercased().contains("slur")
}

// Find warnings in a specific measure
let measure5Warnings = importer.warnings.filter {
    $0.message.contains("measure 5") ||
    $0.location?.elementPath?.contains("measure[number='5']") == true
}
```

## Logging Warnings

For production apps, consider logging warnings appropriately:

```swift
import os

let logger = Logger(subsystem: "com.myapp", category: "MusicXML")

func importWithLogging(from url: URL) throws -> Score {
    let importer = MusicXMLImporter()
    let score = try importer.importScore(from: url)

    // Log warnings at appropriate levels
    for warning in importer.warnings {
        switch warning.recoveryAction {
        case .skip:
            logger.warning("MusicXML import skipped: \(warning.message)")
        case .useDefault:
            logger.info("MusicXML import defaulted: \(warning.message)")
        case .abort:
            logger.error("MusicXML import aborted: \(warning.message)")
        }
    }

    if importer.warnings.isEmpty {
        logger.info("MusicXML import completed without warnings")
    }

    return score
}
```

## User-Facing Warning Reports

For apps that show import results to users:

```swift
struct ImportResult {
    let score: Score
    let warningCount: Int
    let criticalWarnings: [String]
}

func importForUser(from url: URL) throws -> ImportResult {
    let importer = MusicXMLImporter()
    let score = try importer.importScore(from: url)

    // Identify warnings users should know about
    let critical = importer.warnings.filter { warning in
        // Missing notes or significant content
        warning.message.contains("orphaned") ||
        warning.message.contains("missing required")
    }.map { $0.message }

    return ImportResult(
        score: score,
        warningCount: importer.warnings.count,
        criticalWarnings: critical
    )
}

// Display to user
let result = try importForUser(from: url)
if !result.criticalWarnings.isEmpty {
    showAlert(
        title: "Import Issues",
        message: "Some content may be missing:\n" +
                 result.criticalWarnings.joined(separator: "\n")
    )
}
```

## Warnings vs Errors

The distinction between warnings and errors:

| Warnings | Errors |
|----------|--------|
| Non-fatal issues | Fatal issues |
| Import continues | Import fails |
| Collected in `warnings` array | Thrown as `MusicXMLError` |
| Can be reviewed post-import | Must be caught immediately |

```swift
do {
    let score = try importer.importScore(from: url)

    // Import succeeded - check warnings
    if importer.warnings.count > 10 {
        print("Many warnings - file may have quality issues")
    }

} catch let error as MusicXMLError {
    // Import failed completely
    switch error {
    case .invalidXMLStructure:
        print("File is not valid XML")
    case .invalidFileFormat:
        print("Not a MusicXML file")
    default:
        print("Import error: \(error)")
    }
}
```

## Best Practices

1. **Always check warnings** after import, even if it succeeded
2. **Log warnings** in production for debugging user-reported issues
3. **Surface critical warnings** to users when content may be missing
4. **Don't fail** on warnings alone - the score is usually usable
5. **Test with real-world files** that may have quirks

## See Also

- ``MusicXMLWarning``
- ``SourceLocation``
- ``MusicXMLRecoveryAction``
- ``MusicXMLError``
- <doc:ImportingFiles>
