import Foundation
import MusicNotationCore

/// Options controlling MIDI import behavior.
public struct MIDIImportOptions: Sendable {
    /// The smallest note duration to quantize to (default: sixteenth note).
    public var quantizationResolution: DurationBase

    /// Whether to use the extended drum kit map with additional instruments.
    public var useExtendedDrumKit: Bool

    /// Whether to merge tracks that share the same MIDI channel.
    public var mergeTracksByChannel: Bool

    /// Velocity threshold below which notes are treated as ghost notes (default: 40).
    public var ghostNoteVelocityThreshold: UInt8

    /// Whether to import tempo changes as direction elements.
    public var importTempoChanges: Bool

    public init(
        quantizationResolution: DurationBase = .sixteenth,
        useExtendedDrumKit: Bool = false,
        mergeTracksByChannel: Bool = true,
        ghostNoteVelocityThreshold: UInt8 = 40,
        importTempoChanges: Bool = true
    ) {
        self.quantizationResolution = quantizationResolution
        self.useExtendedDrumKit = useExtendedDrumKit
        self.mergeTracksByChannel = mergeTracksByChannel
        self.ghostNoteVelocityThreshold = ghostNoteVelocityThreshold
        self.importTempoChanges = importTempoChanges
    }
}

/// Imports Standard MIDI Files (.mid) and produces `Score` objects.
///
/// ## Usage
///
/// ```swift
/// let importer = MIDIImporter()
/// let score = try importer.importScore(from: midiFileURL)
/// ```
public final class MIDIImporter: @unchecked Sendable {

    /// Options controlling import behavior.
    public var options: MIDIImportOptions

    /// Warnings generated during the last import.
    public private(set) var warnings: [MIDIWarning] = []

    /// Creates a MIDI importer with the given options.
    public init(options: MIDIImportOptions = MIDIImportOptions()) {
        self.options = options
    }

    /// Imports a Score from a MIDI file at the given URL.
    public func importScore(from url: URL) throws -> Score {
        let data: Data
        do {
            data = try Data(contentsOf: url)
        } catch {
            throw MIDIError.fileReadError(url)
        }
        return try importScore(from: data)
    }

    /// Imports a Score from raw MIDI data.
    public func importScore(from data: Data) throws -> Score {
        warnings = []

        // Step 1: Parse binary MIDI data
        let parser = MIDIFileParser()
        let midiFile = try parser.parse(data)

        guard !midiFile.tracks.isEmpty else {
            throw MIDIError.noTracks
        }

        // Resolve ticks-per-quarter
        let tpq: Int
        switch midiFile.timeDivision {
        case .ticksPerQuarter(let value):
            tpq = value
        case .smpte:
            throw MIDIError.unsupportedTimeDivision
        }

        // Step 2: Build attribute maps (tempo, time sig, key sig)
        let attributesMapper = AttributesMapper(tracks: midiFile.tracks)

        // Step 3: Group tracks into channel groups
        let trackMapper = TrackMapper(options: options)
        let channelGroups = trackMapper.mapTracks(file: midiFile)

        guard !channelGroups.isEmpty else {
            throw MIDIError.noNotes
        }

        // Step 4: Build quantizer
        let quantizer = TickQuantizer(
            ticksPerQuarter: tpq,
            resolution: options.quantizationResolution
        )

        // Divisions per quarter note — use tpq for maximum precision
        let divisions = tpq

        // Step 5: Build parts
        let noteMapper = NoteMapper(quantizer: quantizer, options: options)
        let slicer = MeasureSlicer(
            attributesMapper: attributesMapper,
            quantizer: quantizer,
            divisions: divisions
        )

        var parts: [Part] = []

        for (index, group) in channelGroups.enumerated() {
            let partId = "P\(index + 1)"

            // Pair note-on/off events
            let spans = noteMapper.pairNotes(events: group.events)

            guard !spans.isEmpty else {
                warnings.append(MIDIWarning(
                    message: "Track '\(group.name)' has no note events, skipping.",
                    track: index
                ))
                continue
            }

            // Build Note objects
            let timedNotes: [(tick: Int, note: Note)]
            let percussionMap: PercussionMap?

            if group.isPercussion {
                let drumMap = options.useExtendedDrumKit
                    ? PercussionMap.extendedDrumKit
                    : PercussionMap.standardDrumKit
                timedNotes = noteMapper.buildPercussionNotes(
                    spans: spans,
                    percussionMap: drumMap,
                    divisions: divisions
                )
                percussionMap = drumMap
            } else {
                timedNotes = noteMapper.buildPitchedNotes(
                    spans: spans,
                    divisions: divisions
                )
                percussionMap = nil
            }

            // Slice into measures
            let measures = slicer.sliceIntoMeasures(
                notes: timedNotes,
                isPercussion: group.isPercussion
            )

            // Build MIDI instrument info
            var midiInstruments: [MIDIInstrument] = []
            if let program = group.program {
                midiInstruments.append(MIDIInstrument(
                    midiChannel: Int(group.channel) + 1,
                    midiProgram: Int(program)
                ))
            } else if group.isPercussion {
                midiInstruments.append(MIDIInstrument(
                    midiChannel: 10,
                    midiProgram: 0
                ))
            }

            let part = Part(
                id: partId,
                name: group.name,
                measures: measures,
                midiInstruments: midiInstruments,
                percussionMap: percussionMap
            )

            parts.append(part)
        }

        guard !parts.isEmpty else {
            throw MIDIError.noNotes
        }

        // Step 6: Assemble Score
        let metadata = ScoreMetadata(
            workTitle: nil,
            encoding: EncodingInfo(software: ["SwiftMusicNotation MIDIImport"])
        )

        let score = Score(
            metadata: metadata,
            parts: parts
        )

        return score
    }
}
