import Foundation
import YouTubeKit

final class YouTubeVideoRepository: VideoRepository {

    func fetchVideoInfo(url: URL) async throws -> VideoInfo {
        let youtube = YouTube(url: url, methods: [.local, .remote])

        async let streams = youtube.streams
        async let metadata = youtube.metadata

        let (fetchedStreams, fetchedMetadata) = try await (streams, metadata)

        let qualities: [QualityOption] = fetchedStreams
            .filter { $0.isNativelyPlayable }
            .compactMap { stream -> QualityOption? in
                if stream.includesVideoAndAudioTrack, let resolution = stream.videoResolution {
                    return QualityOption(
                        id: "\(resolution)p",
                        label: "\(resolution)p",
                        resolution: resolution,
                        fileExtension: stream.fileExtension.rawValue,
                        streamURL: stream.url,
                        isAudioOnly: false
                    )
                } else if !stream.includesVideoTrack && stream.includesAudioTrack && stream.fileExtension == .m4a {
                    return QualityOption(
                        id: "audio",
                        label: "Audio Only",
                        resolution: nil,
                        fileExtension: stream.fileExtension.rawValue,
                        streamURL: stream.url,
                        isAudioOnly: true
                    )
                }
                return nil
            }
            .reduce(into: [String: QualityOption]()) { dict, option in
                if dict[option.id] == nil { dict[option.id] = option }
            }
            .values
            .sorted { ($0.resolution ?? -1) > ($1.resolution ?? -1) }

        return VideoInfo(
            id: videoID(from: url),
            title: fetchedMetadata?.title ?? "",
            thumbnailURL: fetchedMetadata?.thumbnail?.url,
            channelName: nil,
            qualities: qualities
        )
    }

    private func videoID(from url: URL) -> String {
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let id = components.queryItems?.first(where: { $0.name == "v" })?.value {
            return id
        }
        return url.lastPathComponent
    }
}
