import Foundation
import CoreGraphics
import MusicNotationCore

// MARK: - Vertical Spacing Engine

/// Computes vertical spacing between staves and systems.
public final class VerticalSpacingEngine {
    /// Configuration for vertical spacing.
    public var config: VerticalSpacingConfiguration

    public init(config: VerticalSpacingConfiguration = VerticalSpacingConfiguration()) {
        self.config = config
    }

    /// Computes staff positions for a system.
    /// - Parameters:
    ///   - parts: Parts in the score.
    ///   - staffHeight: Height of each staff in points.
    ///   - startY: Starting Y position (top of first staff).
    /// - Returns: Array of staff position info.
    public func computeStaffPositions(
        parts: [PartStaffInfo],
        staffHeight: CGFloat,
        startY: CGFloat = 0
    ) -> [StaffPositionInfo] {
        var positions: [StaffPositionInfo] = []
        var currentY = startY

        for (partIndex, part) in parts.enumerated() {
            for staffNum in 1...part.staffCount {
                let isFirstStaffInPart = staffNum == 1
                let isFirstPart = partIndex == 0

                // Add spacing before this staff
                let spacing: CGFloat
                if isFirstPart && isFirstStaffInPart {
                    spacing = 0
                } else if isFirstStaffInPart {
                    // Space between parts
                    spacing = config.partDistance
                } else {
                    // Space between staves within a part
                    spacing = part.staffDistance ?? config.staffDistance
                }

                currentY += spacing

                positions.append(StaffPositionInfo(
                    partIndex: partIndex,
                    staffNumber: staffNum,
                    topY: currentY,
                    bottomY: currentY + staffHeight,
                    centerLineY: currentY + staffHeight / 2
                ))

                currentY += staffHeight
            }
        }

        return positions
    }

    /// Computes system positions for a page.
    public func computeSystemPositions(
        systemCount: Int,
        pageHeight: CGFloat,
        topMargin: CGFloat,
        bottomMargin: CGFloat,
        systemHeights: [CGFloat]
    ) -> [SystemPositionInfo] {
        guard systemCount > 0 else { return [] }

        let availableHeight = pageHeight - topMargin - bottomMargin
        let totalSystemHeight = systemHeights.reduce(0, +)

        var positions: [SystemPositionInfo] = []
        var currentY = topMargin

        // Calculate spacing between systems
        let totalSpacing: CGFloat
        if systemCount > 1 {
            totalSpacing = availableHeight - totalSystemHeight
            let systemDistance = max(totalSpacing / CGFloat(systemCount - 1), config.systemDistance)

            for (index, height) in systemHeights.enumerated() {
                positions.append(SystemPositionInfo(
                    systemIndex: index,
                    topY: currentY,
                    bottomY: currentY + height,
                    height: height
                ))

                currentY += height
                if index < systemCount - 1 {
                    currentY += systemDistance
                }
            }
        } else {
            // Single system
            positions.append(SystemPositionInfo(
                systemIndex: 0,
                topY: currentY,
                bottomY: currentY + systemHeights[0],
                height: systemHeights[0]
            ))
        }

        return positions
    }

    /// Computes the height needed for a system with collision avoidance.
    public func computeSystemHeight(
        staffPositions: [StaffPositionInfo],
        elementBounds: [CGRect],
        staffHeight: CGFloat
    ) -> CGFloat {
        guard let firstStaff = staffPositions.first,
              let lastStaff = staffPositions.last else {
            return staffHeight
        }

        // Base height from staff positions
        var height = lastStaff.bottomY - firstStaff.topY

        // Add space for elements that extend beyond staves
        var minY = firstStaff.topY
        var maxY = lastStaff.bottomY

        for bounds in elementBounds {
            minY = min(minY, bounds.minY)
            maxY = max(maxY, bounds.maxY)
        }

        // Add padding
        height = maxY - minY + config.systemTopPadding + config.systemBottomPadding

        return height
    }

    /// Adjusts staff positions to avoid collisions between staves.
    public func resolveCollisions(
        staffPositions: inout [StaffPositionInfo],
        upperBounds: [Int: CGFloat],  // Staff index -> lowest element Y
        lowerBounds: [Int: CGFloat],  // Staff index -> highest element Y
        staffHeight: CGFloat
    ) {
        guard staffPositions.count > 1 else { return }

        for i in 1..<staffPositions.count {
            let prevStaff = staffPositions[i - 1]
            let currentStaff = staffPositions[i]

            // Get bounds of elements between staves
            let prevLowerBound = lowerBounds[i - 1] ?? prevStaff.bottomY
            let currentUpperBound = upperBounds[i] ?? currentStaff.topY

            // Check for collision
            let overlap = prevLowerBound - currentUpperBound + config.minimumStaffClearance

            if overlap > 0 {
                // Move this staff and all following staves down
                for j in i..<staffPositions.count {
                    staffPositions[j].topY += overlap
                    staffPositions[j].bottomY += overlap
                    staffPositions[j].centerLineY += overlap
                }
            }
        }
    }
}

// MARK: - Configuration

/// Configuration for vertical spacing.
public struct VerticalSpacingConfiguration: Sendable {
    /// Default distance between staves within a part (in points).
    public var staffDistance: CGFloat = 60.0

    /// Distance between parts (in points).
    public var partDistance: CGFloat = 80.0

    /// Distance between systems (in points).
    public var systemDistance: CGFloat = 80.0

    /// Distance from top of page to first system.
    public var topSystemDistance: CGFloat = 100.0

    /// Padding above system content.
    public var systemTopPadding: CGFloat = 20.0

    /// Padding below system content.
    public var systemBottomPadding: CGFloat = 20.0

    /// Minimum clearance between staves.
    public var minimumStaffClearance: CGFloat = 10.0

    public init() {}
}

// MARK: - Position Types

/// Information about a staff's vertical position.
public struct StaffPositionInfo: Sendable {
    /// Part index.
    public var partIndex: Int

    /// Staff number within part.
    public var staffNumber: Int

    /// Y position of top staff line.
    public var topY: CGFloat

    /// Y position of bottom staff line.
    public var bottomY: CGFloat

    /// Y position of center line.
    public var centerLineY: CGFloat

    public init(partIndex: Int, staffNumber: Int, topY: CGFloat, bottomY: CGFloat, centerLineY: CGFloat) {
        self.partIndex = partIndex
        self.staffNumber = staffNumber
        self.topY = topY
        self.bottomY = bottomY
        self.centerLineY = centerLineY
    }

    /// Height of the staff.
    public var height: CGFloat {
        bottomY - topY
    }
}

/// Information about a system's vertical position.
public struct SystemPositionInfo: Sendable {
    /// System index on the page.
    public var systemIndex: Int

    /// Y position of top of system.
    public var topY: CGFloat

    /// Y position of bottom of system.
    public var bottomY: CGFloat

    /// Total height of the system.
    public var height: CGFloat

    public init(systemIndex: Int, topY: CGFloat, bottomY: CGFloat, height: CGFloat) {
        self.systemIndex = systemIndex
        self.topY = topY
        self.bottomY = bottomY
        self.height = height
    }
}

/// Information about a part's staves.
public struct PartStaffInfo: Sendable {
    /// Number of staves in this part.
    public var staffCount: Int

    /// Custom staff distance for this part (overrides default).
    public var staffDistance: CGFloat?

    public init(staffCount: Int, staffDistance: CGFloat? = nil) {
        self.staffCount = staffCount
        self.staffDistance = staffDistance
    }
}

// MARK: - Page Layout

/// Computes page layouts with proper vertical distribution.
public final class PageLayoutEngine {
    private let verticalEngine: VerticalSpacingEngine

    public init(config: VerticalSpacingConfiguration = VerticalSpacingConfiguration()) {
        self.verticalEngine = VerticalSpacingEngine(config: config)
    }

    /// Computes page breaks given system heights and page constraints.
    public func computePageBreaks(
        systemHeights: [CGFloat],
        pageHeight: CGFloat,
        topMargin: CGFloat,
        bottomMargin: CGFloat,
        firstPageTopMargin: CGFloat? = nil
    ) -> [PageBreak] {
        var breaks: [PageBreak] = []
        var currentStart = 0
        var currentHeight: CGFloat = 0

        let effectiveTopMargin = firstPageTopMargin ?? topMargin
        var availableHeight = pageHeight - effectiveTopMargin - bottomMargin

        for (index, height) in systemHeights.enumerated() {
            let spacing = index == currentStart ? 0 : verticalEngine.config.systemDistance
            let heightNeeded = height + spacing

            if currentHeight + heightNeeded > availableHeight && currentStart < index {
                // Break before this system
                breaks.append(PageBreak(
                    startSystem: currentStart,
                    endSystem: index - 1,
                    totalHeight: currentHeight
                ))
                currentStart = index
                currentHeight = height
                availableHeight = pageHeight - topMargin - bottomMargin
            } else {
                currentHeight += heightNeeded
            }
        }

        // Add final page
        if currentStart < systemHeights.count {
            breaks.append(PageBreak(
                startSystem: currentStart,
                endSystem: systemHeights.count - 1,
                totalHeight: currentHeight
            ))
        }

        return breaks
    }
}

/// A page break point.
public struct PageBreak: Sendable {
    /// First system index on this page.
    public var startSystem: Int

    /// Last system index on this page.
    public var endSystem: Int

    /// Total height of all systems on this page.
    public var totalHeight: CGFloat

    public init(startSystem: Int, endSystem: Int, totalHeight: CGFloat) {
        self.startSystem = startSystem
        self.endSystem = endSystem
        self.totalHeight = totalHeight
    }

    /// Number of systems on this page.
    public var systemCount: Int {
        endSystem - startSystem + 1
    }
}
