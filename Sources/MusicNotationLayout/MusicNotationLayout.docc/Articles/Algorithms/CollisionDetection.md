# Collision Detection and Resolution

Understand how element collisions are detected and resolved.

@Metadata {
    @PageKind(article)
}

## Overview

Music notation contains many elements that can potentially overlap: accidentals in dense chords, articulation marks above notes, dynamics below staves, and slurs that curve around other elements. The ``CollisionDetector`` identifies these overlaps and provides resolution strategies.

## Bounding Box Collisions

The foundation of collision detection is bounding box intersection testing:

```swift
let detector = CollisionDetector()

// Basic intersection check
if detector.intersects(rectA, rectB) {
    // Handle collision
}

// Check with padding (minimum gap)
if detector.intersects(rectA, rectB, padding: 2.0) {
    // Elements are too close
}
```

### Minimum Displacement

When elements collide, the detector calculates the smallest movement to separate them:

```swift
if let displacement = detector.minimumDisplacement(from: noteheadBounds, avoiding: accidentalBounds) {
    // displacement.dx or displacement.dy tells how far to move
    adjustedPosition.x += displacement.dx
    adjustedPosition.y += displacement.dy
}
```

The algorithm chooses the direction (horizontal or vertical) that requires the smallest movement.

## Accidental Stacking

Dense chords often have multiple accidentals that must be stacked without overlapping:

```swift
let accidentals = [
    AccidentalBounds(bounds: sharpBounds, staffPosition: 5, accidental: .sharp),
    AccidentalBounds(bounds: flatBounds, staffPosition: 3, accidental: .flat),
    AccidentalBounds(bounds: naturalBounds, staffPosition: 4, accidental: .natural)
]

let offsets = detector.resolveAccidentalCollisions(
    accidentals: accidentals,
    noteheadWidth: 10.0
)
// offsets[i] = x offset for accidental i
```

The algorithm:
1. Sorts accidentals by staff position (highest first)
2. Places each accidental as close to the notehead as possible
3. Shifts left when collisions occur, forming columns

## Stem and Beam Collisions

Stems must clear noteheads and beams. The detector provides adjustment calculations:

```swift
// Check if stem needs extension
let extension = detector.adjustStemLength(
    stemStart: stemBasePoint,
    stemEnd: stemTipPoint,
    direction: .up,
    obstacles: [noteheadBounds, beamBounds]
)
// Add 'extension' to stem length to clear obstacles
```

For beams that collide with inner noteheads:

```swift
let beamAdjustment = detector.adjustBeamPosition(
    beamBounds: currentBeamBounds,
    noteheads: innerNoteheadBounds,
    stemDirection: .up
)
// Shift beam by beamAdjustment to clear noteheads
```

## Articulation Stacking

Multiple articulations above or below a note are stacked vertically:

```swift
let articulations = [
    ArticulationBounds(bounds: accentBounds, articulation: .accent, stackPriority: 0),
    ArticulationBounds(bounds: staccatoBounds, articulation: .staccato, stackPriority: 1)
]

let yOffsets = detector.resolveArticulationStack(
    articulations: articulations,
    noteBounds: noteheadBounds,
    placement: .above
)
// yOffsets[i] = y position for articulation i
```

Lower priority numbers are placed closer to the note.

## Dynamic Positioning

Dynamics need clear placement below (or above) staves while avoiding other elements:

```swift
let position = detector.findDynamicPosition(
    dynamicBounds: dynamicRect,
    staffBounds: staffRect,
    obstacles: [slurBounds, pedalBounds],
    preferredPlacement: .below
)
// position.y is adjusted to avoid all obstacles
```

The algorithm iteratively moves the dynamic away from the staff until it clears all obstacles.

## Curve Collision Detection

Slurs and ties can collide with noteheads, stems, and other elements:

```swift
// Sample points along the curve
let collisions = detector.checkCurveCollision(
    curvePoints: bezierSamplePoints,
    obstacles: noteheadBounds
)

// Adjust curve height to clear obstacles
let heightAdjustment = detector.adjustCurveHeight(
    startPoint: curveStart,
    endPoint: curveEnd,
    controlPoint: curveControl,
    obstacles: obstacles,
    direction: .above
)
```

## Configuration

Tune collision thresholds through ``CollisionConfiguration``:

```swift
var config = CollisionConfiguration()

// Tighter accidental spacing
config.accidentalAccidentalGap = 0.05
config.accidentalNoteheadGap = 0.1

// More stem clearance
config.stemClearance = 0.5

// Looser dynamics placement
config.dynamicStaffGap = 1.5

let detector = CollisionDetector(config: config)
```

## Spatial Hashing for Large Scores

For scores with many elements, use ``SpatialHash`` to accelerate collision queries:

```swift
let spatialHash = SpatialHash(cellSize: 20.0)

// Insert all element bounds
for (index, bounds) in allElements.enumerated() {
    spatialHash.insert(bounds)
}

// Query potential collisions efficiently
let candidates = spatialHash.query(newElementBounds)
// Only test against candidates, not all elements
```

This reduces collision detection from O(n²) to approximately O(n) for well-distributed elements.

## See Also

- ``CollisionDetector``
- ``CollisionConfiguration``
- ``SpatialHash``
- <doc:SpacingAlgorithm>
