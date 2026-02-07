import Foundation
import MusicNotationCore

/// Slices a continuous stream of notes into measures using time signature boundaries.
struct MeasureSlicer {

    let attributesMapper: AttributesMapper
    let quantizer: TickQuantizer
    let divisions: Int

    /// Computes measure boundaries from the time signature map.
    /// Returns an array of (startTick, endTick, timeSigEntry) tuples.
    func computeMeasureBoundaries(totalTicks: Int) -> [(start: Int, end: Int, timeSig: AttributesMapper.TimeSigEntry)] {
        var boundaries: [(start: Int, end: Int, timeSig: AttributesMapper.TimeSigEntry)] = []
        var currentTick = 0

        while currentTick < totalTicks {
            let timeSig = attributesMapper.timeSignature(at: currentTick)
            let ticksPerMeasure = measureTicks(numerator: timeSig.numerator, denominator: timeSig.denominator)

            let endTick = min(currentTick + ticksPerMeasure, totalTicks)
            boundaries.append((start: currentTick, end: endTick, timeSig: timeSig))
            currentTick += ticksPerMeasure
        }

        // Ensure at least one measure
        if boundaries.isEmpty {
            let timeSig = attributesMapper.timeSigMap[0]
            let ticksPerMeasure = measureTicks(numerator: timeSig.numerator, denominator: timeSig.denominator)
            boundaries.append((start: 0, end: ticksPerMeasure, timeSig: timeSig))
        }

        return boundaries
    }

    /// Slices notes into measures, splitting tied notes across barlines and filling rests.
    func sliceIntoMeasures(
        notes: [(tick: Int, note: Note)],
        isPercussion: Bool
    ) -> [Measure] {
        let totalTicks = notes.last.map { $0.tick + ticksForNote($0.note) } ?? (quantizer.ticksPerQuarter * 4)
        let boundaries = computeMeasureBoundaries(totalTicks: totalTicks)
        var measures: [Measure] = []

        // Index into sorted notes
        var noteIndex = 0

        for (measureIndex, boundary) in boundaries.enumerated() {
            var elements: [MeasureElement] = []
            let measureNumber = "\(measureIndex + 1)"

            // Collect notes in voice groups for this measure
            var voice1Notes: [(tick: Int, note: Note)] = []
            var voice2Notes: [(tick: Int, note: Note)] = []

            while noteIndex < notes.count && notes[noteIndex].tick < boundary.end {
                let (tick, note) = notes[noteIndex]

                if tick >= boundary.start {
                    let noteDuration = ticksForNote(note)
                    let noteEnd = tick + noteDuration

                    if noteEnd <= boundary.end {
                        // Note fits entirely within this measure
                        if note.voice == 2 {
                            voice2Notes.append((tick: tick, note: note))
                        } else {
                            voice1Notes.append((tick: tick, note: note))
                        }
                    } else {
                        // Note crosses barline — split into tied pair
                        let firstDurationTicks = boundary.end - tick
                        let secondDurationTicks = noteEnd - boundary.end

                        let (firstBase, firstDots) = quantizer.quantizeDuration(firstDurationTicks)
                        let firstDur = Duration(base: firstBase, dots: firstDots)
                        let firstDivs = firstDur.divisions(perQuarter: divisions)

                        var firstNote = note
                        firstNote = Note(
                            noteType: note.noteType,
                            durationDivisions: firstDivs,
                            type: firstBase,
                            dots: firstDots,
                            voice: note.voice,
                            staff: note.staff,
                            isChordTone: note.isChordTone,
                            stemDirection: note.stemDirection,
                            notehead: note.notehead,
                            ties: [Tie(type: .start)]
                        )

                        if note.voice == 2 {
                            voice2Notes.append((tick: tick, note: firstNote))
                        } else {
                            voice1Notes.append((tick: tick, note: firstNote))
                        }

                        // The second part will be picked up in the next measure
                        let (secondBase, secondDots) = quantizer.quantizeDuration(secondDurationTicks)
                        let secondDur = Duration(base: secondBase, dots: secondDots)
                        let secondDivs = secondDur.divisions(perQuarter: divisions)

                        let secondNote = Note(
                            noteType: note.noteType,
                            durationDivisions: secondDivs,
                            type: secondBase,
                            dots: secondDots,
                            voice: note.voice,
                            staff: note.staff,
                            isChordTone: note.isChordTone,
                            stemDirection: note.stemDirection,
                            notehead: note.notehead,
                            ties: [Tie(type: .stop)]
                        )

                        // Insert into notes array for next measure processing
                        // We handle this by adding directly — this note starts at boundary.end
                        if note.voice == 2 {
                            voice2Notes.append((tick: boundary.end, note: secondNote))
                        } else {
                            voice1Notes.append((tick: boundary.end, note: secondNote))
                        }
                    }
                }

                noteIndex += 1
            }

            // Build elements: voice 1 notes with rests, then backup + voice 2 notes with rests
            let voice1Elements = buildVoiceElements(
                notes: voice1Notes,
                measureStart: boundary.start,
                measureEnd: boundary.end,
                voice: 1,
                isPercussion: isPercussion
            )
            elements.append(contentsOf: voice1Elements)

            if !voice2Notes.isEmpty {
                // Backup to start of measure
                let measureDivisions = Duration(
                    base: quantizer.quantizeDuration(boundary.end - boundary.start).base,
                    dots: quantizer.quantizeDuration(boundary.end - boundary.start).dots
                ).divisions(perQuarter: divisions)

                if measureDivisions > 0 {
                    elements.append(.backup(Backup(duration: measureDivisions)))
                }

                let voice2Elements = buildVoiceElements(
                    notes: voice2Notes,
                    measureStart: boundary.start,
                    measureEnd: boundary.end,
                    voice: 2,
                    isPercussion: isPercussion
                )
                elements.append(contentsOf: voice2Elements)
            }

            // Build attributes
            var attributes: MeasureAttributes?
            if measureIndex == 0 {
                attributes = attributesMapper.initialAttributes(
                    isPercussion: isPercussion,
                    divisions: divisions
                )
            } else {
                let prevBoundary = boundaries[measureIndex - 1]
                let prevTimeSig = attributesMapper.timeSignature(at: prevBoundary.start)
                let prevKeySig = attributesMapper.keySignature(at: prevBoundary.start)
                attributes = attributesMapper.attributesChange(
                    at: boundary.start,
                    previousTimeSig: prevTimeSig,
                    previousKeySig: prevKeySig
                )
            }

            let measure = Measure(
                number: measureNumber,
                elements: elements,
                attributes: attributes
            )
            measures.append(measure)
        }

        return measures
    }

    // MARK: - Helpers

    private func buildVoiceElements(
        notes: [(tick: Int, note: Note)],
        measureStart: Int,
        measureEnd: Int,
        voice: Int,
        isPercussion: Bool
    ) -> [MeasureElement] {
        var elements: [MeasureElement] = []
        var currentTick = measureStart

        let sortedNotes = notes.filter { $0.tick >= measureStart && $0.tick < measureEnd }
            .sorted { $0.tick < $1.tick }

        for (tick, note) in sortedNotes {
            // Fill gap with rest if needed
            if tick > currentTick {
                let restElements = buildRests(
                    fromTick: currentTick, toTick: tick,
                    voice: voice, isPercussion: isPercussion
                )
                elements.append(contentsOf: restElements)
            }

            elements.append(.note(note))
            if !note.isChordTone {
                currentTick = tick + ticksForNote(note)
            }
        }

        // Fill remaining time in measure with rests
        if currentTick < measureEnd {
            let restElements = buildRests(
                fromTick: currentTick, toTick: measureEnd,
                voice: voice, isPercussion: isPercussion
            )
            elements.append(contentsOf: restElements)
        }

        return elements
    }

    /// Builds rest notes to fill a gap between two tick positions.
    private func buildRests(
        fromTick: Int, toTick: Int,
        voice: Int, isPercussion: Bool
    ) -> [MeasureElement] {
        var elements: [MeasureElement] = []
        var remaining = toTick - fromTick
        guard remaining > 0 else { return elements }

        while remaining > 0 {
            let (base, dots) = quantizer.quantizeDuration(remaining)
            let actualTicks = quantizer.ticksFor(base: base, dots: dots)

            let dur = Duration(base: base, dots: dots)
            let divs = dur.divisions(perQuarter: divisions)

            let rest = Note(
                noteType: .rest(RestInfo()),
                durationDivisions: divs,
                type: base,
                dots: dots,
                voice: voice,
                staff: 1
            )
            elements.append(.note(rest))
            remaining -= actualTicks
        }

        return elements
    }

    /// Computes ticks for a note based on its duration.
    private func ticksForNote(_ note: Note) -> Int {
        if let base = note.type {
            return quantizer.ticksFor(base: base, dots: note.dots)
        }
        return quantizer.ticksPerQuarter // Default to quarter note
    }

    /// Computes ticks per measure for a given time signature.
    private func measureTicks(numerator: Int, denominator: Int) -> Int {
        // ticks per whole note = tpq * 4
        // ticks per beat = tpq * 4 / denominator
        // ticks per measure = ticks per beat * numerator
        let ticksPerWhole = quantizer.ticksPerQuarter * 4
        return ticksPerWhole * numerator / denominator
    }
}
