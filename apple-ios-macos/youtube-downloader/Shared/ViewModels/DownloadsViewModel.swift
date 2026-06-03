import Foundation
import Observation

@Observable
@MainActor
final class DownloadsViewModel {
    var activeDownloads: [DownloadItem] = []
    var completedDownloads: [DownloadItem] = []

    private let downloadRepository: any DownloadRepository
    private let storageRepository: any LocalStorageRepository

    init(downloadRepository: any DownloadRepository, storageRepository: any LocalStorageRepository) {
        self.downloadRepository = downloadRepository
        self.storageRepository = storageRepository
        completedDownloads = storageRepository.loadDownloads()
    }

    func loadSavedDownloads() {
        completedDownloads = storageRepository.loadDownloads()
    }

    func startDownload(videoInfo: VideoInfo, quality: QualityOption) {
        let item = DownloadItem(
            id: UUID(),
            videoID: videoInfo.id,
            title: videoInfo.title,
            thumbnailURL: videoInfo.thumbnailURL,
            quality: quality,
            status: .downloading,
            progress: 0,
            localURL: nil,
            createdAt: Date(),
            completedAt: nil,
            fileSize: nil
        )
        activeDownloads.append(item)

        Task {
            do {
                for try await progress in downloadRepository.startDownload(id: item.id, from: quality.streamURL, fileExtension: quality.fileExtension, formatID: quality.id) {
                    update(id: item.id, progress: progress.fraction, localURL: progress.localURL)
                }
                complete(id: item.id)
            } catch {
                fail(id: item.id, error: error.localizedDescription)
            }
        }
    }

    func cancelDownload(_ item: DownloadItem) {
        downloadRepository.cancelDownload(id: item.id)
        activeDownloads.removeAll { $0.id == item.id }
    }

    func deleteCompleted(_ item: DownloadItem) {
        try? storageRepository.delete(id: item.id)
        completedDownloads.removeAll { $0.id == item.id }
    }

    private func update(id: UUID, progress: Double, localURL: URL?) {
        guard let index = activeDownloads.firstIndex(where: { $0.id == id }) else { return }
        activeDownloads[index].progress = progress
        if let localURL { activeDownloads[index].localURL = localURL }
    }

    private func complete(id: UUID) {
        guard let index = activeDownloads.firstIndex(where: { $0.id == id }) else { return }
        var item = activeDownloads[index]
        item.status = .completed
        item.completedAt = Date()
        item.progress = 1.0
        activeDownloads.remove(at: index)
        completedDownloads.append(item)
        try? storageRepository.save(item)
        cacheThumbnail(for: item)
    }

    private func cacheThumbnail(for item: DownloadItem) {
        guard let url = item.thumbnailURL else { return }
        let itemID = item.id
        Task {
            guard let (data, _) = try? await URLSession.shared.data(from: url) else { return }
            storageRepository.saveThumbnailData(data, for: itemID)
            if let i = completedDownloads.firstIndex(where: { $0.id == itemID }) {
                completedDownloads[i].thumbnailData = data
            }
        }
    }

    private func fail(id: UUID, error: String) {
        guard let index = activeDownloads.firstIndex(where: { $0.id == id }) else { return }
        activeDownloads[index].status = .failed(error)
    }
}
