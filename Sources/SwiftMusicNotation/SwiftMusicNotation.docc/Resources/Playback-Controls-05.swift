import SwiftUI
import SwiftMusicNotation

struct PlaybackControls: View {
    @ObservedObject var engine: PlaybackEngine

    var body: some View {
        VStack(spacing: 12) {
            // Position display
            HStack {
                // Measure and beat
                VStack(alignment: .leading, spacing: 2) {
                    Text("Position")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("M\(engine.currentPosition.measure) • Beat \(String(format: "%.1f", engine.currentPosition.beat))")
                        .font(.headline)
                        .monospacedDigit()
                }

                Spacer()

                // Elapsed time
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Time")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(formattedTime(engine.currentPosition.timeInSeconds))
                        .font(.headline)
                        .monospacedDigit()
                }
            }
            .frame(maxWidth: 280)

            Divider()

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

    /// Format time as M:SS
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
