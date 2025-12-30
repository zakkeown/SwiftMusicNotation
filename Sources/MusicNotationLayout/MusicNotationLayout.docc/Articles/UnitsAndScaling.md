# Units and Scaling

Understand the coordinate systems used in music notation layout.

@Metadata {
    @PageKind(article)
}

## Overview

Music notation uses several unit systems with different origins and purposes. MusicNotationLayout provides types for working with these units and converting between them. Understanding these systems is essential for precise positioning and accurate rendering.

## Unit Systems

### Points

Points are the final output unit for Core Graphics rendering:
- 1 point = 1/72 inch
- Standard for macOS and iOS graphics
- Used for all `CGRect`, `CGPoint`, and `CGSize` values in engraved output

### Staff Spaces

The primary unit in SMuFL and music engraving:
- 1 staff space = distance between two adjacent staff lines
- 4 staff spaces = staff height (from bottom line to top line)
- SMuFL fonts are designed at 1 em = 4 staff spaces

```swift
// Create staff space values
let oneSpace = StaffSpaces(1.0)
let halfSpace = StaffSpaces(0.5)

// Convert to points
let staffHeight: CGFloat = 40  // points
let oneSpaceInPoints = oneSpace.toPoints(staffHeight: staffHeight)  // 10 points

// Convert from points
let tenPoints: CGFloat = 10
let inStaffSpaces = StaffSpaces.fromPoints(tenPoints, staffHeight: staffHeight)
```

### Tenths

MusicXML's internal unit:
- 1 tenth = 1/40 of a staff space (by convention)
- Used throughout MusicXML for positioning
- Requires scaling information for conversion

```swift
// Create tenths values
let fortyTenths = Tenths(40)  // = 1 staff space

// Convert to staff spaces
let staffSpaces = fortyTenths.toStaffSpaces()  // StaffSpaces(1.0)

// Convert with custom ratio
let customTenths = fortyTenths.toStaffSpaces(tenthsPerStaffSpace: 50)
```

## The Scaling Context

``ScalingContext`` centralizes unit conversion:

```swift
// Create from staff height
let scaling = ScalingContext(staffHeightPoints: 40)

// Convert staff spaces to points
let spaces = StaffSpaces(2.5)
let points = scaling.staffSpacesToPoints(spaces)  // 25 points

// Convert tenths to points
let tenths = Tenths(80)  // 2 staff spaces
let tenthsPoints = scaling.tenthsToPoints(tenths)  // 20 points

// Access derived values
let pointsPerSpace = scaling.pointsPerStaffSpace  // 10 points
```

### Creating from MusicXML Scaling

MusicXML files often include scaling information:

```xml
<defaults>
  <scaling>
    <millimeters>7.2143</millimeters>
    <tenths>40</tenths>
  </scaling>
</defaults>
```

Use this to create an accurate scaling context:

```swift
// From MusicXML scaling element
let scaling = ScalingContext(
    millimeters: 7.2143,  // Size in mm
    tenths: 40,           // Of this many tenths
    staffHeightPoints: 40 // Desired display size
)
```

## Position Types

### StaffPosition

Coordinates in staff space units:

```swift
// Position relative to staff
let position = StaffPosition(
    x: StaffSpaces(5.0),   // 5 spaces from left
    y: StaffSpaces(1.0)    // 1 space above center line
)

// Convert to points
let cgPoint = position.toPoint(staffHeight: 40)
```

Y coordinates in staff positions:
- 0 = center line (B4 in treble clef)
- +1 = one line/space up
- -1 = one line/space down
- +2 = top line (F5 in treble clef)
- -2 = bottom line (E4 in treble clef)

### StaffRect

Rectangles in staff space units:

```swift
// Define a region
let rect = StaffRect(
    x: StaffSpaces(0),
    y: StaffSpaces(-2),    // From bottom line
    width: StaffSpaces(4),
    height: StaffSpaces(4) // Full staff height
)

// Convert to CGRect
let cgRect = rect.toRect(staffHeight: 40)

// Test intersection
let other = StaffRect(x: StaffSpaces(2), y: StaffSpaces(-1),
                      width: StaffSpaces(2), height: StaffSpaces(2))
if rect.intersects(other) {
    // Handle overlap
}
```

## Coordinate System

### Page Coordinates

```
(0, 0) ────────────────────────────▶ X
   │
   │  ┌─────────────────────────┐
   │  │ margins.top             │
   │  │   ┌─────────────────┐   │
   │  │   │ content area    │   │
   │  │   │                 │   │
   │  │   │                 │   │
   │  │   └─────────────────┘   │
   │  │ margins.bottom          │
   │  └─────────────────────────┘
   ▼
   Y
```

- Origin at top-left
- X increases rightward
- Y increases downward
- All values in points

### Staff Coordinates

Within a staff, Y coordinates follow music conventions:

```
    Line 5 (top)    y = +2 staff spaces
    ─────────────
    Space 4         y = +1.5
    Line 4          y = +1
    Space 3         y = +0.5
    Line 3 (center) y = 0
    Space 2         y = -0.5
    Line 2          y = -1
    Space 1         y = -1.5
    Line 1 (bottom) y = -2 staff spaces
    ─────────────
```

## Conversion Examples

### MusicXML Position to Screen Position

```swift
func musicXMLToScreen(
    defaultX: Double?,  // In tenths, from left margin
    defaultY: Double?,  // In tenths, from top line
    scaling: ScalingContext,
    staffCenterY: CGFloat  // Center line Y in page coords
) -> CGPoint {
    let x = scaling.tenthsToPoints(Tenths(defaultX ?? 0))

    // MusicXML Y is from top line, convert to center-relative
    let topLineOffset = StaffSpaces(2).toPoints(staffHeight: scaling.staffHeightPoints)
    let yOffset = scaling.tenthsToPoints(Tenths(defaultY ?? 0))
    let y = staffCenterY - topLineOffset + yOffset

    return CGPoint(x: x, y: y)
}
```

### Pitch to Staff Position

```swift
func pitchToStaffPosition(
    step: PitchStep,
    octave: Int,
    clef: Clef
) -> StaffSpaces {
    // Calculate semitones from reference
    let stepValues: [PitchStep: Int] = [
        .c: 0, .d: 1, .e: 2, .f: 3, .g: 4, .a: 5, .b: 6
    ]

    let stepValue = stepValues[step]!
    let position: Int

    switch clef.sign {
    case .g:  // Treble clef: G4 on line 2
        position = stepValue + (octave - 4) * 7 - 4  // G4 = 0
    case .f:  // Bass clef: F3 on line 4
        position = stepValue + (octave - 3) * 7 - 3  // F3 = 0
    case .c:  // Alto clef: C4 on line 3
        position = stepValue + (octave - 4) * 7      // C4 = 0
    default:
        position = 0
    }

    // Each step is half a staff space
    return StaffSpaces(Double(position) * 0.5)
}
```

## Staff Space Arithmetic

``StaffSpaces`` supports standard arithmetic:

```swift
let a = StaffSpaces(2.0)
let b = StaffSpaces(1.5)

let sum = a + b           // StaffSpaces(3.5)
let difference = a - b    // StaffSpaces(0.5)
let scaled = a * 2.0      // StaffSpaces(4.0)
let divided = a / 4.0     // StaffSpaces(0.5)
let negated = -a          // StaffSpaces(-2.0)

// Comparison
if a > b { /* ... */ }
```

## See Also

- ``StaffSpaces``
- ``Tenths``
- ``ScalingContext``
- ``StaffPosition``
- ``StaffRect``
- <doc:LayoutEngine>
