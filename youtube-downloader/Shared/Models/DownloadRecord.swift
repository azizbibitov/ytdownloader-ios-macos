import SwiftData
import Foundation

@Model
final class DownloadRecord {
    @Attribute(.unique) var id: UUID
    var videoID: String
    var title: String
    var thumbnailURLString: String?
    var thumbnailData: Data?
    var qualityData: Data
    var statusType: String
    var statusMessage: String?
    var progress: Double
    var localFilename: String?
    var createdAt: Date
    var completedAt: Date?
    var fileSize: Int64?

    init(
        id: UUID,
        videoID: String,
        title: String,
        thumbnailURLString: String?,
        qualityData: Data,
        statusType: String,
        statusMessage: String? = nil,
        progress: Double,
        localFilename: String?,
        createdAt: Date,
        completedAt: Date? = nil,
        fileSize: Int64? = nil
    ) {
        self.id = id
        self.videoID = videoID
        self.title = title
        self.thumbnailURLString = thumbnailURLString
        self.qualityData = qualityData
        self.statusType = statusType
        self.statusMessage = statusMessage
        self.progress = progress
        self.localFilename = localFilename
        self.createdAt = createdAt
        self.completedAt = completedAt
        self.fileSize = fileSize
    }
}

extension DownloadRecord {
    @MainActor
    static func from(_ item: DownloadItem) -> DownloadRecord {
        DownloadRecord(
            id: item.id,
            videoID: item.videoID,
            title: item.title,
            thumbnailURLString: item.thumbnailURL?.absoluteString,
            qualityData: (try? JSONEncoder().encode(item.quality)) ?? Data(),
            statusType: item.status.typeString,
            statusMessage: item.status.associatedMessage,
            progress: item.progress,
            localFilename: item.localURL?.lastPathComponent,
            createdAt: item.createdAt,
            completedAt: item.completedAt,
            fileSize: item.fileSize
        )
    }

    @MainActor
    func toDownloadItem(localURL: URL?) -> DownloadItem? {
        guard let quality = try? JSONDecoder().decode(QualityOption.self, from: qualityData) else { return nil }
        return DownloadItem(
            id: id,
            videoID: videoID,
            title: title,
            thumbnailURL: thumbnailURLString.flatMap { URL(string: $0) },
            thumbnailData: thumbnailData,
            quality: quality,
            status: DownloadStatus(typeString: statusType, message: statusMessage),
            progress: progress,
            localURL: localURL,
            createdAt: createdAt,
            completedAt: completedAt,
            fileSize: fileSize
        )
    }

    @MainActor
    func update(from item: DownloadItem) {
        title = item.title
        thumbnailURLString = item.thumbnailURL?.absoluteString
        qualityData = (try? JSONEncoder().encode(item.quality)) ?? qualityData
        statusType = item.status.typeString
        statusMessage = item.status.associatedMessage
        progress = item.progress
        localFilename = item.localURL?.lastPathComponent
        completedAt = item.completedAt
        fileSize = item.fileSize
    }
}

private extension DownloadStatus {
    var typeString: String {
        switch self {
        case .pending:     return "pending"
        case .downloading: return "downloading"
        case .completed:   return "completed"
        case .failed:      return "failed"
        case .cancelled:   return "cancelled"
        }
    }

    var associatedMessage: String? {
        if case .failed(let msg) = self { return msg }
        return nil
    }

    init(typeString: String, message: String?) {
        switch typeString {
        case "pending":     self = .pending
        case "downloading": self = .downloading
        case "completed":   self = .completed
        case "failed":      self = .failed(message ?? "")
        case "cancelled":   self = .cancelled
        default:            self = .completed
        }
    }
}
