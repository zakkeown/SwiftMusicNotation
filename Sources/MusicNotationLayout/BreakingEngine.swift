import Foundation
import CoreGraphics
import MusicNotationCore

// MARK: - Breaking Engine

/// Computes optimal system and page breaks for music notation.
/// Uses a dynamic programming approach similar to TeX's line-breaking algorithm.
public final class BreakingEngine {
    /// Configuration for breaking.
    public var config: BreakingConfiguration

    public init(config: BreakingConfiguration = BreakingConfiguration()) {
        self.config = config
    }

    // MARK: - System Breaking

    /// Computes optimal system breaks for a sequence of measures.
    /// - Parameters:
    ///   - measureWidths: The natural width of each measure.
    ///   - systemWidth: The available width for each system.
    ///   - breakHints: Optional hints for preferred break positions.
    /// - Returns: Array of system breaks.
    public func computeSystemBreaks(
        measureWidths: [CGFloat],
        systemWidth: CGFloat,
        breakHints: [BreakHint] = []
    ) -> [SystemBreak] {
        guard !measureWidths.isEmpty else { return [] }

        // Use dynamic programming to find optimal breaks
        let n = measureWidths.count

        // dp[i] = (cost, previousBreak) for optimal way to end a system at measure i
        var dp: [(cost: Double, prev: Int)] = Array(repeating: (Double.infinity, -1), count: n + 1)
        dp[0] = (0, -1)

        // Try all possible system endings
        for end in 1...n {
            // Try all possible system starts
            for start in 0..<end {
                let measuresInSystem = Array(start..<end)
                let naturalWidth = measuresInSystem.reduce(0) { $0 + measureWidths[$1] }

                // Check if this fits in a system
                let minWidth = naturalWidth + CGFloat(measuresInSystem.count - 1) * config.minimumMeasureGap
                if minWidth > systemWidth && measuresInSystem.count > 1 {
                    continue
                }

                // Calculate cost for this system
                let systemCost = calculateSystemCost(
                    naturalWidth: naturalWidth,
                    targetWidth: systemWidth,
                    measureCount: measuresInSystem.count,
                    breakHints: breakHints,
                    endMeasure: end - 1
                )

                let totalCost = dp[start].cost + systemCost
                if totalCost < dp[end].cost {
                    dp[end] = (totalCost, start)
                }
            }
        }

        // Reconstruct the breaks
        var breaks: [SystemBreak] = []
        var current = n
        while current > 0 {
            let start = dp[current].prev
            let naturalWidth = (start..<current).reduce(0) { $0 + measureWidths[$1] }
            breaks.append(SystemBreak(
                startMeasure: start,
                endMeasure: current - 1,
                naturalWidth: naturalWidth
            ))
            current = start
        }

        breaks.reverse()
        return breaks
    }

    /// Calculates the cost for a potential system.
    private func calculateSystemCost(
        naturalWidth: CGFloat,
        targetWidth: CGFloat,
        measureCount: Int,
        breakHints: [BreakHint],
        endMeasure: Int
    ) -> Double {
        var cost: Double = 0

        // Stretch/compress cost (badness)
        let ratio = Double(naturalWidth / targetWidth)
        if ratio < 1.0 {
            // Stretched - increasing cost as we stretch more
            let stretch = 1.0 - ratio
            cost += stretch * stretch * config.stretchPenalty
        } else {
            // Compressed - higher cost for compression
            let compress = ratio - 1.0
            cost += compress * compress * config.compressPenalty
        }

        // Penalty for too few measures
        if measureCount < config.minimumMeasuresPerSystem {
            cost += config.shortSystemPenalty * Double(config.minimumMeasuresPerSystem - measureCount)
        }

        // Penalty for too many measures
        if measureCount > config.maximumMeasuresPerSystem {
            cost += config.longSystemPenalty * Double(measureCount - config.maximumMeasuresPerSystem)
        }

        // Check for break hints
        for hint in breakHints {
            if hint.measureIndex == endMeasure {
                switch hint.type {
                case .preferred:
                    cost -= config.preferredBreakBonus
                case .required:
                    cost -= config.requiredBreakBonus
                case .forbidden:
                    cost += config.forbiddenBreakPenalty
                }
            }
        }

        return cost
    }

    // MARK: - Page Breaking

    /// Computes optimal page breaks for a sequence of systems.
    /// - Parameters:
    ///   - systemHeights: The height of each system.
    ///   - pageHeight: The available height for content on each page.
    ///   - breakHints: Optional hints for preferred break positions.
    /// - Returns: Array of page breaks.
    public func computePageBreaks(
        systemHeights: [CGFloat],
        pageHeight: CGFloat,
        systemGap: CGFloat,
        breakHints: [BreakHint] = []
    ) -> [PageBreakInfo] {
        guard !systemHeights.isEmpty else { return [] }

        let n = systemHeights.count

        // dp[i] = (cost, previousBreak) for optimal way to end a page at system i
        var dp: [(cost: Double, prev: Int)] = Array(repeating: (Double.infinity, -1), count: n + 1)
        dp[0] = (0, -1)

        for end in 1...n {
            for start in 0..<end {
                let systemsOnPage = Array(start..<end)

                // Calculate total height
                let contentHeight = systemsOnPage.reduce(0) { $0 + systemHeights[$1] }
                let gapsHeight = CGFloat(max(0, systemsOnPage.count - 1)) * systemGap
                let totalHeight = contentHeight + gapsHeight

                // Check if fits on page
                if totalHeight > pageHeight && systemsOnPage.count > 1 {
                    continue
                }

                // Calculate cost
                let pageCost = calculatePageCost(
                    contentHeight: totalHeight,
                    pageHeight: pageHeight,
                    systemCount: systemsOnPage.count,
                    breakHints: breakHints,
                    endSystem: end - 1
                )

                let totalCost = dp[start].cost + pageCost
                if totalCost < dp[end].cost {
                    dp[end] = (totalCost, start)
                }
            }
        }

        // Reconstruct breaks
        var breaks: [PageBreakInfo] = []
        var current = n
        while current > 0 {
            let start = dp[current].prev
            let systemsOnPage = Array(start..<current)
            let contentHeight = systemsOnPage.reduce(0.0) { $0 + systemHeights[$1] }

            breaks.append(PageBreakInfo(
                startSystem: start,
                endSystem: current - 1,
                contentHeight: contentHeight
            ))
            current = start
        }

        breaks.reverse()
        return breaks
    }

    /// Calculates the cost for a potential page.
    private func calculatePageCost(
        contentHeight: CGFloat,
        pageHeight: CGFloat,
        systemCount: Int,
        breakHints: [BreakHint],
        endSystem: Int
    ) -> Double {
        var cost: Double = 0

        // Vertical fill ratio
        let fillRatio = Double(contentHeight / pageHeight)

        if fillRatio < config.minimumPageFill {
            // Underfilled page - penalize
            let underfill = config.minimumPageFill - fillRatio
            cost += underfill * underfill * config.underfillPenalty
        }

        // Penalty for too few systems
        if systemCount < config.minimumSystemsPerPage {
            cost += config.fewSystemsPenalty * Double(config.minimumSystemsPerPage - systemCount)
        }

        // Check for break hints
        for hint in breakHints {
            if hint.measureIndex == endSystem {
                switch hint.type {
                case .preferred:
                    cost -= config.preferredBreakBonus
                case .required:
                    cost -= config.requiredBreakBonus
                case .forbidden:
                    cost += config.forbiddenBreakPenalty
                }
            }
        }

        return cost
    }

    // MARK: - Greedy Breaking (Faster Alternative)

    /// Simple greedy algorithm for system breaking (faster but less optimal).
    public func computeSystemBreaksGreedy(
        measureWidths: [CGFloat],
        systemWidth: CGFloat
    ) -> [SystemBreak] {
        guard !measureWidths.isEmpty else { return [] }

        var breaks: [SystemBreak] = []
        var currentStart = 0
        var currentWidth: CGFloat = 0

        for (index, width) in measureWidths.enumerated() {
            let proposedWidth = currentWidth + width + (currentWidth > 0 ? config.minimumMeasureGap : 0)

            if proposedWidth > systemWidth && currentStart < index {
                // Break before this measure
                let naturalWidth = (currentStart..<index).reduce(0) { $0 + measureWidths[$1] }
                breaks.append(SystemBreak(startMeasure: currentStart, endMeasure: index - 1, naturalWidth: naturalWidth))
                currentStart = index
                currentWidth = width
            } else {
                currentWidth = proposedWidth
            }
        }

        // Add final system
        if currentStart < measureWidths.count {
            let naturalWidth = (currentStart..<measureWidths.count).reduce(0) { $0 + measureWidths[$1] }
            breaks.append(SystemBreak(startMeasure: currentStart, endMeasure: measureWidths.count - 1, naturalWidth: naturalWidth))
        }

        return breaks
    }

    /// Simple greedy algorithm for page breaking.
    public func computePageBreaksGreedy(
        systemHeights: [CGFloat],
        pageHeight: CGFloat,
        systemGap: CGFloat
    ) -> [PageBreakInfo] {
        guard !systemHeights.isEmpty else { return [] }

        var breaks: [PageBreakInfo] = []
        var currentStart = 0
        var currentHeight: CGFloat = 0

        for (index, height) in systemHeights.enumerated() {
            let proposedHeight = currentHeight + height + (currentHeight > 0 ? systemGap : 0)

            if proposedHeight > pageHeight && currentStart < index {
                // Break before this system
                breaks.append(PageBreakInfo(
                    startSystem: currentStart,
                    endSystem: index - 1,
                    contentHeight: currentHeight
                ))
                currentStart = index
                currentHeight = height
            } else {
                currentHeight = proposedHeight
            }
        }

        // Add final page
        if currentStart < systemHeights.count {
            breaks.append(PageBreakInfo(
                startSystem: currentStart,
                endSystem: systemHeights.count - 1,
                contentHeight: currentHeight
            ))
        }

        return breaks
    }

    // MARK: - Justification

    /// Calculates spacing adjustments to justify measures within a system.
    public func justifySystem(
        measureWidths: [CGFloat],
        systemWidth: CGFloat,
        allowCompression: Bool = true
    ) -> JustificationResult {
        let naturalWidth = measureWidths.reduce(0, +)
        let difference = systemWidth - naturalWidth

        if difference >= 0 {
            // Need to stretch
            return distributeSpace(
                measureWidths: measureWidths,
                extraSpace: difference,
                isStretching: true
            )
        } else if allowCompression {
            // Need to compress
            return distributeSpace(
                measureWidths: measureWidths,
                extraSpace: difference,
                isStretching: false
            )
        } else {
            // Can't justify, return original widths
            return JustificationResult(
                adjustedWidths: measureWidths,
                stretchRatio: naturalWidth / systemWidth
            )
        }
    }

    private func distributeSpace(
        measureWidths: [CGFloat],
        extraSpace: CGFloat,
        isStretching: Bool
    ) -> JustificationResult {
        let totalWidth = measureWidths.reduce(0, +)
        var adjustedWidths: [CGFloat] = []

        // Distribute space proportionally to measure width
        for width in measureWidths {
            let proportion = width / totalWidth
            let adjustment = extraSpace * proportion
            adjustedWidths.append(width + adjustment)
        }

        let newTotal = adjustedWidths.reduce(0, +)
        return JustificationResult(
            adjustedWidths: adjustedWidths,
            stretchRatio: newTotal / totalWidth
        )
    }

    // MARK: - First/Last System Handling

    /// Adjusts breaking for first system (may need extra space for clef/key/time).
    public func adjustForFirstSystem(
        breaks: [SystemBreak],
        firstSystemExtraWidth: CGFloat,
        measureWidths: [CGFloat],
        systemWidth: CGFloat
    ) -> [SystemBreak] {
        guard let firstBreak = breaks.first else { return breaks }

        // Check if first system is overfull with the extra width
        let firstSystemWidth = (firstBreak.startMeasure...firstBreak.endMeasure)
            .reduce(0) { $0 + measureWidths[$1] } + firstSystemExtraWidth

        if firstSystemWidth > systemWidth && firstBreak.endMeasure > firstBreak.startMeasure {
            // Need to reduce measures in first system
            var result = breaks
            let newEndMeasure = max(firstBreak.startMeasure, firstBreak.endMeasure - 1)
            let newNaturalWidth = (firstBreak.startMeasure...newEndMeasure).reduce(0) { $0 + measureWidths[$1] }
            result[0] = SystemBreak(startMeasure: firstBreak.startMeasure, endMeasure: newEndMeasure, naturalWidth: newNaturalWidth)

            // Adjust subsequent breaks
            if result.count > 1 {
                let secondNaturalWidth = ((newEndMeasure + 1)...result[1].endMeasure).reduce(0) { $0 + measureWidths[$1] }
                result[1] = SystemBreak(
                    startMeasure: newEndMeasure + 1,
                    endMeasure: result[1].endMeasure,
                    naturalWidth: secondNaturalWidth
                )
            } else {
                let lastNaturalWidth = ((newEndMeasure + 1)..<measureWidths.count).reduce(0) { $0 + measureWidths[$1] }
                result.append(SystemBreak(
                    startMeasure: newEndMeasure + 1,
                    endMeasure: measureWidths.count - 1,
                    naturalWidth: lastNaturalWidth
                ))
            }

            return result
        }

        return breaks
    }
}

// MARK: - Configuration

/// Configuration for breaking algorithms.
public struct BreakingConfiguration: Sendable {
    // System breaking
    /// Penalty for stretching content.
    public var stretchPenalty: Double = 100

    /// Penalty for compressing content.
    public var compressPenalty: Double = 200

    /// Minimum gap between measures.
    public var minimumMeasureGap: CGFloat = 2.0

    /// Minimum measures per system.
    public var minimumMeasuresPerSystem: Int = 1

    /// Maximum measures per system.
    public var maximumMeasuresPerSystem: Int = 8

    /// Penalty for short systems.
    public var shortSystemPenalty: Double = 50

    /// Penalty for long systems.
    public var longSystemPenalty: Double = 30

    // Page breaking
    /// Minimum page fill ratio (0-1).
    public var minimumPageFill: Double = 0.5

    /// Penalty for underfilled pages.
    public var underfillPenalty: Double = 100

    /// Minimum systems per page.
    public var minimumSystemsPerPage: Int = 1

    /// Penalty for too few systems on a page.
    public var fewSystemsPenalty: Double = 50

    // Break hints
    /// Bonus for breaking at preferred position.
    public var preferredBreakBonus: Double = 20

    /// Bonus for breaking at required position.
    public var requiredBreakBonus: Double = 1000

    /// Penalty for breaking at forbidden position.
    public var forbiddenBreakPenalty: Double = 10000

    public init() {}
}

// MARK: - Supporting Types

// Note: SystemBreak is defined in HorizontalSpacing.swift

/// A page break point.
public struct PageBreakInfo: Sendable, Equatable {
    /// First system index on this page.
    public var startSystem: Int

    /// Last system index on this page.
    public var endSystem: Int

    /// Total content height on this page.
    public var contentHeight: CGFloat

    public init(startSystem: Int, endSystem: Int, contentHeight: CGFloat) {
        self.startSystem = startSystem
        self.endSystem = endSystem
        self.contentHeight = contentHeight
    }

    /// Number of systems on this page.
    public var systemCount: Int {
        endSystem - startSystem + 1
    }
}

/// Hint for breaking algorithm.
public struct BreakHint: Sendable {
    /// The measure/system index.
    public var measureIndex: Int

    /// Type of hint.
    public var type: BreakHintType

    public init(measureIndex: Int, type: BreakHintType) {
        self.measureIndex = measureIndex
        self.type = type
    }
}

/// Type of break hint.
public enum BreakHintType: Sendable {
    /// Preferred break position (slightly reduces cost).
    case preferred

    /// Required break (forces break here).
    case required

    /// Forbidden break (prevents break here).
    case forbidden
}

/// Result of justification calculation.
public struct JustificationResult: Sendable {
    /// Adjusted measure widths.
    public var adjustedWidths: [CGFloat]

    /// Ratio of new total width to original.
    public var stretchRatio: CGFloat

    public init(adjustedWidths: [CGFloat], stretchRatio: CGFloat) {
        self.adjustedWidths = adjustedWidths
        self.stretchRatio = stretchRatio
    }

    /// Whether the content was stretched.
    public var isStretched: Bool {
        stretchRatio > 1.0
    }

    /// Whether the content was compressed.
    public var isCompressed: Bool {
        stretchRatio < 1.0
    }
}
