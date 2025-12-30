import Foundation
import CoreGraphics
import MusicNotationCore

// MARK: - Staff Renderer

/// Renders staff lines, ledger lines, and barlines.
public final class StaffRenderer {
    /// Configuration for staff rendering.
    public var config: StaffRenderConfiguration

    public init(config: StaffRenderConfiguration = StaffRenderConfiguration()) {
        self.config = config
    }

    // MARK: - Staff Lines

    /// Renders staff lines.
    public func renderStaffLines(
        at origin: CGPoint,
        width: CGFloat,
        lineCount: Int,
        staffSpacing: CGFloat,
        color: CGColor,
        in context: CGContext
    ) {
        context.saveGState()
        context.setStrokeColor(color)
        context.setLineWidth(config.staffLineThickness)

        for i in 0..<lineCount {
            let y = origin.y + CGFloat(i) * staffSpacing
            context.move(to: CGPoint(x: origin.x, y: y))
            context.addLine(to: CGPoint(x: origin.x + width, y: y))
        }

        context.strokePath()
        context.restoreGState()
    }

    /// Renders staff lines with custom positions (for non-standard staves).
    public func renderStaffLinesAtPositions(
        _ yPositions: [CGFloat],
        startX: CGFloat,
        endX: CGFloat,
        color: CGColor,
        in context: CGContext
    ) {
        context.saveGState()
        context.setStrokeColor(color)
        context.setLineWidth(config.staffLineThickness)

        for y in yPositions {
            context.move(to: CGPoint(x: startX, y: y))
            context.addLine(to: CGPoint(x: endX, y: y))
        }

        context.strokePath()
        context.restoreGState()
    }

    // MARK: - Ledger Lines

    /// Renders ledger lines for a note.
    public func renderLedgerLines(
        at noteX: CGFloat,
        staffPosition: Int,
        noteheadWidth: CGFloat,
        staffTop: CGFloat,
        staffSpacing: CGFloat,
        color: CGColor,
        in context: CGContext
    ) {
        // Staff positions: 0 = bottom line, 8 = top line for 5-line staff
        // Ledger lines needed above staff (position > 8) or below (position < 0)

        guard staffPosition < 0 || staffPosition > 8 else { return }

        context.saveGState()
        context.setStrokeColor(color)
        context.setLineWidth(config.ledgerLineThickness)

        let extension_ = config.ledgerLineExtension
        let startX = noteX - extension_
        let endX = noteX + noteheadWidth + extension_

        if staffPosition > 8 {
            // Ledger lines above staff
            var linePosition = 10 // First ledger line above (C above treble staff)
            while linePosition <= staffPosition {
                if linePosition % 2 == 0 { // Only on line positions
                    let y = staffTop - CGFloat(linePosition - 8) * (staffSpacing / 2)
                    context.move(to: CGPoint(x: startX, y: y))
                    context.addLine(to: CGPoint(x: endX, y: y))
                }
                linePosition += 2
            }
        } else {
            // Ledger lines below staff
            var linePosition = -2 // First ledger line below
            while linePosition >= staffPosition {
                if linePosition % 2 == 0 { // Only on line positions
                    let y = staffTop + CGFloat(-linePosition) * (staffSpacing / 2) + staffSpacing * 4
                    context.move(to: CGPoint(x: startX, y: y))
                    context.addLine(to: CGPoint(x: endX, y: y))
                }
                linePosition -= 2
            }
        }

        context.strokePath()
        context.restoreGState()
    }

    /// Renders ledger lines for a chord (considering all notes).
    public func renderChordLedgerLines(
        at chordX: CGFloat,
        staffPositions: [Int],
        noteheadWidth: CGFloat,
        staffTop: CGFloat,
        staffSpacing: CGFloat,
        color: CGColor,
        in context: CGContext
    ) {
        guard !staffPositions.isEmpty else { return }

        let minPosition = staffPositions.min() ?? 0
        let maxPosition = staffPositions.max() ?? 8

        // Render combined ledger lines
        if maxPosition > 8 || minPosition < 0 {
            context.saveGState()
            context.setStrokeColor(color)
            context.setLineWidth(config.ledgerLineThickness)

            let extension_ = config.ledgerLineExtension
            let startX = chordX - extension_
            let endX = chordX + noteheadWidth + extension_

            // Above staff
            if maxPosition > 8 {
                var linePosition = 10
                while linePosition <= maxPosition {
                    if linePosition % 2 == 0 {
                        let y = staffTop - CGFloat(linePosition - 8) * (staffSpacing / 2)
                        context.move(to: CGPoint(x: startX, y: y))
                        context.addLine(to: CGPoint(x: endX, y: y))
                    }
                    linePosition += 2
                }
            }

            // Below staff
            if minPosition < 0 {
                var linePosition = -2
                while linePosition >= minPosition {
                    if linePosition % 2 == 0 {
                        let y = staffTop + CGFloat(-linePosition) * (staffSpacing / 2) + staffSpacing * 4
                        context.move(to: CGPoint(x: startX, y: y))
                        context.addLine(to: CGPoint(x: endX, y: y))
                    }
                    linePosition -= 2
                }
            }

            context.strokePath()
            context.restoreGState()
        }
    }

    // MARK: - Barlines

    /// Renders a regular barline.
    public func renderBarline(
        at x: CGFloat,
        topY: CGFloat,
        bottomY: CGFloat,
        color: CGColor,
        in context: CGContext
    ) {
        context.saveGState()
        context.setStrokeColor(color)
        context.setLineWidth(config.thinBarlineThickness)
        context.move(to: CGPoint(x: x, y: topY))
        context.addLine(to: CGPoint(x: x, y: bottomY))
        context.strokePath()
        context.restoreGState()
    }

    /// Renders a barline with style.
    public func renderBarline(
        style: BarStyle,
        at x: CGFloat,
        topY: CGFloat,
        bottomY: CGFloat,
        color: CGColor,
        in context: CGContext
    ) {
        context.saveGState()
        context.setStrokeColor(color)

        switch style {
        case .regular:
            context.setLineWidth(config.thinBarlineThickness)
            drawLine(from: CGPoint(x: x, y: topY), to: CGPoint(x: x, y: bottomY), in: context)

        case .dotted:
            context.setLineWidth(config.thinBarlineThickness)
            context.setLineDash(phase: 0, lengths: [config.dottedBarlineDash, config.dottedBarlineDash])
            drawLine(from: CGPoint(x: x, y: topY), to: CGPoint(x: x, y: bottomY), in: context)

        case .dashed:
            context.setLineWidth(config.thinBarlineThickness)
            context.setLineDash(phase: 0, lengths: [config.dashedBarlineDash, config.dashedBarlineGap])
            drawLine(from: CGPoint(x: x, y: topY), to: CGPoint(x: x, y: bottomY), in: context)

        case .heavy:
            context.setLineWidth(config.thickBarlineThickness)
            drawLine(from: CGPoint(x: x, y: topY), to: CGPoint(x: x, y: bottomY), in: context)

        case .lightLight:
            context.setLineWidth(config.thinBarlineThickness)
            let gap = config.doubleBarlineGap
            drawLine(from: CGPoint(x: x - gap, y: topY), to: CGPoint(x: x - gap, y: bottomY), in: context)
            drawLine(from: CGPoint(x: x, y: topY), to: CGPoint(x: x, y: bottomY), in: context)

        case .lightHeavy:
            // Thin then thick (final barline)
            context.setLineWidth(config.thinBarlineThickness)
            let offset = config.doubleBarlineGap + config.thickBarlineThickness / 2
            drawLine(from: CGPoint(x: x - offset, y: topY), to: CGPoint(x: x - offset, y: bottomY), in: context)
            context.setLineWidth(config.thickBarlineThickness)
            drawLine(from: CGPoint(x: x, y: topY), to: CGPoint(x: x, y: bottomY), in: context)

        case .heavyLight:
            // Thick then thin (start repeat)
            context.setLineWidth(config.thickBarlineThickness)
            drawLine(from: CGPoint(x: x, y: topY), to: CGPoint(x: x, y: bottomY), in: context)
            context.setLineWidth(config.thinBarlineThickness)
            let offset = config.doubleBarlineGap + config.thickBarlineThickness / 2
            drawLine(from: CGPoint(x: x + offset, y: topY), to: CGPoint(x: x + offset, y: bottomY), in: context)

        case .heavyHeavy:
            context.setLineWidth(config.thickBarlineThickness)
            let gap = config.doubleBarlineGap
            drawLine(from: CGPoint(x: x - gap, y: topY), to: CGPoint(x: x - gap, y: bottomY), in: context)
            drawLine(from: CGPoint(x: x, y: topY), to: CGPoint(x: x, y: bottomY), in: context)

        case .tick:
            context.setLineWidth(config.thinBarlineThickness)
            let tickLength = config.tickBarlineLength
            drawLine(from: CGPoint(x: x, y: topY), to: CGPoint(x: x, y: topY + tickLength), in: context)

        case .short:
            context.setLineWidth(config.thinBarlineThickness)
            let midY = (topY + bottomY) / 2
            let halfLength = config.shortBarlineLength / 2
            drawLine(from: CGPoint(x: x, y: midY - halfLength), to: CGPoint(x: x, y: midY + halfLength), in: context)

        case .none:
            break
        }

        context.restoreGState()
    }

    /// Renders repeat dots.
    public func renderRepeatDots(
        at x: CGFloat,
        staffTop: CGFloat,
        staffSpacing: CGFloat,
        color: CGColor,
        in context: CGContext
    ) {
        context.saveGState()
        context.setFillColor(color)

        let dotRadius = config.repeatDotRadius

        // Two dots: between lines 2-3 and 3-4 (positions 1.5 and 2.5 staff spaces from top)
        let dot1Y = staffTop + staffSpacing * 1.5
        let dot2Y = staffTop + staffSpacing * 2.5

        // Draw filled circles
        context.fillEllipse(in: CGRect(
            x: x - dotRadius,
            y: dot1Y - dotRadius,
            width: dotRadius * 2,
            height: dotRadius * 2
        ))

        context.fillEllipse(in: CGRect(
            x: x - dotRadius,
            y: dot2Y - dotRadius,
            width: dotRadius * 2,
            height: dotRadius * 2
        ))

        context.restoreGState()
    }

    /// Renders a complete repeat barline (with dots).
    public func renderRepeatBarline(
        direction: RepeatDirection,
        at x: CGFloat,
        topY: CGFloat,
        bottomY: CGFloat,
        staffTop: CGFloat,
        staffSpacing: CGFloat,
        color: CGColor,
        in context: CGContext
    ) {
        let dotsOffset = config.repeatDotsOffset

        switch direction {
        case .forward:
            // Heavy-light with dots after
            renderBarline(style: .heavyLight, at: x, topY: topY, bottomY: bottomY, color: color, in: context)
            let dotsX = x + config.thickBarlineThickness / 2 + config.doubleBarlineGap + config.thinBarlineThickness + dotsOffset
            renderRepeatDots(at: dotsX, staffTop: staffTop, staffSpacing: staffSpacing, color: color, in: context)

        case .backward:
            // Dots before light-heavy
            let dotsX = x - config.thickBarlineThickness / 2 - config.doubleBarlineGap - config.thinBarlineThickness - dotsOffset
            renderRepeatDots(at: dotsX, staffTop: staffTop, staffSpacing: staffSpacing, color: color, in: context)
            renderBarline(style: .lightHeavy, at: x, topY: topY, bottomY: bottomY, color: color, in: context)
        }
    }

    // MARK: - System Barlines

    /// Renders a system barline (connecting multiple staves).
    public func renderSystemBarline(
        at x: CGFloat,
        staffTops: [CGFloat],
        staffBottoms: [CGFloat],
        connections: [BarlineConnection],
        style: BarStyle,
        color: CGColor,
        in context: CGContext
    ) {
        guard !staffTops.isEmpty, staffTops.count == staffBottoms.count else { return }

        // Render individual staff barlines
        for i in 0..<staffTops.count {
            renderBarline(style: style, at: x, topY: staffTops[i], bottomY: staffBottoms[i], color: color, in: context)
        }

        // Render connections between staves
        for connection in connections {
            guard connection.startStaff < staffBottoms.count,
                  connection.endStaff < staffTops.count else { continue }

            let connectTop = staffBottoms[connection.startStaff]
            let connectBottom = staffTops[connection.endStaff]

            if connection.connectionType == .full {
                // Draw connecting line
                context.saveGState()
                context.setStrokeColor(color)
                context.setLineWidth(style == .heavy ? config.thickBarlineThickness : config.thinBarlineThickness)
                drawLine(from: CGPoint(x: x, y: connectTop), to: CGPoint(x: x, y: connectBottom), in: context)
                context.restoreGState()
            }
        }
    }

    // MARK: - Helper Methods

    private func drawLine(from start: CGPoint, to end: CGPoint, in context: CGContext) {
        context.move(to: start)
        context.addLine(to: end)
        context.strokePath()
    }
}

// MARK: - Staff Render Configuration

/// Configuration for staff rendering.
public struct StaffRenderConfiguration: Sendable {
    /// Staff line thickness.
    public var staffLineThickness: CGFloat = 0.13

    /// Ledger line thickness.
    public var ledgerLineThickness: CGFloat = 0.16

    /// Extension of ledger line beyond notehead.
    public var ledgerLineExtension: CGFloat = 0.4

    /// Thin barline thickness.
    public var thinBarlineThickness: CGFloat = 0.16

    /// Thick barline thickness.
    public var thickBarlineThickness: CGFloat = 0.5

    /// Gap between double barlines.
    public var doubleBarlineGap: CGFloat = 0.4

    /// Dash length for dotted barlines.
    public var dottedBarlineDash: CGFloat = 0.5

    /// Dash length for dashed barlines.
    public var dashedBarlineDash: CGFloat = 1.0

    /// Gap for dashed barlines.
    public var dashedBarlineGap: CGFloat = 0.5

    /// Length of tick barline.
    public var tickBarlineLength: CGFloat = 1.0

    /// Length of short barline.
    public var shortBarlineLength: CGFloat = 2.0

    /// Radius of repeat dots.
    public var repeatDotRadius: CGFloat = 0.2

    /// Offset of repeat dots from barline.
    public var repeatDotsOffset: CGFloat = 0.5

    public init() {}
}

// MARK: - Barline Connection (for system barlines)

/// Connection between staves for system barlines.
public struct BarlineConnection: Sendable {
    /// First staff index.
    public var startStaff: Int

    /// Last staff index.
    public var endStaff: Int

    /// Connection type.
    public var connectionType: ConnectionType

    public init(startStaff: Int, endStaff: Int, connectionType: ConnectionType) {
        self.startStaff = startStaff
        self.endStaff = endStaff
        self.connectionType = connectionType
    }

    /// Type of barline connection.
    public enum ConnectionType: Sendable {
        case full       // Connect through all staves
        case grouped    // Connect only within groups
        case none       // No connection
    }
}

// MARK: - Repeat Direction

/// Direction of a repeat barline.
public enum RepeatDirection: String, Sendable {
    case forward
    case backward
}
