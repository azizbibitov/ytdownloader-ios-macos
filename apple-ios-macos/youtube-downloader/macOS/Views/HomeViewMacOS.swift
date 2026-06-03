#if os(macOS)
import SwiftUI

struct HomeViewMacOS: View {
    @State private var viewModel = HomeViewModel(videoRepository: BackendVideoRepository())
    @Environment(DownloadsViewModel.self) private var downloadsViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                urlInputRow
                resultArea
            }
            .padding(24)
        }
        .background(Color.ytBackground)
        .navigationTitle("Search")
        .sheet(isPresented: $viewModel.showQualityPicker) {
            if let video = viewModel.videoInfo {
                QualityPickerPanel(video: video, selectedQuality: $viewModel.selectedQuality) { quality in
                    downloadsViewModel.startDownload(videoInfo: video, quality: quality)
                }
            }
        }
    }

    private var urlInputRow: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "link")
                    .foregroundStyle(Color.ytTextSecondary)
                TextField("Paste YouTube URL", text: $viewModel.urlText)
                    .textFieldStyle(.plain)
                    .foregroundStyle(Color.ytTextPrimary)
                if !viewModel.urlText.isEmpty {
                    Button {
                        viewModel.urlText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(Color.ytTextSecondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(10)
            .background(Color.ytSurface)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.ytDivider, lineWidth: 1))

            Button {
                if viewModel.urlText.isEmpty {
                    viewModel.urlText = NSPasteboard.general.string(forType: .string) ?? ""
                } else {
                    Task { await viewModel.fetchVideo() }
                }
            } label: {
                HStack(spacing: 6) {
                    if viewModel.isLoading {
                        ProgressView().scaleEffect(0.7).frame(width: 14, height: 14)
                    } else {
                        Image(systemName: viewModel.urlText.isEmpty ? "doc.on.clipboard" : "magnifyingglass")
                    }
                    Text(viewModel.isLoading ? "Fetching..." : (viewModel.urlText.isEmpty ? "Paste" : "Fetch"))
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.ytAccent)
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoading)
        }
    }

    @ViewBuilder
    private var resultArea: some View {
        if viewModel.isLoading {
            MacSkeletonCard()
        } else if let error = viewModel.error {
            HStack(spacing: 10) {
                Image(systemName: "exclamationmark.circle.fill")
                    .foregroundStyle(Color.ytAccent)
                Text(error)
                    .font(.subheadline)
                    .foregroundStyle(Color.ytTextSecondary)
                Spacer()
            }
            .padding(14)
            .background(Color.ytSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.ytAccent.opacity(0.3), lineWidth: 1))
        } else if let video = viewModel.videoInfo {
            MacVideoCard(video: video) {
                viewModel.showQualityPicker = true
            }
            .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }
}

private struct MacVideoCard: View {
    let video: VideoInfo
    let onDownload: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            AsyncImage(url: video.thumbnailURL) { image in
                image.resizable().aspectRatio(16/9, contentMode: .fill)
            } placeholder: {
                Rectangle().fill(Color.ytSurfaceElevated)
                    .overlay(ProgressView().tint(Color.ytTextSecondary))
            }
            .aspectRatio(16/9, contentMode: .fit)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(video.title)
                .font(.headline)
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
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(10)
                    .background(Color.ytAccent)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
        }
        .padding(14)
        .background(Color.ytSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct MacSkeletonCard: View {
    @State private var opacity: Double = 0.4

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            RoundedRectangle(cornerRadius: 10).fill(Color.ytSurfaceElevated).frame(height: 200)
            RoundedRectangle(cornerRadius: 6).fill(Color.ytSurfaceElevated).frame(height: 18)
            RoundedRectangle(cornerRadius: 6).fill(Color.ytSurfaceElevated).frame(width: 160, height: 14)
        }
        .padding(14)
        .background(Color.ytSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                opacity = 0.9
            }
        }
    }
}

private struct QualityPickerPanel: View {
    let video: VideoInfo
    @Binding var selectedQuality: QualityOption?
    let onDownload: (QualityOption) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Select Quality")
                    .font(.title3.bold())
                    .foregroundStyle(Color.ytTextPrimary)
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundStyle(Color.ytTextSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding([.horizontal, .top], 20)
            .padding(.bottom, 12)

            Divider().background(Color.ytDivider)

            ScrollView {
                VStack(spacing: 0) {
                    ForEach(video.qualities) { quality in
                        Button {
                            selectedQuality = quality
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: quality.isAudioOnly ? "music.note" : "video.fill")
                                    .font(.subheadline)
                                    .foregroundStyle(selectedQuality?.id == quality.id ? Color.ytAccent : Color.ytTextSecondary)
                                    .frame(width: 20)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(quality.label)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Color.ytTextPrimary)
                                    Text(quality.fileExtension.uppercased())
                                        .font(.caption)
                                        .foregroundStyle(Color.ytTextSecondary)
                                }

                                Spacer()

                                if selectedQuality?.id == quality.id {
                                    Image(systemName: "checkmark")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.ytAccent)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(selectedQuality?.id == quality.id ? Color.ytAccent.opacity(0.1) : Color.clear)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        Divider().background(Color.ytDivider).padding(.leading, 52)
                    }
                }
            }

            Divider().background(Color.ytDivider)

            HStack(spacing: 12) {
                Button("Cancel") { dismiss() }
                    .foregroundStyle(Color.ytTextSecondary)
                    .buttonStyle(.plain)

                Spacer()

                Button {
                    if let quality = selectedQuality {
                        onDownload(quality)
                        dismiss()
                    }
                } label: {
                    Text("Download")
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(selectedQuality != nil ? Color.ytAccent : Color.ytAccent.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .disabled(selectedQuality == nil)
            }
            .padding(20)
        }
        .background(Color.ytBackground)
        .frame(width: 360, height: 480)
    }
}
#endif
