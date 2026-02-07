import Foundation
import MusicNotationCore

/// Pairs MIDI note-on/off events and builds `Note` objects.
struct NoteMapper {

    /// An intermediate representation of a note span in tick space.
    struct NoteSpan {
        let startTick: Int
        let endTick: Int
        let noteNumber: UInt8
        let velocity: UInt8
        let channel: UInt8
    }

    let quantizer: TickQuantizer
    let options: MIDIImportOptions

    // MARK: - Note-On/Off Pairing

    /// Pairs note-on/off events into NoteSpans.
    func pairNotes(events: [MIDITrackEvent]) -> [NoteSpan] {
        // Track pending note-ons: (channel, noteNumber) -> (tick, velocity)
        var pending: [UInt16: (tick: Int, velocity: UInt8)] = [:]
        var spans: [NoteSpan] = []

        for event in events {
            switch event.event {
            case .noteOn(let ch, let note, let vel):
                let key = Self.noteKey(channel: ch, note: note)
                // If there's already a pending note-on for this key, close it first
                if let existing = pending[key] {
                    spans.append(NoteSpan(
                        startTick: existing.tick,
                        endTick: event.absoluteTick,
                        noteNumber: note,
                        velocity: existing.velocity,
                        channel: ch
                    ))
                }
                pending[key] = (tick: event.absoluteTick, velocity: vel)

            case .noteOff(let ch, let note, _):
                let key = Self.noteKey(channel: ch, note: note)
                if let existing = pending[key] {
                    spans.append(NoteSpan(
                        startTick: existing.tick,
                        endTick: event.absoluteTick,
                        noteNumber: note,
                        velocity: existing.velocity,
                        channel: ch
                    ))
                    pending.removeValue(forKey: key)
                }

            default:
                break
            }
        }

        // Close any remaining pending notes at their start tick (zero-duration)
        for (key, info) in pending {
            let note = UInt8(key & 0xFF)
            let channel = UInt8(key >> 8)
            spans.append(NoteSpan(
                startTick: info.tick,
                endTick: info.tick + quantizer.ticksPerQuarter, // Default to quarter note
                noteNumber: note,
                velocity: info.velocity,
                channel: channel
            ))
        }

        return spans.sorted { $0.startTick < $1.startTick }
    }

    // MARK: - Build Notes (Pitched)

    /// Builds pitched `Note` objects from note spans.
    func buildPitchedNotes(spans: [NoteSpan], divisions: Int) -> [(tick: Int, note: Note)] {
        var results: [(tick: Int, note: Note)] = []

        // Group by quantized start tick for chord detection
        let grouped = groupByStartTick(spans)

        for (quantizedTick, group) in grouped {
            for (index, span) in group.enumerated() {
                let pitch = Pitch(midiNoteNumber: Int(span.noteNumber))
                let durationTicks = max(1, span.endTick - span.startTick)
                let (base, dots) = quantizer.quantizeDuration(durationTicks)
                let dur = Duration(base: base, dots: dots)
                let divs = dur.divisions(perQuarter: divisions)

                let isGhostNote = span.velocity < options.ghostNoteVelocityThreshold
                let notehead: NoteheadInfo? = isGhostNote
                    ? NoteheadInfo(type: .normal, parentheses: true)
                    : nil

                let note = Note(
                    noteType: .pitched(pitch),
                    durationDivisions: divs,
                    type: base,
                    dots: dots,
                    voice: 1,
                    staff: 1,
                    isChordTone: index > 0,
                    notehead: notehead
                )

                results.append((tick: quantizedTick, note: note))
            }
        }

        return results
    }

    // MARK: - Build Notes (Percussion)

    /// Builds percussion `Note` objects from note spans using the percussion map.
    func buildPercussionNotes(
        spans: [NoteSpan],
        percussionMap: PercussionMap,
        divisions: Int
    ) -> [(tick: Int, note: Note)] {
        var results: [(tick: Int, note: Note)] = []

        // Group by quantized start tick for chord detection
        let grouped = groupByStartTick(spans)

        for (quantizedTick, group) in grouped {
            // Separate into voice 1 (stems up) and voice 2 (stems down)
            var voice1Notes: [(NoteSpan, PercussionMapEntry)] = []
            var voice2Notes: [(NoteSpan, PercussionMapEntry)] = []

            for span in group {
                if let entry = percussionMap.entry(forMidiNote: span.noteNumber) {
                    if entry.stemDirection == .down {
                        voice2Notes.append((span, entry))
                    } else {
                        voice1Notes.append((span, entry))
                    }
                } else {
                    // Unmapped percussion note — put in voice 1 with default mapping
                    let defaultEntry = PercussionMapEntry(
                        displayStep: .c, displayOctave: 5,
                        instrument: .snareDrum,
                        notehead: .normal,
                        midiNote: span.noteNumber,
                        stemDirection: .up
                    )
                    voice1Notes.append((span, defaultEntry))
                }
            }

            // Build voice 1 notes
            for (index, (span, entry)) in voice1Notes.enumerated() {
                let note = buildPercussionNote(
                    span: span, entry: entry,
                    voice: 1, isChordTone: index > 0,
                    divisions: divisions
                )
                results.append((tick: quantizedTick, note: note))
            }

            // Build voice 2 notes
            for (index, (span, entry)) in voice2Notes.enumerated() {
                let note = buildPercussionNote(
                    span: span, entry: entry,
                    voice: 2, isChordTone: index > 0,
                    divisions: divisions
                )
                results.append((tick: quantizedTick, note: note))
            }
        }

        return results
    }

    // MARK: - Helpers

    private func buildPercussionNote(
        span: NoteSpan,
        entry: PercussionMapEntry,
        voice: Int,
        isChordTone: Bool,
        divisions: Int
    ) -> Note {
        let durationTicks = max(1, span.endTick - span.startTick)
        let (base, dots) = quantizer.quantizeDuration(durationTicks)
        let dur = Duration(base: base, dots: dots)
        let divs = dur.divisions(perQuarter: divisions)

        let isGhostNote = span.velocity < options.ghostNoteVelocityThreshold

        let unpitched = UnpitchedNote(
            displayStep: entry.displayStep,
            displayOctave: entry.displayOctave,
            instrumentId: entry.instrument.rawValue,
            percussionInstrument: entry.instrument,
            noteheadOverride: isGhostNote ? .ghost : entry.notehead
        )

        let noteheadType: NoteheadType = switch entry.notehead {
        case .x: .x
        case .circleX: .circleX
        case .diamond: .diamond
        case .triangle: .triangle
        case .plus: .cross
        case .ghost: .normal
        case .slash: .slash
        default: .normal
        }

        let noteheadInfo: NoteheadInfo? = isGhostNote
            ? NoteheadInfo(type: noteheadType, parentheses: true)
            : (noteheadType != .normal ? NoteheadInfo(type: noteheadType) : nil)

        return Note(
            noteType: .unpitched(unpitched),
            durationDivisions: divs,
            type: base,
            dots: dots,
            voice: voice,
            staff: 1,
            isChordTone: isChordTone,
            stemDirection: entry.stemDirection,
            notehead: noteheadInfo
        )
    }

    /// Groups note spans by their quantized start tick.
    private func groupByStartTick(_ spans: [NoteSpan]) -> [(tick: Int, spans: [NoteSpan])] {
        var dict: [Int: [NoteSpan]] = [:]
        for span in spans {
            let quantizedTick = quantizer.quantizePosition(span.startTick)
            dict[quantizedTick, default: []].append(span)
        }
        return dict.keys.sorted().map { tick in
            (tick: tick, spans: dict[tick]!)
        }
    }

    /// Creates a unique key for a (channel, note) pair.
    private static func noteKey(channel: UInt8, note: UInt8) -> UInt16 {
        UInt16(channel) << 8 | UInt16(note)
    }
}
