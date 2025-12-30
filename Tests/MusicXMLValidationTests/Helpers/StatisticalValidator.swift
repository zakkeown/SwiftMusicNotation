import Foundation
import MusicNotationCore

/// Validates MusicXML parsing using statistical analysis.
/// Detects anomalies in parsed data by comparing against expected distributions.
public struct StatisticalValidator: Sendable {

    // MARK: - Types

    /// Statistics for a corpus of parsed scores.
    public struct CorpusStatistics: Sendable {
        public var fileCount: Int = 0
        public var parseSuccessCount: Int = 0
        public var parseFailureCount: Int = 0

        public var totalParts: Int = 0
        public var totalMeasures: Int = 0
        public var totalNotes: Int = 0

        public var noteCountsByFile: [String: Int] = [:]
        public var measureCountsByFile: [String: Int] = [:]

        public var durationDistribution: [String: Int] = [:]  // quarter, eighth, half, etc.
        public var pitchDistribution: [Int: Int] = [:]  // MIDI note number -> count

        public var anomalies: [Anomaly] = []

        public var parseSuccessRate: Double {
            guard fileCount > 0 else { return 0 }
            return Double(parseSuccessCount) / Double(fileCount)
        }

        public var averageNotesPerFile: Double {
            guard parseSuccessCount > 0 else { return 0 }
            return Double(totalNotes) / Double(parseSuccessCount)
        }

        public var averageMeasuresPerFile: Double {
            guard parseSuccessCount > 0 else { return 0 }
            return Double(totalMeasures) / Double(parseSuccessCount)
        }

        public mutating func addParseSuccess() {
            parseSuccessCount += 1
        }

        public mutating func addParseFailure() {
            parseFailureCount += 1
        }
    }

    /// Detected anomaly in corpus statistics.
    public enum Anomaly: CustomStringConvertible, Sendable {
        case unusualNoteCount(file: String, count: Int, average: Double, deviation: Double)
        case suspiciousDurationRatio(dominant: String, ratio: Double)
        case emptyMeasures(file: String, count: Int)
        case noNotes(file: String)
        case extremePitchRange(file: String, low: Int, high: Int)
        case lowParseSuccessRate(rate: Double)

        public var description: String {
            switch self {
            case .unusualNoteCount(let file, let count, let average, let deviation):
                return "Unusual note count in '\(file)': \(count) (avg: \(Int(average)), deviation: \(String(format: "%.1f", deviation))σ)"
            case .suspiciousDurationRatio(let dominant, let ratio):
                return "Suspicious duration ratio: \(dominant) = \(String(format: "%.1f", ratio * 100))%"
            case .emptyMeasures(let file, let count):
                return "Empty measures in '\(file)': \(count)"
            case .noNotes(let file):
                return "No notes in '\(file)'"
            case .extremePitchRange(let file, let low, let high):
                return "Extreme pitch range in '\(file)': MIDI \(low) to \(high)"
            case .lowParseSuccessRate(let rate):
                return "Low parse success rate: \(String(format: "%.1f", rate * 100))%"
            }
        }
    }

    // MARK: - Properties

    /// Standard deviation threshold for flagging anomalies.
    public var anomalyThreshold: Double = 3.0

    /// Minimum expected parse success rate.
    public var minimumParseSuccessRate: Double = 0.9

    // MARK: - Initialization

    public init(anomalyThreshold: Double = 3.0, minimumParseSuccessRate: Double = 0.9) {
        self.anomalyThreshold = anomalyThreshold
        self.minimumParseSuccessRate = minimumParseSuccessRate
    }

    // MARK: - Public Methods

    /// Analyzes a single score and returns its statistics.
    public func analyze(_ score: Score, filename: String = "unknown") -> ScoreStatistics {
        var stats = ScoreStatistics(filename: filename)

        stats.partCount = score.parts.count

        for part in score.parts {
            stats.measureCount += part.measures.count

            for measure in part.measures {
                let notes = measure.notes

                if notes.isEmpty {
                    stats.emptyMeasureCount += 1
                }

                for note in notes {
                    stats.noteCount += 1

                    // Track duration types
                    if let type = note.type {
                        stats.durationCounts[type.musicXMLTypeName, default: 0] += 1
                    }

                    // Track pitches (MIDI numbers)
                    if let pitch = note.pitch {
                        let midi = pitchToMIDI(pitch)
                        stats.pitchCounts[midi, default: 0] += 1

                        if stats.lowestPitch == nil || midi < stats.lowestPitch! {
                            stats.lowestPitch = midi
                        }
                        if stats.highestPitch == nil || midi > stats.highestPitch! {
                            stats.highestPitch = midi
                        }
                    }

                    // Track other features
                    if note.isRest { stats.restCount += 1 }
                    if note.isChordTone { stats.chordToneCount += 1 }
                    if note.isGraceNote { stats.graceNoteCount += 1 }
                    if !note.ties.isEmpty { stats.tiedNoteCount += 1 }
                }
            }
        }

        return stats
    }

    /// Builds corpus statistics from multiple score statistics.
    public func buildCorpusStatistics(from scoreStats: [ScoreStatistics]) -> CorpusStatistics {
        var corpus = CorpusStatistics()

        corpus.fileCount = scoreStats.count
        corpus.parseSuccessCount = scoreStats.count

        for stats in scoreStats {
            corpus.totalParts += stats.partCount
            corpus.totalMeasures += stats.measureCount
            corpus.totalNotes += stats.noteCount

            corpus.noteCountsByFile[stats.filename] = stats.noteCount
            corpus.measureCountsByFile[stats.filename] = stats.measureCount

            // Merge duration distributions
            for (duration, count) in stats.durationCounts {
                corpus.durationDistribution[duration, default: 0] += count
            }

            // Merge pitch distributions
            for (pitch, count) in stats.pitchCounts {
                corpus.pitchDistribution[pitch, default: 0] += count
            }
        }

        // Detect anomalies
        corpus.anomalies = detectAnomalies(corpus: corpus, scoreStats: scoreStats)

        return corpus
    }

    /// Validates that corpus statistics are within expected ranges.
    public func validateCorpus(_ corpus: CorpusStatistics) -> ValidationResult {
        var violations: [String] = []

        // Check parse success rate
        if corpus.parseSuccessRate < minimumParseSuccessRate {
            violations.append("Parse success rate \(String(format: "%.1f", corpus.parseSuccessRate * 100))% below minimum \(String(format: "%.1f", minimumParseSuccessRate * 100))%")
        }

        // Check for reasonable duration distribution
        // Quarters/eighths should typically be most common
        let totalDurations = corpus.durationDistribution.values.reduce(0, +)
        if totalDurations > 0 {
            let shortDurations = (corpus.durationDistribution["quarter"] ?? 0) +
                                 (corpus.durationDistribution["eighth"] ?? 0) +
                                 (corpus.durationDistribution["16th"] ?? 0)
            let shortRatio = Double(shortDurations) / Double(totalDurations)

            // At least 30% should be quarter/eighth/16th notes
            if shortRatio < 0.3 {
                violations.append("Unusual duration distribution: only \(String(format: "%.1f", shortRatio * 100))% short notes")
            }
        }

        // Check pitch distribution is centered reasonably
        if !corpus.pitchDistribution.isEmpty {
            let pitches = corpus.pitchDistribution.keys.sorted()
            let lowest = pitches.first ?? 0
            let highest = pitches.last ?? 127

            // MIDI range should be within playable limits (21-108 for piano, wider for all instruments)
            if lowest < 12 || highest > 120 {
                violations.append("Extreme pitch range: MIDI \(lowest) to \(highest)")
            }
        }

        return ValidationResult(
            passed: violations.isEmpty,
            violations: violations,
            corpus: corpus
        )
    }

    // MARK: - Helper Types

    /// Statistics for a single score.
    public struct ScoreStatistics: Sendable {
        public var filename: String
        public var partCount: Int = 0
        public var measureCount: Int = 0
        public var noteCount: Int = 0
        public var restCount: Int = 0
        public var chordToneCount: Int = 0
        public var graceNoteCount: Int = 0
        public var tiedNoteCount: Int = 0
        public var emptyMeasureCount: Int = 0

        public var lowestPitch: Int?
        public var highestPitch: Int?

        public var durationCounts: [String: Int] = [:]
        public var pitchCounts: [Int: Int] = [:]

        public init(filename: String) {
            self.filename = filename
        }
    }

    /// Result of corpus validation.
    public struct ValidationResult: Sendable {
        public var passed: Bool
        public var violations: [String]
        public var corpus: CorpusStatistics

        public func report() -> String {
            if passed {
                return "Corpus validation passed. \(corpus.parseSuccessCount)/\(corpus.fileCount) files parsed successfully."
            } else {
                return "Corpus validation failed:\n" + violations.map { "  - \($0)" }.joined(separator: "\n")
            }
        }
    }

    // MARK: - Private Methods

    private func detectAnomalies(corpus: CorpusStatistics, scoreStats: [ScoreStatistics]) -> [Anomaly] {
        var anomalies: [Anomaly] = []

        // Check parse success rate
        if corpus.parseSuccessRate < minimumParseSuccessRate {
            anomalies.append(.lowParseSuccessRate(rate: corpus.parseSuccessRate))
        }

        // Detect unusual note counts (more than N standard deviations from mean)
        let noteCounts = scoreStats.map { Double($0.noteCount) }
        if let (mean, stdDev) = meanAndStdDev(noteCounts), stdDev > 0 {
            for stats in scoreStats {
                let deviation = abs(Double(stats.noteCount) - mean) / stdDev
                if deviation > anomalyThreshold {
                    anomalies.append(.unusualNoteCount(
                        file: stats.filename,
                        count: stats.noteCount,
                        average: mean,
                        deviation: deviation
                    ))
                }
            }
        }

        // Detect files with no notes
        for stats in scoreStats where stats.noteCount == 0 {
            anomalies.append(.noNotes(file: stats.filename))
        }

        // Detect files with many empty measures
        for stats in scoreStats where stats.emptyMeasureCount > stats.measureCount / 2 {
            anomalies.append(.emptyMeasures(file: stats.filename, count: stats.emptyMeasureCount))
        }

        // Detect extreme pitch ranges
        for stats in scoreStats {
            if let low = stats.lowestPitch, let high = stats.highestPitch {
                // Flag if range exceeds 6 octaves (72 semitones) or if very extreme notes
                if high - low > 72 || low < 12 || high > 120 {
                    anomalies.append(.extremePitchRange(file: stats.filename, low: low, high: high))
                }
            }
        }

        // Check for suspicious duration dominance
        let totalDurations = corpus.durationDistribution.values.reduce(0, +)
        if totalDurations > 0 {
            for (duration, count) in corpus.durationDistribution {
                let ratio = Double(count) / Double(totalDurations)
                // Flag if any single duration type is more than 80%
                if ratio > 0.8 {
                    anomalies.append(.suspiciousDurationRatio(dominant: duration, ratio: ratio))
                }
            }
        }

        return anomalies
    }

    private func meanAndStdDev(_ values: [Double]) -> (mean: Double, stdDev: Double)? {
        guard !values.isEmpty else { return nil }

        let mean = values.reduce(0, +) / Double(values.count)

        guard values.count > 1 else { return (mean, 0) }

        let sumSquaredDiffs = values.map { pow($0 - mean, 2) }.reduce(0, +)
        let variance = sumSquaredDiffs / Double(values.count - 1)
        let stdDev = sqrt(variance)

        return (mean, stdDev)
    }

    private func pitchToMIDI(_ pitch: Pitch) -> Int {
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

        // MIDI note number: (octave + 1) * 12 + step + alter
        return (pitch.octave + 1) * 12 + stepValue + Int(pitch.alter)
    }
}
