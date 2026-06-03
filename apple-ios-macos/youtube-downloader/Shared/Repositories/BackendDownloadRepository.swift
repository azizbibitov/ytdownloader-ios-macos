import Foundation

private struct TaskCreatedResponse: Decodable {
    let taskId: String
    enum CodingKeys: String, CodingKey { case taskId = "task_id" }
}

private struct TaskProgressResponse: Decodable {
    let status: String
    let percent: Double
    let speed: String?
    let eta: Int?
    let error: String?
}

@MainActor
final class BackendDownloadRepository: DownloadRepository {
    private var activeTasks: [UUID: Task<Void, Never>] = [:]
    private let storageRepository: any LocalStorageRepository

    init(storageRepository: any LocalStorageRepository) {
        self.storageRepository = storageRepository
    }

    func startDownload(id: UUID, from url: URL, fileExtension: String, formatID: String?) -> AsyncThrowingStream<DownloadProgress, Error> {
        let (stream, continuation) = AsyncThrowingStream<DownloadProgress, Error>.makeStream()
        let destination = storageRepository.localFileURL(for: id, fileExtension: fileExtension)
        let youtubeURL = url.absoluteString
        let format = formatID ?? "bestvideo+bestaudio/best"

        let task = Task { @MainActor in
            do {
                let taskID = try await Self.startBackendDownload(youtubeURL: youtubeURL, formatID: format)

                while true {
                    try Task.checkCancellation()
                    let progress = try await Self.fetchProgress(taskID: taskID)

                    switch progress.status {
                    case "pending", "downloading":
                        continuation.yield(DownloadProgress(
                            bytesDownloaded: Int64(progress.percent),
                            totalBytes: 100,
                            localURL: nil
                        ))
                        try await Task.sleep(nanoseconds: 500_000_000)

                    case "merging":
                        continuation.yield(DownloadProgress(bytesDownloaded: 99, totalBytes: 100, localURL: nil))
                        try await Task.sleep(nanoseconds: 500_000_000)

                    case "done":
                        let localURL = try await Self.downloadFile(taskID: taskID, to: destination)
                        continuation.yield(DownloadProgress(bytesDownloaded: 100, totalBytes: 100, localURL: localURL))
                        continuation.finish()
                        return

                    case "error":
                        throw NSError(
                            domain: "BackendDownloadError", code: 0,
                            userInfo: [NSLocalizedDescriptionKey: progress.error ?? "Download failed on server"]
                        )

                    default:
                        try await Task.sleep(nanoseconds: 500_000_000)
                    }
                }
            } catch {
                continuation.finish(throwing: error)
            }
        }

        activeTasks[id] = task

        continuation.onTermination = { [weak self] _ in
            Task { @MainActor [weak self] in self?.cancelDownload(id: id) }
        }

        return stream
    }

    func cancelDownload(id: UUID) {
        activeTasks.removeValue(forKey: id)?.cancel()
    }

    // MARK: - HTTP helpers

    private static func startBackendDownload(youtubeURL: String, formatID: String) async throws -> String {
        let url = URL(string: Config.backendURL + "/download")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(["url": youtubeURL, "format_id": formatID])

        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(TaskCreatedResponse.self, from: data).taskId
    }

    private static func fetchProgress(taskID: String) async throws -> TaskProgressResponse {
        let url = URL(string: Config.backendURL + "/progress/\(taskID)")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(TaskProgressResponse.self, from: data)
    }

    private static func downloadFile(taskID: String, to destination: URL) async throws -> URL {
        let url = URL(string: Config.backendURL + "/file/\(taskID)")!
        let (tempURL, _) = try await URLSession.shared.download(from: url)
        try FileManager.default.createDirectory(
            at: destination.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        if FileManager.default.fileExists(atPath: destination.path) {
            try FileManager.default.removeItem(at: destination)
        }
        try FileManager.default.moveItem(at: tempURL, to: destination)
        return destination
    }
}
