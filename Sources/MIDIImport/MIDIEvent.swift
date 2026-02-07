import Foundation

/// A parsed Standard MIDI File.
public struct MIDIFile: Sendable {
    /// MIDI format: 0 (single track) or 1 (multi-track).
    public let format: Int
    /// The number of tracks in the file.
    public let trackCount: Int
    /// The time division (ticks per unit).
    public let timeDivision: TimeDivision
    /// The parsed tracks.
    public let tracks: [MIDITrack]
}

/// How MIDI tick values relate to musical time.
public enum TimeDivision: Sendable {
    /// Ticks per quarter note (most common).
    case ticksPerQuarter(Int)
    /// SMPTE-based time division.
    case smpte(framesPerSecond: Int, ticksPerFrame: Int)
}

/// A single MIDI track containing a sequence of events.
public struct MIDITrack: Sendable {
    /// The events in this track, sorted by absolute tick position.
    public let events: [MIDITrackEvent]
}

/// An event at a specific absolute tick position within a track.
public struct MIDITrackEvent: Sendable {
    /// The absolute tick position of this event (accumulated from deltas).
    public let absoluteTick: Int
    /// The event data.
    public let event: MIDIEventType
}

/// The type of a MIDI event.
public enum MIDIEventType: Sendable {
    // MARK: - Channel Voice Messages

    /// Note-on event.
    case noteOn(channel: UInt8, note: UInt8, velocity: UInt8)
    /// Note-off event.
    case noteOff(channel: UInt8, note: UInt8, velocity: UInt8)
    /// Program change (instrument selection).
    case programChange(channel: UInt8, program: UInt8)
    /// Control change.
    case controlChange(channel: UInt8, controller: UInt8, value: UInt8)
    /// Pitch bend.
    case pitchBend(channel: UInt8, value: UInt16)
    /// Polyphonic aftertouch.
    case polyAftertouch(channel: UInt8, note: UInt8, pressure: UInt8)
    /// Channel aftertouch.
    case channelAftertouch(channel: UInt8, pressure: UInt8)

    // MARK: - Meta Events

    /// Tempo in microseconds per quarter note.
    case tempo(microsecondsPerQuarter: Int)
    /// Time signature.
    case timeSignature(numerator: UInt8, denominator: UInt8, clocksPerClick: UInt8, thirtySecondNotesPerQuarter: UInt8)
    /// Key signature.
    case keySignature(sharpsFlats: Int8, isMinor: Bool)
    /// Track name.
    case trackName(String)
    /// End of track marker.
    case endOfTrack
    /// Text event.
    case text(String)
    /// Copyright notice.
    case copyright(String)
    /// Instrument name.
    case instrumentName(String)
    /// Marker text.
    case marker(String)
    /// Cue point.
    case cuePoint(String)
    /// Sequence/track number.
    case sequenceNumber(UInt16)
    /// MIDI channel prefix.
    case channelPrefix(UInt8)
    /// Unknown or unsupported meta event.
    case unknownMeta(type: UInt8, data: Data)

    // MARK: - System Events

    /// System exclusive message.
    case sysEx(Data)
}
