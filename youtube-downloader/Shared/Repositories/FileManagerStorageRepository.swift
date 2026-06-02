import Foundation

@MainActor
final class FileManagerStorageRepository: LocalStorageRepository {

    private let downloadsDirectory: URL
    private let metadataFileURL: URL

    init() {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        downloadsDirectory = documents.appendingPathComponent("Downloads")
        metadataFileURL = documents.appendingPathComponent("downloads_metadata.json")
        try? FileManager.default.createDirectory(at: downloadsDirectory, withIntermediateDirectories: true)
    }

    func loadDownloads() -> [DownloadItem] {
        guard let data = try? Data(contentsOf: metadataFileURL),
              var items = try? JSONDecoder().decode([DownloadItem].self, from: data) else {
            return []
        }
        // Re-derive localURL from the current sandbox path so stale absolute
        // paths (e.g. after reinstall or simulator container change) don't break playback.
        items = items.map { item in
            var item = item
            if item.localURL != nil {
                item.localURL = localFileURL(for: item.id, fileExtension: item.quality.fileExtension)
            }
            return item
        }
        return items.filter { item in
            guard let localURL = item.localURL else { return false }
            return FileManager.default.fileExists(atPath: localURL.path)
        }
    }

    func save(_ item: DownloadItem) throws {
        var items = loadDownloads().filter { $0.id != item.id }
        items.append(item)
        let data = try JSONEncoder().encode(items)
        try data.write(to: metadataFileURL, options: .atomic)
    }

    func delete(id: UUID) throws {
        var items = loadDownloads()
        if let index = items.firstIndex(where: { $0.id == id }) {
            if let localURL = items[index].localURL {
                try? FileManager.default.removeItem(at: localURL)
            }
            items.remove(at: index)
        }
        let data = try JSONEncoder().encode(items)
        try data.write(to: metadataFileURL, options: .atomic)
    }

    func localFileURL(for id: UUID, fileExtension: String) -> URL {
        downloadsDirectory.appendingPathComponent("\(id.uuidString).\(fileExtension)")
    }
}
