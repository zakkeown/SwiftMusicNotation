// MusicXMLExport Module
// Exports Score models to MusicXML format

import Foundation
import MusicNotationCore

// MARK: - MusicXML Exporter

/// Serializes `Score` objects to MusicXML format.
///
/// `MusicXMLExporter` generates valid MusicXML from your score models,
/// supporting both file output and in-memory string/data generation.
///
/// ## Basic Usage
///
/// ```swift
/// let exporter = MusicXMLExporter()
///
/// // Export to a file
/// try exporter.export(score, to: outputURL)
///
/// // Export to a string
/// let xmlString = try exporter.exportToString(score)
///
/// // Export to Data
/// let xmlData = try exporter.export(score)
/// ```
///
/// ## Export Configuration
///
/// Customize the output with ``ExportConfiguration``:
///
/// ```swift
/// var config = ExportConfiguration()
/// config.musicXMLVersion = "4.0"
/// config.includeDoctype = true
/// config.addEncodingSignature = true
///
/// let exporter = MusicXMLExporter(config: config)
/// ```
///
/// ## Round-Trip Fidelity
///
/// For best round-trip fidelity when re-exporting imported files,
/// enable `preserveOriginalContext` during import:
///
/// ```swift
/// var importOptions = ImportOptions.default
/// importOptions.preserveOriginalContext = true
///
/// let importer = MusicXMLImporter(options: importOptions)
/// let score = try importer.importScore(from: url)
///
/// // Re-export preserves original structure
/// let exporter = MusicXMLExporter()
/// try exporter.export(score, to: outputURL)
/// ```
///
/// ## Output Format
///
/// The exporter generates partwise MusicXML (the most common format)
/// with the following structure:
///
/// - XML declaration and DOCTYPE
/// - Work and movement information
/// - Identification (creators, rights, encoding)
/// - Score defaults (scaling, page layout)
/// - Credits (title, composer, etc.)
/// - Part list
/// - Parts with measures
///
/// ## Supported Elements
///
/// The exporter supports all elements from ``MusicNotationCore``:
///
/// - **Notes**: Pitched, unpitched, rests with full duration support
/// - **Attributes**: Clefs, keys, time signatures, transposes
/// - **Notations**: Ties, slurs, tuplets, articulations, dynamics
/// - **Directions**: Dynamics, wedges, tempos, rehearsal marks
/// - **Barlines**: All styles, repeats, endings
/// - **Lyrics**: Text with syllabic information
/// - **Harmony**: Chord symbols
///
/// ## Thread Safety
///
/// `MusicXMLExporter` is not thread-safe. Create separate instances for
/// concurrent exports, or synchronize access externally.
public final class MusicXMLExporter {
    /// Configuration options that control export behavior.
    ///
    /// Modify these settings before calling export methods to customize
    /// the output. See ``ExportConfiguration`` for available options.
    public var config: ExportConfiguration

    /// Creates a new MusicXML exporter with the specified configuration.
    ///
    /// - Parameter config: Configuration options for the export process.
    ///   Defaults to standard settings with MusicXML 4.0 output.
    public init(config: ExportConfiguration = ExportConfiguration()) {
        self.config = config
    }

    // MARK: - Public Export Methods

    /// Exports a score to MusicXML data.
    ///
    /// This method generates a complete MusicXML document and returns it
    /// as `Data` using the encoding specified in ``config``.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let exporter = MusicXMLExporter()
    /// let xmlData = try exporter.export(score)
    ///
    /// // Use the data for network upload, etc.
    /// try await uploadData(xmlData)
    /// ```
    ///
    /// - Parameter score: The score to export.
    ///
    /// - Returns: The MusicXML document as `Data`.
    ///
    /// - Throws: ``MusicXMLExportError/encodingError`` if the XML cannot
    ///   be encoded using the configured encoding.
    public func export(_ score: Score) throws -> Data {
        let xmlString = try exportToString(score)
        guard let data = xmlString.data(using: config.encoding) else {
            throw MusicXMLExportError.encodingError
        }
        return data
    }

    /// Exports a score to a MusicXML string.
    ///
    /// This method generates a complete MusicXML document as a string,
    /// useful for debugging or further processing.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let exporter = MusicXMLExporter()
    /// let xmlString = try exporter.exportToString(score)
    ///
    /// print("Generated XML:")
    /// print(xmlString)
    /// ```
    ///
    /// - Parameter score: The score to export.
    ///
    /// - Returns: The complete MusicXML document as a string.
    public func exportToString(_ score: Score) throws -> String {
        let builder = XMLBuilder(encoding: config.encoding)

        // XML declaration
        builder.writeXMLDeclaration()

        // DOCTYPE
        if config.includeDoctype {
            builder.writeMusicXMLDoctype(version: config.musicXMLVersion)
        }

        // Root element
        builder.element("score-partwise", attributes: ["version": config.musicXMLVersion]) {
            // Work information
            writeWork(score.metadata, builder: builder)

            // Movement title/number
            writeMovement(score.metadata, builder: builder)

            // Identification
            writeIdentification(score.metadata, builder: builder)

            // Defaults
            if let defaults = score.defaults {
                writeDefaults(defaults, builder: builder)
            }

            // Credits
            for credit in score.credits {
                writeCredit(credit, builder: builder)
            }

            // Part list
            writePartList(score.parts, builder: builder)

            // Parts
            for part in score.parts {
                writePart(part, builder: builder)
            }
        }

        return builder.build()
    }

    /// Exports a score to a MusicXML file.
    ///
    /// This method writes a complete MusicXML document to the specified URL.
    ///
    /// ## Example
    ///
    /// ```swift
    /// let exporter = MusicXMLExporter()
    ///
    /// // Export to Documents directory
    /// let documentsURL = FileManager.default.urls(
    ///     for: .documentDirectory,
    ///     in: .userDomainMask
    /// ).first!
    /// let outputURL = documentsURL.appendingPathComponent("score.musicxml")
    ///
    /// try exporter.export(score, to: outputURL)
    /// ```
    ///
    /// - Parameters:
    ///   - score: The score to export.
    ///   - url: The file URL to write the MusicXML document to.
    ///
    /// - Throws: ``MusicXMLExportError`` if the export fails, or file system
    ///   errors if the file cannot be written.
    public func export(_ score: Score, to url: URL) throws {
        let data = try export(score)
        try data.write(to: url)
    }

    /// Exports a score to a compressed MXL file.
    ///
    /// MXL is a compressed container format for MusicXML that uses ZIP
    /// compression. This reduces file size for complex scores.
    ///
    /// > Note: The current implementation writes uncompressed MusicXML.
    /// > Full MXL compression will be added in a future version.
    ///
    /// - Parameters:
    ///   - score: The score to export.
    ///   - url: The file URL to write the MXL archive to.
    ///     Should have a `.mxl` extension.
    ///
    /// - Throws: ``MusicXMLExportError`` if the export fails.
    public func exportCompressed(_ score: Score, to url: URL) throws {
        // For now, just write uncompressed - ZIP compression would require ZIPFoundation
        let data = try export(score)
        try data.write(to: url)
    }

    // MARK: - Header Elements

    private func writeWork(_ metadata: ScoreMetadata, builder: XMLBuilder) {
        guard metadata.workTitle != nil || metadata.workNumber != nil else { return }

        builder.element("work") {
            builder.writeOptionalElement("work-number", text: metadata.workNumber)
            builder.writeOptionalElement("work-title", text: metadata.workTitle)
        }
    }

    private func writeMovement(_ metadata: ScoreMetadata, builder: XMLBuilder) {
        builder.writeOptionalElement("movement-number", text: metadata.movementNumber)
        builder.writeOptionalElement("movement-title", text: metadata.movementTitle)
    }

    private func writeIdentification(_ metadata: ScoreMetadata, builder: XMLBuilder) {
        let hasContent = !metadata.creators.isEmpty ||
                        !metadata.rights.isEmpty ||
                        metadata.encoding != nil ||
                        metadata.source != nil

        guard hasContent else { return }

        builder.element("identification") {
            // Creators
            for creator in metadata.creators {
                var attrs: [String: String] = [:]
                if let type = creator.type {
                    attrs["type"] = type
                }
                builder.writeElement("creator", text: creator.name, attributes: attrs)
            }

            // Rights
            for rights in metadata.rights {
                builder.writeElement("rights", text: rights)
            }

            // Encoding
            if let encoding = metadata.encoding {
                builder.element("encoding") {
                    for software in encoding.software {
                        builder.writeElement("software", text: software)
                    }
                    builder.writeOptionalElement("encoding-date", text: encoding.encodingDate)
                    builder.writeOptionalElement("encoder", text: encoding.encoder)
                    builder.writeOptionalElement("encoding-description", text: encoding.encodingDescription)

                    // Add our software signature
                    if config.addEncodingSignature {
                        builder.writeElement("software", text: "SwiftMusicNotation")
                    }
                }
            } else if config.addEncodingSignature {
                builder.element("encoding") {
                    builder.writeElement("software", text: "SwiftMusicNotation")
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "yyyy-MM-dd"
                    builder.writeElement("encoding-date", text: dateFormatter.string(from: Date()))
                }
            }

            // Source
            builder.writeOptionalElement("source", text: metadata.source)
        }
    }

    private func writeDefaults(_ defaults: ScoreDefaults, builder: XMLBuilder) {
        builder.element("defaults") {
            // Scaling
            if let scaling = defaults.scaling {
                builder.element("scaling") {
                    builder.writeElement("millimeters", value: scaling.millimeters)
                    builder.writeElement("tenths", value: scaling.tenths)
                }
            }

            // Page layout
            if let page = defaults.pageSettings {
                builder.element("page-layout") {
                    builder.writeOptionalElement("page-height", value: page.pageHeight)
                    builder.writeOptionalElement("page-width", value: page.pageWidth)
                    if page.leftMargin != nil || page.rightMargin != nil ||
                       page.topMargin != nil || page.bottomMargin != nil {
                        builder.element("page-margins", attributes: ["type": "both"]) {
                            builder.writeOptionalElement("left-margin", value: page.leftMargin)
                            builder.writeOptionalElement("right-margin", value: page.rightMargin)
                            builder.writeOptionalElement("top-margin", value: page.topMargin)
                            builder.writeOptionalElement("bottom-margin", value: page.bottomMargin)
                        }
                    }
                }
            }

            // System layout
            if let system = defaults.systemLayout {
                builder.element("system-layout") {
                    if system.systemLeftMargin != nil || system.systemRightMargin != nil {
                        builder.element("system-margins") {
                            builder.writeOptionalElement("left-margin", value: system.systemLeftMargin)
                            builder.writeOptionalElement("right-margin", value: system.systemRightMargin)
                        }
                    }
                    builder.writeOptionalElement("system-distance", value: system.systemDistance)
                    builder.writeOptionalElement("top-system-distance", value: system.topSystemDistance)
                }
            }

            // Staff layouts
            for staffLayout in defaults.staffLayouts {
                var attrs: [String: String] = [:]
                if let num = staffLayout.staffNumber {
                    attrs["number"] = String(num)
                }
                builder.element("staff-layout", attributes: attrs) {
                    builder.writeOptionalElement("staff-distance", value: staffLayout.staffDistance)
                }
            }

            // Appearance
            if let appearance = defaults.appearance {
                builder.element("appearance") {
                    for lineWidth in appearance.lineWidths {
                        builder.writeElement("line-width", value: lineWidth.value, attributes: ["type": lineWidth.type])
                    }
                    for noteSize in appearance.noteSizes {
                        builder.writeElement("note-size", value: noteSize.value, attributes: ["type": noteSize.type])
                    }
                }
            }

            // Fonts
            if let musicFont = defaults.musicFont {
                writeFont("music-font", font: musicFont, builder: builder)
            }
            if let wordFont = defaults.wordFont {
                writeFont("word-font", font: wordFont, builder: builder)
            }
        }
    }

    private func writeFont(_ element: String, font: FontSpecification, builder: XMLBuilder) {
        var attrs = XMLAttributes()
        if !font.fontFamily.isEmpty {
            attrs.add("font-family", font.fontFamily.joined(separator: ","))
        }
        if let size = font.fontSize {
            attrs.add("font-size", size)
        }
        if let style = font.fontStyle {
            attrs.add("font-style", style.rawValue)
        }
        if let weight = font.fontWeight {
            attrs.add("font-weight", weight.rawValue)
        }
        builder.writeEmptyElement(element, attributes: attrs.build())
    }

    private func writeCredit(_ credit: Credit, builder: XMLBuilder) {
        var attrs = XMLAttributes()
        attrs.addIfPresent("page", credit.page)
        builder.element("credit", attributes: attrs.build()) {
            builder.writeOptionalElement("credit-type", text: credit.creditType)
            for words in credit.creditWords {
                var wordAttrs = XMLAttributes()
                wordAttrs.addIfPresent("default-x", words.defaultX)
                wordAttrs.addIfPresent("default-y", words.defaultY)
                if let justify = words.justify {
                    wordAttrs.add("justify", justify.rawValue)
                }
                builder.writeElement("credit-words", text: words.text, attributes: wordAttrs.build())
            }
        }
    }

    // MARK: - Part List

    private func writePartList(_ parts: [Part], builder: XMLBuilder) {
        builder.element("part-list") {
            for part in parts {
                builder.element("score-part", attributes: ["id": part.id]) {
                    builder.writeElement("part-name", text: part.name)
                    builder.writeOptionalElement("part-abbreviation", text: part.abbreviation)

                    // Instruments
                    for instrument in part.instruments {
                        builder.element("score-instrument", attributes: ["id": instrument.id]) {
                            builder.writeElement("instrument-name", text: instrument.name)
                            builder.writeOptionalElement("instrument-abbreviation", text: instrument.abbreviation)
                            builder.writeOptionalElement("instrument-sound", text: instrument.sound)
                            if instrument.solo {
                                builder.writeEmptyElement("solo")
                            }
                            if instrument.ensemble {
                                builder.writeEmptyElement("ensemble")
                            }
                        }
                    }

                    // MIDI instruments
                    for midi in part.midiInstruments {
                        var attrs = XMLAttributes()
                        attrs.addIfPresent("id", midi.instrumentId)
                        builder.element("midi-instrument", attributes: attrs.build()) {
                            builder.writeOptionalElement("midi-channel", value: midi.midiChannel)
                            builder.writeOptionalElement("midi-program", value: midi.midiProgram)
                            builder.writeOptionalElement("midi-bank", value: midi.midiBank)
                            builder.writeOptionalElement("volume", value: midi.volume)
                            builder.writeOptionalElement("pan", value: midi.pan)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Part Content

    private func writePart(_ part: Part, builder: XMLBuilder) {
        builder.element("part", attributes: ["id": part.id]) {
            for measure in part.measures {
                writeMeasure(measure, builder: builder)
            }
        }
    }

    private func writeMeasure(_ measure: Measure, builder: XMLBuilder) {
        var attrs = XMLAttributes()
        attrs.add("number", measure.number)
        if measure.implicit {
            attrs.add("implicit", "yes")
        }
        if let width = measure.width {
            attrs.add("width", width)
        }

        builder.element("measure", attributes: attrs.build()) {
            // Print attributes
            if let printAttrs = measure.printAttributes {
                writePrintAttributes(printAttrs, builder: builder)
            }

            // Attributes at measure start
            if let attributes = measure.attributes {
                writeAttributes(attributes, builder: builder)
            }

            // Left barline
            if let barline = measure.leftBarline {
                writeBarline(barline, location: "left", builder: builder)
            }

            // Elements
            for element in measure.elements {
                writeMeasureElement(element, builder: builder)
            }

            // Right barline
            if let barline = measure.rightBarline {
                writeBarline(barline, location: "right", builder: builder)
            }
        }
    }

    private func writePrintAttributes(_ printAttrs: PrintAttributes, builder: XMLBuilder) {
        var attrs = XMLAttributes()
        if printAttrs.newSystem {
            attrs.add("new-system", "yes")
        }
        if printAttrs.newPage {
            attrs.add("new-page", "yes")
        }
        attrs.addIfPresent("blank-page", printAttrs.blankPage)
        attrs.addIfPresent("page-number", printAttrs.pageNumber)
        attrs.addIfPresent("staff-spacing", printAttrs.staffSpacing)

        if !attrs.build().isEmpty {
            builder.writeEmptyElement("print", attributes: attrs.build())
        }
    }

    private func writeAttributes(_ attributes: MeasureAttributes, builder: XMLBuilder) {
        builder.element("attributes") {
            builder.writeOptionalElement("divisions", value: attributes.divisions)

            // Key signatures
            for key in attributes.keySignatures {
                writeKeySignature(key, builder: builder)
            }

            // Time signatures
            for time in attributes.timeSignatures {
                writeTimeSignature(time, builder: builder)
            }

            // Staves
            builder.writeOptionalElement("staves", value: attributes.staves)

            // Clefs
            for clef in attributes.clefs {
                writeClef(clef, builder: builder)
            }

            // Transposes
            for transpose in attributes.transposes {
                writeTranspose(transpose, builder: builder)
            }
        }
    }

    private func writeKeySignature(_ key: KeySignature, builder: XMLBuilder) {
        var attrs = XMLAttributes()
        if let staff = key.staffNumber {
            attrs.add("number", staff)
        }
        builder.element("key", attributes: attrs.build()) {
            builder.writeElement("fifths", value: key.fifths)
            if let mode = key.mode {
                builder.writeElement("mode", text: mode.rawValue)
            }
        }
    }

    private func writeTimeSignature(_ time: TimeSignature, builder: XMLBuilder) {
        var attrs = XMLAttributes()
        if let staff = time.staffNumber {
            attrs.add("number", staff)
        }
        if let symbol = time.symbol {
            attrs.add("symbol", symbol.rawValue)
        }
        builder.element("time", attributes: attrs.build()) {
            builder.writeElement("beats", text: time.beats)
            builder.writeElement("beat-type", text: time.beatType)
        }
    }

    private func writeClef(_ clef: Clef, builder: XMLBuilder) {
        var attrs = XMLAttributes()
        if let staff = clef.staffNumber {
            attrs.add("number", staff)
        }
        builder.element("clef", attributes: attrs.build()) {
            builder.writeElement("sign", text: clef.sign.rawValue)
            builder.writeElement("line", value: clef.line)
            builder.writeOptionalElement("clef-octave-change", value: clef.clefOctaveChange)
        }
    }

    private func writeTranspose(_ transpose: Transpose, builder: XMLBuilder) {
        builder.element("transpose") {
            builder.writeOptionalElement("diatonic", value: transpose.diatonic)
            builder.writeElement("chromatic", value: transpose.chromatic)
            builder.writeOptionalElement("octave-change", value: transpose.octaveChange)
            if transpose.double {
                builder.writeEmptyElement("double")
            }
        }
    }

    private func writeBarline(_ barline: Barline, location: String, builder: XMLBuilder) {
        builder.element("barline", attributes: ["location": location]) {
            builder.writeElement("bar-style", text: barline.barStyle.rawValue)
            if let ending = barline.ending {
                var attrs = XMLAttributes()
                attrs.add("number", ending.number)
                attrs.add("type", ending.type.rawValue)
                builder.writeElement("ending", text: ending.text ?? "", attributes: attrs.build())
            }
            if let repeatDir = barline.repeatDirection {
                var attrs = XMLAttributes()
                attrs.add("direction", repeatDir.rawValue)
                attrs.addIfPresent("times", barline.repeatTimes)
                builder.writeEmptyElement("repeat", attributes: attrs.build())
            }
        }
    }

    // MARK: - Measure Elements

    private func writeMeasureElement(_ element: MeasureElement, builder: XMLBuilder) {
        switch element {
        case .note(let note):
            writeNote(note, builder: builder)
        case .backup(let backup):
            builder.element("backup") {
                builder.writeElement("duration", value: backup.duration)
            }
        case .forward(let forward):
            builder.element("forward") {
                builder.writeElement("duration", value: forward.duration)
                builder.writeOptionalElement("voice", value: forward.voice)
                builder.writeOptionalElement("staff", value: forward.staff)
            }
        case .direction(let direction):
            writeDirection(direction, builder: builder)
        case .attributes(let attrs):
            writeAttributes(attrs, builder: builder)
        case .harmony(let harmony):
            writeHarmony(harmony, builder: builder)
        case .barline(let barline):
            writeBarline(barline, location: "middle", builder: builder)
        case .print(let printAttrs):
            writePrintAttributes(printAttrs, builder: builder)
        case .sound(let sound):
            writeSound(sound, builder: builder)
        }
    }

    // MARK: - Note

    private func writeNote(_ note: Note, builder: XMLBuilder) {
        var attrs = XMLAttributes()
        if !note.printObject {
            attrs.add("print-object", "no")
        }

        builder.element("note", attributes: attrs.build()) {
            // Grace note
            if let grace = note.grace {
                var graceAttrs = XMLAttributes()
                attrs.addIfPresent("steal-time-previous", grace.stealTimePrevious)
                attrs.addIfPresent("steal-time-following", grace.stealTimeFollowing)
                if grace.slash {
                    graceAttrs.add("slash", "yes")
                }
                builder.writeEmptyElement("grace", attributes: graceAttrs.build())
            }

            // Chord
            if note.isChordTone {
                builder.writeEmptyElement("chord")
            }

            // Cue
            if note.cue {
                builder.writeEmptyElement("cue")
            }

            // Pitch/Rest/Unpitched
            switch note.noteType {
            case .pitched(let pitch):
                builder.element("pitch") {
                    builder.writeElement("step", text: pitch.step.rawValue)
                    if pitch.alter != 0 {
                        builder.writeElement("alter", value: pitch.alter)
                    }
                    builder.writeElement("octave", value: pitch.octave)
                }
            case .unpitched(let unpitched):
                builder.element("unpitched") {
                    builder.writeElement("display-step", text: unpitched.displayStep.rawValue)
                    builder.writeElement("display-octave", value: unpitched.displayOctave)
                }
                // Export instrument reference if present
                if let instrumentId = unpitched.instrumentId {
                    builder.writeEmptyElement("instrument", attributes: ["id": instrumentId])
                }
            case .rest(let rest):
                if rest.displayStep != nil && rest.displayOctave != nil {
                    builder.element("rest") {
                        builder.writeOptionalElement("display-step", text: rest.displayStep?.rawValue)
                        builder.writeOptionalElement("display-octave", value: rest.displayOctave)
                    }
                } else if rest.measureRest {
                    builder.writeEmptyElement("rest", attributes: ["measure": "yes"])
                } else {
                    builder.writeEmptyElement("rest")
                }
            }

            // Duration (not for grace notes)
            if note.grace == nil {
                builder.writeElement("duration", value: note.durationDivisions)
            }

            // Ties
            for tie in note.ties {
                builder.writeEmptyElement("tie", attributes: ["type": tie.type.rawValue])
            }

            // Voice
            builder.writeElement("voice", value: note.voice)

            // Type
            if let type = note.type {
                builder.writeElement("type", text: durationBaseToString(type))
            }

            // Dots
            for _ in 0..<note.dots {
                builder.writeEmptyElement("dot")
            }

            // Accidental
            if let accidental = note.accidental {
                var accAttrs = XMLAttributes()
                if accidental.parentheses { accAttrs.add("parentheses", "yes") }
                if accidental.brackets { accAttrs.add("bracket", "yes") }
                if accidental.cautionary { accAttrs.add("cautionary", "yes") }
                if accidental.editorial { accAttrs.add("editorial", "yes") }
                builder.writeElement("accidental", text: accidentalToString(accidental.accidental), attributes: accAttrs.build())
            }

            // Time modification (tuplet)
            if let timeMod = note.timeModification {
                builder.element("time-modification") {
                    builder.writeElement("actual-notes", value: timeMod.actual)
                    builder.writeElement("normal-notes", value: timeMod.normal)
                    if let normalType = timeMod.normalType {
                        builder.writeElement("normal-type", text: durationBaseToString(normalType))
                    }
                }
            }

            // Stem
            if let stem = note.stemDirection {
                builder.writeElement("stem", text: stem.rawValue)
            }

            // Notehead
            if let notehead = note.notehead, notehead.type != .normal {
                var nhAttrs = XMLAttributes()
                if let filled = notehead.filled {
                    nhAttrs.add("filled", filled ? "yes" : "no")
                }
                if notehead.parentheses {
                    nhAttrs.add("parentheses", "yes")
                }
                builder.writeElement("notehead", text: notehead.type.rawValue, attributes: nhAttrs.build())
            }

            // Staff
            if note.staff > 0 {
                builder.writeElement("staff", value: note.staff)
            }

            // Beams
            for beam in note.beams {
                builder.writeElement("beam", text: beam.value.rawValue, attributes: ["number": String(beam.number)])
            }

            // Notations
            if !note.notations.isEmpty || !note.ties.isEmpty {
                builder.element("notations") {
                    // Tied notations (visual ties)
                    for tie in note.ties {
                        builder.writeEmptyElement("tied", attributes: ["type": tie.type.rawValue])
                    }

                    // Other notations
                    for notation in note.notations {
                        writeNotation(notation, builder: builder)
                    }
                }
            }

            // Lyrics
            for lyric in note.lyrics {
                var lyricAttrs = XMLAttributes()
                lyricAttrs.addIfPresent("number", lyric.number)
                builder.element("lyric", attributes: lyricAttrs.build()) {
                    if let syllabic = lyric.syllabic {
                        builder.writeElement("syllabic", text: syllabic.rawValue)
                    }
                    builder.writeElement("text", text: lyric.text)
                    if lyric.extend {
                        builder.writeEmptyElement("extend")
                    }
                }
            }
        }
    }

    private func writeNotation(_ notation: Notation, builder: XMLBuilder) {
        switch notation {
        case .tied(let tied):
            var attrs = XMLAttributes()
            attrs.add("type", tied.type.rawValue)
            attrs.addIfPresent("number", tied.number)
            if let placement = tied.placement {
                attrs.add("placement", placement.rawValue)
            }
            builder.writeEmptyElement("tied", attributes: attrs.build())

        case .slur(let slur):
            var attrs = XMLAttributes()
            attrs.add("type", slur.type.rawValue)
            attrs.add("number", slur.number)
            if let placement = slur.placement {
                attrs.add("placement", placement.rawValue)
            }
            builder.writeEmptyElement("slur", attributes: attrs.build())

        case .tuplet(let tuplet):
            var attrs = XMLAttributes()
            attrs.add("type", tuplet.type.rawValue)
            attrs.add("number", tuplet.number)
            if let bracket = tuplet.bracket {
                attrs.add("bracket", bracket ? "yes" : "no")
            }
            if let showNum = tuplet.showNumber {
                attrs.add("show-number", showNum.rawValue)
            }
            if let showType = tuplet.showType {
                attrs.add("show-type", showType.rawValue)
            }
            builder.writeEmptyElement("tuplet", attributes: attrs.build())

        case .articulations(let marks):
            builder.element("articulations") {
                for mark in marks {
                    var attrs = XMLAttributes()
                    if let placement = mark.placement {
                        attrs.add("placement", placement.rawValue)
                    }
                    builder.writeEmptyElement(mark.type, attributes: attrs.build())
                }
            }

        case .dynamics(let marks):
            builder.element("dynamics") {
                for mark in marks {
                    builder.writeEmptyElement(mark.type)
                }
            }

        case .ornaments(let orn):
            builder.element("ornaments") {
                for o in orn {
                    builder.writeEmptyElement(o.type)
                }
            }

        case .technical(let tech):
            builder.element("technical") {
                for t in tech {
                    builder.writeEmptyElement(t.type)
                }
            }

        case .fermata(let fermata):
            var attrs = XMLAttributes()
            attrs.add("type", fermata.type.rawValue)
            builder.writeElement("fermata", text: fermata.shape.rawValue, attributes: attrs.build())

        case .arpeggiate(let arp):
            var attrs = XMLAttributes()
            if let dir = arp.direction {
                attrs.add("direction", dir.rawValue)
            }
            attrs.addIfPresent("number", arp.number)
            builder.writeEmptyElement("arpeggiate", attributes: attrs.build())

        case .glissando(let gliss):
            var attrs = XMLAttributes()
            attrs.add("type", gliss.type.rawValue)
            attrs.addIfPresent("number", gliss.number)
            builder.writeElement("glissando", text: gliss.text ?? "", attributes: attrs.build())

        case .slide(let slide):
            var attrs = XMLAttributes()
            attrs.add("type", slide.type.rawValue)
            attrs.addIfPresent("number", slide.number)
            builder.writeEmptyElement("slide", attributes: attrs.build())

        case .accidentalMark(let acc):
            var attrs = XMLAttributes()
            if acc.parentheses { attrs.add("parentheses", "yes") }
            if acc.brackets { attrs.add("bracket", "yes") }
            builder.writeElement("accidental-mark", text: accidentalToString(acc.accidental), attributes: attrs.build())
        }
    }

    // MARK: - Direction

    private func writeDirection(_ direction: Direction, builder: XMLBuilder) {
        var attrs = XMLAttributes()
        if let placement = direction.placement {
            attrs.add("placement", placement.rawValue)
        }
        builder.element("direction", attributes: attrs.build()) {
            for dirType in direction.types {
                builder.element("direction-type") {
                    writeDirectionType(dirType, builder: builder)
                }
            }
            builder.writeOptionalElement("offset", value: direction.offset)
            if direction.staff > 0 {
                builder.writeElement("staff", value: direction.staff)
            }
            if let sound = direction.sound {
                writeSound(sound, builder: builder)
            }
        }
    }

    private func writeDirectionType(_ type: DirectionType, builder: XMLBuilder) {
        switch type {
        case .rehearsal(let rehearsal):
            var attrs = XMLAttributes()
            if let enclosure = rehearsal.enclosure {
                attrs.add("enclosure", enclosure.rawValue)
            }
            builder.writeElement("rehearsal", text: rehearsal.text, attributes: attrs.build())
        case .words(let words):
            builder.writeElement("words", text: words.text)
        case .wedge(let wedge):
            var attrs = XMLAttributes()
            attrs.add("type", wedge.type.rawValue)
            attrs.add("number", wedge.number)
            attrs.addIfPresent("spread", wedge.spread)
            if wedge.niente {
                attrs.add("niente", "yes")
            }
            builder.writeEmptyElement("wedge", attributes: attrs.build())
        case .dynamics(let dynamics):
            builder.element("dynamics") {
                for dyn in dynamics.values {
                    builder.writeEmptyElement(dyn.rawValue)
                }
            }
        case .metronome(let metro):
            builder.element("metronome") {
                builder.writeElement("beat-unit", text: durationBaseToString(metro.beatUnit))
                for _ in 0..<metro.beatUnitDots {
                    builder.writeEmptyElement("beat-unit-dot")
                }
                if let perMin = metro.perMinute {
                    builder.writeElement("per-minute", text: perMin)
                }
            }
        case .segno:
            builder.writeEmptyElement("segno")
        case .coda:
            builder.writeEmptyElement("coda")
        case .dashes(let dashes):
            var attrs = XMLAttributes()
            attrs.add("type", dashes.type.rawValue)
            attrs.add("number", dashes.number)
            builder.writeEmptyElement("dashes", attributes: attrs.build())
        case .bracket(let bracket):
            var attrs = XMLAttributes()
            attrs.add("type", bracket.type.rawValue)
            attrs.add("number", bracket.number)
            if let lineEnd = bracket.lineEnd {
                attrs.add("line-end", lineEnd.rawValue)
            }
            builder.writeEmptyElement("bracket", attributes: attrs.build())
        case .pedal(let pedal):
            builder.writeEmptyElement("pedal", attributes: ["type": pedal.type.rawValue])
        case .octaveShift(let octave):
            var attrs = XMLAttributes()
            attrs.add("type", octave.type.rawValue)
            attrs.add("size", octave.size)
            builder.writeEmptyElement("octave-shift", attributes: attrs.build())
        case .otherDirection(let other):
            builder.writeElement("other-direction", text: other.text)
        case .harpPedals, .principalVoice, .accordionRegistration, .percussion:
            // These can be added as needed
            break
        }
    }

    private func writeSound(_ sound: Sound, builder: XMLBuilder) {
        var attrs = XMLAttributes()
        attrs.addIfPresent("tempo", sound.tempo)
        attrs.addIfPresent("dynamics", sound.dynamics)
        if sound.dacapo { attrs.add("dacapo", "yes") }
        attrs.addIfPresent("segno", sound.segno)
        attrs.addIfPresent("dalsegno", sound.dalsegno)
        attrs.addIfPresent("coda", sound.coda)
        attrs.addIfPresent("tocoda", sound.tocoda)
        if sound.forwardRepeat { attrs.add("forward-repeat", "yes") }
        if sound.fine { attrs.add("fine", "yes") }

        builder.writeEmptyElement("sound", attributes: attrs.build())
    }

    // MARK: - Harmony

    private func writeHarmony(_ harmony: Harmony, builder: XMLBuilder) {
        builder.element("harmony") {
            builder.element("root") {
                builder.writeElement("root-step", text: harmony.root.step.rawValue)
                builder.writeOptionalElement("root-alter", value: harmony.root.alter)
            }
            builder.writeElement("kind", text: harmony.kind.rawValue)
            if let bass = harmony.bass {
                builder.element("bass") {
                    builder.writeElement("bass-step", text: bass.step.rawValue)
                    builder.writeOptionalElement("bass-alter", value: bass.alter)
                }
            }
            for degree in harmony.degrees {
                builder.element("degree") {
                    builder.writeElement("degree-value", value: degree.value)
                    builder.writeOptionalElement("degree-alter", value: degree.alter)
                    builder.writeElement("degree-type", text: degree.type.rawValue)
                }
            }
            builder.writeOptionalElement("offset", value: harmony.offset)
            builder.writeOptionalElement("staff", value: harmony.staff)
        }
    }

    // MARK: - Helpers

    private func durationBaseToString(_ base: DurationBase) -> String {
        switch base {
        case .maxima: return "maxima"
        case .longa: return "long"
        case .breve: return "breve"
        case .whole: return "whole"
        case .half: return "half"
        case .quarter: return "quarter"
        case .eighth: return "eighth"
        case .sixteenth: return "16th"
        case .thirtySecond: return "32nd"
        case .sixtyFourth: return "64th"
        case .oneHundredTwentyEighth: return "128th"
        case .twoHundredFiftySixth: return "256th"
        }
    }

    private func accidentalToString(_ acc: Accidental) -> String {
        switch acc {
        case .sharp: return "sharp"
        case .flat: return "flat"
        case .natural: return "natural"
        case .doubleSharp: return "double-sharp"
        case .doubleFlat: return "flat-flat"
        case .tripleSharp: return "triple-sharp"
        case .tripleFlat: return "triple-flat"
        case .naturalSharp: return "natural-sharp"
        case .naturalFlat: return "natural-flat"
        case .quarterToneSharp: return "quarter-sharp"
        case .quarterToneFlat: return "quarter-flat"
        case .threeQuarterToneSharp: return "three-quarters-sharp"
        case .threeQuarterToneFlat: return "three-quarters-flat"
        default: return acc.rawValue
        }
    }
}

// MARK: - Export Configuration

/// Configuration options that control MusicXML export behavior.
///
/// Use `ExportConfiguration` to customize the generated MusicXML output.
///
/// ## Example
///
/// ```swift
/// var config = ExportConfiguration()
///
/// // Use MusicXML 3.1 for broader compatibility
/// config.musicXMLVersion = "3.1"
///
/// // Skip the DOCTYPE for smaller output
/// config.includeDoctype = false
///
/// // Don't add SwiftMusicNotation signature
/// config.addEncodingSignature = false
///
/// let exporter = MusicXMLExporter(config: config)
/// ```
public struct ExportConfiguration: Sendable {
    /// The MusicXML version to declare in the output.
    ///
    /// This sets the `version` attribute on the root element and affects
    /// the DOCTYPE declaration if enabled.
    ///
    /// Common values:
    /// - `"4.0"`: Latest version (default)
    /// - `"3.1"`: Broad compatibility
    /// - `"3.0"`: Legacy compatibility
    public var musicXMLVersion: String = "4.0"

    /// The text encoding to use for the output.
    ///
    /// The encoding is declared in the XML declaration and used when
    /// converting the document to `Data`.
    ///
    /// Defaults to UTF-8, which is recommended for maximum compatibility.
    public var encoding: String.Encoding = .utf8

    /// Whether to include the DOCTYPE declaration in the output.
    ///
    /// The DOCTYPE declares the MusicXML DTD reference. While technically
    /// optional for most parsers, including it improves compatibility.
    ///
    /// Defaults to `true`.
    public var includeDoctype: Bool = true

    /// Whether to add a SwiftMusicNotation software signature.
    ///
    /// When `true`, the exporter adds `<software>SwiftMusicNotation</software>`
    /// to the encoding section and includes the current date as the encoding
    /// date if not already present.
    ///
    /// This helps track the source of exported files.
    ///
    /// Defaults to `true`.
    public var addEncodingSignature: Bool = true

    /// Creates an export configuration with default settings.
    ///
    /// Default values:
    /// - `musicXMLVersion`: `"4.0"`
    /// - `encoding`: `.utf8`
    /// - `includeDoctype`: `true`
    /// - `addEncodingSignature`: `true`
    public init() {}
}

// MARK: - Export Errors

/// Errors that can occur during MusicXML export.
///
/// These errors indicate problems with the export process. Handle them
/// to provide useful feedback to users:
///
/// ```swift
/// do {
///     try exporter.export(score, to: url)
/// } catch let error as MusicXMLExportError {
///     switch error {
///     case .encodingError:
///         print("Encoding failed")
///     case .fileWriteError(let url):
///         print("Could not write to \(url.path)")
///     case .invalidScore(let reason):
///         print("Invalid score: \(reason)")
///     }
/// }
/// ```
public enum MusicXMLExportError: Error, LocalizedError {
    /// The XML string could not be encoded using the configured encoding.
    ///
    /// This typically occurs if the score contains characters that cannot
    /// be represented in the chosen encoding. Using UTF-8 (the default)
    /// avoids this issue.
    case encodingError

    /// The file could not be written to the specified URL.
    ///
    /// This can occur due to permission issues, disk space, or an invalid path.
    /// The associated value contains the target URL.
    case fileWriteError(URL)

    /// The score contains invalid data that cannot be exported.
    ///
    /// The associated string describes the specific issue.
    case invalidScore(String)

    public var errorDescription: String? {
        switch self {
        case .encodingError:
            return "Failed to encode XML to the specified encoding"
        case .fileWriteError(let url):
            return "Failed to write file to \(url.path)"
        case .invalidScore(let reason):
            return "Invalid score: \(reason)"
        }
    }
}
