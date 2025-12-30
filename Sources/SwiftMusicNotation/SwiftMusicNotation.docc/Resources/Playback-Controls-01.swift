import SwiftUI
import SwiftMusicNotation

/// Reusable playback control buttons
struct PlaybackControls: View {
    @ObservedObject var engine: PlaybackEngine

    var body: some View {
        HStack(spacing: 20) {
            // Stop button
            Button {
                engine.stop()
            } label: {
                Image(systemName: "stop.fill")
                    .font(.title2)
            }
            .disabled(engine.state == .stopped)

            // Play/Pause button
            Button {
                togglePlayback()
            } label: {
                Image(systemName: engine.state == .playing ? "pause.fill" : "play.fill")
                    .font(.title)
            }
            .disabled(!engine.isLoaded)
        }
        .padding()
    }

    private func togglePlayback() {
        do {
            if engine.state == .playing {
                engine.pause()
            } else {
                try engine.play()
            }
        } catch {
            print("Playback error: \(error)")
        }
    }
}

#Preview {
    PlaybackControls(engine: PlaybackEngine())
}
