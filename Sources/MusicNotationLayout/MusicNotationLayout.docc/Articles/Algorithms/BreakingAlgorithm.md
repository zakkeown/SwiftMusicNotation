# System and Page Breaking

Understand how music is distributed across systems and pages.

@Metadata {
    @PageKind(article)
}

## Overview

The ``BreakingEngine`` determines where to break music across systems (horizontal lines of music) and pages. It uses a dynamic programming approach inspired by TeX's line-breaking algorithm to find globally optimal break points.

## System Breaking

System breaks determine how measures are distributed across horizontal lines. The algorithm balances:

- **Fill factor**: Systems should be reasonably full, not sparse
- **Stretch/compression**: Measures shouldn't be stretched or compressed too much
- **Visual consistency**: Similar measure counts per system when possible

### The Dynamic Programming Approach

Rather than greedily filling each system, the algorithm considers all possible break combinations to minimize a global cost function:

1. For each possible ending position, try all possible starting positions
2. Calculate the cost of each potential system
3. Use dynamic programming to find the sequence of breaks with minimum total cost

This avoids situations where a greedy approach leaves awkward partial systems at the end.

### Cost Function

The cost for a potential system includes:

```swift
// Stretch/compress penalty
let ratio = naturalWidth / targetWidth
if ratio < 1.0 {
    cost += (1.0 - ratio)² * stretchPenalty
} else {
    cost += (ratio - 1.0)² * compressPenalty
}

// Measure count penalties
if measureCount < minimumMeasuresPerSystem {
    cost += shortSystemPenalty * deficit
}
if measureCount > maximumMeasuresPerSystem {
    cost += longSystemPenalty * excess
}
```

### Break Hints

Authors can influence breaking with hints:

- **Preferred**: Slightly reduces cost at this position
- **Required**: Forces a break (very large bonus)
- **Forbidden**: Prevents a break (very large penalty)

```swift
let hints = [
    BreakHint(measureIndex: 7, type: .preferred),  // Good place to break
    BreakHint(measureIndex: 15, type: .required),  // Must break here
    BreakHint(measureIndex: 3, type: .forbidden)   // Don't break here
]
let breaks = engine.computeSystemBreaks(measureWidths: widths, systemWidth: 600, breakHints: hints)
```

## Page Breaking

Page breaking works similarly but operates on systems rather than measures:

1. Calculate the height of each system
2. Use dynamic programming to distribute systems across pages
3. Minimize underfilled pages and awkward distributions

### Page Cost Function

```swift
// Fill ratio penalty
if fillRatio < minimumPageFill {
    cost += (minimumPageFill - fillRatio)² * underfillPenalty
}

// System count penalty
if systemCount < minimumSystemsPerPage {
    cost += fewSystemsPenalty * deficit
}
```

## Greedy Alternative

For performance-critical scenarios, the engine provides greedy algorithms that run in O(n) time:

```swift
// Fast greedy breaking (less optimal but faster)
let breaks = engine.computeSystemBreaksGreedy(measureWidths: widths, systemWidth: 600)
let pages = engine.computePageBreaksGreedy(systemHeights: heights, pageHeight: 800, systemGap: 20)
```

Use greedy algorithms for:
- Interactive layout during editing
- Very long scores where optimal breaking is less critical
- Preview/draft modes

## Configuration

Tune breaking behavior through ``BreakingConfiguration``:

```swift
var config = BreakingConfiguration()

// Prefer fuller systems
config.minimumMeasuresPerSystem = 2
config.shortSystemPenalty = 100

// Allow more stretch
config.stretchPenalty = 50  // Lower = more stretch allowed

// Strict page filling
config.minimumPageFill = 0.7
config.underfillPenalty = 200

let engine = BreakingEngine(config: config)
```

## First System Handling

The first system often needs extra space for the initial clef, key signature, and time signature. Use `adjustForFirstSystem` to account for this:

```swift
var breaks = engine.computeSystemBreaks(measureWidths: widths, systemWidth: 600)
breaks = engine.adjustForFirstSystem(
    breaks: breaks,
    firstSystemExtraWidth: 50,  // Clef + key + time
    measureWidths: widths,
    systemWidth: 600
)
```

## See Also

- ``BreakingEngine``
- ``BreakingConfiguration``
- <doc:SpacingAlgorithm>
- <doc:CollisionDetection>
