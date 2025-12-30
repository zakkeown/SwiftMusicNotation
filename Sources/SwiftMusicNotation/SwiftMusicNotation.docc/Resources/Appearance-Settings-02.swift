import SwiftUI
import SwiftMusicNotation
import CoreGraphics

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

    // MARK: - Computed Configurations

    /// Generate RenderConfiguration from current settings
    var renderConfiguration: RenderConfiguration {
        RenderConfiguration(
            backgroundColor: cgColor(from: backgroundColor),
            staffLineColor: cgColor(from: staffLineColor),
            barlineColor: cgColor(from: barlineColor),
            noteColor: cgColor(from: noteColor),
            staffLineThickness: CGFloat(staffLineThickness),
            thinBarlineThickness: CGFloat(thinBarlineThickness),
            thickBarlineThickness: CGFloat(thickBarlineThickness),
            bracketThickness: 2.0,
            stemThickness: CGFloat(stemThickness)
        )
    }

    /// Generate LayoutConfiguration from current settings
    var layoutConfiguration: LayoutConfiguration {
        var config = LayoutConfiguration()
        config.spacingConfig.quarterNoteSpacing = quarterNoteSpacing
        config.spacingConfig.spacingFactor = spacingFactor
        config.verticalConfig.systemDistance = CGFloat(systemDistance)
        config.verticalConfig.partDistance = CGFloat(partDistance)
        return config
    }

    /// Generate LayoutContext from current settings
    var layoutContext: LayoutContext {
        let size: CGSize
        switch pageSize {
        case .letter:
            size = CGSize(width: 612, height: 792)
        case .a4:
            size = CGSize(width: 595, height: 842)
        case .custom:
            size = CGSize(width: customPageWidth, height: customPageHeight)
        }

        return LayoutContext(
            pageSize: size,
            margins: EdgeInsets(
                top: CGFloat(marginTop),
                left: CGFloat(marginLeft),
                bottom: CGFloat(marginBottom),
                right: CGFloat(marginRight)
            ),
            staffHeight: CGFloat(staffHeight),
            fontName: selectedFontName
        )
    }

    // MARK: - Helpers

    private func cgColor(from color: Color) -> CGColor {
        #if canImport(UIKit)
        return UIColor(color).cgColor
        #elseif canImport(AppKit)
        return NSColor(color).cgColor
        #else
        return CGColor(gray: 0, alpha: 1)
        #endif
    }
}
