import SwiftUI
import SwiftMusicNotation

struct PlaybackControls: View {
    @ObservedObject var engine: PlaybackEngine
    let totalMeasures: Int

    var body: some View {
        VStack(spacing: 12) {
            // Progress bar
            VStack(spacing: 4) {
                ProgressView(value: progressValue)
                    .progressViewStyle(.linear)

                HStack {
                    Text(formattedTime(engine.currentPosition.timeInSeconds))
                        .font(.caption)
                        .monospacedDigit()

                    Spacer()

                    Text("Measure \(engine.currentPosition.measure) of \(totalMeasures)")
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

    /// Progress through the score (0.0 to 1.0)
    private var progressValue: Double {
        guard totalMeasures > 0 else { return 0 }
        return Double(engine.currentPosition.measure - 1) / Double(totalMeasures)
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
