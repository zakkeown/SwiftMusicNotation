import SwiftUI
import SwiftMusicNotation
import CoreGraphics

/// Observable settings object for score appearance customization
@Observable
class AppearanceSettings {
    // MARK: - Font Settings

    var selectedFontName: String = "Bravura"
    var availableFonts: [String] = ["Bravura", "Petaluma", "Leland"]

    // MARK: - Color Settings

    var useDarkMode: Bool = false
    var backgroundColor: Color = .white
    var noteColor: Color = .black
    var staffLineColor: Color = .black
    var barlineColor: Color = .black

    // MARK: - Line Thickness Settings

    var staffLineThickness: Double = 0.8
    var stemThickness: Double = 0.8
    var thinBarlineThickness: Double = 0.8
    var thickBarlineThickness: Double = 3.0

    // MARK: - Layout Settings

    var staffHeight: Double = 40.0
    var quarterNoteSpacing: Double = 30.0
    var spacingFactor: Double = 0.7
    var systemDistance: Double = 80.0
    var partDistance: Double = 80.0

    // MARK: - Page Settings

    enum PageSize: String, CaseIterable {
        case letter = "Letter"
        case a4 = "A4"
        case custom = "Custom"
    }

    var pageSize: PageSize = .letter
    var customPageWidth: Double = 612
    var customPageHeight: Double = 792
    var marginTop: Double = 72
    var marginBottom: Double = 72
    var marginLeft: Double = 72
    var marginRight: Double = 72
}
