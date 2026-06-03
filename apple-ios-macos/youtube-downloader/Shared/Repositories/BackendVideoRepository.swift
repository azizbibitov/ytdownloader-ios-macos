import Foundation

private struct BackendVideoInfoResponse: Decodable {
    let id: String
    let title: String
    let thumbnailUrl: String?
    let channel: String?
    let duration: Int
    let qualities: [BackendQualityOption]

    enum CodingKeys: String, CodingKey {
        case id, title, channel, duration, qualities
        case thumbnailUrl = "thumbnail_url"
    }
}

private struct BackendQualityOption: Decodable {
    let formatId: String
    let label: String
    let ext: String
    let filesize: Int?
    let isAudioOnly: Bool

    enum CodingKeys: String, CodingKey {
        case label, ext, filesize
        case formatId = "format_id"
        case isAudioOnly = "is_audio_only"
    }
}

final class BackendVideoRepository: VideoRepository {
    func fetchVideoInfo(url: URL) async throws -> VideoInfo {
        var components = URLComponents(string: Config.backendURL + "/video-info")!
        components.queryItems = [URLQueryItem(name: "url", value: url.absoluteString)]

        let (data, response) = try await URLSession.shared.data(from: components.url!)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            let detail = (try? JSONDecoder().decode([String: String].self, from: data))?["detail"]
            throw NSError(domain: "BackendError", code: 0,
                          userInfo: [NSLocalizedDescriptionKey: detail ?? "Failed to fetch video info"])
        }

        let decoded = try JSONDecoder().decode(BackendVideoInfoResponse.self, from: data)
        return decoded.toVideoInfo(originalURL: url)
    }
}

private extension BackendVideoInfoResponse {
    func toVideoInfo(originalURL: URL) -> VideoInfo {
        VideoInfo(
            id: id,
            title: title,
            thumbnailURL: thumbnailUrl.flatMap { URL(string: $0) },
            channelName: channel,
            qualities: qualities.map { q in
                QualityOption(
                    id: q.formatId,
                    label: q.label,
                    resolution: parseResolution(q.label),
                    fileExtension: q.ext,
                    streamURL: originalURL,
                    isAudioOnly: q.isAudioOnly
                )
            }
        )
    }

    private func parseResolution(_ label: String) -> Int? {
        Int(label.replacingOccurrences(of: "p", with: ""))
    }
}
