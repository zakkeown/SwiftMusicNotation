# Orchestral Score Layout

Configure layout for multi-part orchestral and ensemble scores.

@Metadata {
    @PageKind(article)
}

## Overview

Orchestral scores present unique layout challenges: many simultaneous parts, instrument family groupings, connected barlines, and careful vertical spacing. This guide covers configuration options for professional orchestral layouts.

## Staff Grouping

Orchestral scores organize instruments into families with visual groupings:

```
┌─ Flutes 1, 2          ┐
│  Oboes 1, 2           │ Woodwinds (bracket)
│  Clarinets 1, 2       │
└─ Bassoons 1, 2        ┘

┌─ Horns 1-4            ┐
│  Trumpets 1, 2        │ Brass (bracket)
│  Trombones 1, 2, Bass │
└─ Tuba                 ┘

┌─ Timpani              ┐
└─ Percussion           ┘ Percussion (bracket)

   Harp                    Harp (no bracket)

┌─ Violin I             ┐
│  Violin II            │
│  Viola                │ Strings (bracket + brace)
│  Cello                │
└─ Double Bass          ┘
```

### Configuring Groups

Use ``StaffGroupConfiguration`` to define family groupings:

```swift
var config = LayoutConfiguration()

config.staffGroups = [
    StaffGroupConfiguration(
        name: "Woodwinds",
        partIndices: [0, 1, 2, 3],  // Fl, Ob, Cl, Bn
        bracketType: .bracket,
        barlineConnection: .connected
    ),
    StaffGroupConfiguration(
        name: "Brass",
        partIndices: [4, 5, 6, 7],  // Hn, Tpt, Tbn, Tba
        bracketType: .bracket,
        barlineConnection: .connected
    ),
    StaffGroupConfiguration(
        name: "Strings",
        partIndices: [9, 10, 11, 12, 13],
        bracketType: .bracket,
        barlineConnection: .connected,
        subGroups: [
            // Brace connecting Vln I and II
            StaffGroupConfiguration(
                name: "Violins",
                partIndices: [9, 10],
                bracketType: .brace,
                barlineConnection: .none
            )
        ]
    )
]
```

## Bracket and Brace Types

| Type | Usage | Visual |
|------|-------|--------|
| `.bracket` | Instrument families | Thick vertical line with serifs |
| `.brace` | Grand staff, divided strings | Curly brace |
| `.squareBracket` | Percussion groups | Square bracket |
| `.none` | Solo instruments | No grouping symbol |

## Barline Connection

Control how barlines connect between staves:

```swift
StaffGroupConfiguration(
    name: "Strings",
    partIndices: [9, 10, 11, 12, 13],
    bracketType: .bracket,
    barlineConnection: .connected  // Single barline through all staves
)
```

Options:
- `.connected`: Single barline spans all staves in group
- `.mensurstrich`: Barline between staves only (early music style)
- `.none`: Separate barlines per staff

## Vertical Spacing

Orchestral scores need careful vertical spacing:

```swift
var verticalConfig = VerticalSpacingConfiguration()

// Space between staves within a family
verticalConfig.intraGroupStaffSpacing = 8.0

// Space between instrument families
verticalConfig.interGroupSpacing = 15.0

// Minimum space for lyrics, dynamics, etc.
verticalConfig.minimumSystemPadding = 5.0

config.verticalConfig = verticalConfig
```

## Hide Empty Staves

For large scores, hide staves that have rests for an entire system:

```swift
config.hideEmptyStaves = true
config.hideEmptyStavesExceptFirst = true  // Always show on first system
config.minimumVisibleParts = 1  // Always show at least one part
```

## Part Names and Abbreviations

Configure staff labels:

```swift
config.staffLabelStyle = .firstSystemFull  // Full names on first system only
config.staffLabelAbbreviationStyle = .standard  // "Fl.", "Ob.", etc.
config.staffLabelPosition = .left
config.staffLabelIndent = 10.0
```

## System Indentation

First system typically needs more indentation for full part names:

```swift
config.firstSystemIndent = 80.0  // Extra space for "Flute 1, 2" etc.
config.subsequentSystemIndent = 30.0  // Less space for "Fl."
```

## Performance Optimization

Large orchestral scores can be computationally expensive:

### Lazy Layout

Only layout visible pages:

```swift
let layoutEngine = LayoutEngine(config: config)
layoutEngine.lazyLayout = true

// Layout first page immediately
let firstPage = layoutEngine.layoutPage(0, score: score, context: context)

// Layout additional pages on demand
let nextPage = layoutEngine.layoutPage(1, score: score, context: context)
```

### Caching

Enable layout caching for scores that don't change:

```swift
layoutEngine.enableCaching = true
layoutEngine.cacheKey = score.hashValue

// Subsequent layouts use cached results
let engravedScore = layoutEngine.layout(score: score, context: context)
```

## Example: Full Orchestra Configuration

```swift
var config = LayoutConfiguration()

// Page setup
config.pageSize = .a3Landscape  // Larger page for full orchestra
config.margins = EdgeInsets(top: 36, left: 36, bottom: 36, right: 36)

// Spacing
config.spacingConfig.quarterNoteSpacing = 25.0  // Tighter horizontal spacing
config.verticalConfig.interGroupSpacing = 20.0

// Staff groups (abbreviated)
config.staffGroups = [
    woodwindsGroup,
    brassGroup,
    percussionGroup,
    stringsGroup
]

// Labels
config.staffLabelStyle = .firstSystemFull
config.firstSystemIndent = 100.0

// Optimization
config.hideEmptyStaves = true
config.hideEmptyStavesExceptFirst = true

let layoutEngine = LayoutEngine(config: config)
```

## See Also

- ``LayoutConfiguration``
- ``StaffGroupConfiguration``
- ``VerticalSpacingConfiguration``
- <doc:BreakingAlgorithm>
