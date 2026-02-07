import Foundation

/// Parses raw MIDI file data into a structured `MIDIFile`.
struct MIDIFileParser {

    /// Parses MIDI data into a `MIDIFile`.
    func parse(_ data: Data) throws -> MIDIFile {
        var reader = BinaryReader(data: data)

        // Parse header chunk
        let (format, trackCount, timeDivision) = try parseHeader(&reader)

        // Parse track chunks
        var tracks: [MIDITrack] = []
        tracks.reserveCapacity(trackCount)
        for _ in 0..<trackCount {
            let track = try parseTrack(&reader)
            tracks.append(track)
        }

        return MIDIFile(
            format: format,
            trackCount: trackCount,
            timeDivision: timeDivision,
            tracks: tracks
        )
    }

    // MARK: - Header

    private func parseHeader(_ reader: inout BinaryReader) throws -> (Int, Int, TimeDivision) {
        // "MThd"
        guard reader.remaining >= 14 else { throw MIDIError.unexpectedEOF }
        let chunkID = try reader.readBytes(4)
        guard chunkID == [0x4D, 0x54, 0x68, 0x64] else { throw MIDIError.invalidHeader }

        let chunkSize = try reader.readUInt32()
        guard chunkSize >= 6 else { throw MIDIError.invalidHeader }

        let format = Int(try reader.readUInt16())
        guard format == 0 || format == 1 else { throw MIDIError.unsupportedFormat(format) }

        let trackCount = Int(try reader.readUInt16())
        let divisionRaw = try reader.readUInt16()

        let timeDivision: TimeDivision
        if divisionRaw & 0x8000 == 0 {
            // Ticks per quarter note
            timeDivision = .ticksPerQuarter(Int(divisionRaw & 0x7FFF))
        } else {
            // SMPTE
            let fps = Int(Int8(bitPattern: UInt8(divisionRaw >> 8)))
            let tpf = Int(divisionRaw & 0xFF)
            timeDivision = .smpte(framesPerSecond: -fps, ticksPerFrame: tpf)
        }

        // Skip any extra header bytes beyond the standard 6
        if chunkSize > 6 {
            try reader.skip(Int(chunkSize) - 6)
        }

        return (format, trackCount, timeDivision)
    }

    // MARK: - Track

    private func parseTrack(_ reader: inout BinaryReader) throws -> MIDITrack {
        // "MTrk"
        guard reader.remaining >= 8 else { throw MIDIError.unexpectedEOF }
        let chunkID = try reader.readBytes(4)
        guard chunkID == [0x4D, 0x54, 0x72, 0x6B] else { throw MIDIError.invalidTrackChunk }

        let chunkSize = Int(try reader.readUInt32())
        guard reader.remaining >= chunkSize else { throw MIDIError.unexpectedEOF }

        let trackEnd = reader.position + chunkSize
        var events: [MIDITrackEvent] = []
        var absoluteTick = 0
        var runningStatus: UInt8 = 0

        while reader.position < trackEnd {
            let deltaTime = try reader.readVariableLength()
            absoluteTick += deltaTime

            let event = try parseEvent(&reader, runningStatus: &runningStatus)
            events.append(MIDITrackEvent(absoluteTick: absoluteTick, event: event))

            if case .endOfTrack = event {
                break
            }
        }

        // Ensure we're at the end of the track chunk
        if reader.position < trackEnd {
            reader.position = trackEnd
        }

        return MIDITrack(events: events)
    }

    // MARK: - Event Parsing

    private func parseEvent(_ reader: inout BinaryReader, runningStatus: inout UInt8) throws -> MIDIEventType {
        guard reader.remaining > 0 else { throw MIDIError.unexpectedEOF }

        let firstByte = try reader.readUInt8()

        // Meta event
        if firstByte == 0xFF {
            return try parseMetaEvent(&reader)
        }

        // SysEx
        if firstByte == 0xF0 || firstByte == 0xF7 {
            let length = try reader.readVariableLength()
            let data = try reader.readData(length)
            return .sysEx(data)
        }

        // Channel message
        var statusByte: UInt8
        var dataByte1: UInt8

        if firstByte >= 0x80 {
            // New status byte
            statusByte = firstByte
            runningStatus = statusByte
            dataByte1 = try reader.readUInt8()
        } else {
            // Running status: firstByte is the data byte
            statusByte = runningStatus
            dataByte1 = firstByte
        }

        let messageType = statusByte & 0xF0
        let channel = statusByte & 0x0F

        switch messageType {
        case 0x80: // Note Off
            let velocity = try reader.readUInt8()
            return .noteOff(channel: channel, note: dataByte1, velocity: velocity)

        case 0x90: // Note On
            let velocity = try reader.readUInt8()
            // Note On with velocity 0 is treated as Note Off
            if velocity == 0 {
                return .noteOff(channel: channel, note: dataByte1, velocity: 0)
            }
            return .noteOn(channel: channel, note: dataByte1, velocity: velocity)

        case 0xA0: // Polyphonic Aftertouch
            let pressure = try reader.readUInt8()
            return .polyAftertouch(channel: channel, note: dataByte1, pressure: pressure)

        case 0xB0: // Control Change
            let value = try reader.readUInt8()
            return .controlChange(channel: channel, controller: dataByte1, value: value)

        case 0xC0: // Program Change (single data byte)
            return .programChange(channel: channel, program: dataByte1)

        case 0xD0: // Channel Aftertouch (single data byte)
            return .channelAftertouch(channel: channel, pressure: dataByte1)

        case 0xE0: // Pitch Bend
            let msb = try reader.readUInt8()
            let value = UInt16(dataByte1) | (UInt16(msb) << 7)
            return .pitchBend(channel: channel, value: value)

        default:
            // Unknown status; skip as best we can
            return .unknownMeta(type: statusByte, data: Data())
        }
    }

    // MARK: - Meta Events

    private func parseMetaEvent(_ reader: inout BinaryReader) throws -> MIDIEventType {
        let type = try reader.readUInt8()
        let length = try reader.readVariableLength()

        switch type {
        case 0x00: // Sequence Number
            guard length >= 2 else {
                try reader.skip(length)
                return .unknownMeta(type: type, data: Data())
            }
            let number = try reader.readUInt16()
            if length > 2 { try reader.skip(length - 2) }
            return .sequenceNumber(number)

        case 0x01: // Text Event
            let data = try reader.readData(length)
            return .text(String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) ?? "")

        case 0x02: // Copyright
            let data = try reader.readData(length)
            return .copyright(String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) ?? "")

        case 0x03: // Track Name
            let data = try reader.readData(length)
            return .trackName(String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) ?? "")

        case 0x04: // Instrument Name
            let data = try reader.readData(length)
            return .instrumentName(String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) ?? "")

        case 0x05: // Lyric
            let data = try reader.readData(length)
            return .text(String(data: data, encoding: .utf8) ?? "")

        case 0x06: // Marker
            let data = try reader.readData(length)
            return .marker(String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) ?? "")

        case 0x07: // Cue Point
            let data = try reader.readData(length)
            return .cuePoint(String(data: data, encoding: .utf8) ?? String(data: data, encoding: .ascii) ?? "")

        case 0x20: // MIDI Channel Prefix
            guard length >= 1 else {
                try reader.skip(length)
                return .unknownMeta(type: type, data: Data())
            }
            let ch = try reader.readUInt8()
            if length > 1 { try reader.skip(length - 1) }
            return .channelPrefix(ch)

        case 0x2F: // End of Track
            try reader.skip(length)
            return .endOfTrack

        case 0x51: // Tempo
            guard length >= 3 else {
                try reader.skip(length)
                return .unknownMeta(type: type, data: Data())
            }
            let b0 = Int(try reader.readUInt8())
            let b1 = Int(try reader.readUInt8())
            let b2 = Int(try reader.readUInt8())
            let microseconds = (b0 << 16) | (b1 << 8) | b2
            if length > 3 { try reader.skip(length - 3) }
            return .tempo(microsecondsPerQuarter: microseconds)

        case 0x58: // Time Signature
            guard length >= 4 else {
                try reader.skip(length)
                return .unknownMeta(type: type, data: Data())
            }
            let numerator = try reader.readUInt8()
            let denominatorPower = try reader.readUInt8()
            let clocks = try reader.readUInt8()
            let thirtySeconds = try reader.readUInt8()
            let denominator = UInt8(1 << denominatorPower)
            if length > 4 { try reader.skip(length - 4) }
            return .timeSignature(
                numerator: numerator,
                denominator: denominator,
                clocksPerClick: clocks,
                thirtySecondNotesPerQuarter: thirtySeconds
            )

        case 0x59: // Key Signature
            guard length >= 2 else {
                try reader.skip(length)
                return .unknownMeta(type: type, data: Data())
            }
            let sf = Int8(bitPattern: try reader.readUInt8())
            let mi = try reader.readUInt8()
            if length > 2 { try reader.skip(length - 2) }
            return .keySignature(sharpsFlats: sf, isMinor: mi != 0)

        default:
            let data = try reader.readData(length)
            return .unknownMeta(type: type, data: data)
        }
    }
}

// MARK: - BinaryReader

/// A cursor-based reader for big-endian binary data.
struct BinaryReader {
    let data: Data
    var position: Int = 0

    var remaining: Int { data.count - position }

    mutating func readUInt8() throws -> UInt8 {
        guard position < data.count else { throw MIDIError.unexpectedEOF }
        let value = data[data.startIndex + position]
        position += 1
        return value
    }

    mutating func readUInt16() throws -> UInt16 {
        guard remaining >= 2 else { throw MIDIError.unexpectedEOF }
        let b0 = UInt16(data[data.startIndex + position])
        let b1 = UInt16(data[data.startIndex + position + 1])
        position += 2
        return (b0 << 8) | b1
    }

    mutating func readUInt32() throws -> UInt32 {
        guard remaining >= 4 else { throw MIDIError.unexpectedEOF }
        let b0 = UInt32(data[data.startIndex + position])
        let b1 = UInt32(data[data.startIndex + position + 1])
        let b2 = UInt32(data[data.startIndex + position + 2])
        let b3 = UInt32(data[data.startIndex + position + 3])
        position += 4
        return (b0 << 24) | (b1 << 16) | (b2 << 8) | b3
    }

    mutating func readBytes(_ count: Int) throws -> [UInt8] {
        guard remaining >= count else { throw MIDIError.unexpectedEOF }
        let bytes = Array(data[(data.startIndex + position)..<(data.startIndex + position + count)])
        position += count
        return bytes
    }

    mutating func readData(_ count: Int) throws -> Data {
        guard remaining >= count else { throw MIDIError.unexpectedEOF }
        let result = data[(data.startIndex + position)..<(data.startIndex + position + count)]
        position += count
        return Data(result)
    }

    mutating func skip(_ count: Int) throws {
        guard remaining >= count else { throw MIDIError.unexpectedEOF }
        position += count
    }

    /// Reads a MIDI variable-length quantity (1-4 bytes).
    mutating func readVariableLength() throws -> Int {
        var value = 0
        for _ in 0..<4 {
            let byte = try readUInt8()
            value = (value << 7) | Int(byte & 0x7F)
            if byte & 0x80 == 0 {
                return value
            }
        }
        // If we get here, the VLQ was more than 4 bytes — malformed
        return value
    }
}
