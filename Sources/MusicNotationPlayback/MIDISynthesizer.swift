import Foundation
import AVFoundation

// MARK: - MIDI Synthesizer Protocol

/// Protocol for MIDI synthesizers, enabling dependency injection and testing.
///
/// Conform to this protocol to create custom synthesizers or mock
/// implementations for testing playback without audio hardware.
public protocol MIDISynthesizerProtocol: AnyObject {
    /// Whether the synthesizer is currently running.
    var isRunning: Bool { get }

    /// Current playback time in seconds.
    var currentTime: TimeInterval { get }

    /// Sets up the audio engine and loads the sound bank.
    func setup() async throws

    /// Starts the audio engine.
    func start() throws

    /// Stops the audio engine.
    func stop()

    /// Resets the playback time.
    func resetTime()

    /// Sends a note-on event.
    func noteOn(note: UInt8, velocity: UInt8, channel: UInt8)

    /// Sends a note-off event.
    func noteOff(note: UInt8, channel: UInt8)

    /// Sends a program change event.
    func programChange(program: UInt8, channel: UInt8)

    /// Sends a control change event.
    func controlChange(controller: UInt8, value: UInt8, channel: UInt8)

    /// Turns off all notes on all channels.
    func allNotesOff()

    /// Sets the master volume.
    func setMasterVolume(_ volume: Float)

    /// Sets the volume for a specific channel.
    func setVolume(_ volume: Float, forChannel channel: UInt8)

    /// Mutes or unmutes a specific channel.
    func setMuted(_ muted: Bool, forChannel channel: UInt8)
}

// MARK: - MIDI Synthesizer

/// MIDI synthesizer using AVAudioEngine and AVAudioUnitSampler.
///
/// `MIDISynthesizer` provides real-time audio synthesis of MIDI events using Apple's
/// AVFoundation framework. It supports General MIDI instruments, custom SoundFonts,
/// and full per-channel control of volume, pan, and effects.
///
/// ## Audio Engine Setup
///
/// The synthesizer uses an audio graph with sampler and mixer nodes:
///
/// ```
/// AVAudioUnitSampler ──▶ AVAudioMixerNode ──▶ MainMixerNode ──▶ Output
/// ```
///
/// ## Sound Banks
///
/// On macOS, the synthesizer attempts to load the system's General MIDI sound bank.
/// On iOS, the built-in sounds are used automatically. Custom SoundFonts (.sf2, .dls)
/// can be loaded for higher quality or specialized instruments.
///
/// ## Usage
///
/// ```swift
/// let synth = MIDISynthesizer()
/// try await synth.setup()
/// try synth.start()
///
/// // Send MIDI events
/// synth.programChange(program: 41, channel: 0)  // Violin
/// synth.noteOn(note: 60, velocity: 100, channel: 0)
///
/// // Later...
/// synth.noteOff(note: 60, channel: 0)
/// synth.stop()
/// ```
///
/// ## Channel Control
///
/// Each MIDI channel (0-15) supports independent control:
///
/// ```swift
/// synth.setVolume(0.8, forChannel: 0)    // 80% volume
/// synth.setPan(-0.5, forChannel: 0)       // Pan left
/// synth.setMuted(true, forChannel: 1)     // Mute channel
/// synth.setReverbSend(0.3, forChannel: 0) // Add reverb
/// ```
///
/// ## Percussion
///
/// Channel 10 (index 9) is reserved for percussion per the General MIDI specification.
/// Percussion instruments use note numbers to select different drum sounds.
///
/// - SeeAlso: ``ScoreSequencer`` for converting scores to MIDI events
/// - SeeAlso: ``PlaybackEngine`` for high-level playback control
public final class MIDISynthesizer: MIDISynthesizerProtocol, @unchecked Sendable {

    // MARK: - Properties

    /// The audio engine.
    private let audioEngine: AVAudioEngine

    /// The sampler unit for MIDI playback.
    private let sampler: AVAudioUnitSampler

    /// Mixer node for volume control.
    private let mixer: AVAudioMixerNode

    /// Lock for thread-safe access to mutable state.
    private let stateLock = NSLock()

    /// Start time for calculating current position.
    private var _engineStartTime: TimeInterval = 0

    /// Whether the engine is running.
    private var _isRunning: Bool = false

    /// Whether the engine is running (thread-safe).
    public var isRunning: Bool {
        stateLock.lock()
        defer { stateLock.unlock() }
        return _isRunning
    }

    /// Current playback time in seconds (thread-safe).
    public var currentTime: TimeInterval {
        stateLock.lock()
        defer { stateLock.unlock() }
        guard _isRunning else { return 0 }
        return CACurrentMediaTime() - _engineStartTime
    }

    /// Per-channel volume levels.
    private var channelVolumes: [UInt8: Float] = [:]

    /// Per-channel mute states.
    private var channelMutes: [UInt8: Bool] = [:]

    // MARK: - Initialization

    public init() {
        audioEngine = AVAudioEngine()
        sampler = AVAudioUnitSampler()
        mixer = AVAudioMixerNode()
    }

    // MARK: - Setup

    /// Sets up the audio engine and loads the sound bank.
    public func setup() async throws {
        // Attach nodes
        audioEngine.attach(sampler)
        audioEngine.attach(mixer)

        // Connect nodes
        audioEngine.connect(sampler, to: mixer, format: nil)
        audioEngine.connect(mixer, to: audioEngine.mainMixerNode, format: nil)

        // Load sound bank
        try loadSoundBank()

        // Prepare the engine
        audioEngine.prepare()
    }

    /// Loads the default General MIDI sound bank.
    private func loadSoundBank() throws {
        // Try to load the built-in Apple sound bank
        #if os(macOS)
        let soundBankPath = "/Library/Audio/Sounds/Banks/gs_instruments.dls"
        let soundBankURL = URL(fileURLWithPath: soundBankPath)

        if FileManager.default.fileExists(atPath: soundBankPath) {
            try sampler.loadSoundBankInstrument(
                at: soundBankURL,
                program: 0,
                bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                bankLSB: UInt8(kAUSampler_DefaultBankLSB)
            )
        } else {
            // Fallback: try the Roland GS sound bank location
            let alternativePath = "/System/Library/Components/CoreAudio.component/Contents/Resources/gs_instruments.dls"
            if FileManager.default.fileExists(atPath: alternativePath) {
                let alternativeURL = URL(fileURLWithPath: alternativePath)
                try sampler.loadSoundBankInstrument(
                    at: alternativeURL,
                    program: 0,
                    bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
                    bankLSB: UInt8(kAUSampler_DefaultBankLSB)
                )
            }
            // If no sound bank found, sampler will use default sounds
        }
        #else
        // iOS uses the built-in sounds automatically
        // Optionally load a custom SoundFont here
        #endif
    }

    /// Loads a custom SoundFont file.
    /// - Parameter url: URL to the .sf2 or .dls file.
    public func loadSoundFont(at url: URL) throws {
        try sampler.loadSoundBankInstrument(
            at: url,
            program: 0,
            bankMSB: UInt8(kAUSampler_DefaultMelodicBankMSB),
            bankLSB: UInt8(kAUSampler_DefaultBankLSB)
        )
    }

    // MARK: - Playback Control

    /// Starts the audio engine.
    public func start() throws {
        stateLock.lock()
        guard !_isRunning else {
            stateLock.unlock()
            return
        }
        stateLock.unlock()

        try audioEngine.start()

        stateLock.lock()
        _isRunning = true
        _engineStartTime = CACurrentMediaTime()
        stateLock.unlock()
    }

    /// Stops the audio engine.
    public func stop() {
        stateLock.lock()
        guard _isRunning else {
            stateLock.unlock()
            return
        }
        stateLock.unlock()

        audioEngine.stop()

        stateLock.lock()
        _isRunning = false
        stateLock.unlock()
    }

    /// Resets the playback time.
    public func resetTime() {
        stateLock.lock()
        _engineStartTime = CACurrentMediaTime()
        stateLock.unlock()
    }

    // MARK: - MIDI Events

    /// Sends a note-on event.
    /// - Parameters:
    ///   - note: MIDI note number (0-127).
    ///   - velocity: Note velocity (0-127).
    ///   - channel: MIDI channel (0-15).
    public func noteOn(note: UInt8, velocity: UInt8, channel: UInt8) {
        stateLock.lock()
        // Check if channel is muted
        if channelMutes[channel] == true {
            stateLock.unlock()
            return
        }

        // Apply channel volume
        var adjustedVelocity = velocity
        if let channelVolume = channelVolumes[channel] {
            adjustedVelocity = UInt8(Float(velocity) * channelVolume)
        }
        stateLock.unlock()

        sampler.startNote(note, withVelocity: adjustedVelocity, onChannel: channel)
    }

    /// Sends a note-off event.
    /// - Parameters:
    ///   - note: MIDI note number (0-127).
    ///   - channel: MIDI channel (0-15).
    public func noteOff(note: UInt8, channel: UInt8) {
        sampler.stopNote(note, onChannel: channel)
    }

    /// Sends a program change event.
    /// - Parameters:
    ///   - program: MIDI program number (0-127).
    ///   - channel: MIDI channel (0-15).
    public func programChange(program: UInt8, channel: UInt8) {
        sampler.sendProgramChange(program, onChannel: channel)
    }

    /// Sends a control change event.
    /// - Parameters:
    ///   - controller: MIDI controller number (0-127).
    ///   - value: Controller value (0-127).
    ///   - channel: MIDI channel (0-15).
    public func controlChange(controller: UInt8, value: UInt8, channel: UInt8) {
        sampler.sendController(controller, withValue: value, onChannel: channel)
    }

    /// Sends a pitch bend event.
    /// - Parameters:
    ///   - value: Pitch bend value (0-16383, 8192 = center).
    ///   - channel: MIDI channel (0-15).
    public func pitchBend(value: UInt16, channel: UInt8) {
        sampler.sendPitchBend(value, onChannel: channel)
    }

    /// Turns off all notes on all channels.
    public func allNotesOff() {
        for channel: UInt8 in 0..<16 {
            // All Notes Off (CC 123)
            sampler.sendController(123, withValue: 0, onChannel: channel)
            // All Sound Off (CC 120)
            sampler.sendController(120, withValue: 0, onChannel: channel)
        }
    }

    // MARK: - Volume Control

    /// Sets the master volume.
    /// - Parameter volume: Volume level (0.0 to 1.0).
    public func setMasterVolume(_ volume: Float) {
        mixer.outputVolume = volume
    }

    /// Sets the volume for a specific channel.
    /// - Parameters:
    ///   - volume: Volume level (0.0 to 1.0).
    ///   - channel: MIDI channel (0-15).
    public func setVolume(_ volume: Float, forChannel channel: UInt8) {
        stateLock.lock()
        channelVolumes[channel] = volume
        stateLock.unlock()
        // Send volume control change (CC 7)
        let midiVolume = UInt8(volume * 127)
        sampler.sendController(7, withValue: midiVolume, onChannel: channel)
    }

    /// Mutes or unmutes a specific channel.
    /// - Parameters:
    ///   - muted: Whether the channel should be muted.
    ///   - channel: MIDI channel (0-15).
    public func setMuted(_ muted: Bool, forChannel channel: UInt8) {
        stateLock.lock()
        channelMutes[channel] = muted
        stateLock.unlock()

        if muted {
            // Turn off all notes on this channel
            sampler.sendController(123, withValue: 0, onChannel: channel)
        }
    }

    /// Sets the pan position for a specific channel.
    /// - Parameters:
    ///   - pan: Pan position (-1.0 = left, 0.0 = center, 1.0 = right).
    ///   - channel: MIDI channel (0-15).
    public func setPan(_ pan: Float, forChannel channel: UInt8) {
        // Convert to MIDI pan (0-127, 64 = center)
        let midiPan = UInt8((pan + 1.0) * 63.5)
        sampler.sendController(10, withValue: midiPan, onChannel: channel)
    }

    /// Sets the reverb send level for a specific channel.
    /// - Parameters:
    ///   - level: Reverb level (0.0 to 1.0).
    ///   - channel: MIDI channel (0-15).
    public func setReverbSend(_ level: Float, forChannel channel: UInt8) {
        let midiLevel = UInt8(level * 127)
        sampler.sendController(91, withValue: midiLevel, onChannel: channel)
    }

    /// Sets the chorus send level for a specific channel.
    /// - Parameters:
    ///   - level: Chorus level (0.0 to 1.0).
    ///   - channel: MIDI channel (0-15).
    public func setChorusSend(_ level: Float, forChannel channel: UInt8) {
        let midiLevel = UInt8(level * 127)
        sampler.sendController(93, withValue: midiLevel, onChannel: channel)
    }
}

// MARK: - MIDI Constants

public extension MIDISynthesizer {

    /// Common MIDI controller numbers.
    enum Controller: UInt8 {
        case modulation = 1
        case volume = 7
        case pan = 10
        case expression = 11
        case sustain = 64
        case sostenuto = 66
        case soft = 67
        case reverb = 91
        case chorus = 93
        case allSoundOff = 120
        case allNotesOff = 123
    }

    /// General MIDI instrument categories.
    enum InstrumentFamily: UInt8 {
        case piano = 0
        case chromaticPercussion = 8
        case organ = 16
        case guitar = 24
        case bass = 32
        case strings = 40
        case ensemble = 48
        case brass = 56
        case reed = 64
        case pipe = 72
        case synthLead = 80
        case synthPad = 88
        case synthEffects = 96
        case ethnic = 104
        case percussive = 112
        case soundEffects = 120
    }
}
