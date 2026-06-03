#if os(macOS)
import SwiftUI

struct DownloadsViewMacOS: View {
    @State private var viewModel: DownloadsViewModel
    @State private var selectedTab: Int = 0
    @State private var playerURL: URL?

    init(viewModel: DownloadsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    var body: some View {
        VStack(spacing: 0) {
            segmentedControl
                .padding(.horizontal, 24)
                .padding(.vertical, 12)

            Divider().background(Color.ytDivider)

            if selectedTab == 0 {
                activeContent
            } else {
                completedContent
            }
        }
        .background(Color.ytBackground)
        .navigationTitle("Downloads")
        .onAppear { viewModel.loadSavedDownloads() }
        .sheet(item: $playerURL) { url in
            PlayerViewMacOS(url: url)
        }
    }

    private var segmentedControl: some View {
        HStack(spacing: 0) {
            segmentButton(title: "Downloading", index: 0)
            segmentButton(title: "Completed", index: 1)
        }
        .padding(3)
        .background(Color.ytSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.ytDivider, lineWidth: 1))
    }

    private func segmentButton(title: String, index: Int) -> some View {
        Button {
            withAnimation(.spring(duration: 0.25)) { selectedTab = index }
        } label: {
            Text(title)
                .font(.subheadline.weight(selectedTab == index ? .semibold : .regular))
                .foregroundStyle(selectedTab == index ? Color.ytTextPrimary : Color.ytTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 7)
                .background(
                    selectedTab == index
                        ? Color.ytSurfaceElevated
                        : Color.clear,
                    in: RoundedRectangle(cornerRadius: 8)
                )
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .animation(.spring(duration: 0.25), value: selectedTab)
    }

    @ViewBuilder
    private var activeContent: some View {
        if viewModel.activeDownloads.isEmpty {
            macEmptyState(icon: "arrow.down.circle", message: "No active downloads")
        } else {
            List(viewModel.activeDownloads) { item in
                ActiveDownloadRowMac(item: item) { viewModel.cancelDownload(item) }
                    .listRowBackground(Color.ytSurface)
                    .listRowSeparatorTint(Color.ytDivider)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.ytBackground)
        }
    }

    @ViewBuilder
    private var completedContent: some View {
        if viewModel.completedDownloads.isEmpty {
            macEmptyState(icon: "checkmark.circle", message: "No completed downloads")
        } else {
            List(viewModel.completedDownloads) { item in
                CompletedDownloadRowMac(item: item) {
                    playerURL = item.localURL
                } onDelete: {
                    viewModel.deleteCompleted(item)
                }
                .listRowBackground(Color.ytSurface)
                .listRowSeparatorTint(Color.ytDivider)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(Color.ytBackground)
        }
    }

    private func macEmptyState(icon: String, message: String) -> some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 40))
                .foregroundStyle(Color.ytTextSecondary.opacity(0.5))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Color.ytTextSecondary)
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}

private struct ActiveDownloadRowMac: View {
    let item: DownloadItem
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            thumbnailView
                .frame(width: 80, height: 52)
                .clipShape(RoundedRectangle(cornerRadius: 6))

            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.ytTextPrimary)
                    .lineLimit(2)
                Text(item.quality.label)
                    .font(.caption)
                    .foregroundStyle(Color.ytTextSecondary)
                ProgressView(value: item.progress)
                    .tint(Color.ytAccent)
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

            Button(action: onCancel) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(Color.ytTextSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
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

    private var thumbnailView: some View {
        Group {
            if let data = item.thumbnailData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage).resizable().aspectRatio(contentMode: .fill)
            } else {
                AsyncImage(url: item.thumbnailURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.ytSurfaceElevated
                }
            }
        }
    }
}

private struct CompletedDownloadRowMac: View {
    let item: DownloadItem
    let onPlay: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onPlay) {
                HStack(spacing: 12) {
                    ZStack(alignment: .bottomTrailing) {
                        thumbnailView
                            .frame(width: 80, height: 52)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        Image(systemName: "play.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .shadow(radius: 3)
                            .padding(3)
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
                    .foregroundStyle(Color.ytTextSecondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 6)
    }

    private var thumbnailView: some View {
        Group {
            if let data = item.thumbnailData, let nsImage = NSImage(data: data) {
                Image(nsImage: nsImage).resizable().aspectRatio(contentMode: .fill)
            } else {
                AsyncImage(url: item.thumbnailURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.ytSurfaceElevated
                }
            }
        }
    }
}
#endif
