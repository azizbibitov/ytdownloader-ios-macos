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
            Picker("Tab", selection: $selectedTab) {
                Text("Downloading").tag(0)
                Text("Completed").tag(1)
            }
            .pickerStyle(.segmented)
            .padding()

            if selectedTab == 0 {
                activeDownloadsList
            } else {
                completedDownloadsList
            }
        }
        .onAppear { viewModel.loadSavedDownloads() }
        .sheet(item: $playerURL) { url in
            PlayerViewMacOS(url: url)
        }
    }

    private var activeDownloadsList: some View {
        List(viewModel.activeDownloads) { item in
            HStack(spacing: 12) {
                AsyncImage(url: item.thumbnailURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 80, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title).font(.subheadline).lineLimit(2)
                    ProgressView(value: item.progress).tint(.red)
                    Text("\(Int(item.progress * 100))%").font(.caption).foregroundStyle(.secondary)
                }

                Button {
                    viewModel.cancelDownload(item)
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var completedDownloadsList: some View {
        List(viewModel.completedDownloads) { item in
            HStack(spacing: 12) {
                AsyncImage(url: item.thumbnailURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray
                }
                .frame(width: 80, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading) {
                    Text(item.title).font(.subheadline).lineLimit(2)
                    Text(item.quality.label).font(.caption).foregroundStyle(.secondary)
                }

                Spacer()

                Button("Play") { playerURL = item.localURL }
                    .buttonStyle(.borderedProminent)

                Button(role: .destructive) {
                    viewModel.deleteCompleted(item)
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
            }
        }
    }
}
#endif
