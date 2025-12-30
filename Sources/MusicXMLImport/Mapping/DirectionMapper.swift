import Foundation
import MusicNotationCore

/// Maps MusicXML `<direction>` elements to ``Direction`` model objects.
///
/// `DirectionMapper` handles the parsing of musical directions—annotations that appear above
/// or below the staff and don't directly attach to notes. These include dynamics, tempo
/// indications, wedges (hairpins), pedal marks, and various text directions.
///
/// ## Responsibilities
///
/// - **Dynamics**: Parses dynamic markings (`p`, `f`, `mp`, `sfz`, etc.)
/// - **Wedges**: Handles crescendo/diminuendo hairpin start/stop/continue
/// - **Metronome Marks**: Extracts tempo indications with beat unit and BPM
/// - **Text Directions**: Parses `<words>` elements with font specifications
/// - **Rehearsal Marks**: Handles boxed/circled rehearsal letters or numbers
/// - **Pedal Marks**: Parses piano pedal start/change/stop
/// - **Octave Shifts**: Handles 8va/8vb/15ma lines
/// - **Sound Elements**: Extracts MIDI tempo/dynamics and navigation (D.C., D.S., coda)
///
/// ## Direction Types
///
/// MusicXML directions can contain multiple `<direction-type>` children, each with
/// different content. The mapper iterates all types and returns them in a single
/// ``Direction`` object with its ``Direction/types`` array.
///
/// ## Placement
///
/// Directions have a `placement` attribute indicating whether they appear above or
/// below the staff. This is preserved in the output model for correct rendering.
///
/// ```swift
/// let mapper = DirectionMapper()
/// let direction = try mapper.mapDirection(from: element, context: context)
/// // direction.types contains all parsed direction types
/// // direction.placement indicates above/below positioning
/// ```
///
/// - SeeAlso: ``MusicXMLImporter`` for the main import entry point
/// - SeeAlso: ``Direction`` for the output model
/// - SeeAlso: ``DirectionType`` for the enumeration of direction content types
public struct DirectionMapper {
    public init() {}

    /// Maps a `<direction>` XML element to a ``Direction`` model.
    ///
    /// Parses all direction-type children, placement, staff/voice assignment, offset,
    /// and optional sound element for MIDI playback data.
    ///
    /// - Parameters:
    ///   - element: The `<direction>` XML element to parse
    ///   - context: The parser context (used for state tracking)
    /// - Returns: A ``Direction`` instance with all parsed direction types
    /// - Throws: ``MusicXMLError`` if direction types contain invalid data
    public func mapDirection(
        from element: XMLElement,
        context: XMLParserContext
    ) throws -> Direction {
        // Parse placement attribute
        let placementStr = element.attribute(named: "placement")
        let placement = placementStr.flatMap { Placement(rawValue: $0) }

        // Parse directive attribute
        let directive = element.attribute(named: "directive") == "yes"

        // Parse staff number
        let staff = element.child(named: "staff")?.textContent.flatMap(Int.init) ?? 1

        // Parse voice
        let voice = element.child(named: "voice")?.textContent.flatMap(Int.init)

        // Parse offset
        let offset = element.child(named: "offset")?.textContent.flatMap(Int.init)

        // Parse direction-type elements
        var types: [DirectionType] = []
        for directionTypeElement in element.children(named: "direction-type") {
            let directionTypes = try mapDirectionTypes(from: directionTypeElement, context: context)
            types.append(contentsOf: directionTypes)
        }

        // Parse sound element
        var sound: Sound?
        if let soundElement = element.child(named: "sound") {
            sound = mapSound(from: soundElement)
        }

        return Direction(
            placement: placement,
            directive: directive,
            voice: voice,
            staff: staff,
            types: types,
            offset: offset,
            sound: sound
        )
    }

    // MARK: - Direction Types

    private func mapDirectionTypes(
        from element: XMLElement,
        context: XMLParserContext
    ) throws -> [DirectionType] {
        var types: [DirectionType] = []

        // Rehearsal marks
        for rehearsalElement in element.children(named: "rehearsal") {
            let rehearsal = mapRehearsal(from: rehearsalElement)
            types.append(.rehearsal(rehearsal))
        }

        // Segno
        for segnoElement in element.children(named: "segno") {
            let segno = mapSegno(from: segnoElement)
            types.append(.segno(segno))
        }

        // Coda
        for codaElement in element.children(named: "coda") {
            let coda = mapCoda(from: codaElement)
            types.append(.coda(coda))
        }

        // Words (text directions)
        for wordsElement in element.children(named: "words") {
            let words = mapWords(from: wordsElement)
            types.append(.words(words))
        }

        // Wedge (crescendo/diminuendo hairpin)
        for wedgeElement in element.children(named: "wedge") {
            let wedge = mapWedge(from: wedgeElement)
            types.append(.wedge(wedge))
        }

        // Dynamics
        for dynamicsElement in element.children(named: "dynamics") {
            let dynamics = mapDynamics(from: dynamicsElement)
            types.append(.dynamics(dynamics))
        }

        // Dashes
        for dashesElement in element.children(named: "dashes") {
            let dashes = mapDashes(from: dashesElement)
            types.append(.dashes(dashes))
        }

        // Bracket
        for bracketElement in element.children(named: "bracket") {
            let bracket = mapBracket(from: bracketElement)
            types.append(.bracket(bracket))
        }

        // Pedal
        for pedalElement in element.children(named: "pedal") {
            let pedal = mapPedal(from: pedalElement)
            types.append(.pedal(pedal))
        }

        // Metronome
        for metronomeElement in element.children(named: "metronome") {
            if let metronome = mapMetronome(from: metronomeElement) {
                types.append(.metronome(metronome))
            }
        }

        // Octave shift
        for octaveShiftElement in element.children(named: "octave-shift") {
            let octaveShift = mapOctaveShift(from: octaveShiftElement)
            types.append(.octaveShift(octaveShift))
        }

        // Harp pedals
        for harpPedalsElement in element.children(named: "harp-pedals") {
            let harpPedals = mapHarpPedals(from: harpPedalsElement)
            types.append(.harpPedals(harpPedals))
        }

        // Principal voice
        for principalVoiceElement in element.children(named: "principal-voice") {
            if let principalVoice = mapPrincipalVoice(from: principalVoiceElement) {
                types.append(.principalVoice(principalVoice))
            }
        }

        // Accordion registration
        for accordionElement in element.children(named: "accordion-registration") {
            let accordion = mapAccordionRegistration(from: accordionElement)
            types.append(.accordionRegistration(accordion))
        }

        // Percussion
        for percussionElement in element.children(named: "percussion") {
            let percussion = mapPercussion(from: percussionElement)
            types.append(.percussion(percussion))
        }

        // Other direction
        for otherElement in element.children(named: "other-direction") {
            let other = mapOtherDirection(from: otherElement)
            types.append(.otherDirection(other))
        }

        return types
    }

    // MARK: - Individual Type Mappers

    private func mapRehearsal(from element: XMLElement) -> Rehearsal {
        let text = element.textContent ?? ""
        let enclosureStr = element.attribute(named: "enclosure")
        let enclosure = enclosureStr.flatMap { Enclosure(rawValue: $0) } ?? .rectangle
        return Rehearsal(text: text, enclosure: enclosure)
    }

    private func mapSegno(from element: XMLElement) -> Segno {
        let id = element.attribute(named: "id")
        return Segno(id: id)
    }

    private func mapCoda(from element: XMLElement) -> Coda {
        let id = element.attribute(named: "id")
        return Coda(id: id)
    }

    private func mapWords(from element: XMLElement) -> Words {
        let text = element.textContent ?? ""

        // Parse font specification
        var font: FontSpecification?
        let fontFamily = element.attribute(named: "font-family")
        let fontSizeStr = element.attribute(named: "font-size")
        let fontSize = fontSizeStr.flatMap(Double.init)
        let fontStyle = element.attribute(named: "font-style")
        let fontWeight = element.attribute(named: "font-weight")

        if fontFamily != nil || fontSize != nil || fontStyle != nil || fontWeight != nil {
            let families: [String] = fontFamily.map { [$0] } ?? []
            font = FontSpecification(
                fontFamily: families,
                fontStyle: fontStyle.flatMap { FontStyle(rawValue: $0) },
                fontSize: fontSize,
                fontWeight: fontWeight.flatMap { FontWeight(rawValue: $0) }
            )
        }

        // Parse justification
        let justifyStr = element.attribute(named: "justify")
        let justify = justifyStr.flatMap { Justification(rawValue: $0) }

        return Words(text: text, font: font, justify: justify)
    }

    private func mapWedge(from element: XMLElement) -> Wedge {
        let typeStr = element.attribute(named: "type") ?? "crescendo"
        let type = WedgeType(rawValue: typeStr) ?? .crescendo
        let number = element.attribute(named: "number").flatMap(Int.init) ?? 1
        let spread = element.attribute(named: "spread").flatMap(Double.init)
        let niente = element.attribute(named: "niente") == "yes"

        return Wedge(type: type, number: number, spread: spread, niente: niente)
    }

    private func mapDynamics(from element: XMLElement) -> DynamicsDirection {
        var values: [DynamicValue] = []

        // Check for each dynamic type element
        let dynamicTypes = ["p", "pp", "ppp", "pppp", "ppppp", "pppppp",
                           "f", "ff", "fff", "ffff", "fffff", "ffffff",
                           "mp", "mf", "sf", "sfp", "sfpp", "fp",
                           "rf", "rfz", "sfz", "sffz", "fz", "n", "pf", "sfzp"]

        for dynType in dynamicTypes {
            if element.child(named: dynType) != nil {
                if let value = DynamicValue(rawValue: dynType) {
                    values.append(value)
                }
            }
        }

        return DynamicsDirection(values: values)
    }

    private func mapDashes(from element: XMLElement) -> Dashes {
        let typeStr = element.attribute(named: "type") ?? "start"
        let type = StartStopContinue(rawValue: typeStr) ?? .start
        let number = element.attribute(named: "number").flatMap(Int.init) ?? 1
        return Dashes(type: type, number: number)
    }

    private func mapBracket(from element: XMLElement) -> DirectionBracket {
        let typeStr = element.attribute(named: "type") ?? "start"
        let type = StartStopContinue(rawValue: typeStr) ?? .start
        let number = element.attribute(named: "number").flatMap(Int.init) ?? 1
        let lineEndStr = element.attribute(named: "line-end")
        let lineEnd = lineEndStr.flatMap { LineEnd(rawValue: $0) }
        return DirectionBracket(type: type, number: number, lineEnd: lineEnd)
    }

    private func mapPedal(from element: XMLElement) -> Pedal {
        let typeStr = element.attribute(named: "type") ?? "start"
        let type = PedalType(rawValue: typeStr) ?? .start
        let line = element.attribute(named: "line").map { $0 == "yes" }
        let sign = element.attribute(named: "sign").map { $0 == "yes" }
        return Pedal(type: type, line: line, sign: sign)
    }

    private func mapMetronome(from element: XMLElement) -> Metronome? {
        // MusicXML structure: beat-unit, beat-unit-dot*, (per-minute | (beat-unit, beat-unit-dot*))
        // We need to parse in order to correctly associate dots with their beat-units

        var beatUnit: DurationBase?
        var beatUnitDots = 0
        var beatUnit2: DurationBase?
        var beatUnit2Dots = 0
        var perMinute: String?
        var foundFirstBeatUnit = false

        for child in element.children {
            switch child.name {
            case "beat-unit":
                if let typeStr = child.textContent,
                   let duration = DurationBase(musicXMLTypeName: typeStr) {
                    if !foundFirstBeatUnit {
                        beatUnit = duration
                        foundFirstBeatUnit = true
                    } else {
                        beatUnit2 = duration
                    }
                }
            case "beat-unit-dot":
                // Dots apply to the most recently parsed beat-unit
                if beatUnit2 != nil {
                    beatUnit2Dots += 1
                } else if foundFirstBeatUnit {
                    beatUnitDots += 1
                }
            case "per-minute":
                perMinute = child.textContent
            default:
                break
            }
        }

        guard let beatUnit = beatUnit else {
            return nil
        }

        // Check for parentheses
        let parentheses = element.attribute(named: "parentheses") == "yes"

        return Metronome(
            beatUnit: beatUnit,
            beatUnitDots: beatUnitDots,
            perMinute: perMinute,
            beatUnit2: beatUnit2,
            beatUnit2Dots: beatUnit2Dots,
            parentheses: parentheses
        )
    }

    private func mapOctaveShift(from element: XMLElement) -> OctaveShift {
        let typeStr = element.attribute(named: "type") ?? "up"
        let type = OctaveShiftType(rawValue: typeStr) ?? .up
        let number = element.attribute(named: "number").flatMap(Int.init) ?? 1
        let size = element.attribute(named: "size").flatMap(Int.init) ?? 8
        return OctaveShift(type: type, number: number, size: size)
    }

    private func mapHarpPedals(from element: XMLElement) -> HarpPedals {
        var pedalTuning: [HarpPedalTuning] = []

        for tuningElement in element.children(named: "pedal-tuning") {
            if let stepStr = tuningElement.child(named: "pedal-step")?.textContent,
               let step = PitchStep(rawValue: stepStr.uppercased()),
               let alterStr = tuningElement.child(named: "pedal-alter")?.textContent,
               let alter = Double(alterStr) {
                pedalTuning.append(HarpPedalTuning(pedalStep: step, pedalAlter: alter))
            }
        }

        return HarpPedals(pedalTuning: pedalTuning)
    }

    private func mapPrincipalVoice(from element: XMLElement) -> PrincipalVoice? {
        let typeStr = element.attribute(named: "type") ?? "start"
        guard let type = StartStop(rawValue: typeStr) else { return nil }

        let symbolStr = element.attribute(named: "symbol")
        let symbol = symbolStr.flatMap { PrincipalVoiceSymbol(rawValue: $0) }

        return PrincipalVoice(type: type, symbol: symbol)
    }

    private func mapAccordionRegistration(from element: XMLElement) -> AccordionRegistration {
        let accordionHigh = element.child(named: "accordion-high") != nil
        let accordionMiddleStr = element.child(named: "accordion-middle")?.textContent
        let accordionMiddle = accordionMiddleStr.flatMap(Int.init)
        let accordionLow = element.child(named: "accordion-low") != nil

        return AccordionRegistration(
            accordionHigh: accordionHigh,
            accordionMiddle: accordionMiddle,
            accordionLow: accordionLow
        )
    }

    private func mapPercussion(from element: XMLElement) -> PercussionDirection {
        // Parse the percussion sub-elements
        let type = parsePercussionType(from: element)
        let text = element.textContent?.trimmingCharacters(in: .whitespacesAndNewlines)
        let displayText = text?.isEmpty == false ? text : nil
        return PercussionDirection(type: type, text: displayText)
    }

    private func parsePercussionType(from element: XMLElement) -> PercussionDirectionType {
        // Check for timpani
        if let timpaniElement = element.child(named: "timpani") {
            let tuning = parseTimpaniTuning(from: timpaniElement)
            return .timpani(tuning)
        }

        // Check for beater
        if let beaterElement = element.child(named: "beater") {
            if let beaterText = beaterElement.textContent,
               let beaterType = BeaterType(musicXMLValue: beaterText) {
                return .beater(beaterType)
            }
        }

        // Check for stick
        if let stickElement = element.child(named: "stick") {
            let spec = parseStickSpecification(from: stickElement)
            return .stick(spec)
        }

        // Check for stick-location
        if let stickLocationElement = element.child(named: "stick-location") {
            if let locationText = stickLocationElement.textContent,
               let location = StickLocation(rawValue: locationText.replacingOccurrences(of: "-", with: " ")) {
                return .stickLocation(location)
            }
        }

        // Check for membrane (drum) instruments
        if let membraneElement = element.child(named: "membrane") {
            if let membraneText = membraneElement.textContent,
               let membraneType = MembraneType(musicXMLValue: membraneText) {
                return .membrane(membraneType)
            }
        }

        // Check for metal instruments
        if let metalElement = element.child(named: "metal") {
            if let metalText = metalElement.textContent,
               let metalType = MetalType(musicXMLValue: metalText) {
                return .metal(metalType)
            }
        }

        // Check for wood instruments
        if let woodElement = element.child(named: "wood") {
            if let woodText = woodElement.textContent,
               let woodType = WoodType(musicXMLValue: woodText) {
                return .wood(woodType)
            }
        }

        // Check for pitched percussion
        if let pitchedElement = element.child(named: "pitched") {
            if let pitchedText = pitchedElement.textContent,
               let pitchedType = PitchedPercussionType(rawValue: pitchedText.replacingOccurrences(of: "-", with: " ")) {
                return .pitched(pitchedType)
            }
        }

        // Check for glass instruments
        if let glassElement = element.child(named: "glass") {
            if let glassText = glassElement.textContent,
               let glassType = GlassType(musicXMLValue: glassText) {
                return .glass(glassType)
            }
        }

        // Check for effect
        if let effectElement = element.child(named: "effect") {
            if let effectText = effectElement.textContent,
               let effectType = PercussionEffect(musicXMLValue: effectText) {
                return .effect(effectType)
            }
        }

        // Check for other-percussion
        if let otherElement = element.child(named: "other-percussion") {
            let text = otherElement.textContent ?? ""
            return .other(text)
        }

        // Fallback to text content
        let fallbackText = element.textContent ?? ""
        return .other(fallbackText)
    }

    private func parseTimpaniTuning(from element: XMLElement) -> TimpaniTuning? {
        // Check for tuning-step, tuning-alter, tuning-octave
        guard let stepElement = element.child(named: "tuning-step"),
              let stepText = stepElement.textContent,
              let step = PitchStep(rawValue: stepText.uppercased()) else {
            return nil
        }

        let alter = element.child(named: "tuning-alter")?.textContent.flatMap(Double.init)
        let octave = element.child(named: "tuning-octave")?.textContent.flatMap(Int.init)

        return TimpaniTuning(step: step, alter: alter, octave: octave)
    }

    private func parseStickSpecification(from element: XMLElement) -> StickSpecification {
        let materialText = element.child(named: "stick-material")?.textContent
        let material = materialText.flatMap { StickMaterial(rawValue: $0) }

        let typeText = element.child(named: "stick-type")?.textContent
        let type = typeText.flatMap { StickType(musicXMLValue: $0) }

        let tipText = element.attribute(named: "tip")
        let tip = tipText.flatMap { TipDirection(rawValue: $0) }

        return StickSpecification(material: material, type: type, tip: tip)
    }

    private func mapOtherDirection(from element: XMLElement) -> OtherDirection {
        let text = element.textContent ?? ""
        return OtherDirection(text: text)
    }

    // MARK: - Sound

    private func mapSound(from element: XMLElement) -> Sound {
        // Tempo
        let tempo: Double?
        if let tempoStr = element.attribute(named: "tempo") {
            tempo = Double(tempoStr)
        } else {
            tempo = nil
        }

        // Dynamics (velocity)
        let dynamics: Double?
        if let dynamicsStr = element.attribute(named: "dynamics") {
            dynamics = Double(dynamicsStr)
        } else {
            dynamics = nil
        }

        // Da capo/segno/coda navigation
        let dacapo = element.attribute(named: "dacapo") == "yes"
        let segno = element.attribute(named: "segno")
        let dalsegno = element.attribute(named: "dalsegno")
        let coda = element.attribute(named: "coda")
        let tocoda = element.attribute(named: "tocoda")
        let fine = element.attribute(named: "fine") != nil

        // Forward repeat
        let forwardRepeat = element.attribute(named: "forward-repeat") == "yes"

        return Sound(
            tempo: tempo,
            dynamics: dynamics,
            dacapo: dacapo,
            segno: segno,
            dalsegno: dalsegno,
            coda: coda,
            tocoda: tocoda,
            forwardRepeat: forwardRepeat,
            fine: fine
        )
    }
}
