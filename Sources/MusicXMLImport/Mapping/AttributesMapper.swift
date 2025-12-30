import Foundation
import MusicNotationCore

/// Maps MusicXML `<attributes>` elements to ``MeasureAttributes`` model objects.
///
/// `AttributesMapper` handles the parsing of measure-level musical attributes that define
/// the musical context for subsequent notes. These attributes include clefs, key signatures,
/// time signatures, staff configurations, and transposition settings.
///
/// ## Responsibilities
///
/// - **Divisions**: Parses the `<divisions>` value that defines duration units per quarter note
/// - **Key Signatures**: Extracts fifths-based key signatures with optional mode
/// - **Time Signatures**: Parses beat/beat-type pairs and common/cut time symbols
/// - **Clefs**: Handles multiple clefs for multi-staff parts with staff number assignment
/// - **Transposition**: Parses chromatic and diatonic transposition for transposing instruments
/// - **Staff Details**: Extracts staff line count and staff type for non-standard staves
///
/// ## Multi-Staff Support
///
/// MusicXML allows different attributes per staff in multi-staff parts (e.g., piano).
/// The mapper tracks staff numbers and updates the parser context's staff count.
///
/// ## Context Updates
///
/// When parsing divisions, the mapper updates ``XMLParserContext/divisions`` so subsequent
/// note duration calculations use the correct base value.
///
/// ```swift
/// let mapper = AttributesMapper()
/// let attributes = try mapper.mapAttributes(from: element, context: context)
/// // context.divisions is now updated if <divisions> was present
/// ```
///
/// - SeeAlso: ``MusicXMLImporter`` for the main import entry point
/// - SeeAlso: ``NoteMapper`` for note element parsing
/// - SeeAlso: ``MeasureAttributes`` for the output model
public struct AttributesMapper {
    // MARK: - Validation Constants

    /// Maximum reasonable value for divisions (prevents DoS).
    private static let maxDivisions: Int = 1_000_000

    /// Maximum reasonable number of staves per part.
    private static let maxStaves: Int = 100

    public init() {}

    /// Maps an `<attributes>` XML element to a ``MeasureAttributes`` model.
    ///
    /// Parses all attribute children including divisions, key signatures, time signatures,
    /// clefs, transposition, staff details, and measure style. Updates the parser context
    /// with new divisions and staff count values.
    ///
    /// - Parameters:
    ///   - element: The `<attributes>` XML element to parse
    ///   - context: The parser context to update with divisions and staff counts
    /// - Returns: A ``MeasureAttributes`` instance containing all parsed attributes
    /// - Throws: ``MusicXMLError`` if required elements have invalid values
    public func mapAttributes(
        from element: XMLElement,
        context: XMLParserContext
    ) throws -> MeasureAttributes {
        // Divisions (duration units per quarter note)
        var divisions: Int?
        if let divisionsStr = element.child(named: "divisions")?.textContent,
           let divisionsValue = Int(divisionsStr) {
            // Validate divisions is within reasonable bounds
            guard divisionsValue > 0 && divisionsValue <= Self.maxDivisions else {
                throw MusicXMLError.invalidXMLStructure("Divisions value \(divisionsValue) is out of valid range (1-\(Self.maxDivisions))")
            }
            context.divisions = divisionsValue
            divisions = divisionsValue
        }

        // Number of staves
        var staves: Int?
        if let stavesStr = element.child(named: "staves")?.textContent,
           let stavesValue = Int(stavesStr) {
            // Validate staves is within reasonable bounds
            guard stavesValue > 0 && stavesValue <= Self.maxStaves else {
                throw MusicXMLError.invalidXMLStructure("Staves value \(stavesValue) is out of valid range (1-\(Self.maxStaves))")
            }
            staves = stavesValue
            if let partId = context.currentPartId {
                context.partStaffCounts[partId] = stavesValue
            }
        }

        // Key signatures (can be multiple for different staves)
        var keySignatures: [KeySignature] = []
        for keyElement in element.children(named: "key") {
            let staffNumber = keyElement.attribute(named: "number").flatMap(Int.init)
            let key = try mapKeySignature(from: keyElement, staffNumber: staffNumber)
            keySignatures.append(key)
        }

        // Time signatures (can be multiple for different staves)
        var timeSignatures: [TimeSignature] = []
        for timeElement in element.children(named: "time") {
            let staffNumber = timeElement.attribute(named: "number").flatMap(Int.init)
            let time = try mapTimeSignature(from: timeElement, staffNumber: staffNumber)
            timeSignatures.append(time)
        }

        // Clefs (can be multiple for different staves)
        var clefs: [Clef] = []
        for clefElement in element.children(named: "clef") {
            let staffNumber = clefElement.attribute(named: "number").flatMap(Int.init)
            let additional = clefElement.attribute(named: "additional") == "yes"
            let clef = try mapClef(from: clefElement, staffNumber: staffNumber, additional: additional)
            clefs.append(clef)
        }

        // Transpose
        var transposes: [Transpose] = []
        for transposeElement in element.children(named: "transpose") {
            let staffNumber = transposeElement.attribute(named: "number").flatMap(Int.init)
            let transpose = mapTranspose(from: transposeElement, staffNumber: staffNumber)
            transposes.append(transpose)
        }

        // Staff details
        var staffDetails: [StaffDetails] = []
        for staffDetailsElement in element.children(named: "staff-details") {
            let detail = mapStaffDetails(from: staffDetailsElement)
            staffDetails.append(detail)
        }

        // Measure style
        var measureStyle: MeasureStyle?
        if let measureStyleElement = element.child(named: "measure-style") {
            measureStyle = mapMeasureStyle(from: measureStyleElement)
        }

        return MeasureAttributes(
            divisions: divisions,
            keySignatures: keySignatures,
            timeSignatures: timeSignatures,
            staves: staves,
            clefs: clefs,
            transposes: transposes,
            staffDetails: staffDetails,
            measureStyle: measureStyle
        )
    }

    // MARK: - Key Signature

    private func mapKeySignature(from element: XMLElement, staffNumber: Int?) throws -> KeySignature {
        // Traditional key (fifths-based)
        if let fifthsStr = element.child(named: "fifths")?.textContent,
           let fifths = Int(fifthsStr) {
            let modeStr = element.child(named: "mode")?.textContent ?? "major"
            let mode = KeyMode(rawValue: modeStr)
            return KeySignature(fifths: fifths, mode: mode, staffNumber: staffNumber)
        }

        // Non-traditional key - default to C major
        return KeySignature(fifths: 0, mode: .major, staffNumber: staffNumber)
    }

    // MARK: - Time Signature

    private func mapTimeSignature(from element: XMLElement, staffNumber: Int?) throws -> TimeSignature {
        // Check for common/cut time symbols
        var symbol: TimeSymbol?
        if let symbolStr = element.attribute(named: "symbol") {
            symbol = TimeSymbol(rawValue: symbolStr)
            switch symbolStr {
            case "common":
                return TimeSignature(beats: "4", beatType: "4", symbol: .common, staffNumber: staffNumber)
            case "cut":
                return TimeSignature(beats: "2", beatType: "2", symbol: .cut, staffNumber: staffNumber)
            default:
                break
            }
        }

        // Standard time signature
        guard let beatsStr = element.child(named: "beats")?.textContent,
              let beatTypeStr = element.child(named: "beat-type")?.textContent else {
            throw MusicXMLError.invalidTimeSignature(
                beats: element.child(named: "beats")?.textContent,
                beatType: element.child(named: "beat-type")?.textContent
            )
        }

        return TimeSignature(beats: beatsStr, beatType: beatTypeStr, symbol: symbol, staffNumber: staffNumber)
    }

    // MARK: - Clef

    private func mapClef(from element: XMLElement, staffNumber: Int?, additional: Bool) throws -> Clef {
        guard let signStr = element.child(named: "sign")?.textContent else {
            throw MusicXMLError.missingRequiredElement(element: "sign", parent: "clef")
        }

        let sign: ClefSign
        switch signStr.uppercased() {
        case "G": sign = .g
        case "F": sign = .f
        case "C": sign = .c
        case "PERCUSSION": sign = .percussion
        case "TAB": sign = .tab
        case "NONE": sign = .none
        default:
            throw MusicXMLError.invalidAttributeValue(attribute: "sign", element: "clef", value: signStr)
        }

        let line = element.child(named: "line")?.textContent.flatMap(Int.init) ?? defaultLine(for: sign)
        let octaveChange = element.child(named: "clef-octave-change")?.textContent.flatMap(Int.init)

        return Clef(
            sign: sign,
            line: line,
            clefOctaveChange: octaveChange,
            staffNumber: staffNumber,
            additional: additional
        )
    }

    private func defaultLine(for sign: ClefSign) -> Int {
        switch sign {
        case .g: return 2
        case .f: return 4
        case .c: return 3
        case .percussion: return 3
        case .tab: return 5
        case .none: return 1
        }
    }

    // MARK: - Transpose

    private func mapTranspose(from element: XMLElement, staffNumber: Int?) -> Transpose {
        let diatonic = element.child(named: "diatonic")?.textContent.flatMap(Int.init)
        let chromatic = element.child(named: "chromatic")?.textContent.flatMap(Int.init) ?? 0
        let octaveChange = element.child(named: "octave-change")?.textContent.flatMap(Int.init)
        let double = element.child(named: "double") != nil

        return Transpose(
            diatonic: diatonic,
            chromatic: chromatic,
            octaveChange: octaveChange,
            double: double,
            staffNumber: staffNumber
        )
    }

    // MARK: - Staff Details

    private func mapStaffDetails(from element: XMLElement) -> StaffDetails {
        let staffNumber = element.attribute(named: "number").flatMap(Int.init)
        let staffLines = element.child(named: "staff-lines")?.textContent.flatMap(Int.init)
        let staffTypeStr = element.child(named: "staff-type")?.textContent
        let staffType = staffTypeStr.flatMap { StaffType(rawValue: $0) }

        return StaffDetails(
            staffNumber: staffNumber,
            staffLines: staffLines,
            staffType: staffType
        )
    }

    // MARK: - Measure Style

    private func mapMeasureStyle(from element: XMLElement) -> MeasureStyle {
        var style = MeasureStyle()

        if let multipleRest = element.child(named: "multiple-rest")?.textContent.flatMap(Int.init) {
            style.multipleRest = multipleRest
        }

        if let slashElement = element.child(named: "slash") {
            let typeStr = slashElement.attribute(named: "type") ?? "start"
            if let type = StartStop(rawValue: typeStr) {
                let useDots = slashElement.attribute(named: "use-dots") == "yes"
                let useStems = slashElement.attribute(named: "use-stems") == "yes"
                style.slash = SlashNotation(type: type, useDots: useDots, useStems: useStems)
            }
        }

        if let beatRepeatElement = element.child(named: "beat-repeat") {
            let typeStr = beatRepeatElement.attribute(named: "type") ?? "start"
            if let type = StartStop(rawValue: typeStr) {
                let slashes = beatRepeatElement.attribute(named: "slashes").flatMap(Int.init)
                style.beatRepeat = BeatRepeat(type: type, slashes: slashes)
            }
        }

        if let measureRepeatElement = element.child(named: "measure-repeat") {
            let typeStr = measureRepeatElement.attribute(named: "type") ?? "start"
            if let type = StartStop(rawValue: typeStr) {
                let slashes = measureRepeatElement.textContent.flatMap(Int.init)
                style.measureRepeat = MeasureRepeat(type: type, slashes: slashes)
            }
        }

        return style
    }
}

// MARK: - Extension for MeasureAttributes

extension MeasureAttributes {
    /// Whether this attributes element has any content.
    public var isEmpty: Bool {
        divisions == nil &&
        keySignatures.isEmpty &&
        timeSignatures.isEmpty &&
        staves == nil &&
        clefs.isEmpty &&
        transposes.isEmpty &&
        staffDetails.isEmpty &&
        measureStyle == nil
    }
}
