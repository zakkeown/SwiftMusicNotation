# Cursor Tracking

Synchronize visual cursors with audio playback.

@Metadata {
    @PageKind(article)
}

## Overview

``PlaybackCursor`` maps between time-based playback position and score coordinates (measure number, beat position). This enables synchronization of visual playback cursors with audio, creating a "follow along" experience in notation applications.

## How It Works

The cursor maintains a timing map that correlates:
- **Time** (seconds from start) ↔ **Position** (measure, beat)

```
Time:     0s      2s      4s      6s      8s
          │       │       │       │       │
Position: M1,B1 → M1,B3 → M2,B1 → M2,B3 → M3,B1
```

The mapping accounts for:
- Tempo changes within the score
- Time signature changes
- Measure durations

## Basic Usage

The cursor is managed internally by ``PlaybackEngine``, but you can access position through the engine:

```swift
// Current position is published
engine.$currentPosition
    .receive(on: DispatchQueue.main)
    .sink { position in
        updateCursor(at: position)
    }
    .store(in: &cancellables)

func updateCursor(at position: PlaybackPosition) {
    let measure = position.measure      // 1-based measure number
    let beat = position.beat            // 1-based beat (e.g., 1.0, 2.5)
    let time = position.timeInSeconds   // Elapsed time

    // Move visual cursor to this position
    cursorView.moveTo(measure: measure, beat: beat)
}
```

## Position Events

Subscribe to position changes through the engine's events publisher:

```swift
engine.events
    .receive(on: DispatchQueue.main)
    .sink { event in
        switch event {
        case .positionChanged(let measure, let beat):
            highlightMeasure(measure)
            updateBeatIndicator(beat)

        case .stopped:
            resetCursor()

        default:
            break
        }
    }
    .store(in: &cancellables)
```

## Visual Cursor Implementation

### SwiftUI Cursor View

```swift
struct PlaybackCursorView: View {
    let measureNumber: Int
    let beat: Double
    let measureWidth: CGFloat
    let beatCount: Int

    var body: some View {
        GeometryReader { geometry in
            // Calculate X position based on beat
            let beatFraction = (beat - 1.0) / Double(beatCount)
            let xOffset = CGFloat(beatFraction) * measureWidth

            Rectangle()
                .fill(Color.red.opacity(0.3))
                .frame(width: 2)
                .offset(x: xOffset)
                .animation(.linear(duration: 0.05), value: beat)
        }
    }
}
```

### Measure Highlight

```swift
struct MeasureHighlight: View {
    let measureNumber: Int
    @Binding var currentMeasure: Int

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(measureNumber == currentMeasure
                ? Color.accentColor.opacity(0.2)
                : Color.clear)
            .animation(.easeInOut(duration: 0.15), value: currentMeasure)
    }
}
```

## Cursor Delegate

For UIKit/AppKit apps, implement the ``PlaybackCursor/Delegate`` protocol:

```swift
class ScoreViewController: PlaybackCursor.Delegate {
    func cursorDidMove(to position: PlaybackPosition) {
        // Update cursor position smoothly
        animateCursor(to: position)
    }

    func cursorDidEnterMeasure(_ measureNumber: Int) {
        // Highlight new measure
        highlightMeasure(measureNumber)

        // Auto-scroll to keep measure visible
        scrollToMeasureIfNeeded(measureNumber)
    }

    func cursorDidReachElement(id: String, in measureNumber: Int) {
        // Highlight specific element (note, rest, etc.)
        highlightElement(id: id)
    }
}
```

## Time Calculations

### Time for Position

Calculate when a specific position will be reached:

```swift
let cursor = PlaybackCursor(score: score)

// When will measure 5, beat 2 occur?
let time = cursor.timeForPosition(measure: 5, beat: 2.0)
print("Measure 5, beat 2 at \(time) seconds")
```

### Position at Time

Find the position at a given time:

```swift
// What position is at 30 seconds?
let position = cursor.positionAt(time: 30.0)
print("At 30s: Measure \(position.measure), beat \(position.beat)")
```

### Measure Timing

Get timing info for a specific measure:

```swift
if let timing = cursor.timingForMeasure(5) {
    print("Measure 5 starts at \(timing.startTime)s")
    print("Duration: \(timing.duration)s")
    print("Beats: \(timing.beats)")
}

// Get individual beat times
let beatTimes = cursor.beatTimesForMeasure(5)
for (index, time) in beatTimes.enumerated() {
    print("Beat \(index + 1) at \(time)s")
}
```

## Progress Tracking

Track overall progress through the score:

```swift
struct ProgressView: View {
    let cursor: PlaybackCursor

    var body: some View {
        VStack {
            // Progress bar
            ProgressView(value: cursor.progress())

            // Time display
            let total = cursor.totalDuration()
            let current = cursor.currentPosition.timeInSeconds
            Text("\(formatTime(current)) / \(formatTime(total))")

            // Measure display
            Text("Measure \(cursor.currentPosition.measure) of \(cursor.totalMeasures())")
        }
    }

    func formatTime(_ seconds: TimeInterval) -> String {
        let mins = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", mins, secs)
    }
}
```

## Tempo Changes

When tempo changes, rebuild the timing map:

```swift
// Update cursor when user changes tempo
func tempoSliderChanged(_ newTempo: Double) {
    engine.tempo = newTempo
    // Cursor timing map updates automatically
}
```

## Auto-Scrolling

Keep the playback position visible:

```swift
func cursorDidEnterMeasure(_ measureNumber: Int) {
    // Get the measure frame
    guard let measureFrame = getMeasureFrame(measureNumber) else { return }

    // Check if it's visible
    let visibleRect = scrollView.visibleRect

    if !visibleRect.contains(measureFrame) {
        // Scroll to make it visible
        withAnimation(.easeInOut(duration: 0.3)) {
            scrollView.scrollRectToVisible(measureFrame, animated: true)
        }
    }
}
```

### SwiftUI Auto-Scroll

```swift
struct AutoScrollingScoreView: View {
    @State private var currentMeasure = 1

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                ForEach(1...measureCount, id: \.self) { measure in
                    MeasureView(number: measure)
                        .id("measure-\(measure)")
                }
            }
            .onChange(of: currentMeasure) { _, newMeasure in
                withAnimation {
                    proxy.scrollTo("measure-\(newMeasure)", anchor: .center)
                }
            }
        }
    }
}
```

## Beat Subdivision

For precise cursor animation, track sub-beat positions:

```swift
func updateCursor(at position: PlaybackPosition) {
    let measure = position.measure
    let beat = position.beat

    // Whole beat
    let wholeBeat = Int(beat)

    // Fractional part (for sub-beat positioning)
    let fraction = beat - Double(wholeBeat)

    // Position cursor with sub-beat precision
    let xOffset = calculateXPosition(measure: measure, beat: wholeBeat, fraction: fraction)
    cursorView.frame.origin.x = xOffset
}
```

## See Also

- ``PlaybackCursor``
- ``PlaybackPosition``
- ``PlaybackCursor/Delegate``
- ``PlaybackEngine``
- <doc:PlaybackEngine>
