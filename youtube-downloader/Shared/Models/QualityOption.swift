import Foundation

struct QualityOption: Identifiable, Hashable, Codable, Sendable {
    let id: String
    let label: String
    let resolution: Int?
    let fileExtension: String
    let streamURL: URL
    let isAudioOnly: Bool
}
