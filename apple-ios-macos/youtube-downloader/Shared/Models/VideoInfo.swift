import Foundation

struct VideoInfo {
    let id: String
    let title: String
    let thumbnailURL: URL?
    let channelName: String?
    let qualities: [QualityOption]
}
