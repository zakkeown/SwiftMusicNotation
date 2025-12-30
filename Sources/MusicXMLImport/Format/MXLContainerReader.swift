import Foundation
import ZIPFoundation

/// Reads compressed MusicXML (.mxl) archives.
public struct MXLContainerReader {
    public init() {}

    /// Extracts the main MusicXML document from an MXL archive.
    /// - Parameter url: URL to the .mxl file.
    /// - Returns: The extracted XML data.
    public func extractMainDocument(from url: URL) throws -> Data {
        guard let archive = Archive(url: url, accessMode: .read) else {
            throw MusicXMLError.invalidMXLArchive("Unable to open archive")
        }

        return try extractMainDocument(from: archive)
    }

    /// Extracts the main MusicXML document from archive data.
    /// - Parameter data: The MXL archive data.
    /// - Returns: The extracted XML data.
    public func extractMainDocument(from data: Data) throws -> Data {
        guard let archive = Archive(data: data, accessMode: .read) else {
            throw MusicXMLError.invalidMXLArchive("Unable to read archive data")
        }

        return try extractMainDocument(from: archive)
    }

    /// Internal extraction from an open archive.
    private func extractMainDocument(from archive: Archive) throws -> Data {
        // First, read META-INF/container.xml to find the root file
        let rootFilePath = try findRootFile(in: archive)

        // Extract the root file
        guard let entry = archive[rootFilePath] else {
            throw MusicXMLError.invalidMXLArchive("Root file '\(rootFilePath)' not found in archive")
        }

        var extractedData = Data()
        _ = try archive.extract(entry) { data in
            extractedData.append(data)
        }

        return extractedData
    }

    /// Finds the root file path from container.xml.
    private func findRootFile(in archive: Archive) throws -> String {
        // Look for META-INF/container.xml
        guard let containerEntry = archive["META-INF/container.xml"] else {
            throw MusicXMLError.missingContainerXML
        }

        var containerData = Data()
        _ = try archive.extract(containerEntry) { data in
            containerData.append(data)
        }

        return try parseContainerXML(containerData)
    }

    /// Parses container.xml to extract the root file path.
    private func parseContainerXML(_ data: Data) throws -> String {
        let parser = ContainerXMLParser(data: data)
        guard let rootFile = try parser.parse() else {
            throw MusicXMLError.missingRootFile
        }
        return rootFile
    }

    /// Extracts all files from an MXL archive.
    /// - Parameter url: URL to the .mxl file.
    /// - Returns: Dictionary mapping file paths to their data.
    public func extractAllFiles(from url: URL) throws -> [String: Data] {
        guard let archive = Archive(url: url, accessMode: .read) else {
            throw MusicXMLError.invalidMXLArchive("Unable to open archive")
        }

        var files: [String: Data] = [:]

        for entry in archive {
            guard entry.type == .file else { continue }

            var fileData = Data()
            _ = try archive.extract(entry) { data in
                fileData.append(data)
            }
            files[entry.path] = fileData
        }

        return files
    }
}

/// Simple XML parser for container.xml.
private class ContainerXMLParser: NSObject, XMLParserDelegate {
    private let data: Data
    private var rootFilePath: String?
    private var parseError: Error?

    init(data: Data) {
        self.data = data
    }

    func parse() throws -> String? {
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()

        if let error = parseError {
            throw error
        }

        return rootFilePath
    }

    // MARK: - XMLParserDelegate

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        // Look for <rootfile full-path="...">
        if elementName == "rootfile", rootFilePath == nil {
            if let fullPath = attributeDict["full-path"] {
                // Prefer .xml or .musicxml files
                let ext = (fullPath as NSString).pathExtension.lowercased()
                if ext == "xml" || ext == "musicxml" || rootFilePath == nil {
                    rootFilePath = fullPath
                }
            }
        }
    }

    func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
        self.parseError = MusicXMLError.xmlParsingFailed(
            line: parser.lineNumber,
            column: parser.columnNumber,
            message: parseError.localizedDescription
        )
    }
}
