import SwiftData
import Foundation

@MainActor
final class SwiftDataStorageRepository: LocalStorageRepository {
    private let context: ModelContext
    private let downloadsDirectory: URL

    init(context: ModelContext) {
        self.context = context
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        downloadsDirectory = documents.appendingPathComponent("Downloads")
        try? FileManager.default.createDirectory(at: downloadsDirectory, withIntermediateDirectories: true)
    }

    func loadDownloads() -> [DownloadItem] {
        let descriptor = FetchDescriptor<DownloadRecord>()
        guard let records = try? context.fetch(descriptor) else { return [] }
        return records.compactMap { record in
            guard let filename = record.localFilename else { return nil }
            let localURL = downloadsDirectory.appendingPathComponent(filename)
            guard FileManager.default.fileExists(atPath: localURL.path) else { return nil }
            return record.toDownloadItem(localURL: localURL)
        }
    }

    func save(_ item: DownloadItem) throws {
        let id = item.id
        let descriptor = FetchDescriptor<DownloadRecord>(
            predicate: #Predicate { $0.id == id }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.update(from: item)
        } else {
            context.insert(DownloadRecord.from(item))
        }
        try context.save()
    }

    func delete(id: UUID) throws {
        let descriptor = FetchDescriptor<DownloadRecord>(
            predicate: #Predicate { $0.id == id }
        )
        if let record = try? context.fetch(descriptor).first {
            if let filename = record.localFilename {
                let url = downloadsDirectory.appendingPathComponent(filename)
                try? FileManager.default.removeItem(at: url)
            }
            context.delete(record)
        }
        try context.save()
    }

    func localFileURL(for id: UUID, fileExtension: String) -> URL {
        downloadsDirectory.appendingPathComponent("\(id.uuidString).\(fileExtension)")
    }

    func saveThumbnailData(_ data: Data, for id: UUID) {
        let descriptor = FetchDescriptor<DownloadRecord>(
            predicate: #Predicate { $0.id == id }
        )
        guard let record = try? context.fetch(descriptor).first else { return }
        record.thumbnailData = data
        try? context.save()
    }

    func thumbnailData(for id: UUID) -> Data? {
        let descriptor = FetchDescriptor<DownloadRecord>(
            predicate: #Predicate { $0.id == id }
        )
        return (try? context.fetch(descriptor).first)?.thumbnailData
    }
}
