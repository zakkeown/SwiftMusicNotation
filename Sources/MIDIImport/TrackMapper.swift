import Foundation
import MusicNotationCore

/// Groups MIDI tracks by channel, detects percussion, and names parts.
struct TrackMapper {

    /// A logical channel group extracted from MIDI tracks.
    struct ChannelGroup {
        /// The MIDI channel (0-indexed).
        let channel: UInt8
        /// Whether this is the percussion channel (channel 9, 0-indexed).
        let isPercussion: Bool
        /// The resolved part name.
        let name: String
        /// The GM program number, if a program change was found.
        let program: UInt8?
        /// All events belonging to this channel group.
        let events: [MIDITrackEvent]
    }

    let options: MIDIImportOptions

    /// Groups MIDI file tracks into channel groups for conversion to Parts.
    func mapTracks(file: MIDIFile) -> [ChannelGroup] {
        switch file.format {
        case 0:
            return mapFormat0(file.tracks)
        default:
            return mapFormat1(file.tracks)
        }
    }

    // MARK: - Format 0

    /// Format 0: single track — split by channel.
    private func mapFormat0(_ tracks: [MIDITrack]) -> [ChannelGroup] {
        guard let track = tracks.first else { return [] }
        return splitByChannel(events: track.events)
    }

    // MARK: - Format 1

    /// Format 1: track 0 is tempo/meta, tracks 1+ are instruments.
    /// If mergeTracksByChannel is true, events from different tracks on the same channel are merged.
    private func mapFormat1(_ tracks: [MIDITrack]) -> [ChannelGroup] {
        if options.mergeTracksByChannel {
            // Collect all events from all tracks (except pure meta-only track 0)
            var allEvents: [MIDITrackEvent] = []
            var trackNames: [Int: String] = [:]

            for (index, track) in tracks.enumerated() {
                // Capture track names
                for event in track.events {
                    if case .trackName(let name) = event.event {
                        trackNames[index] = name
                        break
                    }
                }

                // Include all events from all tracks (meta events from track 0 are
                // needed by AttributesMapper, channel events from tracks 1+ are the notes)
                allEvents.append(contentsOf: track.events)
            }

            var groups = splitByChannel(events: allEvents)

            // Try to apply track names to groups
            for (index, track) in tracks.enumerated() where index > 0 {
                if let name = trackNames[index] {
                    // Find which channel this track primarily uses
                    let primaryChannel = findPrimaryChannel(in: track.events)
                    if let ch = primaryChannel,
                       let groupIndex = groups.firstIndex(where: { $0.channel == ch }) {
                        let group = groups[groupIndex]
                        groups[groupIndex] = ChannelGroup(
                            channel: group.channel,
                            isPercussion: group.isPercussion,
                            name: name,
                            program: group.program,
                            events: group.events
                        )
                    }
                }
            }

            return groups
        } else {
            // Each track becomes its own group
            var groups: [ChannelGroup] = []
            for (index, track) in tracks.enumerated() {
                // Skip track 0 if it has no note events (pure tempo/meta track)
                let hasNotes = track.events.contains { event in
                    if case .noteOn = event.event { return true }
                    return false
                }
                guard hasNotes else { continue }

                let channel = findPrimaryChannel(in: track.events) ?? 0
                let isPercussion = channel == 9

                let name = findTrackName(in: track.events)
                    ?? findProgramName(in: track.events)
                    ?? (isPercussion ? "Drums" : "Track \(index)")

                let program = findProgram(in: track.events)

                groups.append(ChannelGroup(
                    channel: channel,
                    isPercussion: isPercussion,
                    name: name,
                    program: program,
                    events: track.events
                ))
            }
            return groups
        }
    }

    // MARK: - Split by Channel

    private func splitByChannel(events: [MIDITrackEvent]) -> [ChannelGroup] {
        var channelEvents: [UInt8: [MIDITrackEvent]] = [:]
        var channelPrograms: [UInt8: UInt8] = [:]
        let channelNames: [UInt8: String] = [:]

        for event in events {
            let channel: UInt8?
            switch event.event {
            case .noteOn(let ch, _, _), .noteOff(let ch, _, _):
                channel = ch
            case .programChange(let ch, let prog):
                channel = ch
                channelPrograms[ch] = prog
            case .controlChange(let ch, _, _):
                channel = ch
            default:
                channel = nil
            }

            if let ch = channel {
                channelEvents[ch, default: []].append(event)
            }
        }

        // Build groups for channels that have note events
        return channelEvents.keys.sorted().compactMap { channel in
            let events = channelEvents[channel]!
            let hasNotes = events.contains { event in
                if case .noteOn = event.event { return true }
                return false
            }
            guard hasNotes else { return nil }

            let isPercussion = channel == 9
            let program = channelPrograms[channel]

            let name = channelNames[channel]
                ?? program.map { GMProgramMap.instrumentName(forProgram: $0) }
                ?? (isPercussion ? "Drums" : "Channel \(channel + 1)")

            return ChannelGroup(
                channel: channel,
                isPercussion: isPercussion,
                name: name,
                program: program,
                events: events
            )
        }
    }

    // MARK: - Helpers

    private func findPrimaryChannel(in events: [MIDITrackEvent]) -> UInt8? {
        var channelCounts: [UInt8: Int] = [:]
        for event in events {
            switch event.event {
            case .noteOn(let ch, _, _): channelCounts[ch, default: 0] += 1
            default: break
            }
        }
        return channelCounts.max(by: { $0.value < $1.value })?.key
    }

    private func findTrackName(in events: [MIDITrackEvent]) -> String? {
        for event in events {
            if case .trackName(let name) = event.event, !name.isEmpty {
                return name
            }
        }
        return nil
    }

    private func findProgramName(in events: [MIDITrackEvent]) -> String? {
        if let program = findProgram(in: events) {
            return GMProgramMap.instrumentName(forProgram: program)
        }
        return nil
    }

    private func findProgram(in events: [MIDITrackEvent]) -> UInt8? {
        for event in events {
            if case .programChange(_, let program) = event.event {
                return program
            }
        }
        return nil
    }
}
