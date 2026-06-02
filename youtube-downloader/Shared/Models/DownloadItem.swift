import Foundation

struct DownloadItem: Identifiable, Codable, Sendable {
    let id: UUID
    let videoID: String
    let title: String
    let thumbnailURL: URL?
    var thumbnailData: Data? = nil
    let quality: QualityOption
    var status: DownloadStatus
    var progress: Double
    var localURL: URL?
    let createdAt: Date
    var completedAt: Date?
    var fileSize: Int64?
}

enum DownloadStatus: Equatable {
    case pending
    case downloading
    case completed
    case failed(String)
    case cancelled
}

extension DownloadStatus: Codable {
    private enum CodingKeys: String, CodingKey { case type, message }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        switch try c.decode(String.self, forKey: .type) {
        case "pending":    self = .pending
        case "downloading": self = .downloading
        case "completed":  self = .completed
        case "failed":     self = .failed(try c.decodeIfPresent(String.self, forKey: .message) ?? "")
        case "cancelled":  self = .cancelled
        default:           self = .completed
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .pending:          try c.encode("pending",     forKey: .type)
        case .downloading:      try c.encode("downloading", forKey: .type)
        case .completed:        try c.encode("completed",   forKey: .type)
        case .failed(let msg):  try c.encode("failed",      forKey: .type); try c.encode(msg, forKey: .message)
        case .cancelled:        try c.encode("cancelled",   forKey: .type)
        }
    }
}
