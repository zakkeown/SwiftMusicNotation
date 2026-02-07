import Foundation
import MusicNotationCore

/// Extracts tempo, time signature, and key signature maps from MIDI meta events.
struct AttributesMapper {

    /// A tempo change at a given tick.
    struct TempoEntry {
        let tick: Int
        /// BPM (beats per minute).
        let bpm: Double
        /// Microseconds per quarter note.
        let microsecondsPerQuarter: Int
    }

    /// A time signature change at a given tick.
    struct TimeSigEntry {
        let tick: Int
        let numerator: Int
        let denominator: Int
    }

    /// A key signature change at a given tick.
    struct KeySigEntry {
        let tick: Int
        let fifths: Int
        let isMinor: Bool
    }

    /// Sorted tempo changes.
    let tempoMap: [TempoEntry]
    /// Sorted time signature changes.
    let timeSigMap: [TimeSigEntry]
    /// Sorted key signature changes.
    let keySigMap: [KeySigEntry]

    /// Scans all tracks for meta events and builds sorted maps.
    init(tracks: [MIDITrack]) {
        var tempos: [TempoEntry] = []
        var timeSigs: [TimeSigEntry] = []
        var keySigs: [KeySigEntry] = []

        for track in tracks {
            for event in track.events {
                switch event.event {
                case .tempo(let usPerQuarter):
                    let bpm = 60_000_000.0 / Double(usPerQuarter)
                    tempos.append(TempoEntry(
                        tick: event.absoluteTick,
                        bpm: bpm,
                        microsecondsPerQuarter: usPerQuarter
                    ))

                case .timeSignature(let num, let denom, _, _):
                    timeSigs.append(TimeSigEntry(
                        tick: event.absoluteTick,
                        numerator: Int(num),
                        denominator: Int(denom)
                    ))

                case .keySignature(let sf, let isMinor):
                    keySigs.append(KeySigEntry(
                        tick: event.absoluteTick,
                        fifths: Int(sf),
                        isMinor: isMinor
                    ))

                default:
                    break
                }
            }
        }

        // Sort by tick and deduplicate
        tempos.sort { $0.tick < $1.tick }
        timeSigs.sort { $0.tick < $1.tick }
        keySigs.sort { $0.tick < $1.tick }

        // Default values if none found
        if tempos.isEmpty {
            tempos = [TempoEntry(tick: 0, bpm: 120.0, microsecondsPerQuarter: 500_000)]
        }
        if timeSigs.isEmpty {
            timeSigs = [TimeSigEntry(tick: 0, numerator: 4, denominator: 4)]
        }

        self.tempoMap = tempos
        self.timeSigMap = timeSigs
        self.keySigMap = keySigs
    }

    /// Returns the time signature active at the given tick.
    func timeSignature(at tick: Int) -> TimeSigEntry {
        var result = timeSigMap[0]
        for entry in timeSigMap {
            if entry.tick <= tick {
                result = entry
            } else {
                break
            }
        }
        return result
    }

    /// Returns the tempo (BPM) active at the given tick.
    func tempo(at tick: Int) -> TempoEntry {
        var result = tempoMap[0]
        for entry in tempoMap {
            if entry.tick <= tick {
                result = entry
            } else {
                break
            }
        }
        return result
    }

    /// Returns the key signature active at the given tick.
    func keySignature(at tick: Int) -> KeySigEntry? {
        var result: KeySigEntry?
        for entry in keySigMap {
            if entry.tick <= tick {
                result = entry
            } else {
                break
            }
        }
        return result
    }

    /// Builds `MeasureAttributes` for the first measure of a part.
    func initialAttributes(isPercussion: Bool, divisions: Int) -> MeasureAttributes {
        let timeSig = timeSigMap[0]
        let keySig = keySigMap.first

        var keySignatures: [KeySignature] = []
        if let ks = keySig {
            keySignatures.append(KeySignature(
                fifths: ks.fifths,
                mode: ks.isMinor ? .minor : .major
            ))
        } else if !isPercussion {
            keySignatures.append(.cMajor)
        }

        let clefs: [Clef] = [isPercussion ? .percussion : .treble]

        return MeasureAttributes(
            divisions: divisions,
            keySignatures: keySignatures,
            timeSignatures: [TimeSignature(
                beats: "\(timeSig.numerator)",
                beatType: "\(timeSig.denominator)"
            )],
            clefs: clefs
        )
    }

    /// Builds `MeasureAttributes` for a measure at the given tick, if attributes changed.
    func attributesChange(at tick: Int, previousTimeSig: TimeSigEntry?, previousKeySig: KeySigEntry?) -> MeasureAttributes? {
        let currentTimeSig = timeSignature(at: tick)
        let currentKeySig = keySignature(at: tick)

        let timeSigChanged = previousTimeSig.map {
            $0.numerator != currentTimeSig.numerator || $0.denominator != currentTimeSig.denominator
        } ?? true

        let keySigChanged: Bool
        if let prev = previousKeySig, let curr = currentKeySig {
            keySigChanged = prev.fifths != curr.fifths || prev.isMinor != curr.isMinor
        } else {
            keySigChanged = previousKeySig != nil || currentKeySig != nil
        }

        guard timeSigChanged || keySigChanged else { return nil }

        var attrs = MeasureAttributes()
        if timeSigChanged {
            attrs.timeSignatures = [TimeSignature(
                beats: "\(currentTimeSig.numerator)",
                beatType: "\(currentTimeSig.denominator)"
            )]
        }
        if keySigChanged, let ks = currentKeySig {
            attrs.keySignatures = [KeySignature(
                fifths: ks.fifths,
                mode: ks.isMinor ? .minor : .major
            )]
        }
        return attrs
    }
}
