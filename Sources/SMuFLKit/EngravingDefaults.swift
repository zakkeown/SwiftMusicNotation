import Foundation
import CoreGraphics

/// Default engraving values for a SMuFL font.
///
/// All measurements are in staff spaces unless otherwise noted.
/// These values come from the font's metadata.json file.
///
/// Reference: https://w3c.github.io/smufl/latest/specification/engravingdefaults.html
public struct EngravingDefaults: Codable, Sendable {

    // MARK: - Line Thicknesses

    /// Thickness of staff lines.
    public var staffLineThickness: StaffSpaces

    /// Thickness of stems.
    public var stemThickness: StaffSpaces

    /// Thickness of beams.
    public var beamThickness: StaffSpaces

    /// Spacing between beams.
    public var beamSpacing: StaffSpaces

    /// Thickness of leger lines.
    public var legerLineThickness: StaffSpaces

    /// Extension of leger lines beyond the notehead.
    public var legerLineExtension: StaffSpaces

    // MARK: - Slur and Tie Thicknesses

    /// Thickness of slur endpoints.
    public var slurEndpointThickness: StaffSpaces

    /// Thickness at the midpoint of slurs.
    public var slurMidpointThickness: StaffSpaces

    /// Thickness of tie endpoints.
    public var tieEndpointThickness: StaffSpaces

    /// Thickness at the midpoint of ties.
    public var tieMidpointThickness: StaffSpaces

    // MARK: - Barline Thicknesses

    /// Thickness of thin barlines.
    public var thinBarlineThickness: StaffSpaces

    /// Thickness of thick barlines.
    public var thickBarlineThickness: StaffSpaces

    /// Thickness of dashed barlines.
    public var dashedBarlineThickness: StaffSpaces

    /// Length of dashes in dashed barlines.
    public var dashedBarlineDashLength: StaffSpaces

    /// Length of gaps in dashed barlines.
    public var dashedBarlineGapLength: StaffSpaces

    // MARK: - Barline Spacing

    /// Separation between barline components.
    public var barlineSeparation: StaffSpaces

    /// Separation between thin and thick barlines.
    public var thinThickBarlineSeparation: StaffSpaces

    /// Separation between repeat dots and barlines.
    public var repeatBarlineDotSeparation: StaffSpaces

    // MARK: - Bracket Thicknesses

    /// Thickness of system brackets.
    public var bracketThickness: StaffSpaces

    /// Thickness of sub-brackets.
    public var subBracketThickness: StaffSpaces

    // MARK: - Other Element Thicknesses

    /// Thickness of hairpin lines.
    public var hairpinThickness: StaffSpaces

    /// Thickness of octave lines.
    public var octaveLineThickness: StaffSpaces

    /// Thickness of pedal lines.
    public var pedalLineThickness: StaffSpaces

    /// Thickness of repeat ending lines.
    public var repeatEndingLineThickness: StaffSpaces

    /// Thickness of lyric extender lines.
    public var lyricLineThickness: StaffSpaces

    /// Thickness of text enclosure lines.
    public var textEnclosureThickness: StaffSpaces

    /// Thickness of tuplet bracket lines.
    public var tupletBracketThickness: StaffSpaces

    /// Thickness of H-bar for multi-bar rests.
    public var hBarThickness: StaffSpaces

    // MARK: - Text

    /// Recommended text font families.
    public var textFontFamily: [String]?

    // MARK: - Initialization

    /// Creates engraving defaults with the specified values.
    public init(
        staffLineThickness: StaffSpaces = 0.13,
        stemThickness: StaffSpaces = 0.12,
        beamThickness: StaffSpaces = 0.5,
        beamSpacing: StaffSpaces = 0.25,
        legerLineThickness: StaffSpaces = 0.16,
        legerLineExtension: StaffSpaces = 0.4,
        slurEndpointThickness: StaffSpaces = 0.1,
        slurMidpointThickness: StaffSpaces = 0.22,
        tieEndpointThickness: StaffSpaces = 0.1,
        tieMidpointThickness: StaffSpaces = 0.22,
        thinBarlineThickness: StaffSpaces = 0.16,
        thickBarlineThickness: StaffSpaces = 0.5,
        dashedBarlineThickness: StaffSpaces = 0.16,
        dashedBarlineDashLength: StaffSpaces = 0.5,
        dashedBarlineGapLength: StaffSpaces = 0.25,
        barlineSeparation: StaffSpaces = 0.4,
        thinThickBarlineSeparation: StaffSpaces = 0.4,
        repeatBarlineDotSeparation: StaffSpaces = 0.16,
        bracketThickness: StaffSpaces = 0.5,
        subBracketThickness: StaffSpaces = 0.16,
        hairpinThickness: StaffSpaces = 0.16,
        octaveLineThickness: StaffSpaces = 0.16,
        pedalLineThickness: StaffSpaces = 0.16,
        repeatEndingLineThickness: StaffSpaces = 0.16,
        lyricLineThickness: StaffSpaces = 0.16,
        textEnclosureThickness: StaffSpaces = 0.16,
        tupletBracketThickness: StaffSpaces = 0.16,
        hBarThickness: StaffSpaces = 1.0,
        textFontFamily: [String]? = nil
    ) {
        self.staffLineThickness = staffLineThickness
        self.stemThickness = stemThickness
        self.beamThickness = beamThickness
        self.beamSpacing = beamSpacing
        self.legerLineThickness = legerLineThickness
        self.legerLineExtension = legerLineExtension
        self.slurEndpointThickness = slurEndpointThickness
        self.slurMidpointThickness = slurMidpointThickness
        self.tieEndpointThickness = tieEndpointThickness
        self.tieMidpointThickness = tieMidpointThickness
        self.thinBarlineThickness = thinBarlineThickness
        self.thickBarlineThickness = thickBarlineThickness
        self.dashedBarlineThickness = dashedBarlineThickness
        self.dashedBarlineDashLength = dashedBarlineDashLength
        self.dashedBarlineGapLength = dashedBarlineGapLength
        self.barlineSeparation = barlineSeparation
        self.thinThickBarlineSeparation = thinThickBarlineSeparation
        self.repeatBarlineDotSeparation = repeatBarlineDotSeparation
        self.bracketThickness = bracketThickness
        self.subBracketThickness = subBracketThickness
        self.hairpinThickness = hairpinThickness
        self.octaveLineThickness = octaveLineThickness
        self.pedalLineThickness = pedalLineThickness
        self.repeatEndingLineThickness = repeatEndingLineThickness
        self.lyricLineThickness = lyricLineThickness
        self.textEnclosureThickness = textEnclosureThickness
        self.tupletBracketThickness = tupletBracketThickness
        self.hBarThickness = hBarThickness
        self.textFontFamily = textFontFamily
    }

    /// Default engraving values based on Bravura reference font.
    public static let `default` = EngravingDefaults()
}

// MARK: - Codable

extension EngravingDefaults {
    enum CodingKeys: String, CodingKey {
        case staffLineThickness
        case stemThickness
        case beamThickness
        case beamSpacing
        case legerLineThickness
        case legerLineExtension
        case slurEndpointThickness
        case slurMidpointThickness
        case tieEndpointThickness
        case tieMidpointThickness
        case thinBarlineThickness
        case thickBarlineThickness
        case dashedBarlineThickness
        case dashedBarlineDashLength
        case dashedBarlineGapLength
        case barlineSeparation
        case thinThickBarlineSeparation
        case repeatBarlineDotSeparation
        case bracketThickness
        case subBracketThickness
        case hairpinThickness
        case octaveLineThickness
        case pedalLineThickness
        case repeatEndingLineThickness
        case lyricLineThickness
        case textEnclosureThickness
        case tupletBracketThickness
        case hBarThickness
        case textFontFamily
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let defaults = EngravingDefaults.default

        self.staffLineThickness = try container.decodeIfPresent(StaffSpaces.self, forKey: .staffLineThickness) ?? defaults.staffLineThickness
        self.stemThickness = try container.decodeIfPresent(StaffSpaces.self, forKey: .stemThickness) ?? defaults.stemThickness
        self.beamThickness = try container.decodeIfPresent(StaffSpaces.self, forKey: .beamThickness) ?? defaults.beamThickness
        self.beamSpacing = try container.decodeIfPresent(StaffSpaces.self, forKey: .beamSpacing) ?? defaults.beamSpacing
        self.legerLineThickness = try container.decodeIfPresent(StaffSpaces.self, forKey: .legerLineThickness) ?? defaults.legerLineThickness
        self.legerLineExtension = try container.decodeIfPresent(StaffSpaces.self, forKey: .legerLineExtension) ?? defaults.legerLineExtension
        self.slurEndpointThickness = try container.decodeIfPresent(StaffSpaces.self, forKey: .slurEndpointThickness) ?? defaults.slurEndpointThickness
        self.slurMidpointThickness = try container.decodeIfPresent(StaffSpaces.self, forKey: .slurMidpointThickness) ?? defaults.slurMidpointThickness
        self.tieEndpointThickness = try container.decodeIfPresent(StaffSpaces.self, forKey: .tieEndpointThickness) ?? defaults.tieEndpointThickness
        self.tieMidpointThickness = try container.decodeIfPresent(StaffSpaces.self, forKey: .tieMidpointThickness) ?? defaults.tieMidpointThickness
        self.thinBarlineThickness = try container.decodeIfPresent(StaffSpaces.self, forKey: .thinBarlineThickness) ?? defaults.thinBarlineThickness
        self.thickBarlineThickness = try container.decodeIfPresent(StaffSpaces.self, forKey: .thickBarlineThickness) ?? defaults.thickBarlineThickness
        self.dashedBarlineThickness = try container.decodeIfPresent(StaffSpaces.self, forKey: .dashedBarlineThickness) ?? defaults.dashedBarlineThickness
        self.dashedBarlineDashLength = try container.decodeIfPresent(StaffSpaces.self, forKey: .dashedBarlineDashLength) ?? defaults.dashedBarlineDashLength
        self.dashedBarlineGapLength = try container.decodeIfPresent(StaffSpaces.self, forKey: .dashedBarlineGapLength) ?? defaults.dashedBarlineGapLength
        self.barlineSeparation = try container.decodeIfPresent(StaffSpaces.self, forKey: .barlineSeparation) ?? defaults.barlineSeparation
        self.thinThickBarlineSeparation = try container.decodeIfPresent(StaffSpaces.self, forKey: .thinThickBarlineSeparation) ?? defaults.thinThickBarlineSeparation
        self.repeatBarlineDotSeparation = try container.decodeIfPresent(StaffSpaces.self, forKey: .repeatBarlineDotSeparation) ?? defaults.repeatBarlineDotSeparation
        self.bracketThickness = try container.decodeIfPresent(StaffSpaces.self, forKey: .bracketThickness) ?? defaults.bracketThickness
        self.subBracketThickness = try container.decodeIfPresent(StaffSpaces.self, forKey: .subBracketThickness) ?? defaults.subBracketThickness
        self.hairpinThickness = try container.decodeIfPresent(StaffSpaces.self, forKey: .hairpinThickness) ?? defaults.hairpinThickness
        self.octaveLineThickness = try container.decodeIfPresent(StaffSpaces.self, forKey: .octaveLineThickness) ?? defaults.octaveLineThickness
        self.pedalLineThickness = try container.decodeIfPresent(StaffSpaces.self, forKey: .pedalLineThickness) ?? defaults.pedalLineThickness
        self.repeatEndingLineThickness = try container.decodeIfPresent(StaffSpaces.self, forKey: .repeatEndingLineThickness) ?? defaults.repeatEndingLineThickness
        self.lyricLineThickness = try container.decodeIfPresent(StaffSpaces.self, forKey: .lyricLineThickness) ?? defaults.lyricLineThickness
        self.textEnclosureThickness = try container.decodeIfPresent(StaffSpaces.self, forKey: .textEnclosureThickness) ?? defaults.textEnclosureThickness
        self.tupletBracketThickness = try container.decodeIfPresent(StaffSpaces.self, forKey: .tupletBracketThickness) ?? defaults.tupletBracketThickness
        self.hBarThickness = try container.decodeIfPresent(StaffSpaces.self, forKey: .hBarThickness) ?? defaults.hBarThickness
        self.textFontFamily = try container.decodeIfPresent([String].self, forKey: .textFontFamily)
    }
}
