import Foundation
import MusicNotationCore

/// The primary interface for parsing MusicXML files into `Score` objects.
///
/// `MusicXMLImporter` handles all MusicXML file formats:
/// - Uncompressed partwise format (`.musicxml`)
/// - Uncompressed timewise format (`.musicxml`)
/// - Compressed archives (`.mxl`)
///
/// The importer automatically detects the file format and handles decompression
/// when necessary.
///
/// ## Basic Usage
///
/// ```swift
/// let importer = MusicXMLImporter()
///
/// // Import from a file URL
/// let score = try importer.importScore(from: musicXMLURL)
///
/// // Or import from Data
/// let score = try importer.importScore(from: musicXMLData)
/// ```
///
/// ## Handling Warnings
///
/// The importer collects non-fatal warnings during parsing. Check these after
/// import to identify potential issues:
///
/// ```swift
/// let score = try importer.importScore(from: url)
///
/// for warning in importer.warnings {
///     print("Warning: \(warning)")
/// }
/// ```
///
/// ## Error Handling
///
/// Import errors are thrown as `MusicXMLError`:
///
/// ```swift
/// do {
///     let score = try importer.importScore(from: url)
/// } catch let error as MusicXMLError {
///     switch error {
///     case .invalidFileFormat(let message):
///         print("Invalid format: \(message)")
///     case .unsupportedVersion(let version):
///         print("Unsupported MusicXML version: \(version)")
///     case .invalidXMLStructure(let message):
///         print("Invalid XML: \(message)")
///     default:
///         print("Import error: \(error)")
///     }
/// }
/// ```
///
/// ## Supported Features
///
/// The importer supports the following MusicXML elements:
///
/// - **Score structure**: Parts, measures, voices, staves
/// - **Notes**: Pitched notes, rests, unpitched percussion, chords, grace notes
/// - **Durations**: All standard note values, dots, tuplets
/// - **Attributes**: Clefs, key signatures, time signatures, divisions
/// - **Notations**: Ties, slurs, beams, articulations, dynamics, ornaments, fermatas
/// - **Directions**: Dynamics, wedges (crescendo/diminuendo), tempo markings,
///   rehearsal marks, pedal, octave shifts
/// - **Barlines**: All bar styles, repeats, endings (1st/2nd)
/// - **Percussion**: Unpitched notes with instrument mapping
/// - **Metadata**: Work/movement titles, composer, credits
/// - **Layout hints**: System breaks, page breaks
///
/// ## Thread Safety
///
/// `MusicXMLImporter` is not thread-safe. Create separate instances for
/// concurrent imports, or synchronize access externally.
public final class MusicXMLImporter {
    /// Format detector for identifying MusicXML file types.
    private let formatDetector = FormatDetector()

    /// Version detector for checking MusicXML version compatibility.
    private let versionDetector = VersionDetector()

    /// Container reader for extracting content from compressed `.mxl` files.
    private let containerReader = MXLContainerReader()

    /// Mapper for converting MusicXML note elements to `Note` objects.
    private let noteMapper = NoteMapper()

    /// Mapper for converting MusicXML attributes to `MeasureAttributes` objects.
    private let attributesMapper = AttributesMapper()

    /// Configuration options that control import behavior.
    ///
    /// Modify these options before calling `importScore(from:)` to customize
    /// the import process. See ``ImportOptions`` for available settings.
    public var options: ImportOptions

    /// Non-fatal warnings collected during the most recent import.
    ///
    /// This array is cleared at the start of each import and populated with
    /// any warnings encountered during parsing. Check this after import to
    /// identify potential issues that didn't prevent the import from completing.
    ///
    /// Common warnings include:
    /// - Missing optional elements
    /// - Unrecognized element types (gracefully ignored)
    /// - Invalid attribute values that were substituted with defaults
    public private(set) var warnings: [MusicXMLWarning] = []

    /// Creates a new MusicXML importer with the specified options.
    ///
    /// - Parameter options: Configuration options for the import process.
    ///   Defaults to ``ImportOptions/default``.
    public init(options: ImportOptions = .default) {
        self.options = options
    }

    // MARK: - Public Import Methods

    /// Imports a MusicXML file from a URL.
    ///
    /// This method automatically detects the file format based on the file content,
    /// supporting uncompressed `.musicxml` files and compressed `.mxl` archives.
    ///
    /// After import, check the ``warnings`` property for any non-fatal issues
    /// encountered during parsing.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let importer = MusicXMLImporter()
    ///
    /// do {
    ///     let score = try importer.importScore(from: fileURL)
    ///     print("Imported '\(score.metadata.workTitle ?? "Untitled")'")
    ///     print("Parts: \(score.parts.count)")
    ///     print("Measures: \(score.measureCount)")
    /// } catch {
    ///     print("Import failed: \(error)")
    /// }
    /// ```
    ///
    /// - Parameter url: The file URL of the MusicXML file to import.
    ///   Can be `.musicxml`, `.mxl`, or `.xml`.
    ///
    /// - Returns: A `Score` object containing the parsed music notation.
    ///
    /// - Throws: `MusicXMLError` if the file cannot be read or contains invalid
    ///   MusicXML content. Specific error cases include:
    ///   - ``MusicXMLError/invalidFileFormat(_:)`` if the format cannot be detected
    ///   - ``MusicXMLError/unsupportedVersion(_:)`` if strict version checking is
    ///     enabled and the version is unsupported
    ///   - ``MusicXMLError/invalidXMLStructure(_:)`` if the XML structure is invalid
    public func importScore(from url: URL) throws -> Score {
        let format = try formatDetector.detectFormat(at: url)

        let xmlData: Data
        switch format {
        case .compressed:
            xmlData = try containerReader.extractMainDocument(from: url)
        case .partwise, .timewise:
            xmlData = try Data(contentsOf: url)
        case .unknown:
            throw MusicXMLError.invalidFileFormat("Unable to detect MusicXML format")
        }

        return try importScore(from: xmlData, format: format == .timewise ? .timewise : .partwise)
    }

    /// Imports a MusicXML file from in-memory data.
    ///
    /// This method automatically detects whether the data contains a compressed
    /// `.mxl` archive or uncompressed MusicXML content.
    ///
    /// Use this method when you already have the file content in memory, such as
    /// when downloading from a network or reading from a custom data source.
    ///
    /// ## Example
    ///
    /// ```swift
    /// // Download MusicXML from a server
    /// let (data, _) = try await URLSession.shared.data(from: serverURL)
    ///
    /// let importer = MusicXMLImporter()
    /// let score = try importer.importScore(from: data)
    /// ```
    ///
    /// - Parameter data: The raw MusicXML file content. Can be either compressed
    ///   `.mxl` format (ZIP archive) or uncompressed XML.
    ///
    /// - Returns: A `Score` object containing the parsed music notation.
    ///
    /// - Throws: `MusicXMLError` if the data contains invalid MusicXML content.
    public func importScore(from data: Data) throws -> Score {
        let format = formatDetector.detectFormat(from: data)

        let xmlData: Data
        switch format {
        case .compressed:
            xmlData = try containerReader.extractMainDocument(from: data)
        case .partwise, .timewise:
            xmlData = data
        case .unknown:
            throw MusicXMLError.invalidFileFormat("Unable to detect MusicXML format")
        }

        return try importScore(from: xmlData, format: format == .timewise ? .timewise : .partwise)
    }

    // MARK: - Internal Parsing

    private func importScore(from xmlData: Data, format: MusicXMLFormat) throws -> Score {
        // Check version
        if let version = versionDetector.detectVersion(from: xmlData) {
            if !versionDetector.isSupported(version: version) && options.strictVersionCheck {
                throw MusicXMLError.unsupportedVersion(version)
            }
        }

        // Parse XML tree
        let builder = XMLTreeBuilder()
        let root = try builder.parse(data: xmlData)

        // Create parsing context
        let context = XMLParserContext()

        // Parse based on format
        let score: Score
        if root.name == "score-partwise" {
            score = try parsePartwise(root: root, context: context)
        } else if root.name == "score-timewise" {
            score = try parseTimewise(root: root, context: context)
        } else {
            throw MusicXMLError.invalidXMLStructure("Root element must be score-partwise or score-timewise")
        }

        // Collect warnings
        warnings = context.warnings

        return score
    }

    // MARK: - Partwise Parsing

    private func parsePartwise(root: XMLElement, context: XMLParserContext) throws -> Score {
        // Parse header elements
        let metadata = parseMetadata(from: root)
        let defaults = parseDefaults(from: root)
        let credits = parseCredits(from: root)

        // Parse part-list
        let partList = root.child(named: "part-list")
        parsePartList(from: partList, context: context)

        // Parse parts
        var parts: [Part] = []
        for partElement in root.children(named: "part") {
            guard let partId = partElement.attribute(named: "id") else {
                context.addWarning("Part element missing id attribute")
                continue
            }

            context.currentPartId = partId
            context.resetForNewPart()

            let part = try parsePart(from: partElement, partId: partId, context: context)
            parts.append(part)
        }

        return Score(
            metadata: metadata,
            parts: parts,
            defaults: defaults,
            credits: credits
        )
    }

    // MARK: - Timewise Parsing

    private func parseTimewise(root: XMLElement, context: XMLParserContext) throws -> Score {
        // Parse header elements
        let metadata = parseMetadata(from: root)
        let defaults = parseDefaults(from: root)
        let credits = parseCredits(from: root)

        // Parse part-list
        let partList = root.child(named: "part-list")
        parsePartList(from: partList, context: context)

        // Get part IDs in order
        let partIds = context.partNames.keys.sorted()

        // Initialize parts
        var partMeasures: [String: [Measure]] = [:]
        for partId in partIds {
            partMeasures[partId] = []
        }

        // Parse measures (each contains parts)
        for measureElement in root.children(named: "measure") {
            let measureNumber = measureElement.attribute(named: "number") ?? "1"

            for partElement in measureElement.children(named: "part") {
                guard let partId = partElement.attribute(named: "id") else { continue }

                context.currentPartId = partId
                context.currentMeasureNumber = measureNumber

                let measure = try parseMeasure(from: measureElement, partElement: partElement, context: context)
                partMeasures[partId, default: []].append(measure)
            }
        }

        // Build parts
        let parts = partIds.map { partId -> Part in
            Part(
                id: partId,
                name: context.partNames[partId] ?? partId,
                abbreviation: context.partAbbreviations[partId],
                staffCount: context.partStaffCounts[partId] ?? 1,
                measures: partMeasures[partId] ?? [],
                instruments: context.partInstruments[partId] ?? [],
                midiInstruments: context.partMidiInstruments[partId] ?? []
            )
        }

        return Score(
            metadata: metadata,
            parts: parts,
            defaults: defaults,
            credits: credits
        )
    }

    // MARK: - Part Parsing

    private func parsePart(from element: XMLElement, partId: String, context: XMLParserContext) throws -> Part {
        var measures: [Measure] = []

        for measureElement in element.children(named: "measure") {
            context.currentMeasureNumber = measureElement.attribute(named: "number")
            context.resetForNewMeasure()

            let measure = try parseMeasure(from: measureElement, partElement: nil, context: context)
            measures.append(measure)
        }

        return Part(
            id: partId,
            name: context.partNames[partId] ?? partId,
            abbreviation: context.partAbbreviations[partId],
            staffCount: context.partStaffCounts[partId] ?? 1,
            measures: measures,
            instruments: context.partInstruments[partId] ?? [],
            midiInstruments: context.partMidiInstruments[partId] ?? []
        )
    }

    // MARK: - Measure Parsing

    private func parseMeasure(from measureElement: XMLElement, partElement: XMLElement?, context: XMLParserContext) throws -> Measure {
        let measureNumber = measureElement.attribute(named: "number") ?? context.currentMeasureNumber ?? "1"
        let isImplicit = measureElement.attribute(named: "implicit") == "yes"
        let width = measureElement.attribute(named: "width").flatMap(Double.init)

        // Use partElement if provided (timewise), otherwise use measureElement children (partwise)
        let contentElement = partElement ?? measureElement

        var elements: [MeasureElement] = []

        for child in contentElement.children {
            switch child.name {
            case "note":
                let note = try noteMapper.mapNote(from: child, context: context)
                elements.append(.note(note))

            case "attributes":
                let attrs = try attributesMapper.mapAttributes(from: child, context: context)
                if !attrs.isEmpty {
                    elements.append(.attributes(attrs))
                }

            case "direction":
                if let direction = parseDirection(from: child, context: context) {
                    elements.append(.direction(direction))
                }

            case "barline":
                if let barline = parseBarline(from: child) {
                    elements.append(.barline(barline))
                }

            case "forward":
                if let durationStr = child.child(named: "duration")?.textContent,
                   let duration = Int(durationStr) {
                    let voice = child.child(named: "voice")?.textContent.flatMap(Int.init)
                    let staff = child.child(named: "staff")?.textContent.flatMap(Int.init)
                    elements.append(.forward(Forward(duration: duration, voice: voice, staff: staff)))
                }

            case "backup":
                if let durationStr = child.child(named: "duration")?.textContent,
                   let duration = Int(durationStr) {
                    elements.append(.backup(Backup(duration: duration)))
                }

            case "print":
                if let printAttrs = parsePrint(from: child) {
                    elements.append(.print(printAttrs))
                }

            case "harmony":
                // TODO: Parse harmony/chord symbols
                break

            default:
                break
            }
        }

        return Measure(
            number: measureNumber,
            implicit: isImplicit,
            width: width,
            elements: elements
        )
    }

    // MARK: - Direction Parsing

    private func parseDirection(from element: XMLElement, context: XMLParserContext) -> Direction? {
        var types: [DirectionType] = []

        for directionType in element.children(named: "direction-type") {
            if let rehearsal = directionType.child(named: "rehearsal") {
                let text = rehearsal.textContent ?? ""
                let enclosure = rehearsal.attribute(named: "enclosure").flatMap { Enclosure(rawValue: $0) }
                types.append(.rehearsal(Rehearsal(text: text, enclosure: enclosure)))
            }

            if directionType.child(named: "segno") != nil {
                types.append(.segno(Segno()))
            }

            if directionType.child(named: "coda") != nil {
                types.append(.coda(Coda()))
            }

            if let words = directionType.child(named: "words") {
                let text = words.textContent ?? ""
                types.append(.words(Words(text: text)))
            }

            if let wedge = directionType.child(named: "wedge") {
                if let typeStr = wedge.attribute(named: "type"),
                   let wedgeType = WedgeType(rawValue: typeStr) {
                    let number = wedge.attribute(named: "number").flatMap(Int.init) ?? 1
                    let spread = wedge.attribute(named: "spread").flatMap(Double.init)
                    let niente = wedge.attribute(named: "niente") == "yes"
                    types.append(.wedge(Wedge(type: wedgeType, number: number, spread: spread, niente: niente)))
                }
            }

            if let dynamics = directionType.child(named: "dynamics") {
                var values: [DynamicValue] = []
                for child in dynamics.children {
                    if let value = DynamicValue(rawValue: child.name) {
                        values.append(value)
                    }
                }
                if !values.isEmpty {
                    types.append(.dynamics(DynamicsDirection(values: values)))
                }
            }

            if let metronome = directionType.child(named: "metronome") {
                if let beatUnitStr = metronome.child(named: "beat-unit")?.textContent,
                   let beatUnit = DurationBase(musicXMLName: beatUnitStr) {
                    let dots = metronome.children(named: "beat-unit-dot").count
                    let perMinute = metronome.child(named: "per-minute")?.textContent
                    let parentheses = metronome.attribute(named: "parentheses") == "yes"
                    types.append(.metronome(Metronome(beatUnit: beatUnit, beatUnitDots: dots, perMinute: perMinute, parentheses: parentheses)))
                }
            }

            if let octaveShift = directionType.child(named: "octave-shift") {
                if let typeStr = octaveShift.attribute(named: "type"),
                   let shiftType = OctaveShiftType(rawValue: typeStr) {
                    let number = octaveShift.attribute(named: "number").flatMap(Int.init) ?? 1
                    let size = octaveShift.attribute(named: "size").flatMap(Int.init) ?? 8
                    types.append(.octaveShift(OctaveShift(type: shiftType, number: number, size: size)))
                }
            }

            if let pedal = directionType.child(named: "pedal") {
                if let typeStr = pedal.attribute(named: "type"),
                   let pedalType = PedalType(rawValue: typeStr) {
                    let line = pedal.attribute(named: "line") == "yes"
                    let sign = pedal.attribute(named: "sign") == "yes"
                    types.append(.pedal(Pedal(type: pedalType, line: line, sign: sign)))
                }
            }

            // Percussion direction
            for percussionElement in directionType.children(named: "percussion") {
                let percType = parsePercussionType(from: percussionElement)
                let text = percussionElement.textContent?.trimmingCharacters(in: .whitespacesAndNewlines)
                let displayText = text?.isEmpty == false ? text : nil
                types.append(.percussion(PercussionDirection(type: percType, text: displayText)))
            }
        }

        guard !types.isEmpty else { return nil }

        let placement = element.attribute(named: "placement").flatMap { Placement(rawValue: $0) }
        let directive = element.attribute(named: "directive") == "yes"
        let voice = element.child(named: "voice")?.textContent.flatMap(Int.init)
        let staff = element.child(named: "staff")?.textContent.flatMap(Int.init) ?? 1
        let offset = element.child(named: "offset")?.textContent.flatMap(Int.init)

        return Direction(
            placement: placement,
            directive: directive,
            voice: voice,
            staff: staff,
            types: types,
            offset: offset
        )
    }

    // MARK: - Percussion Direction Parsing

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

    // MARK: - Barline Parsing

    private func parseBarline(from element: XMLElement) -> Barline? {
        let location = element.attribute(named: "location") ?? "right"

        var barStyle = BarStyle.regular
        if let barStyleStr = element.child(named: "bar-style")?.textContent {
            barStyle = BarStyle(rawValue: barStyleStr) ?? .regular
        }

        var repeatDirection: RepeatDirection?
        if let repeatElement = element.child(named: "repeat") {
            if let dirStr = repeatElement.attribute(named: "direction") {
                repeatDirection = RepeatDirection(rawValue: dirStr)
            }
        }

        var ending: Ending?
        if let endingElement = element.child(named: "ending") {
            let number = endingElement.attribute(named: "number") ?? "1"
            let typeStr = endingElement.attribute(named: "type") ?? "start"
            let text = endingElement.textContent
            if let endingType = EndingType(rawValue: typeStr) {
                ending = Ending(number: number, type: endingType, text: text)
            }
        }

        return Barline(
            location: BarlineLocation(rawValue: location) ?? .right,
            barStyle: barStyle,
            repeatDirection: repeatDirection,
            ending: ending
        )
    }

    // MARK: - Print Parsing

    private func parsePrint(from element: XMLElement) -> PrintAttributes? {
        let newSystem = element.attribute(named: "new-system") == "yes"
        let newPage = element.attribute(named: "new-page") == "yes"
        let blankPage = element.attribute(named: "blank-page").flatMap(Int.init)
        let pageNumber = element.attribute(named: "page-number")
        let staffSpacing = element.child(named: "staff-layout")?.child(named: "staff-distance")?.textContent.flatMap(Double.init)

        return PrintAttributes(
            newSystem: newSystem,
            newPage: newPage,
            blankPage: blankPage,
            pageNumber: pageNumber,
            staffSpacing: staffSpacing
        )
    }

    // MARK: - Header Parsing

    private func parseMetadata(from root: XMLElement) -> ScoreMetadata {
        var metadata = ScoreMetadata()

        if let work = root.child(named: "work") {
            metadata.workTitle = work.child(named: "work-title")?.textContent
            metadata.workNumber = work.child(named: "work-number")?.textContent
        }

        metadata.movementTitle = root.child(named: "movement-title")?.textContent
        metadata.movementNumber = root.child(named: "movement-number")?.textContent

        if let identification = root.child(named: "identification") {
            for creator in identification.children(named: "creator") {
                let type = creator.attribute(named: "type")
                let name = creator.textContent ?? ""
                metadata.creators.append(Creator(type: type, name: name))
            }

            let rightsElements = identification.children(named: "rights")
            metadata.rights = rightsElements.compactMap { $0.textContent }

            if let encoding = identification.child(named: "encoding") {
                var encodingInfo = EncodingInfo()
                if let software = encoding.child(named: "software")?.textContent {
                    encodingInfo.software = [software]
                }
                encodingInfo.encodingDate = encoding.child(named: "encoding-date")?.textContent
                encodingInfo.encoder = encoding.child(named: "encoder")?.textContent
                metadata.encoding = encodingInfo
            }
        }

        return metadata
    }

    private func parseDefaults(from root: XMLElement) -> ScoreDefaults? {
        guard let defaults = root.child(named: "defaults") else { return nil }

        var scoreDefaults = ScoreDefaults()

        if let scaling = defaults.child(named: "scaling") {
            if let mmStr = scaling.child(named: "millimeters")?.textContent,
               let mm = Double(mmStr),
               let tenthsStr = scaling.child(named: "tenths")?.textContent,
               let tenths = Double(tenthsStr) {
                scoreDefaults.scaling = Scaling(millimeters: mm, tenths: tenths)
            }
        }

        if let pageLayout = defaults.child(named: "page-layout") {
            var settings = PageSettings()
            settings.pageHeight = pageLayout.child(named: "page-height")?.textContent.flatMap(Double.init)
            settings.pageWidth = pageLayout.child(named: "page-width")?.textContent.flatMap(Double.init)

            if let margins = pageLayout.child(named: "page-margins") {
                settings.leftMargin = margins.child(named: "left-margin")?.textContent.flatMap(Double.init)
                settings.rightMargin = margins.child(named: "right-margin")?.textContent.flatMap(Double.init)
                settings.topMargin = margins.child(named: "top-margin")?.textContent.flatMap(Double.init)
                settings.bottomMargin = margins.child(named: "bottom-margin")?.textContent.flatMap(Double.init)
            }

            scoreDefaults.pageSettings = settings
        }

        return scoreDefaults
    }

    private func parseCredits(from root: XMLElement) -> [Credit] {
        var credits: [Credit] = []

        for creditElement in root.children(named: "credit") {
            let page = creditElement.attribute(named: "page").flatMap(Int.init)
            let creditType = creditElement.child(named: "credit-type")?.textContent

            var creditWords: [CreditWords] = []
            for wordsElement in creditElement.children(named: "credit-words") {
                let text = wordsElement.textContent ?? ""
                let defaultX = wordsElement.attribute(named: "default-x").flatMap(Double.init)
                let defaultY = wordsElement.attribute(named: "default-y").flatMap(Double.init)
                let justify = wordsElement.attribute(named: "justify").flatMap { Justification(rawValue: $0) }

                creditWords.append(CreditWords(
                    text: text,
                    defaultX: defaultX,
                    defaultY: defaultY,
                    justify: justify
                ))
            }

            credits.append(Credit(page: page, creditType: creditType, creditWords: creditWords))
        }

        return credits
    }

    private func parsePartList(from element: XMLElement?, context: XMLParserContext) {
        guard let partList = element else { return }

        for scorePart in partList.children(named: "score-part") {
            guard let id = scorePart.attribute(named: "id") else { continue }

            if let partName = scorePart.child(named: "part-name")?.textContent {
                context.partNames[id] = partName
            }

            if let partAbbr = scorePart.child(named: "part-abbreviation")?.textContent {
                context.partAbbreviations[id] = partAbbr
            }

            // Parse score-instrument elements
            var instruments: [Instrument] = []
            for scoreInstrument in scorePart.children(named: "score-instrument") {
                if let instrument = parseScoreInstrument(from: scoreInstrument) {
                    instruments.append(instrument)
                }
            }
            if !instruments.isEmpty {
                context.partInstruments[id] = instruments
            }

            // Parse midi-instrument elements
            var midiInstruments: [MIDIInstrument] = []
            for midiInstrument in scorePart.children(named: "midi-instrument") {
                if let midi = parseMidiInstrument(from: midiInstrument) {
                    midiInstruments.append(midi)
                }
            }
            if !midiInstruments.isEmpty {
                context.partMidiInstruments[id] = midiInstruments
            }
        }
    }

    private func parseScoreInstrument(from element: XMLElement) -> Instrument? {
        guard let id = element.attribute(named: "id") else { return nil }

        let name = element.child(named: "instrument-name")?.textContent ?? id
        let abbreviation = element.child(named: "instrument-abbreviation")?.textContent
        let sound = element.child(named: "instrument-sound")?.textContent

        // Check for solo/ensemble
        let solo = element.child(named: "solo") != nil
        let ensemble = element.child(named: "ensemble") != nil

        return Instrument(
            id: id,
            name: name,
            abbreviation: abbreviation,
            sound: sound,
            solo: solo,
            ensemble: ensemble
        )
    }

    private func parseMidiInstrument(from element: XMLElement) -> MIDIInstrument? {
        let instrumentId = element.attribute(named: "id")

        let midiChannel = element.child(named: "midi-channel")?.textContent.flatMap(Int.init)
        let midiProgram = element.child(named: "midi-program")?.textContent.flatMap(Int.init)
        let midiBank = element.child(named: "midi-bank")?.textContent.flatMap(Int.init)
        let volume = element.child(named: "volume")?.textContent.flatMap(Double.init)
        let pan = element.child(named: "pan")?.textContent.flatMap(Double.init)

        // Also check for midi-unpitched (for percussion)
        // This is the MIDI note number for unpitched percussion
        // We don't store this in MIDIInstrument currently, but it could be extended

        return MIDIInstrument(
            instrumentId: instrumentId,
            midiChannel: midiChannel,
            midiProgram: midiProgram,
            midiBank: midiBank,
            volume: volume,
            pan: pan
        )
    }
}

// MARK: - Import Options

/// Configuration options that control MusicXML import behavior.
///
/// Use `ImportOptions` to customize how `MusicXMLImporter` handles various
/// aspects of the import process.
///
/// ## Example
///
/// ```swift
/// var options = ImportOptions.default
///
/// // Reject files with unsupported MusicXML versions
/// options.strictVersionCheck = true
///
/// // Preserve original data for round-trip export
/// options.preserveOriginalContext = true
///
/// let importer = MusicXMLImporter(options: options)
/// ```
public struct ImportOptions: Sendable {
    /// Controls whether the importer rejects unsupported MusicXML versions.
    ///
    /// When `true`, importing a file with an unsupported MusicXML version throws
    /// ``MusicXMLError/unsupportedVersion(_:)``. When `false` (the default),
    /// the importer attempts to parse the file regardless of version.
    ///
    /// Most MusicXML files are backwards-compatible, so leaving this `false`
    /// usually works well. Set to `true` if you need strict compliance.
    public var strictVersionCheck: Bool

    /// Controls whether the importer preserves original XML context.
    ///
    /// When `true`, the importer stores additional context from the original
    /// XML that helps preserve fidelity during round-trip export. This includes
    /// element ordering, optional attributes, and formatting hints.
    ///
    /// Enable this when you plan to re-export the score and want to maintain
    /// as much of the original structure as possible. This uses slightly more
    /// memory but improves export quality.
    public var preserveOriginalContext: Bool

    /// The default import options.
    ///
    /// Default values:
    /// - `strictVersionCheck`: `false`
    /// - `preserveOriginalContext`: `false`
    public static let `default` = ImportOptions(
        strictVersionCheck: false,
        preserveOriginalContext: false
    )

    /// Creates import options with the specified settings.
    ///
    /// - Parameters:
    ///   - strictVersionCheck: Whether to reject unsupported MusicXML versions.
    ///     Defaults to `false`.
    ///   - preserveOriginalContext: Whether to preserve original XML context
    ///     for round-trip export. Defaults to `false`.
    public init(strictVersionCheck: Bool = false, preserveOriginalContext: Bool = false) {
        self.strictVersionCheck = strictVersionCheck
        self.preserveOriginalContext = preserveOriginalContext
    }
}

// MARK: - Extensions to Core Types

extension NoteheadType {
    init?(musicXMLName: String) {
        switch musicXMLName {
        case "normal": self = .normal
        case "diamond": self = .diamond
        case "triangle": self = .triangle
        case "slash": self = .slash
        case "cross", "x": self = .cross
        case "circle-x": self = .circleX
        case "square": self = .square
        default: return nil
        }
    }
}

extension ClefSign {
    var defaultLine: Int {
        switch self {
        case .g: return 2
        case .f: return 4
        case .c: return 3
        case .percussion: return 3
        case .tab: return 5
        case .none: return 1
        }
    }
}
