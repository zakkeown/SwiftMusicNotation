import SwiftUI
import SwiftMusicNotation

struct PlaybackControls: View {
    @ObservedObject var engine: PlaybackEngine
    let totalMeasures: Int

    @State private var isScrubbing = false
    @State private var scrubPosition: Double = 0

    var body: some View {
        VStack(spacing: 12) {
            // Interactive progress bar
            VStack(spacing: 4) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track
                        Rectangle()
                            .fill(Color.secondary.opacity(0.2))
                            .frame(height: 8)
                            .clipShape(Capsule())

                        // Progress
                        Rectangle()
                            .fill(Color.accentColor)
                            .frame(width: geometry.size.width * CGFloat(displayProgress), height: 8)
                            .clipShape(Capsule())
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                isScrubbing = true
                                let fraction = value.location.x / geometry.size.width
                                scrubPosition = min(max(fraction, 0), 1)
                            }
                            .onEnded { value in
                                let targetMeasure = Int(scrubPosition * Double(totalMeasures)) + 1
                                try? engine.seek(to: min(targetMeasure, totalMeasures))
                                isScrubbing = false
                            }
                    )
                }
                .frame(height: 8)

                HStack {
                    Text(formattedTime(engine.currentPosition.timeInSeconds))
                        .font(.caption)
                        .monospacedDigit()

                    Spacer()

                    Text("Measure \(displayMeasure) of \(totalMeasures)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: 300)

            // Transport controls
            HStack(spacing: 16) {
                Button { try? engine.previousMeasure() } label: {
                    Image(systemName: "backward.end.fill").font(.title3)
                }
                .disabled(!engine.isLoaded)

                Button { engine.stop() } label: {
                    Image(systemName: "stop.fill").font(.title2)
                }
                .disabled(engine.state == .stopped)

                Button { togglePlayback() } label: {
                    Image(systemName: engine.state == .playing ? "pause.fill" : "play.fill").font(.title)
                }
                .disabled(!engine.isLoaded)
                .buttonStyle(.borderedProminent)

                Button { try? engine.nextMeasure() } label: {
                    Image(systemName: "forward.end.fill").font(.title3)
                }
                .disabled(!engine.isLoaded)
            }

            // Tempo control
            HStack {
                Image(systemName: "metronome")
                    .foregroundStyle(.secondary)
                Slider(value: $engine.tempo, in: 40...240, step: 1)
                    .frame(width: 150)
                    .disabled(!engine.isLoaded)
                Text("\(Int(engine.tempo)) BPM")
                    .font(.caption)
                    .monospacedDigit()
                    .frame(width: 60, alignment: .trailing)
            }
        }
        .padding()
    }

    private var displayProgress: Double {
        if isScrubbing {
            return scrubPosition
        }
        guard totalMeasures > 0 else { return 0 }
        return Double(engine.currentPosition.measure - 1) / Double(totalMeasures)
    }

    private var displayMeasure: Int {
        if isScrubbing {
            return Int(scrubPosition * Double(totalMeasures)) + 1
        }
        return engine.currentPosition.measure
    }

    private func formattedTime(_ seconds: TimeInterval) -> String {
        let minutes = Int(seconds) / 60
        let secs = Int(seconds) % 60
        return String(format: "%d:%02d", minutes, secs)
    }

    private func togglePlayback() {
        do {
            if engine.state == .playing { engine.pause() }
            else { try engine.play() }
        } catch {
            print("Playback error: \(error)")
        }
    }
}
