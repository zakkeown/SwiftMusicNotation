import Foundation
import CoreGraphics
import MusicNotationCore

// MARK: - Orchestral Layout

/// Handles orchestral score layout including staff grouping, brackets, braces,
/// and connected barlines.
public final class OrchestralLayout {
    /// Configuration for orchestral layout.
    public var config: OrchestralConfiguration

    public init(config: OrchestralConfiguration = OrchestralConfiguration()) {
        self.config = config
    }

    // MARK: - Staff Grouping

    /// Creates staff groups from part information.
    public func createStaffGroups(
        from parts: [PartLayoutInfo]
    ) -> [StaffGroup] {
        var groups: [StaffGroup] = []
        var currentIndex = 0

        for part in parts {
            // Determine group type based on part characteristics
            let groupType = inferGroupType(for: part)

            let group = StaffGroup(
                name: part.name,
                abbreviation: part.abbreviation,
                startStaff: currentIndex,
                endStaff: currentIndex + part.staffCount - 1,
                groupType: groupType,
                barlineConnection: part.staffCount > 1 ? .connected : .none,
                showBracket: part.staffCount > 1 || groupType == .bracket
            )

            groups.append(group)
            currentIndex += part.staffCount
        }

        return groups
    }

    /// Creates nested groups for orchestral families (e.g., woodwinds, brass).
    public func createFamilyGroups(
        staffGroups: [StaffGroup],
        familyAssignments: [Int: InstrumentFamily]
    ) -> [FamilyGroup] {
        var familyGroups: [FamilyGroup] = []
        var currentFamily: InstrumentFamily?
        var familyStartIndex = 0
        var familyGroups_indices: [(family: InstrumentFamily, start: Int, end: Int)] = []

        for (index, _) in staffGroups.enumerated() {
            let family = familyAssignments[index] ?? .other

            if family != currentFamily {
                if let current = currentFamily, familyStartIndex < index {
                    familyGroups_indices.append((current, familyStartIndex, index - 1))
                }
                currentFamily = family
                familyStartIndex = index
            }
        }

        // Add the last family
        if let current = currentFamily {
            familyGroups_indices.append((current, familyStartIndex, staffGroups.count - 1))
        }

        // Create family groups
        for (family, start, end) in familyGroups_indices {
            guard start != end else { continue } // Skip single-instrument families

            let startStaff = staffGroups[start].startStaff
            let endStaff = staffGroups[end].endStaff

            familyGroups.append(FamilyGroup(
                family: family,
                startStaff: startStaff,
                endStaff: endStaff,
                showBracket: true
            ))
        }

        return familyGroups
    }

    /// Infers the group type from part characteristics.
    private func inferGroupType(for part: PartLayoutInfo) -> StaffGroupType {
        // Piano, harp, organ typically use brace
        let braceInstruments = ["piano", "harp", "organ", "celesta", "harpsichord", "keyboard"]
        let lowerName = part.name.lowercased()

        for instrument in braceInstruments {
            if lowerName.contains(instrument) {
                return .brace
            }
        }

        // Multi-staff parts default to brace
        if part.staffCount > 1 {
            return .brace
        }

        // Single-staff orchestral instruments use bracket in groups
        return .bracket
    }

    // MARK: - Bracket/Brace Positioning

    /// Calculates bracket positions for staff groups.
    public func calculateBracketPositions(
        staffGroups: [StaffGroup],
        staffPositions: [CGFloat],
        staffHeights: [CGFloat]
    ) -> [BracketPosition] {
        var brackets: [BracketPosition] = []

        for group in staffGroups where group.showBracket {
            guard group.startStaff < staffPositions.count,
                  group.endStaff < staffPositions.count else { continue }

            let topY = staffPositions[group.startStaff]
            let bottomY = staffPositions[group.endStaff] + staffHeights[group.endStaff]

            let bracket = BracketPosition(
                groupType: group.groupType,
                topY: topY,
                bottomY: bottomY,
                xPosition: config.bracketOffset,
                thickness: group.groupType == .brace ? config.braceThickness : config.bracketThickness
            )

            brackets.append(bracket)
        }

        return brackets
    }

    /// Calculates family bracket positions.
    public func calculateFamilyBracketPositions(
        familyGroups: [FamilyGroup],
        staffPositions: [CGFloat],
        staffHeights: [CGFloat]
    ) -> [BracketPosition] {
        var brackets: [BracketPosition] = []

        for group in familyGroups where group.showBracket {
            guard group.startStaff < staffPositions.count,
                  group.endStaff < staffPositions.count else { continue }

            let topY = staffPositions[group.startStaff]
            let bottomY = staffPositions[group.endStaff] + staffHeights[group.endStaff]

            let bracket = BracketPosition(
                groupType: .squareBracket,
                topY: topY,
                bottomY: bottomY,
                xPosition: config.familyBracketOffset,
                thickness: config.squareBracketThickness
            )

            brackets.append(bracket)
        }

        return brackets
    }

    // MARK: - Connected Barlines

    /// Determines which staves should have connected barlines.
    public func calculateBarlineConnections(
        staffGroups: [StaffGroup]
    ) -> [BarlineConnection] {
        var connections: [BarlineConnection] = []

        for group in staffGroups {
            switch group.barlineConnection {
            case .connected:
                connections.append(BarlineConnection(
                    startStaff: group.startStaff,
                    endStaff: group.endStaff,
                    connectionType: .full
                ))
            case .mensurstrich:
                // Barlines between staves only (early music style)
                connections.append(BarlineConnection(
                    startStaff: group.startStaff,
                    endStaff: group.endStaff,
                    connectionType: .mensurstrich
                ))
            case .none:
                break
            }
        }

        return connections
    }

    /// Calculates barline positions for a system.
    public func calculateSystemBarlines(
        connections: [BarlineConnection],
        staffPositions: [CGFloat],
        staffHeights: [CGFloat],
        barlineX: CGFloat
    ) -> [BarlineLayout] {
        var barlines: [BarlineLayout] = []

        // First, add individual staff barlines
        for (index, position) in staffPositions.enumerated() {
            barlines.append(BarlineLayout(
                startY: position,
                endY: position + staffHeights[index],
                xPosition: barlineX,
                style: .regular
            ))
        }

        // Then, add connected barlines
        for connection in connections {
            guard connection.startStaff < staffPositions.count,
                  connection.endStaff < staffPositions.count else { continue }

            switch connection.connectionType {
            case .full:
                let startY = staffPositions[connection.startStaff]
                let endY = staffPositions[connection.endStaff] + staffHeights[connection.endStaff]
                barlines.append(BarlineLayout(
                    startY: startY,
                    endY: endY,
                    xPosition: barlineX,
                    style: .regular
                ))

            case .mensurstrich:
                // Draw barlines only in the spaces between staves
                for staffIndex in connection.startStaff..<connection.endStaff {
                    let startY = staffPositions[staffIndex] + staffHeights[staffIndex]
                    let endY = staffPositions[staffIndex + 1]
                    barlines.append(BarlineLayout(
                        startY: startY,
                        endY: endY,
                        xPosition: barlineX,
                        style: .regular
                    ))
                }
            }
        }

        return barlines
    }

    // MARK: - System Layout

    /// Calculates the layout for a complete system.
    public func layoutSystem(
        parts: [PartLayoutInfo],
        staffHeights: [CGFloat],
        systemTop: CGFloat
    ) -> SystemLayoutResult {
        let staffGroups = createStaffGroups(from: parts)

        // Calculate staff positions
        var staffPositions: [CGFloat] = []
        var currentY = systemTop

        for (partIndex, part) in parts.enumerated() {
            for staffIndex in 0..<part.staffCount {
                staffPositions.append(currentY)

                // Add staff height
                let globalStaffIndex = staffPositions.count - 1
                if globalStaffIndex < staffHeights.count {
                    currentY += staffHeights[globalStaffIndex]
                }

                // Add gap within part (between grand staff staves)
                if staffIndex < part.staffCount - 1 {
                    currentY += config.innerStaffGap
                }
            }

            // Add gap between parts
            if partIndex < parts.count - 1 {
                currentY += config.partGap
            }
        }

        // Calculate brackets
        let brackets = calculateBracketPositions(
            staffGroups: staffGroups,
            staffPositions: staffPositions,
            staffHeights: staffHeights
        )

        // Calculate barline connections
        let connections = calculateBarlineConnections(staffGroups: staffGroups)

        return SystemLayoutResult(
            staffGroups: staffGroups,
            staffPositions: staffPositions,
            brackets: brackets,
            barlineConnections: connections,
            totalHeight: currentY - systemTop
        )
    }

    // MARK: - Staff Labels

    /// Calculates positions for staff/part labels.
    public func calculateLabelPositions(
        staffGroups: [StaffGroup],
        staffPositions: [CGFloat],
        staffHeights: [CGFloat],
        isFirstSystem: Bool
    ) -> [LabelPosition] {
        var labels: [LabelPosition] = []

        for group in staffGroups {
            guard group.startStaff < staffPositions.count,
                  group.endStaff < staffPositions.count else { continue }

            let topY = staffPositions[group.startStaff]
            let bottomY = staffPositions[group.endStaff] + staffHeights[group.endStaff]
            let centerY = (topY + bottomY) / 2

            let labelText = isFirstSystem ? group.name : (group.abbreviation ?? group.name)

            labels.append(LabelPosition(
                text: labelText,
                centerY: centerY,
                xPosition: config.labelOffset
            ))
        }

        return labels
    }
}

// MARK: - Configuration

/// Configuration for orchestral layout.
public struct OrchestralConfiguration: Sendable {
    /// Offset for bracket from staff left edge (in staff spaces).
    public var bracketOffset: CGFloat = -2.0

    /// Offset for family bracket (further left than instrument brackets).
    public var familyBracketOffset: CGFloat = -3.5

    /// Thickness of bracket line.
    public var bracketThickness: CGFloat = 0.5

    /// Thickness of brace.
    public var braceThickness: CGFloat = 0.75

    /// Thickness of square bracket.
    public var squareBracketThickness: CGFloat = 0.4

    /// Gap between staves within a part (e.g., piano grand staff).
    public var innerStaffGap: CGFloat = 6.0

    /// Gap between different parts.
    public var partGap: CGFloat = 10.0

    /// Gap between instrument families.
    public var familyGap: CGFloat = 14.0

    /// Offset for staff labels.
    public var labelOffset: CGFloat = -8.0

    public init() {}
}

// MARK: - Supporting Types

/// Information about a part for layout purposes.
public struct PartLayoutInfo: Sendable {
    /// Part name.
    public var name: String

    /// Part abbreviation.
    public var abbreviation: String?

    /// Number of staves in this part.
    public var staffCount: Int

    /// Part identifier.
    public var partId: String

    public init(name: String, abbreviation: String? = nil, staffCount: Int, partId: String) {
        self.name = name
        self.abbreviation = abbreviation
        self.staffCount = staffCount
        self.partId = partId
    }
}

/// A group of staves that belong together.
public struct StaffGroup: Sendable {
    /// Group name.
    public var name: String

    /// Group abbreviation.
    public var abbreviation: String?

    /// First staff index in this group.
    public var startStaff: Int

    /// Last staff index in this group.
    public var endStaff: Int

    /// Type of grouping (bracket, brace, etc.).
    public var groupType: StaffGroupType

    /// How barlines are connected.
    public var barlineConnection: BarlineConnectionType

    /// Whether to show the bracket/brace.
    public var showBracket: Bool

    public init(
        name: String,
        abbreviation: String? = nil,
        startStaff: Int,
        endStaff: Int,
        groupType: StaffGroupType,
        barlineConnection: BarlineConnectionType,
        showBracket: Bool
    ) {
        self.name = name
        self.abbreviation = abbreviation
        self.startStaff = startStaff
        self.endStaff = endStaff
        self.groupType = groupType
        self.barlineConnection = barlineConnection
        self.showBracket = showBracket
    }

    /// Number of staves in this group.
    public var staffCount: Int {
        endStaff - startStaff + 1
    }
}

/// Type of staff grouping symbol.
public enum StaffGroupType: String, Sendable {
    /// Curly brace (typically for keyboard/harp).
    case brace

    /// Square bracket (for orchestral sections).
    case bracket

    /// Thick square bracket (for instrument families).
    case squareBracket

    /// No grouping symbol.
    case none
}

/// How barlines connect between staves.
public enum BarlineConnectionType: String, Sendable {
    /// Full connection from top to bottom.
    case connected

    /// Mensural notation style (between staves only).
    case mensurstrich

    /// No connection.
    case none
}

/// Instrument family classification.
public enum InstrumentFamily: String, Sendable {
    case woodwinds
    case brass
    case percussion
    case keyboards
    case strings
    case voices
    case other
}

/// A group of instruments in the same family.
public struct FamilyGroup: Sendable {
    /// The instrument family.
    public var family: InstrumentFamily

    /// First staff index.
    public var startStaff: Int

    /// Last staff index.
    public var endStaff: Int

    /// Whether to show the family bracket.
    public var showBracket: Bool

    public init(family: InstrumentFamily, startStaff: Int, endStaff: Int, showBracket: Bool) {
        self.family = family
        self.startStaff = startStaff
        self.endStaff = endStaff
        self.showBracket = showBracket
    }
}

/// Position of a bracket or brace.
public struct BracketPosition: Sendable {
    /// Type of bracket.
    public var groupType: StaffGroupType

    /// Top Y coordinate.
    public var topY: CGFloat

    /// Bottom Y coordinate.
    public var bottomY: CGFloat

    /// X position of the bracket.
    public var xPosition: CGFloat

    /// Thickness of the bracket line.
    public var thickness: CGFloat

    public init(
        groupType: StaffGroupType,
        topY: CGFloat,
        bottomY: CGFloat,
        xPosition: CGFloat,
        thickness: CGFloat
    ) {
        self.groupType = groupType
        self.topY = topY
        self.bottomY = bottomY
        self.xPosition = xPosition
        self.thickness = thickness
    }

    /// Height of the bracket.
    public var height: CGFloat {
        bottomY - topY
    }
}

/// Connection information for barlines.
public struct BarlineConnection: Sendable {
    /// First staff to connect.
    public var startStaff: Int

    /// Last staff to connect.
    public var endStaff: Int

    /// Type of connection.
    public var connectionType: BarlineConnectionStyle

    public init(startStaff: Int, endStaff: Int, connectionType: BarlineConnectionStyle) {
        self.startStaff = startStaff
        self.endStaff = endStaff
        self.connectionType = connectionType
    }
}

/// Style of barline connection.
public enum BarlineConnectionStyle: String, Sendable {
    /// Full connection through all staves.
    case full

    /// Connection only between staves (mensural style).
    case mensurstrich
}

/// Layout information for a barline.
public struct BarlineLayout: Sendable {
    /// Starting Y coordinate.
    public var startY: CGFloat

    /// Ending Y coordinate.
    public var endY: CGFloat

    /// X position.
    public var xPosition: CGFloat

    /// Barline style.
    public var style: BarStyle

    public init(startY: CGFloat, endY: CGFloat, xPosition: CGFloat, style: BarStyle) {
        self.startY = startY
        self.endY = endY
        self.xPosition = xPosition
        self.style = style
    }

    /// Height of the barline.
    public var height: CGFloat {
        endY - startY
    }
}

/// Result of system layout calculation.
public struct SystemLayoutResult: Sendable {
    /// Staff groups in the system.
    public var staffGroups: [StaffGroup]

    /// Y positions of each staff.
    public var staffPositions: [CGFloat]

    /// Bracket/brace positions.
    public var brackets: [BracketPosition]

    /// Barline connections.
    public var barlineConnections: [BarlineConnection]

    /// Total height of the system.
    public var totalHeight: CGFloat

    public init(
        staffGroups: [StaffGroup],
        staffPositions: [CGFloat],
        brackets: [BracketPosition],
        barlineConnections: [BarlineConnection],
        totalHeight: CGFloat
    ) {
        self.staffGroups = staffGroups
        self.staffPositions = staffPositions
        self.brackets = brackets
        self.barlineConnections = barlineConnections
        self.totalHeight = totalHeight
    }
}

/// Position for a staff/part label.
public struct LabelPosition: Sendable {
    /// Label text.
    public var text: String

    /// Vertical center of the label.
    public var centerY: CGFloat

    /// X position (typically negative, left of staff).
    public var xPosition: CGFloat

    public init(text: String, centerY: CGFloat, xPosition: CGFloat) {
        self.text = text
        self.centerY = centerY
        self.xPosition = xPosition
    }
}

// MARK: - Standard Orchestral Order

/// Standard orchestral score order for instrument families.
public struct OrchestraOrder {
    /// Standard instrument family order from top to bottom.
    public static let standardOrder: [InstrumentFamily] = [
        .woodwinds,
        .brass,
        .percussion,
        .keyboards,
        .voices,
        .strings
    ]

    /// Assigns instruments to families based on name patterns.
    public static func inferFamily(fromPartName name: String) -> InstrumentFamily {
        let lower = name.lowercased()

        // Woodwinds
        let woodwinds = ["flute", "piccolo", "oboe", "clarinet", "bassoon", "saxophone", "recorder", "english horn", "cor anglais"]
        for instrument in woodwinds {
            if lower.contains(instrument) { return .woodwinds }
        }

        // Brass
        let brass = ["horn", "trumpet", "trombone", "tuba", "cornet", "euphonium", "flugelhorn"]
        for instrument in brass {
            if lower.contains(instrument) { return .brass }
        }

        // Percussion
        let percussion = ["timpani", "percussion", "drum", "cymbal", "triangle", "tambourine", "xylophone", "vibraphone", "marimba", "glockenspiel", "chimes", "bells"]
        for instrument in percussion {
            if lower.contains(instrument) { return .percussion }
        }

        // Keyboards
        let keyboards = ["piano", "organ", "celesta", "harpsichord", "keyboard", "harp"]
        for instrument in keyboards {
            if lower.contains(instrument) { return .keyboards }
        }

        // Voices
        let voices = ["soprano", "alto", "tenor", "bass", "baritone", "mezzo", "choir", "chorus", "voice", "vocal"]
        for instrument in voices {
            if lower.contains(instrument) { return .voices }
        }

        // Strings
        let strings = ["violin", "viola", "cello", "violoncello", "bass", "contrabass", "double bass", "string"]
        for instrument in strings {
            if lower.contains(instrument) { return .strings }
        }

        return .other
    }

    /// Sorts parts into standard orchestral order.
    public static func sortParts(_ parts: [PartLayoutInfo]) -> [PartLayoutInfo] {
        parts.sorted { part1, part2 in
            let family1 = inferFamily(fromPartName: part1.name)
            let family2 = inferFamily(fromPartName: part2.name)

            guard let index1 = standardOrder.firstIndex(of: family1),
                  let index2 = standardOrder.firstIndex(of: family2) else {
                return part1.name < part2.name
            }

            if index1 != index2 {
                return index1 < index2
            }

            // Same family - maintain original order or sort alphabetically
            return part1.name < part2.name
        }
    }
}
