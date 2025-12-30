import Foundation
import AVFoundation
import MusicNotationCore
import Combine

/// Coordinates MIDI playback of music notation scores.
///
/// `PlaybackEngine` is the main entry point for adding audio playback to your music
/// notation application. It converts scores to timed MIDI events and synthesizes
/// audio using AVFoundation's built-in MIDI synthesizer.
///
/// ## Basic Usage
///
/// Load a score and control playback:
///
/// ```swift
/// let engine = PlaybackEngine()
///
/// // Load a score
/// try await engine.load(score)
///
/// // Control playback
/// try engine.play()
/// engine.pause()
/// engine.stop()
/// ```
///
/// ## SwiftUI Integration
///
/// `PlaybackEngine` is an `ObservableObject` with `@Published` properties for
/// easy SwiftUI integration:
///
/// ```swift
/// struct PlaybackControls: View {
///     @StateObject private var engine = PlaybackEngine()
///
///     var body: some View {
///         VStack {
///             Text("Measure \(engine.currentPosition.measure)")
///
///             HStack {
///                 Button(engine.state == .playing ? "Pause" : "Play") {
///                     if engine.state == .playing {
///                         engine.pause()
///                     } else {
///                         try? engine.play()
///                     }
///                 }
///                 Button("Stop") { engine.stop() }
///             }
///
///             Slider(value: $engine.tempo, in: 40...240)
///         }
///     }
/// }
/// ```
///
/// ## Event Handling with Combine
///
/// Subscribe to playback events for detailed control:
///
/// ```swift
/// var cancellables = Set<AnyCancellable>()
///
/// engine.events
///     .receive(on: DispatchQueue.main)
///     .sink { event in
///         switch event {
///         case .started:
///             highlightPlayButton()
///         case .positionChanged(let measure, let beat):
///             updateCursor(measure: measure, beat: beat)
///         case .stopped:
///             resetCursor()
///         case .error(let error):
///             showError(error)
///         default:
///             break
///         }
///     }
///     .store(in: &cancellables)
/// ```
///
/// ## Position Navigation
///
/// Navigate within the score:
///
/// ```swift
/// // Seek to a specific position
/// try engine.seek(to: 5, beat: 1.0)  // Measure 5, beat 1
///
/// // Navigate by measure
/// try engine.nextMeasure()
/// try engine.previousMeasure()
/// ```
///
/// ## Volume Control
///
/// Control master and per-part volumes:
///
/// ```swift
/// engine.masterVolume = 0.8  // 80% volume
///
/// // Mute or adjust individual parts
/// engine.setMuted(true, forPart: "P2")
/// engine.setVolume(0.5, forPart: "P1")
/// ```
///
/// ## Thread Safety
///
/// `PlaybackEngine` is marked `@MainActor` and all calls must be made from the
/// main thread. The `load(_:)` method is `async` to handle sound bank loading.
///
/// - SeeAlso: `PlaybackPosition` for position tracking
/// - SeeAlso: `PlaybackEvent` for event types
/// - SeeAlso: `PlaybackError` for error handling
@MainActor
public final class PlaybackEngine: ObservableObject {

    // MARK: - Types

    /// Represents the current state of the playback engine.
    public enum State: Sendable {
        /// Playback is stopped and position is at the beginning.
        case stopped
        /// Audio is currently playing.
        case playing
        /// Playback is paused at the current position.
        case paused
    }

    /// Events emitted by the playback engine via the `events` publisher.
    ///
    /// Subscribe to these events to update UI or respond to playback changes.
    public enum PlaybackEvent: Sendable {
        /// Playback has started or resumed.
        case started
        /// Playback has been paused.
        case paused
        /// Playback has been stopped.
        case stopped
        /// The playback position has changed.
        /// - Parameters:
        ///   - measure: Current measure number (1-based).
        ///   - beat: Current beat within the measure.
        case positionChanged(measure: Int, beat: Double)
        /// The tempo has changed.
        /// - Parameter bpm: New tempo in beats per minute.
        case tempoChanged(bpm: Double)
        /// An error occurred during playback.
        /// - Parameter error: The error that occurred.
        case error(PlaybackError)
    }

    /// Errors that can occur during playback operations.
    public enum PlaybackError: Error, Sendable {
        /// Attempted to play without loading a score first.
        case noScoreLoaded
        /// The AVFoundation audio engine failed.
        case audioEngineError(String)
        /// The MIDI sound bank could not be found.
        case soundBankNotFound
        /// The seek position is invalid (e.g., negative measure number).
        case invalidPosition
        /// Failed to convert the score to MIDI events.
        case sequencingError(String)
    }

    // MARK: - Published Properties

    /// The current playback state.
    ///
    /// Use this to update UI elements like play/pause buttons.
    /// Observe this property in SwiftUI views for automatic updates.
    @Published public private(set) var state: State = .stopped

    /// The playback tempo in beats per minute (BPM).
    ///
    /// Changing this property immediately affects playback speed.
    /// Valid range is typically 20-400 BPM, though no validation is performed.
    ///
    /// Default: 120 BPM
    @Published public var tempo: Double = 120.0 {
        didSet {
            sequencer?.tempo = tempo
            eventSubject.send(.tempoChanged(bpm: tempo))
        }
    }

    /// The current playback position within the score.
    ///
    /// This updates continuously during playback with measure number, beat,
    /// and elapsed time. Use for visual playback cursor positioning.
    @Published public private(set) var currentPosition: PlaybackPosition = .zero

    /// Whether a score has been loaded and is ready for playback.
    ///
    /// Check this before calling `play()`. Attempting to play without
    /// a loaded score throws `PlaybackError.noScoreLoaded`.
    @Published public private(set) var isLoaded: Bool = false

    /// The master volume level from 0.0 (silent) to 1.0 (full volume).
    ///
    /// This affects all parts equally. For per-part control, use
    /// `setVolume(_:forPart:)` or `setMuted(_:forPart:)`.
    ///
    /// Default: 1.0
    @Published public var masterVolume: Float = 1.0 {
        didSet {
            synthesizer?.setMasterVolume(masterVolume)
        }
    }

    // MARK: - Private Properties

    private var score: Score?
    private var sequencer: ScoreSequencer?
    private var synthesizer: MIDISynthesizer?
    private var cursor: PlaybackCursor?

    private var displayLink: CADisplayLink?
    private var playbackTimer: Timer?

    private let eventSubject = PassthroughSubject<PlaybackEvent, Never>()

    /// A Combine publisher that emits playback events.
    ///
    /// Subscribe to this publisher to receive notifications about playback
    /// state changes, position updates, and errors.
    ///
    /// Events are published on the background thread; use `.receive(on:)` to
    /// switch to the main thread for UI updates.
    ///
    /// ```swift
    /// engine.events
    ///     .receive(on: DispatchQueue.main)
    ///     .sink { event in
    ///         // Handle event
    ///     }
    ///     .store(in: &cancellables)
    /// ```
    public var events: AnyPublisher<PlaybackEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    // MARK: - Initialization

    /// Creates a new playback engine.
    ///
    /// The engine starts in the stopped state with no score loaded.
    /// Call `load(_:)` before attempting playback.
    public init() {}

    deinit {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    // MARK: - Public Methods

    /// Loads a score for playback.
    ///
    /// This method initializes the MIDI synthesizer (if needed), builds the
    /// event sequence from the score, and prepares the playback cursor.
    ///
    /// Any currently playing score is stopped before loading the new one.
    ///
    /// - Parameter score: The score to load.
    /// - Throws: Errors from the synthesizer setup or sequencing process.
    ///
    /// ## Example
    ///
    /// ```swift
    /// do {
    ///     try await engine.load(score)
    ///     // Ready to play
    /// } catch {
    ///     print("Failed to load score: \(error)")
    /// }
    /// ```
    public func load(_ score: Score) async throws {
        // Stop any current playback
        stop()

        self.score = score

        // Initialize synthesizer if needed
        if synthesizer == nil {
            synthesizer = MIDISynthesizer()
            try await synthesizer?.setup()
        }

        // Create sequencer and build sequence before assigning
        let newSequencer = ScoreSequencer(score: score)
        newSequencer.tempo = tempo

        // Build sequence first - if this throws, we don't update state
        try newSequencer.buildSequence()

        // Only assign after successful build
        sequencer = newSequencer

        // Create cursor
        cursor = PlaybackCursor(score: score)

        isLoaded = true
        currentPosition = .zero
    }

    /// Starts or resumes playback.
    ///
    /// If stopped, playback begins from the current position (usually the beginning).
    /// If paused, playback resumes from where it was paused.
    /// If already playing, this method does nothing.
    ///
    /// - Throws: `PlaybackError.noScoreLoaded` if no score has been loaded.
    public func play() throws {
        guard isLoaded, let sequencer = sequencer, let synthesizer = synthesizer else {
            throw PlaybackError.noScoreLoaded
        }

        switch state {
        case .stopped:
            // Start from beginning or current position
            sequencer.reset()
            cursor?.reset()
            try synthesizer.start()
            startPlaybackTimer()
            state = .playing
            eventSubject.send(.started)

        case .paused:
            // Resume from current position
            try synthesizer.start()
            startPlaybackTimer()
            state = .playing
            eventSubject.send(.started)

        case .playing:
            // Already playing
            break
        }
    }

    /// Pauses playback at the current position.
    ///
    /// All sounding notes are silenced. Call `play()` to resume from this position.
    /// Does nothing if playback is already paused or stopped.
    public func pause() {
        guard state == .playing else { return }

        stopPlaybackTimer()
        synthesizer?.stop()
        synthesizer?.allNotesOff()

        state = .paused
        eventSubject.send(.paused)
    }

    /// Stops playback and resets to the beginning.
    ///
    /// All sounding notes are silenced and the position resets to measure 1.
    /// This is safe to call at any time, regardless of current state.
    public func stop() {
        stopPlaybackTimer()
        synthesizer?.stop()
        synthesizer?.allNotesOff()

        sequencer?.reset()
        cursor?.reset()
        currentPosition = .zero

        state = .stopped
        eventSubject.send(.stopped)
    }

    /// Seeks to a specific position in the score.
    ///
    /// If playback is active, it will pause, seek, then resume automatically.
    /// If stopped or paused, the position updates without starting playback.
    ///
    /// - Parameters:
    ///   - measureNumber: The measure number (1-based). Must be ≥ 1.
    ///   - beat: The beat within the measure (1-based). Defaults to 1.0 (first beat).
    /// - Throws: `PlaybackError.noScoreLoaded` if no score is loaded.
    ///   `PlaybackError.invalidPosition` if the measure number is less than 1.
    public func seek(to measureNumber: Int, beat: Double = 1.0) throws {
        guard isLoaded else {
            throw PlaybackError.noScoreLoaded
        }

        guard measureNumber >= 1 else {
            throw PlaybackError.invalidPosition
        }

        let wasPlaying = state == .playing

        if wasPlaying {
            pause()
        }

        // Calculate the time position
        let timePosition = sequencer?.timeForPosition(measure: measureNumber, beat: beat) ?? 0

        // Update cursor and sequencer
        cursor?.seek(to: measureNumber, beat: beat)
        sequencer?.seek(to: timePosition)

        currentPosition = PlaybackPosition(measure: measureNumber, beat: beat, timeInSeconds: timePosition)
        eventSubject.send(.positionChanged(measure: measureNumber, beat: beat))

        if wasPlaying {
            try play()
        }
    }

    /// Seeks to the next measure.
    ///
    /// Advances playback position by one measure. If already at the last measure,
    /// playback will stop when it reaches the end.
    ///
    /// - Throws: `PlaybackError.noScoreLoaded` if no score is loaded.
    public func nextMeasure() throws {
        try seek(to: currentPosition.measure + 1)
    }

    /// Seeks to the previous measure.
    ///
    /// Moves playback position back one measure. If already at measure 1,
    /// stays at measure 1.
    ///
    /// - Throws: `PlaybackError.noScoreLoaded` if no score is loaded.
    public func previousMeasure() throws {
        try seek(to: max(1, currentPosition.measure - 1))
    }

    /// Sets the volume for a specific part.
    ///
    /// Use this to create a mix where some instruments are quieter than others,
    /// or to temporarily highlight a part while practicing.
    ///
    /// - Parameters:
    ///   - volume: Volume level from 0.0 (silent) to 1.0 (full).
    ///   - partId: The part identifier (from `Part.id`).
    public func setVolume(_ volume: Float, forPart partId: String) {
        synthesizer?.setVolume(volume, forChannel: channelForPart(partId))
    }

    /// Mutes or unmutes a specific part.
    ///
    /// Use this to isolate parts for practice or study.
    ///
    /// - Parameters:
    ///   - muted: `true` to mute the part, `false` to unmute.
    ///   - partId: The part identifier (from `Part.id`).
    public func setMuted(_ muted: Bool, forPart partId: String) {
        synthesizer?.setMuted(muted, forChannel: channelForPart(partId))
    }

    // MARK: - Private Methods

    private func startPlaybackTimer() {
        // Use a high-frequency timer for accurate scheduling
        playbackTimer = Timer.scheduledTimer(withTimeInterval: 0.005, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            Task { @MainActor [weak self] in
                self?.processPlayback()
            }
        }
        RunLoop.current.add(playbackTimer!, forMode: .common)
    }

    private func stopPlaybackTimer() {
        playbackTimer?.invalidate()
        playbackTimer = nil
    }

    private func processPlayback() {
        guard state == .playing,
              let sequencer = sequencer,
              let synthesizer = synthesizer else {
            return
        }

        // Get current time
        let currentTime = synthesizer.currentTime

        // Process pending events
        let events = sequencer.eventsUpTo(time: currentTime)

        for event in events {
            switch event.type {
            case .noteOn(let note, let velocity, let channel):
                synthesizer.noteOn(note: note, velocity: velocity, channel: channel)

            case .noteOff(let note, let channel):
                synthesizer.noteOff(note: note, channel: channel)

            case .programChange(let program, let channel):
                synthesizer.programChange(program: program, channel: channel)

            case .controlChange(let controller, let value, let channel):
                synthesizer.controlChange(controller: controller, value: value, channel: channel)

            case .tempoChange(let newTempo):
                // Handle tempo changes in the score
                sequencer.tempo = newTempo
            }
        }

        // Update cursor position
        if let newPosition = cursor?.positionAt(time: currentTime) {
            if newPosition.measure != currentPosition.measure ||
               abs(newPosition.beat - currentPosition.beat) > 0.01 {
                currentPosition = newPosition
                eventSubject.send(.positionChanged(measure: newPosition.measure, beat: newPosition.beat))
            }
        }

        // Check if playback is complete
        if sequencer.isComplete {
            stop()
        }
    }

    private func channelForPart(_ partId: String) -> UInt8 {
        guard let score = score else { return 0 }

        for (index, part) in score.parts.enumerated() {
            if part.id == partId {
                return UInt8(index % 16)
            }
        }
        return 0
    }
}

// MARK: - PlaybackPosition

/// Represents a position within a score during playback.
///
/// `PlaybackPosition` tracks where playback is occurring, providing both
/// musical coordinates (measure and beat) and elapsed time. Use this to
/// position a visual cursor on the score during playback.
///
/// ## Usage
///
/// Access the current position through `PlaybackEngine.currentPosition`:
///
/// ```swift
/// let position = engine.currentPosition
/// print("Measure \(position.measure), beat \(position.beat)")
/// print("Elapsed: \(position.timeInSeconds) seconds")
/// ```
///
/// ## Coordinate System
///
/// - **Measure**: 1-based measure number (first measure is 1)
/// - **Beat**: 1-based beat within the measure (first beat is 1.0)
/// - **Time**: Elapsed time in seconds from the start of playback
public struct PlaybackPosition: Sendable, Equatable {
    /// The measure number (1-based).
    ///
    /// The first measure of the score is measure 1.
    public let measure: Int

    /// The beat position within the measure (1-based).
    ///
    /// The first beat is 1.0. Fractional values represent positions
    /// between beats (e.g., 1.5 is halfway between beats 1 and 2).
    public let beat: Double

    /// Elapsed time from the start of playback in seconds.
    public let timeInSeconds: TimeInterval

    /// A position representing the beginning of the score.
    public static let zero = PlaybackPosition(measure: 1, beat: 1.0, timeInSeconds: 0)

    /// Creates a new playback position.
    ///
    /// - Parameters:
    ///   - measure: The measure number (1-based).
    ///   - beat: The beat within the measure (1-based).
    ///   - timeInSeconds: Elapsed time from the start.
    public init(measure: Int, beat: Double, timeInSeconds: TimeInterval) {
        self.measure = measure
        self.beat = beat
        self.timeInSeconds = timeInSeconds
    }
}

// MARK: - CADisplayLink (cross-platform)

#if os(macOS)
import AppKit

/// macOS implementation of display link for smooth updates.
private class CADisplayLink {
    private var timer: Timer?
    private let callback: () -> Void

    init(callback: @escaping () -> Void) {
        self.callback = callback
    }

    func start() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { [weak self] _ in
            self?.callback()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }
}
#endif
