#if os(iOS)
import SwiftUI

struct HomeViewIOS: View {
    @State private var viewModel = HomeViewModel(videoRepository: YouTubeVideoRepository())
    @Environment(DownloadsViewModel.self) private var downloadsViewModel

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    urlInput
                    fetchButton
                    resultArea
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 32)
            }
            .scrollDismissesKeyboard(.interactively)
            .background(Color.ytBackground.ignoresSafeArea())
            .navigationTitle("YouTube Downloader")
            .sheet(isPresented: $viewModel.showQualityPicker) {
                if let video = viewModel.videoInfo {
                    QualityPickerSheetIOS(video: video, selectedQuality: $viewModel.selectedQuality) { quality in
                        downloadsViewModel.startDownload(videoInfo: video, quality: quality)
                    }
                }
            }
        }
    }

    private var urlInput: some View {
        HStack(spacing: 10) {
            Image(systemName: "link")
                .foregroundStyle(Color.ytTextSecondary)
                .font(.subheadline)

            TextField("", text: $viewModel.urlText,
                      prompt: Text("Paste YouTube URL").foregroundColor(Color.ytTextSecondary))
                .foregroundStyle(Color.ytTextPrimary)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .tint(Color.ytAccent)

            Button {
                if viewModel.urlText.isEmpty {
                    viewModel.urlText = UIPasteboard.general.string ?? ""
                } else {
                    viewModel.urlText = ""
                }
            } label: {
                Image(systemName: viewModel.urlText.isEmpty ? "doc.on.clipboard" : "xmark.circle.fill")
                    .foregroundStyle(viewModel.urlText.isEmpty ? Color.ytAccent : Color.ytTextSecondary)
                    .font(.subheadline)
            }
        }
        .padding(14)
        .background(Color.ytSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.ytDivider, lineWidth: 1)
        )
    }

    private var fetchButton: some View {
        Button {
            Task { await viewModel.fetchVideo() }
        } label: {
            HStack(spacing: 8) {
                if viewModel.isLoading {
                    ProgressView().tint(.white).scaleEffect(0.8)
                } else {
                    Image(systemName: "magnifyingglass")
                }
                Text(viewModel.isLoading ? "Fetching..." : "Fetch Video")
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(14)
            .background(viewModel.urlText.isEmpty ? Color.ytAccent.opacity(0.4) : Color.ytAccent)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(viewModel.urlText.isEmpty || viewModel.isLoading)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isLoading)
    }

    @ViewBuilder
    private var resultArea: some View {
        if viewModel.isLoading {
            SkeletonCardView()
        } else if let error = viewModel.error {
            ErrorBannerView(message: error)
        } else if let video = viewModel.videoInfo {
            VideoCardView(video: video) {
                viewModel.showQualityPicker = true
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }
}

// MARK: - Subviews

private struct SkeletonCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            SkeletonBox(height: 200)
            SkeletonBox(height: 20, width: nil)
            SkeletonBox(height: 16, width: 160)
        }
        .padding(16)
        .background(Color.ytSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct SkeletonBox: View {
    let height: CGFloat
    var width: CGFloat? = nil
    @State private var opacity: Double = 0.4

    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.ytSurfaceElevated)
            .frame(width: width, height: height)
            .opacity(opacity)
            .onAppear {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    opacity = 0.9
                }
            }
    }
}

private struct ErrorBannerView: View {
    let message: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .foregroundStyle(Color.ytAccent)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.ytTextSecondary)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(14)
        .background(Color.ytSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.ytAccent.opacity(0.3), lineWidth: 1)
        )
    }
}

private struct VideoCardView: View {
    let video: VideoInfo
    let onDownload: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncImage(url: video.thumbnailURL) { image in
                image.resizable().aspectRatio(16 / 9, contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.ytSurfaceElevated)
                    .overlay(ProgressView().tint(Color.ytTextSecondary))
            }
            .aspectRatio(16 / 9, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: .black.opacity(0.5), radius: 8, y: 4)

            Text(video.title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Color.ytTextPrimary)
                .lineLimit(2)

            if let channel = video.channelName {
                HStack(spacing: 4) {
                    Image(systemName: "person.circle.fill")
                        .font(.caption)
                        .foregroundStyle(Color.ytTextSecondary)
                    Text(channel)
                        .font(.caption)
                        .foregroundStyle(Color.ytTextSecondary)
                }
            }

            Button(action: onDownload) {
                Label("Select Quality", systemImage: "chevron.up.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.ytAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
        }
        .padding(14)
        .background(Color.ytSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
#endif
