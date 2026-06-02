#if os(iOS)
import SwiftUI

private struct ThumbnailView: View {
    let item: DownloadItem
    let width: CGFloat
    let height: CGFloat

    var body: some View {
        if let data = item.thumbnailData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: width, height: height)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } else {
            AsyncImage(url: item.thumbnailURL) { image in
                image.resizable().aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.ytSurfaceElevated
            }
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

struct DownloadsViewIOS: View {
    @State private var viewModel: DownloadsViewModel
    @State private var selectedTab: Int = 0
    @State private var playerURL: URL?

    init(viewModel: DownloadsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.ytBackground.ignoresSafeArea()
                VStack(spacing: 0) {
                    segmentedControl
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    Divider().background(Color.ytDivider)
                    if selectedTab == 0 {
                        activeContent
                    } else {
                        completedContent
                    }
                }
            }
            .navigationTitle("Downloads")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.ytBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .onAppear { viewModel.loadSavedDownloads() }
            .sheet(item: $playerURL) { url in
                PlayerViewIOS(url: url)
            }
        }
    }

    private var segmentedControl: some View {
        HStack(spacing: 4) {
            segmentButton(title: "Downloading", index: 0)
            segmentButton(title: "Completed", index: 1)
        }
        .padding(4)
        .background {
            if #available(iOS 26.0, *) {
                Color.clear
                    .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14))
            } else {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )
            }
        }
    }

    private func segmentButton(title: String, index: Int) -> some View {
        Button {
            withAnimation(.spring(duration: 0.3)) { selectedTab = index }
        } label: {
            Text(title)
                .font(.subheadline.weight(selectedTab == index ? .semibold : .regular))
                .foregroundStyle(selectedTab == index ? Color.ytTextPrimary : Color.ytTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 9)
                .background {
                    if selectedTab == index {
                        if #available(iOS 26.0, *) {
                            Color.clear
                                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 10))
                        } else {
                            RoundedRectangle(cornerRadius: 10)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .black.opacity(0.15), radius: 4, y: 2)
                        }
                    }
                }
        }
        .animation(.spring(duration: 0.3), value: selectedTab)
    }

    @ViewBuilder
    private var activeContent: some View {
        if viewModel.activeDownloads.isEmpty {
            EmptyStateView(icon: "arrow.down.circle", message: "No active downloads")
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.activeDownloads) { item in
                        ActiveDownloadCard(item: item) { viewModel.cancelDownload(item) }
                    }
                }
                .padding(16)
            }
        }
    }

    @ViewBuilder
    private var completedContent: some View {
        if viewModel.completedDownloads.isEmpty {
            EmptyStateView(icon: "checkmark.circle", message: "No completed downloads")
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.completedDownloads) { item in
                        CompletedDownloadCard(item: item) {
                            playerURL = item.localURL
                        } onDelete: {
                            viewModel.deleteCompleted(item)
                        }
                    }
                }
                .padding(16)
            }
        }
    }
}

// MARK: - Cards

private struct ActiveDownloadCard: View {
    let item: DownloadItem
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                ThumbnailView(item: item, width: 72, height: 48)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(Color.ytTextPrimary)
                        .lineLimit(2)
                    Text(item.quality.label)
                        .font(.caption)
                        .foregroundStyle(Color.ytTextSecondary)
                }
                Spacer()
                Button(action: onCancel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.ytTextSecondary)
                }
            }

            VStack(spacing: 4) {
                ProgressView(value: item.progress)
                    .tint(Color.ytAccent)
                    .animation(.linear(duration: 0.3), value: item.progress)
                HStack {
                    Text(statusLabel(for: item.status))
                        .font(.caption)
                        .foregroundStyle(Color.ytTextSecondary)
                    Spacer()
                    Text("\(Int(item.progress * 100))%")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(Color.ytTextSecondary)
                }
            }
        }
        .padding(14)
        .background(Color.ytSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func statusLabel(for status: DownloadStatus) -> String {
        switch status {
        case .pending: return "Pending..."
        case .downloading: return "Downloading"
        case .completed: return "Done"
        case .failed: return "Failed"
        case .cancelled: return "Cancelled"
        }
    }
}

private struct CompletedDownloadCard: View {
    let item: DownloadItem
    let onPlay: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Entire left+center area is tappable
            Button(action: onPlay) {
                HStack(spacing: 12) {
                    ZStack(alignment: .bottomTrailing) {
                        ThumbnailView(item: item, width: 96, height: 64)

                        Image(systemName: "play.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.white)
                            .shadow(radius: 4)
                            .padding(4)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(Color.ytTextPrimary)
                            .lineLimit(2)

                        HStack(spacing: 4) {
                            Text(item.quality.label)
                            Text("·")
                            Text(item.quality.fileExtension.uppercased())
                            if let date = item.completedAt {
                                Text("·")
                                Text(date, style: .date)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(Color.ytTextSecondary)
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.subheadline)
                    .foregroundStyle(Color.ytTextSecondary)
                    .padding(8)
            }
        }
        .padding(12)
        .background(Color.ytSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct EmptyStateView: View {
    let icon: String
    let message: String

    var body: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 48))
                .foregroundStyle(Color.ytTextSecondary.opacity(0.5))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.ytTextSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
#endif
