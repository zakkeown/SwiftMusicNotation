import SwiftMusicNotation
import Observation

@Observable
class ScoreLoader {
    private let importer = MusicXMLImporter()

    var score: Score?
    var error: ScoreLoaderError?
    var isLoading = false

    func loadScore(named filename: String) {
        isLoading = true
        error = nil

        do {
            guard let url = Bundle.main.url(
                forResource: filename,
                withExtension: "musicxml"
            ) else {
                throw ScoreLoaderError.fileNotFound(filename)
            }

            score = try importer.importScore(from: url)
        } catch let loaderError as ScoreLoaderError {
            error = loaderError
        } catch let importError as MusicXMLImportError {
            error = .importFailed(importError.localizedDescription)
        } catch {
            error = .importFailed(error.localizedDescription)
        }

        isLoading = false
    }
}

enum ScoreLoaderError: Error, LocalizedError {
    case fileNotFound(String)
    case importFailed(String)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let name):
            return "Could not find '\(name).musicxml' in the app bundle."
        case .importFailed(let reason):
            return "Failed to import MusicXML: \(reason)"
        }
    }
}
