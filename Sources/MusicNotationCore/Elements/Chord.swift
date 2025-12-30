import Foundation

/// A chord is a collection of notes played simultaneously.
/// All notes in a chord share the same onset time and typically share a stem.
public struct Chord: Identifiable, Sendable {
    /// Unique identifier for this chord.
    public let id: UUID

    /// The notes in this chord, sorted by pitch (lowest to highest).
    public private(set) var notes: [Note]

    /// Voice assignment.
    public var voice: Int

    /// Staff assignment.
    public var staff: Int

    /// Shared stem direction for the chord.
    public var stemDirection: StemDirection?

    /// Duration in divisions (shared by all notes).
    public var durationDivisions: Int {
        notes.first?.durationDivisions ?? 0
    }

    /// The visual note type (shared by all notes).
    public var type: DurationBase? {
        notes.first?.type
    }

    /// Number of augmentation dots (shared by all notes).
    public var dots: Int {
        notes.first?.dots ?? 0
    }

    /// Creates a new chord from an array of notes.
    /// Notes are automatically sorted by pitch.
    public init(
        id: UUID = UUID(),
        notes: [Note],
        voice: Int = 1,
        staff: Int = 1,
        stemDirection: StemDirection? = nil
    ) {
        self.id = id
        self.notes = notes.sorted { note1, note2 in
            guard let pitch1 = note1.pitch, let pitch2 = note2.pitch else {
                return false
            }
            return pitch1.midiNoteNumber < pitch2.midiNoteNumber
        }
        self.voice = voice
        self.staff = staff
        self.stemDirection = stemDirection
    }

    /// Creates a chord from a single note (for consistency in processing).
    public init(note: Note) {
        self.id = UUID()
        self.notes = [note]
        self.voice = note.voice
        self.staff = note.staff
        self.stemDirection = note.stemDirection
    }

    // MARK: - Pitch Access

    /// The lowest note in the chord.
    public var lowestNote: Note? {
        notes.first
    }

    /// The highest note in the chord.
    public var highestNote: Note? {
        notes.last
    }

    /// The lowest pitch in the chord.
    public var lowestPitch: Pitch? {
        lowestNote?.pitch
    }

    /// The highest pitch in the chord.
    public var highestPitch: Pitch? {
        highestNote?.pitch
    }

    /// All pitches in the chord, sorted low to high.
    public var pitches: [Pitch] {
        notes.compactMap { $0.pitch }
    }

    /// The interval span of the chord in semitones.
    public var span: Int? {
        guard let low = lowestPitch, let high = highestPitch else { return nil }
        return high.midiNoteNumber - low.midiNoteNumber
    }

    // MARK: - Note Management

    /// Adds a note to the chord, maintaining pitch order.
    public mutating func addNote(_ note: Note) {
        notes.append(note)
        notes.sort { note1, note2 in
            guard let pitch1 = note1.pitch, let pitch2 = note2.pitch else {
                return false
            }
            return pitch1.midiNoteNumber < pitch2.midiNoteNumber
        }
    }

    /// Removes a note from the chord by ID.
    @discardableResult
    public mutating func removeNote(withId id: UUID) -> Note? {
        guard let index = notes.firstIndex(where: { $0.id == id }) else {
            return nil
        }
        return notes.remove(at: index)
    }

    /// Returns the note at the given pitch, if any.
    public func note(at pitch: Pitch) -> Note? {
        notes.first { $0.pitch == pitch }
    }

    // MARK: - Stem Calculations

    /// Calculates the optimal stem direction based on note positions.
    /// Returns .down if the average pitch is above middle line, .up otherwise.
    public func optimalStemDirection(middleLinePitch: Pitch = Pitch(step: .b, octave: 4)) -> StemDirection {
        guard !notes.isEmpty else { return .up }

        let middleMidi = middleLinePitch.midiNoteNumber
        let avgMidi = pitches.reduce(0) { $0 + $1.midiNoteNumber } / pitches.count

        return avgMidi >= middleMidi ? .down : .up
    }

    /// Determines if noteheads need to be offset (seconds in the chord).
    /// Returns pairs of note indices that form seconds.
    public var secondsRequiringOffset: [(Int, Int)] {
        var seconds: [(Int, Int)] = []

        for i in 0..<(notes.count - 1) {
            guard let pitch1 = notes[i].pitch,
                  let pitch2 = notes[i + 1].pitch else { continue }

            let interval = pitch2.midiNoteNumber - pitch1.midiNoteNumber
            // A second is 1-2 semitones
            if interval <= 2 {
                seconds.append((i, i + 1))
            }
        }

        return seconds
    }

    /// Whether this chord contains any seconds (adjacent notes requiring offset).
    public var containsSeconds: Bool {
        !secondsRequiringOffset.isEmpty
    }

    // MARK: - Chord Properties

    /// Number of notes in the chord.
    public var noteCount: Int {
        notes.count
    }

    /// Whether this is actually a single note (not a chord).
    public var isSingleNote: Bool {
        notes.count == 1
    }

    /// Whether all notes have the same accidental display.
    public var hasUniformAccidentals: Bool {
        let accidentals = notes.compactMap { $0.accidental?.accidental }
        guard let first = accidentals.first else { return true }
        return accidentals.allSatisfy { $0 == first }
    }

    /// Gets all accidentals that need to be displayed for this chord.
    public var displayedAccidentals: [(noteIndex: Int, accidental: AccidentalMark)] {
        notes.enumerated().compactMap { index, note in
            guard let acc = note.accidental else { return nil }
            return (index, acc)
        }
    }
}

// MARK: - Chord Interval Analysis

extension Chord {
    /// The intervals between adjacent notes in semitones.
    public var intervals: [Int] {
        guard pitches.count > 1 else { return [] }

        var result: [Int] = []
        for i in 0..<(pitches.count - 1) {
            result.append(pitches[i + 1].midiNoteNumber - pitches[i].midiNoteNumber)
        }
        return result
    }

    /// Whether this chord is in close position (all intervals within an octave).
    public var isClosePosition: Bool {
        guard let spanValue = span else { return true }
        return spanValue <= 12
    }

    /// Whether this chord is in open position (spans more than an octave).
    public var isOpenPosition: Bool {
        guard let spanValue = span else { return false }
        return spanValue > 12
    }
}

// MARK: - Chord Building Helpers

extension Chord {
    /// Creates a chord from pitches with shared properties.
    public static func fromPitches(
        _ pitches: [Pitch],
        durationDivisions: Int,
        type: DurationBase?,
        dots: Int = 0,
        voice: Int = 1,
        staff: Int = 1
    ) -> Chord {
        let notes = pitches.enumerated().map { index, pitch in
            Note(
                noteType: .pitched(pitch),
                durationDivisions: durationDivisions,
                type: type,
                dots: dots,
                voice: voice,
                staff: staff,
                isChordTone: index > 0
            )
        }
        return Chord(notes: notes, voice: voice, staff: staff)
    }

    /// Creates a major triad from a root pitch.
    public static func majorTriad(
        root: Pitch,
        durationDivisions: Int,
        type: DurationBase?,
        voice: Int = 1,
        staff: Int = 1
    ) -> Chord {
        let third = root.transposed(by: 4)  // Major third
        let fifth = root.transposed(by: 7)  // Perfect fifth
        return fromPitches([root, third, fifth], durationDivisions: durationDivisions, type: type, voice: voice, staff: staff)
    }

    /// Creates a minor triad from a root pitch.
    public static func minorTriad(
        root: Pitch,
        durationDivisions: Int,
        type: DurationBase?,
        voice: Int = 1,
        staff: Int = 1
    ) -> Chord {
        let third = root.transposed(by: 3)  // Minor third
        let fifth = root.transposed(by: 7)  // Perfect fifth
        return fromPitches([root, third, fifth], durationDivisions: durationDivisions, type: type, voice: voice, staff: staff)
    }
}

// MARK: - Pitch Transposition Helper

extension Pitch {
    /// Returns a new pitch transposed by the given number of semitones.
    func transposed(by semitones: Int) -> Pitch {
        let newMidi = midiNoteNumber + semitones
        return Pitch(midiNoteNumber: newMidi)
    }
}
