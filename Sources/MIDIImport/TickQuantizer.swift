import Foundation
import MusicNotationCore

/// Quantizes raw MIDI tick values to the nearest musical grid position and duration.
struct TickQuantizer {

    /// The ticks-per-quarter-note value from the MIDI file header.
    let ticksPerQuarter: Int

    /// The smallest duration to consider when quantizing.
    let resolution: DurationBase

    /// Pre-computed grid entries for efficient lookup.
    private let durationGrid: [(ticks: Int, base: DurationBase, dots: Int)]
    /// Pre-computed position grid for snapping tick positions.
    private let positionGrid: [Int]

    init(ticksPerQuarter: Int, resolution: DurationBase = .sixteenth) {
        self.ticksPerQuarter = ticksPerQuarter
        self.resolution = resolution
        self.durationGrid = Self.buildDurationGrid(tpq: ticksPerQuarter, resolution: resolution)
        self.positionGrid = Self.buildPositionGrid(tpq: ticksPerQuarter, resolution: resolution)
    }

    // MARK: - Grid Building

    /// Builds a sorted grid of (tick count, base, dots) for all valid durations
    /// from whole note down to the resolution, with 0-2 dots each.
    private static func buildDurationGrid(
        tpq: Int,
        resolution: DurationBase
    ) -> [(ticks: Int, base: DurationBase, dots: Int)] {
        var grid: [(ticks: Int, base: DurationBase, dots: Int)] = []

        // Whole note ticks = tpq * 4
        let wholeNoteTicks = tpq * 4

        for base in DurationBase.allCases {
            // Skip durations shorter than the resolution
            if base < resolution { continue }
            // Skip absurdly long values (longa, maxima, breve can be included)
            if base.rawValue > 4 { continue }

            for dots in 0...2 {
                let baseTicks: Int
                if base.rawValue >= 1 {
                    baseTicks = wholeNoteTicks * base.rawValue
                } else {
                    baseTicks = wholeNoteTicks / (1 << -base.rawValue)
                }

                // Apply dots: ticks * (2^(d+1) - 1) / 2^d
                let dotNumerator = (1 << (dots + 1)) - 1
                let dotDenominator = 1 << dots
                let totalTicks = baseTicks * dotNumerator / dotDenominator

                if totalTicks > 0 {
                    grid.append((ticks: totalTicks, base: base, dots: dots))
                }
            }
        }

        // Sort by tick count ascending for efficient search
        grid.sort { $0.ticks < $1.ticks }
        return grid
    }

    /// Builds a sorted array of grid positions at the resolution level within one whole note.
    private static func buildPositionGrid(tpq: Int, resolution: DurationBase) -> [Int] {
        let resolutionTicks: Int
        if resolution.rawValue >= 1 {
            resolutionTicks = tpq * 4 * resolution.rawValue
        } else {
            resolutionTicks = tpq * 4 / (1 << -resolution.rawValue)
        }

        guard resolutionTicks > 0 else { return [0] }
        return [resolutionTicks]
    }

    // MARK: - Quantization

    /// Snaps a tick position to the nearest grid line.
    func quantizePosition(_ tick: Int) -> Int {
        let resolutionTicks = positionGrid[0]
        guard resolutionTicks > 0 else { return tick }

        let remainder = tick % resolutionTicks
        if remainder == 0 { return tick }

        if remainder <= resolutionTicks / 2 {
            return tick - remainder
        } else {
            return tick - remainder + resolutionTicks
        }
    }

    /// Finds the best (DurationBase, dots) match for a given tick duration.
    func quantizeDuration(_ ticks: Int) -> (base: DurationBase, dots: Int) {
        guard ticks > 0, !durationGrid.isEmpty else {
            return (.quarter, 0)
        }

        var bestMatch = durationGrid[0]
        var bestDistance = abs(ticks - bestMatch.ticks)

        for entry in durationGrid {
            let distance = abs(ticks - entry.ticks)
            if distance < bestDistance {
                bestDistance = distance
                bestMatch = entry
            }
        }

        return (bestMatch.base, bestMatch.dots)
    }

    /// Computes the tick count for a given base duration and dot count.
    func ticksFor(base: DurationBase, dots: Int) -> Int {
        let wholeNoteTicks = ticksPerQuarter * 4
        let baseTicks: Int
        if base.rawValue >= 1 {
            baseTicks = wholeNoteTicks * base.rawValue
        } else {
            baseTicks = wholeNoteTicks / (1 << -base.rawValue)
        }
        let dotNumerator = (1 << (dots + 1)) - 1
        let dotDenominator = 1 << dots
        return baseTicks * dotNumerator / dotDenominator
    }
}
