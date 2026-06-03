import Foundation

protocol VideoRepository {
    func fetchVideoInfo(url: URL) async throws -> VideoInfo
}
