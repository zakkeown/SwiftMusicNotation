import Foundation
import MusicNotationCore

/// Maps MusicXML `<note>` elements to ``Note`` model objects.
///
/// `NoteMapper` is a core component of the import pipeline responsible for transforming
/// XML note data into rich domain model objects. It handles all aspects of note parsing
/// including pitch extraction, duration calculation, and notation attachment.
///
/// ## Responsibilities
///
/// - **Pitch Extraction**: Parses `<pitch>`, `<unpitched>`, and `<rest>` elements
/// - **Duration Parsing**: Extracts divisions-based duration and visual note type
/// - **Voice/Staff Assignment**: Tracks polyphonic voice and multi-staff placement
/// - **Notation Attachment**: Parses articulations, dynamics, ornaments, technical marks
/// - **Beam/Tie Data**: Extracts beam levels and tie start/stop indicators
/// - **Lyrics**: Parses lyric syllables with syllabic type and extensions
///
/// ## Usage
///
/// `NoteMapper` is typically used internally by ``MusicXMLImporter`` but can be used
/// directly for custom import scenarios:
///
/// ```swift
/// let mapper = NoteMapper()
/// let note = try mapper.mapNote(from: noteElement, context: parserContext)
/// ```
///
/// ## Alteration Inference
///
/// When a `<pitch>` element lacks an explicit `<alter>` child but the note has an
/// `<accidental>` element, the mapper infers the alteration value. This handles
/// MusicXML files that omit redundant alter values.
///
/// - SeeAlso: ``MusicXMLImporter`` for the main import entry point
/// - SeeAlso: ``AttributesMapper`` for measure attribute parsing
/// - SeeAlso: ``DirectionMapper`` for direction element parsing
public struct NoteMapper {
    public init() {}

    /// Maps an XML `<note>` element to a ``Note`` model object.
    ///
    /// This method extracts all note properties from the XML element including pitch/rest content,
    /// duration, voice and staff assignment, visual properties (stem, notehead, accidental),
    /// beam grouping data, ties, and attached notations.
    ///
    /// - Parameters:
    ///   - element: The `<note>` XML element to parse
    ///   - context: The parser context containing state like current divisions
    /// - Returns: A fully populated ``Note`` instance
    /// - Throws: ``MusicXMLError`` if required elements are missing or invalid
    public func mapNote(
        from element: XMLElement,
        context: XMLParserContext
    ) throws -> Note {
        // Determine note content type
        let isRest = element.child(named: "rest") != nil
        let isChord = element.child(named: "chord") != nil

        // Parse note content
        let noteContent: NoteContent
        if isRest {
            noteContent = try mapRest(from: element)
        } else if let pitchElement = element.child(named: "pitch") {
            noteContent = try mapPitch(from: pitchElement, noteElement: element)
        } else if let unpitchedElement = element.child(named: "unpitched") {
            noteContent = mapUnpitched(from: unpitchedElement, noteElement: element)
        } else {
            throw MusicXMLError.invalidXMLStructure("Note must have pitch, rest, or unpitched")
        }

        // Parse duration
        let durationDivisions = element.child(named: "duration")?.textContent.flatMap(Int.init) ?? 0

        // Parse voice and staff
        let voice = element.child(named: "voice")?.textContent.flatMap(Int.init) ?? 1
        let staff = element.child(named: "staff")?.textContent.flatMap(Int.init) ?? 1

        // Parse type (visual duration)
        let noteTypeStr = element.child(named: "type")?.textContent
        let durationBase = noteTypeStr.flatMap { DurationBase(musicXMLName: $0) }

        // Parse dots
        let dots = element.children(named: "dot").count

        // Parse stem direction
        let stemDirection = element.child(named: "stem")?.textContent.flatMap { StemDirection(rawValue: $0) }

        // Parse accidental
        let accidentalMark = mapAccidental(from: element)

        // Parse notehead
        let noteheadInfo = mapNotehead(from: element)

        // Parse beams
        let beams = mapBeams(from: element)

        // Parse ties
        let ties = mapTies(from: element)

        // Parse notations
        let notations = try mapNotations(from: element)

        // Parse grace note
        let grace = mapGraceNote(from: element)

        // Parse time modification (tuplet)
        let timeModification = mapTimeModification(from: element)

        // Parse lyrics
        let lyrics = mapLyrics(from: element)

        // Parse cue
        let cue = element.child(named: "cue") != nil

        // Parse print-object
        let printObject = element.attribute(named: "print-object") != "no"

        return Note(
            noteType: noteContent,
            durationDivisions: durationDivisions,
            type: durationBase,
            dots: dots,
            voice: voice,
            staff: staff,
            isChordTone: isChord,
            grace: grace,
            cue: cue,
            stemDirection: stemDirection,
            notehead: noteheadInfo,
            beams: beams,
            ties: ties,
            accidental: accidentalMark,
            notations: notations,
            lyrics: lyrics,
            timeModification: timeModification,
            printObject: printObject
        )
    }

    // MARK: - Private Helpers

    private func mapPitch(from element: XMLElement, noteElement: XMLElement) throws -> NoteContent {
        guard let stepStr = element.child(named: "step")?.textContent,
              let step = PitchStep(rawValue: stepStr.uppercased()) else {
            throw MusicXMLError.invalidPitch(step: element.child(named: "step")?.textContent, octave: nil)
        }

        guard let octaveStr = element.child(named: "octave")?.textContent,
              let octave = Int(octaveStr) else {
            throw MusicXMLError.invalidPitch(step: stepStr, octave: nil)
        }

        // Get alter from <pitch><alter> element
        var alter = element.child(named: "alter")?.textContent.flatMap(Double.init) ?? 0

        // If no <alter> element, try to infer from <accidental> (some MusicXML files omit alter)
        if alter == 0, let accidentalText = noteElement.child(named: "accidental")?.textContent {
            alter = alterFromAccidental(accidentalText)
        }

        return .pitched(Pitch(step: step, alter: alter, octave: octave))
    }

    /// Converts accidental name to semitone alteration.
    private func alterFromAccidental(_ accidental: String) -> Double {
        switch accidental {
        case "sharp": return 1
        case "natural": return 0
        case "flat": return -1
        case "double-sharp", "sharp-sharp": return 2
        case "flat-flat", "double-flat": return -2
        case "natural-sharp": return 1
        case "natural-flat": return -1
        case "quarter-flat": return -0.5
        case "quarter-sharp": return 0.5
        case "three-quarters-flat": return -1.5
        case "three-quarters-sharp": return 1.5
        default: return 0
        }
    }

    private func mapRest(from element: XMLElement) throws -> NoteContent {
        let restElement = element.child(named: "rest")

        // Check for display-step and display-octave (positioned rest)
        let displayStep = restElement?.child(named: "display-step")?.textContent
            .flatMap { PitchStep(rawValue: $0.uppercased()) }
        let displayOctave = restElement?.child(named: "display-octave")?.textContent
            .flatMap(Int.init)

        // Check for measure rest
        let isMeasureRest = restElement?.attribute(named: "measure") == "yes"

        return .rest(RestInfo(
            measureRest: isMeasureRest,
            displayStep: displayStep,
            displayOctave: displayOctave
        ))
    }

    private func mapUnpitched(from unpitchedElement: XMLElement, noteElement: XMLElement) -> NoteContent {
        let displayStep = unpitchedElement.child(named: "display-step")?.textContent
            .flatMap { PitchStep(rawValue: $0.uppercased()) } ?? .c
        let displayOctave = unpitchedElement.child(named: "display-octave")?.textContent
            .flatMap(Int.init) ?? 4

        // Parse instrument reference from the note element
        let instrumentId = noteElement.child(named: "instrument")?.attribute(named: "id")

        return .unpitched(UnpitchedNote(
            displayStep: displayStep,
            displayOctave: displayOctave,
            instrumentId: instrumentId
        ))
    }

    private func mapAccidental(from element: XMLElement) -> AccidentalMark? {
        guard let accidentalElement = element.child(named: "accidental"),
              let accidentalText = accidentalElement.textContent,
              let accidental = Accidental(musicXMLName: accidentalText) else {
            return nil
        }

        let parentheses = accidentalElement.attribute(named: "parentheses") == "yes"
        let brackets = accidentalElement.attribute(named: "bracket") == "yes"
        let editorial = accidentalElement.attribute(named: "editorial") == "yes"
        let cautionary = accidentalElement.attribute(named: "cautionary") == "yes"

        return AccidentalMark(
            accidental: accidental,
            parentheses: parentheses,
            brackets: brackets,
            editorial: editorial,
            cautionary: cautionary
        )
    }

    private func mapNotehead(from element: XMLElement) -> NoteheadInfo? {
        guard let noteheadElement = element.child(named: "notehead"),
              let noteheadText = noteheadElement.textContent,
              let noteheadType = NoteheadType(rawValue: noteheadText) else {
            return nil
        }

        let filled = noteheadElement.attribute(named: "filled").map { $0 == "yes" }
        let parentheses = noteheadElement.attribute(named: "parentheses") == "yes"

        return NoteheadInfo(type: noteheadType, filled: filled, parentheses: parentheses)
    }

    private func mapBeams(from element: XMLElement) -> [BeamValue] {
        return element.children(named: "beam").compactMap { beamElement in
            guard let text = beamElement.textContent else { return nil }
            let beamType: BeamType?
            switch text {
            case "begin": beamType = .begin
            case "continue": beamType = .continue
            case "end": beamType = .end
            case "forward hook": beamType = .forwardHook
            case "backward hook": beamType = .backwardHook
            default: beamType = nil
            }
            guard let type = beamType else { return nil }
            let number = beamElement.attribute(named: "number").flatMap(Int.init) ?? 1
            return BeamValue(number: number, value: type)
        }
    }

    private func mapTies(from element: XMLElement) -> [Tie] {
        return element.children(named: "tie").compactMap { tieElement in
            guard let typeStr = tieElement.attribute(named: "type"),
                  let type = TieType(rawValue: typeStr) else {
                return nil
            }
            return Tie(type: type)
        }
    }

    private func mapGraceNote(from element: XMLElement) -> GraceNote? {
        guard let graceElement = element.child(named: "grace") else { return nil }

        let slash = graceElement.attribute(named: "slash") == "yes"
        let stealTimePrevious = graceElement.attribute(named: "steal-time-previous").flatMap(Double.init)
        let stealTimeFollowing = graceElement.attribute(named: "steal-time-following").flatMap(Double.init)

        return GraceNote(
            stealTimePrevious: stealTimePrevious,
            stealTimeFollowing: stealTimeFollowing,
            slash: slash
        )
    }

    private func mapTimeModification(from element: XMLElement) -> TupletRatio? {
        guard let timeModElement = element.child(named: "time-modification") else { return nil }

        guard let actualNotes = timeModElement.child(named: "actual-notes")?.textContent.flatMap(Int.init),
              let normalNotes = timeModElement.child(named: "normal-notes")?.textContent.flatMap(Int.init) else {
            return nil
        }

        let normalType = timeModElement.child(named: "normal-type")?.textContent
            .flatMap { DurationBase(musicXMLName: $0) }

        return TupletRatio(
            actual: actualNotes,
            normal: normalNotes,
            normalType: normalType
        )
    }

    private func mapLyrics(from element: XMLElement) -> [Lyric] {
        return element.children(named: "lyric").compactMap { lyricElement in
            guard let text = lyricElement.child(named: "text")?.textContent else { return nil }

            let number = lyricElement.attribute(named: "number")
            let syllabicStr = lyricElement.child(named: "syllabic")?.textContent
            let syllabic = syllabicStr.flatMap { Syllabic(rawValue: $0) }
            let extend = lyricElement.child(named: "extend") != nil

            return Lyric(number: number, text: text, syllabic: syllabic, extend: extend)
        }
    }

    private func mapNotations(from element: XMLElement) throws -> [Notation] {
        // Handle multiple <notations> elements per note (MusicXML allows this)
        let notationsElements = element.children(named: "notations")
        guard !notationsElements.isEmpty else {
            return []
        }

        var notations: [Notation] = []

        for notationsElement in notationsElements {
            // Tied
            for tiedElement in notationsElement.children(named: "tied") {
                if let typeStr = tiedElement.attribute(named: "type"),
                   let type = TieType(rawValue: typeStr) {
                    let number = tiedElement.attribute(named: "number").flatMap(Int.init)
                    let placement = tiedElement.attribute(named: "placement").flatMap { Placement(rawValue: $0) }
                    notations.append(.tied(TiedNotation(type: type, number: number, placement: placement)))
                }
            }

            // Slurs
            for slurElement in notationsElement.children(named: "slur") {
                if let typeStr = slurElement.attribute(named: "type"),
                   let type = StartStopContinue(rawValue: typeStr) {
                    let number = slurElement.attribute(named: "number").flatMap(Int.init) ?? 1
                    let placement = slurElement.attribute(named: "placement").flatMap { Placement(rawValue: $0) }
                    notations.append(.slur(SlurNotation(type: type, number: number, placement: placement)))
                }
            }

            // Tuplets
            for tupletElement in notationsElement.children(named: "tuplet") {
                if let typeStr = tupletElement.attribute(named: "type"),
                   let type = StartStop(rawValue: typeStr) {
                    let number = tupletElement.attribute(named: "number").flatMap(Int.init) ?? 1
                    let bracket = tupletElement.attribute(named: "bracket").map { $0 == "yes" }
                    let showNumberStr = tupletElement.attribute(named: "show-number")
                    let showNumber = showNumberStr.flatMap { ShowTuplet(rawValue: $0) }
                    let showTypeStr = tupletElement.attribute(named: "show-type")
                    let showType = showTypeStr.flatMap { ShowTuplet(rawValue: $0) }
                    notations.append(.tuplet(TupletNotation(type: type, number: number, bracket: bracket, showNumber: showNumber, showType: showType)))
                }
            }

            // Articulations - handle multiple <articulations> elements too
            for articulationsElement in notationsElement.children(named: "articulations") {
                let articulations = mapArticulations(from: articulationsElement)
                if !articulations.isEmpty {
                    notations.append(.articulations(articulations))
                }
            }

            // Dynamics
            if let dynamicsElement = notationsElement.child(named: "dynamics") {
                let dynamics = mapDynamics(from: dynamicsElement)
                if !dynamics.isEmpty {
                    notations.append(.dynamics(dynamics))
                }
            }

            // Ornaments
            if let ornamentsElement = notationsElement.child(named: "ornaments") {
                let ornaments = mapOrnaments(from: ornamentsElement)
                if !ornaments.isEmpty {
                    notations.append(.ornaments(ornaments))
                }
            }

            // Technical
            if let technicalElement = notationsElement.child(named: "technical") {
                let technical = mapTechnical(from: technicalElement)
                if !technical.isEmpty {
                    notations.append(.technical(technical))
                }
            }

            // Fermata
            if let fermataElement = notationsElement.child(named: "fermata") {
                let shapeStr = fermataElement.textContent ?? "normal"
                let shape = FermataShape(rawValue: shapeStr) ?? .normal
                let typeStr = fermataElement.attribute(named: "type") ?? "upright"
                let type = FermataType(rawValue: typeStr) ?? .upright
                notations.append(.fermata(Fermata(shape: shape, type: type)))
            }

            // Arpeggiate
            if let arpeggiateElement = notationsElement.child(named: "arpeggiate") {
                let directionStr = arpeggiateElement.attribute(named: "direction")
                let direction = directionStr.flatMap { ArpeggiateDirection(rawValue: $0) }
                let number = arpeggiateElement.attribute(named: "number").flatMap(Int.init)
                notations.append(.arpeggiate(Arpeggiate(direction: direction, number: number)))
            }

            // Glissando
            for glissandoElement in notationsElement.children(named: "glissando") {
                if let typeStr = glissandoElement.attribute(named: "type"),
                   let type = StartStop(rawValue: typeStr) {
                    let number = glissandoElement.attribute(named: "number").flatMap(Int.init)
                    let text = glissandoElement.textContent
                    notations.append(.glissando(Glissando(type: type, number: number, text: text)))
                }
            }

            // Slide
            for slideElement in notationsElement.children(named: "slide") {
                if let typeStr = slideElement.attribute(named: "type"),
                   let type = StartStop(rawValue: typeStr) {
                    let number = slideElement.attribute(named: "number").flatMap(Int.init)
                    notations.append(.slide(Slide(type: type, number: number)))
                }
            }
        }

        return notations
    }

    private func mapArticulations(from element: XMLElement) -> [ArticulationMark] {
        let articulationNames = [
            "accent", "strong-accent", "staccato", "staccatissimo", "tenuto",
            "detached-legato", "spiccato", "breath-mark", "caesura", "stress",
            "unstress", "soft-accent", "scoop", "plop", "doit", "falloff"
        ]

        return articulationNames.compactMap { name in
            guard let artElement = element.child(named: name) else { return nil }
            let placement = artElement.attribute(named: "placement").flatMap { Placement(rawValue: $0) }
            return ArticulationMark(type: name, placement: placement)
        }
    }

    private func mapDynamics(from element: XMLElement) -> [DynamicMark] {
        let dynamicNames = [
            "p", "pp", "ppp", "pppp", "ppppp", "pppppp",
            "f", "ff", "fff", "ffff", "fffff", "ffffff",
            "mp", "mf", "sf", "sfp", "sfpp", "fp",
            "rf", "rfz", "sfz", "sffz", "fz", "n", "pf", "sfzp"
        ]

        return dynamicNames.compactMap { name in
            guard element.child(named: name) != nil else { return nil }
            return DynamicMark(type: name)
        }
    }

    private func mapOrnaments(from element: XMLElement) -> [Ornament] {
        let ornamentNames = [
            "trill-mark", "turn", "delayed-turn", "inverted-turn",
            "delayed-inverted-turn", "vertical-turn", "shake", "mordent",
            "inverted-mordent", "schleifer", "tremolo"
        ]

        return ornamentNames.compactMap { name in
            guard let ornElement = element.child(named: name) else { return nil }
            let placement = ornElement.attribute(named: "placement").flatMap { Placement(rawValue: $0) }
            return Ornament(type: name, placement: placement)
        }
    }

    private func mapTechnical(from element: XMLElement) -> [TechnicalMark] {
        let technicalNames = [
            "up-bow", "down-bow", "harmonic", "open-string", "stopped",
            "snap-pizzicato", "fingering", "string", "fret", "hammer-on",
            "pull-off", "bend", "tap", "heel", "toe"
        ]

        return technicalNames.compactMap { name in
            guard element.child(named: name) != nil else { return nil }
            return TechnicalMark(type: name)
        }
    }
}

// MARK: - DurationBase Extension

extension DurationBase {
    init?(musicXMLName: String) {
        switch musicXMLName {
        case "maxima": self = .maxima
        case "long": self = .longa
        case "breve": self = .breve
        case "whole": self = .whole
        case "half": self = .half
        case "quarter": self = .quarter
        case "eighth": self = .eighth
        case "16th": self = .sixteenth
        case "32nd": self = .thirtySecond
        case "64th": self = .sixtyFourth
        case "128th": self = .oneHundredTwentyEighth
        case "256th": self = .twoHundredFiftySixth
        default: return nil
        }
    }
}
