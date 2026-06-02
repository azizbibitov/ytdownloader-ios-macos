#if os(macOS)
import SwiftUI

struct HomeViewMacOS: View {
    @State private var viewModel = HomeViewModel(
        videoRepository: YouTubeVideoRepository()
    )

    var body: some View {
        VStack(spacing: 20) {
            // TODO: app logo / title

            // URL input field
            HStack {
                TextField("Paste YouTube URL", text: $viewModel.urlText)
                    .textFieldStyle(.roundedBorder)
                Button("Paste") {
                    viewModel.urlText = NSPasteboard.general.string(forType: .string) ?? ""
                }
            }

            Button("Fetch Video") {
                Task { await viewModel.fetchVideo() }
            }
            .disabled(viewModel.urlText.isEmpty)

            if viewModel.isLoading {
                ProgressView()
            }

            if let error = viewModel.error {
                Text(error)
                    .foregroundStyle(.red)
            }

            if let video = viewModel.videoInfo {
                // TODO: video card
                VStack(alignment: .leading, spacing: 12) {
                    AsyncImage(url: video.thumbnailURL) { image in
                        image.resizable().aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray
                    }
                    .frame(height: 200)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                    Text(video.title)
                        .font(.headline)
                        .lineLimit(2)

                    Button("Select Quality") {
                        viewModel.showQualityPicker = true
                    }
                }
            }

            Spacer()
        }
        .padding()
        .sheet(isPresented: $viewModel.showQualityPicker) {
            if let video = viewModel.videoInfo {
                QualityPickerPanel(video: video, selectedQuality: $viewModel.selectedQuality)
            }
        }
    }
}

private struct QualityPickerPanel: View {
    let video: VideoInfo
    @Binding var selectedQuality: QualityOption?
    @Environment(\.dismiss) private var dismiss

    var onDownload: ((QualityOption) -> Void)?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select Quality")
                .font(.title2)
                .bold()

            ForEach(video.qualities) { quality in
                Button {
                    selectedQuality = quality
                } label: {
                    HStack {
                        VStack(alignment: .leading) {
                            Text(quality.label).font(.headline)
                            Text(quality.fileExtension.uppercased()).font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        if selectedQuality?.id == quality.id {
                            Image(systemName: "checkmark").foregroundStyle(.red)
                        }
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
                Divider()
            }

            HStack {
                Button("Cancel") { dismiss() }
                Spacer()
                Button("Download") {
                    if let quality = selectedQuality { onDownload?(quality) }
                    dismiss()
                }
                .disabled(selectedQuality == nil)
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(minWidth: 320)
    }
}
#endif
