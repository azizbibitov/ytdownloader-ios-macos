import Foundation

private final class DownloadBridge: NSObject, URLSessionDownloadDelegate, URLSessionTaskDelegate, @unchecked Sendable {
    private let destinationURL: URL
    private let continuation: AsyncThrowingStream<DownloadProgress, Error>.Continuation
    private var localURL: URL?

    init(destinationURL: URL, continuation: AsyncThrowingStream<DownloadProgress, Error>.Continuation) {
        self.destinationURL = destinationURL
        self.continuation = continuation
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        continuation.yield(DownloadProgress(bytesDownloaded: totalBytesWritten, totalBytes: totalBytesExpectedToWrite, localURL: nil))
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        do {
            try FileManager.default.createDirectory(at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            if FileManager.default.fileExists(atPath: destinationURL.path) {
                try FileManager.default.removeItem(at: destinationURL)
            }
            try FileManager.default.moveItem(at: location, to: destinationURL)
            localURL = destinationURL
        } catch {
            continuation.finish(throwing: error)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error {
            continuation.finish(throwing: error)
        } else {
            let total = task.countOfBytesExpectedToReceive
            continuation.yield(DownloadProgress(bytesDownloaded: total, totalBytes: total, localURL: localURL))
            continuation.finish()
        }
    }
}

@MainActor
final class URLSessionDownloadRepository: DownloadRepository {
    private var active: [UUID: (session: URLSession, bridge: DownloadBridge)] = [:]
    private let storageRepository: any LocalStorageRepository

    init(storageRepository: any LocalStorageRepository) {
        self.storageRepository = storageRepository
    }

    func startDownload(id: UUID, from url: URL, fileExtension: String, formatID: String?) -> AsyncThrowingStream<DownloadProgress, Error> {
        let (stream, continuation) = AsyncThrowingStream<DownloadProgress, Error>.makeStream()

        let destination = storageRepository.localFileURL(for: id, fileExtension: fileExtension)
        let bridge = DownloadBridge(destinationURL: destination, continuation: continuation)
        let session = URLSession(configuration: .default, delegate: bridge, delegateQueue: nil)
        let task = session.downloadTask(with: url)
        active[id] = (session, bridge)
        task.resume()

        continuation.onTermination = { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.cancelDownload(id: id)
            }
        }

        return stream
    }

    func cancelDownload(id: UUID) {
        let pair = active.removeValue(forKey: id)
        pair?.session.invalidateAndCancel()
    }
}
