# Understanding the Import Pipeline

Learn how MusicXML files are transformed into Score objects.

@Metadata {
    @PageKind(article)
}

## Overview

The MusicXML import process follows a multi-stage pipeline that transforms raw XML data into rich domain model objects. Understanding this pipeline helps contributors extend the importer and debug import issues.

## Pipeline Stages

The import process consists of five sequential stages:

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  1. Format      │ ──▶ │  2. XML         │ ──▶ │  3. Element     │
│     Detection   │     │     Parsing     │     │     Mapping     │
└─────────────────┘     └─────────────────┘     └─────────────────┘
                                                        │
                                                        ▼
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  5. Score       │ ◀── │  4. Spanner     │ ◀── │                 │
│     Assembly    │     │     Resolution  │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

### Stage 1: Format Detection

`FormatDetector` identifies the input file type:

- **.musicxml** / **.xml**: Uncompressed MusicXML (partwise or timewise)
- **.mxl**: Compressed archive containing MusicXML and optional resources

For MXL files, `MXLContainerReader` extracts the archive and locates the root MusicXML file via the `container.xml` manifest.

### Stage 2: XML Parsing

The raw XML is parsed into a lightweight DOM representation using `XMLElement`. The `XMLParserContext` tracks parsing state including:

- Current part and measure indices
- Current divisions value (duration units per quarter note)
- Staff counts per part
- Accumulated warnings

### Stage 3: Element Mapping

Three specialized mappers transform XML elements into domain models:

| Mapper | Input Elements | Output Models |
|--------|---------------|---------------|
| ``NoteMapper`` | `<note>`, `<pitch>`, `<rest>` | ``Note``, ``Pitch`` |
| ``AttributesMapper`` | `<attributes>`, `<clef>`, `<key>`, `<time>` | ``MeasureAttributes``, ``Clef``, ``KeySignature``, ``TimeSignature`` |
| ``DirectionMapper`` | `<direction>`, `<dynamics>`, `<wedge>` | ``Direction``, ``DirectionType`` |

Each mapper handles one category of MusicXML elements, extracting all relevant attributes and child elements into structured Swift types.

### Stage 4: Spanner Resolution

Cross-element relationships (spanners) require special handling because their start and stop points are encoded on different note elements. Four tracker classes resolve these relationships:

| Tracker | Matches By | Handles |
|---------|-----------|---------|
| ``TieTracker`` | Pitch + Voice + Staff | Note ties (same pitch connected) |
| ``SlurTracker`` | Number + Voice + Staff | Slurs (phrase groupings) |
| ``BeamGrouper`` | Beam level (1-6) | Beamed note groups |
| ``TupletParser`` | Number (1-6) | Tuplet groups with ratios |

Each tracker maintains internal state as notes are processed, matching start events with their corresponding stop events.

### Stage 5: Score Assembly

The final stage combines:
- Mapped elements (notes, attributes, directions)
- Resolved spanners (ties, slurs, beams, tuplets)
- Score metadata (work title, creators, credits)
- Part information (names, instruments)

The result is a complete ``Score`` object ready for layout and rendering.

## Error and Warning Generation

Errors and warnings are generated throughout the pipeline:

**Errors** (fatal, stop import):
- Invalid XML structure (malformed elements)
- Missing required elements (e.g., `<pitch>` without `<step>`)
- Invalid attribute values (e.g., unrecognized clef sign)

**Warnings** (non-fatal, collected):
- Orphaned spanners (start without stop, or vice versa)
- Unrecognized optional elements
- Unsupported features that are skipped

Access warnings after import via ``MusicXMLImporter/warnings``.

## Extending the Importer

To add support for new MusicXML elements:

1. **Add model types** in MusicNotationCore if needed
2. **Extend the appropriate mapper** to parse the new element
3. **Add tracker logic** if the element is a spanner
4. **Update tests** with sample MusicXML files

## See Also

- ``MusicXMLImporter``
- ``NoteMapper``
- ``AttributesMapper``
- ``DirectionMapper``
- ``BeamGrouper``
- ``SlurTracker``
- ``TieTracker``
- ``TupletParser``
