import Foundation
import MusicNotationCore

/// Compares two scores for equality with configurable options.
public struct ScoreComparator {

    // MARK: - Options

    /// Configuration options for score comparison.
    public struct Options: Sendable {
        /// Whether to compare metadata (title, composer, etc.).
        public var compareMetadata: Bool

        /// Whether to compare layout properties (page size, margins, etc.).
        public var compareLayout: Bool

        /// Tolerance for floating point comparisons.
        public var floatTolerance: Double

        /// Whether to compare identifiers (UUIDs, part IDs).
        public var compareIdentifiers: Bool

        /// Whether to compare encoding information (software, date).
        public var compareEncoding: Bool

        /// Whether to compare credits (title credits, copyright text).
        public var compareCredits: Bool

        /// Maximum number of differences to collect before stopping.
        public var maxDifferences: Int

        public init(
            compareMetadata: Bool = true,
            compareLayout: Bool = false,
            floatTolerance: Double = 0.001,
            compareIdentifiers: Bool = false,
            compareEncoding: Bool = false,
            compareCredits: Bool = false,
            maxDifferences: Int = 100
        ) {
            self.compareMetadata = compareMetadata
            self.compareLayout = compareLayout
            self.floatTolerance = floatTolerance
            self.compareIdentifiers = compareIdentifiers
            self.compareEncoding = compareEncoding
            self.compareCredits = compareCredits
            self.maxDifferences = maxDifferences
        }

        /// Options for round-trip validation (import → export → reimport).
        /// Ignores identifiers, encoding, layout, and credits.
        public static let roundTrip = Options(
            compareMetadata: true,
            compareLayout: false,
            floatTolerance: 0.001,
            compareIdentifiers: false,
            compareEncoding: false,
            compareCredits: false,
            maxDifferences: 100
        )

        /// Strict comparison options - compares everything except identifiers.
        public static let strict = Options(
            compareMetadata: true,
            compareLayout: true,
            floatTolerance: 0.0001,
            compareIdentifiers: false,
            compareEncoding: false,
            compareCredits: true,
            maxDifferences: 1000
        )

        /// Minimal comparison - only compares musical content (notes, rests).
        public static let musicalContent = Options(
            compareMetadata: false,
            compareLayout: false,
            floatTolerance: 0.001,
            compareIdentifiers: false,
            compareEncoding: false,
            compareCredits: false,
            maxDifferences: 100
        )
    }

    // MARK: - Properties

    private let options: Options

    // MARK: - Initialization

    public init(options: Options = .roundTrip) {
        self.options = options
    }

    // MARK: - Public Methods

    /// Compares two scores and returns their differences.
    public func compare(_ score1: Score, _ score2: Score) -> ScoreDiff {
        let builder = ScoreDiff.Builder()

        // Compare metadata
        if options.compareMetadata {
            compareMetadata(score1.metadata, score2.metadata, builder: builder)
        }

        // Compare part count
        if score1.parts.count != score2.parts.count {
            builder.add(.partCountMismatch(expected: score1.parts.count, actual: score2.parts.count))
            return builder.build()
        }

        // Compare each part
        for (partIndex, (part1, part2)) in zip(score1.parts, score2.parts).enumerated() {
            if builder.count >= options.maxDifferences { break }
            comparePart(part1, part2, partIndex: partIndex, builder: builder)
        }

        return builder.build()
    }

    // MARK: - Private Methods

    private func compareMetadata(_ meta1: ScoreMetadata, _ meta2: ScoreMetadata, builder: ScoreDiff.Builder) {
        if meta1.workTitle != meta2.workTitle {
            builder.add(.metadataMismatch(field: "workTitle", expected: meta1.workTitle, actual: meta2.workTitle))
        }
        if meta1.workNumber != meta2.workNumber {
            builder.add(.metadataMismatch(field: "workNumber", expected: meta1.workNumber, actual: meta2.workNumber))
        }
        if meta1.movementTitle != meta2.movementTitle {
            builder.add(.metadataMismatch(field: "movementTitle", expected: meta1.movementTitle, actual: meta2.movementTitle))
        }
        if meta1.movementNumber != meta2.movementNumber {
            builder.add(.metadataMismatch(field: "movementNumber", expected: meta1.movementNumber, actual: meta2.movementNumber))
        }

        // Compare creators
        let creators1 = meta1.creators.map { "\($0.type ?? "unknown"):\($0.name)" }.sorted()
        let creators2 = meta2.creators.map { "\($0.type ?? "unknown"):\($0.name)" }.sorted()
        if creators1 != creators2 {
            builder.add(.metadataMismatch(field: "creators", expected: creators1.joined(separator: ", "), actual: creators2.joined(separator: ", ")))
        }
    }

    private func comparePart(_ part1: Part, _ part2: Part, partIndex: Int, builder: ScoreDiff.Builder) {
        // Compare part name
        if part1.name != part2.name {
            builder.add(.partNameMismatch(partIndex: partIndex, expected: part1.name, actual: part2.name))
        }

        // Compare identifiers if requested
        if options.compareIdentifiers && part1.id != part2.id {
            builder.add(.partIdMismatch(partIndex: partIndex, expected: part1.id, actual: part2.id))
        }

        // Compare measure count
        if part1.measures.count != part2.measures.count {
            builder.add(.measureCountMismatch(
                partIndex: partIndex,
                partName: part1.name,
                expected: part1.measures.count,
                actual: part2.measures.count
            ))
            return
        }

        // Compare each measure
        for (measureIndex, (measure1, measure2)) in zip(part1.measures, part2.measures).enumerated() {
            if builder.count >= options.maxDifferences { break }

            let location = ScoreDiff.MeasureLocation(
                partIndex: partIndex,
                partName: part1.name,
                measureIndex: measureIndex,
                measureNumber: measure1.number
            )

            compareMeasure(measure1, measure2, location: location, builder: builder)
        }
    }

    private func compareMeasure(_ measure1: Measure, _ measure2: Measure, location: ScoreDiff.MeasureLocation, builder: ScoreDiff.Builder) {
        // Compare attributes
        if let attrs1 = measure1.attributes, let attrs2 = measure2.attributes {
            compareAttributes(attrs1, attrs2, location: location, builder: builder)
        } else if measure1.attributes != nil || measure2.attributes != nil {
            // One has attributes, the other doesn't - check if they're meaningful differences
            if let attrs1 = measure1.attributes {
                if attrs1.divisions != nil || !attrs1.timeSignatures.isEmpty || !attrs1.keySignatures.isEmpty || !attrs1.clefs.isEmpty {
                    builder.add(.attributeDifference(location: location, diff: .divisionsMismatch(expected: attrs1.divisions, actual: nil)))
                }
            }
            if let attrs2 = measure2.attributes {
                if attrs2.divisions != nil || !attrs2.timeSignatures.isEmpty || !attrs2.keySignatures.isEmpty || !attrs2.clefs.isEmpty {
                    builder.add(.attributeDifference(location: location, diff: .divisionsMismatch(expected: nil, actual: attrs2.divisions)))
                }
            }
        }

        // Compare notes
        let notes1 = measure1.notes
        let notes2 = measure2.notes

        if notes1.count != notes2.count {
            builder.add(.noteCountMismatch(location: location, expected: notes1.count, actual: notes2.count))
        } else {
            for (noteIndex, (note1, note2)) in zip(notes1, notes2).enumerated() {
                if builder.count >= options.maxDifferences { break }

                let noteLocation = ScoreDiff.NoteLocation(
                    measureLocation: location,
                    noteIndex: noteIndex,
                    voice: note1.voice,
                    staff: note1.staff
                )

                compareNote(note1, note2, location: noteLocation, builder: builder)
            }
        }

        // Compare barlines
        compareBarline(measure1.leftBarline, measure2.leftBarline, location: location, side: .left, builder: builder)
        compareBarline(measure1.rightBarline, measure2.rightBarline, location: location, side: .right, builder: builder)

        // Compare directions
        let directions1 = measure1.elements.compactMap { element -> Direction? in
            if case .direction(let dir) = element { return dir }
            return nil
        }
        let directions2 = measure2.elements.compactMap { element -> Direction? in
            if case .direction(let dir) = element { return dir }
            return nil
        }

        compareDirections(directions1, directions2, location: location, builder: builder)
    }

    private func compareAttributes(_ attrs1: MeasureAttributes, _ attrs2: MeasureAttributes, location: ScoreDiff.MeasureLocation, builder: ScoreDiff.Builder) {
        // Compare divisions
        if attrs1.divisions != attrs2.divisions {
            builder.add(.attributeDifference(location: location, diff: .divisionsMismatch(expected: attrs1.divisions, actual: attrs2.divisions)))
        }

        // Compare staves
        if attrs1.staves != attrs2.staves {
            builder.add(.attributeDifference(location: location, diff: .stavesMismatch(expected: attrs1.staves ?? 1, actual: attrs2.staves ?? 1)))
        }

        // Compare time signatures
        let time1 = attrs1.timeSignatures.first.map { "\($0.beats)/\($0.beatType)" } ?? "none"
        let time2 = attrs2.timeSignatures.first.map { "\($0.beats)/\($0.beatType)" } ?? "none"
        if time1 != time2 {
            builder.add(.attributeDifference(location: location, diff: .timeMismatch(expected: time1, actual: time2)))
        }

        // Compare key signatures
        let key1 = attrs1.keySignatures.first.map { "\($0.fifths)" } ?? "none"
        let key2 = attrs2.keySignatures.first.map { "\($0.fifths)" } ?? "none"
        if key1 != key2 {
            builder.add(.attributeDifference(location: location, diff: .keyMismatch(expected: key1, actual: key2)))
        }

        // Compare clefs
        let clef1 = attrs1.clefs.first.map { "\($0.sign.rawValue)\($0.line)" } ?? "none"
        let clef2 = attrs2.clefs.first.map { "\($0.sign.rawValue)\($0.line)" } ?? "none"
        if clef1 != clef2 {
            builder.add(.attributeDifference(location: location, diff: .clefMismatch(expected: clef1, actual: clef2)))
        }
    }

    private func compareNote(_ note1: Note, _ note2: Note, location: ScoreDiff.NoteLocation, builder: ScoreDiff.Builder) {
        // Compare rest status
        if note1.isRest != note2.isRest {
            builder.add(.noteDifference(location: location, diff: .restMismatch(expected: note1.isRest, actual: note2.isRest)))
            return
        }

        // Compare pitch
        let pitch1 = pitchDescription(for: note1)
        let pitch2 = pitchDescription(for: note2)
        if pitch1.step != pitch2.step || pitch1.octave != pitch2.octave || !floatsEqual(pitch1.alter, pitch2.alter) {
            builder.add(.noteDifference(location: location, diff: .pitchMismatch(expected: pitch1, actual: pitch2)))
        }

        // Compare duration
        if note1.durationDivisions != note2.durationDivisions {
            builder.add(.noteDifference(location: location, diff: .durationMismatch(expected: note1.durationDivisions, actual: note2.durationDivisions)))
        }

        // Compare type
        let type1 = note1.type?.musicXMLTypeName
        let type2 = note2.type?.musicXMLTypeName
        if type1 != type2 {
            builder.add(.noteDifference(location: location, diff: .typeMismatch(expected: type1, actual: type2)))
        }

        // Compare dots
        if note1.dots != note2.dots {
            builder.add(.noteDifference(location: location, diff: .dotsMismatch(expected: note1.dots, actual: note2.dots)))
        }

        // Compare voice
        if note1.voice != note2.voice {
            builder.add(.noteDifference(location: location, diff: .voiceMismatch(expected: note1.voice, actual: note2.voice)))
        }

        // Compare staff
        if note1.staff != note2.staff {
            builder.add(.noteDifference(location: location, diff: .staffMismatch(expected: note1.staff, actual: note2.staff)))
        }

        // Compare chord status
        if note1.isChordTone != note2.isChordTone {
            builder.add(.noteDifference(location: location, diff: .chordMismatch(expected: note1.isChordTone, actual: note2.isChordTone)))
        }

        // Compare grace note status
        if note1.isGraceNote != note2.isGraceNote {
            builder.add(.noteDifference(location: location, diff: .graceMismatch(expected: note1.isGraceNote, actual: note2.isGraceNote)))
        }

        // Compare ties
        let ties1 = note1.ties.map { $0.type.rawValue }.sorted()
        let ties2 = note2.ties.map { $0.type.rawValue }.sorted()
        if ties1 != ties2 {
            builder.add(.noteDifference(location: location, diff: .tieMismatch(expected: ties1, actual: ties2)))
        }

        // Compare accidentals
        let acc1 = note1.accidental?.accidental.rawValue
        let acc2 = note2.accidental?.accidental.rawValue
        if acc1 != acc2 {
            builder.add(.noteDifference(location: location, diff: .accidentalMismatch(expected: acc1, actual: acc2)))
        }
    }

    private func pitchDescription(for note: Note) -> ScoreDiff.PitchDescription {
        if note.isRest {
            return .rest
        }

        if let pitch = note.pitch {
            return ScoreDiff.PitchDescription(
                step: pitch.step.rawValue,
                octave: pitch.octave,
                alter: pitch.alter
            )
        }

        if let unpitched = note.unpitched {
            return .unpitched(step: unpitched.displayStep.rawValue, octave: unpitched.displayOctave)
        }

        return .rest
    }

    private func compareBarline(_ barline1: Barline?, _ barline2: Barline?, location: ScoreDiff.MeasureLocation, side: ScoreDiff.BarlineSide, builder: ScoreDiff.Builder) {
        let style1 = barline1?.barStyle.rawValue
        let style2 = barline2?.barStyle.rawValue

        // Don't report differences for default barlines
        if style1 == "regular" && style2 == nil { return }
        if style1 == nil && style2 == "regular" { return }
        if style1 == nil && style2 == nil { return }

        if style1 != style2 {
            builder.add(.barlineDifference(location: location, side: side, diff: .styleMismatch(expected: style1, actual: style2)))
        }

        // Compare repeat
        let repeat1 = barline1?.repeatDirection?.rawValue
        let repeat2 = barline2?.repeatDirection?.rawValue
        if repeat1 != repeat2 {
            builder.add(.barlineDifference(location: location, side: side, diff: .repeatMismatch(expected: repeat1, actual: repeat2)))
        }

        // Compare ending
        let ending1 = barline1?.ending.map { "type:\($0.type.rawValue),number:\($0.number)" }
        let ending2 = barline2?.ending.map { "type:\($0.type.rawValue),number:\($0.number)" }
        if ending1 != ending2 {
            builder.add(.barlineDifference(location: location, side: side, diff: .endingMismatch(expected: ending1, actual: ending2)))
        }
    }

    private func compareDirections(_ dirs1: [Direction], _ dirs2: [Direction], location: ScoreDiff.MeasureLocation, builder: ScoreDiff.Builder) {
        // Extract dynamics from both
        let dynamics1 = extractDynamics(from: dirs1)
        let dynamics2 = extractDynamics(from: dirs2)

        if dynamics1 != dynamics2 {
            builder.add(.directionDifference(location: location, diff: .dynamicsMismatch(expected: dynamics1, actual: dynamics2)))
        }

        // Extract wedges
        let wedges1 = extractWedges(from: dirs1)
        let wedges2 = extractWedges(from: dirs2)

        if wedges1 != wedges2 {
            builder.add(.directionDifference(location: location, diff: .wedgeMismatch(expected: wedges1.first, actual: wedges2.first)))
        }

        // Extract tempo
        let tempo1 = dirs1.compactMap { $0.sound?.tempo }.first
        let tempo2 = dirs2.compactMap { $0.sound?.tempo }.first

        if !optionalFloatsEqual(tempo1, tempo2) {
            builder.add(.directionDifference(location: location, diff: .tempoMismatch(expected: tempo1, actual: tempo2)))
        }
    }

    private func extractDynamics(from directions: [Direction]) -> [String] {
        var result: [String] = []
        for dir in directions {
            for type in dir.types {
                if case .dynamics(let dyn) = type {
                    result.append(contentsOf: dyn.values.map { $0.rawValue })
                }
            }
        }
        return result.sorted()
    }

    private func extractWedges(from directions: [Direction]) -> [String] {
        var result: [String] = []
        for dir in directions {
            for type in dir.types {
                if case .wedge(let wedge) = type {
                    result.append("\(wedge.type.rawValue)")
                }
            }
        }
        return result
    }

    private func floatsEqual(_ a: Double, _ b: Double) -> Bool {
        abs(a - b) < options.floatTolerance
    }

    private func optionalFloatsEqual(_ a: Double?, _ b: Double?) -> Bool {
        switch (a, b) {
        case (.none, .none):
            return true
        case (.some(let a), .some(let b)):
            return floatsEqual(a, b)
        default:
            return false
        }
    }
}
