import Foundation
import MusicNotationCore

/// Compares Swift parsed scores against music21 output.
public struct Music21Comparator: Sendable {

    // MARK: - Types

    /// Result from music21 parsing.
    public struct Music21Result: Codable, Sendable {
        public var filename: String?
        public var partCount: Int?
        public var partNames: [String?]?
        public var measureCount: Int?
        public var notes: [Music21Note]?
        public var totalNotes: Int?
        public var pitchedNotes: Int?
        public var rests: Int?
        public var chords: Int?
        public var timeSignatures: [Music21TimeSignature]?
        public var keySignatures: [Music21KeySignature]?
        public var dynamics: [Music21Dynamic]?
        public var totalDynamics: Int?
        public var slurs: [Music21Slur]?
        public var totalSlurs: Int?
        public var totalArticulations: Int?
        public var totalExpressions: Int?
        public var error: String?
    }

    public struct Music21Note: Codable, Sendable {
        public var partIndex: Int?
        public var partName: String?
        public var measureNumber: Int?
        public var offset: Double?
        public var quarterLength: Double?
        public var isRest: Bool?
        public var isChord: Bool?
        public var pitch: Int?
        public var pitchName: String?
        public var step: String?
        public var octave: Int?
        public var alter: Double?
        public var duration: String?
        public var dots: Int?
        public var tie: String?
        public var voice: String?
        public var articulations: [String]?
        public var expressions: [String]?
    }

    public struct Music21Dynamic: Codable, Sendable {
        public var type: String?
        public var offset: Double?
        public var partIndex: Int?
        public var measureNumber: Int?
    }

    public struct Music21Slur: Codable, Sendable {
        public var type: String?
        public var offset: Double?
    }

    public struct Music21TimeSignature: Codable, Sendable {
        public var numerator: Int
        public var denominator: Int
        public var offset: Double?
    }

    public struct Music21KeySignature: Codable, Sendable {
        public var sharps: Int
        public var mode: String?
        public var offset: Double?
    }

    /// Comparison result between Swift and music21.
    public struct ComparisonResult: Sendable {
        public var swiftNoteCount: Int
        public var music21NoteCount: Int
        public var swiftPitchedCount: Int
        public var music21PitchedCount: Int
        public var pitchMatches: Int
        public var durationMatches: Int
        public var pitchAndDurationMatches: Int
        public var discrepancies: [Discrepancy]

        // Notation counts
        public var swiftArticulationCount: Int
        public var music21ArticulationCount: Int
        public var swiftDynamicsCount: Int
        public var music21DynamicsCount: Int
        public var swiftSlurCount: Int
        public var music21SlurCount: Int
        public var swiftExpressionCount: Int
        public var music21ExpressionCount: Int

        public var passed: Bool {
            discrepancies.isEmpty && swiftNoteCount == music21NoteCount
        }

        public var pitchSimilarity: Double {
            // Compare pitched notes only (exclude rests)
            let minPitched = min(swiftPitchedCount, music21PitchedCount)
            guard minPitched > 0 else { return 1.0 }
            return Double(pitchMatches) / Double(minPitched)
        }

        public var durationSimilarity: Double {
            let minPitched = min(swiftPitchedCount, music21PitchedCount)
            guard minPitched > 0 else { return 1.0 }
            return Double(durationMatches) / Double(minPitched)
        }

        /// Combined pitch + duration similarity (both must match)
        public var similarity: Double {
            let minPitched = min(swiftPitchedCount, music21PitchedCount)
            guard minPitched > 0 else { return 1.0 }
            return Double(pitchAndDurationMatches) / Double(minPitched)
        }

        /// Articulation match ratio
        public var articulationSimilarity: Double {
            let max = max(swiftArticulationCount, music21ArticulationCount)
            guard max > 0 else { return 1.0 }
            let min = min(swiftArticulationCount, music21ArticulationCount)
            return Double(min) / Double(max)
        }

        /// Dynamics match ratio
        public var dynamicsSimilarity: Double {
            let max = max(swiftDynamicsCount, music21DynamicsCount)
            guard max > 0 else { return 1.0 }
            let min = min(swiftDynamicsCount, music21DynamicsCount)
            return Double(min) / Double(max)
        }
    }

    /// A discrepancy between Swift and music21 parsing.
    public struct Discrepancy: CustomStringConvertible, Sendable {
        public let measure: Int
        public let field: String
        public let swiftValue: String
        public let music21Value: String

        public var description: String {
            "Measure \(measure): \(field) - Swift: \(swiftValue), music21: \(music21Value)"
        }
    }

    // MARK: - Static Properties

    /// Path to the Python script.
    public static var scriptPath: String {
        let bundle = Bundle.module

        // Try to find in bundle (when resources are properly copied)
        if let path = bundle.path(forResource: "parse_musicxml", ofType: "py", inDirectory: "Scripts") {
            return path
        }

        // Try resourcePath + Scripts
        if let resourcePath = bundle.resourcePath {
            let scriptPath = (resourcePath as NSString).appendingPathComponent("Scripts/parse_musicxml.py")
            if FileManager.default.fileExists(atPath: scriptPath) {
                return scriptPath
            }
        }

        // Fallback to known location from project root
        return "Tests/MusicXMLValidationTests/Scripts/parse_musicxml.py"
    }

    /// Checks if music21 is available.
    public static var isAvailable: Bool {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = ["-c", "import music21"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
            return process.terminationStatus == 0
        } catch {
            return false
        }
    }

    // MARK: - Public Methods

    /// Parses a MusicXML file with music21 and returns the result.
    public func parseWithMusic21(path: URL) throws -> Music21Result {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = [Self.scriptPath, path.path]

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe

        // Read data asynchronously to avoid pipe buffer blocking
        var outputData = Data()
        var errorData = Data()

        let outputHandle = outputPipe.fileHandleForReading
        let errorHandle = errorPipe.fileHandleForReading

        try process.run()

        // Read all output (this can block until EOF)
        outputData = outputHandle.readDataToEndOfFile()
        errorData = errorHandle.readDataToEndOfFile()

        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
            throw Music21Error.processError(errorMessage)
        }

        let decoder = JSONDecoder()
        return try decoder.decode(Music21Result.self, from: outputData)
    }

    /// Compares a Swift-parsed score against music21 output.
    public func compare(swiftScore: Score, music21Result: Music21Result) -> ComparisonResult {
        // Count pitched notes
        let swiftPitched = countPitchedNotes(in: swiftScore)
        let m21Pitched = music21Result.pitchedNotes ?? (music21Result.notes?.filter { $0.pitch != nil }.count ?? 0)

        // Count notations in Swift score
        let swiftNotationCounts = countNotations(in: swiftScore)

        var result = ComparisonResult(
            swiftNoteCount: countNotes(in: swiftScore),
            music21NoteCount: music21Result.totalNotes ?? 0,
            swiftPitchedCount: swiftPitched,
            music21PitchedCount: m21Pitched,
            pitchMatches: 0,
            durationMatches: 0,
            pitchAndDurationMatches: 0,
            discrepancies: [],
            swiftArticulationCount: swiftNotationCounts.articulations,
            music21ArticulationCount: music21Result.totalArticulations ?? 0,
            swiftDynamicsCount: swiftNotationCounts.dynamics,
            music21DynamicsCount: music21Result.totalDynamics ?? 0,
            swiftSlurCount: swiftNotationCounts.slurs,
            music21SlurCount: music21Result.totalSlurs ?? 0,
            swiftExpressionCount: swiftNotationCounts.expressions,
            music21ExpressionCount: music21Result.totalExpressions ?? 0
        )

        // Compare part count
        if swiftScore.parts.count != (music21Result.partCount ?? 0) {
            result.discrepancies.append(Discrepancy(
                measure: 0,
                field: "partCount",
                swiftValue: "\(swiftScore.parts.count)",
                music21Value: "\(music21Result.partCount ?? 0)"
            ))
        }

        // Compare notes using pitch+duration multiset comparison per measure
        // (ignoring part index since parsers may split parts differently)
        guard let music21Notes = music21Result.notes else { return result }

        // Note representation: (pitch, quarterLength)
        typealias NoteData = (pitch: Int, quarterLength: Double)

        // Build multisets of notes per measure (across all parts)
        var music21Notes_: [String: [NoteData]] = [:]
        for note in music21Notes {
            guard let pitch = note.pitch, let measureNum = note.measureNumber else { continue }
            let ql = note.quarterLength ?? 1.0
            music21Notes_["\(measureNum)", default: []].append((pitch, ql))
        }

        // Build Swift notes per measure (across all parts)
        var swiftNotes: [String: [NoteData]] = [:]
        for part in swiftScore.parts {
            // Track divisions (starts at 1, updates when we encounter attributes with divisions)
            var divisions = 1

            for measure in part.measures {
                // Check for divisions in measure attributes (direct property)
                if let div = measure.attributes?.divisions, div > 0 {
                    divisions = div
                }

                // Process elements in order to handle mid-measure division changes
                for element in measure.elements {
                    switch element {
                    case .attributes(let attrs):
                        // Update divisions when we encounter attributes (mid-measure or start)
                        if let div = attrs.divisions, div > 0 {
                            divisions = div
                        }

                    case .note(let note):
                        if let pitch = note.pitch, let midi = pitchToMIDI(pitch) {
                            // Grace notes have 0 duration (matching music21)
                            let quarterLength: Double
                            if note.grace != nil {
                                quarterLength = 0.0
                            } else {
                                // Convert duration to quarter lengths using current divisions
                                // Note: MusicXML duration already includes tuplet modification
                                quarterLength = Double(note.durationDivisions) / Double(divisions)
                            }

                            swiftNotes[measure.number, default: []].append((midi, quarterLength))
                        }

                    default:
                        break
                    }
                }
            }
        }

        // Detect measure number offset (music21 uses 0 for pickup, MusicXML often uses 1)
        let swiftMeasures = swiftNotes.keys.compactMap { Int($0) }.sorted()
        let m21Measures = music21Notes_.keys.compactMap { Int($0) }.sorted()

        var measureOffset = 0
        if let swiftFirst = swiftMeasures.first, let m21First = m21Measures.first {
            measureOffset = m21First - swiftFirst
        }

        // Build a combined pool of all music21 notes for flexible matching
        // This helps when implicit measures are merged differently
        var allM21Notes: [NoteData] = music21Notes_.values.flatMap { $0 }

        // Compare notes per measure
        for (measureNum, swiftMeasureNotes) in swiftNotes {
            var m21MeasureNotes: [NoteData] = []

            // Try adjusted measure number first (using offset)
            if let num = Int(measureNum) {
                let adjustedMeasure = num + measureOffset
                m21MeasureNotes = music21Notes_["\(adjustedMeasure)"] ?? []
            }

            // If still no match, try direct match
            if m21MeasureNotes.isEmpty {
                m21MeasureNotes = music21Notes_[measureNum] ?? []
            }

            // For implicit measures (like "X1"), try to find notes in nearby measures
            if m21MeasureNotes.isEmpty && measureNum.hasPrefix("X") {
                // Extract the base measure number and try that
                let baseMeasure = String(measureNum.dropFirst())
                if let num = Int(baseMeasure) {
                    m21MeasureNotes = music21Notes_["\(num)"] ?? music21Notes_["\(num + measureOffset)"] ?? []
                }
            }

            // Match notes (use 0.02 tolerance for floating-point tuplet differences)
            let durationTolerance = 0.02
            for swiftNote in swiftMeasureNotes {
                // Try to find exact match in measure (pitch + duration)
                if let idx = m21MeasureNotes.firstIndex(where: {
                    $0.pitch == swiftNote.pitch && abs($0.quarterLength - swiftNote.quarterLength) < durationTolerance
                }) {
                    result.pitchMatches += 1
                    result.durationMatches += 1
                    result.pitchAndDurationMatches += 1
                    m21MeasureNotes.remove(at: idx)
                }
                // Try pitch-only match in measure
                else if let idx = m21MeasureNotes.firstIndex(where: { $0.pitch == swiftNote.pitch }) {
                    result.pitchMatches += 1
                    m21MeasureNotes.remove(at: idx)
                }
                // Fallback: try to find in global pool (for implicit measure merging issues)
                else if let idx = allM21Notes.firstIndex(where: {
                    $0.pitch == swiftNote.pitch && abs($0.quarterLength - swiftNote.quarterLength) < durationTolerance
                }) {
                    result.pitchMatches += 1
                    result.durationMatches += 1
                    result.pitchAndDurationMatches += 1
                    allM21Notes.remove(at: idx)
                }
                else if let idx = allM21Notes.firstIndex(where: { $0.pitch == swiftNote.pitch }) {
                    result.pitchMatches += 1
                    allM21Notes.remove(at: idx)
                }
            }
        }

        return result
    }

    /// Full comparison: parse with music21, then compare.
    public func compare(musicxmlPath: URL, swiftScore: Score) throws -> ComparisonResult {
        let music21Result = try parseWithMusic21(path: musicxmlPath)

        if let error = music21Result.error {
            throw Music21Error.parseError(error)
        }

        return compare(swiftScore: swiftScore, music21Result: music21Result)
    }

    // MARK: - Private Methods

    private func countNotes(in score: Score) -> Int {
        score.parts.flatMap { $0.measures.flatMap { $0.notes } }.count
    }

    private func countPitchedNotes(in score: Score) -> Int {
        score.parts.flatMap { $0.measures.flatMap { $0.notes } }.filter { $0.pitch != nil }.count
    }

    private struct NotationCounts {
        var articulations: Int = 0
        var dynamics: Int = 0
        var slurs: Int = 0
        var expressions: Int = 0  // ornaments
    }

    private func countNotations(in score: Score) -> NotationCounts {
        var counts = NotationCounts()

        for part in score.parts {
            for measure in part.measures {
                // Count articulations, technical, and ornaments from notes
                for note in measure.notes {
                    // Skip chord tones for articulations/technical - music21 only counts
                    // these once per chord (on the chord object), not per chord note
                    let skipArticulations = note.isChordTone

                    for notation in note.notations {
                        switch notation {
                        case .articulations(let arts):
                            if !skipArticulations {
                                counts.articulations += arts.count
                            }
                        case .technical(let techs):
                            // music21 counts technical markings (fingering, string, fret,
                            // harmonic, up-bow, down-bow, etc.) as articulations
                            if !skipArticulations {
                                counts.articulations += techs.count
                            }
                        case .slur(let slur):
                            if slur.type == .start {
                                counts.slurs += 1
                            }
                        case .ornaments(let ornaments):
                            if !skipArticulations {
                                counts.expressions += ornaments.count
                            }
                        case .fermata:
                            // music21 counts fermatas as expressions
                            if !skipArticulations {
                                counts.expressions += 1
                            }
                        case .arpeggiate:
                            // music21 counts arpeggio marks as expressions
                            if !skipArticulations {
                                counts.expressions += 1
                            }
                        default:
                            break
                        }
                    }
                }

                // Count dynamics from directions
                for element in measure.elements {
                    if case .direction(let direction) = element {
                        for dirType in direction.types {
                            if case .dynamics = dirType {
                                counts.dynamics += 1
                            }
                        }
                    }
                }
            }
        }

        return counts
    }

    private func pitchToMIDI(_ pitch: Pitch) -> Int? {
        let stepValue: Int
        switch pitch.step {
        case .c: stepValue = 0
        case .d: stepValue = 2
        case .e: stepValue = 4
        case .f: stepValue = 5
        case .g: stepValue = 7
        case .a: stepValue = 9
        case .b: stepValue = 11
        }
        // Calculate pitch space (with fractional microtones) then round to MIDI
        // music21 uses round-half-up: 58.5 → 59, 64.5 → 65
        let pitchSpace = Double((pitch.octave + 1) * 12 + stepValue) + pitch.alter
        return Int(pitchSpace.rounded(.toNearestOrAwayFromZero))
    }
}

// MARK: - Errors

public enum Music21Error: Error, LocalizedError {
    case notAvailable
    case processError(String)
    case parseError(String)

    public var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "music21 is not available. Install with: pip install music21"
        case .processError(let message):
            return "Process error: \(message)"
        case .parseError(let message):
            return "Parse error: \(message)"
        }
    }
}
