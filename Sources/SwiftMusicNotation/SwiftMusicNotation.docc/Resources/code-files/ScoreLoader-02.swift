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

        return try importer.importScore(from: url)
    }
}

enum ScoreLoaderError: Error {
    case fileNotFound(String)
}
