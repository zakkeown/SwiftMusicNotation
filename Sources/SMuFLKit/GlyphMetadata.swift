import Foundation
import CoreGraphics

/// Units measured in staff spaces (the distance between two staff lines).
public typealias StaffSpaces = CGFloat

/// Bounding box for a SMuFL glyph in staff spaces.
///
/// Coordinates follow SMuFL convention:
/// - Origin (0, 0) is at the glyph's registration point
/// - Y increases upward (mathematical coordinates)
/// - bBoxSW is the bottom-left corner
/// - bBoxNE is the top-right corner
public struct GlyphBoundingBox: Codable, Hashable, Sendable {
    /// The x-coordinate of the bottom-left corner.
    public let southWestX: StaffSpaces

    /// The y-coordinate of the bottom-left corner.
    public let southWestY: StaffSpaces

    /// The x-coordinate of the top-right corner.
    public let northEastX: StaffSpaces

    /// The y-coordinate of the top-right corner.
    public let northEastY: StaffSpaces

    /// Creates a bounding box from SMuFL JSON format [swX, swY], [neX, neY].
    public init(bBoxSW: [CGFloat], bBoxNE: [CGFloat]) {
        precondition(bBoxSW.count >= 2, "bBoxSW must have at least 2 elements")
        precondition(bBoxNE.count >= 2, "bBoxNE must have at least 2 elements")
        self.southWestX = bBoxSW[0]
        self.southWestY = bBoxSW[1]
        self.northEastX = bBoxNE[0]
        self.northEastY = bBoxNE[1]
    }

    /// Creates a bounding box with explicit coordinates.
    public init(southWestX: StaffSpaces, southWestY: StaffSpaces,
                northEastX: StaffSpaces, northEastY: StaffSpaces) {
        self.southWestX = southWestX
        self.southWestY = southWestY
        self.northEastX = northEastX
        self.northEastY = northEastY
    }

    /// The width of the bounding box in staff spaces.
    public var width: StaffSpaces {
        northEastX - southWestX
    }

    /// The height of the bounding box in staff spaces.
    public var height: StaffSpaces {
        northEastY - southWestY
    }

    /// The bounding box as a CGRect (note: Y is flipped for Core Graphics).
    public func cgRect(staffSpaceInPoints: CGFloat) -> CGRect {
        CGRect(
            x: southWestX * staffSpaceInPoints,
            y: -northEastY * staffSpaceInPoints,  // Flip Y for Core Graphics
            width: width * staffSpaceInPoints,
            height: height * staffSpaceInPoints
        )
    }
}

/// Anchor point types defined in SMuFL for combining glyphs.
public enum AnchorType: String, Codable, CaseIterable, Sendable {
    // Stem attachment points for noteheads
    case stemUpSE             // Bottom-right for upward stems
    case stemDownNW           // Top-left for downward stems
    case stemUpNW             // Top-left extension for upward stems
    case stemDownSW           // Bottom-left for downward stems

    // Split stem anchors (for complex noteheads)
    case splitStemUpSE
    case splitStemUpSW
    case splitStemDownNE
    case splitStemDownNW

    // Cut-out regions for accidental kerning
    case cutOutNE
    case cutOutSE
    case cutOutSW
    case cutOutNW

    // Grace note slash attachment
    case graceNoteSlashSW
    case graceNoteSlashNE
    case graceNoteSlashNW
    case graceNoteSlashSE

    // Positioning anchors
    case opticalCenter        // Visual center for dynamics alignment
    case noteheadOrigin       // Left edge of asymmetric noteheads
    case nominalWidth         // Precise width for leger line alignment

    // Numeral anchors (for clefs with numbers)
    case numeralTop
    case numeralBottom

    // Repeat/tessellation
    case repeatOffset         // For tiling multi-segment lines
}

/// Anchor points for a glyph, used for precise positioning when combining glyphs.
public struct GlyphAnchors: Codable, Sendable {
    /// Raw anchor data keyed by anchor name.
    private var anchors: [String: [CGFloat]]

    /// Creates anchors from a dictionary of anchor points.
    public init(anchors: [String: [CGFloat]]) {
        self.anchors = anchors
    }

    /// Returns the anchor point for the specified type, if available.
    public func point(for type: AnchorType) -> CGPoint? {
        guard let values = anchors[type.rawValue], values.count >= 2 else {
            return nil
        }
        return CGPoint(x: values[0], y: values[1])
    }

    /// Returns the anchor point as staff space coordinates.
    public func staffSpacePoint(for type: AnchorType) -> (x: StaffSpaces, y: StaffSpaces)? {
        guard let values = anchors[type.rawValue], values.count >= 2 else {
            return nil
        }
        return (x: values[0], y: values[1])
    }

    /// All available anchor types for this glyph.
    public var availableAnchors: [AnchorType] {
        AnchorType.allCases.filter { anchors[$0.rawValue] != nil }
    }
}

/// Information about a glyph alternate.
public struct GlyphAlternate: Codable, Sendable {
    /// The code point of the alternate glyph.
    public let codepoint: String

    /// The canonical name of the alternate glyph.
    public let name: String

    /// The glyph this is an alternate for.
    public let alternateFor: String?
}

/// Information about an optional glyph.
public struct OptionalGlyph: Codable, Sendable {
    /// The code point of the optional glyph.
    public let codepoint: String

    /// The class(es) this glyph belongs to.
    public let classes: [String]?

    /// Description of the glyph.
    public let description: String?
}

/// A ligature combining multiple glyphs.
public struct GlyphLigature: Codable, Sendable {
    /// The code point of the ligature glyph.
    public let codepoint: String

    /// The component glyphs that form this ligature.
    public let componentGlyphs: [String]

    /// Description of the ligature.
    public let description: String?
}
