#!/usr/bin/env python3
"""
Parse MusicXML file using music21 and output JSON for comparison.

Usage:
    python3 parse_musicxml.py input.xml output.json

Requires: pip install music21
"""

import json
import sys
import os


def extract_articulations(element):
    """Extract articulation names from a note or chord element."""
    articulations = []
    if hasattr(element, 'articulations'):
        for art in element.articulations:
            articulations.append(type(art).__name__)
    return articulations


def extract_expressions(element):
    """Extract expression names (ornaments, dynamics on notes) from an element."""
    expressions = []
    if hasattr(element, 'expressions'):
        for expr in element.expressions:
            expressions.append(type(expr).__name__)
    return expressions


def get_part_index(element, score):
    """Get the part index for an element."""
    try:
        for idx, part in enumerate(score.parts):
            if element in part.recurse():
                return idx
    except Exception:
        pass
    return None


def get_measure_number(element):
    """Get the measure number for an element."""
    try:
        measure = element.getContextByClass('Measure')
        if measure:
            return measure.number
    except Exception:
        pass
    return None


def extract_notes(xml_path):
    """Extract notes from a MusicXML file using music21."""
    try:
        import music21 as m21
    except ImportError:
        return {"error": "music21 not installed. Run: pip install music21"}

    try:
        score = m21.converter.parse(xml_path)
    except Exception as e:
        return {"error": f"Parse error: {str(e)}"}

    notes = []

    for part_idx, part in enumerate(score.parts):
        part_name = part.partName or f"Part {part_idx + 1}"

        for measure in part.getElementsByClass('Measure'):
            for element in measure.recurse():
                if isinstance(element, m21.note.Note):
                    notes.append({
                        'partIndex': part_idx,
                        'partName': part_name,
                        'measureNumber': measure.number,
                        'offset': float(element.offset),
                        'quarterLength': float(element.quarterLength),
                        'isRest': False,
                        'isChord': False,
                        'pitch': element.pitch.midi if element.pitch else None,
                        'pitchName': str(element.pitch) if element.pitch else None,
                        'step': element.pitch.step if element.pitch else None,
                        'octave': element.pitch.octave if element.pitch else None,
                        'alter': element.pitch.alter if element.pitch else None,
                        'duration': element.duration.type if element.duration else None,
                        'dots': element.duration.dots if element.duration else 0,
                        'tie': str(element.tie.type) if element.tie else None,
                        'voice': element.voice if hasattr(element, 'voice') else None,
                        'articulations': extract_articulations(element),
                        'expressions': extract_expressions(element),
                    })
                elif isinstance(element, m21.chord.Chord):
                    # Get articulations/expressions once for the chord (not per note)
                    chord_articulations = extract_articulations(element)
                    chord_expressions = extract_expressions(element)
                    first_note = True
                    for note in element.notes:
                        notes.append({
                            'partIndex': part_idx,
                            'partName': part_name,
                            'measureNumber': measure.number,
                            'offset': float(element.offset),
                            'quarterLength': float(element.quarterLength),
                            'isRest': False,
                            'isChord': True,
                            'pitch': note.pitch.midi if note.pitch else None,
                            'pitchName': str(note.pitch) if note.pitch else None,
                            'step': note.pitch.step if note.pitch else None,
                            'octave': note.pitch.octave if note.pitch else None,
                            'alter': note.pitch.alter if note.pitch else None,
                            'duration': element.duration.type if element.duration else None,
                            'dots': element.duration.dots if element.duration else 0,
                            'tie': str(note.tie.type) if note.tie else None,
                            'voice': element.voice if hasattr(element, 'voice') else None,
                            # Only count articulations/expressions on first note of chord
                            # to avoid double-counting (MusicXML attaches them to the chord, not each note)
                            'articulations': chord_articulations if first_note else [],
                            'expressions': chord_expressions if first_note else [],
                        })
                        first_note = False
                elif isinstance(element, m21.note.Rest):
                    notes.append({
                        'partIndex': part_idx,
                        'partName': part_name,
                        'measureNumber': measure.number,
                        'offset': float(element.offset),
                        'quarterLength': float(element.quarterLength),
                        'isRest': True,
                        'isChord': False,
                        'pitch': None,
                        'pitchName': None,
                        'step': None,
                        'octave': None,
                        'alter': None,
                        'duration': element.duration.type if element.duration else None,
                        'dots': element.duration.dots if element.duration else 0,
                        'tie': None,
                        'voice': element.voice if hasattr(element, 'voice') else None
                    })

    # Extract time signatures
    time_signatures = []
    for ts in score.recurse().getElementsByClass('TimeSignature'):
        time_signatures.append({
            'numerator': ts.numerator,
            'denominator': ts.denominator,
            'offset': float(ts.offset)
        })

    # Extract key signatures
    key_signatures = []
    for ks in score.recurse().getElementsByClass('KeySignature'):
        key_signatures.append({
            'sharps': ks.sharps,
            'mode': str(ks.mode) if hasattr(ks, 'mode') else None,
            'offset': float(ks.offset)
        })

    # Extract dynamics
    dynamics = []
    for dyn in score.recurse().getElementsByClass('Dynamic'):
        dynamics.append({
            'type': dyn.value if hasattr(dyn, 'value') else str(dyn),
            'offset': float(dyn.offset),
            'partIndex': get_part_index(dyn, score),
            'measureNumber': get_measure_number(dyn),
        })

    # Extract slurs
    slurs = []
    for slur in score.recurse().getElementsByClass('Slur'):
        slurs.append({
            'type': slur.type if hasattr(slur, 'type') else 'unknown',
            'offset': float(slur.offset) if hasattr(slur, 'offset') else 0,
        })

    # Count articulations across all notes
    total_articulations = sum(len(n.get('articulations', [])) for n in notes)

    # Count expressions (ornaments) across all notes
    total_expressions = sum(len(n.get('expressions', [])) for n in notes)

    return {
        'filename': os.path.basename(xml_path),
        'partCount': len(score.parts),
        'partNames': [p.partName for p in score.parts],
        'measureCount': max(len(list(p.getElementsByClass('Measure'))) for p in score.parts) if score.parts else 0,
        'notes': notes,
        'totalNotes': len(notes),
        'pitchedNotes': len([n for n in notes if n['pitch'] is not None]),
        'rests': len([n for n in notes if n['isRest']]),
        'chords': len([n for n in notes if n['isChord']]),
        'timeSignatures': time_signatures,
        'keySignatures': key_signatures,
        'dynamics': dynamics,
        'totalDynamics': len(dynamics),
        'slurs': slurs,
        'totalSlurs': len(slurs),
        'totalArticulations': total_articulations,
        'totalExpressions': total_expressions,
    }

def main():
    if len(sys.argv) < 2:
        print(f"Usage: {sys.argv[0]} input.xml [output.json]", file=sys.stderr)
        sys.exit(1)

    input_path = sys.argv[1]
    output_path = sys.argv[2] if len(sys.argv) > 2 else None

    result = extract_notes(input_path)

    if output_path:
        with open(output_path, 'w') as f:
            json.dump(result, f, indent=2)
        print(f"Output written to {output_path}")
    else:
        print(json.dumps(result, indent=2))

if __name__ == '__main__':
    main()
