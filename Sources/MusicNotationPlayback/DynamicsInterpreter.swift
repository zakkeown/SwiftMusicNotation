import Foundation
import MusicNotationCore

/// Converts musical dynamics markings to MIDI velocity values.
///
/// `DynamicsInterpreter` translates expressive markings from notation into MIDI velocity
/// values (0-127). It handles standard dynamics (pp to ff), accented dynamics (sf, sfz),
/// articulation adjustments, and continuous velocity changes during crescendos/diminuendos.
///
/// ## Dynamic Levels
///
/// Standard dynamics are mapped to velocities on a configurable scale:
///
/// | Dynamic | Default Velocity |
/// |---------|-----------------|
/// | ppp | ~35 |
/// | pp | ~48 |
/// | p | ~64 |
/// | mp | ~80 |
/// | mf | ~96 |
/// | f | ~106 |
/// | ff | ~118 |
/// | fff | ~124 |
///
/// ## Velocity Curves
///
/// Three curve shapes control how dynamics map to velocities:
/// - **Linear**: Equal steps between dynamic levels
/// - **Logarithmic**: More control at softer dynamics (natural feel)
/// - **Exponential**: Dramatic crescendos, subtle piano passages
///
/// ## Articulation Adjustments
///
/// Articulations modify the base velocity:
/// - Accents: +30% velocity
/// - Marcato: +40% velocity
/// - Staccato: -10% velocity
/// - Tenuto: +10% velocity
///
/// ## Usage
///
/// ```swift
/// let interpreter = DynamicsInterpreter(velocityCurve: .logarithmic)
///
/// // Get velocity for a dynamic marking
/// let velocity = interpreter.velocityFor(dynamic: .f)  // ~106
///
/// // Adjust for articulations
/// let accentedVelocity = interpreter.adjustVelocityForArticulations(
///     velocity,
///     notations: [.articulations([accentMark])]
/// )
///
/// // Interpolate during crescendo
/// let midCrescendo = interpreter.interpolateVelocity(
///     from: 64,
///     to: 106,
///     progress: 0.5
/// )
/// ```
///
/// - SeeAlso: ``WedgeInterpreter`` for crescendo/diminuendo handling
/// - SeeAlso: ``ScoreSequencer`` for using the interpreter during playback
public struct DynamicsInterpreter: Sendable {

    // MARK: - Types

    /// Velocity curve style.
    public enum VelocityCurve: Sendable {
        /// Linear mapping from dynamics to velocity.
        case linear
        /// Logarithmic mapping (more natural feel).
        case logarithmic
        /// Exponential mapping (more dramatic changes).
        case exponential
    }

    // MARK: - Properties

    /// The velocity curve to use.
    public var velocityCurve: VelocityCurve

    /// Minimum velocity value (for pppppp).
    public var minimumVelocity: UInt8

    /// Maximum velocity value (for ffffff).
    public var maximumVelocity: UInt8

    // MARK: - Initialization

    public init(
        velocityCurve: VelocityCurve = .logarithmic,
        minimumVelocity: UInt8 = 16,
        maximumVelocity: UInt8 = 127
    ) {
        self.velocityCurve = velocityCurve
        self.minimumVelocity = minimumVelocity
        self.maximumVelocity = maximumVelocity
    }

    // MARK: - Public Methods

    /// Gets the MIDI velocity for a dynamic marking.
    /// - Parameter dynamic: The dynamic value.
    /// - Returns: MIDI velocity (0-127).
    public func velocityFor(dynamic: DynamicValue) -> UInt8 {
        let level = dynamicLevel(for: dynamic)
        return velocityForLevel(level)
    }

    /// Gets the MIDI velocity for a dynamic level.
    /// - Parameter level: Dynamic level from 0.0 (silence) to 1.0 (maximum).
    /// - Returns: MIDI velocity (0-127).
    public func velocityForLevel(_ level: Double) -> UInt8 {
        let clampedLevel = max(0.0, min(1.0, level))

        let adjustedLevel: Double
        switch velocityCurve {
        case .linear:
            adjustedLevel = clampedLevel
        case .logarithmic:
            // Logarithmic curve provides more subtle control at lower dynamics
            adjustedLevel = log10(1 + 9 * clampedLevel) // Maps 0-1 to 0-1 with log curve
        case .exponential:
            // Exponential curve provides more dramatic crescendos
            adjustedLevel = pow(clampedLevel, 2)
        }

        let range = Double(maximumVelocity - minimumVelocity)
        let velocity = Double(minimumVelocity) + (adjustedLevel * range)

        return UInt8(max(1, min(127, Int(velocity.rounded()))))
    }

    /// Adjusts velocity for articulation markings.
    /// - Parameters:
    ///   - baseVelocity: The base velocity from dynamics.
    ///   - notations: The notations attached to the note.
    /// - Returns: Adjusted MIDI velocity.
    public func adjustVelocityForArticulations(_ baseVelocity: UInt8, notations: [Notation]) -> UInt8 {
        var velocity = Double(baseVelocity)

        for notation in notations {
            switch notation {
            case .articulations(let marks):
                for mark in marks {
                    velocity *= articulationVelocityMultiplier(for: mark.articulation.musicXMLName)
                }

            case .dynamics(let marks):
                // Note-level dynamics override
                for mark in marks {
                    velocity = Double(velocityForLevel(mark.dynamic.relativeLoudness))
                }

            case .fermata:
                // Fermatas often have a slight emphasis
                velocity *= 1.05

            default:
                break
            }
        }

        return UInt8(max(1, min(127, Int(velocity.rounded()))))
    }

    /// Interpolates velocity during a crescendo or diminuendo.
    /// - Parameters:
    ///   - startVelocity: Starting velocity.
    ///   - endVelocity: Ending velocity.
    ///   - progress: Progress through the wedge (0.0 to 1.0).
    /// - Returns: Interpolated velocity.
    public func interpolateVelocity(
        from startVelocity: UInt8,
        to endVelocity: UInt8,
        progress: Double
    ) -> UInt8 {
        let clampedProgress = max(0.0, min(1.0, progress))

        let curvedProgress: Double
        switch velocityCurve {
        case .linear:
            curvedProgress = clampedProgress
        case .logarithmic:
            curvedProgress = log10(1 + 9 * clampedProgress)
        case .exponential:
            curvedProgress = pow(clampedProgress, 2)
        }

        let startDouble = Double(startVelocity)
        let endDouble = Double(endVelocity)
        let interpolated = startDouble + (endDouble - startDouble) * curvedProgress

        return UInt8(max(1, min(127, Int(interpolated.rounded()))))
    }

    // MARK: - Private Methods

    private func dynamicLevel(for dynamic: DynamicValue) -> Double {
        switch dynamic {
        case .pppppp: return 0.05
        case .ppppp: return 0.10
        case .pppp: return 0.15
        case .ppp: return 0.22
        case .pp: return 0.30
        case .p: return 0.40
        case .mp: return 0.50
        case .mf: return 0.60
        case .f: return 0.72
        case .ff: return 0.82
        case .fff: return 0.90
        case .ffff: return 0.95
        case .fffff: return 0.98
        case .ffffff: return 1.00

        // Accented dynamics
        case .sf, .sfz: return 0.85
        case .sffz: return 0.95
        case .fz: return 0.80
        case .rfz, .rf: return 0.82

        // Combined dynamics
        case .fp: return 0.75  // Initial attack
        case .sfp: return 0.80
        case .sfpp: return 0.82
        case .pf: return 0.45
        case .sfzp: return 0.85

        // Niente
        case .n: return 0.0
        }
    }

    private func dynamicLevelFromString(_ typeString: String) -> Double? {
        // Try to parse common dynamic strings
        let normalized = typeString.lowercased().trimmingCharacters(in: .whitespaces)

        switch normalized {
        case "pppppp": return 0.05
        case "ppppp": return 0.10
        case "pppp": return 0.15
        case "ppp": return 0.22
        case "pp": return 0.30
        case "p": return 0.40
        case "mp": return 0.50
        case "mf": return 0.60
        case "f": return 0.72
        case "ff": return 0.82
        case "fff": return 0.90
        case "ffff": return 0.95
        case "fffff": return 0.98
        case "ffffff": return 1.00
        case "sf", "sfz": return 0.85
        case "sffz": return 0.95
        case "fz": return 0.80
        case "rfz", "rf": return 0.82
        case "fp": return 0.75
        case "sfp": return 0.80
        case "sfpp": return 0.82
        default: return nil
        }
    }

    private func articulationVelocityMultiplier(for articulationType: String) -> Double {
        let normalized = articulationType.lowercased()

        switch normalized {
        // Accent markings - increase velocity
        case "accent":
            return 1.3
        case "strong-accent", "marcato":
            return 1.4
        case "tenuto":
            return 1.1

        // Soft articulations - decrease velocity
        case "staccato":
            return 0.9
        case "staccatissimo":
            return 0.85
        case "spiccato":
            return 0.88

        // Combined
        case "detached-legato":
            return 1.0
        case "staccato-accent":
            return 1.2

        // Special
        case "breath-mark":
            return 0.95

        default:
            return 1.0
        }
    }
}

// MARK: - Wedge Interpreter

/// Interprets crescendo and diminuendo wedges.
public struct WedgeInterpreter: Sendable {

    /// Represents an active wedge.
    public struct ActiveWedge: Sendable {
        public let startTime: TimeInterval
        public let endTime: TimeInterval
        public let startVelocity: UInt8
        public let endVelocity: UInt8
        public let isCrescendo: Bool

        public init(
            startTime: TimeInterval,
            endTime: TimeInterval,
            startVelocity: UInt8,
            endVelocity: UInt8,
            isCrescendo: Bool
        ) {
            self.startTime = startTime
            self.endTime = endTime
            self.startVelocity = startVelocity
            self.endVelocity = endVelocity
            self.isCrescendo = isCrescendo
        }

        /// Gets the velocity at a given time.
        public func velocityAt(time: TimeInterval, interpreter: DynamicsInterpreter) -> UInt8? {
            guard time >= startTime && time <= endTime else { return nil }

            let duration = endTime - startTime
            guard duration > 0 else { return startVelocity }

            let progress = (time - startTime) / duration
            return interpreter.interpolateVelocity(
                from: startVelocity,
                to: endVelocity,
                progress: progress
            )
        }
    }

    private let dynamicsInterpreter: DynamicsInterpreter

    public init(dynamicsInterpreter: DynamicsInterpreter = DynamicsInterpreter()) {
        self.dynamicsInterpreter = dynamicsInterpreter
    }

    /// Creates a wedge from a crescendo marking.
    /// - Parameters:
    ///   - startTime: Start time of the wedge.
    ///   - endTime: End time of the wedge.
    ///   - startDynamic: Starting dynamic level.
    ///   - endDynamic: Ending dynamic level (if specified).
    /// - Returns: An active wedge.
    public func createCrescendo(
        startTime: TimeInterval,
        endTime: TimeInterval,
        startDynamic: DynamicValue,
        endDynamic: DynamicValue? = nil
    ) -> ActiveWedge {
        let startVelocity = dynamicsInterpreter.velocityFor(dynamic: startDynamic)
        let endVelocity: UInt8

        if let end = endDynamic {
            endVelocity = dynamicsInterpreter.velocityFor(dynamic: end)
        } else {
            // Default: increase by two dynamic levels
            endVelocity = min(127, startVelocity + 25)
        }

        return ActiveWedge(
            startTime: startTime,
            endTime: endTime,
            startVelocity: startVelocity,
            endVelocity: endVelocity,
            isCrescendo: true
        )
    }

    /// Creates a wedge from a diminuendo marking.
    /// - Parameters:
    ///   - startTime: Start time of the wedge.
    ///   - endTime: End time of the wedge.
    ///   - startDynamic: Starting dynamic level.
    ///   - endDynamic: Ending dynamic level (if specified).
    /// - Returns: An active wedge.
    public func createDiminuendo(
        startTime: TimeInterval,
        endTime: TimeInterval,
        startDynamic: DynamicValue,
        endDynamic: DynamicValue? = nil
    ) -> ActiveWedge {
        let startVelocity = dynamicsInterpreter.velocityFor(dynamic: startDynamic)
        let endVelocity: UInt8

        if let end = endDynamic {
            endVelocity = dynamicsInterpreter.velocityFor(dynamic: end)
        } else {
            // Default: decrease by two dynamic levels
            endVelocity = max(16, startVelocity - 25)
        }

        return ActiveWedge(
            startTime: startTime,
            endTime: endTime,
            startVelocity: startVelocity,
            endVelocity: endVelocity,
            isCrescendo: false
        )
    }
}
