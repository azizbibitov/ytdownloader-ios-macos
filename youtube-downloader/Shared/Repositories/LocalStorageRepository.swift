import Foundation

@MainActor
protocol LocalStorageRepository {
    func loadDownloads() -> [DownloadItem]
    func save(_ item: DownloadItem) throws
    func delete(id: UUID) throws
    func localFileURL(for id: UUID, fileExtension: String) -> URL
    func saveThumbnailData(_ data: Data, for id: UUID)
}

extension LocalStorageRepository {
    func saveThumbnailData(_ data: Data, for id: UUID) {}
}
