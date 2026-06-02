import Foundation

struct DownloadProgress {
    let bytesDownloaded: Int64
    let totalBytes: Int64
    let localURL: URL?

    var fraction: Double {
        guard totalBytes > 0 else { return 0 }
        return Double(bytesDownloaded) / Double(totalBytes)
    }
}

@MainActor
protocol DownloadRepository {
    func startDownload(id: UUID, from url: URL, fileExtension: String) -> AsyncThrowingStream<DownloadProgress, Error>
    func cancelDownload(id: UUID)
}
