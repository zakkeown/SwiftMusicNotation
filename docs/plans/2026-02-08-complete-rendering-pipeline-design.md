# Complete Rendering Pipeline

## Problem

ExportEngine renders only raw glyphs (noteheads, accidentals, rests, clefs, key/time signatures). Missing from rendered output: stems, flags, augmentation dots, beams, dynamic glyphs, wedge hairpins, metronome markings, text directions, styled barlines, system barlines, staff groupings (braces/brackets), and ledger lines.

The individual renderers (NoteRenderer, BeamRenderer, CurveRenderer, StaffRenderer, TextRenderer, GlyphRenderer) are fully implemented. The layout model (EngravedScore) already carries all necessary data. The gap is purely in ExportEngine not wiring them together.

Additionally, TextRenderer discards bold/italic traits for direction text and credits.

## Scope

1. **ExportEngine.swift** - Wire complete rendering pipeline using existing renderers
2. **TextRenderer.swift** - Fix bold/italic trait application
3. **Tests** - Rendering smoke tests covering all element types

## Design

### ExportEngine Changes

`renderElement()` expanded to use full renderer suite:
- `.note` -> NoteRenderer.renderNote() with stem, flag, dots, accidental
- `.chord` -> NoteRenderer.renderChord() with shared stem, flag, dots
- `.direction` -> Switch on DirectionContent: dynamic glyphs, wedge hairpins, text, metronome
- `.barline` -> StaffRenderer.renderBarline(style:)

`renderMeasure()` expanded:
- Render beamGroups via BeamRenderer after individual elements

`renderPage()` expanded per system:
- Render systemBarlines via StaffRenderer
- Render groupings via GlyphRenderer (braces/brackets)

### TextRenderer Fix

Replace `_ = traits` pattern with actual font trait application in renderDirection() and renderCredit().

### Tests

Smoke test: build EngravedScore with all element types, render to bitmap, verify non-crash and non-empty output.
