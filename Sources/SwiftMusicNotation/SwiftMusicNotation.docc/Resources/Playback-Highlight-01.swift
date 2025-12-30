import SwiftUI
import SwiftMusicNotation

/// A visual highlight overlay for the current playback measure
struct MeasureHighlight: View {
    let measureNumber: Int
    let totalMeasures: Int

    /// Approximate measure width (in a real app, get this from the layout engine)
    let measureWidth: CGFloat = 100

    /// Number of measures per system (in a real app, get this from the layout engine)
    let measuresPerSystem: Int = 4

    var body: some View {
        GeometryReader { geometry in
            // Calculate which system and position within the system
            let systemIndex = (measureNumber - 1) / measuresPerSystem
            let measureInSystem = (measureNumber - 1) % measuresPerSystem

            // Calculate position (simplified - real implementation would use layout data)
            let xOffset = CGFloat(measureInSystem) * measureWidth + 50
            let yOffset = CGFloat(systemIndex) * 120 + 60

            Rectangle()
                .fill(Color.accentColor.opacity(0.2))
                .frame(width: measureWidth, height: 80)
                .border(Color.accentColor, width: 2)
                .position(x: xOffset + measureWidth / 2, y: yOffset + 40)
        }
        .allowsHitTesting(false)  // Don't intercept touches
    }
}

#Preview {
    MeasureHighlight(measureNumber: 3, totalMeasures: 16)
        .frame(width: 500, height: 400)
        .background(Color.gray.opacity(0.1))
}
