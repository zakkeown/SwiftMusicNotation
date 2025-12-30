import SwiftMusicNotation

struct ScoreLoader {
    private let importer = MusicXMLImporter()

    func loadScore(named filename: String) throws -> Score {
        guard let url = Bundle.main.url(
            forResource: filename,
            withExtension: "musicxml"
        ) else {
            throw ScoreLoaderError.fileNotFound(filename)
        }

        do {
            return try importer.importScore(from: url)
        } catch let error as MusicXMLImportError {
            throw ScoreLoaderError.importFailed(error.localizedDescription)
        }
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
