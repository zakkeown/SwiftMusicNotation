# Contributing to SwiftMusicNotation

Thank you for your interest in contributing to SwiftMusicNotation! This document provides guidelines and information to help you contribute effectively.

## Getting Started

### Prerequisites

- Xcode 15.0 or later
- Swift 5.9 or later
- macOS 13+ or iOS 16+

### Building the Project

```bash
# Clone the repository
git clone https://github.com/yourusername/SwiftMusicNotation.git
cd SwiftMusicNotation

# Build the package
swift build

# Run all tests
swift test
```

### Running Specific Tests

```bash
# Run tests for a specific module
swift test --filter MusicNotationCoreTests
swift test --filter SMuFLKitTests
swift test --filter MusicXMLImportTests
swift test --filter MusicXMLExportTests
swift test --filter MusicNotationLayoutTests
swift test --filter MusicNotationPlaybackTests

# Run a single test
swift test --filter MusicXMLImportTests.testImportSimpleScale
```

## Architecture Overview

SwiftMusicNotation is organized as a multi-module Swift Package:

| Module | Purpose |
|--------|---------|
| **MusicNotationCore** | Domain models (Score, Part, Measure, Note, etc.) |
| **SMuFLKit** | SMuFL font integration and glyph management |
| **MusicXMLImport** | Parse MusicXML files (.musicxml, .mxl) |
| **MusicXMLExport** | Generate MusicXML from Score objects |
| **MusicNotationLayout** | Compute element positions for rendering |
| **MusicNotationRenderer** | Core Graphics rendering and platform views |
| **MusicNotationPlayback** | MIDI playback via AVFoundation |
| **SwiftMusicNotation** | Umbrella module (re-exports all modules) |

### Data Flow

```
MusicXML → MusicXMLImporter → Score → LayoutEngine → EngravedScore → MusicRenderer → CGContext
```

## How to Contribute

### Reporting Issues

Before creating an issue:
1. Search existing issues to avoid duplicates
2. Include a minimal reproducible example when possible
3. Provide Swift/Xcode version information
4. Describe expected vs. actual behavior

### Pull Requests

1. Fork the repository
2. Create a feature branch from `main`
3. Make your changes following the coding guidelines below
4. Add or update tests as needed
5. Update documentation if applicable
6. Submit a pull request with a clear description

### What We're Looking For

- Bug fixes with test cases
- Performance improvements with benchmarks
- Documentation improvements
- New MusicXML features (import/export)
- Rendering improvements
- Accessibility enhancements

## Coding Guidelines

### Swift Style

- Use Swift's standard naming conventions
- Prefer `let` over `var` when possible
- Mark types as `Sendable` when thread-safe
- Use `final class` for classes not designed for inheritance
- Prefer value types (structs/enums) over reference types

### Documentation

All public APIs must have documentation comments. Follow this format:

```swift
/// Brief one-line description.
///
/// Detailed explanation of purpose, usage, and considerations.
///
/// ## Example
///
/// ```swift
/// let example = TypeName()
/// let result = try example.method()
/// ```
///
/// - Parameter param: Description of parameter
/// - Returns: Description of return value
/// - Throws: ``ErrorType`` when condition occurs
///
/// - SeeAlso: ``RelatedType`` for related functionality
public func method(param: String) throws -> Result {
    // implementation
}
```

### Documentation Standards

1. **Every public type needs**:
   - A one-line summary
   - Detailed description (when non-obvious)
   - Usage example (for complex types)

2. **Every public method/property needs**:
   - A one-line summary
   - Parameter documentation
   - Return value documentation
   - Throws documentation (if applicable)

3. **Use DocC links**:
   - Link to related types: `` ``RelatedType`` ``
   - Link to methods: `` ``method(param:)`` ``

4. **Include examples**:
   - Show typical usage patterns
   - Include error handling when relevant
   - Keep examples concise but complete

### Testing

- Add tests for new functionality
- Update tests when modifying existing behavior
- Test edge cases and error conditions
- Use descriptive test names: `testImportScoreWithMultipleParts()`

### Commit Messages

Format: `[Module] Brief description`

Examples:
- `[MusicXMLImport] Add support for compressed MXL files`
- `[Layout] Fix beam positioning for cross-staff notes`
- `[Docs] Add tutorial for custom rendering`

## Module-Specific Guidelines

### MusicNotationCore

- Keep domain models simple and focused
- Prefer immutable structs for data types
- Use enums for closed sets of values
- Document music theory concepts when helpful

### SMuFLKit

- Follow SMuFL specification for glyph names
- Document glyph anchors and metrics
- Test with multiple SMuFL-compliant fonts

### MusicXMLImport/Export

- Maintain round-trip fidelity where possible
- Preserve original XML context for re-export
- Handle gracefully degraded imports with warnings
- Test against real-world MusicXML files

### MusicNotationLayout

- Use staff spaces as the base unit for calculations
- Document spacing algorithms
- Consider print vs. screen rendering needs
- Test with complex scores (orchestral, piano)

### MusicNotationRenderer

- Support both UIKit and AppKit
- Use Core Graphics for cross-platform rendering
- Implement accessibility where applicable
- Test visual output with snapshot tests if possible

### MusicNotationPlayback

- Use async/await for playback operations
- Expose Combine publishers for state changes
- Handle audio session management properly
- Test playback timing accuracy

## Building Documentation

Generate DocC documentation:

```bash
# Build documentation
swift package generate-documentation

# Preview documentation locally
swift package --disable-sandbox preview-documentation
```

## Questions?

- Open a GitHub Discussion for questions
- File an issue for bugs or feature requests
- Review existing documentation and tutorials

Thank you for contributing to SwiftMusicNotation!
