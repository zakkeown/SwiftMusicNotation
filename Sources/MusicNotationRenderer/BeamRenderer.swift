import Foundation
import CoreGraphics
import MusicNotationCore

// MARK: - Beam Renderer

/// Renders beams connecting groups of notes in music notation.
///
/// `BeamRenderer` handles all beam-related rendering including primary beams (eighth notes),
/// secondary beams (sixteenth notes and smaller), fractional beams (hooks), and tremolo marks.
/// It produces visually correct beams that follow traditional engraving conventions.
///
/// ## Beam Geometry
///
/// Beams are rendered as parallelograms with horizontal thickness (perpendicular to the staff,
/// not perpendicular to the beam line). This matches the standard engraving practice where
/// beam thickness remains constant regardless of slope.
///
/// ## Multi-Level Beams
///
/// Beamed notes can have multiple beam levels:
/// - Level 1: Primary beam (eighth notes)
/// - Level 2: Secondary beam (sixteenth notes)
/// - Level 3+: Additional beams for 32nd notes and smaller
///
/// Each level is offset vertically from the previous by `beamThickness + beamSpacing`.
///
/// ## Usage
///
/// ```swift
/// let renderer = BeamRenderer()
///
/// // Render a simple beam group
/// let beamInfo = BeamGroupRenderInfo(
///     primaryBeamStart: CGPoint(x: 100, y: 50),
///     primaryBeamEnd: CGPoint(x: 200, y: 45),
///     beamThickness: 5.0,
///     stemDirection: .up
/// )
/// renderer.renderBeamGroup(beamInfo, color: CGColor.black, in: context)
/// ```
///
/// - SeeAlso: ``NoteRenderer`` for note and stem rendering
/// - SeeAlso: ``BeamRenderConfiguration`` for customization options
public final class BeamRenderer {
    /// Configuration for beam rendering.
    public var config: BeamRenderConfiguration

    public init(config: BeamRenderConfiguration = BeamRenderConfiguration()) {
        self.config = config
    }

    // MARK: - Primary Beam Rendering

    /// Renders a beam group.
    public func renderBeamGroup(
        _ beamGroup: BeamGroupRenderInfo,
        color: CGColor,
        in context: CGContext
    ) {
        // Render primary beam
        renderBeam(
            from: beamGroup.primaryBeamStart,
            to: beamGroup.primaryBeamEnd,
            thickness: beamGroup.beamThickness,
            color: color,
            in: context
        )

        // Render secondary beams
        for secondaryBeam in beamGroup.secondaryBeams {
            renderBeam(
                from: secondaryBeam.start,
                to: secondaryBeam.end,
                thickness: beamGroup.beamThickness,
                color: color,
                in: context
            )
        }
    }

    /// Renders a single beam.
    public func renderBeam(
        from start: CGPoint,
        to end: CGPoint,
        thickness: CGFloat,
        color: CGColor,
        in context: CGContext
    ) {
        context.saveGState()
        context.setFillColor(color)

        // Calculate the parallelogram corners
        let halfThickness = thickness / 2

        // For a slanted beam, the thickness is perpendicular to the staff
        // (not perpendicular to the beam line)
        let path = CGMutablePath()
        path.move(to: CGPoint(x: start.x, y: start.y - halfThickness))
        path.addLine(to: CGPoint(x: end.x, y: end.y - halfThickness))
        path.addLine(to: CGPoint(x: end.x, y: end.y + halfThickness))
        path.addLine(to: CGPoint(x: start.x, y: start.y + halfThickness))
        path.closeSubpath()

        context.addPath(path)
        context.fillPath()

        context.restoreGState()
    }

    /// Renders a beam with precise angle control.
    public func renderAngledBeam(
        from start: CGPoint,
        to end: CGPoint,
        thickness: CGFloat,
        color: CGColor,
        in context: CGContext
    ) {
        context.saveGState()
        context.setFillColor(color)

        // Calculate the angle of the beam
        let dx = end.x - start.x
        let dy = end.y - start.y
        let angle = atan2(dy, dx)

        // Calculate perpendicular offset for thickness
        let halfThickness = thickness / 2
        let offsetX = halfThickness * sin(angle)
        let offsetY = halfThickness * cos(angle)

        // Draw parallelogram
        let path = CGMutablePath()
        path.move(to: CGPoint(x: start.x - offsetX, y: start.y + offsetY))
        path.addLine(to: CGPoint(x: end.x - offsetX, y: end.y + offsetY))
        path.addLine(to: CGPoint(x: end.x + offsetX, y: end.y - offsetY))
        path.addLine(to: CGPoint(x: start.x + offsetX, y: start.y - offsetY))
        path.closeSubpath()

        context.addPath(path)
        context.fillPath()

        context.restoreGState()
    }

    // MARK: - Multi-Level Beams

    /// Renders multiple beam levels.
    public func renderMultiLevelBeams(
        beamLevels: [BeamLevelInfo],
        stemDirection: StemDirection,
        color: CGColor,
        in context: CGContext
    ) {
        for level in beamLevels {
            let yOffset = beamYOffset(for: level.level, direction: stemDirection)

            for segment in level.segments {
                let startY = segment.start.y + yOffset
                let endY = segment.end.y + yOffset

                renderBeam(
                    from: CGPoint(x: segment.start.x, y: startY),
                    to: CGPoint(x: segment.end.x, y: endY),
                    thickness: config.beamThickness,
                    color: color,
                    in: context
                )
            }
        }
    }

    /// Calculates Y offset for a beam level.
    public func beamYOffset(for level: Int, direction: StemDirection) -> CGFloat {
        let offset = CGFloat(level - 1) * (config.beamThickness + config.beamSpacing)
        return direction == .up ? offset : -offset
    }

    // MARK: - Fractional Beams (Hooks)

    /// Renders a fractional beam (hook/partial beam).
    public func renderFractionalBeam(
        at stemEnd: CGPoint,
        level: Int,
        length: CGFloat,
        side: FractionalBeamSide,
        stemDirection: StemDirection,
        primaryBeamSlope: CGFloat,
        color: CGColor,
        in context: CGContext
    ) {
        let yOffset = beamYOffset(for: level, direction: stemDirection)
        let startY = stemEnd.y + yOffset

        let actualLength: CGFloat
        let endX: CGFloat

        switch side {
        case .left:
            actualLength = -length
            endX = stemEnd.x - length
        case .right:
            actualLength = length
            endX = stemEnd.x + length
        }

        // Apply slope to end Y
        let endY = startY + actualLength * primaryBeamSlope

        renderBeam(
            from: CGPoint(x: stemEnd.x, y: startY),
            to: CGPoint(x: endX, y: endY),
            thickness: config.beamThickness,
            color: color,
            in: context
        )
    }

    // MARK: - Beam Calculations

    /// Calculates beam endpoints for a group of notes.
    public func calculateBeamEndpoints(
        stemEnds: [CGPoint],
        stemDirection: StemDirection
    ) -> (start: CGPoint, end: CGPoint, slope: CGFloat)? {
        guard let firstStemEnd = stemEnds.first,
              let lastStemEnd = stemEnds.last,
              stemEnds.count >= 2 else {
            return nil
        }

        // Calculate ideal slope
        let dx = lastStemEnd.x - firstStemEnd.x
        guard dx != 0 else {
            return (firstStemEnd, lastStemEnd, 0)
        }

        let dy = lastStemEnd.y - firstStemEnd.y
        var slope = dy / dx

        // Limit slope to maximum
        slope = max(-config.maxBeamSlope, min(config.maxBeamSlope, slope))

        // Recalculate end point with limited slope
        let adjustedEndY = firstStemEnd.y + slope * dx

        // Check if all stems can reach the beam
        var beamStartY = firstStemEnd.y
        var beamEndY = adjustedEndY

        for stemEnd in stemEnds {
            let beamYAtStem = firstStemEnd.y + slope * (stemEnd.x - firstStemEnd.x)

            if stemDirection == .up {
                // Beam should be above all stems
                if stemEnd.y < beamYAtStem {
                    let adjustment = beamYAtStem - stemEnd.y
                    beamStartY -= adjustment
                    beamEndY -= adjustment
                }
            } else {
                // Beam should be below all stems
                if stemEnd.y > beamYAtStem {
                    let adjustment = stemEnd.y - beamYAtStem
                    beamStartY += adjustment
                    beamEndY += adjustment
                }
            }
        }

        return (
            CGPoint(x: firstStemEnd.x, y: beamStartY),
            CGPoint(x: lastStemEnd.x, y: beamEndY),
            slope
        )
    }

    /// Calculates stem lengths for beamed notes.
    public func calculateBeamedStemLengths(
        notePositions: [CGPoint],
        beamStart: CGPoint,
        beamSlope: CGFloat,
        stemDirection: StemDirection,
        minimumLength: CGFloat
    ) -> [CGFloat] {
        return notePositions.map { notePos in
            let beamYAtNote = beamStart.y + beamSlope * (notePos.x - beamStart.x)
            var stemLength = abs(beamYAtNote - notePos.y)
            return max(stemLength, minimumLength)
        }
    }

    // MARK: - Grace Note Beams

    /// Renders a grace note beam (thinner).
    public func renderGraceNoteBeam(
        from start: CGPoint,
        to end: CGPoint,
        color: CGColor,
        in context: CGContext
    ) {
        let graceThickness = config.beamThickness * config.graceNoteBeamScale
        renderBeam(from: start, to: end, thickness: graceThickness, color: color, in: context)
    }

    // MARK: - Tremolo Beams

    /// Renders tremolo beams.
    public func renderTremoloBeams(
        between note1: CGPoint,
        and note2: CGPoint,
        count: Int,
        thickness: CGFloat,
        color: CGColor,
        in context: CGContext
    ) {
        guard count > 0 else { return }

        // Calculate midpoint and angle
        let midX = (note1.x + note2.x) / 2
        let midY = (note1.y + note2.y) / 2
        let totalHeight = CGFloat(count) * thickness + CGFloat(count - 1) * config.beamSpacing

        var currentY = midY - totalHeight / 2

        for _ in 0..<count {
            let halfWidth = config.tremoloBeamWidth / 2

            renderBeam(
                from: CGPoint(x: midX - halfWidth, y: currentY),
                to: CGPoint(x: midX + halfWidth, y: currentY),
                thickness: thickness,
                color: color,
                in: context
            )

            currentY += thickness + config.beamSpacing
        }
    }

    /// Renders a single-note tremolo.
    public func renderSingleNoteTremolo(
        at stemEnd: CGPoint,
        count: Int,
        stemDirection: StemDirection,
        color: CGColor,
        in context: CGContext
    ) {
        guard count > 0 else { return }

        let angle: CGFloat = stemDirection == .up ? -0.3 : 0.3
        let halfWidth = config.tremoloBeamWidth / 2
        let spacing = config.beamThickness + config.beamSpacing

        var currentY = stemEnd.y + (stemDirection == .up ? spacing : -spacing)

        for _ in 0..<count {
            let leftY = currentY - angle * halfWidth
            let rightY = currentY + angle * halfWidth

            renderBeam(
                from: CGPoint(x: stemEnd.x - halfWidth, y: leftY),
                to: CGPoint(x: stemEnd.x + halfWidth, y: rightY),
                thickness: config.beamThickness,
                color: color,
                in: context
            )

            currentY += stemDirection == .up ? spacing : -spacing
        }
    }
}

// MARK: - Beam Render Configuration

/// Configuration for beam rendering.
public struct BeamRenderConfiguration: Sendable {
    /// Beam thickness (in staff spaces).
    public var beamThickness: CGFloat = 0.5

    /// Spacing between beam levels.
    public var beamSpacing: CGFloat = 0.25

    /// Maximum beam slope.
    public var maxBeamSlope: CGFloat = 0.5

    /// Ideal beam slope for typical passages.
    public var idealBeamSlope: CGFloat = 0.25

    /// Minimum fractional beam length.
    public var minFractionalBeamLength: CGFloat = 1.0

    /// Default fractional beam length.
    public var defaultFractionalBeamLength: CGFloat = 1.25

    /// Scale factor for grace note beams.
    public var graceNoteBeamScale: CGFloat = 0.75

    /// Width of tremolo beams.
    public var tremoloBeamWidth: CGFloat = 1.5

    public init() {}
}

// MARK: - Beam Render Info Types

/// Information for rendering a beam group.
public struct BeamGroupRenderInfo: Sendable {
    /// Start point of primary beam.
    public var primaryBeamStart: CGPoint

    /// End point of primary beam.
    public var primaryBeamEnd: CGPoint

    /// Beam thickness.
    public var beamThickness: CGFloat

    /// Stem direction.
    public var stemDirection: StemDirection

    /// Secondary beams (16ths, 32nds, etc.).
    public var secondaryBeams: [BeamSegment]

    /// Slope of the primary beam.
    public var slope: CGFloat

    public init(
        primaryBeamStart: CGPoint,
        primaryBeamEnd: CGPoint,
        beamThickness: CGFloat,
        stemDirection: StemDirection,
        secondaryBeams: [BeamSegment] = [],
        slope: CGFloat = 0
    ) {
        self.primaryBeamStart = primaryBeamStart
        self.primaryBeamEnd = primaryBeamEnd
        self.beamThickness = beamThickness
        self.stemDirection = stemDirection
        self.secondaryBeams = secondaryBeams
        self.slope = slope
    }
}

/// A segment of a beam.
public struct BeamSegment: Sendable {
    /// Start point.
    public var start: CGPoint

    /// End point.
    public var end: CGPoint

    /// Beam level (1 = primary, 2 = secondary, etc.).
    public var level: Int

    public init(start: CGPoint, end: CGPoint, level: Int = 1) {
        self.start = start
        self.end = end
        self.level = level
    }
}

/// Information for a beam level.
public struct BeamLevelInfo: Sendable {
    /// Beam level (1 = 8th, 2 = 16th, etc.).
    public var level: Int

    /// Segments at this level.
    public var segments: [BeamSegment]

    public init(level: Int, segments: [BeamSegment]) {
        self.level = level
        self.segments = segments
    }
}

/// Side for fractional beams.
public enum FractionalBeamSide: Sendable {
    case left
    case right
}

// MARK: - Beam Group Builder

/// Helper for building beam group render info.
public struct BeamGroupBuilder {
    private var stemEnds: [CGPoint] = []
    private var noteDurations: [Int] = [] // Number of beams for each note
    private var stemDirection: StemDirection

    public init(stemDirection: StemDirection) {
        self.stemDirection = stemDirection
    }

    /// Adds a note to the beam group.
    public mutating func addNote(stemEnd: CGPoint, beamCount: Int) {
        stemEnds.append(stemEnd)
        noteDurations.append(beamCount)
    }

    /// Builds the beam group render info.
    public func build(config: BeamRenderConfiguration) -> BeamGroupRenderInfo? {
        guard let firstEnd = stemEnds.first,
              let lastEnd = stemEnds.last,
              stemEnds.count >= 2 else {
            return nil
        }

        // Calculate primary beam
        let dx = lastEnd.x - firstEnd.x
        let slope = dx != 0 ? (lastEnd.y - firstEnd.y) / dx : 0
        let clampedSlope = max(-config.maxBeamSlope, min(config.maxBeamSlope, slope))

        // Build secondary beams based on note durations
        var secondaryBeams: [BeamSegment] = []
        let maxBeams = noteDurations.max() ?? 1

        // Only iterate if there are secondary beams (level 2+)
        guard maxBeams >= 2 else {
            return BeamGroupRenderInfo(
                primaryBeamStart: firstEnd,
                primaryBeamEnd: CGPoint(x: lastEnd.x, y: firstEnd.y + clampedSlope * dx),
                beamThickness: config.beamThickness,
                stemDirection: stemDirection,
                secondaryBeams: [],
                slope: clampedSlope
            )
        }

        for level in 2...maxBeams {
            var currentSegmentStart: Int? = nil

            for (index, beamCount) in noteDurations.enumerated() {
                if beamCount >= level {
                    if currentSegmentStart == nil {
                        currentSegmentStart = index
                    }
                } else {
                    if let start = currentSegmentStart {
                        // Close the segment
                        let yOffset = CGFloat(level - 1) * (config.beamThickness + config.beamSpacing)
                        let directionMultiplier: CGFloat = stemDirection == .up ? 1 : -1

                        let segmentStartY = stemEnds[start].y + yOffset * directionMultiplier
                        let segmentEndY = stemEnds[index - 1].y + yOffset * directionMultiplier

                        secondaryBeams.append(BeamSegment(
                            start: CGPoint(x: stemEnds[start].x, y: segmentStartY),
                            end: CGPoint(x: stemEnds[index - 1].x, y: segmentEndY),
                            level: level
                        ))
                        currentSegmentStart = nil
                    }
                }
            }

            // Handle segment that extends to the end
            if let start = currentSegmentStart {
                let lastIndex = stemEnds.count - 1
                let yOffset = CGFloat(level - 1) * (config.beamThickness + config.beamSpacing)
                let directionMultiplier: CGFloat = stemDirection == .up ? 1 : -1

                let segmentStartY = stemEnds[start].y + yOffset * directionMultiplier
                let segmentEndY = stemEnds[lastIndex].y + yOffset * directionMultiplier

                secondaryBeams.append(BeamSegment(
                    start: CGPoint(x: stemEnds[start].x, y: segmentStartY),
                    end: CGPoint(x: stemEnds[lastIndex].x, y: segmentEndY),
                    level: level
                ))
            }
        }

        return BeamGroupRenderInfo(
            primaryBeamStart: firstEnd,
            primaryBeamEnd: CGPoint(x: lastEnd.x, y: firstEnd.y + clampedSlope * dx),
            beamThickness: config.beamThickness,
            stemDirection: stemDirection,
            secondaryBeams: secondaryBeams,
            slope: clampedSlope
        )
    }
}
