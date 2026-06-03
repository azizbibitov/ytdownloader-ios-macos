import Foundation
import Observation

@Observable
@MainActor
final class HomeViewModel {
    var urlText: String = ""
    var videoInfo: VideoInfo?
    var isLoading: Bool = false
    var error: String?
    var selectedQuality: QualityOption?
    var showQualityPicker: Bool = false

    private let videoRepository: any VideoRepository

    init(videoRepository: any VideoRepository) {
        self.videoRepository = videoRepository
    }

    func fetchVideo() async {
        guard let url = URL(string: urlText.trimmingCharacters(in: .whitespaces)) else {
            error = "Invalid URL"
            return
        }
        isLoading = true
        error = nil
        videoInfo = nil
        do {
            videoInfo = try await videoRepository.fetchVideoInfo(url: url)
        } catch {
            self.error = error.localizedDescription
        }
        isLoading = false
    }


}
