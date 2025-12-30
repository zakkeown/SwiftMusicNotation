import Foundation
import SMuFLKit

/// The notehead style used for percussion notation.
///
/// Different percussion instruments use distinct notehead shapes to indicate
/// the specific instrument on a percussion staff. This enum represents the
/// common notehead styles used in drum kit and orchestral percussion notation.
public enum PercussionNotehead: String, Codable, Sendable, CaseIterable {

    /// Standard filled/open notehead (used for drums)
    case normal

    /// X-shaped notehead (used for hi-hat, cymbals)
    case x

    /// Circle with X inside (used for open hi-hat)
    case circleX

    /// Diamond-shaped notehead (used for ride bell, cowbell)
    case diamond

    /// Triangle-shaped notehead pointing up (used for triangle instrument)
    case triangle

    /// Triangle-shaped notehead pointing down
    case triangleDown

    /// Slash notehead (used for rhythm slashes)
    case slash

    /// Plus/cross notehead (used for muted/dead stroke, rim shots)
    case plus

    /// Ghost note (parenthesized - notehead with parentheses)
    case ghost

    // MARK: - Glyph Resolution

    /// Returns the appropriate SMuFL glyph for this notehead and duration.
    ///
    /// - Parameter duration: The duration base to get the glyph for
    /// - Returns: The SMuFL glyph name for rendering
    public func glyph(for duration: DurationBase) -> SMuFLGlyphName {
        switch self {
        case .normal:
            return normalGlyph(for: duration)
        case .x:
            return xGlyph(for: duration)
        case .circleX:
            return circleXGlyph(for: duration)
        case .diamond:
            return diamondGlyph(for: duration)
        case .triangle:
            return triangleUpGlyph(for: duration)
        case .triangleDown:
            return triangleDownGlyph(for: duration)
        case .slash:
            return slashGlyph(for: duration)
        case .plus:
            return plusGlyph(for: duration)
        case .ghost:
            // Ghost notes use the normal notehead - parentheses are rendered separately
            return normalGlyph(for: duration)
        }
    }

    /// Returns the left parenthesis glyph for ghost notes.
    public var leftParenthesisGlyph: SMuFLGlyphName {
        .noteheadParenthesisLeft
    }

    /// Returns the right parenthesis glyph for ghost notes.
    public var rightParenthesisGlyph: SMuFLGlyphName {
        .noteheadParenthesisRight
    }

    // MARK: - Private Glyph Helpers

    private func normalGlyph(for duration: DurationBase) -> SMuFLGlyphName {
        switch duration {
        case .maxima, .longa, .breve:
            return .noteheadDoubleWhole
        case .whole:
            return .noteheadWhole
        case .half:
            return .noteheadHalf
        default:
            return .noteheadBlack
        }
    }

    private func xGlyph(for duration: DurationBase) -> SMuFLGlyphName {
        switch duration {
        case .maxima, .longa, .breve:
            return .noteheadXDoubleWhole
        case .whole:
            return .noteheadXWhole
        case .half:
            return .noteheadXHalf
        default:
            return .noteheadXBlack
        }
    }

    private func circleXGlyph(for duration: DurationBase) -> SMuFLGlyphName {
        switch duration {
        case .maxima, .longa, .breve:
            return .noteheadCircleXDoubleWhole
        case .whole:
            return .noteheadCircleXWhole
        case .half:
            return .noteheadCircleXHalf
        default:
            return .noteheadCircleX
        }
    }

    private func diamondGlyph(for duration: DurationBase) -> SMuFLGlyphName {
        switch duration {
        case .maxima, .longa, .breve:
            return .noteheadDiamondDoubleWhole
        case .whole:
            return .noteheadDiamondWhole
        case .half:
            return .noteheadDiamondHalf
        default:
            return .noteheadDiamondBlack
        }
    }

    private func triangleUpGlyph(for duration: DurationBase) -> SMuFLGlyphName {
        switch duration {
        case .maxima, .longa, .breve:
            return .noteheadTriangleUpDoubleWhole
        case .whole:
            return .noteheadTriangleUpWhole
        case .half:
            return .noteheadTriangleUpHalf
        default:
            return .noteheadTriangleUpBlack
        }
    }

    private func triangleDownGlyph(for duration: DurationBase) -> SMuFLGlyphName {
        switch duration {
        case .maxima, .longa, .breve:
            return .noteheadTriangleDownDoubleWhole
        case .whole:
            return .noteheadTriangleDownWhole
        case .half:
            return .noteheadTriangleDownHalf
        default:
            return .noteheadTriangleDownBlack
        }
    }

    private func slashGlyph(for duration: DurationBase) -> SMuFLGlyphName {
        switch duration {
        case .maxima, .longa, .breve, .whole:
            return .noteheadSlashWhiteWhole
        case .half:
            return .noteheadSlashWhiteHalf
        default:
            return .noteheadSlashVerticalEnds
        }
    }

    private func plusGlyph(for duration: DurationBase) -> SMuFLGlyphName {
        switch duration {
        case .maxima, .longa, .breve:
            return .noteheadPlusDoubleWhole
        case .whole:
            return .noteheadPlusWhole
        case .half:
            return .noteheadPlusHalf
        default:
            return .noteheadPlusBlack
        }
    }

    // MARK: - MusicXML Conversion

    /// Creates a PercussionNotehead from a MusicXML notehead value.
    ///
    /// - Parameter musicXMLValue: The MusicXML notehead type string
    /// - Returns: The corresponding PercussionNotehead, or nil if not a percussion notehead
    public init?(musicXMLValue: String) {
        switch musicXMLValue {
        case "normal", "":
            self = .normal
        case "x":
            self = .x
        case "circle-x":
            self = .circleX
        case "diamond":
            self = .diamond
        case "triangle":
            self = .triangle
        case "inverted triangle":
            self = .triangleDown
        case "slash":
            self = .slash
        case "cross", "plus":
            self = .plus
        default:
            return nil
        }
    }

    /// The MusicXML notehead type value for this notehead.
    public var musicXMLValue: String {
        switch self {
        case .normal:
            return "normal"
        case .x:
            return "x"
        case .circleX:
            return "circle-x"
        case .diamond:
            return "diamond"
        case .triangle:
            return "triangle"
        case .triangleDown:
            return "inverted triangle"
        case .slash:
            return "slash"
        case .plus:
            return "cross"
        case .ghost:
            return "normal"  // Ghost uses normal with parentheses attribute
        }
    }
}
