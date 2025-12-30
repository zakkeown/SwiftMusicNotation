import Foundation
import CoreGraphics
import MusicNotationCore

// MARK: - Horizontal Spacing Engine

/// Computes horizontal spacing for music notation using a logarithmic duration-based algorithm.
/// Based on engraving principles where note spacing is proportional to the log of duration.
public final class HorizontalSpacingEngine {
    /// Configuration for spacing calculations.
    public var config: SpacingConfiguration

    public init(config: SpacingConfiguration = SpacingConfiguration()) {
        self.config = config
    }

    /// Computes spacing for a measure.
    /// - Parameters:
    ///   - elements: Elements in the measure grouped by voice.
    ///   - divisions: Divisions per quarter note.
    ///   - measureDuration: Total duration of measure in divisions.
    /// - Returns: Spacing result with positioned columns.
    public func computeSpacing(
        elements: [SpacingElement],
        divisions: Int,
        measureDuration: Int
    ) -> SpacingResult {
        // Group elements by their time position
        var columns: [Int: SpacingColumn] = [:]

        for element in elements {
            let position = element.position
            if columns[position] == nil {
                columns[position] = SpacingColumn(position: position)
            }
            columns[position]?.elements.append(element)
        }

        // Sort columns by position
        let sortedPositions = columns.keys.sorted()

        // Calculate minimum widths for each column
        for position in sortedPositions {
            guard var column = columns[position] else { continue }
            column.minWidth = computeMinWidth(for: column)
            columns[position] = column
        }

        // Calculate ideal widths based on durations to next event
        var columnWidths: [Int: CGFloat] = [:]

        for (index, position) in sortedPositions.enumerated() {
            let nextPosition = index + 1 < sortedPositions.count
                ? sortedPositions[index + 1]
                : measureDuration

            let durationToNext = nextPosition - position
            let idealWidth = computeIdealWidth(
                duration: durationToNext,
                divisions: divisions
            )

            let minWidth = columns[position]?.minWidth ?? config.minimumNoteSpacing
            columnWidths[position] = max(idealWidth, minWidth)
        }

        // Calculate x positions
        var currentX = config.measureLeftPadding
        var positionedColumns: [SpacingColumn] = []

        for position in sortedPositions {
            guard var column = columns[position] else { continue }
            column.x = currentX
            positionedColumns.append(column)
            currentX += columnWidths[position] ?? config.minimumNoteSpacing
        }

        let totalWidth = currentX + config.measureRightPadding

        return SpacingResult(
            columns: positionedColumns,
            totalWidth: totalWidth,
            measureDuration: measureDuration
        )
    }

    /// Computes the ideal width for a duration using logarithmic spacing.
    /// - Parameters:
    ///   - duration: Duration in divisions.
    ///   - divisions: Divisions per quarter note.
    /// - Returns: Ideal width in points.
    public func computeIdealWidth(duration: Int, divisions: Int) -> CGFloat {
        guard duration > 0 && divisions > 0 else {
            return config.minimumNoteSpacing
        }

        // Convert to quarter notes
        let quarterNotes = Double(duration) / Double(divisions)

        // Logarithmic spacing formula:
        // width = baseWidth * (1 + spacingFactor * log2(duration_ratio))
        // where duration_ratio is relative to a quarter note
        let logRatio = log2(max(quarterNotes, 0.0625))  // min 1/16 note
        let width = config.quarterNoteSpacing * (1 + config.spacingFactor * logRatio)

        return max(CGFloat(width), config.minimumNoteSpacing)
    }

    /// Computes minimum width needed for a column based on its elements.
    private func computeMinWidth(for column: SpacingColumn) -> CGFloat {
        var maxWidth: CGFloat = config.minimumNoteSpacing

        for element in column.elements {
            var elementWidth: CGFloat = 0

            switch element.type {
            case .note:
                elementWidth = config.noteheadWidth
                if element.hasAccidental {
                    elementWidth += config.accidentalWidth + config.accidentalSpacing
                }
                if element.hasDots {
                    elementWidth += CGFloat(element.dotCount) * (config.dotWidth + config.dotSpacing)
                }

            case .rest:
                elementWidth = config.restWidth

            case .clef:
                elementWidth = config.clefWidth

            case .keySignature:
                elementWidth = CGFloat(element.accidentalCount) * config.keyAccidentalWidth

            case .timeSignature:
                elementWidth = config.timeSignatureWidth

            case .barline:
                elementWidth = config.barlineWidth
            }

            maxWidth = max(maxWidth, elementWidth)
        }

        return maxWidth
    }

    /// Justifies columns to fit a target width.
    public func justify(
        result: SpacingResult,
        targetWidth: CGFloat
    ) -> SpacingResult {
        guard !result.columns.isEmpty else { return result }

        let currentWidth = result.totalWidth
        let extraSpace = targetWidth - currentWidth

        guard extraSpace > 0 else { return result }

        // Distribute extra space proportionally based on original widths
        let totalOriginalWidth = result.columns.enumerated().reduce(CGFloat(0)) { sum, pair in
            let (index, _) = pair
            if index + 1 < result.columns.count {
                return sum + (result.columns[index + 1].x - result.columns[index].x)
            }
            return sum + config.measureRightPadding
        }

        var justifiedColumns: [SpacingColumn] = []
        var currentX = config.measureLeftPadding

        for (index, var column) in result.columns.enumerated() {
            column.x = currentX
            justifiedColumns.append(column)

            // Calculate width to next column
            let originalWidth: CGFloat
            if index + 1 < result.columns.count {
                originalWidth = result.columns[index + 1].x - result.columns[index].x
            } else {
                originalWidth = config.measureRightPadding
            }

            // Proportional extra space
            let proportionalExtra = totalOriginalWidth > 0
                ? extraSpace * (originalWidth / totalOriginalWidth)
                : extraSpace / CGFloat(result.columns.count)

            currentX += originalWidth + proportionalExtra
        }

        return SpacingResult(
            columns: justifiedColumns,
            totalWidth: targetWidth,
            measureDuration: result.measureDuration
        )
    }
}

// MARK: - Configuration

/// Configuration for spacing calculations.
public struct SpacingConfiguration: Sendable {
    /// Base width for a quarter note in points.
    public var quarterNoteSpacing: Double = 30.0

    /// Spacing factor for logarithmic scaling (0 = linear, higher = more logarithmic).
    public var spacingFactor: Double = 0.7

    /// Minimum spacing between any two events.
    public var minimumNoteSpacing: CGFloat = 12.0

    /// Width of a notehead.
    public var noteheadWidth: CGFloat = 10.0

    /// Width reserved for an accidental.
    public var accidentalWidth: CGFloat = 8.0

    /// Space between accidental and notehead.
    public var accidentalSpacing: CGFloat = 2.0

    /// Width of a dot.
    public var dotWidth: CGFloat = 3.0

    /// Space before a dot.
    public var dotSpacing: CGFloat = 3.0

    /// Width of a rest glyph.
    public var restWidth: CGFloat = 12.0

    /// Width of a clef.
    public var clefWidth: CGFloat = 18.0

    /// Width per key signature accidental.
    public var keyAccidentalWidth: CGFloat = 8.0

    /// Width of time signature.
    public var timeSignatureWidth: CGFloat = 16.0

    /// Width of a barline.
    public var barlineWidth: CGFloat = 1.0

    /// Padding at start of measure.
    public var measureLeftPadding: CGFloat = 4.0

    /// Padding at end of measure.
    public var measureRightPadding: CGFloat = 4.0

    public init() {}
}

// MARK: - Spacing Types

/// An element to be spaced.
public struct SpacingElement: Sendable {
    /// Time position in divisions.
    public var position: Int

    /// Voice number.
    public var voice: Int

    /// Staff number.
    public var staff: Int

    /// Element type.
    public var type: SpacingElementType

    /// Whether this element has an accidental.
    public var hasAccidental: Bool

    /// Number of dots.
    public var dotCount: Int

    /// Whether this has dots.
    public var hasDots: Bool { dotCount > 0 }

    /// Number of accidentals (for key signatures).
    public var accidentalCount: Int

    public init(
        position: Int,
        voice: Int = 1,
        staff: Int = 1,
        type: SpacingElementType,
        hasAccidental: Bool = false,
        dotCount: Int = 0,
        accidentalCount: Int = 0
    ) {
        self.position = position
        self.voice = voice
        self.staff = staff
        self.type = type
        self.hasAccidental = hasAccidental
        self.dotCount = dotCount
        self.accidentalCount = accidentalCount
    }
}

/// Type of spacing element.
public enum SpacingElementType: Sendable {
    case note
    case rest
    case clef
    case keySignature
    case timeSignature
    case barline
}

/// A column of elements at the same time position.
public struct SpacingColumn: Sendable {
    /// Time position in divisions.
    public var position: Int

    /// X position in points.
    public var x: CGFloat

    /// Minimum width needed.
    public var minWidth: CGFloat

    /// Elements in this column.
    public var elements: [SpacingElement]

    public init(position: Int, x: CGFloat = 0, minWidth: CGFloat = 0, elements: [SpacingElement] = []) {
        self.position = position
        self.x = x
        self.minWidth = minWidth
        self.elements = elements
    }
}

/// Result of spacing calculation.
public struct SpacingResult: Sendable {
    /// Positioned columns.
    public var columns: [SpacingColumn]

    /// Total width of the measure.
    public var totalWidth: CGFloat

    /// Duration of the measure in divisions.
    public var measureDuration: Int

    public init(columns: [SpacingColumn] = [], totalWidth: CGFloat = 0, measureDuration: Int = 0) {
        self.columns = columns
        self.totalWidth = totalWidth
        self.measureDuration = measureDuration
    }

    /// Gets the x position for a given time position.
    public func xPosition(for timePosition: Int) -> CGFloat? {
        columns.first { $0.position == timePosition }?.x
    }

    /// Gets the x position by interpolating between columns.
    public func interpolatedX(for timePosition: Int) -> CGFloat {
        guard !columns.isEmpty else { return 0 }

        // Find surrounding columns
        var leftColumn: SpacingColumn?
        var rightColumn: SpacingColumn?

        for column in columns {
            if column.position <= timePosition {
                leftColumn = column
            }
            if column.position >= timePosition && rightColumn == nil {
                rightColumn = column
            }
        }

        guard let left = leftColumn else {
            return columns.first?.x ?? 0
        }

        guard let right = rightColumn, right.position != left.position else {
            return left.x
        }

        // Linear interpolation
        let ratio = CGFloat(timePosition - left.position) / CGFloat(right.position - left.position)
        return left.x + ratio * (right.x - left.x)
    }
}

// MARK: - Measure Spacing

/// Spacing for a complete measure.
public struct MeasureSpacing: Sendable {
    /// Measure index.
    public var measureIndex: Int

    /// Natural (minimum) width.
    public var naturalWidth: CGFloat

    /// Justified width (if different).
    public var justifiedWidth: CGFloat?

    /// Column positions.
    public var columns: [SpacingColumn]

    /// Width for the measure.
    public var width: CGFloat {
        justifiedWidth ?? naturalWidth
    }

    public init(measureIndex: Int, naturalWidth: CGFloat, justifiedWidth: CGFloat? = nil, columns: [SpacingColumn] = []) {
        self.measureIndex = measureIndex
        self.naturalWidth = naturalWidth
        self.justifiedWidth = justifiedWidth
        self.columns = columns
    }
}

// MARK: - System Spacing

/// Computes spacing for a system (multiple measures across the page).
public final class SystemSpacingEngine {
    private let measureSpacingEngine: HorizontalSpacingEngine

    public init(config: SpacingConfiguration = SpacingConfiguration()) {
        self.measureSpacingEngine = HorizontalSpacingEngine(config: config)
    }

    /// Computes which measures fit on a system given a target width.
    public func computeSystemBreaks(
        measureWidths: [CGFloat],
        systemWidth: CGFloat,
        startIndex: Int = 0
    ) -> [SystemBreak] {
        var breaks: [SystemBreak] = []
        var currentStart = startIndex
        var currentWidth: CGFloat = 0

        for (index, width) in measureWidths.enumerated() where index >= startIndex {
            if currentWidth + width > systemWidth && currentStart < index {
                // Break before this measure
                breaks.append(SystemBreak(
                    startMeasure: currentStart,
                    endMeasure: index - 1,
                    naturalWidth: currentWidth
                ))
                currentStart = index
                currentWidth = width
            } else {
                currentWidth += width
            }
        }

        // Add final system
        if currentStart < measureWidths.count {
            breaks.append(SystemBreak(
                startMeasure: currentStart,
                endMeasure: measureWidths.count - 1,
                naturalWidth: currentWidth
            ))
        }

        return breaks
    }

    /// Justifies measures within a system to fill the available width.
    public func justifySystem(
        measureSpacings: [MeasureSpacing],
        systemWidth: CGFloat
    ) -> [MeasureSpacing] {
        let totalNaturalWidth = measureSpacings.reduce(0) { $0 + $1.naturalWidth }

        guard totalNaturalWidth < systemWidth else {
            return measureSpacings
        }

        let extraSpace = systemWidth - totalNaturalWidth
        let extraPerMeasure = extraSpace / CGFloat(measureSpacings.count)

        return measureSpacings.map { spacing in
            var justified = spacing
            justified.justifiedWidth = spacing.naturalWidth + extraPerMeasure
            return justified
        }
    }
}

/// A system break point.
public struct SystemBreak: Sendable {
    /// First measure index in the system.
    public var startMeasure: Int

    /// Last measure index in the system.
    public var endMeasure: Int

    /// Natural width of all measures combined.
    public var naturalWidth: CGFloat

    public init(startMeasure: Int, endMeasure: Int, naturalWidth: CGFloat) {
        self.startMeasure = startMeasure
        self.endMeasure = endMeasure
        self.naturalWidth = naturalWidth
    }

    /// Number of measures in this system.
    public var measureCount: Int {
        endMeasure - startMeasure + 1
    }
}
