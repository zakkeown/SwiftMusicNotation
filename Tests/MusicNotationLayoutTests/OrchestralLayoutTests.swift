import XCTest
import CoreGraphics
@testable import MusicNotationLayout
@testable import MusicNotationCore

// MARK: - OrchestralLayout Tests

final class OrchestralLayoutTests: XCTestCase {

    private var layout: OrchestralLayout!

    override func setUp() {
        super.setUp()
        layout = OrchestralLayout()
    }

    // MARK: - Staff Group Creation Tests

    func testCreateStaffGroupsSinglePart() {
        let parts = [
            PartLayoutInfo(name: "Violin", staffCount: 1, partId: "P1")
        ]

        let groups = layout.createStaffGroups(from: parts)

        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].name, "Violin")
        XCTAssertEqual(groups[0].startStaff, 0)
        XCTAssertEqual(groups[0].endStaff, 0)
        XCTAssertEqual(groups[0].staffCount, 1)
    }

    func testCreateStaffGroupsMultipleParts() {
        let parts = [
            PartLayoutInfo(name: "Flute", staffCount: 1, partId: "P1"),
            PartLayoutInfo(name: "Oboe", staffCount: 1, partId: "P2"),
            PartLayoutInfo(name: "Clarinet", staffCount: 1, partId: "P3")
        ]

        let groups = layout.createStaffGroups(from: parts)

        XCTAssertEqual(groups.count, 3)
        XCTAssertEqual(groups[0].startStaff, 0)
        XCTAssertEqual(groups[0].endStaff, 0)
        XCTAssertEqual(groups[1].startStaff, 1)
        XCTAssertEqual(groups[1].endStaff, 1)
        XCTAssertEqual(groups[2].startStaff, 2)
        XCTAssertEqual(groups[2].endStaff, 2)
    }

    func testCreateStaffGroupsPianoGrandStaff() {
        let parts = [
            PartLayoutInfo(name: "Piano", staffCount: 2, partId: "P1")
        ]

        let groups = layout.createStaffGroups(from: parts)

        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].startStaff, 0)
        XCTAssertEqual(groups[0].endStaff, 1)
        XCTAssertEqual(groups[0].staffCount, 2)
        XCTAssertEqual(groups[0].groupType, .brace)
        XCTAssertEqual(groups[0].barlineConnection, .connected)
        XCTAssertTrue(groups[0].showBracket)
    }

    func testCreateStaffGroupsOrgan() {
        let parts = [
            PartLayoutInfo(name: "Organ", staffCount: 3, partId: "P1")
        ]

        let groups = layout.createStaffGroups(from: parts)

        XCTAssertEqual(groups[0].groupType, .brace)
        XCTAssertEqual(groups[0].staffCount, 3)
    }

    func testCreateStaffGroupsHarp() {
        let parts = [
            PartLayoutInfo(name: "Harp", staffCount: 2, partId: "P1")
        ]

        let groups = layout.createStaffGroups(from: parts)

        XCTAssertEqual(groups[0].groupType, .brace)
    }

    func testCreateStaffGroupsMixedParts() {
        let parts = [
            PartLayoutInfo(name: "Flute", staffCount: 1, partId: "P1"),
            PartLayoutInfo(name: "Piano", staffCount: 2, partId: "P2"),
            PartLayoutInfo(name: "Violin", staffCount: 1, partId: "P3")
        ]

        let groups = layout.createStaffGroups(from: parts)

        XCTAssertEqual(groups.count, 3)
        // Flute
        XCTAssertEqual(groups[0].startStaff, 0)
        XCTAssertEqual(groups[0].endStaff, 0)
        // Piano
        XCTAssertEqual(groups[1].startStaff, 1)
        XCTAssertEqual(groups[1].endStaff, 2)
        // Violin
        XCTAssertEqual(groups[2].startStaff, 3)
        XCTAssertEqual(groups[2].endStaff, 3)
    }

    func testCreateStaffGroupsWithAbbreviation() {
        let parts = [
            PartLayoutInfo(name: "Violin I", abbreviation: "Vln. I", staffCount: 1, partId: "P1")
        ]

        let groups = layout.createStaffGroups(from: parts)

        XCTAssertEqual(groups[0].abbreviation, "Vln. I")
    }

    // MARK: - Family Group Tests

    func testCreateFamilyGroupsEmpty() {
        let groups = layout.createFamilyGroups(staffGroups: [], familyAssignments: [:])
        XCTAssertTrue(groups.isEmpty)
    }

    func testCreateFamilyGroupsSingleFamily() {
        let staffGroups = [
            StaffGroup(name: "Flute", startStaff: 0, endStaff: 0, groupType: .bracket, barlineConnection: .none, showBracket: false),
            StaffGroup(name: "Oboe", startStaff: 1, endStaff: 1, groupType: .bracket, barlineConnection: .none, showBracket: false),
            StaffGroup(name: "Clarinet", startStaff: 2, endStaff: 2, groupType: .bracket, barlineConnection: .none, showBracket: false)
        ]

        let familyAssignments: [Int: InstrumentFamily] = [
            0: .woodwinds,
            1: .woodwinds,
            2: .woodwinds
        ]

        let familyGroups = layout.createFamilyGroups(staffGroups: staffGroups, familyAssignments: familyAssignments)

        XCTAssertEqual(familyGroups.count, 1)
        XCTAssertEqual(familyGroups[0].family, .woodwinds)
        XCTAssertEqual(familyGroups[0].startStaff, 0)
        XCTAssertEqual(familyGroups[0].endStaff, 2)
    }

    func testCreateFamilyGroupsMultipleFamilies() {
        let staffGroups = [
            StaffGroup(name: "Flute", startStaff: 0, endStaff: 0, groupType: .bracket, barlineConnection: .none, showBracket: false),
            StaffGroup(name: "Horn", startStaff: 1, endStaff: 1, groupType: .bracket, barlineConnection: .none, showBracket: false),
            StaffGroup(name: "Trumpet", startStaff: 2, endStaff: 2, groupType: .bracket, barlineConnection: .none, showBracket: false)
        ]

        let familyAssignments: [Int: InstrumentFamily] = [
            0: .woodwinds,
            1: .brass,
            2: .brass
        ]

        let familyGroups = layout.createFamilyGroups(staffGroups: staffGroups, familyAssignments: familyAssignments)

        // Single woodwind doesn't form a group, but brass does (2 instruments)
        XCTAssertEqual(familyGroups.count, 1)
        XCTAssertEqual(familyGroups[0].family, .brass)
    }

    // MARK: - Bracket Position Tests

    func testCalculateBracketPositionsEmpty() {
        let brackets = layout.calculateBracketPositions(staffGroups: [], staffPositions: [], staffHeights: [])
        XCTAssertTrue(brackets.isEmpty)
    }

    func testCalculateBracketPositionsSingleGroup() {
        let staffGroups = [
            StaffGroup(name: "Piano", startStaff: 0, endStaff: 1, groupType: .brace, barlineConnection: .connected, showBracket: true)
        ]
        let staffPositions: [CGFloat] = [0, 50]
        let staffHeights: [CGFloat] = [40, 40]

        let brackets = layout.calculateBracketPositions(staffGroups: staffGroups, staffPositions: staffPositions, staffHeights: staffHeights)

        XCTAssertEqual(brackets.count, 1)
        XCTAssertEqual(brackets[0].topY, 0)
        XCTAssertEqual(brackets[0].bottomY, 90) // 50 + 40
        XCTAssertEqual(brackets[0].groupType, .brace)
    }

    func testCalculateBracketPositionsHiddenBracket() {
        let staffGroups = [
            StaffGroup(name: "Violin", startStaff: 0, endStaff: 0, groupType: .bracket, barlineConnection: .none, showBracket: false)
        ]
        let staffPositions: [CGFloat] = [0]
        let staffHeights: [CGFloat] = [40]

        let brackets = layout.calculateBracketPositions(staffGroups: staffGroups, staffPositions: staffPositions, staffHeights: staffHeights)

        XCTAssertTrue(brackets.isEmpty)
    }

    func testCalculateFamilyBracketPositions() {
        let familyGroups = [
            FamilyGroup(family: .woodwinds, startStaff: 0, endStaff: 2, showBracket: true)
        ]
        let staffPositions: [CGFloat] = [0, 50, 100]
        let staffHeights: [CGFloat] = [40, 40, 40]

        let brackets = layout.calculateFamilyBracketPositions(familyGroups: familyGroups, staffPositions: staffPositions, staffHeights: staffHeights)

        XCTAssertEqual(brackets.count, 1)
        XCTAssertEqual(brackets[0].groupType, .squareBracket)
        XCTAssertEqual(brackets[0].topY, 0)
        XCTAssertEqual(brackets[0].bottomY, 140)
    }

    // MARK: - Barline Connection Tests

    func testCalculateBarlineConnectionsNone() {
        let staffGroups = [
            StaffGroup(name: "Violin", startStaff: 0, endStaff: 0, groupType: .bracket, barlineConnection: .none, showBracket: false)
        ]

        let connections = layout.calculateBarlineConnections(staffGroups: staffGroups)

        XCTAssertTrue(connections.isEmpty)
    }

    func testCalculateBarlineConnectionsConnected() {
        let staffGroups = [
            StaffGroup(name: "Piano", startStaff: 0, endStaff: 1, groupType: .brace, barlineConnection: .connected, showBracket: true)
        ]

        let connections = layout.calculateBarlineConnections(staffGroups: staffGroups)

        XCTAssertEqual(connections.count, 1)
        XCTAssertEqual(connections[0].startStaff, 0)
        XCTAssertEqual(connections[0].endStaff, 1)
        XCTAssertEqual(connections[0].connectionType, .full)
    }

    func testCalculateBarlineConnectionsMensurstrich() {
        let staffGroups = [
            StaffGroup(name: "Choir", startStaff: 0, endStaff: 3, groupType: .bracket, barlineConnection: .mensurstrich, showBracket: true)
        ]

        let connections = layout.calculateBarlineConnections(staffGroups: staffGroups)

        XCTAssertEqual(connections.count, 1)
        XCTAssertEqual(connections[0].connectionType, .mensurstrich)
    }

    // MARK: - System Barlines Tests

    func testCalculateSystemBarlinesSimple() {
        let connections: [BarlineConnection] = []
        let staffPositions: [CGFloat] = [0, 50]
        let staffHeights: [CGFloat] = [40, 40]

        let barlines = layout.calculateSystemBarlines(
            connections: connections,
            staffPositions: staffPositions,
            staffHeights: staffHeights,
            barlineX: 100
        )

        XCTAssertEqual(barlines.count, 2) // One per staff
        XCTAssertEqual(barlines[0].startY, 0)
        XCTAssertEqual(barlines[0].endY, 40)
        XCTAssertEqual(barlines[1].startY, 50)
        XCTAssertEqual(barlines[1].endY, 90)
    }

    func testCalculateSystemBarlinesWithConnection() {
        let connections = [
            BarlineConnection(startStaff: 0, endStaff: 1, connectionType: .full)
        ]
        let staffPositions: [CGFloat] = [0, 50]
        let staffHeights: [CGFloat] = [40, 40]

        let barlines = layout.calculateSystemBarlines(
            connections: connections,
            staffPositions: staffPositions,
            staffHeights: staffHeights,
            barlineX: 100
        )

        // 2 individual + 1 connected
        XCTAssertEqual(barlines.count, 3)
    }

    func testCalculateSystemBarlinesMensurstrich() {
        let connections = [
            BarlineConnection(startStaff: 0, endStaff: 2, connectionType: .mensurstrich)
        ]
        let staffPositions: [CGFloat] = [0, 50, 100]
        let staffHeights: [CGFloat] = [40, 40, 40]

        let barlines = layout.calculateSystemBarlines(
            connections: connections,
            staffPositions: staffPositions,
            staffHeights: staffHeights,
            barlineX: 100
        )

        // 3 individual + 2 between staves (mensural style)
        XCTAssertEqual(barlines.count, 5)
    }

    // MARK: - System Layout Tests

    func testLayoutSystemSinglePart() {
        let parts = [
            PartLayoutInfo(name: "Violin", staffCount: 1, partId: "P1")
        ]
        let staffHeights: [CGFloat] = [40]

        let result = layout.layoutSystem(parts: parts, staffHeights: staffHeights, systemTop: 0)

        XCTAssertEqual(result.staffGroups.count, 1)
        XCTAssertEqual(result.staffPositions.count, 1)
        XCTAssertEqual(result.staffPositions[0], 0)
    }

    func testLayoutSystemMultipleParts() {
        let parts = [
            PartLayoutInfo(name: "Flute", staffCount: 1, partId: "P1"),
            PartLayoutInfo(name: "Violin", staffCount: 1, partId: "P2")
        ]
        let staffHeights: [CGFloat] = [40, 40]

        let result = layout.layoutSystem(parts: parts, staffHeights: staffHeights, systemTop: 10)

        XCTAssertEqual(result.staffPositions.count, 2)
        XCTAssertEqual(result.staffPositions[0], 10)
        // Second staff should be offset by staffHeight + partGap
        XCTAssertTrue(result.staffPositions[1] > result.staffPositions[0])
    }

    func testLayoutSystemGrandStaff() {
        let parts = [
            PartLayoutInfo(name: "Piano", staffCount: 2, partId: "P1")
        ]
        let staffHeights: [CGFloat] = [40, 40]

        let result = layout.layoutSystem(parts: parts, staffHeights: staffHeights, systemTop: 0)

        XCTAssertEqual(result.staffPositions.count, 2)
        XCTAssertFalse(result.brackets.isEmpty)
        XCTAssertFalse(result.barlineConnections.isEmpty)
    }

    // MARK: - Label Position Tests

    func testCalculateLabelPositionsFirstSystem() {
        let staffGroups = [
            StaffGroup(name: "Violin I", abbreviation: "Vln. I", startStaff: 0, endStaff: 0, groupType: .bracket, barlineConnection: .none, showBracket: false)
        ]
        let staffPositions: [CGFloat] = [0]
        let staffHeights: [CGFloat] = [40]

        let labels = layout.calculateLabelPositions(
            staffGroups: staffGroups,
            staffPositions: staffPositions,
            staffHeights: staffHeights,
            isFirstSystem: true
        )

        XCTAssertEqual(labels.count, 1)
        XCTAssertEqual(labels[0].text, "Violin I") // Full name on first system
        XCTAssertEqual(labels[0].centerY, 20) // Center of 0-40
    }

    func testCalculateLabelPositionsSubsequentSystem() {
        let staffGroups = [
            StaffGroup(name: "Violin I", abbreviation: "Vln. I", startStaff: 0, endStaff: 0, groupType: .bracket, barlineConnection: .none, showBracket: false)
        ]
        let staffPositions: [CGFloat] = [0]
        let staffHeights: [CGFloat] = [40]

        let labels = layout.calculateLabelPositions(
            staffGroups: staffGroups,
            staffPositions: staffPositions,
            staffHeights: staffHeights,
            isFirstSystem: false
        )

        XCTAssertEqual(labels[0].text, "Vln. I") // Abbreviation on subsequent systems
    }

    func testCalculateLabelPositionsNoAbbreviation() {
        let staffGroups = [
            StaffGroup(name: "Flute", abbreviation: nil, startStaff: 0, endStaff: 0, groupType: .bracket, barlineConnection: .none, showBracket: false)
        ]
        let staffPositions: [CGFloat] = [0]
        let staffHeights: [CGFloat] = [40]

        let labels = layout.calculateLabelPositions(
            staffGroups: staffGroups,
            staffPositions: staffPositions,
            staffHeights: staffHeights,
            isFirstSystem: false
        )

        XCTAssertEqual(labels[0].text, "Flute") // Full name when no abbreviation
    }
}

// MARK: - OrchestralConfiguration Tests

final class OrchestralConfigurationTests: XCTestCase {

    func testDefaultConfiguration() {
        let config = OrchestralConfiguration()

        XCTAssertEqual(config.bracketOffset, -2.0)
        XCTAssertEqual(config.familyBracketOffset, -3.5)
        XCTAssertEqual(config.bracketThickness, 0.5)
        XCTAssertEqual(config.braceThickness, 0.75)
        XCTAssertEqual(config.innerStaffGap, 6.0)
        XCTAssertEqual(config.partGap, 10.0)
    }

    func testCustomConfiguration() {
        var config = OrchestralConfiguration()
        config.partGap = 15.0
        config.innerStaffGap = 8.0

        XCTAssertEqual(config.partGap, 15.0)
        XCTAssertEqual(config.innerStaffGap, 8.0)
    }
}

// MARK: - OrchestraOrder Tests

final class OrchestraOrderTests: XCTestCase {

    func testInferFamilyWoodwinds() {
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Flute"), .woodwinds)
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Oboe"), .woodwinds)
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Clarinet in Bb"), .woodwinds)
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Bassoon"), .woodwinds)
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Piccolo"), .woodwinds)
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "English Horn"), .woodwinds)
    }

    func testInferFamilyBrass() {
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Horn in F"), .brass)
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Trumpet"), .brass)
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Trombone"), .brass)
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Tuba"), .brass)
    }

    func testInferFamilyPercussion() {
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Timpani"), .percussion)
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Snare Drum"), .percussion)
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Xylophone"), .percussion)
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Triangle"), .percussion)
    }

    func testInferFamilyKeyboards() {
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Piano"), .keyboards)
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Organ"), .keyboards)
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Celesta"), .keyboards)
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Harp"), .keyboards)
    }

    func testInferFamilyVoices() {
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Soprano"), .voices)
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Alto"), .voices)
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Tenor"), .voices)
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Bass Voice"), .voices)
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Choir"), .voices)
    }

    func testInferFamilyStrings() {
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Violin I"), .strings)
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Violin II"), .strings)
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Viola"), .strings)
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Violoncello"), .strings)
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Cello"), .strings)
        // Note: "bass" alone matches voices first; "string" is a generic string match
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "String Section"), .strings)
    }

    func testInferFamilyOther() {
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Unknown Instrument"), .other)
        XCTAssertEqual(OrchestraOrder.inferFamily(fromPartName: "Custom Part"), .other)
    }

    func testSortPartsOrchestralOrder() {
        let parts = [
            PartLayoutInfo(name: "Violin I", staffCount: 1, partId: "P1"),
            PartLayoutInfo(name: "Flute", staffCount: 1, partId: "P2"),
            PartLayoutInfo(name: "Trumpet", staffCount: 1, partId: "P3"),
            PartLayoutInfo(name: "Timpani", staffCount: 1, partId: "P4")
        ]

        let sorted = OrchestraOrder.sortParts(parts)

        // Expected order: Woodwinds (Flute), Brass (Trumpet), Percussion (Timpani), Strings (Violin)
        XCTAssertEqual(sorted[0].name, "Flute")
        XCTAssertEqual(sorted[1].name, "Trumpet")
        XCTAssertEqual(sorted[2].name, "Timpani")
        XCTAssertEqual(sorted[3].name, "Violin I")
    }

    func testStandardOrder() {
        let order = OrchestraOrder.standardOrder

        XCTAssertEqual(order[0], .woodwinds)
        XCTAssertEqual(order[1], .brass)
        XCTAssertEqual(order[2], .percussion)
        XCTAssertEqual(order[3], .keyboards)
        XCTAssertEqual(order[4], .voices)
        XCTAssertEqual(order[5], .strings)
    }
}

// MARK: - Supporting Type Tests

final class StaffGroupTests: XCTestCase {

    func testStaffGroupStaffCount() {
        let group = StaffGroup(
            name: "Piano",
            startStaff: 0,
            endStaff: 1,
            groupType: .brace,
            barlineConnection: .connected,
            showBracket: true
        )

        XCTAssertEqual(group.staffCount, 2)
    }
}

final class BracketPositionTests: XCTestCase {

    func testBracketPositionHeight() {
        let bracket = BracketPosition(
            groupType: .brace,
            topY: 10,
            bottomY: 90,
            xPosition: -2,
            thickness: 0.5
        )

        XCTAssertEqual(bracket.height, 80)
    }
}

final class BarlineLayoutTests: XCTestCase {

    func testBarlineLayoutHeight() {
        let barline = BarlineLayout(
            startY: 0,
            endY: 40,
            xPosition: 100,
            style: .regular
        )

        XCTAssertEqual(barline.height, 40)
    }
}
